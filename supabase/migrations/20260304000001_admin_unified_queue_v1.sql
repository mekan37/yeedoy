alter table public.business_submissions
  add column if not exists assigned_to uuid null references auth.users(id) on delete set null;

alter table public.business_submissions
  add column if not exists assigned_at timestamptz null;

create index if not exists idx_business_submissions_assigned_created
  on public.business_submissions (assigned_to, created_at desc);

create or replace function public.admin_queue_v1(
  p_type text default null,
  p_status text default null,
  p_city text default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_q text default null,
  p_sort_key text default 'created_at',
  p_sort_dir text default 'desc',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table(
  id uuid,
  item_type text,
  status text,
  created_at timestamptz,
  age_hours numeric,
  sla_hours integer,
  sla_breached boolean,
  title text,
  subtitle text,
  city text,
  district text,
  business_id uuid,
  business_name text,
  assigned_to uuid,
  assigned_at timestamptz,
  detail jsonb,
  total_count bigint
)
language sql
security definer
set search_path = public
as $$
  with unioned as (
    select
      s.id,
      'business_submission'::text as item_type,
      s.status::text as status,
      s.created_at,
      extract(epoch from (now() - s.created_at)) / 3600.0 as age_hours,
      24 as sla_hours,
      (s.status = 'new' and s.created_at < now() - interval '24 hours') as sla_breached,
      s.name as title,
      coalesce(nullif(trim(s.category), ''), '-') || ' • ' || coalesce(nullif(trim(s.address), ''), '-') as subtitle,
      s.city,
      s.district,
      null::uuid as business_id,
      s.name as business_name,
      s.assigned_to,
      s.assigned_at,
      jsonb_build_object(
        'submitted_by', s.submitted_by,
        'name', s.name,
        'city', s.city,
        'district', s.district,
        'category', s.category,
        'address', s.address,
        'phone', s.phone,
        'website', s.website,
        'admin_note', s.admin_note
      ) as detail
    from public.business_submissions s

    union all

    select
      r.id,
      case
        when r.target_type in ('business_media', 'menu_item_photo') then 'media_flag'
        else 'report'
      end as item_type,
      r.status::text as status,
      r.created_at,
      extract(epoch from (now() - r.created_at)) / 3600.0 as age_hours,
      24 as sla_hours,
      (r.status in ('open', 'reviewing') and r.created_at < now() - interval '24 hours') as sla_breached,
      coalesce(nullif(trim(r.reason), ''), 'report') as title,
      coalesce(nullif(trim(r.details), ''), coalesce(r.target_type, 'report')) as subtitle,
      b.city,
      b.district,
      r.business_id,
      b.name as business_name,
      r.assigned_to,
      r.assigned_at,
      jsonb_build_object(
        'reason', r.reason,
        'details', r.details,
        'target_type', r.target_type,
        'target_id', r.target_id,
        'reporter_id', r.user_id,
        'admin_note', r.admin_note,
        'handled_by', r.handled_by,
        'handled_at', r.handled_at
      ) as detail
    from public.reports r
    left join public.businesses b on b.id = r.business_id

    union all

    select
      c.id,
      'claim'::text as item_type,
      c.status::text as status,
      c.created_at,
      extract(epoch from (now() - c.created_at)) / 3600.0 as age_hours,
      48 as sla_hours,
      (c.status = 'pending' and c.created_at < now() - interval '48 hours') as sla_breached,
      coalesce(nullif(trim(c.full_name), ''), 'claim') as title,
      coalesce(nullif(trim(c.phone), ''), '-') as subtitle,
      b.city,
      b.district,
      c.business_id,
      b.name as business_name,
      c.handled_by as assigned_to,
      c.handled_at as assigned_at,
      jsonb_build_object(
        'full_name', c.full_name,
        'phone', c.phone,
        'evidence_url', c.evidence_url,
        'note', c.note,
        'admin_note', c.admin_note
      ) as detail
    from public.owner_claims c
    left join public.businesses b on b.id = c.business_id

    union all

    select
      s.id,
      'price_suggestion'::text as item_type,
      s.status::text as status,
      s.created_at,
      extract(epoch from (now() - s.created_at)) / 3600.0 as age_hours,
      48 as sla_hours,
      (s.status = 'pending' and s.created_at < now() - interval '48 hours') as sla_breached,
      coalesce(nullif(trim(mi.name), ''), 'price suggestion') as title,
      concat(
        coalesce(mi.price_cents, 0) / 100.0,
        ' -> ',
        coalesce(s.suggested_price_cents, 0) / 100.0,
        ' ',
        coalesce(s.currency, 'TRY')
      ) as subtitle,
      b.city,
      b.district,
      s.business_id,
      b.name as business_name,
      s.handled_by as assigned_to,
      s.handled_at as assigned_at,
      jsonb_build_object(
        'menu_item_id', s.menu_item_id,
        'menu_item_name', mi.name,
        'current_price_cents', mi.price_cents,
        'suggested_price_cents', s.suggested_price_cents,
        'currency', s.currency,
        'created_by', s.created_by,
        'quality_confidence', s.quality_confidence,
        'anomaly_score', s.anomaly_score,
        'anomaly_flags', s.anomaly_flags,
        'conflict_state', s.conflict_state,
        'conflict_variants_24h', s.conflict_variants_24h
      ) as detail
    from public.menu_item_price_suggestions s
    join public.menu_items mi on mi.id = s.menu_item_id
    join public.businesses b on b.id = s.business_id
  ),
  filtered as (
    select *
    from unioned q
    where public.is_admin()
      and (p_type is null or p_type = '' or q.item_type = p_type)
      and (p_status is null or p_status = '' or q.status = p_status)
      and (p_city is null or p_city = '' or coalesce(q.city, '') ilike ('%' || p_city || '%'))
      and (p_from is null or q.created_at >= p_from)
      and (p_to is null or q.created_at <= p_to)
      and (
        p_q is null
        or p_q = ''
        or coalesce(q.title, '') ilike ('%' || p_q || '%')
        or coalesce(q.subtitle, '') ilike ('%' || p_q || '%')
        or coalesce(q.business_name, '') ilike ('%' || p_q || '%')
        or coalesce(q.city, '') ilike ('%' || p_q || '%')
        or coalesce(q.district, '') ilike ('%' || p_q || '%')
      )
  ),
  ranked as (
    select
      f.*,
      count(*) over() as total_count
    from filtered f
    order by
      case when p_sort_key = 'item_type' and p_sort_dir = 'asc' then f.item_type end asc nulls last,
      case when p_sort_key = 'item_type' and p_sort_dir = 'desc' then f.item_type end desc nulls last,
      case when p_sort_key = 'title' and p_sort_dir = 'asc' then f.title end asc nulls last,
      case when p_sort_key = 'title' and p_sort_dir = 'desc' then f.title end desc nulls last,
      case when p_sort_key = 'city' and p_sort_dir = 'asc' then f.city end asc nulls last,
      case when p_sort_key = 'city' and p_sort_dir = 'desc' then f.city end desc nulls last,
      case when p_sort_key = 'status' and p_sort_dir = 'asc' then f.status end asc nulls last,
      case when p_sort_key = 'status' and p_sort_dir = 'desc' then f.status end desc nulls last,
      case when p_sort_key = 'age_hours' and p_sort_dir = 'asc' then f.age_hours end asc nulls last,
      case when p_sort_key = 'age_hours' and p_sort_dir = 'desc' then f.age_hours end desc nulls last,
      case when p_sort_key = 'created_at' and p_sort_dir = 'asc' then f.created_at end asc nulls last,
      case when p_sort_key = 'created_at' and p_sort_dir = 'desc' then f.created_at end desc nulls last,
      f.created_at desc
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0)
  )
  select *
  from ranked;
