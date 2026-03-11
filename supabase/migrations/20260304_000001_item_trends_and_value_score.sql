-- Business item trends (last 7 days)
create or replace view public.business_item_trends_v1 as
with price_votes as (
  select
    v.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '7 days'
    ) as price_votes_7d
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
photo_votes as (
  select
    p.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '7 days'
    ) as photo_votes_7d
  from public.menu_item_photo_votes v
  join public.menu_item_photos p on p.id = v.photo_id
  group by p.menu_item_id
),
price_changes as (
  select
    h.menu_item_id,
    count(*) filter (
      where h.created_at >= now() - interval '7 days'
    ) as price_changes_7d
  from public.menu_item_price_history h
  group by h.menu_item_id
)
select
  mi.id as menu_item_id,
  mi.business_id,
  coalesce(pv.price_votes_7d, 0) as price_votes_7d,
  coalesce(phv.photo_votes_7d, 0) as photo_votes_7d,
  0::int as menu_item_views_7d,
  coalesce(pc.price_changes_7d, 0) as price_changes_7d,
  (
    coalesce(pv.price_votes_7d, 0) * 3
    + coalesce(phv.photo_votes_7d, 0) * 2
    + coalesce(pc.price_changes_7d, 0)
  )::int as score
from public.menu_items mi
left join price_votes pv on pv.menu_item_id = mi.id
left join photo_votes phv on phv.menu_item_id = mi.id
left join price_changes pc on pc.menu_item_id = mi.id;
create or replace function public.get_business_trending_items_v1(
  p_business_id uuid,
  p_limit int default 6
)
returns table(
  menu_item_id uuid,
  item_name text,
  price_cents int,
  currency text,
  score int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents,
    mi.currency,
    t.score
  from public.business_item_trends_v1 t
  join public.menu_items mi on mi.id = t.menu_item_id
  where t.business_id = p_business_id
  order by t.score desc, mi.updated_at desc nulls last, mi.created_at desc
  limit p_limit;
$$;
-- Menu item value score (F/P)
create or replace view public.menu_item_value_score_v1 as
with votes_all as (
  select
    v.menu_item_id,
    count(*) filter (where v.vote = 1) as pos_votes,
    count(*) as total_votes
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
votes_30d as (
  select
    v.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '30 days'
    ) as pos_votes_30d,
    count(*) filter (
      where v.created_at >= now() - interval '30 days'
    ) as total_votes_30d
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
price_changes_30d as (
  select
    h.menu_item_id,
    count(*) filter (
      where h.created_at >= now() - interval '30 days'
    ) as changes_30d
  from public.menu_item_price_history h
  group by h.menu_item_id
)
select
  mi.id as menu_item_id,
  coalesce(va.pos_votes::float / nullif(va.total_votes, 0), 0) as verified_ratio,
  coalesce(v30.pos_votes_30d::float / nullif(v30.total_votes_30d, 0), 0) as recent_positive_ratio,
  (1 - least(coalesce(pc.changes_30d, 0) / 5.0, 1.0))::float as price_stability,
  coalesce(pc.changes_30d, 0) as price_changes_30d,
  (
    coalesce(va.pos_votes::float / nullif(va.total_votes, 0), 0) * 0.4
    + coalesce(v30.pos_votes_30d::float / nullif(v30.total_votes_30d, 0), 0) * 0.3
    + (1 - least(coalesce(pc.changes_30d, 0) / 5.0, 1.0)) * 0.3
  )::float as value_score
from public.menu_items mi
left join votes_all va on va.menu_item_id = mi.id
left join votes_30d v30 on v30.menu_item_id = mi.id
left join price_changes_30d pc on pc.menu_item_id = mi.id;
create or replace function public.get_menu_item_value_score_v1(
  p_menu_item_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'score', coalesce(v.value_score, 0),
    'breakdown', jsonb_build_object(
      'verified_ratio', coalesce(v.verified_ratio, 0),
      'recent_positive_ratio', coalesce(v.recent_positive_ratio, 0),
      'price_stability', coalesce(v.price_stability, 0),
      'price_changes_30d', coalesce(v.price_changes_30d, 0)
    )
  )
  from public.menu_item_value_score_v1 v
  where v.menu_item_id = p_menu_item_id;
$$;
