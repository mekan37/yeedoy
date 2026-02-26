alter table public.reports
  add column if not exists menu_item_photo_id uuid;

alter table public.reports
  drop constraint if exists reports_target_type_check;

alter table public.reports
  add constraint reports_target_type_check
  check (
    target_type = any (
      array['business'::text, 'review'::text, 'menu_item_photo'::text]
    )
  );

create or replace function public.submit_report_v1(
  p_business_id uuid default null,
  p_review_id uuid default null,
  p_menu_item_photo_id uuid default null,
  p_reason text default 'other',
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
  v_target_type text;
  v_target_id uuid;
  v_business_id uuid;
  v_review_id uuid;
  v_photo_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null and p_review_id is null and p_menu_item_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  if p_menu_item_photo_id is not null then
    v_target_type := 'menu_item_photo';
    v_target_id := p_menu_item_photo_id;
    v_photo_id := p_menu_item_photo_id;
    select business_id into v_business_id
    from public.menu_item_photos
    where id = p_menu_item_photo_id;
    if v_business_id is null then
      return jsonb_build_object('ok', false, 'error', 'photo_not_found');
    end if;
  elsif p_review_id is not null then
    v_target_type := 'review';
    v_target_id := p_review_id;
    v_review_id := p_review_id;
  else
    v_target_type := 'business';
    v_target_id := p_business_id;
    v_business_id := p_business_id;
  end if;

  if v_target_type = 'business' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = v_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  elsif v_target_type = 'review' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = v_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and menu_item_photo_id = v_photo_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    reason,
    details
  )
  values (
    v_uid,
    v_business_id,
    v_review_id,
    v_photo_id,
    v_target_type,
    v_target_id,
    coalesce(nullif(trim(p_reason), ''), 'other'),
    nullif(trim(p_details), '')
  )
  returning id into v_report_id;

  return jsonb_build_object('ok', true, 'report_id', v_report_id);
end;
$$;

grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to anon;
grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to authenticated;
grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to service_role;

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
    where public.is_admin()
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

grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to anon;
grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to authenticated;
grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to service_role;
