-- search_nearby_businesses_v3 (lat/lng/radius/query/category/open_now/limit
-- overload, used by the Discovery "nearby" search) previously returned no
-- price or open-now data, so BusinessCardModel.medianPriceCents/isOpenNow
-- were always null and the Discovery price badge only ever showed a bare
-- "₺" tier symbol with no number. Add both columns:
--   - median_price_cents: median menu_items.price_cents for the business
--   - is_open_now: derived from business_hours for "today", null if no
--     hours row exists (matches the existing UI null-check convention)
-- CREATE OR REPLACE cannot change a function's return type (adding columns
-- to RETURNS TABLE), so drop this overload first.
drop function if exists public.search_nearby_businesses_v3(
  double precision, double precision, integer, text, text, boolean, integer
);

create or replace function public.search_nearby_businesses_v3(
  p_lat double precision,
  p_lng double precision,
  p_radius_km integer default 5,
  p_query text default null::text,
  p_category text default null::text,
  p_open_now boolean default false,
  p_limit integer default 30
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
  quality_score integer,
  median_price_cents integer,
  is_open_now boolean
)
language sql
stable security definer
set search_path to 'public'
as $function$
  with base as (
    select
      b.*,
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) as distance_km,
      (
        0
        + case when b.phone is not null and length(b.phone) >= 7 then 1 else 0 end
        + case when b.address is not null and length(b.address) >= 6 then 1 else 0 end
        + case when length(b.name) >= 6 then 1 else 0 end
        + case when lower(b.name) in ('restaurant','cafe','bar','pub','mekan','lokanta') then -3 else 2 end
      ) as quality_score,
      (
        select percentile_disc(0.5) within group (order by mi.price_cents)
        from public.menu_items mi
        where mi.business_id = b.id
          and mi.price_cents is not null
          and mi.price_cents > 0
      )::int as median_price_cents,
      case
        when h.business_id is null then null
        else (
          case extract(dow from now())
            when 1 then (h.mon_open is not null and current_time between h.mon_open and h.mon_close)
            when 2 then (h.tue_open is not null and current_time between h.tue_open and h.tue_close)
            when 3 then (h.wed_open is not null and current_time between h.wed_open and h.wed_close)
            when 4 then (h.thu_open is not null and current_time between h.thu_open and h.thu_close)
            when 5 then (h.fri_open is not null and current_time between h.fri_open and h.fri_close)
            when 6 then (h.sat_open is not null and current_time between h.sat_open and h.sat_close)
            when 0 then (h.sun_open is not null and current_time between h.sun_open and h.sun_close)
          end
        )
      end as is_open_now
    from public.businesses b
    left join public.business_hours h on h.business_id = b.id
    where b.is_active = true
      and b.lat is not null
      and b.lng is not null
      and (p_category is null or p_category = '' or b.category = p_category)
      and (
        p_query is null
        or p_query = ''
        or b.name ilike ('%' || p_query || '%')
        or coalesce(b.address,'') ilike ('%' || p_query || '%')
      )
      and (
        p_open_now = false
        or (
          h.business_id is not null
          and (
            case extract(dow from now())
              when 1 then (h.mon_open is not null and current_time between h.mon_open and h.mon_close)
              when 2 then (h.tue_open is not null and current_time between h.tue_open and h.tue_close)
              when 3 then (h.wed_open is not null and current_time between h.wed_open and h.wed_close)
              when 4 then (h.thu_open is not null and current_time between h.thu_open and h.thu_close)
              when 5 then (h.fri_open is not null and current_time between h.fri_open and h.fri_close)
              when 6 then (h.sat_open is not null and current_time between h.sat_open and h.sat_close)
              when 0 then (h.sun_open is not null and current_time between h.sun_open and h.sun_close)
            end
          )
        )
      )
  )
  select
    id, name, category, city, district, address, lat, lng,
    distance_km,
    quality_score,
    median_price_cents,
    is_open_now
  from base
  where distance_km <= greatest(1, p_radius_km)::double precision
  order by quality_score desc, distance_km asc
  limit p_limit;
$function$;
