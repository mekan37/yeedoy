-- Migration: 20260422000005_reviews_sort_verified
-- Purpose: Adds 'verified' sort option to get_business_reviews_v3, ordering
--          verified_visit=true reviews first, then by created_at desc.
--          Also adds the verified_visit column to the RPC output.
--
-- The verified_visit flag is computed by _review_verified_visit() SECURITY DEFINER
-- helper added in migration 20260422000001.

-- review_ratings tablosu yoksa oluştur (migration güvenliği — 2026-07-23'te
-- bulundu: bu tablo hiçbir migration'da INSERT edilmiyor, sadece LEFT JOIN
-- ile okunuyor, ve 00000000000000_base_schema.sql'e hiç dahil edilmemiş
-- olabilir; her review için opsiyonel alt-puanlar tutar).
CREATE TABLE IF NOT EXISTS review_ratings (
  review_id      uuid PRIMARY KEY REFERENCES reviews(id) ON DELETE CASCADE,
  r_taste        integer,
  r_service      integer,
  r_price_value  integer,
  r_cleanliness  integer,
  r_atmosphere   integer
);

DROP FUNCTION IF EXISTS public.get_business_reviews_v3(uuid, text, integer, integer);
CREATE OR REPLACE FUNCTION public.get_business_reviews_v3(
  p_business_id  uuid,
  p_sort         text    DEFAULT 'newest',
  p_limit        integer DEFAULT 20,
  p_offset       integer DEFAULT 0
)
RETURNS TABLE (
  id              uuid,
  business_id     uuid,
  user_id         uuid,
  rating          integer,
  title           text,
  content         text,
  helpful_count   integer,
  created_at      timestamptz,
  status          text,
  quality_score   numeric,
  verified_visit  boolean,
  -- multi-criterion ratings (nullable for older reviews)
  r_taste         integer,
  r_service       integer,
  r_price_value   integer,
  r_cleanliness   integer,
  r_atmosphere    integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH base AS (
    SELECT
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      COALESCE(r.helpful_count, 0)::integer          AS helpful_count,
      r.created_at,
      COALESCE(r.status, 'published')                AS status,
      COALESCE(r.helpful_count, 0)::numeric          AS quality_score,
      COALESCE(_review_verified_visit(
        r.user_id,
        r.business_id::uuid,
        r.created_at::date
      ), false)                                       AS verified_visit,
      rr.r_taste,
      rr.r_service,
      rr.r_price_value,
      rr.r_cleanliness,
      rr.r_atmosphere
    FROM reviews r
    LEFT JOIN review_ratings rr ON rr.review_id = r.id
    WHERE r.business_id = p_business_id
      AND COALESCE(r.status, 'published') NOT IN ('rejected', 'spam')
  )
  SELECT
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score,
    b.verified_visit,
    b.r_taste,
    b.r_service,
    b.r_price_value,
    b.r_cleanliness,
    b.r_atmosphere
  FROM base b
  ORDER BY
    -- verified: verified_visit reviews first, then newest
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'verified'
      THEN (b.verified_visit)::int ELSE NULL END DESC,
    -- helpful: quality score + helpful_count desc, then newest
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'helpful'
      THEN b.quality_score ELSE NULL END DESC,
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'helpful'
      THEN b.helpful_count ELSE NULL END DESC,
    b.created_at DESC
  LIMIT  greatest(p_limit, 1)
  OFFSET greatest(p_offset, 0);
$$;

GRANT EXECUTE ON FUNCTION public.get_business_reviews_v3(uuid, text, integer, integer)
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.get_business_reviews_v3(uuid, text, integer, integer) IS
  'Business reviews with multi-criterion ratings and verified_visit flag.
   p_sort: newest | helpful | verified. verified puts checked-in reviews first.';
