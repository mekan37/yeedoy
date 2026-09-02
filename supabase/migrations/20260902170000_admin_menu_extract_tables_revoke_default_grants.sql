-- Kod inceleme bulgusu: admin_menu_extract_jobs/items tabloları RLS ile korunuyor
-- (policy yok, tüm erişim SECURITY DEFINER RPC'ler üzerinden) ama standing
-- ALTER DEFAULT PRIVILEGES kaydı (postgres rolünün oluşturduğu her yeni tabloya
-- anon/authenticated'a ALL GRANT eder) bu iki tabloyu da otomatik kapsamıştı.
-- RLS, TRUNCATE'i kapsamaz (Postgres'in belgelenmiş bir tasarım gerçeği) — bu
-- proje bu deseni daha önce 2 kez düzeltti (moderation_blacklist_terms,
-- 20260901090000_revoke_truncate_default_privilege_all_public_objects).
REVOKE ALL ON TABLE public.admin_menu_extract_jobs FROM anon, authenticated;
REVOKE ALL ON TABLE public.admin_menu_extract_items FROM anon, authenticated;
