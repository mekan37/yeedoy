-- Expose businesses.is_verified through businesses_with_stats so clients can
-- show a real "verified business" badge instead of a hardcoded one.
create or replace view public.businesses_with_stats
with (security_invoker = true) as
select
  b.id,
  b.name,
  b.category,
  b.description,
  b.phone,
  b.address,
  b.city,
  b.district,
  b.lat,
  b.lng,
  b.is_active,
  b.is_verified,
  b.created_at,
  coalesce(r.reviews_count, 0) as reviews_count,
  (coalesce(r.avg_rating, (0)::numeric))::numeric(3, 2) as avg_rating
from public.businesses b
left join (
  select
    reviews.business_id,
    (count(*) filter (where reviews.status = 'approved'::text))::integer as reviews_count,
    avg(reviews.rating) filter (where reviews.status = 'approved'::text) as avg_rating
  from public.reviews
  group by reviews.business_id
) r on r.business_id = b.id;
