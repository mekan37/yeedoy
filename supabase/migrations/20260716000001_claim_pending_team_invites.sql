-- Bekleyen (user_id IS NULL) ekip davetlerini, davet edilen e-posta ile giriş
-- yapan kullanıcının hesabına bağlar. upsert_team_member_v1 ile oluşturulan
-- davetler, davet edilen kişi henüz kayıtlı değilse invite_email ile bekler;
-- bu RPC olmadan kişi kayıt olup giriş yaptığında üyelik "pending" kalırdı.
-- Called by: app/sunucu/kimlik/giris/route.ts (başarılı girişten hemen sonra).
CREATE OR REPLACE FUNCTION public.claim_pending_team_invites_v1()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
  v_count int;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT lower(u.email::text) INTO v_email FROM auth.users u WHERE u.id = auth.uid();
  IF v_email IS NULL THEN
    RETURN jsonb_build_object('ok', true, 'linked', 0);
  END IF;

  UPDATE public.business_team_memberships
  SET user_id = auth.uid(),
      accepted_at = now(),
      updated_at = now()
  WHERE user_id IS NULL
    AND lower(invite_email) = v_email
    AND revoked_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  RETURN jsonb_build_object('ok', true, 'linked', v_count);
END;
$$;

REVOKE ALL ON FUNCTION public.claim_pending_team_invites_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_pending_team_invites_v1() TO authenticated;
COMMENT ON FUNCTION public.claim_pending_team_invites_v1 IS 'Giriş yapan kullanıcının e-postasıyla eşleşen bekleyen ekip davetlerini kendi hesabına bağlar. Called by: app/sunucu/kimlik/giris/route.ts.';
