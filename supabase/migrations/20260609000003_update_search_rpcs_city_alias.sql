-- ============================================================
-- 20260609000003_update_search_rpcs_city_alias.sql
--
-- Amaç: search_businesses_v1 ve search_nearby_businesses_v3 RPC'lerine
-- city_search_aliases tablosuna dayanan alias lookup desteği ekle.
--
-- Gerekçe: PR #94 (chore/normalize-business-location-data) şu dönüşümleri
-- yapacak: İzmit→Kocaeli, Adapazarı→Sakarya, Afyon→Afyonkarahisar,
-- Antakya→Hatay. Normalizasyon sonrası "İzmit" araması sonuçsuz dönerdi.
--
-- Değişen davranış:
--   p_city = 'İzmit'  → alias tablosunda 'izmit' bulunur
--                     → canonical_city='Kocaeli', canonical_district='İzmit'
--                     → b.city='Kocaeli' AND b.district='İzmit' eşleşir
--   p_city = 'Kocaeli' → alias tablosunda bulunamaz
--                      → mevcut b.city=p_city eşleşmesi çalışır (değişmez)
--   p_city = NULL      → alias lookup atlanır, mevcut NULL davranışı korunur
--
-- Korunan özellikler:
--   - RETURNS TABLE imzası ve kolon sırası değişmiyor
--   - Tüm diğer parametreler (p_query, p_lat, p_lng, p_radius_km, vb.) aynı
--   - SECURITY DEFINER, LANGUAGE, SET search_path aynı
--   - p_city IS NULL → alias tablosuna dokunulmaz, performans etkilenmez
--   - Mevcut GRANT'lar yeniden verilir
--
-- ROLLBACK:
--   search_businesses_v1: 20260507000004_arama_konum_populerite.sql içeriğini yeniden uygula
--   search_nearby_businesses_v3: 20260603000004_search_nearby_v3_extend_returns.sql içeriğini yeniden uygula
-- ============================================================


