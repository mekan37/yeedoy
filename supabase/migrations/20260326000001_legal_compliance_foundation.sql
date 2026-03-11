create table if not exists public.policy_versions (
  id uuid primary key default gen_random_uuid(),
  policy_type text not null check (
    policy_type in (
      'terms',
      'privacy',
      'cookies',
      'community',
      'business',
      'copyright',
      'ai',
      'dmca',
      'dsa',
      'data-safety',
      'trust-safety',
      'security',
      'law-enforcement',
      'delete-account'
    )
  ),
  version_label text not null,
  content_hash text not null,
  published_at timestamptz not null default now(),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid null references auth.users(id) on delete set null
);

create unique index if not exists policy_versions_policy_type_version_label_key
  on public.policy_versions(policy_type, version_label);

create unique index if not exists policy_versions_one_active_per_type_idx
  on public.policy_versions(policy_type)
  where is_active = true;

create index if not exists policy_versions_active_lookup_idx
  on public.policy_versions(policy_type, is_active, published_at desc);

create table if not exists public.user_policy_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  policy_version_id uuid not null references public.policy_versions(id) on delete cascade,
  accepted_at timestamptz not null default now(),
  ip_address inet null,
  user_agent text null,
  source_app text not null check (
    source_app in ('mobile_flutter', 'panel_flutter_web', 'next')
  ),
  created_at timestamptz not null default now(),
  unique(user_id, policy_version_id)
);

create index if not exists user_policy_acceptances_user_id_idx
  on public.user_policy_acceptances(user_id, accepted_at desc);

create index if not exists user_policy_acceptances_policy_version_id_idx
  on public.user_policy_acceptances(policy_version_id);

create table if not exists public.business_policy_acceptances (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  policy_version_id uuid not null references public.policy_versions(id) on delete cascade,
  accepted_at timestamptz not null default now(),
  ip_address inet null,
  user_agent text null,
  created_at timestamptz not null default now(),
  unique(business_id, user_id, policy_version_id)
);

create index if not exists business_policy_acceptances_business_id_idx
  on public.business_policy_acceptances(business_id, accepted_at desc);

create index if not exists business_policy_acceptances_user_id_idx
  on public.business_policy_acceptances(user_id, accepted_at desc);

create table if not exists public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  request_type text not null check (
    request_type in (
      'data_export',
      'privacy_application',
      'access',
      'rectification',
      'erasure',
      'restriction',
      'objection',
      'portability'
    )
  ),
  status text not null default 'submitted' check (
    status in ('submitted', 'in_review', 'resolved', 'rejected', 'cancelled')
  ),
  details text not null default '',
  submitted_at timestamptz not null default now(),
  resolved_at timestamptz null,
  created_at timestamptz not null default now()
);

create index if not exists privacy_requests_user_id_status_idx
  on public.privacy_requests(user_id, status, submitted_at desc);

create unique index if not exists privacy_requests_one_open_per_user_idx
  on public.privacy_requests(user_id)
  where status in ('submitted', 'in_review');

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null default '',
  status text not null default 'requested' check (
    status in ('requested', 'in_review', 'completed', 'rejected', 'cancelled')
  ),
  requested_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now()
);

create index if not exists account_deletion_requests_user_id_status_idx
  on public.account_deletion_requests(user_id, status, requested_at desc);

create unique index if not exists account_deletion_requests_one_open_per_user_idx
  on public.account_deletion_requests(user_id)
  where status in ('requested', 'in_review');

create or replace function public.request_header_v1(p_name text)
returns text
language sql
stable
as $$
  select coalesce(
    (coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb ->> lower(p_name)),
    (coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb ->> p_name)
  );
$$;

create or replace function public.request_ip_v1()
returns inet
language plpgsql
stable
as $$
declare
  v_ip_text text;
begin
  v_ip_text := coalesce(
    public.request_header_v1('x-forwarded-for'),
    public.request_header_v1('x-real-ip')
  );

  if nullif(trim(coalesce(v_ip_text, '')), '') is null then
    return null;
  end if;

  begin
    return trim(split_part(v_ip_text, ',', 1))::inet;
  exception
    when others then
      return null;
  end;
end;
$$;

create or replace function public.capture_request_metadata_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_table_name in ('user_policy_acceptances', 'privacy_requests', 'account_deletion_requests')
     and new.user_id is null then
    new.user_id := auth.uid();
  end if;

  if tg_table_name in ('user_policy_acceptances', 'business_policy_acceptances') then
    if new.accepted_at is null then
      new.accepted_at := now();
    end if;
    if new.user_agent is null then
      new.user_agent := public.request_header_v1('user-agent');
    end if;
    if new.ip_address is null then
      new.ip_address := public.request_ip_v1();
    end if;
  end if;

  if tg_table_name = 'privacy_requests' and new.submitted_at is null then
    new.submitted_at := now();
  end if;

  if tg_table_name = 'account_deletion_requests' and new.requested_at is null then
    new.requested_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists trg_user_policy_acceptances_capture_request_metadata_v1
  on public.user_policy_acceptances;
