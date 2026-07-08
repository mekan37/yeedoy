-- =============================================================================
-- Migration: 20260619000001_remove_ip_metadata_from_policy_acceptances.sql
-- =============================================================================
--
-- Karar: R-4 Seçenek B — IP metadata sessiz kaydını politika kabul tablolarından kaldır
--
-- Özet:
--   Bu migration, KVKK md. 10 (aydınlatma yükümlülüğü) ve KVKK md. 4/2-ç
--   (veri minimizasyon ilkesi) kapsamında alınan "Seçenek B" kararını uygular.
--
--   Yapılanlar:
--     1. capture_request_metadata_v1() fonksiyonu yeniden tanımlanır:
--          - ip_address ve user_agent otomatik doldurma bloğu çıkarılır
--          - user_id, accepted_at, submitted_at, requested_at doldurma mantığı korunur
--     2. user_policy_acceptances tablosundaki mevcut ip_address ve user_agent
--        değerleri NULL'a güncellenir (geçmiş veri temizliği)
--     3. business_policy_acceptances tablosundaki mevcut ip_address ve user_agent
--        değerleri NULL'a güncellenir
--
--   Yapılmayanlar (kesin yasaklar):
--     - DROP COLUMN yok
--     - RLS policy değişikliği yok
--     - privacy_requests / account_deletion_requests tablolarına dokunulmaz
--     - request_ip_v1() ve request_header_v1() fonksiyonları silinmez
--       (admin_audit_log akışı capture_request_meta_v1() üzerinden bu helper'ları kullanır)
--     - Flutter UI değişikliği bu migration kapsamında değildir
--
--   Etkilenen nesneler:
--     - FONKSIYON: public.capture_request_metadata_v1() — yeniden tanımlanır
--     - TABLO VERİSİ: user_policy_acceptances (ip_address, user_agent → NULL)
--     - TABLO VERİSİ: business_policy_acceptances (ip_address, user_agent → NULL)
--
--   Dokunulmayan nesneler:
--     - public.request_ip_v1()
--     - public.request_header_v1()
--     - public.capture_request_meta_v1()
--     - public.privacy_requests
--     - public.account_deletion_requests
--     - Tüm RLS policy'ler
--     - Tüm trigger tanımları (isimler korunur, aynı fonksiyon çağrılmaya devam eder)
--
--   Rollback:
--     Sütunlar DROP EDİLMEDİĞİ için geri alınabilir. Önceki capture_request_metadata_v1()
--     tanımı aşağıda yorum olarak korunmuştur; rollback migration bu bloğu yeniden
--     CREATE OR REPLACE ile uygulayabilir. NULL'lanan eski IP verileri geri gelmez
--     (amaçsız veri — kabul edilebilir).
--
--   Tarih: 2026-06-19
--   Hazırlayan: postgres-pro (R-4 Seçenek B kararı)
-- =============================================================================


-- =============================================================================
-- BÖLÜM 1: capture_request_metadata_v1() fonksiyonunu yeniden tanımla
--           IP/UA doldurma bloğunu çıkar; user_id ve zaman damgası mantığını koru
-- =============================================================================

CREATE OR REPLACE FUNCTION public.capture_request_metadata_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
-- R-4 Seçenek B (2026-06-19): ip_address ve user_agent otomatik doldurma kaldırıldı.
-- KVKK md. 10 aydınlatma yükümlülüğü ve md. 4/2-ç veri minimizasyon ilkesi gereği.
-- user_id / accepted_at / submitted_at / requested_at doldurma korunmaktadır.
BEGIN
  -- user_id doldurma: user_policy_acceptances, privacy_requests, account_deletion_requests
  IF tg_table_name IN ('user_policy_acceptances', 'privacy_requests', 'account_deletion_requests')
     AND coalesce(to_jsonb(NEW)->>'user_id', '') = '' THEN
    NEW := jsonb_populate_record(NEW, jsonb_build_object('user_id', auth.uid()));
  END IF;

  -- accepted_at doldurma: user_policy_acceptances, business_policy_acceptances
  -- NOT: ip_address ve user_agent doldurma bu bloktan kaldırıldı (R-4 Seçenek B)
  IF tg_table_name IN ('user_policy_acceptances', 'business_policy_acceptances') THEN
    IF coalesce(to_jsonb(NEW)->>'accepted_at', '') = '' THEN
      NEW := jsonb_populate_record(NEW, jsonb_build_object('accepted_at', now()));
    END IF;
  END IF;

  -- submitted_at doldurma: privacy_requests
  IF tg_table_name = 'privacy_requests'
     AND coalesce(to_jsonb(NEW)->>'submitted_at', '') = '' THEN
    NEW := jsonb_populate_record(NEW, jsonb_build_object('submitted_at', now()));
  END IF;

  -- requested_at doldurma: account_deletion_requests
  IF tg_table_name = 'account_deletion_requests'
     AND coalesce(to_jsonb(NEW)->>'requested_at', '') = '' THEN
    NEW := jsonb_populate_record(NEW, jsonb_build_object('requested_at', now()));
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.capture_request_metadata_v1() IS
  'BEFORE INSERT trigger: user_id / accepted_at / submitted_at / requested_at otomatik doldurur. '
  'ip_address ve user_agent doldurma R-4 Seçenek B kararıyla 2026-06-19 tarihinde kaldırıldı '
  '(KVKK md. 10 aydınlatma + md. 4/2-ç veri minimizasyon). '
  'Çağıranlar: trg_user_policy_acceptances_capture_request_metadata_v1, '
  'trg_business_policy_acceptances_capture_request_metadata_v1, '
  'trg_privacy_requests_capture_request_metadata_v1, '
  'trg_account_deletion_requests_capture_request_metadata_v1.';


-- =============================================================================
-- BÖLÜM 2: Geçmiş veri temizliği — user_policy_acceptances
--           Mevcut kayıtlardaki ip_address ve user_agent NULL'a çekilir
-- =============================================================================

-- Sütunların varlığını bilgi şeması üzerinden kontrol etmeden doğrudan güncelliyoruz.
-- Her iki sütun da base schema'da inet null / text null olarak tanımlıdır;
-- NOT NULL kısıtı yok. UPDATE güvenle çalışır.

UPDATE public.user_policy_acceptances
SET
  ip_address = NULL,
  user_agent = NULL
WHERE
  ip_address IS NOT NULL
  OR user_agent IS NOT NULL;


-- =============================================================================
-- BÖLÜM 3: Geçmiş veri temizliği — business_policy_acceptances
--           Mevcut kayıtlardaki ip_address ve user_agent NULL'a çekilir
-- =============================================================================

UPDATE public.business_policy_acceptances
SET
  ip_address = NULL,
  user_agent = NULL
WHERE
  ip_address IS NOT NULL
  OR user_agent IS NOT NULL;


-- =============================================================================
-- ROLLBACK REFEREransı (yorum olarak korundu — production'da çalıştırmayın)
-- =============================================================================
-- Geri almak gerekirse: yeni bir migration dosyası oluşturun ve içinde
-- aşağıdaki CREATE OR REPLACE bloğunu çalıştırın:
--
-- CREATE OR REPLACE FUNCTION public.capture_request_metadata_v1()
-- RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
-- begin
--   if tg_table_name in ('user_policy_acceptances', 'privacy_requests', 'account_deletion_requests')
--      and coalesce(to_jsonb(new)->>'user_id', '') = '' then
--     new := jsonb_populate_record(new, jsonb_build_object('user_id', auth.uid()));
--   end if;
--   if tg_table_name in ('user_policy_acceptances', 'business_policy_acceptances') then
--     if coalesce(to_jsonb(new)->>'accepted_at', '') = '' then
--       new := jsonb_populate_record(new, jsonb_build_object('accepted_at', now()));
--     end if;
--     if coalesce(to_jsonb(new)->>'user_agent', '') = '' then
--       new := jsonb_populate_record(new,
--               jsonb_build_object('user_agent', public.request_header_v1('user-agent')));
--     end if;
--     if coalesce(to_jsonb(new)->>'ip_address', '') = '' then
--       new := jsonb_populate_record(new,
--               jsonb_build_object('ip_address', public.request_ip_v1()));
--     end if;
--   end if;
--   if tg_table_name = 'privacy_requests' and coalesce(to_jsonb(new)->>'submitted_at', '') = '' then
--     new := jsonb_populate_record(new, jsonb_build_object('submitted_at', now()));
--   end if;
--   if tg_table_name = 'account_deletion_requests' and coalesce(to_jsonb(new)->>'requested_at', '') = '' then
--     new := jsonb_populate_record(new, jsonb_build_object('requested_at', now()));
--   end if;
--   return new;
-- end;
-- $$;
-- =============================================================================
