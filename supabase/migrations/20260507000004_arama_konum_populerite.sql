-- search_businesses_v1 güncelleme: konum + popülerlik sinyali
-- Mevcut RPC'ye p_lat, p_lng, p_radius_km parametreleri eklenir.
-- Yakın işletmeler similarity skora mesafe bonusu alır.
-- Popülerlik: avg_rating * log(review_count + 1) ile hesaplanır.

CREATE OR REPLACE FUNCTION search_businesses_v1(
  p_query      TEXT,
  p_city       TEXT     DEFAULT NULL,
  p_district   TEXT     DEFAULT NULL,
  p_lat        FLOAT8   DEFAULT NULL,
  p_lng        FLOAT8   DEFAULT NULL,
  p_radius_km  FLOAT8   DEFAULT 50,
  p_limit      INT      DEFAULT 50,
  p_offset     INT      DEFAULT 0
)
RETURNS TABLE (
  id                          UUID,
  name                        TEXT,
  slug                        TEXT,
  category                    TEXT,
  city                        TEXT,
  district                    TEXT,
  address                     TEXT,
  lat                         FLOAT8,
  lng                         FLOAT8,
  distance_km                 FLOAT8,
  avg_rating                  FLOAT8,
  review_count                INT,
  quality_score               FLOAT8,
  trust_score                 FLOAT8,
  is_open_now                 BOOLEAN,
  is_active                   BOOLEAN,
  owner_verified              BOOLEAN,
  median_price_cents          INT,
  recent_price_verified_count INT,
  meal_card_providers         JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH similarity_scores AS (
    SELECT
      b.id,
      b.name,
      b.slug,
      b.category,
      b.city,
      b.district,
      b.address,
      b.lat,
      b.lng,
      -- Mesafe (km) — null eğer konum yok
      CASE
        WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND b.lat IS NOT NULL AND b.lng IS NOT NULL
        THEN extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lng), extensions.ll_to_earth(b.lat, b.lng)) / 1000.0
        ELSE NULL
      END AS distance_km,
      -- Metin benzerliği skoru
      greatest(
        similarity(lower(b.name), lower(p_query)),
        CASE WHEN lower(b.name) LIKE '%' || lower(p_query) || '%' THEN 0.5 ELSE 0 END
      ) AS text_score,
      b.is_active,
      -- Popülerlik sinyali: değerlendirme sayısı + puan
      COALESCE(bws.avg_rating, 0) * ln(COALESCE(bws.reviews_count, 0) + 2) AS popularity_score,
      bws.avg_rating,
      bws.reviews_count
    FROM businesses b
    LEFT JOIN businesses_with_stats bws ON bws.id = b.id
    WHERE b.is_active = TRUE
      AND (p_city IS NULL OR b.city = p_city)
      AND (p_district IS NULL OR b.district = p_district)
      AND (
        lower(b.name) LIKE '%' || lower(p_query) || '%'
        OR similarity(lower(b.name), lower(p_query)) > 0.15
      )
      -- Konum filtresi: radius içindeyse veya konum yoksa dahil et
      AND (
        p_lat IS NULL OR p_lng IS NULL OR b.lat IS NULL OR b.lng IS NULL
        OR extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lng), extensions.ll_to_earth(b.lat, b.lng)) / 1000.0 <= p_radius_km
      )
  )
  SELECT
    ss.id,
    ss.name,
    ss.slug,
    ss.category,
    ss.city,
    ss.district,
    ss.address,
    ss.lat,
    ss.lng,
    ss.distance_km,
    ss.avg_rating,
    ss.reviews_count::INT,
    NULL::FLOAT8 AS quality_score,
    NULL::FLOAT8 AS trust_score,
    NULL::BOOLEAN AS is_open_now,
    ss.is_active,
    NULL::BOOLEAN AS owner_verified,
    NULL::INT AS median_price_cents,
    NULL::INT AS recent_price_verified_count,
    '[]'::JSONB AS meal_card_providers
  FROM similarity_scores ss
  ORDER BY
    -- Bileşik skor: metin benzerliği + konum bonusu + popülerlik
    (ss.text_score * 2.0
      + CASE WHEN ss.distance_km IS NOT NULL THEN greatest(0, 1.0 - ss.distance_km / p_radius_km) ELSE 0 END
      + ss.popularity_score * 0.1
    ) DESC,
    ss.distance_km ASC NULLS LAST
  LIMIT p_limit
  OFFSET p_offset;
$$;
