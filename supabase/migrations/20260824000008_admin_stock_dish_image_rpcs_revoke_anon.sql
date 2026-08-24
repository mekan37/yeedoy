-- Task 3 spec-compliance review'da bulundu: bu üç admin_* fonksiyonu postgres
-- rolüyle oluşturulduğunda, production'daki standing ALTER DEFAULT PRIVILEGES
-- girdisi yeni fonksiyonlara otomatik olarak anon'a da EXECUTE veriyor.
-- REVOKE ALL ... FROM PUBLIC bunu geri almıyor çünkü anon PUBLIC pseudo-role'ü
-- değil gerçek bir rol. Bu repo'da aynı sınıf hata daha önce iki kez bulunup
-- düzeltilmişti (20260810000006_sadakat_v1_revoke_anon_execute,
-- 20260820062028_fix_admin_alert_rules_anon_execute) — aynı düzeltme burada da
-- uygulanıyor. Fonksiyonların kendi is_admin() kontrolü zaten anon çağrılarını
-- reddediyordu (pratik istismar riski yoktu) ama izin seviyesinde savunma
-- derinliği eksikti.
REVOKE EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1() FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_stock_dish_image_v1(uuid, text, text[], boolean) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_delete_stock_dish_image_v1(uuid) FROM anon;
