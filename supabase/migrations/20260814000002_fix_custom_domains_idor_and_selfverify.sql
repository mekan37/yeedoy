-- Fix two live vulnerabilities in the custom_domains feature (QR-menu custom domain):
--
-- 1. get_custom_domain_v1 had NO ownership check (unlike its siblings
--    upsert_custom_domain_v1 / delete_custom_domain_v1) and was GRANTed
--    directly to `authenticated` — any logged-in user could read any
--    business's dns_txt_token/domain/verification status by passing an
--    arbitrary business_id.
--
-- 2. custom_domains_owner_write RLS policy is FOR ALL with no column
--    restriction, so an approved owner could PATCH verified_at/is_active
--    directly via PostgREST without ever proving DNS ownership — a
--    domain self-verification / hijack bypass. The verify-domain edge
--    function's actual DNS-over-HTTPS check was rendered advisory,
--    since the same RLS policy let a client skip it entirely.
--
-- Fix: add the missing ownership check to get_custom_domain_v1, and
-- revoke all direct table privileges from anon/authenticated so every
-- access path goes through the SECURITY DEFINER RPCs (which already
-- enforce ownership) or the edge function's service-role client
-- (see accompanying verify-domain/index.ts fix).

CREATE OR REPLACE FUNCTION public.get_custom_domain_v1(
  p_business_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_build_object(
        'domain',        domain,
        'dns_txt_token', dns_txt_token,
        'verified_at',   verified_at,
        'is_active',     is_active
      )
      FROM public.custom_domains
      WHERE business_id = p_business_id
      ORDER BY created_at DESC
      LIMIT 1
    ),
    'null'::jsonb
  );
END;
$$;

-- All four RPCs on this table are SECURITY DEFINER and continue to work
-- after this REVOKE (they run with the function owner's privileges,
-- which bypass table grants and RLS). The verify-domain edge function
-- is updated in the same deploy to use SUPABASE_SERVICE_ROLE_KEY for its
-- privileged write instead of the caller's forwarded JWT.
REVOKE ALL ON public.custom_domains FROM anon, authenticated;
