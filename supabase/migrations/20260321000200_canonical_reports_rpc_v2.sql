-- Canonical report RPC surface.
-- Adds status-based wrappers without breaking existing p_durum/v3-v4 callers.

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
begin
  perform public.admin_update_report_v1(
    p_report_id => p_report_id,
    p_durum => p_status,
    p_admin_note => p_admin_note
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
begin
  return public.admin_bulk_update_reports_status_v1(
    p_report_ids => p_report_ids,
    p_durum => p_status,
    p_admin_note => p_admin_note
  );
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
  select
    r.id,
    r.created_at,
    r.durum as status,
    r.reason,
    r.details,
    r.user_id,
    r.business_id,
    r.review_id,
    r.menu_item_photo_id,
    r.target_type,
    r.target_id,
    r.assigned_to,
    r.assigned_at,
    r.handled_by,
    r.handled_at,
    r.admin_note,
    r.age_hours,
    r.sla_breached
  from public.admin_list_reports_v4(
    p_status => p_status,
    p_limit => p_limit,
    p_offset => p_offset,
    p_q => p_q,
    p_assigned => p_assigned,
    p_sla_only => p_sla_only
  ) as r;
$$;
