-- get_smart_recommendations_v2: gerçek verilerle çalışan akıllı öneri RPC.
--
-- v1 sorunları:
--   - search_nearby_businesses_v3 city/district overload'u distance_km döndürmüyor
--   - businesses_with_stats.avg_rating ve reviews_count kullanılmıyordu
--   - cover_url yerine NULL image_url dönüyordu
--   - Aktif kampanya discount_pct her zaman NULL'dı
--
-- v2 düzeltmeleri:
--   - businesses_with_stats view'ı üzerinden avg_rating + reviews_count alınıyor
--   - business_price_index_v1 lateral join ile gerçek median_price_cents
--   - businesses.cover_url doğrudan image_url olarak dönüyor
--   - p_lat/p_lng verilirse Haversine ile gerçek distance_km hesaplanıyor
--   - Aktif promo story varsa discount_pct alınıyor
--   - Sıralama: kampanyalı > yüksek puanlı > çok yorumlu

CREATE OR REPLACE FUNCTION public.get_smart_recommendations_v2(
  p_city             text,
  p_district         text,
  p_party_size       int     DEFAULT 2,
  p_budget_max_cents int     DEFAULT 60000,
  p_lat              double precision DEFAULT NULL,
  p_lng              double precision DEFAULT NULL,
  p_limit            int     DEFAULT 10
)
RETURNS TABLE (
  business_id          uuid,
  business_name        text,
  image_url            text,
  cuisine              text,
  rating               numeric,
  review_count         int,
  distance_km          double precision,
  estimated_minutes    int,
  total_cents          int,
  original_total_cents int,
  discount_pct         int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH campaign AS (
    -- Aktif (süresi dolmamış, silinmemiş) promo story'den indirim yüzdesi
    SELECT DISTINCT ON (s.business_id)
      s.business_id,
      s.discount_percent
    FROM public.business_stories s
    WHERE s.type = 'promo'
      AND s.is_deleted = false
      AND s.expires_at > now()
      AND s.discount_percent IS NOT NULL
    ORDER BY s.business_id, s.is_featured DESC, s.expires_at DESC
  )
  SELECT
    b.id                                                             AS business_id,
    b.name                                                           AS business_name,
    bus.cover_url                                                    AS image_url,
    b.category                                                       AS cuisine,
    b.avg_rating                                                     AS rating,
    b.reviews_count                                                  AS review_count,
    CASE
      WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL
           AND bus.lat IS NOT NULL AND bus.lng IS NOT NULL THEN
        6371.0 * 2.0 * asin(
          sqrt(
            power(sin(radians((bus.lat - p_lat) / 2.0)), 2)
            + cos(radians(p_lat)) * cos(radians(bus.lat))
              * power(sin(radians((bus.lng - p_lng) / 2.0)), 2)
          )
        )
      ELSE NULL
    END                                                              AS distance_km,
    NULL::int                                                        AS estimated_minutes,
    LEAST(
      p_budget_max_cents,
      COALESCE(pi.median_price_cents, 15000) * p_party_size
    )::int                                                           AS total_cents,
    NULL::int                                                        AS original_total_cents,
    c.discount_percent::int                                          AS discount_pct
  FROM public.businesses_with_stats b
  JOIN public.businesses bus ON bus.id = b.id
  LEFT JOIN LATERAL (
    SELECT bpi.median_price_cents
    FROM public.business_price_index_v1 bpi
    WHERE bpi.business_id = b.id
    LIMIT 1
  ) pi ON true
  LEFT JOIN campaign c ON c.business_id = b.id
  WHERE b.is_active = true
    AND (p_city    IS NULL OR trim(p_city)    = '' OR lower(b.city)     = lower(trim(p_city)))
    AND (p_district IS NULL OR trim(p_district) = '' OR lower(b.district) = lower(trim(p_district)))
    AND COALESCE(pi.median_price_cents, 15000) * p_party_size <= p_budget_max_cents
  ORDER BY
    (c.discount_percent IS NOT NULL) DESC,
    b.avg_rating         DESC NULLS LAST,
    b.reviews_count      DESC NULLS LAST,
    random()
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_smart_recommendations_v2(text, text, int, int, double precision, double precision, int)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_smart_recommendations_v2(text, text, int, int, double precision, double precision, int)
  TO anon, authenticated;

COMMENT ON FUNCTION public.get_smart_recommendations_v1(text, text, int, int, int)
  IS 'DEPRECATED 2026-07-08: use get_smart_recommendations_v2';

COMMENT ON FUNCTION public.get_smart_recommendations_v2 IS
  'Gerçek verilerle akıllı öneri: businesses_with_stats üzerinden avg_rating/review_count, '
  'business_price_index_v1 üzerinden median_price_cents, aktif promo story''dan discount_pct. '
  'p_lat/p_lng verilirse Haversine mesafe hesaplanır. Called by: smart_reco_repository.dart';
