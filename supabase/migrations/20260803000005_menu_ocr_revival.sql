-- OCR/AI menü tarama şeması — arşivden diriltildi (_archive/20260411000001_ai_menu_analysis_v1.sql),
-- ownership kontrolleri güncel owner_claims/is_admin() konvansiyonuna taşındı.

CREATE TABLE public.menu_ocr_jobs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_url      text NOT NULL,
  file_name     text,
  status        text NOT NULL DEFAULT 'queued'
                  CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  raw_text      text,
  parsed_output jsonb,
  error_message text,
  item_count    int,
  ocr_engine    text DEFAULT 'none' CHECK (ocr_engine IN ('none', 'deepseek-ocr', 'manual')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX menu_ocr_jobs_business_id_idx ON public.menu_ocr_jobs(business_id, created_at DESC);
CREATE INDEX menu_ocr_jobs_status_idx ON public.menu_ocr_jobs(status, created_at DESC);

ALTER TABLE public.menu_ocr_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "menu_ocr_jobs_owner_all" ON public.menu_ocr_jobs
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = menu_ocr_jobs.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
    OR public.is_admin()
  );

CREATE TABLE public.menu_item_ai_analysis (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ocr_job_id       uuid REFERENCES public.menu_ocr_jobs(id) ON DELETE SET NULL,
  business_id      uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  menu_item_id     uuid REFERENCES public.menu_items(id) ON DELETE SET NULL,
  source_text      text NOT NULL,
  normalized_text  text,
  ingredients_json jsonb DEFAULT '[]'::jsonb,
  allergens_json   jsonb DEFAULT '[]'::jsonb,
  calorie_min      int,
  calorie_max      int,
  confidence       numeric(4,3) NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 1),
  requires_review  boolean NOT NULL DEFAULT true,
  status           text NOT NULL DEFAULT 'pending_review'
                      CHECK (status IN ('pending_review', 'applied', 'rejected')),
  ai_model         text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX menu_item_ai_analysis_business_id_idx ON public.menu_item_ai_analysis(business_id, created_at DESC);
CREATE INDEX menu_item_ai_analysis_ocr_job_id_idx ON public.menu_item_ai_analysis(ocr_job_id);

ALTER TABLE public.menu_item_ai_analysis ENABLE ROW LEVEL SECURITY;

CREATE POLICY "menu_item_ai_analysis_owner_all" ON public.menu_item_ai_analysis
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = menu_item_ai_analysis.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
    OR public.is_admin()
  );

CREATE OR REPLACE FUNCTION public.tg_menu_ocr_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END; $$;

CREATE TRIGGER menu_ocr_jobs_updated_at
  BEFORE UPDATE ON public.menu_ocr_jobs
  FOR EACH ROW EXECUTE FUNCTION public.tg_menu_ocr_touch_updated_at();

CREATE TRIGGER menu_item_ai_analysis_updated_at
  BEFORE UPDATE ON public.menu_item_ai_analysis
  FOR EACH ROW EXECUTE FUNCTION public.tg_menu_ocr_touch_updated_at();

-- ── RPC: create_menu_ocr_job_v1 ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_menu_ocr_job_v1(
  p_business_id uuid,
  p_file_url    text,
  p_file_name   text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_job_id uuid;
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

  PERFORM public._check_plan_limit_v1(p_business_id, 'ocr_scans_per_month');

  INSERT INTO public.menu_ocr_jobs (business_id, owner_id, file_url, file_name)
  VALUES (p_business_id, auth.uid(), p_file_url, p_file_name)
  RETURNING id INTO v_job_id;

  PERFORM public._increment_plan_usage_v1(p_business_id, 'ocr_scans_per_month');

  RETURN v_job_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_menu_ocr_job_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_menu_ocr_job_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.create_menu_ocr_job_v1(uuid, text, text) FROM anon;
COMMENT ON FUNCTION public.create_menu_ocr_job_v1 IS
  'Owner: OCR tarama işi oluşturur (plan limiti kontrollü). Called by: app/sahip/menu/ocr.';

-- ── RPC: list_menu_ocr_jobs_v1 ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.list_menu_ocr_jobs_v1(
  p_business_id uuid,
  p_limit       int DEFAULT 20,
  p_offset      int DEFAULT 0
)
RETURNS TABLE (
  id            uuid,
  file_url      text,
  file_name     text,
  status        text,
  item_count    int,
  error_message text,
  created_at    timestamptz,
  updated_at    timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT j.id, j.file_url, j.file_name, j.status,
           j.item_count, j.error_message, j.created_at, j.updated_at
    FROM public.menu_ocr_jobs j
    WHERE j.business_id = p_business_id
    ORDER BY j.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.list_menu_ocr_jobs_v1(uuid, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_menu_ocr_jobs_v1(uuid, int, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.list_menu_ocr_jobs_v1(uuid, int, int) FROM anon;
COMMENT ON FUNCTION public.list_menu_ocr_jobs_v1 IS
  'Owner/admin: OCR tarama işlerini listeler. Called by: app/sahip/menu/ocr.';

-- ── RPC: list_menu_ai_analysis_v1 ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.list_menu_ai_analysis_v1(
  p_business_id uuid,
  p_ocr_job_id  uuid DEFAULT NULL,
  p_status      text DEFAULT NULL,
  p_limit       int DEFAULT 50,
  p_offset      int DEFAULT 0
)
RETURNS TABLE (
  id               uuid,
  ocr_job_id       uuid,
  source_text      text,
  normalized_text  text,
  ingredients_json jsonb,
  allergens_json   jsonb,
  calorie_min      int,
  calorie_max      int,
  confidence       numeric,
  requires_review  boolean,
  status           text,
  created_at       timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT a.id, a.ocr_job_id, a.source_text, a.normalized_text,
           a.ingredients_json, a.allergens_json,
           a.calorie_min, a.calorie_max,
           a.confidence, a.requires_review, a.status, a.created_at
    FROM public.menu_item_ai_analysis a
    WHERE a.business_id = p_business_id
      AND (p_ocr_job_id IS NULL OR a.ocr_job_id = p_ocr_job_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) FROM anon;
COMMENT ON FUNCTION public.list_menu_ai_analysis_v1 IS
  'Owner/admin: bir OCR taramasının AI analiz sonuçlarını listeler. Called by: app/sahip/menu/ocr.';
