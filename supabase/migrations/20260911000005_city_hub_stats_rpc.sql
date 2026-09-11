-- [sehir]/page.tsx (şehir hub sayfası) `district, category` sütunlarını
-- (LIMIT 2000) çekip ilçe/kategori sayımlarını JS'te yapıyordu. Bu yalnızca
-- performans sorunu değil, gerçek bir doğruluk hatasıydı: 2000'den fazla aktif
-- işletmesi olan bir şehirde (İstanbul gibi) sayımlar sessizce yanlış/eksik
-- çıkıyordu — örneklemin ötesindeki ilçe/kategoriler hiç sayılmıyordu.
-- Postgres tarafında GROUP BY ile doğru ve ölçeklenebilir bir toplam.

CREATE OR REPLACE FUNCTION public.get_city_hub_stats_v1(p_city text)
RETURNS TABLE(district text, category text, item_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.district, b.category, count(*)::bigint AS item_count
  FROM public.businesses b
  WHERE b.is_active = true
    AND b.city ILIKE p_city
    AND b.district IS NOT NULL
    AND b.category IS NOT NULL
  GROUP BY b.district, b.category;
$$;

REVOKE ALL ON FUNCTION public.get_city_hub_stats_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_city_hub_stats_v1(text) TO anon;
GRANT EXECUTE ON FUNCTION public.get_city_hub_stats_v1(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_city_hub_stats_v1(text) TO service_role;

COMMENT ON FUNCTION public.get_city_hub_stats_v1(text) IS
  'Bir şehirdeki aktif işletmelerin ilçe x kategori dağılımını döner (GROUP BY). Called by: app/(genel)/[sehir]/page.tsx.';
