-- Plan limiti kontrol/artırım yardımcı RPC'leri.

CREATE OR REPLACE FUNCTION public._get_business_plan_tier_v1(p_business_id uuid)
RETURNS text
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT tier FROM public.business_premium
     WHERE business_id = p_business_id
       AND status = 'active'
       AND tier IN ('starter','standard','pro')
       AND (ends_at IS NULL OR ends_at >= now())
     ORDER BY starts_at DESC
     LIMIT 1),
    'free'
  );
$$;

REVOKE ALL ON FUNCTION public._get_business_plan_tier_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._get_business_plan_tier_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._get_business_plan_tier_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public._get_business_plan_tier_v1(uuid) FROM authenticated;
COMMENT ON FUNCTION public._get_business_plan_tier_v1 IS
  'İşletmenin güncel plan kademesini döner (aktif starter/standard/pro yoksa free).';

-- p_feature_key = 'menu_item_count' -> menu_items tablosunda canlı sayım.
-- Diğer tüm feature_key'ler -> plan_feature_usage üzerinden aylık sayaç.
-- (language_count, upsert_menu_item_translation_v1 içinde ayrıca ve özel
--  mantıkla kontrol edilir — bkz. Task 12 — çünkü "zaten var olan dile
--  güncelleme" ile "yeni dil ekleme" ayrımı burada genelleştirilemez.)
CREATE OR REPLACE FUNCTION public._check_plan_limit_v1(
  p_business_id uuid,
  p_feature_key text
)
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

REVOKE ALL ON FUNCTION public._check_plan_limit_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._check_plan_limit_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._check_plan_limit_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public._check_plan_limit_v1 IS
  'İşletmenin plan kademesine göre bir özelliği kullanmasına izin var mı kontrol eder; aşılmışsa P0003 fırlatır. Called by: menu-islemleri.ts, create_menu_ocr_job_v1, ai-allergen-detect/ai-nutrition-estimate/ai-menu-image-gen çağrı noktaları.';

CREATE OR REPLACE FUNCTION public._increment_plan_usage_v1(
  p_business_id uuid,
  p_feature_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.plan_feature_usage (business_id, feature_key, period_start, usage_count)
  VALUES (p_business_id, p_feature_key, date_trunc('month', now())::date, 1)
  ON CONFLICT (business_id, feature_key, period_start)
  DO UPDATE SET usage_count = public.plan_feature_usage.usage_count + 1;
END;
$$;

REVOKE ALL ON FUNCTION public._increment_plan_usage_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._increment_plan_usage_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._increment_plan_usage_v1(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public._increment_plan_usage_v1(uuid, text) FROM authenticated;
COMMENT ON FUNCTION public._increment_plan_usage_v1 IS
  'Aylık sayaçlı bir plan özelliğinin kullanımını 1 artırır. _check_plan_limit_v1 ile başarılı geçen işlemden SONRA çağrılmalı.';
