-- Admin İşletmeler sayfası filtre dropdown'ları için gerçek distinct kategori/ilçe listeleri.
-- Önceki uygulama .limit(N) örneklemi ile kategori/şehir çekiyordu; bu, düşük kardinaliteli
-- kategori alanında yanlış (eksik) liste üretiyordu çünkü örneklem tek bir kategoriye denk geliyordu.

CREATE OR REPLACE FUNCTION public.get_business_categories_v1()
RETURNS TABLE(category text, business_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT b.category, count(*)::bigint
  FROM public.businesses b
  WHERE b.category IS NOT NULL
  GROUP BY b.category
  ORDER BY count(*) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_categories_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_categories_v1() TO authenticated;
COMMENT ON FUNCTION public.get_business_categories_v1 IS 'Businesses tablosundaki distinct kategori listesi (sayımla). Called by: app/yonetici/isletmeler/page.tsx.';

CREATE OR REPLACE FUNCTION public.get_business_districts_v1(p_city text DEFAULT NULL)
RETURNS TABLE(district text, business_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT b.district, count(*)::bigint
  FROM public.businesses b
  WHERE b.district IS NOT NULL
    AND (p_city IS NULL OR b.city = p_city)
  GROUP BY b.district
  ORDER BY count(*) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_districts_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_districts_v1(text) TO authenticated;
COMMENT ON FUNCTION public.get_business_districts_v1 IS 'Businesses tablosundaki distinct ilçe listesi, opsiyonel şehir filtresiyle. Called by: app/yonetici/isletmeler/page.tsx.';
