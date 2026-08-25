-- Harita pin'lerinde açık/kapalı rozeti göstermek için nearby_businesses_v2'ye
-- is_open_now ekleniyor. search_nearby_businesses_v3'teki mevcut is_open_now mantığı
-- kasıtlı olarak KOPYALANMADI: o, public.business_hours (yalnızca 1 satır — terk
-- edilmiş eski tablo) üzerinden hesaplıyor. Gerçek/canlı veri
-- public.business_weekly_hours'ta (232.894 satır) — get_business_hours_v1'in
-- kullandığı, Europe/Istanbul saat dilimine göre doğru hesaplayan tablo. Bu migration
-- get_business_hours_v1 ile aynı mantığı kullanıyor.
-- RETURNS TABLE sütun listesi değiştiği için CREATE OR REPLACE yetmiyor (Postgres
-- OUT parametre satır tipini değiştirmeye izin vermiyor) — önce DROP gerekiyor.
DROP FUNCTION IF EXISTS public.nearby_businesses_v2(double precision, double precision, integer, text, integer, integer);

CREATE FUNCTION public.nearby_businesses_v2(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer DEFAULT 2000,
  p_category text DEFAULT NULL::text,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  id uuid, name text, slug text, public_slug text, category text, address text,
  city text, district text, neighborhood text, lat double precision, lng double precision,
  distance_m integer, avg_rating double precision, review_count integer,
  is_active boolean, is_verified boolean, logo_url text, cover_url text,
  is_open_now boolean
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
  WITH ref AS (
    SELECT ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::public.geography AS pt
  ),
  rows AS (
    SELECT
      b.id,
      b.name,
      b.slug,
      b.public_slug,
      b.category,
      b.address,
      b.city,
      b.district,
      b.neighborhood,
      b.lat,
      b.lng,
      ST_Distance(b.geog, ref.pt)::INT        AS distance_m,
      COALESCE(bws.avg_rating,    0)::FLOAT8  AS avg_rating,
      COALESCE(bws.reviews_count, 0)::INT     AS review_count,
      b.is_active,
      b.is_verified,
      b.logo_url,
      b.cover_url,
      -- Plan/ticari sponsorluk: aktif discovery sponsorluğu olan işletmeler öne alınır.
      EXISTS (
        SELECT 1 FROM public.sponsorships s
        WHERE s.business_id = b.id
          AND s.surface = 'discovery'
          AND s.status = 'active'
          AND (s.starts_at IS NULL OR s.starts_at <= now())
          AND (s.ends_at IS NULL OR s.ends_at >= now())
      ) AS is_boosted,
      (
        SELECT
          CASE
            WHEN EXISTS (
              SELECT 1 FROM public.business_special_hours sh
              WHERE sh.business_id = b.id AND sh.special_date = current_date
            ) THEN (
              SELECT NOT sh.is_closed
                AND sh.open_time IS NOT NULL
                AND (current_timestamp AT TIME ZONE 'Europe/Istanbul')::time BETWEEN sh.open_time AND sh.close_time
              FROM public.business_special_hours sh
              WHERE sh.business_id = b.id AND sh.special_date = current_date
            )
            WHEN EXISTS (
              SELECT 1 FROM public.business_weekly_hours bh
              WHERE bh.business_id = b.id
                AND bh.day_of_week = EXTRACT(DOW FROM current_timestamp AT TIME ZONE 'Europe/Istanbul')::smallint
            ) THEN (
              SELECT NOT bh.is_closed
                AND (current_timestamp AT TIME ZONE 'Europe/Istanbul')::time BETWEEN bh.open_time AND bh.close_time
              FROM public.business_weekly_hours bh
              WHERE bh.business_id = b.id
                AND bh.day_of_week = EXTRACT(DOW FROM current_timestamp AT TIME ZONE 'Europe/Istanbul')::smallint
            )
            ELSE NULL
          END
      ) AS is_open_now
    FROM public.businesses b
    CROSS JOIN ref
    LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
    WHERE
      b.is_active = TRUE
      AND b.geog IS NOT NULL
      AND ST_DWithin(b.geog, ref.pt, p_radius_m)
      AND (p_category IS NULL OR b.category = p_category)
  )
  SELECT
    id, name, slug, public_slug, category, address, city, district, neighborhood,
    lat, lng, distance_m, avg_rating, review_count, is_active, is_verified,
    logo_url, cover_url, is_open_now
  FROM rows
  ORDER BY is_boosted DESC, distance_m ASC
  LIMIT  p_limit
  OFFSET p_offset;
$function$;

-- DROP, fonksiyonun önceki tüm GRANT'lerini sıfırlıyor — orijinal erişim setini
-- (PUBLIC dahil) geri veriyoruz.
GRANT EXECUTE ON FUNCTION public.nearby_businesses_v2 TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.nearby_businesses_v2 TO anon, authenticated, service_role, postgres;

COMMENT ON FUNCTION public.nearby_businesses_v2 IS 'Harita için yakın işletmeler. is_open_now business_weekly_hours üzerinden Europe/Istanbul saatiyle hesaplanır (get_business_hours_v1 ile aynı mantık). Called by: harita-okuma.ts.';
