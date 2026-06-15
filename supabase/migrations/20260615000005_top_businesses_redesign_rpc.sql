drop function if exists public.get_top_businesses_period_v1(text, integer, integer);

create or replace function public.get_top_businesses_period_v1(
  p_period text,
  p_limit integer default 6,
  p_min_reviews integer default 0,
  p_user_lat double precision default null,
  p_user_lng double precision default null
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  avg_rating double precision,
  reviews_count integer,
  score double precision,
  image_url text,
  lat double precision,
  lng double precision,
  distance_km double precision
)
language sql
security definer
set search_path to 'public'
as $function$
  with bounds as (
    select
      case
        when p_period = 'month' then now() - interval '30 days'
        else now() - interval '7 days'
      end as since_at
  ),
  agg as (
    select
      r.business_id as id,
      count(*)::int as reviews_count,
      avg(r.rating)::double precision as avg_rating
    from public.reviews r, bounds b
    where r.status = 'approved'
      and r.created_at >= b.since_at
    group by r.business_id
  )
  select
    b.id,
    b.name,
    b.category,
    b.city,
    b.district,
    coalesce(a.avg_rating, 0)::double precision as avg_rating,
    coalesce(a.reviews_count, 0) as reviews_count,
    (coalesce(a.avg_rating, 0) * ln(1 + coalesce(a.reviews_count, 0)))::double precision as score,
    coalesce(b.cover_url, b.logo_url) as image_url,
    b.lat,
    b.lng,
    case
      when p_user_lat is null or p_user_lng is null or b.lat is null or b.lng is null then null
      else (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_user_lat) / 2.0)), 2)
          + cos(radians(p_user_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_user_lng) / 2.0)), 2)
        )
      ))::double precision
    end as distance_km
  from public.businesses b
  left join agg a on a.id = b.id
  where b.is_active = true
    and coalesce(a.reviews_count, 0) >= p_min_reviews
  order by score desc, coalesce(a.reviews_count, 0) desc, b.id
  limit greatest(p_limit, 0);
$function$;