create trigger trg_user_policy_acceptances_capture_request_metadata_v1
before insert on public.user_policy_acceptances
for each row execute function public.capture_request_metadata_v1();

drop trigger if exists trg_business_policy_acceptances_capture_request_metadata_v1
  on public.business_policy_acceptances;
create trigger trg_business_policy_acceptances_capture_request_metadata_v1
before insert on public.business_policy_acceptances
for each row execute function public.capture_request_metadata_v1();

drop trigger if exists trg_privacy_requests_capture_request_metadata_v1
  on public.privacy_requests;
create trigger trg_privacy_requests_capture_request_metadata_v1
before insert on public.privacy_requests
for each row execute function public.capture_request_metadata_v1();

drop trigger if exists trg_account_deletion_requests_capture_request_metadata_v1
  on public.account_deletion_requests;
create trigger trg_account_deletion_requests_capture_request_metadata_v1
before insert on public.account_deletion_requests
for each row execute function public.capture_request_metadata_v1();

alter table public.policy_versions enable row level security;
alter table public.user_policy_acceptances enable row level security;
alter table public.business_policy_acceptances enable row level security;
alter table public.privacy_requests enable row level security;
alter table public.account_deletion_requests enable row level security;

drop policy if exists policy_versions_read_all on public.policy_versions;
create policy policy_versions_read_all
on public.policy_versions
for select
to anon, authenticated
using (true);

drop policy if exists policy_versions_admin_write on public.policy_versions;
create policy policy_versions_admin_write
on public.policy_versions
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists user_policy_acceptances_select_own on public.user_policy_acceptances;
create policy user_policy_acceptances_select_own
on public.user_policy_acceptances
for select
to authenticated
using (public.is_admin() or user_id = auth.uid());

drop policy if exists user_policy_acceptances_insert_own on public.user_policy_acceptances;
create policy user_policy_acceptances_insert_own
on public.user_policy_acceptances
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists business_policy_acceptances_select_owned on public.business_policy_acceptances;
create policy business_policy_acceptances_select_owned
on public.business_policy_acceptances
for select
to authenticated
using (
  public.is_admin()
  or user_id = auth.uid()
  or public.can_manage_business_v1(business_id)
);

drop policy if exists business_policy_acceptances_insert_owned on public.business_policy_acceptances;
create policy business_policy_acceptances_insert_owned
on public.business_policy_acceptances
for insert
to authenticated
with check (
  user_id = auth.uid()
  and public.can_manage_business_v1(business_id)
);

drop policy if exists privacy_requests_select_own on public.privacy_requests;
create policy privacy_requests_select_own
on public.privacy_requests
for select
to authenticated
using (public.is_admin() or user_id = auth.uid());

drop policy if exists privacy_requests_insert_own on public.privacy_requests;
create policy privacy_requests_insert_own
on public.privacy_requests
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists account_deletion_requests_select_own on public.account_deletion_requests;
create policy account_deletion_requests_select_own
on public.account_deletion_requests
for select
to authenticated
using (public.is_admin() or user_id = auth.uid());

drop policy if exists account_deletion_requests_insert_own on public.account_deletion_requests;
create policy account_deletion_requests_insert_own
on public.account_deletion_requests
for insert
to authenticated
with check (user_id = auth.uid());

grant select on public.policy_versions to anon, authenticated;
grant select, insert on public.user_policy_acceptances to authenticated;
grant select, insert on public.business_policy_acceptances to authenticated;
grant select, insert on public.privacy_requests to authenticated;
grant select, insert on public.account_deletion_requests to authenticated;

insert into public.policy_versions (
  policy_type,
  version_label,
  content_hash,
  published_at,
  is_active
)
values
  ('terms', '2026.03-tr-v1', md5('terms:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('privacy', '2026.03-tr-v1', md5('privacy:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('cookies', '2026.03-tr-v1', md5('cookies:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('community', '2026.03-tr-v1', md5('community:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('business', '2026.03-tr-v1', md5('business:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('copyright', '2026.03-tr-v1', md5('copyright:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('ai', '2026.03-tr-v1', md5('ai:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('dmca', '2026.03-tr-v1', md5('dmca:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('dsa', '2026.03-tr-v1', md5('dsa:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('data-safety', '2026.03-tr-v1', md5('data-safety:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('trust-safety', '2026.03-tr-v1', md5('trust-safety:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('security', '2026.03-tr-v1', md5('security:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('law-enforcement', '2026.03-tr-v1', md5('law-enforcement:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('delete-account', '2026.03-tr-v1', md5('delete-account:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true)
on conflict (policy_type, version_label) do update
set
  content_hash = excluded.content_hash,
  published_at = excluded.published_at,
  is_active = excluded.is_active;
