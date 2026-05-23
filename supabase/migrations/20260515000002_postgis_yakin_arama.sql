-- PostGIS tabanlı yakın işletme araması ve sınır atama fonksiyonları
-- ST_DWithin + <-> KNN operatörü ile index-aware sıralama

-- ── Trigger: lat/lng değiştiğinde geog'u otomatik güncelle ────────────────
CREATE OR REPLACE FUNCTION public._fn_sync_business_geog()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.geog := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::public.geography;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_business_geog ON public.businesses;
CREATE TRIGGER trg_sync_business_geog
  BEFORE INSERT OR UPDATE OF lat, lng
  ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public._fn_sync_business_geog();

-- Mevcut satırları backfill et (geog eksik olanlar)
UPDATE public.businesses
SET geog = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::public.geography
WHERE lat IS NOT NULL AND lng IS NOT NULL AND geog IS NULL;

-- ── nearby_businesses_v2: PostGIS ST_DWithin ─────────────────────────────
CREATE OR REPLACE FUNCTION public.nearby_businesses_v2(
  p_lat       FLOAT8,
  p_lng       FLOAT8,
  p_radius_m  INT  DEFAULT 2000,
  p_category  TEXT DEFAULT NULL,
  p_limit     INT  DEFAULT 50,
  p_offset    INT  DEFAULT 0
)
RETURNS TABLE (
  id           UUID,
  name         TEXT,
  slug         TEXT,
  public_slug  TEXT,
  category     TEXT,
  address      TEXT,
  city         TEXT,
  district     TEXT,
  neighborhood TEXT,
  lat          FLOAT8,
  lng          FLOAT8,
  distance_m   INT,
  avg_rating   FLOAT8,
  review_count INT,
  is_active    BOOLEAN,
  is_verified  BOOLEAN,
  logo_url     TEXT,
  cover_url    TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH ref AS (
    SELECT ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::public.geography AS pt
  )
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
    b.cover_url
  FROM public.businesses b
  CROSS JOIN ref
  LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
  WHERE
    b.is_active = TRUE
    AND b.geog IS NOT NULL
    AND ST_DWithin(b.geog, ref.pt, p_radius_m)
    AND (p_category IS NULL OR b.category = p_category)
  ORDER BY
    b.geog <-> ref.pt
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.nearby_businesses_v2(FLOAT8, FLOAT8, INT, TEXT, INT, INT)
  TO anon, authenticated, service_role;

-- ── get_businesses_in_boundary_v1: sınır içindeki işletmeler ─────────────
CREATE OR REPLACE FUNCTION public.get_businesses_in_boundary_v1(
  p_boundary_id UUID,
  p_limit       INT DEFAULT 100,
  p_offset      INT DEFAULT 0
)
RETURNS TABLE (
  id           UUID,
  name         TEXT,
  slug         TEXT,
  category     TEXT,
  address      TEXT,
  lat          FLOAT8,
  lng          FLOAT8,
  avg_rating   FLOAT8,
  review_count INT,
  is_active    BOOLEAN,
  is_verified  BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.id, b.name, b.slug, b.category, b.address, b.lat, b.lng,
    COALESCE(bws.avg_rating,    0)::FLOAT8 AS avg_rating,
    COALESCE(bws.reviews_count, 0)::INT    AS review_count,
    b.is_active,
    b.is_verified
  FROM public.businesses b
  LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
  WHERE
    b.is_active = TRUE
    AND b.osm_boundary_id = p_boundary_id
  ORDER BY COALESCE(bws.avg_rating, 0) DESC
  LIMIT p_limit OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.get_businesses_in_boundary_v1(UUID, INT, INT)
  TO anon, authenticated, service_role;

-- ── assign_business_to_boundary_v1: tek işletme için sınır ata ───────────
CREATE OR REPLACE FUNCTION public.assign_business_to_boundary_v1(p_business_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_geog        public.geography;
  v_boundary_id UUID;
BEGIN
  SELECT geog INTO v_geog FROM public.businesses WHERE id = p_business_id;
  IF v_geog IS NULL THEN RETURN NULL; END IF;

  -- En küçük kapsayan mahalle (8)
  SELECT id INTO v_boundary_id
  FROM public.osm_admin_boundaries
  WHERE admin_level = 8
    AND boundary IS NOT NULL
    AND ST_Within(v_geog::geometry, boundary::geometry)
  ORDER BY ST_Area(boundary::geometry) ASC
  LIMIT 1;

  -- Mahalle yoksa ilçe (6)
  IF v_boundary_id IS NULL THEN
    SELECT id INTO v_boundary_id
    FROM public.osm_admin_boundaries
    WHERE admin_level = 6
      AND boundary IS NOT NULL
      AND ST_Within(v_geog::geometry, boundary::geometry)
    ORDER BY ST_Area(boundary::geometry) ASC
    LIMIT 1;
  END IF;

  IF v_boundary_id IS NOT NULL THEN
    UPDATE public.businesses SET osm_boundary_id = v_boundary_id WHERE id = p_business_id;
  END IF;

  RETURN v_boundary_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.assign_business_to_boundary_v1(UUID) TO service_role;

-- ── assign_all_businesses_to_boundaries_v1: toplu sınır atama ────────────
CREATE OR REPLACE FUNCTION public.assign_all_businesses_to_boundaries_v1(
  p_batch INT DEFAULT 500
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT := 0;
  v_id    UUID;
BEGIN
  FOR v_id IN
    SELECT id FROM public.businesses
    WHERE geog IS NOT NULL AND osm_boundary_id IS NULL
    LIMIT p_batch
  LOOP
    PERFORM public.assign_business_to_boundary_v1(v_id);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.assign_all_businesses_to_boundaries_v1(INT) TO service_role;

-- ── search_businesses_in_boundary_v1: sınır + metin ──────────────────────
CREATE OR REPLACE FUNCTION public.search_businesses_in_boundary_v1(
  p_query       TEXT,
  p_boundary_id UUID,
  p_limit       INT DEFAULT 50,
  p_offset      INT DEFAULT 0
)
RETURNS TABLE (
  id           UUID,
  name         TEXT,
  slug         TEXT,
  category     TEXT,
  address      TEXT,
  lat          FLOAT8,
  lng          FLOAT8,
  avg_rating   FLOAT8,
  review_count INT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT
    b.id, b.name, b.slug, b.category, b.address, b.lat, b.lng,
    COALESCE(bws.avg_rating,    0)::FLOAT8 AS avg_rating,
    COALESCE(bws.reviews_count, 0)::INT    AS review_count
  FROM public.businesses b
  LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
  WHERE
    b.is_active = TRUE
    AND b.osm_boundary_id = p_boundary_id
    AND (
      lower(b.name) LIKE '%' || lower(p_query) || '%'
      OR extensions.similarity(lower(b.name), lower(p_query)) > 0.15
    )
  ORDER BY extensions.similarity(lower(b.name), lower(p_query)) DESC
  LIMIT p_limit OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.search_businesses_in_boundary_v1(TEXT, UUID, INT, INT)
  TO anon, authenticated, service_role;

-- ── get_boundary_stats_v1: sınır istatistikleri ───────────────────────────
CREATE OR REPLACE FUNCTION public.get_boundary_stats_v1(p_admin_level SMALLINT DEFAULT 6)
RETURNS TABLE (
  boundary_id   UUID,
  name          TEXT,
  admin_level   SMALLINT,
  business_count BIGINT,
  avg_rating    FLOAT8
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ab.id,
    ab.name,
    ab.admin_level,
    COUNT(b.id) AS business_count,
    AVG(bws.avg_rating) AS avg_rating
  FROM public.osm_admin_boundaries ab
  LEFT JOIN public.businesses b ON b.osm_boundary_id = ab.id AND b.is_active = TRUE
  LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
  WHERE ab.admin_level = p_admin_level
  GROUP BY ab.id, ab.name, ab.admin_level
  ORDER BY business_count DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_boundary_stats_v1(SMALLINT)
  TO anon, authenticated, service_role;
