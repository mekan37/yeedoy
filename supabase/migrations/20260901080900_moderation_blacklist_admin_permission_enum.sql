-- Task 4 (bölüm 1/2): page:kara-liste izin anahtarını admin_permission_key enum'una ekler.
-- Postgres, yeni eklenen enum değerinin aynı transaction içinde (dolaylı da olsa)
-- kullanılmasına izin vermiyor ("unsafe use of new value"), bu yüzden ALTER TYPE
-- ayrı bir migration'da, RPC'leri ve admin_roles.permissions UPDATE'ini içeren
-- 20260901081000_moderation_blacklist_admin_rpcs.sql'den önce commit edilir.

ALTER TYPE public.admin_permission_key ADD VALUE 'page:kara-liste';
