-- Genel "Konum Seç" ekranındaki Şehirler sekmesi 20 satırlık sabit bir liste
-- gösteriyordu (gerçek taranan işletme verisiyle ilgisiz). businesses.city
-- serbest metin (1924+ farklı değer, admin_business_city_lookup migration'ında
-- da belirtildiği gibi) — bu yüzden en sık kullanılan gerçek şehirleri sayımla
-- döndüren, anon dahil herkese açık bir RPC ekliyoruz (get_business_cities_v1
-- kimlik doğrulaması gerektiriyor ve sadece admin panelinde kullanılıyor).

CREATE OR REPLACE FUNCTION public.get_public_business_cities_v1(p_limit int DEFAULT 60)
RETURNS TABLE(city text, business_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.city, count(*)::bigint AS business_count
  FROM public.businesses b
  WHERE b.city IS NOT NULL
    AND b.is_active = true
  GROUP BY b.city
  ORDER BY count(*) DESC
  LIMIT p_limit;
$$;

REVOKE ALL ON FUNCTION public.get_public_business_cities_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_business_cities_v1(int) TO anon, authenticated;
COMMENT ON FUNCTION public.get_public_business_cities_v1 IS 'Genel konum seçici (Şehirler sekmesi) için en sık kullanılan şehirler, gerçek aktif işletme sayımıyla. Called by: src/ui/acik/konum-secici.tsx.';
