-- business_submissions.assigned_to/assigned_at kolonları vardı ama hiç kullanılmıyordu.
-- "İncelemede" durumunu (admin başvuruyu üstlendi ama henüz karar vermedi) gerçek kılmak
-- için bu kolonları set/unset eden bir RPC ekliyoruz.

CREATE OR REPLACE FUNCTION public.admin_set_submission_review_v1(p_submission_id uuid, p_in_review boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_admin');
  END IF;

  UPDATE public.business_submissions
  SET assigned_to = CASE WHEN p_in_review THEN auth.uid() ELSE NULL END,
      assigned_at = CASE WHEN p_in_review THEN now() ELSE NULL END
  WHERE id = p_submission_id AND status = 'new';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found_or_not_new');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_submission_review_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_submission_review_v1(uuid, boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_set_submission_review_v1 IS 'Admin: işletme başvurusunu incelemeye al/bırak (assigned_to/assigned_at). Called by: app/yonetici/kuyruklar/inceleme-islemleri.ts.';
