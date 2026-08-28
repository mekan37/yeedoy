-- =============================================================================
-- Migration: 20260620000001_user_profiles_marketing_email_opt_in.sql
-- =============================================================================
--
-- Karar: R-5 Seçenek B — Global pazarlama e-posta izni user_profiles tablosuna ekleniyor
--
-- Özet:
--   legal-data-inventory.md R-5 ve r5-marketing-optin-data-model-decision.md
--   kararı uyarınca, platform genelinde pazarlama e-posta izni (global opt-in)
--   user_profiles tablosunda iki yeni sütunla modellenmiştir.
--
--   Bu izin, işletme bazlı e-posta aboneliğinden (business_follows.is_subscribed_email)
--   kavramsal olarak ayrıdır ve ayrı tutulmalıdır.
--
--   Eklenen sütunlar:
--     - marketing_email_opt_in boolean NOT NULL DEFAULT false
--         Kullanıcının platform genelinde pazarlama e-postası almak isteyip
--         istemediğini gösterir. DEFAULT false — mevcut ve yeni kullanıcılar
--         otomatik olarak opt-out durumunda başlar.
--     - marketing_email_opted_in_at timestamptz NULL
--         Kullanıcının son opt-in yaptığı zaman damgası. KVKK ispat yükümlülüğü
--         için korunur. Kullanıcı izni geri çektiğinde NULL yapılır.
--
--   Yapılmayanlar (kesin kısıtlar):
--     - business_follows.is_subscribed_email alanına dokunulmaz
--     - Mevcut RLS policy'lere dokunulmaz
--     - Mevcut kullanıcılar otomatik opt-in yapılmaz (DEFAULT false güvencesi)
--
--   RLS etki analizi:
--     user_profiles tablosunda mevcut policy "profiles_update_own":
--       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())
--     Yeni sütunlar bu policy kapsamına otomatik girer. Ek policy gerekmez.
--     Okuma için mevcut "profiles_read" policy (USING true) yeterlidir.
--     Ancak marketing_email_opt_in değeri yalnızca RPC üzerinden güncellenmeli
--     (bkz. 20260620000002); doğrudan UPDATE güvenli ama RPC daha kontrollüdür.
--
--   Rollback:
--     ALTER TABLE public.user_profiles
--       DROP COLUMN IF EXISTS marketing_email_opted_in_at,
--       DROP COLUMN IF EXISTS marketing_email_opt_in;
--     UYARI: rollback veri kaybına yol açar; opt-in kayıtları silinir.
--
--   Tarih: 2026-06-20
--   Karar referansı: docs/arsiv/r5-marketing-optin-data-model-decision.md Bölüm 4
--   Hazırlayan: postgres-pro (R-5 Seçenek B)
-- =============================================================================


-- =============================================================================
-- BÖLÜM 1: user_profiles tablosuna global pazarlama izni sütunları ekleniyor
-- =============================================================================

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS marketing_email_opt_in boolean NOT NULL DEFAULT false;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS marketing_email_opted_in_at timestamptz NULL;

-- Sütun açıklamaları — KVKK ve teknik dokümantasyon için
COMMENT ON COLUMN public.user_profiles.marketing_email_opt_in IS
  'Kullanıcının platform genelinde Yeedoy pazarlama e-postası almak isteyip istemediği. '
  'DEFAULT false — yeni ve mevcut kullanıcılar otomatik opt-out durumunda başlar. '
  'Yalnızca update_my_marketing_email_opt_in_v1 RPC üzerinden güncellenmeli. '
  'R-5 Seçenek B (2026-06-20). '
  'İşletme bazlı e-posta aboneliği için business_follows.is_subscribed_email kullanılır; '
  'bu iki alan birbirinden bağımsızdır.';

COMMENT ON COLUMN public.user_profiles.marketing_email_opted_in_at IS
  'Kullanıcının global pazarlama e-posta iznini son verdiği zaman damgası. '
  'opt-in sırasında now() ile doldurulur; opt-out sırasında NULL yapılır. '
  'KVKK ispat yükümlülüğü için korunur. '
  'R-5 Seçenek B (2026-06-20). Çağıran: update_my_marketing_email_opt_in_v1.';
