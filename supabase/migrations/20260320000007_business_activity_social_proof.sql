create or replace function public.get_business_activity_v1(
  p_business_id uuid,
  p_limit integer default 10
)
returns table(
  activity_id uuid,
  activity_type text,
  meta jsonb,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with base as (
    select
      a.id as activity_id,
      a.type as activity_type,
      a.meta,
      a.created_at
    from public.business_activity_log a
    where a.business_id = p_business_id
  ),
  menu_views as (
    select count(*)::int as count_today
    from public.analytics_events e
    where e.business_id = p_business_id
      and e.event_name = 'menu_view'
      and e.created_at >= date_trunc('day', now())
  ),
  ranked as (
    select
      b.id,
      b.district,
      coalesce(q.score, 0) as score,
      rank() over (
        partition by b.district
        order by coalesce(q.score, 0) desc, b.id
      ) as rank
    from public.businesses b
    left join public.business_quality_score_v1 q
      on q.business_id = b.id
    where b.district is not null
      and b.is_active = true
  ),
  district_rank as (
    select r.rank, r.district
    from ranked r
    where r.id = p_business_id
  ),
  synthetic as (
    select
      '00000000-0000-0000-0000-000000000000'::uuid as activity_id,
      'menu_views' as activity_type,
      jsonb_build_object('count_today', mv.count_today) as meta,
      now() as created_at
    from menu_views mv
    where mv.count_today > 0

    union all

    select
      '00000000-0000-0000-0000-000000000000'::uuid as activity_id,
      'district_rank' as activity_type,
      jsonb_build_object('rank', dr.rank, 'district', dr.district) as meta,
      now() as created_at
    from district_rank dr
    where dr.rank is not null
  )
  select *
  from (
    select * from base
    union all
    select * from synthetic
  ) s
  order by created_at desc
  limit greatest(p_limit, 0);
$function$;
