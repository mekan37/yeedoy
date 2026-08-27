-- Production'da postgres rolünün oluşturduğu her yeni fonksiyona anon'a otomatik
-- EXECUTE izni veren bir ALTER DEFAULT PRIVILEGES kaydı var (bkz. CLAUDE.md admin_*
-- notu — REVOKE ALL FROM PUBLIC bunu geri almıyor, anon gerçek bir rol). Doğrulama:
-- anon anahtarıyla get_my_recent_activity_v1() çağrısı hata vermek yerine boş dizi
-- döndürdü (auth.uid() NULL olduğu için satır eşleşmiyor ama fonksiyon çağrılabiliyordu).
-- get_my_plan_v1 gibi kardeş "bana özel" fonksiyonlar bu yüzden ayrıca anon'u revoke
-- ediyor — aynı deseni burada da uyguluyoruz.
REVOKE EXECUTE ON FUNCTION public.get_my_recent_activity_v1(int) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_category_preferences_v1(int) FROM anon;
