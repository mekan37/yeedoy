-- Operations and moderation scaling:
-- - role expansion: community_mod
-- - queue SLA alignment: reports 24h, owner claims 48h
-- - decision templates
-- - moderation appeal flow

create or replace function public.get_app_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_claim jsonb := auth.jwt();
  v_role text;
begin
  v_role := lower(
    coalesce(
      v_claim -> 'app_metadata' ->> 'role',
      v_claim -> 'user_metadata' ->> 'role',
      'user'
    )
  );

  if v_role not in ('user', 'owner', 'community_mod', 'admin') then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;
create or replace function public.current_user_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_claim jsonb := auth.jwt();
  v_role text := lower(
    coalesce(
      v_claim -> 'app_metadata' ->> 'role',
      v_claim -> 'user_metadata' ->> 'role',
      ''
    )
  );
  v_has_owner boolean := false;
begin
  if v_uid is null then
    return 'user';
  end if;

  if v_role in ('admin', 'community_mod') then
    return v_role;
  end if;

  select exists(
    select 1
    from public.owner_claims oc
    where oc.user_id = v_uid
      and oc.status::text in ('approved', 'accepted')
  )
  into v_has_owner;

  if v_has_owner then
    return 'owner';
  end if;

  return 'user';
end;
$$;
create or replace function public.is_admin_or_community_mod_v1()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin()
    or lower(coalesce(public.get_app_role_v1(), 'user')) = 'community_mod';
$$;
create table if not exists public.moderation_decision_templates (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('report', 'claim', 'appeal')),
  decision text not null check (decision in ('approved', 'rejected', 'needs_info')),
  title text not null,
  body text not null,
  locale text not null default 'tr-TR',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scope, decision, title, locale)
);
insert into public.moderation_decision_templates(scope, decision, title, body, locale)
values
  ('report', 'approved', 'Ihlal Teyit', 'Raporunuz incelendi. İhlal teyit edildi ve gerekli işlem uygulandı.', 'tr-TR'),
  ('report', 'rejected', 'Kanıt Yetersiz', 'Raporunuz incelendi. Mevcut kanıt nedeniyle işlem uygulanamadı.', 'tr-TR'),
  ('claim', 'approved', 'Sahiplik Onayı', 'Talebiniz incelendi ve işletme sahipliği onaylandı.', 'tr-TR'),
  ('claim', 'rejected', 'Sahiplik Reddi', 'Talebiniz incelendi ancak doğrulama kriterleri sağlanamadı.', 'tr-TR'),
  ('appeal', 'approved', 'İtiraz Kabul', 'İtirazınız yeniden incelendi ve kararınız güncellendi.', 'tr-TR'),
  ('appeal', 'rejected', 'İtiraz Sonucu', 'İtirazınız incelendi. İlk karar geçerliliğini koruyor.', 'tr-TR')
on conflict (scope, decision, title, locale) do nothing;
alter table public.moderation_decision_templates enable row level security;
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_decision_templates'
      and policyname = 'moderation_templates_read_v1'
  ) then
    create policy moderation_templates_read_v1
      on public.moderation_decision_templates
      for select
      to authenticated
      using (is_active = true and locale = 'tr-TR');
  end if;
end $$;
create table if not exists public.moderation_appeals (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('report', 'claim')),
  source_id uuid not null,
  appellant_user_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  decision_note text,
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_moderation_appeals_status_created_at
  on public.moderation_appeals(status, created_at desc);
create index if not exists idx_moderation_appeals_source
  on public.moderation_appeals(source_type, source_id);
create index if not exists idx_moderation_appeals_appellant
  on public.moderation_appeals(appellant_user_id, created_at desc);
alter table public.moderation_appeals enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_insert_own_v1'
  ) then
    create policy appeals_insert_own_v1
      on public.moderation_appeals
      for insert
      to authenticated
      with check (auth.uid() = appellant_user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_select_owner_or_mod_v1'
  ) then
    create policy appeals_select_owner_or_mod_v1
      on public.moderation_appeals
      for select
      to authenticated
      using (
        auth.uid() = appellant_user_id
        or public.is_admin_or_community_mod_v1()
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_update_mod_only_v1'
  ) then
    create policy appeals_update_mod_only_v1
      on public.moderation_appeals
      for update
      to authenticated
      using (public.is_admin_or_community_mod_v1())
      with check (public.is_admin_or_community_mod_v1());
  end if;
