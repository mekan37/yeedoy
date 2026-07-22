-- Giriş yapan kullanıcının e-postasına eşleşen, henüz kimseye bağlanmamış
-- (user_id IS NULL) bekleyen ekip davetlerini bu hesaba bağlar.
-- Çağıran: uygulamalar/web/app/sunucu/kimlik/giris/route.ts (login sonrası, best-effort).
CREATE OR REPLACE FUNCTION public.claim_pending_team_invites_v1()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_email text;
  v_linked_count int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  SELECT lower(email::text) INTO v_email FROM auth.users WHERE id = v_user_id;
  IF v_email IS NULL THEN
    RETURN jsonb_build_object('ok', true, 'linked_count', 0);
  END IF;

  WITH linked AS (
    UPDATE public.business_team_memberships
    SET user_id = v_user_id,
        accepted_at = now(),
        updated_at = now()
    WHERE user_id IS NULL
      AND revoked_at IS NULL
      AND lower(coalesce(invite_email, '')) = v_email
    RETURNING id
  )
  SELECT count(*) INTO v_linked_count FROM linked;

  RETURN jsonb_build_object('ok', true, 'linked_count', v_linked_count);
END;
$$;

REVOKE ALL ON FUNCTION public.claim_pending_team_invites_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_pending_team_invites_v1() TO authenticated;
COMMENT ON FUNCTION public.claim_pending_team_invites_v1 IS 'Giriş yapan kullanıcıya ait bekleyen ekip davetlerini hesaba bağlar. Called by: app/sunucu/kimlik/giris/route.ts.';
