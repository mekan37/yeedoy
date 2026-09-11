-- Menu Source Discovery işleri mevcut staging/review hattını kullanır.
-- Ham extractor sonucu job.result içinde tutulur; gerçek menu_items'e yazma
-- yalnızca admin_apply_menu_extract_job_v1 ile açık admin onayından sonra olur.

ALTER TABLE public.admin_menu_extract_jobs
  DROP CONSTRAINT IF EXISTS admin_menu_extract_jobs_source_type_check;

ALTER TABLE public.admin_menu_extract_jobs
  ADD CONSTRAINT admin_menu_extract_jobs_source_type_check
  CHECK (source_type IN ('url', 'upload', 'website_discovery'));

CREATE OR REPLACE FUNCTION public.admin_create_menu_extract_job_v1(
  p_business_id uuid,
  p_source_type text,
  p_external_job_id text,
  p_source_url text DEFAULT NULL,
  p_source_file_name text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_source_type NOT IN ('url', 'upload', 'website_discovery') THEN
    RAISE EXCEPTION 'validation_error: gecersiz source_type' USING ERRCODE = 'P0003';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id) THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.admin_menu_extract_jobs (
    business_id, created_by, source_type, source_url, source_file_name,
    external_job_id, status
  )
  VALUES (
    p_business_id, auth.uid(), p_source_type, p_source_url,
    p_source_file_name, p_external_job_id, 'queued'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) FROM anon;

-- Return type yeni result alanını içerdiği için fonksiyon yeniden oluşturulur.
DROP FUNCTION IF EXISTS public.admin_get_menu_extract_job_v1(uuid);

CREATE FUNCTION public.admin_get_menu_extract_job_v1(p_job_id uuid)
RETURNS TABLE (
  id uuid,
  business_id uuid,
  source_type text,
  source_url text,
  source_file_name text,
  external_job_id text,
  status text,
  error_message text,
  result jsonb,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT
      j.id, j.business_id, j.source_type, j.source_url,
      j.source_file_name, j.external_job_id, j.status, j.error_message,
      j.result, j.created_at
    FROM public.admin_menu_extract_jobs j
    WHERE j.id = p_job_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) FROM anon;

COMMENT ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) IS
  'Admin: menü analiz işinin durumunu ve review özetinde kullanılacak ham sonucu döner.';
