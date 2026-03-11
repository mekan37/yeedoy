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
