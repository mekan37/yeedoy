-- _check_plan_limit_v1: menu_item_count'a ek olarak team_seat_count ve branch_count için de
-- "anlık durum sayısı" hesabı ekleniyor (plan_feature_usage aylık sayacı yerine).
CREATE OR REPLACE FUNCTION public._check_plan_limit_v1(p_business_id uuid, p_feature_key text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier    text;
  v_enabled boolean;
  v_limit   int;
  v_used    int;
  v_chain_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT enabled, limit_value INTO v_enabled, v_limit
  FROM public.plan_features
  WHERE plan_tier = v_tier AND feature_key = p_feature_key;

  IF NOT FOUND OR NOT v_enabled THEN
    RAISE EXCEPTION 'plan_limit_exceeded: %', p_feature_key USING ERRCODE = 'P0003';
  END IF;

  IF v_limit IS NULL THEN
    RETURN; -- sınırsız
  END IF;

  IF p_feature_key = 'menu_item_count' THEN
    SELECT count(*) INTO v_used
    FROM public.menu_items mi
    WHERE mi.business_id = p_business_id;
  ELSIF p_feature_key = 'team_seat_count' THEN
    SELECT b.chain_id INTO v_chain_id FROM public.businesses b WHERE b.id = p_business_id;
    SELECT count(*) INTO v_used
    FROM public.business_team_memberships btm
    WHERE btm.revoked_at IS NULL
      AND (btm.business_id = p_business_id OR (v_chain_id IS NOT NULL AND btm.chain_id = v_chain_id));
  ELSIF p_feature_key = 'branch_count' THEN
    SELECT b.chain_id INTO v_chain_id FROM public.businesses b WHERE b.id = p_business_id;
    IF v_chain_id IS NULL THEN
      v_used := 1; -- henüz zincirde değil = kendi başına 1 şube sayılır
    ELSE
      SELECT count(*) INTO v_used FROM public.businesses WHERE chain_id = v_chain_id;
    END IF;
  ELSE
    SELECT COALESCE(usage_count, 0) INTO v_used
    FROM public.plan_feature_usage
    WHERE business_id = p_business_id
      AND feature_key = p_feature_key
      AND period_start = date_trunc('month', now())::date;
    v_used := COALESCE(v_used, 0);
  END IF;

  IF v_used >= v_limit THEN
    RAISE EXCEPTION 'plan_limit_exceeded: %', p_feature_key USING ERRCODE = 'P0003';
  END IF;
END;
$$;

COMMENT ON FUNCTION public._check_plan_limit_v1 IS
  'Plan limiti kontrolü. menu_item_count/team_seat_count/branch_count anlık satır sayımı, diğerleri plan_feature_usage aylık sayacı. Aşılmışsa P0003 plan_limit_exceeded fırlatır.';

-- get_my_plan_v1: owner-facing özet de aynı iki yeni anlık-sayaç özelliğini doğru "used" ile göstermeli.
CREATE OR REPLACE FUNCTION public.get_my_plan_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier     text;
  v_features jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT jsonb_agg(jsonb_build_object(
    'feature_key', pf.feature_key,
    'enabled', pf.enabled,
    'limit_value', pf.limit_value,
    'used', CASE
      WHEN pf.feature_key = 'menu_item_count' THEN (
        SELECT count(*) FROM public.menu_items WHERE business_id = p_business_id
      )
      WHEN pf.feature_key = 'language_count' THEN (
        SELECT 1 + count(DISTINCT mt.locale)
        FROM public.menu_translations mt
        JOIN public.menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
        WHERE mi.business_id = p_business_id
      )
      WHEN pf.feature_key = 'team_seat_count' THEN (
        SELECT count(*) FROM public.business_team_memberships btm
        WHERE btm.revoked_at IS NULL
          AND (
            btm.business_id = p_business_id
            OR (btm.chain_id IS NOT NULL AND btm.chain_id = (SELECT chain_id FROM public.businesses WHERE id = p_business_id))
          )
      )
      WHEN pf.feature_key = 'branch_count' THEN (
        SELECT CASE
          WHEN b.chain_id IS NULL THEN 1
          ELSE (SELECT count(*) FROM public.businesses WHERE chain_id = b.chain_id)
        END
        FROM public.businesses b WHERE b.id = p_business_id
      )
      ELSE COALESCE((
        SELECT usage_count FROM public.plan_feature_usage
        WHERE business_id = p_business_id
          AND feature_key = pf.feature_key
          AND period_start = date_trunc('month', now())::date
      ), 0)
    END
  ) ORDER BY pf.feature_key)
  INTO v_features
  FROM public.plan_features pf
  WHERE pf.plan_tier = v_tier;

  RETURN jsonb_build_object('plan_tier', v_tier, 'features', COALESCE(v_features, '[]'::jsonb));
END;
$$;
