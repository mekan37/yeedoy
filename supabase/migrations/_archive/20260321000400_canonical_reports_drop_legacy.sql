-- Canonicalize reports RPC surface and remove legacy function versions.
-- Keep only:
--   - admin_list_reports_v5
--   - admin_update_report_v2
--   - admin_bulk_update_reports_status_v2

create or replace function public.admin_update_report_v2(
  p_report_id uuid,
  p_status text,
  p_admin_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.update',
    'reports',
    p_report_id,
    jsonb_build_object('status', v_status, 'admin_note', p_admin_note)
  );
end;
$$;
create or replace function public.admin_bulk_update_reports_status_v2(
  p_report_ids uuid[],
  p_status text,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = coalesce(p_admin_note, admin_note)
  where id = any(p_report_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'report.bulk_update',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$$;
create or replace function public.admin_list_reports_v5(
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
  status text,
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
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin_or_community_mod_v1()
      and (p.status_filter is null or r.status = p.status_filter)
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
    id, created_at, status, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;
drop function if exists public.admin_list_reports_v4(text, integer, integer, text, text, boolean);
drop function if exists public.admin_list_reports_v3(text, integer, integer, text, text, boolean);
drop function if exists public.admin_list_reports_v2(text, integer, integer, text, text);
drop function if exists public.admin_list_reports_v1(text, integer, integer, text);
drop function if exists public.admin_update_report_v1(uuid, text, text);
drop function if exists public.admin_bulk_update_reports_status_v1(uuid[], text, text);
