-- import_osm_businesses_batch_v1
-- OSM POI toplu import RPC'si.
-- Supabase'in varsayılan statement_timeout'unu bu fonksiyon için devre dışı bırakır;
-- yalnızca service_role çağırabilir.

CREATE OR REPLACE FUNCTION public.import_osm_businesses_batch_v1(
  p_rows JSONB
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Toplu import için timeout sıfırla (service_role bağlantısı)
  SET LOCAL statement_timeout = '0';

  INSERT INTO public.businesses (
    name,
    category,
    phone,
    address,
    city,
    district,
    neighborhood,
    lat,
    lng,
    is_active,
    source,
    source_id,
    fingerprint,
    reservation_url,
    order_yemeksepeti_url,
    order_trendyolgo_url,
    order_getir_url
  )
  SELECT
    r.name,
    r.category,
    NULLIF(TRIM(r.phone), ''),
    NULLIF(TRIM(r.address), ''),
    NULLIF(TRIM(r.city), ''),
    NULLIF(TRIM(r.district), ''),
    NULLIF(TRIM(r.neighborhood), ''),
    r.lat::FLOAT8,
    r.lng::FLOAT8,
    TRUE,
    r.source,
    r.source_id,
    r.fingerprint,
    NULLIF(TRIM(r.reservation_url), ''),
    NULL,  -- order_yemeksepeti_url: OSM'de yok
    NULL,  -- order_trendyolgo_url: OSM'de yok
    NULL   -- order_getir_url: OSM'de yok
  FROM jsonb_to_recordset(p_rows) AS r(
    name                  TEXT,
    category              TEXT,
    phone                 TEXT,
    address               TEXT,
    city                  TEXT,
    district              TEXT,
    neighborhood          TEXT,
    lat                   TEXT,
    lng                   TEXT,
    source                TEXT,
    source_id             TEXT,
    fingerprint           TEXT,
    reservation_url       TEXT,
    order_yemeksepeti_url TEXT,
    order_trendyolgo_url  TEXT,
    order_getir_url       TEXT
  )
  WHERE r.name       IS NOT NULL
    AND r.source_id  IS NOT NULL
    AND r.lat        IS NOT NULL
    AND r.lng        IS NOT NULL
  ON CONFLICT (source, source_id) DO UPDATE SET
    name         = EXCLUDED.name,
    category     = EXCLUDED.category,
    phone        = COALESCE(EXCLUDED.phone,        businesses.phone),
    address      = COALESCE(EXCLUDED.address,      businesses.address),
    city         = COALESCE(EXCLUDED.city,         businesses.city),
    district     = COALESCE(EXCLUDED.district,     businesses.district),
    neighborhood = COALESCE(EXCLUDED.neighborhood, businesses.neighborhood),
    lat          = EXCLUDED.lat,
    lng          = EXCLUDED.lng,
    fingerprint  = EXCLUDED.fingerprint,
    reservation_url = COALESCE(EXCLUDED.reservation_url, businesses.reservation_url)
    -- is_verified, logo_url, cover_url, slug korunur (admin/owner tarafından set edilmiş olabilir)
  ;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Yalnızca service_role (import scripti) çalıştırabilir
REVOKE EXECUTE ON FUNCTION public.import_osm_businesses_batch_v1(JSONB) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.import_osm_businesses_batch_v1(JSONB) TO service_role;
