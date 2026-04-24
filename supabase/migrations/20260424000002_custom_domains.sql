-- Custom Domains: businesses can serve their menus at custom hostnames
-- e.g. menu.bistrobodrum.com → /m/bistrobodrum

CREATE TABLE IF NOT EXISTS public.custom_domains (
  id             uuid        PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  business_id    uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  domain         text        NOT NULL,            -- e.g. "menu.bistrobodrum.com"
  dns_txt_token  text        NOT NULL,            -- e.g. "yd-verify=abc123"
  verified_at    timestamptz,                     -- null = not yet verified
  is_active      bool        NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (domain)
);

ALTER TABLE public.custom_domains OWNER TO postgres;

CREATE INDEX IF NOT EXISTS custom_domains_business_id_idx
  ON public.custom_domains (business_id);

CREATE INDEX IF NOT EXISTS custom_domains_domain_idx
  ON public.custom_domains (domain);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.custom_domains ENABLE ROW LEVEL SECURITY;

-- Public can read verified active domains (for middleware lookup)
CREATE POLICY "custom_domains_public_read"
  ON public.custom_domains FOR SELECT
  USING (verified_at IS NOT NULL AND is_active = true);

-- Owner can read their own domains (including unverified)
CREATE POLICY "custom_domains_owner_read"
  ON public.custom_domains FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.business_claims bc
      WHERE bc.business_id = custom_domains.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );

-- Owner can insert/update/delete their own domains
CREATE POLICY "custom_domains_owner_write"
  ON public.custom_domains FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.business_claims bc
      WHERE bc.business_id = custom_domains.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );

-- ─── RPC: add or replace custom domain for a business ─────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_custom_domain_v1(
  p_business_id uuid,
  p_domain      text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _token text;
  _existing uuid;
BEGIN
  -- Ownership check
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  -- Sanitize domain
  p_domain := lower(trim(p_domain));
  IF p_domain = '' OR p_domain NOT LIKE '%.%' THEN
    RAISE EXCEPTION 'invalid_domain';
  END IF;

  -- Generate verification token
  _token := 'yd-verify=' || encode(extensions.gen_random_bytes(16), 'hex');

  -- Check if another business already owns this domain
  SELECT business_id INTO _existing
  FROM public.custom_domains
  WHERE domain = p_domain;

  IF _existing IS NOT NULL AND _existing <> p_business_id THEN
    RAISE EXCEPTION 'domain_taken';
  END IF;

  INSERT INTO public.custom_domains (business_id, domain, dns_txt_token, verified_at, is_active)
  VALUES (p_business_id, p_domain, _token, NULL, false)
  ON CONFLICT (domain) DO UPDATE SET
    dns_txt_token = _token,
    verified_at   = NULL,
    is_active     = false,
    updated_at    = now();

  RETURN jsonb_build_object('dns_txt_token', _token, 'domain', p_domain);
END;
$$;

-- ─── RPC: get custom domain status for a business ─────────────────────────────
CREATE OR REPLACE FUNCTION public.get_custom_domain_v1(
  p_business_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
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
$$;

-- ─── RPC: delete custom domain ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.delete_custom_domain_v1(
  p_business_id uuid
)
RETURNS void
LANGUAGE plpgsql
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

  DELETE FROM public.custom_domains WHERE business_id = p_business_id;
END;
$$;

-- ─── Helper: resolve slug from custom domain (for middleware) ──────────────────
CREATE OR REPLACE FUNCTION public.get_slug_for_domain_v1(
  p_domain text
)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.slug
  FROM public.custom_domains cd
  JOIN public.businesses b ON b.id = cd.business_id
  WHERE cd.domain = lower(trim(p_domain))
    AND cd.verified_at IS NOT NULL
    AND cd.is_active = true
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_custom_domain_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_custom_domain_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_custom_domain_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_slug_for_domain_v1 TO anon, authenticated;
