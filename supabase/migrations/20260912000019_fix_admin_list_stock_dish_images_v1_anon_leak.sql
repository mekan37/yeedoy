-- 20260912000015, admin_list_stock_dish_images_v1'i DROP+CREATE ile p_limit
-- parametreli hale getirirken sadece "REVOKE ALL ... FROM PUBLIC" yaptı —
-- CLAUDE.md'nin uyardığı standing ALTER DEFAULT PRIVILEGES nedeniyle anon
-- rolüne fonksiyon oluşturulduğu anda ayrıca ve doğrudan EXECUTE veriliyor,
-- PUBLIC'ten revoke bunu geri almıyor. Bu yüzden yeni imza hâlâ anon'a
-- açıktı (get_advisors ile tespit edildi). Aynı 3 önceki insidanla birebir
-- aynı kök neden.
REVOKE EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1(integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1(integer) TO authenticated;
