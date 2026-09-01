-- ============================================================
-- 20260901071500_fix_search_businesses_v1_generic_plan_timeout.sql
--
-- Bug (devam — bkz. 20260901070800): 5-arg overload'ı silince ambiguous
-- function hatası (PGRST203) gitti, ama arkasında ikinci, daha ciddi bir
-- bug ortaya çıktı: kalan 8-arg search_businesses_v1 canlıda HER çağrıda
-- statement timeout'a çarpıyordu (HTTP 500, code 57014).
--
-- Kök neden: Fonksiyon LANGUAGE sql + SET search_path = public, extensions
-- ile tanımlıydı. `SET search_path` bir SQL fonksiyonunun caller sorgusuna
-- inline edilmesini KALICI olarak engeller (Postgres dokümantasyonunda
-- belirtilen bir kısıtlama). Inline edilemeyen bir set-returning SQL
-- fonksiyonu, gövdesindeki sorguyu backend'in fonksiyon-çağrı mekanizması
-- üzerinden — parametre değerlerinden bağımsız, sabit/"generic" bir plan
-- ile — çalıştırıyor. Bu da p_query='kebap' gibi son derece seçici bir
-- trigram/LIKE filtresinin seçiciliğini plan zamanında tamamen görmezden
-- gelip yanlış join stratejisi seçilmesine yol açıyor.
--
-- Doğrulama: Aynı sorgu gövdesi elle (literal değerlerle) veya PREPARE/
-- EXECUTE ile çalıştırıldığında ~300-650ms sürüyor (51.710 satırlık
-- businesses tablosu için normal); ama gerçek RPC çağrısı (curl ile canlı
-- REST endpoint'ine, mobilin attığı body ile) tutarlı şekilde 17-18 saniye
-- sürüp PostgREST statement_timeout'una takılıyordu. plpgsql + EXECUTE
-- (dynamic SQL) ile yeniden yazılıp aynı testler tekrarlandığında süre
-- ~300-650ms'ye düşüyor — çünkü EXECUTE ile çalıştırılan dynamic SQL her
-- çağrıda YENİDEN planlanıyor, gerçek parametre değerlerine göre.
--
-- Fix: LANGUAGE sql -> LANGUAGE plpgsql + `RETURN QUERY EXECUTE ... USING`.
-- RETURNS TABLE imzası, parametre listesi, davranış (alias lookup, mesafe
-- hesabı, sıralama) ve GRANT'lar AYNEN korunuyor — sadece çalıştırma
-- mekanizması değişti.
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
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  RETURN QUERY EXECUTE
  $sql$
  WITH
  resolved_city AS (
    SELECT
      COALESCE(csa.canonical_city, $2)  AS city_val,
      csa.canonical_district             AS district_hint
    FROM (SELECT 1) _dummy
    LEFT JOIN public.city_search_aliases csa
      ON public.normalize_tr_location_text(csa.alias)
         = public.normalize_tr_location_text($2)
    WHERE $2 IS NOT NULL
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
      CASE
        WHEN $4 IS NOT NULL AND $5 IS NOT NULL AND b.lat IS NOT NULL AND b.lng IS NOT NULL
        THEN extensions.earth_distance(
               extensions.ll_to_earth($4, $5),
               extensions.ll_to_earth(b.lat, b.lng)
             ) / 1000.0
        ELSE NULL
      END AS distance_km,
      greatest(
        similarity(lower(b.name), lower($1)),
        CASE WHEN lower(b.name) LIKE '%' || lower($1) || '%' THEN 0.5 ELSE 0 END
      ) AS text_score,
      b.is_active,
      COALESCE(bws.avg_rating, 0) * ln(COALESCE(bws.reviews_count, 0) + 2) AS popularity_score,
      bws.avg_rating,
      bws.reviews_count
    FROM businesses b
    LEFT JOIN businesses_with_stats bws ON bws.id = b.id
    WHERE b.is_active = TRUE
      AND (
        $2 IS NULL
        OR b.city = $2
        OR EXISTS (
          SELECT 1
          FROM resolved_city rc
          WHERE rc.city_val = b.city
            AND (rc.district_hint IS NULL OR b.district = rc.district_hint)
        )
      )
      AND ($3 IS NULL OR b.district = $3)
      AND (
        lower(b.name) LIKE '%' || lower($1) || '%'
        OR similarity(lower(b.name), lower($1)) > 0.15
      )
      AND (
        $4 IS NULL OR $5 IS NULL OR b.lat IS NULL OR b.lng IS NULL
        OR extensions.earth_distance(
             extensions.ll_to_earth($4, $5),
             extensions.ll_to_earth(b.lat, b.lng)
           ) / 1000.0 <= $6
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
    ss.avg_rating::float8,
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
    (ss.text_score * 2.0
      + CASE
          WHEN ss.distance_km IS NOT NULL
          THEN greatest(0, 1.0 - ss.distance_km / $6)
          ELSE 0
        END
      + ss.popularity_score * 0.1
    ) DESC,
    ss.distance_km ASC NULLS LAST
  LIMIT $7
  OFFSET $8
  $sql$
  USING p_query, p_city, p_district, p_lat, p_lng, p_radius_km, p_limit, p_offset;
END;
$$;

-- GRANT'lar korunuyor (20260609000003_update_search_rpcs_city_alias.sql ile aynı imza)
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
  'LANGUAGE plpgsql + EXECUTE (dynamic SQL) kullanıyor — LANGUAGE sql + SET search_path '
  'kombinasyonu inline edilemediği için generic (parametre-körü) plan kullanıyordu ve '
  'canlıda 17s+ statement timeout''a sebep oluyordu (bkz. 20260901071500 migration notu). '
  'Called by: uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart, '
  'uygulamalar/mobil/lib/features/discovery/data/search_repository.dart, '
  'uygulamalar/web/src/lib/veri/kesif-okuma.ts';
