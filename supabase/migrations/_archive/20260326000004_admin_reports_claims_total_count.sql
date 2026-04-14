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
  sla_breached boolean,
  total_count bigint
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
      (extract(epoch from (now() - r.created_at)) / 3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open', 'reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin_or_community_mod_v1()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned = 'me' and r.assigned_to = auth.uid())
        or (p_assigned = 'unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%' || p_q || '%')
        or r.details ilike ('%' || p_q || '%')
        or r.admin_note ilike ('%' || p_q || '%')
      )
  ),
  filtered as (
    select
      id,
      created_at,
      status,
      reason,
      details,
      user_id,
      business_id,
      review_id,
      menu_item_photo_id,
      target_type,
      target_id,
      assigned_to,
      assigned_at,
      handled_by,
      handled_at,
      admin_note,
      age_hours,
      sla_breached,
      count(*) over ()::bigint as total_count
    from base
    where (not p_sla_only) or sla_breached
  )
  select
    id,
    created_at,
    status,
    reason,
    details,
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    assigned_to,
    assigned_at,
    handled_by,
    handled_at,
    admin_note,
    age_hours,
    sla_breached,
    total_count
  from filtered
  order by sla_breached desc, created_at desc
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
  auto_moderated boolean,
  total_count bigint
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with base as (
    select
      c.id as claim_id,
      c.status::text as status,
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
  ),
  filtered as (
    select
      claim_id,
      status,
      created_at,
      age_days,
      sla_breached,
      business_id,
      full_name,
      phone,
      evidence_url,
      note,
      admin_note,
      assigned_to,
      assigned_at,
      auto_moderated,
      count(*) over ()::bigint as total_count
    from base
  )
  select
    claim_id,
    status,
    created_at,
    age_days,
    sla_breached,
    business_id,
    full_name,
    phone,
    evidence_url,
    note,
    admin_note,
    assigned_to,
    assigned_at,
    auto_moderated,
    total_count
  from filtered
  order by (status = 'pending') desc, created_at asc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$function$;