$$;

create or replace function public.admin_queue_assign_v1(
  p_item_type text,
  p_item_id uuid,
  p_assign_to_me boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_item_id is null then
    raise exception 'missing_item_id';
  end if;

  if p_item_type in ('report', 'media_flag') then
    if p_assign_to_me then
      perform public.admin_assign_report_v1(p_item_id);
    else
      perform public.admin_unassign_report_v1(p_item_id);
    end if;
  elsif p_item_type = 'claim' then
    if p_assign_to_me then
      perform public.admin_assign_owner_claim_v1(p_item_id);
    else
      perform public.admin_unassign_owner_claim_v1(p_item_id);
    end if;
  elsif p_item_type = 'price_suggestion' then
    update public.menu_item_price_suggestions
    set
      handled_by = case when p_assign_to_me then v_uid else null end,
      handled_at = case when p_assign_to_me then now() else null end
    where id = p_item_id;

    if not found then
      return jsonb_build_object('ok', false, 'error', 'not_found');
    end if;

    perform public.log_admin_action_v1(
      case when p_assign_to_me then 'price_suggestion.assigned' else 'price_suggestion.unassigned' end,
      'menu_item_price_suggestions',
      p_item_id,
      jsonb_build_object('assigned_to', case when p_assign_to_me then v_uid else null end)
    );
  elsif p_item_type = 'business_submission' then
    update public.business_submissions
    set
      assigned_to = case when p_assign_to_me then v_uid else null end,
      assigned_at = case when p_assign_to_me then now() else null end
    where id = p_item_id;

    if not found then
      return jsonb_build_object('ok', false, 'error', 'not_found');
    end if;

    perform public.log_admin_action_v1(
      case when p_assign_to_me then 'business_submission.assigned' else 'business_submission.unassigned' end,
      'business_submissions',
      p_item_id,
      jsonb_build_object('assigned_to', case when p_assign_to_me then v_uid else null end)
    );
  else
    raise exception 'unsupported_item_type';
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.admin_queue_v1(
  text,
  text,
  text,
  timestamptz,
  timestamptz,
  text,
  text,
  text,
  integer,
  integer
) to authenticated, service_role;

grant execute on function public.admin_queue_assign_v1(
  text,
  uuid,
  boolean
) to authenticated, service_role;
