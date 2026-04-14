create table if not exists public.incident_updates (
  id uuid primary key default gen_random_uuid(),
  incident_key text not null,
  title text not null,
  summary text not null,
  action_taken text not null,
  status text not null default 'open' check (status in ('open', 'mitigated', 'resolved')),
  visibility text not null default 'public' check (visibility in ('public', 'internal')),
  created_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists incident_updates_incident_key_created_at_idx
  on public.incident_updates (incident_key, created_at desc);
create index if not exists incident_updates_visibility_created_at_idx
  on public.incident_updates (visibility, created_at desc);
alter table public.incident_updates enable row level security;
drop policy if exists "incident_updates_public_read" on public.incident_updates;
create policy "incident_updates_public_read"
on public.incident_updates
for select
using (visibility = 'public');
drop policy if exists "incident_updates_admin_insert" on public.incident_updates;
create policy "incident_updates_admin_insert"
on public.incident_updates
for insert
with check (public.is_admin());
drop policy if exists "incident_updates_admin_update" on public.incident_updates;
create policy "incident_updates_admin_update"
on public.incident_updates
for update
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "incident_updates_admin_delete" on public.incident_updates;
create policy "incident_updates_admin_delete"
on public.incident_updates
for delete
using (public.is_admin());
create or replace function public.admin_list_incident_updates_v1(
  p_limit int default 100
)
returns table(
  id uuid,
  incident_key text,
  title text,
  summary text,
  action_taken text,
  status text,
  visibility text,
  created_by uuid,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    iu.id,
    iu.incident_key,
    iu.title,
    iu.summary,
    iu.action_taken,
    iu.status,
    iu.visibility,
    iu.created_by,
    iu.created_at
  from public.incident_updates iu
  where public.is_admin()
  order by iu.created_at desc
  limit greatest(p_limit, 1);
$$;
create or replace function public.public_list_incident_updates_v1(
  p_limit int default 100
)
returns table(
  id uuid,
  incident_key text,
  title text,
  summary text,
  action_taken text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    iu.id,
    iu.incident_key,
    iu.title,
    iu.summary,
    iu.action_taken,
    iu.status,
    iu.created_at
  from public.incident_updates iu
  where iu.visibility = 'public'
  order by iu.created_at desc
  limit greatest(p_limit, 1);
$$;
create or replace function public.admin_create_incident_update_v1(
  p_incident_key text,
  p_title text,
  p_summary text,
  p_action_taken text,
  p_status text default 'open',
  p_visibility text default 'public'
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  insert into public.incident_updates(
    incident_key,
    title,
    summary,
    action_taken,
    status,
    visibility,
    created_by
  ) values (
    nullif(trim(p_incident_key), ''),
    trim(p_title),
    trim(p_summary),
    trim(p_action_taken),
    coalesce(nullif(trim(p_status), ''), 'open'),
    coalesce(nullif(trim(p_visibility), ''), 'public'),
    auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;
