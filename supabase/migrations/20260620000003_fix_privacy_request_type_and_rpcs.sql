-- =============================================================================
-- Migration: 20260620000003_fix_privacy_request_type_and_rpcs.sql
-- =============================================================================
--
-- Amaç: Veri silme / hesap silme backend sorunlarını düzelt
--
-- Sorunlar (data-deletion-page-alignment-report.md kaynaklı):
--   1. privacy_requests.request_type CHECK constraint'i 'delete_data',
--      'delete_interactions', 'delete_support', 'delete_owner_claims', 'other'
--      değerlerini REDDEDIYOR. Flutter UI bu değerleri gönderiyor → runtime hata.
--   2. submit_privacy_request_v1 RPC yoktu; Flutter doğrudan INSERT yapıyordu.
--      CHECK constraint bypass için RPC katmanı gerekiyor.
--   3. submit_account_deletion_request_v1 RPC yoktu; Flutter doğrudan INSERT yapıyordu.
--      Duplicate engeli ve auth kontrolü için RPC katmanı gerekiyor.
--
-- Yapılanlar:
--   1. privacy_requests.request_type CHECK constraint genişletiliyor:
--      Mevcut 8 değer KORUNUYOR + 5 yeni değer ekleniyor:
--        delete_data, delete_interactions, delete_support,
--        delete_owner_claims, other
--   2. submit_privacy_request_v1(p_request_type, p_details) RPC oluşturuluyor
--   3. submit_account_deletion_request_v1(p_reason) RPC oluşturuluyor
--
-- Yapılmayanlar (kesin yasaklar):
--   - DROP COLUMN yok
--   - ip_address / user_agent ekleme yok
--   - Pazarlama opt-out RPC'lerine dokunulmuyor
--   - Mevcut RLS policy silinmiyor
--   - Flutter dosyaları bu migration kapsamında değil
--   - production'a doğrudan push edilmiyor
--
-- Bağımlılıklar:
--   - 20260619000001_remove_ip_metadata_from_policy_acceptances.sql
--   - 20260620000001_user_profiles_marketing_email_opt_in.sql
--   - 20260620000002_r5_marketing_email_rpcs.sql
--
-- Tarih: 2026-06-19
-- Hazırlayan: postgres-pro
-- =============================================================================


-- =============================================================================
-- BÖLÜM 1: privacy_requests.request_type CHECK constraint genişletme
--
-- Mevcut constraint (base schema):
--   CONSTRAINT "privacy_requests_request_type_check" CHECK (
--     request_type = ANY (ARRAY[
--       'data_export', 'privacy_application', 'access', 'rectification',
--       'erasure', 'restriction', 'objection', 'portability'
--     ])
--   )
--
-- Yeni değerler ekleniyor (Flutter UI + veri-silme-talebi.md uyumu):
--   'delete_data'           — Hesabımı silme talebi (eski genel kullanım)
--   'delete_interactions'   — Yorum / favori / check-in verisi silme talebi
--   'delete_support'        — Destek talebi geçmişi silme talebi
--   'delete_owner_claims'   — İşletme sahipliği başvurusu silme talebi
--   'other'                 — Diğer
--
-- Güvenlik: Mevcut kayıtlar bu değerleri içermiyor (runtime INSERT hatasından
-- dolayı hiç yazılamamış). DROP + ADD CONSTRAINT güvenle uygulanabilir.
-- =============================================================================

ALTER TABLE public.privacy_requests
  DROP CONSTRAINT IF EXISTS privacy_requests_request_type_check;

ALTER TABLE public.privacy_requests
  ADD CONSTRAINT privacy_requests_request_type_check
  CHECK (
    request_type = ANY (ARRAY[
      -- Mevcut (korunan) değerler
      'data_export'::text,
      'privacy_application'::text,
      'access'::text,
      'rectification'::text,
      'erasure'::text,
      'restriction'::text,
      'objection'::text,
      'portability'::text,
      -- Yeni eklenen değerler (Flutter UI + KVKK veri silme talebi kategorileri)
      'delete_data'::text,
      'delete_interactions'::text,
      'delete_support'::text,
      'delete_owner_claims'::text,
      'other'::text
    ])
  );

COMMENT ON CONSTRAINT privacy_requests_request_type_check ON public.privacy_requests IS
  'İzin verilen talep türleri. Orijinal 8 KVKK türü + 5 uygulama türü. '
  '2026-06-19 genişletildi: delete_data, delete_interactions, delete_support, '
  'delete_owner_claims, other eklendi (veri-silme-talebi.md Bölüm 4 uyumu).';


-- =============================================================================
-- BÖLÜM 2: submit_privacy_request_v1 RPC
--
-- Güvenlik:
--   - auth.uid() IS NULL → P0002 unauthorized
--   - p_request_type CHECK listesi dışında → P0003 validation_error
--   - Aynı kullanıcıdan açık (submitted/in_review) talep varsa → P0003 validation_error
--   - INSERT: user_id = auth.uid(), submitted_at = now(), status = 'submitted'
--   - SECURITY DEFINER + SET search_path = public
--   - REVOKE ALL FROM PUBLIC; GRANT EXECUTE TO authenticated
--
-- Çağıranlar: Flutter LegalRepository.submitPrivacyRequest()
-- =============================================================================