-- ============================================================
-- 1. search_businesses_v1 — alias lookup eklendi
--
-- Mevcut son tanım: 20260507000004_arama_konum_populerite.sql
-- Parametreler: p_query, p_city, p_district, p_lat, p_lng, p_radius_km, p_limit, p_offset
-- LANGUAGE sql, STABLE, SECURITY DEFINER, SET search_path = public, extensions
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_businesses_v1(
  p_query      text,
  p_city       text    DEFAULT NULL,
  p_district   text    DEFAULT NULL,
  p_lat        float8  DEFAULT NULL,
  p_lng        float8  DEFAULT NULL,
  p_radius_km  float8  DEFAULT 50,
  p_limit      int     DEFAULT 50,
  p_offset     int     DEFAULT 0
)
RETURNS TABLE (
  id                          uuid,
  name                        text,
  slug                        text,
  category                    text,
  city                        text,
  district                    text,
  address                     text,
  lat                         float8,
  lng                         float8,
  distance_km                 float8,
  avg_rating                  float8,
  review_count                int,
  quality_score               float8,
  trust_score                 float8,
  is_open_now                 boolean,
  is_active                   boolean,
  owner_verified              boolean,
  median_price_cents          int,
  recent_price_verified_count int,
  meal_card_providers         jsonb
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH
  -- Alias resolution: p_city bir alias'a karşılık geliyorsa canonical değeri döndür
  -- p_city NULL ise bu CTE boş satır döndürür (WHERE koşulundan elenir)
  resolved_city AS (
    SELECT
      COALESCE(csa.canonical_city, p_city)  AS city_val,
      csa.canonical_district                 AS district_hint
    FROM (SELECT 1) _dummy
    LEFT JOIN public.city_search_aliases csa
      ON public.normalize_tr_location_text(csa.alias)
         = public.normalize_tr_location_text(p_city)
    WHERE p_city IS NOT NULL
    LIMIT 1
  ),
  similarity_scores AS (
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
      -- Mesafe (km) — null eğer konum parametresi verilmediyse
      CASE
        WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND b.lat IS NOT NULL AND b.lng IS NOT NULL
        THEN extensions.earth_distance(
               extensions.ll_to_earth(p_lat, p_lng),
               extensions.ll_to_earth(b.lat, b.lng)
             ) / 1000.0
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
      -- Şehir filtresi: doğrudan eşleşme VEYA alias lookup
      AND (
        p_city IS NULL
        OR b.city = p_city
        OR EXISTS (
          SELECT 1
          FROM resolved_city rc
          WHERE rc.city_val = b.city
            AND (rc.district_hint IS NULL OR b.district = rc.district_hint)
        )
      )
      -- İlçe filtresi: doğrudan parametre (alias lookup'tan gelen district_hint değil)
      AND (p_district IS NULL OR b.district = p_district)
      -- Metin eşleşmesi
      AND (
        lower(b.name) LIKE '%' || lower(p_query) || '%'
        OR similarity(lower(b.name), lower(p_query)) > 0.15
      )
      -- Konum filtresi: radius içindeyse veya konum yoksa dahil et
      AND (
        p_lat IS NULL OR p_lng IS NULL OR b.lat IS NULL OR b.lng IS NULL
        OR extensions.earth_distance(
             extensions.ll_to_earth(p_lat, p_lng),
             extensions.ll_to_earth(b.lat, b.lng)
           ) / 1000.0 <= p_radius_km
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
    ss.reviews_count::int,
    NULL::float8   AS quality_score,
    NULL::float8   AS trust_score,
    NULL::boolean  AS is_open_now,
    ss.is_active,
    NULL::boolean  AS owner_verified,
    NULL::int      AS median_price_cents,
    NULL::int      AS recent_price_verified_count,
    '[]'::jsonb    AS meal_card_providers
  FROM similarity_scores ss
  ORDER BY
    -- Bileşik skor: metin benzerliği + konum bonusu + popülerlik
    (ss.text_score * 2.0
      + CASE
          WHEN ss.distance_km IS NOT NULL
          THEN greatest(0, 1.0 - ss.distance_km / p_radius_km)
          ELSE 0
        END
      + ss.popularity_score * 0.1
    ) DESC,
    ss.distance_km ASC NULLS LAST
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- GRANTs — yeni imzaya (p_lat, p_lng, p_radius_km dahil) göre verilir
REVOKE ALL ON FUNCTION public.search_businesses_v1(
  text, text, text, float8, float8, float8, int, int
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.search_businesses_v1(
  text, text, text, float8, float8, float8, int, int
) TO anon;

GRANT EXECUTE ON FUNCTION public.search_businesses_v1(
  text, text, text, float8, float8, float8, int, int
) TO authenticated;

COMMENT ON FUNCTION public.search_businesses_v1(
  text, text, text, float8, float8, float8, int, int
) IS
  'İşletme metin araması. Popülerlik + mesafe + benzerlik skoru. '
  'p_city: doğrudan eşleşme veya city_search_aliases tablosu üzerinden alias lookup. '
  'Alias desteği: İzmit→Kocaeli, Adapazarı→Sakarya, Afyon→Afyonkarahisar, Antakya→Hatay. '
  'Called by: uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart, '
  'uygulamalar/mobil/lib/features/discovery/data/search_repository.dart, '
  'uygulamalar/web/src/lib/veri/kesif-okuma.ts';


-- ============================================================
-- 2. search_nearby_businesses_v3 — alias lookup eklendi
--
-- Mevcut son tanım: 20260603000004_search_nearby_v3_extend_returns.sql
-- Parametreler: p_user_lat, p_user_lng, p_radius_km, p_limit, p_offset,
--               p_city, p_district, p_query
-- LANGUAGE sql, SECURITY DEFINER, SET search_path TO 'public'
--
-- Bu overload'ı DROP + CREATE ile güncelliyoruz çünkü RETURNS TABLE
-- değişmedi; CREATE OR REPLACE yeterli.
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(
  p_user_lat  double precision,
  p_user_lng  double precision,
  p_radius_km double precision DEFAULT 5,
  p_limit     integer          DEFAULT 50,
  p_offset    integer          DEFAULT 0,
  p_city      text             DEFAULT NULL::text,
  p_district  text             DEFAULT NULL::text,
  p_query     text             DEFAULT NULL::text
)
RETURNS TABLE(
  id                 uuid,
  name               text,
  category           text,
  address            text,
  city               text,
  district           text,
  lat                double precision,
  lng                double precision,
  distance_km        double precision,
  -- 20260603000004 ile eklenen kolonlar — sıra korunuyor
  is_open_now        boolean,
  median_price_cents integer,
  price_level        text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH
  -- Alias resolution: p_city bir alias'a karşılık geliyorsa canonical değeri döndür
  -- p_city NULL ise LEFT JOIN eşleşmez, COALESCE p_city=NULL döndürür
  resolved_city AS (
    SELECT
      COALESCE(csa.canonical_city, p_city)  AS city_val,
      csa.canonical_district                 AS district_hint
    FROM (SELECT 1) _dummy
    LEFT JOIN public.city_search_aliases csa
      ON public.normalize_tr_location_text(csa.alias)
         = public.normalize_tr_location_text(p_city)
    WHERE p_city IS NOT NULL
    LIMIT 1
  ),
  params AS (
    SELECT
      st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography AS user_geog,
      greatest(p_radius_km, 0.1) * 1000.0 AS radius_m,
      nullif(trim(coalesce(p_query, '')), '') AS q
  )
  SELECT
    b.id,
    b.name,
    b.category,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    (st_distance(b.geog, (SELECT user_geog FROM params)) / 1000.0)::double precision AS distance_km,
    -- is_open_now: Bu overload'da business_hours join'i ve p_open_now parametresi
    -- mevcut değil. Hesaplanamaz, NULL döndürülüyor. Mobil fromMap null-safe.
    NULL::boolean AS is_open_now,
    -- median_price_cents: business_price_index_v1 view'ından lateral lookup.
    pi.median_price_cents,
    -- price_level: businesses.price_level (migration 20260603000001).
    b.price_level
  FROM public.businesses b
  CROSS JOIN params
  LEFT JOIN LATERAL (
    SELECT bpi.median_price_cents
    FROM public.business_price_index_v1 bpi
    WHERE bpi.business_id = b.id
    LIMIT 1
  ) pi ON true
  WHERE b.geog IS NOT NULL
    AND st_dwithin(b.geog, params.user_geog, params.radius_m)
    -- Şehir filtresi: doğrudan eşleşme VEYA alias lookup
    AND (
      p_city IS NULL
      OR b.city = p_city
      OR EXISTS (
        SELECT 1
        FROM resolved_city rc
        WHERE rc.city_val = b.city
          AND (rc.district_hint IS NULL OR b.district = rc.district_hint)
      )
    )
    -- İlçe filtresi: doğrudan parametre
    AND (p_district IS NULL OR b.district = p_district)
    -- Metin filtresi
    AND (
      params.q IS NULL
      OR b.search_tsv @@ websearch_to_tsquery('turkish', params.q)
      OR b.name    ILIKE '%' || params.q || '%'
      OR b.address ILIKE '%' || params.q || '%'
    )
  ORDER BY st_distance(b.geog, params.user_geog) ASC
  LIMIT  greatest(p_limit, 0)
  OFFSET greatest(p_offset, 0);
$$;

-- GRANTs — 20260603000004'teki aynı imza
REVOKE ALL ON FUNCTION public.search_nearby_businesses_v3(
  double precision, double precision, double precision,
  integer, integer, text, text, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.search_nearby_businesses_v3(
  double precision, double precision, double precision,
  integer, integer, text, text, text
) TO anon;

GRANT EXECUTE ON FUNCTION public.search_nearby_businesses_v3(
  double precision, double precision, double precision,
  integer, integer, text, text, text
) TO authenticated;

COMMENT ON FUNCTION public.search_nearby_businesses_v3(
  double precision, double precision, double precision,
  integer, integer, text, text, text
) IS
  'PostGIS ST_DWithin ile yakın işletme arama. '
  'RETURNS TABLE: id/name/category/address/city/district/lat/lng/distance_km (mevcut) '
  '+ is_open_now boolean (NULL — bu overload hours join içermiyor) '
  '+ median_price_cents integer (business_price_index_v1 lateral join) '
  '+ price_level text (businesses.price_level, migration 20260603000001). '
  'p_city: doğrudan eşleşme veya city_search_aliases tablosu üzerinden alias lookup. '
  'Alias desteği: İzmit→Kocaeli, Adapazarı→Sakarya, Afyon→Afyonkarahisar, Antakya→Hatay. '
  'Called by: uygulamalar/mobil/lib/features/discovery/data/search_repository.dart';
