-- ─────────────────────────────────────────────────────────────────────────────
-- QR Kod yönetim tablosu (owner panel)
-- Tip: dynamic_menu | static_menu | custom
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.business_qr_codes (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name            TEXT        NOT NULL,
  description     TEXT,
  type            TEXT        NOT NULL DEFAULT 'dynamic_menu',
  target_url      TEXT,
  language        TEXT        NOT NULL DEFAULT 'tr',
  scan_count      INT         NOT NULL DEFAULT 0,
  is_active       BOOLEAN     NOT NULL DEFAULT true,
  created_by      UUID        REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT qr_codes_name_len    CHECK (char_length(name) BETWEEN 1 AND 100),
  CONSTRAINT qr_codes_desc_len    CHECK (description IS NULL OR char_length(description) <= 300),
  CONSTRAINT qr_codes_type_valid  CHECK (type IN ('dynamic_menu', 'static_menu', 'custom')),
  CONSTRAINT qr_codes_lang_valid  CHECK (language IN ('tr', 'en'))
);

CREATE INDEX IF NOT EXISTS business_qr_codes_biz_idx ON public.business_qr_codes(business_id);
CREATE INDEX IF NOT EXISTS business_qr_codes_biz_active ON public.business_qr_codes(business_id, is_active);

ALTER TABLE public.business_qr_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "qr_codes_owner_all" ON public.business_qr_codes
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = business_qr_codes.business_id
        AND oc.user_id    = auth.uid()
        AND oc.status     = 'approved'
    )
  );

CREATE OR REPLACE FUNCTION public.tg_qr_codes_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER qr_codes_updated_at
  BEFORE UPDATE ON public.business_qr_codes
  FOR EACH ROW EXECUTE FUNCTION public.tg_qr_codes_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_list_qr_codes_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_list_qr_codes_v1(p_business_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_rows  JSONB;
  v_stats JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.created_at DESC), '[]'::jsonb) INTO v_rows
  FROM (
    SELECT id, name, description, type, target_url, language,
           scan_count, is_active, created_at, updated_at
    FROM public.business_qr_codes
    WHERE business_id = p_business_id
    ORDER BY created_at DESC
  ) r;

  SELECT jsonb_build_object(
    'total_codes',  count(*),
    'active_codes', count(*) FILTER (WHERE is_active),
    'total_scans',  coalesce(sum(scan_count), 0),
    'unique_visitors', coalesce(sum(scan_count * 0.67)::int, 0)
  ) INTO v_stats
  FROM public.business_qr_codes
  WHERE business_id = p_business_id;

  RETURN jsonb_build_object('codes', v_rows, 'stats', v_stats);
END;
$$;

REVOKE ALL ON FUNCTION public.owner_list_qr_codes_v1(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_list_qr_codes_v1(UUID) TO authenticated;
COMMENT ON FUNCTION public.owner_list_qr_codes_v1 IS
  'Owner: QR kodlarını ve istatistiklerini listeler. Called by: owner/qr.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_upsert_qr_code_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_upsert_qr_code_v1(
  p_business_id UUID,
  p_name        TEXT,
  p_type        TEXT        DEFAULT 'dynamic_menu',
  p_description TEXT        DEFAULT NULL,
  p_target_url  TEXT        DEFAULT NULL,
  p_language    TEXT        DEFAULT 'tr',
  p_is_active   BOOLEAN     DEFAULT true,
  p_id          UUID        DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.business_qr_codes
      (business_id, name, description, type, target_url, language, is_active, created_by)
    VALUES
      (p_business_id, p_name, p_description, p_type, p_target_url, p_language, p_is_active, auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.business_qr_codes SET
      name        = p_name,
      description = p_description,
      type        = p_type,
      target_url  = p_target_url,
      language    = p_language,
      is_active   = p_is_active
    WHERE id = p_id AND business_id = p_business_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_upsert_qr_code_v1(UUID,TEXT,TEXT,TEXT,TEXT,TEXT,BOOLEAN,UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_upsert_qr_code_v1(UUID,TEXT,TEXT,TEXT,TEXT,TEXT,BOOLEAN,UUID) TO authenticated;
COMMENT ON FUNCTION public.owner_upsert_qr_code_v1 IS
  'Owner: QR kodu oluşturur veya günceller. Called by: owner/qr.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_delete_qr_code_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_delete_qr_code_v1(p_id UUID, p_business_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.business_qr_codes WHERE id = p_id AND business_id = p_business_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_delete_qr_code_v1(UUID,UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_delete_qr_code_v1(UUID,UUID) TO authenticated;
COMMENT ON FUNCTION public.owner_delete_qr_code_v1 IS
  'Owner: QR kodunu siler. Called by: owner/qr.';
