-- Admin Konumlar sayfası: il/ilçe özetleri artık gerçek SQL GROUP BY ile üretiliyor
-- (önceki uygulama businesses tablosundan sırasız 5.000 satırlık bir örneklem çekip
-- JS tarafında topluyordu — bu, 55.004 gerçek işletmenin sadece ~%9'unu kapsıyordu ve
-- ORDER BY olmadığı için hangi bölgelerin temsil edildiği rastgeleydi).
--
-- Ayrıca gerçek il sınırı poligonlarını (osm_admin_boundaries, admin_level=4) işletme
-- yoğunluğuyla eşleştiren bir RPC eklendi — Türkiye haritası bu gerçek veriyle çiziliyor.
--
-- businesses.city serbest metin olduğundan eşleştirme _normalize_tr_match() ile yapılıyor;
-- bu da normalize_tr_text()'in üstüne Unicode NFD çözümleme + birleşik aksan işareti (ör.
-- "i" + U+0307 kombinleyen nokta) temizliği ekliyor. Gerçek veride "Balikesi̇r" gibi bozuk
-- kodlanmış İ karakterleri bulundu (import pipeline'ından kalma) — bu düzeltmeyle eşleşme
-- oranı %70,5'ten %85,5'e çıktı (49.964 şehirli işletme içinden).

CREATE OR REPLACE FUNCTION public._normalize_tr_match(p text)
RETURNS text
LANGUAGE sql IMMUTABLE
SET search_path = public
AS $$
  SELECT public.normalize_tr_text(
    regexp_replace(normalize(coalesce(p, ''), NFD), '[̀-ͯ]', '', 'g')
  );
$$;

CREATE OR REPLACE FUNCTION public.get_business_location_city_stats_v1()
RETURNS TABLE(city text, business_count bigint, active_count bigint, verified_count bigint, district_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT
    b.city,
    count(*)::bigint,
    count(*) FILTER (WHERE b.is_active)::bigint,
    count(*) FILTER (WHERE b.is_verified)::bigint,
    count(DISTINCT b.district) FILTER (WHERE b.district IS NOT NULL)::bigint
  FROM public.businesses b
  WHERE b.city IS NOT NULL AND btrim(b.city) <> ''
  GROUP BY b.city;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_location_city_stats_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_location_city_stats_v1() TO authenticated;
COMMENT ON FUNCTION public.get_business_location_city_stats_v1 IS 'Şehir başına gerçek işletme/aktif/doğrulanmış/ilçe sayımı (tam tablo GROUP BY, örneklem değil). Called by: app/yonetici/konumlar/page.tsx.';

CREATE OR REPLACE FUNCTION public.get_business_location_district_stats_v1()
RETURNS TABLE(city text, district text, business_count bigint, active_count bigint, verified_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT
    b.city,
    b.district,
    count(*)::bigint,
    count(*) FILTER (WHERE b.is_active)::bigint,
    count(*) FILTER (WHERE b.is_verified)::bigint
  FROM public.businesses b
  WHERE b.district IS NOT NULL AND btrim(b.district) <> ''
    AND b.city IS NOT NULL AND btrim(b.city) <> ''
  GROUP BY b.city, b.district;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_location_district_stats_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_location_district_stats_v1() TO authenticated;
COMMENT ON FUNCTION public.get_business_location_district_stats_v1 IS 'İlçe başına gerçek işletme/aktif/doğrulanmış sayımı (tam tablo GROUP BY). Called by: app/yonetici/konumlar/page.tsx.';

CREATE OR REPLACE FUNCTION public.get_business_province_map_v1(p_tolerance double precision DEFAULT 0.02)
RETURNS TABLE(
  province_name text,
  business_count bigint,
  active_count bigint,
  verified_count bigint,
  geojson text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  WITH province AS (
    SELECT
      o.id,
      o.name,
      ST_AsGeoJSON(ST_SimplifyPreserveTopology(o.boundary::geometry, p_tolerance)) AS geojson
    FROM public.osm_admin_boundaries o
    WHERE o.admin_level = 4 AND o.boundary IS NOT NULL
  ),
  matched AS (
    SELECT
      p.id,
      count(b.id)::bigint AS business_count,
      count(b.id) FILTER (WHERE b.is_active)::bigint AS active_count,
      count(b.id) FILTER (WHERE b.is_verified)::bigint AS verified_count
    FROM province p
    LEFT JOIN public.businesses b
      ON public._normalize_tr_match(b.city) = public._normalize_tr_match(p.name)
    GROUP BY p.id
  )
  SELECT p.name, m.business_count, m.active_count, m.verified_count, p.geojson
  FROM province p
  JOIN matched m ON m.id = p.id
  ORDER BY p.name;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_province_map_v1(double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_province_map_v1(double precision) TO authenticated;
COMMENT ON FUNCTION public.get_business_province_map_v1 IS 'Gerçek il sınırı poligonları (osm_admin_boundaries) + işletme yoğunluğu eşleştirmesi; Konumlar sayfasındaki Türkiye haritasını besler. Called by: app/yonetici/konumlar/page.tsx.';
