-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: 20260708000001_business_suggestions_anon_ratelimit
-- Purpose:   Anon business suggestion INSERT için IP tabanlı rate limiting
-- Risk:      20260703000001 ile açılan anon INSERT'te rate limiting yoktu → spam vektörü
-- Approach:
--   1. submit_business_suggestion_v1 RPC oluşturulur (SECURITY DEFINER)
--      - PostgREST'in x-forwarded-for header'ından client IP çeker
--      - Mevcut check_rate_limit_v1 altyapısını kullanır: 5 istek / 1 saat / IP
--      - Input validation: name >= 3 karakter, category zorunlu
--      - auth.uid() ile user_id doldurur (authenticated ise)
--   2. Açık anon+authenticated INSERT policy'si kaldırılır
--   3. RPC'ye anon + authenticated GRANT verilir
--
-- Frontend güncelleme gereklidir:
--   uygulamalar/web/app/(genel)/isletme-oner/isletme-oner-formu.tsx
--   .from('business_suggestions').insert({...})
--   → .rpc('submit_business_suggestion_v1', {p_name: ..., p_category: ..., ...})
--   (Bu migration ile birlikte yapılmıştır — commit içeriğine bkz.)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Rate-limited submit RPC
CREATE OR REPLACE FUNCTION public.submit_business_suggestion_v1(
  p_name     text,
  p_category text,
  p_city     text DEFAULT NULL,
  p_district text DEFAULT NULL,
  p_address  text DEFAULT NULL,
  p_phone    text DEFAULT NULL,
  p_website  text DEFAULT NULL,
  p_notes    text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_headers   jsonb;
  v_client_ip text;
  v_allowed   boolean;
  v_new_id    uuid;
BEGIN
  -- Input validation
  IF length(trim(coalesce(p_name, ''))) < 3 THEN
    RAISE EXCEPTION 'validation_error: İşletme adı en az 3 karakter olmalıdır' USING ERRCODE = 'P0003';
  END IF;
  IF length(trim(coalesce(p_category, ''))) < 2 THEN
    RAISE EXCEPTION 'validation_error: Kategori seçilmesi zorunludur' USING ERRCODE = 'P0003';
  END IF;

  -- Extract client IP from PostgREST request headers.
  -- PostgREST injects request headers as request.headers session variable (JSON).
  -- x-forwarded-for may contain comma-separated proxy chain; first value is client IP.
  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
    v_client_ip := coalesce(
      nullif(trim(split_part(v_headers->>'x-forwarded-for', ',', 1)), ''),
      nullif(trim(v_headers->>'x-real-ip'), ''),
      'unknown'
    );
  EXCEPTION WHEN OTHERS THEN
    -- If headers aren't available (direct DB call, migration tooling), fall back gracefully
    v_client_ip := 'unknown';
  END;

  -- Rate limit: max 5 suggestions per IP per hour.
  -- Uses existing check_rate_limit_v1 + rate_limit_buckets infrastructure.
  -- SECURITY DEFINER runs as postgres (superuser) — can call check_rate_limit_v1
  -- even though it is only GRANTED to service_role.
  v_allowed := public.check_rate_limit_v1(
    'suggestion:ip:' || v_client_ip,
    5,
    interval '1 hour'
  );

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'rate_limited: Saatte en fazla 5 öneri gönderilebilir. Lütfen daha sonra tekrar deneyin.' USING ERRCODE = 'P0003';
  END IF;

  -- Insert the suggestion
  INSERT INTO public.business_suggestions (
    user_id, name, category, city, district, address, phone, website, notes, status
  ) VALUES (
    auth.uid(),                                              -- NULL for anon, uuid for authenticated
    trim(p_name),
    trim(p_category),
    nullif(trim(coalesce(p_city, '')), ''),
    nullif(trim(coalesce(p_district, '')), ''),
    nullif(trim(coalesce(p_address, '')), ''),
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_website, '')), ''),
    nullif(trim(coalesce(p_notes, '')), ''),
    'pending'
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object('ok', true, 'id', v_new_id);
END;
$$;

-- 2. Permissions — anon and authenticated can call the RPC; no direct table INSERT
REVOKE ALL ON FUNCTION public.submit_business_suggestion_v1(text, text, text, text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_business_suggestion_v1(text, text, text, text, text, text, text, text) TO anon, authenticated;

COMMENT ON FUNCTION public.submit_business_suggestion_v1 IS
  'Rate-limited business suggestion submit (5 req/hr per client IP via x-forwarded-for).
   Replaces direct anon INSERT on business_suggestions (20260703000001).
   Called by: uygulamalar/web/app/(genel)/isletme-oner/isletme-oner-formu.tsx';

-- 3. Remove the open anon+authenticated INSERT policy that had no rate limiting.
--    Anon users must now go through submit_business_suggestion_v1 RPC.
DROP POLICY IF EXISTS "business_suggestions_insert_access" ON public.business_suggestions;
