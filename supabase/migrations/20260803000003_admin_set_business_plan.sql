-- Admin: işletmeye plan kademesi atar. Ödeme entegrasyonu gelene kadar
-- planların TEK atanma yolu bu (admin_set_business_verified_v1 pattern'i
-- izlenerek yazıldı, ama farklı kaygı — is_verified'a dokunmaz).

CREATE OR REPLACE FUNCTION public.admin_set_business_plan_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz DEFAULT NULL
)
RETURNS jsonb
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

  IF p_plan_tier NOT IN ('free','starter','standard','pro') THEN
    RAISE EXCEPTION 'validation_error: geçersiz plan_tier' USING ERRCODE = 'P0003';
  END IF;

  -- Var olan aktif plan kademesini sonlandır (starter/standard/pro karşılıklı dışlar)
  UPDATE public.business_premium
  SET status = 'ended', ends_at = now()
  WHERE business_id = p_business_id
    AND status = 'active'
    AND tier IN ('starter','standard','pro');

  IF p_plan_tier <> 'free' THEN
    INSERT INTO public.business_premium (business_id, tier, status, starts_at, ends_at, source, created_by)
    VALUES (p_business_id, p_plan_tier, 'active', now(), p_ends_at, 'manual', auth.uid())
    RETURNING id INTO v_id;
  END IF;

  PERFORM public.insert_audit_log_v1(
    'business.plan_changed',
    'business',
    p_business_id,
    '{}'::jsonb,
    jsonb_build_object('plan_tier', p_plan_tier, 'premium_id', v_id)
  );

  RETURN jsonb_build_object('ok', true, 'business_id', p_business_id, 'plan_tier', p_plan_tier, 'premium_id', v_id);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_business_plan_v1(uuid, text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_business_plan_v1(uuid, text, timestamptz) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_business_plan_v1(uuid, text, timestamptz) FROM anon;
COMMENT ON FUNCTION public.admin_set_business_plan_v1 IS
  'Admin: işletmeye premium plan kademesi atar (free/starter/standard/pro). Ödeme entegrasyonu gelene kadar manuel atama yolu — Supabase SQL/Studio üzerinden çağrılır, admin panelde UI''ı yok (bu turun kapsamı dışında).';
