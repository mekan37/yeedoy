create or replace function public.get_district_top_views_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  views_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  views as (
    select
      business_id,
      count(*) filter (
        where created_at >= now() - interval '7 days'
      ) as views_7d
    from public.analytics_events
    where event_name = 'menu_view'
    group by business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(v.views_7d, 0)::int as views_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  left join views v on v.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by v.views_7d desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_top_views_v1(text, text, text, int) to anon;
grant all on function public.get_district_top_views_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_top_views_v1(text, text, text, int) to service_role;

create or replace function public.get_district_price_changes_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  price_changes_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  changes as (
    select
      mi.business_id,
      count(*) filter (
        where h.created_at >= now() - interval '7 days'
      ) as changes_7d
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    group by mi.business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(c.changes_7d, 0)::int as price_changes_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  left join changes c on c.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by c.changes_7d desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_price_changes_v1(text, text, text, int) to anon;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to service_role;

create or replace function public.get_district_night_favorites_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  favorites_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  favorites as (
    select business_id, count(*) as favorites_count
    from public.business_follows
    group by business_id
  ),
  night_open as (
    select bh.business_id
    from public.business_hours bh
    where (
      bh.mon_open is not null and bh.mon_close is not null and
      (bh.mon_close >= time '23:00' or bh.mon_close < bh.mon_open)
    ) or (
      bh.tue_open is not null and bh.tue_close is not null and
      (bh.tue_close >= time '23:00' or bh.tue_close < bh.tue_open)
    ) or (
      bh.wed_open is not null and bh.wed_close is not null and
      (bh.wed_close >= time '23:00' or bh.wed_close < bh.wed_open)
    ) or (
      bh.thu_open is not null and bh.thu_close is not null and
      (bh.thu_close >= time '23:00' or bh.thu_close < bh.thu_open)
    ) or (
      bh.fri_open is not null and bh.fri_close is not null and
      (bh.fri_close >= time '23:00' or bh.fri_close < bh.fri_open)
    ) or (
      bh.sat_open is not null and bh.sat_close is not null and
      (bh.sat_close >= time '23:00' or bh.sat_close < bh.sat_open)
    ) or (
      bh.sun_open is not null and bh.sun_close is not null and
      (bh.sun_close >= time '23:00' or bh.sun_close < bh.sun_open)
    )
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(f.favorites_count, 0)::int as favorites_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  join night_open n on n.business_id = bws.id
  left join favorites f on f.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by f.favorites_count desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_night_favorites_v1(text, text, text, int) to anon;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to service_role;

