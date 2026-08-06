-- ROLLBACK:
-- DROP TRIGGER IF EXISTS trg_protect_price_level ON public.businesses;
-- DROP FUNCTION IF EXISTS public.tg_protect_price_level();

-- ============================================================
-- businesses.price_level yazma koruması
--
-- Mevcut durum (base_schema.sql satır 26913):
--   "businesses_update_owner_admin" policy:
--     FOR UPDATE TO authenticated
--     USING (is_admin() OR is_owner_of_business(id))
--     WITH CHECK (is_admin() OR is_owner_of_business(id))
--
-- Sorun: Bu policy, authenticated owner/admin'in tüm sütunları
-- güncellemesine izin veriyor. price_level sadece compute_business_price_level_v1
-- (SECURITY DEFINER, service_role kontekstinde çalışır) tarafından
-- yazılmalı; owner veya admin doğrudan UPDATE ile değiştirmemeli.
--
-- Çözüm: BEFORE UPDATE trigger.
--   - auth.role() = 'service_role' ise (SECURITY DEFINER içinden) → geç
--   - is_admin() true ise → geç (admin doğrudan müdahale edebilir)
--   - Diğer tüm durumlar (authenticated owner) → eski değeri koru
--
-- Neden trigger, column-level security (CLS) değil?
--   Supabase / PostgreSQL'de CLS (column-level privilege) RLS ile tam
--   entegre çalışmıyor; GRANT UPDATE(col) / REVOKE UPDATE(col) pattern'i
--   Supabase client tarafında hata yaratıyor. Trigger daha taşınabilir
--   ve öngörülebilir bir koruma sağlar.
-- ============================================================

CREATE OR REPLACE FUNCTION public.tg_protect_price_level()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- service_role (SECURITY DEFINER batch RPC) veya admin → serbest bırak
  IF auth.role() = 'service_role' OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- Diğer tüm çağrıcılar (owner vb.) price_level'i değiştirmeye çalışırsa
  -- eski değeri geri yaz — sessizce (hata fırlatmadan).
  -- Sessiz davranış tercih edilir: owner panel diğer alanları güncellerken
  -- sadece price_level'in korunmasını istiyor; UPDATE hata vermemeli.
  IF NEW.price_level IS DISTINCT FROM OLD.price_level THEN
    NEW.price_level := OLD.price_level;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger: authenticated client (owner, vb.) UPDATE denemelerini yakalar
-- 2026-08-06 fix: production'a push denemesinde bulunan drift'in bir parçası
-- olarak idempotent hale getirildi (DROP IF EXISTS + CREATE).
DROP TRIGGER IF EXISTS trg_protect_price_level ON public.businesses;
CREATE TRIGGER trg_protect_price_level
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.tg_protect_price_level();

COMMENT ON FUNCTION public.tg_protect_price_level() IS
  'businesses.price_level sütununu yetkisiz UPDATE''den korur. '
  'service_role veya is_admin() → geçer. Diğerleri → eski değer korunur. '
  'Supabase column-level security yerine kullanıldı (CLS RLS ile entegre değil). '
  'Callers: trg_protect_price_level trigger (businesses tablosunda BEFORE UPDATE).';

COMMENT ON TRIGGER trg_protect_price_level ON public.businesses IS
  'authenticated owner/kullanıcıların price_level sütununu değiştirmesini engeller. '
  'service_role (compute/batch RPC) ve is_admin() bypass eder.';
