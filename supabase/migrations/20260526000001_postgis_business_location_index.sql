-- PostGIS uzantısı (zaten aktifse hata vermez)
CREATE EXTENSION IF NOT EXISTS postgis;

-- lat/lng'den geography sütunu ekle (idempotent)
ALTER TABLE businesses
  ADD COLUMN IF NOT EXISTS location geography(Point, 4326)
  GENERATED ALWAYS AS (
    CASE
      WHEN lat IS NOT NULL AND lng IS NOT NULL
      THEN ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
      ELSE NULL
    END
  ) STORED;

-- Spatial index
CREATE INDEX IF NOT EXISTS businesses_location_gix
  ON businesses USING GIST (location);

-- Yakın işletme arama fonksiyonu
CREATE OR REPLACE FUNCTION find_nearby_businesses_v1(
  p_lat double precision,
  p_lng double precision,
  p_radius_meters integer DEFAULT 2000,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  name text,
  distance_meters double precision
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    id,
    name,
    ST_Distance(
      location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) AS distance_meters
  FROM businesses
  WHERE
    location IS NOT NULL
    AND is_active = true
    AND ST_DWithin(
      location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_meters
    )
  ORDER BY distance_meters
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION find_nearby_businesses_v1(double precision, double precision, integer, integer) TO anon, authenticated;
COMMENT ON FUNCTION find_nearby_businesses_v1 IS 'PostGIS tabanlı yakın işletme araması. lat/lng GENERATED sütununu kullanır.';
