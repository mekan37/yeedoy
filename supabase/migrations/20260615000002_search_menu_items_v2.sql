-- search_menu_items_v2: additive version of search_menu_items_v1 that also
-- returns image_url, is_today_special and special_note so the redesigned
-- Yemekler tab can render images and a "Günün lezzeti" banner.
-- v1 is left untouched (still used by the diet-aware wrapper).
create or replace function public.search_menu_items_v2(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_km double precision default 5,
  p_q text default null::text,
  p_is_vegan boolean default false,
  p_is_vegetarian boolean default false,
  p_is_gluten_free boolean default false,
  p_is_lactose_free boolean default false,
  p_is_halal boolean default false,
  p_max_calories integer default null::integer,
  p_verified_price_only boolean default false,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table(
  menu_item_id uuid,
  item_name text,
  item_description text,
  price_cents integer,
  currency text,
  calories integer,
  is_vegan boolean,
  is_vegetarian boolean,
  is_gluten_free boolean,
  is_lactose_free boolean,
  is_halal boolean,
  business_id uuid,
  business_name text,
  address text,
  city text,
  district text,
  distance_km double precision,
  price_status text,
  ok_30d integer,
  bad_30d integer,
  image_url text,
  is_today_special boolean,
  special_note text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with items as (
    select
      mi.id as menu_item_id,
      mi.name as item_name,
      mi.description as item_description,
      mi.price_cents,
      mi.currency,
      null::integer as calories,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'vegan'
      ) as is_vegan,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('vegetarian','vejetaryen')
      ) as is_vegetarian,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('gluten_free','glutensiz')
      ) as is_gluten_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('lactose_free','laktozsuz')
      ) as is_lactose_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'halal'
      ) as is_halal,
      mi.business_id,
      mi.image_url,
      mi.is_today_special,
      mi.special_note
    from public.menu_items mi
    where mi.is_available = true
      and (not p_is_vegan or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'vegan'
      ))
      and (not p_is_vegetarian or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('vegetarian','vejetaryen')
      ))
      and (not p_is_gluten_free or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('gluten_free','glutensiz')
      ))
      and (not p_is_lactose_free or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('lactose_free','laktozsuz')
      ))
      and (not p_is_halal or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'halal'
      ))
      and (
        p_q is null
        or lower(mi.name) ilike ('%'||lower(p_q)||'%')
        or lower(coalesce(mi.description,'')) ilike ('%'||lower(p_q)||'%')
      )
  ),
  price as (
    select
      v.menu_item_id,
      count(*) filter (where v.created_at >= now() - interval '30 days') as total_30d,
      count(*) filter (where v.vote=1 and v.created_at >= now() - interval '30 days') as ok_30d,
      count(*) filter (where v.vote=-1 and v.created_at >= now() - interval '30 days') as bad_30d
    from public.menu_item_price_votes v
    group by v.menu_item_id
  ),
  joined as (
    select
      i.*,
      b.name as business_name,
      b.address,
      b.city,
      b.district,
      (
        6371.0 * acos(
          greatest(-1, least(1,
            cos(radians(p_user_lat)) * cos(radians(b.lat)) *
            cos(radians(b.lng) - radians(p_user_lng)) +
            sin(radians(p_user_lat)) * sin(radians(b.lat))
          ))
        )
      ) as distance_km,
      coalesce(p.ok_30d,0) as ok_30d,
      coalesce(p.bad_30d,0) as bad_30d,
      coalesce(p.total_30d,0) as total_30d,
      case
        when coalesce(p.total_30d,0) = 0 then 'unknown'
        when coalesce(p.ok_30d,0) >= 3 and coalesce(p.ok_30d,0) >= coalesce(p.bad_30d,0)*2 then 'verified'
        when coalesce(p.bad_30d,0) >= 3 and coalesce(p.bad_30d,0) > coalesce(p.ok_30d,0) then 'outdated'
        else 'mixed'
      end as price_status
    from items i
    join public.businesses b on b.id = i.business_id
    left join price p on p.menu_item_id = i.menu_item_id
    where b.lat is not null and b.lng is not null
  )
  select
    menu_item_id,
    item_name,
    item_description,
    price_cents,
    currency,
    calories,
    is_vegan,
    is_vegetarian,
    is_gluten_free,
    is_lactose_free,
    is_halal,
    business_id,
    business_name,
    address,
    city,
    district,
    distance_km,
    price_status,
    ok_30d,
    bad_30d,
    image_url,
    is_today_special,
    special_note
  from joined
  where distance_km <= p_radius_km
    and (not p_verified_price_only or price_status = 'verified')
  order by distance_km asc, price_status desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$;

revoke all on function public.search_menu_items_v2(
  double precision, double precision, double precision, text,
  boolean, boolean, boolean, boolean, boolean, integer, boolean, integer, integer
) from public;

grant execute on function public.search_menu_items_v2(
  double precision, double precision, double precision, text,
  boolean, boolean, boolean, boolean, boolean, integer, boolean, integer, integer
) to anon, authenticated, service_role;

comment on function public.search_menu_items_v2 is
  'Search menu items with diet filters, price status and image/today''s-special fields. Called by: lib/features/menus/data/menu_item_search_repository.dart.';
