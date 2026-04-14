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
  with business_submission_base as (
    select
      s.*,
      array_remove(
        array[
          case when coalesce(nullif(trim(s.address), ''), '') = '' then 'address' end,
          case when coalesce(nullif(trim(s.phone), ''), '') = '' then 'phone' end,
          case when coalesce(nullif(trim(s.website), ''), '') = '' then 'website' end,
          case when coalesce(nullif(trim(s.category), ''), '') = '' then 'category' end
        ],
        null
      ) as missing_fields
    from public.business_submissions s
  ),
  report_base as (
    select
      r.*,
      b.city,
      b.district,
      b.name as business_name,
      coalesce(usa.risk_score, 0) as reporter_risk_score,
      case
        when r.user_id is null then 0
        when to_regprocedure('public.get_user_reputation_score_v2(uuid)') is null then 0
        else coalesce(public.get_user_reputation_score_v2(r.user_id), 0)
      end as reporter_reputation
    from public.reports r
    left join public.businesses b on b.id = r.business_id
    left join public.user_safety_actions usa on usa.user_id = r.user_id
  ),
  claim_base as (
    select
      c.*,
      b.city,
      b.district,
      b.name as business_name,
      coalesce(usa.risk_score, 0) as claimant_risk_score,
      coalesce(usa.auto_pending_until > now(), false) as claimant_auto_pending,
      case
        when c.user_id is null then 0
        when to_regprocedure('public.get_user_reputation_score_v2(uuid)') is null then 0
        else coalesce(public.get_user_reputation_score_v2(c.user_id), 0)
      end as claimant_reputation
    from public.owner_claims c
    left join public.businesses b on b.id = c.business_id
    left join public.user_safety_actions usa on usa.user_id = c.user_id
  ),
  price_suggestion_base as (
    select
      s.*,
      mi.name as menu_item_name,
      mi.price_cents as current_price_cents,
      b.city,
      b.district,
      b.name as business_name,
      coalesce(bq.score, 0) as business_quality_score,
      coalesce(usa.risk_score, 0) as created_by_risk_score,
      case
        when s.created_by is null then 0
        when to_regprocedure('public.get_user_reputation_score_v2(uuid)') is null then 0
        else coalesce(public.get_user_reputation_score_v2(s.created_by), 0)
      end as created_by_reputation
    from public.menu_item_price_suggestions s
    join public.menu_items mi on mi.id = s.menu_item_id
    join public.businesses b on b.id = s.business_id
    left join public.business_quality_score_v1 bq on bq.business_id = s.business_id
    left join public.user_safety_actions usa on usa.user_id = s.created_by
  ),
  unioned as (
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
        'admin_note', s.admin_note,
        'missing_fields', to_jsonb(s.missing_fields),
        'missing_field_count', cardinality(s.missing_fields),
        'review_reason', case
          when cardinality(s.missing_fields) >= 2 then 'missing_submission_data'
          else 'manual_review'
        end
      ) as detail
    from business_submission_base s

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
      r.city,
      r.district,
      r.business_id,
      r.business_name,
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
        'handled_at', r.handled_at,
        'reporter_reputation', r.reporter_reputation,
        'reporter_risk_score', r.reporter_risk_score,
        'auto_moderated', coalesce(r.auto_moderated, false),
        'review_reason', case
          when coalesce(r.auto_moderated, false) then 'grey_area'
          when coalesce(r.reporter_risk_score, 0) >= 50 then 'risky_actor'
          else 'manual_review'
        end
      ) as detail
    from report_base r

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
      c.city,
      c.district,
      c.business_id,
      c.business_name,
      c.handled_by as assigned_to,
      c.handled_at as assigned_at,
      jsonb_build_object(
        'full_name', c.full_name,
        'phone', c.phone,
        'evidence_url', c.evidence_url,
        'note', c.note,
        'admin_note', c.admin_note,
        'claimant_reputation', c.claimant_reputation,
        'claimant_risk_score', c.claimant_risk_score,
        'claimant_auto_pending', c.claimant_auto_pending,
        'review_reason', case
          when coalesce(nullif(trim(c.evidence_url), ''), '') = '' then 'missing_evidence'
          when c.claimant_auto_pending or coalesce(c.claimant_risk_score, 0) >= 50 then 'claimant_auto_pending'
          else 'manual_review'
        end
      ) as detail
    from claim_base c

    union all

    select
      s.id,
      'price_suggestion'::text as item_type,
      s.status::text as status,
      s.created_at,
      extract(epoch from (now() - s.created_at)) / 3600.0 as age_hours,
      48 as sla_hours,
      (s.status = 'pending' and s.created_at < now() - interval '48 hours') as sla_breached,
      coalesce(nullif(trim(s.menu_item_name), ''), 'price suggestion') as title,
      concat(
        coalesce(s.current_price_cents, 0) / 100.0,
        ' -> ',
        coalesce(s.suggested_price_cents, 0) / 100.0,
        ' ',
        coalesce(s.currency, 'TRY')
      ) as subtitle,
      s.city,
      s.district,
      s.business_id,
      s.business_name,
      s.handled_by as assigned_to,
      s.handled_at as assigned_at,
      jsonb_build_object(
        'menu_item_id', s.menu_item_id,
        'menu_item_name', s.menu_item_name,
        'current_price_cents', s.current_price_cents,
        'suggested_price_cents', s.suggested_price_cents,
        'currency', s.currency,
        'created_by', s.created_by,
        'quality_confidence', s.quality_confidence,
        'anomaly_score', s.anomaly_score,
        'anomaly_flags', s.anomaly_flags,
        'conflict_state', s.conflict_state,
        'conflict_variants_24h', s.conflict_variants_24h,
        'created_by_reputation', s.created_by_reputation,
        'created_by_risk_score', s.created_by_risk_score,
        'business_quality_score', s.business_quality_score,
        'review_reason', case
          when s.conflict_state = 'queued' and coalesce(s.anomaly_score, 0) >= 0.5 then 'conflict_and_anomaly'
          when s.conflict_state = 'queued' then 'price_conflict'
          when coalesce(s.anomaly_score, 0) >= 0.5 then 'anomaly_queue'
          when coalesce(s.quality_confidence, 1) < 0.65 then 'low_confidence'
          else 'manual_review'
        end
      ) as detail
    from price_suggestion_base s
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
$$;;
