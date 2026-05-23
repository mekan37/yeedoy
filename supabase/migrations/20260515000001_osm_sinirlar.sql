-- OSM Türkiye İdari Sınırları
-- admin_level: 4=il (province), 6=ilçe (district), 8=mahalle (neighborhood)

CREATE TABLE IF NOT EXISTS public.osm_admin_boundaries (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  osm_id        BIGINT      NOT NULL,
  admin_level   SMALLINT    NOT NULL CHECK (admin_level IN (4, 6, 8)),
  name          TEXT        NOT NULL,
  name_en       TEXT,
  parent_id     UUID        REFERENCES public.osm_admin_boundaries(id) ON DELETE SET NULL,
  boundary      public.geography(Geometry, 4326),
  centroid      public.geography(Point, 4326),
  properties    JSONB       NOT NULL DEFAULT '{}'::JSONB,
  imported_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (osm_id)
);

ALTER TABLE public.osm_admin_boundaries OWNER TO postgres;

CREATE INDEX IF NOT EXISTS idx_osm_admin_boundaries_boundary
  ON public.osm_admin_boundaries USING GIST (boundary);

CREATE INDEX IF NOT EXISTS idx_osm_admin_boundaries_centroid
  ON public.osm_admin_boundaries USING GIST (centroid);

CREATE INDEX IF NOT EXISTS idx_osm_admin_boundaries_admin_level
  ON public.osm_admin_boundaries (admin_level);

CREATE INDEX IF NOT EXISTS idx_osm_admin_boundaries_name_trgm
  ON public.osm_admin_boundaries USING GIN (name extensions.gin_trgm_ops);

-- businesses tablosuna OSM sınır bağlantısı
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS osm_boundary_id UUID
    REFERENCES public.osm_admin_boundaries(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_businesses_osm_boundary_id
  ON public.businesses (osm_boundary_id)
  WHERE osm_boundary_id IS NOT NULL;

-- geog sütunu GiST index (yoksa)
CREATE INDEX IF NOT EXISTS idx_businesses_geog
  ON public.businesses USING GIST (geog);

-- RLS
ALTER TABLE public.osm_admin_boundaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "osm_admin_boundaries_select_all"
  ON public.osm_admin_boundaries FOR SELECT USING (true);

GRANT SELECT ON public.osm_admin_boundaries TO anon, authenticated, service_role;
GRANT INSERT, UPDATE, DELETE ON public.osm_admin_boundaries TO service_role;

-- Batch import RPC: Node.js'ten GeoJSON geometri gönderir, PostGIS'e çevirir.
-- Batch küçük tutulmalı (5-20 boundary) çünkü her geometry büyük olabilir.
CREATE OR REPLACE FUNCTION public.import_osm_boundaries_batch_v1(
  p_rows JSONB  -- [{osm_id, admin_level, name, name_en?, geojson?, properties?}]
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row     JSONB;
  v_count   INT := 0;
  v_geog    public.geography;
  v_centroid public.geography;
BEGIN
  FOR v_row IN SELECT jsonb_array_elements(p_rows)
  LOOP
    -- Geometry: GeoJSON string → geography
    IF v_row->>'geojson' IS NOT NULL AND v_row->>'geojson' <> 'null' THEN
      BEGIN
        v_geog := ST_GeogFromGeoJSON(v_row->>'geojson');
        v_centroid := ST_Centroid(v_geog::geometry)::public.geography;
      EXCEPTION WHEN OTHERS THEN
        v_geog := NULL;
        v_centroid := NULL;
      END;
    ELSE
      v_geog := NULL;
      v_centroid := NULL;
    END IF;

    INSERT INTO public.osm_admin_boundaries (
      osm_id, admin_level, name, name_en, boundary, centroid, properties
    ) VALUES (
      (v_row->>'osm_id')::BIGINT,
      (v_row->>'admin_level')::SMALLINT,
      v_row->>'name',
      NULLIF(v_row->>'name_en', ''),
      v_geog,
      v_centroid,
      COALESCE(v_row->'properties', '{}')
    )
    ON CONFLICT (osm_id) DO UPDATE SET
      name       = EXCLUDED.name,
      name_en    = EXCLUDED.name_en,
      boundary   = COALESCE(EXCLUDED.boundary, osm_admin_boundaries.boundary),
      centroid   = COALESCE(EXCLUDED.centroid, osm_admin_boundaries.centroid),
      properties = osm_admin_boundaries.properties || EXCLUDED.properties;

    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.import_osm_boundaries_batch_v1(JSONB) TO service_role;

-- Sınır hiyerarşisini osm_id üzerinden kur (import sonrası çağrılır)
CREATE OR REPLACE FUNCTION public.link_osm_boundary_parents_v1()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT := 0;
  v_rec   RECORD;
BEGIN
  -- ilçeleri (6) → illere (4) bağla: centroid hangi il içindeyse
  FOR v_rec IN
    SELECT child.id AS child_id, parent.id AS parent_id
    FROM public.osm_admin_boundaries child
    JOIN public.osm_admin_boundaries parent
      ON parent.admin_level = 4
      AND child.admin_level = 6
      AND child.centroid IS NOT NULL
      AND parent.boundary IS NOT NULL
      AND ST_Within(child.centroid::geometry, parent.boundary::geometry)
    WHERE child.parent_id IS NULL
  LOOP
    UPDATE public.osm_admin_boundaries SET parent_id = v_rec.parent_id WHERE id = v_rec.child_id;
    v_count := v_count + 1;
  END LOOP;

  -- mahalleleri (8) → ilçelere (6) bağla
  FOR v_rec IN
    SELECT child.id AS child_id, parent.id AS parent_id
    FROM public.osm_admin_boundaries child
    JOIN public.osm_admin_boundaries parent
      ON parent.admin_level = 6
      AND child.admin_level = 8
      AND child.centroid IS NOT NULL
      AND parent.boundary IS NOT NULL
      AND ST_Within(child.centroid::geometry, parent.boundary::geometry)
    WHERE child.parent_id IS NULL
  LOOP
    UPDATE public.osm_admin_boundaries SET parent_id = v_rec.parent_id WHERE id = v_rec.child_id;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_osm_boundary_parents_v1() TO service_role;
