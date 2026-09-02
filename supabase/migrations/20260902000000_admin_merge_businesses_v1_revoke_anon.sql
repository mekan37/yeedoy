-- Kod kalitesi incelemesi bulgusu (işletme birleştirme özelliği eklenirken): admin_merge_businesses_v1
-- (daha önce hiç kullanılmayan, şimdi bu özellikle canlı hale gelen bir admin_* RPC)
-- hâlâ anon'a GRANT edilmişti (base_schema.sql'den kalma). is_admin() body-içi kontrolü
-- koruyor ama CLAUDE.md'nin belgelediği ve 3 kez production düzeltmesine yol açan
-- aynı desen — açıkça REVOKE şart.
REVOKE EXECUTE ON FUNCTION public.admin_merge_businesses_v1(uuid, uuid, text, boolean) FROM anon;