end $$;
create or replace function public.get_moderation_templates_v1(
  p_scope text default null
)
returns table(
  id uuid,
  scope text,
  decision text,
  title text,
  body text,
  locale text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.id,
    t.scope,
    t.decision,
    t.title,
    t.body,
    t.locale
  from public.moderation_decision_templates t
  where t.is_active = true
    and (p_scope is null or p_scope = '' or t.scope = p_scope)
  order by t.scope, t.decision, t.title;
$$;
create or replace function public.submit_moderation_appeal_v1(
  p_source_type text,
  p_source_id uuid,
  p_reason text,
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_appeal_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if coalesce(trim(p_source_type), '') not in ('report', 'claim') then
    return jsonb_build_object('ok', false, 'error', 'invalid_source_type');
  end if;
  if p_source_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_source_id');
  end if;
  if coalesce(trim(p_reason), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  if exists (
    select 1
    from public.moderation_appeals a
    where a.source_type = p_source_type
      and a.source_id = p_source_id
      and a.appellant_user_id = v_uid
      and a.status = 'pending'
  ) then
    return jsonb_build_object('ok', false, 'error', 'appeal_already_pending');
  end if;

  insert into public.moderation_appeals(
    source_type,
    source_id,
    appellant_user_id,
    reason,
    details
  )
  values (
    trim(p_source_type),
    p_source_id,
    v_uid,
    left(trim(p_reason), 120),
    nullif(trim(coalesce(p_details, '')), '')
  )
  returning id into v_appeal_id;

  return jsonb_build_object('ok', true, 'appeal_id', v_appeal_id);
end;
$$;
create or replace function public.admin_list_moderation_appeals_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  appeal_id uuid,
  source_type text,
  source_id uuid,
  appellant_user_id uuid,
  reason text,
  details text,
  status text,
  decision_note text,
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    a.id as appeal_id,
    a.source_type,
    a.source_id,
    a.appellant_user_id,
    a.reason,
    a.details,
    a.status,
    a.decision_note,
    a.decided_by,
    a.decided_at,
    a.created_at
  from public.moderation_appeals a
  where public.is_admin_or_community_mod_v1()
    and (p_status is null or p_status = '' or a.status = p_status)
  order by
    (a.status = 'pending') desc,
    a.created_at asc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;
create or replace function public.admin_decide_moderation_appeal_v1(
  p_appeal_id uuid,
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;
  if not public.is_admin_or_community_mod_v1() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;
  if p_appeal_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_appeal_id');
  end if;
  if p_decision not in ('approved', 'rejected') then
    return jsonb_build_object('ok', false, 'error', 'invalid_decision');
  end if;

  update public.moderation_appeals
  set
    status = p_decision,
    decision_note = nullif(trim(coalesce(p_note, '')), ''),
    decided_by = v_uid,
    decided_at = now(),
    updated_at = now()
  where id = p_appeal_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'appeal_not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.admin_list_reports_v4(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours double precision,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.durum in ('acik','inceleniyor')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    where public.is_admin_or_community_mod_v1()
      and (p_status is null or r.durum = p_status)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, durum, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by
    sla_breached desc,
    created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;
create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '48 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '48 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;
grant all on function public.get_app_role_v1() to authenticated;
grant all on function public.current_user_role_v1() to authenticated;
grant all on function public.is_admin_or_community_mod_v1() to authenticated, service_role;
grant all on function public.get_moderation_templates_v1(text) to authenticated, service_role;
grant all on function public.submit_moderation_appeal_v1(text, uuid, text, text) to authenticated, service_role;
grant all on function public.admin_list_moderation_appeals_v1(text, integer, integer) to authenticated, service_role;
grant all on function public.admin_decide_moderation_appeal_v1(uuid, text, text) to authenticated, service_role;
