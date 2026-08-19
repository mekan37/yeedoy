-- businesses.city alanında 1924 farklı değer var (temiz bir il listesi değil, serbest metin) —
-- örneklem tabanlı liste burada da yanlış/eksik sonuç verebiliyordu. En sık kullanılan
-- şehirleri (gerçek sayımla) döndüren bir RPC ile değiştiriyoruz.

CREATE OR REPLACE FUNCTION public.get_business_cities_v1(p_limit int DEFAULT 150)
RETURNS TABLE(city text, business_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT b.city, count(*)::bigint
  FROM public.businesses b
  WHERE b.city IS NOT NULL
  GROUP BY b.city
  ORDER BY count(*) DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_cities_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_cities_v1(int) TO authenticated;
COMMENT ON FUNCTION public.get_business_cities_v1 IS 'Businesses tablosundaki en sık kullanılan şehirler (gerçek sayımla, varsayılan ilk 150). Called by: app/yonetici/isletmeler/page.tsx.';
