-- =============================================================================
-- Migration: 20260620000002_r5_marketing_email_rpcs.sql
-- =============================================================================
--
-- Karar: R-5 Seçenek B — Global pazarlama izni ve işletme bazlı e-posta
--         aboneliği için üç RPC oluşturuluyor
--
-- Bu migration 20260620000001 sonrası çalıştırılmalıdır.
--
-- Oluşturulan RPC'ler:
--   1. get_my_notification_preferences_v1()
--        Kullanıcının kendi notification/pazarlama tercihlerini okur.
--        Döndürülenler: marketing_email_opt_in, marketing_email_opted_in_at
--
--   2. update_my_marketing_email_opt_in_v1(p_value boolean)
--        Kullanıcının global platform pazarlama e-posta iznini günceller.
--        - p_value = true  → marketing_email_opt_in = true, opted_in_at = now()
--        - p_value = false → marketing_email_opt_in = false, opted_in_at = NULL
--        Yalnızca auth.uid() kullanıcısının kendi kaydını günceller.
--
--   3. update_business_follow_email_subscription_v1(p_business_id, p_subscribed)
--        Kullanıcının belirli bir işletme takibindeki is_subscribed_email değerini günceller.
--        Yalnızca mevcut takip ilişkisi için çalışır; yoksa not_found hatası verir.
--        Global marketing_email_opt_in alanına dokunmaz.
--
-- Güvenlik:
--   - Tüm RPC'ler SECURITY DEFINER + SET search_path = public
--   - auth.uid() IS NULL kontrolü her RPC'de zorunlu
--   - Kullanıcı yalnızca kendi kaydını okuyup güncelleyebilir
--   - business_follows'ta RLS UPDATE policy yoktur; bu RPC tablo-level
--     güncellemeyi SECURITY DEFINER aracılığıyla güvenli biçimde sağlar
--
-- Tarih: 2026-06-20
-- Karar referansı: docs/legal/r5-marketing-optin-data-model-decision.md Bölüm 5
-- Hazırlayan: postgres-pro (R-5 Seçenek B)
-- =============================================================================


