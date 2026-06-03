-- ============================================================
-- 20260603000004_search_nearby_v3_extend_returns.sql
--
-- Amaç: search_nearby_businesses_v3 (PostGIS overload) RETURNS TABLE'a
-- 3 yeni kolon ekle:
--   is_open_now        boolean
--   median_price_cents integer
--   price_level        text
--
-- Gerekçe: Mobil BusinessCardModel.fromMap() bu alanları bekliyor
-- (business_card.dart satır 61-62). Şu an RPC'den gelmedikleri için
-- nullable parse ediliyor ama NULL döner. Bu migration değerleri doldurur.
--
-- Hangi overload: p_user_lat / p_user_lng / p_radius_km double precision
-- (search_repository.dart satır 256-270 tarafından çağrılır).
-- p_lat / p_lng / p_open_now integer overload'u DEĞİŞTİRİLMEDİ.
--
-- Kararlar:
--   is_open_now: Bu overload'da business_hours join'i yok, p_open_now
--     parametresi de yok. Doğru hesap yapamayacağımız için NULL::boolean
--     döndürülüyor. Sahte veri üretilmiyor. Mobil fromMap null-safe.
--
--   median_price_cents: business_price_index_v1 view'ı per-business
--     median_price_cents sağlıyor (percentile weighted join). LEFT JOIN
--     LATERAL ile eklendi — satır başına tek lookup, index destekli.
--     Fiyat verisi olmayan işletmeler NULL alır.
--
--   price_level: 20260603000001 ile eklenen businesses.price_level
--     sütununun doğrudan b.price_level referansı. NULL işletmeler için
--     NULL döner.
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.search_nearby_businesses_v3(
--     double precision, double precision, double precision,
--     integer, integer, text, text, text
--   );
--   CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(
--     p_user_lat double precision,
--     p_user_lng double precision,
--     p_radius_km double precision DEFAULT 5,
--     p_limit integer DEFAULT 50,
--     p_offset integer DEFAULT 0,
--     p_city text DEFAULT NULL::text,
--     p_district text DEFAULT NULL::text,
--     p_query text DEFAULT NULL::text
--   )
--   RETURNS TABLE(
--     id uuid, name text, category text, address text,
--     city text, district text,
--     lat double precision, lng double precision,
--     distance_km double precision
--   )
--   LANGUAGE sql
--   SECURITY DEFINER
--   SET search_path TO 'public'
--   AS $$
--     with params as (
--       select
--         st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography as user_geog,
--         greatest(p_radius_km, 0.1) * 1000.0 as radius_m,
--         nullif(trim(coalesce(p_query,'')), '') as q
--     )
--     select
--       b.id, b.name, b.category, b.address, b.city, b.district, b.lat, b.lng,
--       (st_distance(b.geog, (select user_geog from params)) / 1000.0)::double precision as distance_km
--     from public.businesses b, params
--     where b.geog is not null
--       and st_dwithin(b.geog, params.user_geog, params.radius_m)
--       and (p_city is null or b.city = p_city)
--       and (p_district is null or b.district = p_district)
--       and (
--         params.q is null
--         or b.search_tsv @@ websearch_to_tsquery('turkish', params.q)
--         or b.name ilike '%' || params.q || '%'
--         or b.address ilike '%' || params.q || '%'
--       )
--     order by st_distance(b.geog, params.user_geog) asc
--     limit greatest(p_limit, 0)
--     offset greatest(p_offset, 0);
--   $$;
--   REVOKE ALL ON FUNCTION public.search_nearby_businesses_v3(
--     double precision, double precision, double precision,
--     integer, integer, text, text, text
--   ) FROM PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.search_nearby_businesses_v3(
--     double precision, double precision, double precision,
--     integer, integer, text, text, text
--   ) TO anon;
--   GRANT EXECUTE ON FUNCTION public.search_nearby_businesses_v3(
--     double precision, double precision, double precision,
--     integer, integer, text, text, text
--   ) TO authenticated;
--   COMMENT ON FUNCTION public.search_nearby_businesses_v3(
--     double precision, double precision, double precision,
--     integer, integer, text, text, text
--   ) IS 'PostGIS nearby search. Called by: search_repository.dart';
-- ============================================================

-- 1. Eski fonksiyonu bırak (RETURNS TABLE değiştiği için CREATE OR REPLACE yeterli değil)
DROP FUNCTION IF EXISTS public.search_nearby_businesses_v3(
  double precision,   -- p_user_lat
  double precision,   -- p_user_lng
  double precision,   -- p_radius_km
  integer,            -- p_limit
  integer,            -- p_offset
  text,               -- p_city
  text,               -- p_district
  text                -- p_query
);

-- 2. Genişletilmiş fonksiyonu oluştur
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
  -- Mevcut kolonlar — sıra ve tipler korunuyor
  id           uuid,
  name         text,
  category     text,
  address      text,
  city         text,
  district     text,
  lat          double precision,
  lng          double precision,
  distance_km  double precision,
  -- Yeni kolonlar — sona ekleniyor
  is_open_now        boolean,
  median_price_cents integer,
  price_level        text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  with params as (
    select
      st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography as user_geog,
      greatest(p_radius_km, 0.1) * 1000.0 as radius_m,
      nullif(trim(coalesce(p_query, '')), '') as q
  )
  select
    b.id,
    b.name,
    b.category,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    (st_distance(b.geog, (select user_geog from params)) / 1000.0)::double precision as distance_km,
    -- is_open_now: Bu overload'da business_hours join'i ve p_open_now parametresi
    -- mevcut değil. Hesaplanamaz, NULL döndürülüyor. Mobil fromMap null-safe.
    NULL::boolean as is_open_now,
    -- median_price_cents: business_price_index_v1 view'ından lateral lookup.
    -- Fiyat verisi olmayan işletmeler için NULL döner.
    pi.median_price_cents,
    -- price_level: 20260603000001 migration'ı ile eklenen businesses sütunu.
    b.price_level
  from public.businesses b
  cross join params
  left join lateral (
    select bpi.median_price_cents
    from public.business_price_index_v1 bpi
    where bpi.business_id = b.id
    limit 1
  ) pi on true
  where b.geog is not null
    and st_dwithin(b.geog, params.user_geog, params.radius_m)
    and (p_city     is null or b.city     = p_city)
    and (p_district is null or b.district = p_district)
    and (
      params.q is null
      or b.search_tsv @@ websearch_to_tsquery('turkish', params.q)
      or b.name    ilike '%' || params.q || '%'
      or b.address ilike '%' || params.q || '%'
    )
  order by st_distance(b.geog, params.user_geog) asc
  limit  greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;

-- 3. GRANT'ları yeniden ver
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
  'Eski kolonlar sıra ve tip olarak korundu. '
  'Called by: uygulamalar/mobil/lib/features/discovery/data/search_repository.dart';
