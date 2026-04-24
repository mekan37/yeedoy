-- get_business_rating_summary_v2
-- Extends v1 with per-star distribution from business_stats.
-- Falls back to 0 for all star counts when no stats row exists.

CREATE OR REPLACE FUNCTION public.get_business_rating_summary_v2(
  p_business_id uuid
)
RETURNS TABLE (
  business_id          uuid,
  rating_count         integer,
  avg_overall_rating   numeric,
  avg_taste_rating     numeric,
  avg_service_speed_rating    numeric,
  avg_price_performance_rating numeric,
  avg_cleanliness_rating      numeric,
  avg_atmosphere_rating       numeric,
  rating_5             integer,
  rating_4             integer,
  rating_3             integer,
  rating_2             integer,
  rating_1             integer
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH summary AS (
    SELECT *
    FROM public.business_rating_summary
    WHERE business_rating_summary.business_id = p_business_id
  ),
  stats AS (
    SELECT *
    FROM public.business_stats
    WHERE business_stats.business_id = p_business_id
  )
  SELECT
    COALESCE((SELECT s.business_id FROM summary s), p_business_id) AS business_id,
    COALESCE((SELECT s.rating_count FROM summary s), 0)            AS rating_count,
    (SELECT s.avg_overall_rating FROM summary s)                   AS avg_overall_rating,
    (SELECT s.avg_taste_rating FROM summary s)                     AS avg_taste_rating,
    (SELECT s.avg_service_speed_rating FROM summary s)             AS avg_service_speed_rating,
    (SELECT s.avg_price_performance_rating FROM summary s)         AS avg_price_performance_rating,
    (SELECT s.avg_cleanliness_rating FROM summary s)               AS avg_cleanliness_rating,
    (SELECT s.avg_atmosphere_rating FROM summary s)                AS avg_atmosphere_rating,
    COALESCE((SELECT t.rating_5 FROM stats t), 0)                  AS rating_5,
    COALESCE((SELECT t.rating_4 FROM stats t), 0)                  AS rating_4,
    COALESCE((SELECT t.rating_3 FROM stats t), 0)                  AS rating_3,
    COALESCE((SELECT t.rating_2 FROM stats t), 0)                  AS rating_2,
    COALESCE((SELECT t.rating_1 FROM stats t), 0)                  AS rating_1;
$$;

GRANT EXECUTE ON FUNCTION public.get_business_rating_summary_v2(uuid) TO anon, authenticated, service_role;