-- =============================================================================
-- RPC 1: get_my_notification_preferences_v1
--        Kullanıcının pazarlama ve bildirim tercihlerini okur
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_my_notification_preferences_v1()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row record;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT
    marketing_email_opt_in,
    marketing_email_opted_in_at
  INTO v_row
  FROM public.user_profiles
  WHERE user_id = v_uid;

  -- user_profiles kaydı henüz oluşturulmamışsa (edge case: kayıt yeni oluşturuluyor)
  -- DEFAULT değerlerle yanıt ver
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'marketing_email_opt_in',      false,
      'marketing_email_opted_in_at', null
    );
  END IF;

  RETURN jsonb_build_object(
    'marketing_email_opt_in',      v_row.marketing_email_opt_in,
    'marketing_email_opted_in_at', v_row.marketing_email_opted_in_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_notification_preferences_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_notification_preferences_v1() TO authenticated;

COMMENT ON FUNCTION public.get_my_notification_preferences_v1() IS
  'Kullanıcının kendi global pazarlama e-posta izin durumunu döndürür. '
  'Alanlar: marketing_email_opt_in (bool), marketing_email_opted_in_at (timestamptz|null). '
  'R-5 Seçenek B. Çağıranlar: notification_preferences_page.dart, legal_acceptance_page.dart.';


-- =============================================================================
-- RPC 2: update_my_marketing_email_opt_in_v1
--        Kullanıcının global platform pazarlama e-posta iznini günceller
-- =============================================================================

CREATE OR REPLACE FUNCTION public.update_my_marketing_email_opt_in_v1(
  p_value boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  -- p_value NULL geçilmesini engelle — boolean tipi kontrol
  IF p_value IS NULL THEN
    RAISE EXCEPTION 'validation_error: p_value NULL olamaz' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.user_profiles
  SET
    marketing_email_opt_in     = p_value,
    -- true ise opted_in_at = now(); false ise opted_in_at = NULL (ispat: son izin zamanı)
    marketing_email_opted_in_at = CASE
                                    WHEN p_value = true  THEN now()
                                    WHEN p_value = false THEN NULL
                                  END,
    updated_at                  = now()
  WHERE user_id = v_uid;

  -- user_profiles kaydı yoksa: sessizce başarılı say (kayıt henüz oluşturulmamış olabilir)
  -- Flutter tarafı zaten upsert ile profil oluşturduğundan bu edge case nadirdir
  IF NOT FOUND THEN
    RAISE WARNING 'update_my_marketing_email_opt_in_v1: user_profiles kaydı bulunamadı, user_id=%', v_uid;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_marketing_email_opt_in_v1(boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_my_marketing_email_opt_in_v1(boolean) TO authenticated;

COMMENT ON FUNCTION public.update_my_marketing_email_opt_in_v1(boolean) IS
  'Kullanıcının global platform pazarlama e-posta iznini günceller. '
  'p_value=true → marketing_email_opt_in=true + opted_in_at=now(). '
  'p_value=false → marketing_email_opt_in=false + opted_in_at=NULL. '
  'business_follows.is_subscribed_email alanına DOKUNMAZ. '
  'R-5 Seçenek B. Çağıranlar: legal_acceptance_page.dart, notification_preferences_page.dart.';


-- =============================================================================
-- RPC 3: update_business_follow_email_subscription_v1
--        İşletme bazlı e-posta abonelik durumunu günceller
-- =============================================================================

CREATE OR REPLACE FUNCTION public.update_business_follow_email_subscription_v1(
  p_business_id uuid,
  p_subscribed  boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: p_business_id NULL olamaz' USING ERRCODE = 'P0003';
  END IF;

  IF p_subscribed IS NULL THEN
    RAISE EXCEPTION 'validation_error: p_subscribed NULL olamaz' USING ERRCODE = 'P0003';
  END IF;

  -- Yalnızca kendi takip ilişkisini güncelle
  -- business_follows.is_subscribed_email: işletme bazlı abonelik bayrağı
  -- user_profiles.marketing_email_opt_in: global platform izni (bu RPC DOKUNMAZ)
  UPDATE public.business_follows
  SET is_subscribed_email = p_subscribed
  WHERE user_id     = v_uid
    AND business_id = p_business_id;

  -- Kullanıcının bu işletmeyi takip etmediği durumda hata ver
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Takip ilişkisi bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_business_follow_email_subscription_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_business_follow_email_subscription_v1(uuid, boolean) TO authenticated;

COMMENT ON FUNCTION public.update_business_follow_email_subscription_v1(uuid, boolean) IS
  'İşletme bazlı e-posta abonelik durumunu günceller (business_follows.is_subscribed_email). '
  'Yalnızca auth.uid() kullanıcısının kendi takip ilişkisi güncellenebilir. '
  'Takip ilişkisi yoksa P0001 not_found hatası verir. '
  'user_profiles.marketing_email_opt_in (global platform izni) alanına DOKUNMAZ. '
  'R-5 Seçenek B. Çağıranlar: business_profile_repository.dart (yeni), '
  'unsubscribe endpoint (web/api/unsubscribe/route.ts).';


-- =============================================================================
-- BÖLÜM 4: business_follows için UPDATE RLS policy ekleniyor
-- =============================================================================
--
-- Mevcut durum (base_schema + tüm migration'lar):
--   business_follows'ta SELECT, INSERT, DELETE policy'leri mevcut.
--   UPDATE policy yok — tablo GRANT ALL authenticated olduğundan doğrudan
--   UPDATE çalışıyor ancak row-level guard yok.
--
-- Bu migration SECURITY DEFINER RPC kullandığından doğrudan client UPDATE'i
-- kapatmak en güvenli yaklaşımdır. Ancak mevcut kod doğrudan UPDATE yapan
--  bir path içerebilir (örn. follow_business_v1 onConflict doNothing).
--
-- Güvenli çözüm: Ayrı bir UPDATE policy ekle — kullanıcı yalnızca kendi
-- satırını güncelleyebilsin. Bu SECURITY DEFINER RPC'leri etkilemez.
-- Hatalı kullanıma (yanlış user_id ile UPDATE) karşı ek koruma sağlar.

DO $$
BEGIN
  -- Önceki versiyonu temizle (idempotent)
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'business_follows'
      AND policyname = 'business_follows_update_own'
  ) THEN
    EXECUTE 'DROP POLICY business_follows_update_own ON public.business_follows';
  END IF;
END;
$$;

CREATE POLICY "business_follows_update_own"
  ON public.business_follows
  FOR UPDATE
  TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

COMMENT ON POLICY "business_follows_update_own" ON public.business_follows IS
  'Kullanıcı yalnızca kendi takip kaydını güncelleyebilir. '
  'is_subscribed_email güncellemesi için update_business_follow_email_subscription_v1 '
  'SECURITY DEFINER RPC kullanılması önerilir. '
  'R-5 Seçenek B (2026-06-20).';