CREATE OR REPLACE FUNCTION public.submit_privacy_request_v1(
  p_request_type text,
  p_details      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid          uuid;
  v_open_count   int;
  v_allowed_types text[] := ARRAY[
    'data_export', 'privacy_application', 'access', 'rectification',
    'erasure', 'restriction', 'objection', 'portability',
    'delete_data', 'delete_interactions', 'delete_support',
    'delete_owner_claims', 'other'
  ];
BEGIN
  -- Kimlik doğrulama
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor'
      USING ERRCODE = 'P0002';
  END IF;

  -- Talep türü doğrulama
  IF p_request_type IS NULL OR NOT (p_request_type = ANY(v_allowed_types)) THEN
    RAISE EXCEPTION 'validation_error: Geçersiz talep türü: %', p_request_type
      USING ERRCODE = 'P0003';
  END IF;

  -- Açık talep tekrar engeli (submitted veya in_review)
  SELECT COUNT(*)
    INTO v_open_count
    FROM public.privacy_requests
   WHERE user_id = v_uid
     AND status = ANY(ARRAY['submitted', 'in_review']);

  IF v_open_count > 0 THEN
    RAISE EXCEPTION 'validation_error: Bu kullanıcı için zaten açık bir gizlilik talebi mevcut'
      USING ERRCODE = 'P0003';
  END IF;

  -- Talebi kaydet
  INSERT INTO public.privacy_requests (
    user_id,
    request_type,
    status,
    details,
    submitted_at
  ) VALUES (
    v_uid,
    p_request_type,
    'submitted',
    COALESCE(TRIM(p_details), ''),
    now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_privacy_request_v1(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_privacy_request_v1(text, text) TO authenticated;

COMMENT ON FUNCTION public.submit_privacy_request_v1(text, text) IS
  'KVKK kapsamında gizlilik / veri silme talebi oluşturur. '
  'p_request_type: izin verilen değerler için privacy_requests_request_type_check constraint bakın. '
  'Açık (submitted/in_review) talep varsa P0003 döner. '
  'Çağıranlar: Flutter LegalRepository.submitPrivacyRequest(). '
  'Oluşturuldu: 2026-06-19.';


-- =============================================================================
-- BÖLÜM 3: submit_account_deletion_request_v1 RPC
--
-- Güvenlik:
--   - auth.uid() IS NULL → P0002 unauthorized
--   - Aynı kullanıcıdan açık (requested/in_review) talep varsa → P0003 validation_error
--   - INSERT: user_id = auth.uid(), requested_at = now(), status = 'requested'
--   - SECURITY DEFINER + SET search_path = public
--   - REVOKE ALL FROM PUBLIC; GRANT EXECUTE TO authenticated
--
-- Not: account_deletion_requests tablosunda zaten unique index var:
--   account_deletion_requests_one_open_per_user_idx ON (user_id) WHERE status IN
--   ('requested','in_review'). RPC düzeyinde önceden kontrol yapıyoruz; DB index
--   son güvencedir.
--
-- Çağıranlar: Flutter LegalRepository.submitAccountDeletionRequest()
-- =============================================================================

CREATE OR REPLACE FUNCTION public.submit_account_deletion_request_v1(
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid        uuid;
  v_open_count int;
BEGIN
  -- Kimlik doğrulama
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor'
      USING ERRCODE = 'P0002';
  END IF;

  -- Açık talep tekrar engeli (requested veya in_review)
  SELECT COUNT(*)
    INTO v_open_count
    FROM public.account_deletion_requests
   WHERE user_id = v_uid
     AND status = ANY(ARRAY['requested', 'in_review']);

  IF v_open_count > 0 THEN
    RAISE EXCEPTION 'validation_error: Bu kullanıcı için zaten açık bir hesap silme talebi mevcut'
      USING ERRCODE = 'P0003';
  END IF;

  -- Talebi kaydet
  INSERT INTO public.account_deletion_requests (
    user_id,
    reason,
    status,
    requested_at
  ) VALUES (
    v_uid,
    COALESCE(TRIM(p_reason), ''),
    'requested',
    now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_account_deletion_request_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_account_deletion_request_v1(text) TO authenticated;

COMMENT ON FUNCTION public.submit_account_deletion_request_v1(text) IS
  'Hesap silme talebi oluşturur. account_deletion_requests tablosuna yazar. '
  'p_reason: isteğe bağlı açıklama metni. '
  'Açık (requested/in_review) talep varsa P0003 döner. '
  'Çağıranlar: Flutter LegalRepository.submitAccountDeletionRequest(). '
  'Oluşturuldu: 2026-06-19.';


-- =============================================================================
-- BÖLÜM 4: RLS policy doğrulama (mevcut policy'ler yeterli — ek gerekmez)
--
-- privacy_requests mevcut RLS:
--   - ENABLE ROW LEVEL SECURITY ✓
--   - privacy_requests_insert_own: FOR INSERT TO authenticated
--       WITH CHECK (user_id = auth.uid()) ✓
--   - privacy_requests_select_own: FOR SELECT TO authenticated
--       USING (is_admin() OR user_id = auth.uid()) ✓
--
-- account_deletion_requests mevcut RLS:
--   - ENABLE ROW LEVEL SECURITY ✓
--   - account_deletion_requests_insert_own: FOR INSERT TO authenticated
--       WITH CHECK (user_id = auth.uid()) ✓
--   - account_deletion_requests_select_own: FOR SELECT TO authenticated
--       USING (is_admin() OR user_id = auth.uid()) ✓
--
-- NOT: RPC'ler SECURITY DEFINER olduğu için RLS bu bağlamda bypass edilir;
-- ancak RPC içinde auth.uid() manuel kontrolü her iki RPC'de de zorunlu tutulmuş.
-- RPC çağrısı olmadan doğrudan INSERT yapıldığında RLS devreye girer — çift koruma.
-- =============================================================================

-- RLS policy eklenmesi gerekmiyor; mevcut policy'ler yeterli.
-- Bu bölüm yalnızca belgeleme amaçlıdır.
