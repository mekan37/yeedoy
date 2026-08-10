-- Sadakat/Loyalty ölü kod temizliği — iki çakışan eski tasarım + P4 otomasyon
-- eklentisi kaldırılıyor, yerine docs/superpowers/specs/2026-08-10-sadakat-design.md
-- tasarımı gelecek (bu migration'ı takip eden 4 migration'da).
--   20260424000007_loyalty_program.sql      (puan-bazlı tasarım)
--   20260424000010_loyalty_automations.sql  (P4 otomasyon: doğum günü/eşik/missed_you)
--   20260507000008_sadakat_karti.sql        (damga-kartı tasarımı, çakışan 2. tasarım)
-- run_loyalty_automations_v1 cron'u zaten 20260723000003_unschedule_dead_cron_jobs.sql
-- içinde unschedule edilmişti; bu migration fonksiyonun kendisini de kaldırır.

DROP TRIGGER IF EXISTS trg_loyalty_review ON public.reviews;
DROP TRIGGER IF EXISTS trg_loyalty_checkin ON public.business_checkins;

DROP FUNCTION IF EXISTS public.trg_award_loyalty_on_review();
DROP FUNCTION IF EXISTS public.trg_award_loyalty_on_checkin();
DROP FUNCTION IF EXISTS public.award_loyalty_points_v1(uuid, uuid, int);
DROP FUNCTION IF EXISTS public.get_loyalty_status_v1(uuid);
DROP FUNCTION IF EXISTS public.get_my_loyalty_cards_v1();
DROP FUNCTION IF EXISTS public.upsert_loyalty_program_v1(uuid, boolean, int, int, int, int, text, int);
DROP FUNCTION IF EXISTS public.get_business_loyal_customers_v1(uuid, int);
DROP FUNCTION IF EXISTS public.create_loyalty_program_v1(uuid, text, int, text);
DROP FUNCTION IF EXISTS public.add_loyalty_stamp_v1(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_business_automations_v1(uuid);
DROP FUNCTION IF EXISTS public.upsert_business_automation_v1(uuid, text, boolean, text);
DROP FUNCTION IF EXISTS public.run_loyalty_automations_v1();

DROP TABLE IF EXISTS public.loyalty_cards;
DROP TABLE IF EXISTS public.loyalty_accounts;
DROP TABLE IF EXISTS public.loyalty_programs;
DROP TABLE IF EXISTS public.business_automations;
