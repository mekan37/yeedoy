-- Task 13 doğrulama turunda Supabase security advisor'da bulundu: owner_upsert_campaign_v1
-- (tek başına, kardeş fonksiyonların (_check_plan_limit_v1, get_my_plan_v1,
-- upsert_team_member_v1, owner_add_business_to_chain_v1, create_support_ticket_v1) hiçbirinde
-- olmayan) production'da anon rolüne EXECUTE izni vermiş durumdaydı. Orijinal migration
-- (20260710000002_campaigns.sql) yalnızca "GRANT EXECUTE ... TO authenticated" içeriyordu —
-- anon hiç kastedilmemişti. Fonksiyonun kendi içindeki auth.uid() IS NULL kontrolü zaten
-- anon çağrılarını reddediyordu (fonksiyonel istismar riski yoktu) ama izin, tasarım
-- niyetiyle ve tüm kardeş fonksiyonlarla tutarsızdı. Kapatılıyor.
REVOKE EXECUTE ON FUNCTION public.owner_upsert_campaign_v1(
  UUID, TEXT, TEXT, TEXT, TEXT, SMALLINT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, UUID
) FROM anon;
