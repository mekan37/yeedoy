-- Sadakat v1 — production güvenlik acil düzeltmesi.
--
-- Proje genelinde yeni oluşturulan fonksiyonlar, ALTER DEFAULT PRIVILEGES
-- ayarı nedeniyle otomatik olarak anon/authenticated rollerine EXECUTE hakkı
-- kazanıyor — REVOKE ALL FROM PUBLIC bunu geri almıyor, ayrıca doğrudan
-- REVOKE ... FROM anon/authenticated gerekiyor (bkz. _get_business_plan_tier_v1,
-- 20260803000001_premium_plan_foundation.sql — bu deseni zaten uyguluyordu).
--
-- 20260810000003/000004 migration'ları bunu atlamıştı. En kritik sonucu:
-- _award_loyalty_progress fonksiyonunun İÇİNDE HİÇBİR yetki kontrolü yok
-- (tasarımı "sadece trigger çağırır" varsayımına dayanıyordu) — bu yüzden
-- kimliksiz (anon) veya oturum açmış herhangi bir kullanıcı bu fonksiyonu
-- doğrudan /rest/v1/rpc/_award_loyalty_progress üzerinden çağırıp keyfi
-- p_amount ile herhangi bir işletmenin sadakat programına sınırsız
-- damga/puan enjekte edebiliyordu. Bu migration hem bu kritik açığı hem de
-- diğer 7 sadakat fonksiyonunun tutarlılık için aynı şekilde kilitlenmesini
-- kapatır (owner/müşteri RPC'leri kendi içlerinde auth.uid() tabanlı kontrol
-- yapıyor, dolayısıyla anon'a açık olmaları kritik değildi, ama proje
-- genelindeki "authenticated-only" tasarım niyetiyle tutarsızdı).

REVOKE EXECUTE ON FUNCTION public._award_loyalty_progress(uuid, uuid, int, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._resolve_loyalty_program_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) FROM anon;
REVOKE EXECUTE ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) FROM anon;
REVOKE EXECUTE ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.redeem_loyalty_reward_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_business_loyalty_members_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_loyalty_cards_v1() FROM anon;
