-- moderation_appeals sadece pending/approved/rejected kabul ediyordu (CHECK kısıtı) —
-- "İnceleniyor" durumunu business_submissions'daki gibi assigned_to/assigned_at ile
-- gerçek kılıyoruz (durum değeri değişmiyor, sadece kimin incelediği izleniyor).

ALTER TABLE public.moderation_appeals
  ADD COLUMN IF NOT EXISTS assigned_to uuid,
  ADD COLUMN IF NOT EXISTS assigned_at timestamptz;

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
  WHERE id = p_appeal_id AND status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_appeal_review_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_appeal_review_v1(uuid, boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_set_appeal_review_v1 IS 'Admin/moderatör: itirazı incelemeye al/bırak (assigned_to/assigned_at). Called by: app/yonetici/itirazlar/page.tsx.';
