-- P2: Iki admin ayni kaydi ayni anda "incelemeye alabiliyordu" —
-- WHERE ... AND status='new'/'pending' guard'i assigned_to'yu hic kontrol
-- etmiyordu, ikinci admin'in cagrisi ilkinin atamasini sessizce eziyordu.
-- Artik: claim (p_in_review=true) yalnizca bos veya kendi atamasindaysa
-- basarili; release (p_in_review=false) yalnizca kendi atamasindaysa
-- basarili.

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
  WHERE id = p_submission_id
    AND status = 'new'
    AND (
      (p_in_review AND (assigned_to IS NULL OR assigned_to = auth.uid()))
      OR (NOT p_in_review AND assigned_to = auth.uid())
    );

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found_or_not_new');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_appeal_review_v1(p_appeal_id uuid, p_in_review boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin_or_community_mod_v1() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_admin');
  END IF;

  UPDATE public.moderation_appeals
  SET assigned_to = CASE WHEN p_in_review THEN auth.uid() ELSE NULL END,
      assigned_at = CASE WHEN p_in_review THEN now() ELSE NULL END
  WHERE id = p_appeal_id
    AND status = 'pending'
    AND (
      (p_in_review AND (assigned_to IS NULL OR assigned_to = auth.uid()))
      OR (NOT p_in_review AND assigned_to = auth.uid())
    );

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;
