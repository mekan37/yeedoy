-- Postgres, fonksiyon oluşturulduğunda varsayılan olarak PUBLIC pseudo-role'üne
-- EXECUTE veriyor. anon rolü PUBLIC'e dahil olduğundan, önceki migration'daki
-- (20260912000001) "REVOKE EXECUTE ... FROM anon" bunu düzeltmedi — anon
-- PUBLIC üzerinden hâlâ çalıştırabiliyordu (get_advisors + has_function_privilege
-- ile doğrulandı: has_function_privilege('anon', ..., 'EXECUTE') = true).
-- Kök nedeni kapatmak için PUBLIC'ten de açıkça revoke ediliyor.

REVOKE EXECUTE ON FUNCTION public.admin_set_shadow_banned_v1(uuid[], boolean) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_moderate_business_media_v1(uuid, text, boolean, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_update_privacy_request_status_v1(uuid, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_set_shadow_banned_v1(uuid[], boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_moderate_business_media_v1(uuid, text, boolean, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_privacy_request_status_v1(uuid, text) TO authenticated;
