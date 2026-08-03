-- get_menu_item_counts_v1 stub'ını gerçek implementasyonla değiştir.
-- (Önceki tanım: supabase/migrations/20260526000002_planned_rpc_stubs.sql)
CREATE OR REPLACE FUNCTION public.get_menu_item_counts_v1(
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active  int;
  v_passive int;
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

  SELECT
    count(*) FILTER (WHERE is_available),
    count(*) FILTER (WHERE NOT is_available)
  INTO v_active, v_passive
  FROM public.menu_items
  WHERE business_id = p_business_id;

  RETURN json_build_object('aktif', v_active, 'pasif', v_passive, 'toplam', v_active + v_passive);
END;
$$;

REVOKE ALL ON FUNCTION public.get_menu_item_counts_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_menu_item_counts_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_menu_item_counts_v1(uuid) FROM anon;

COMMENT ON FUNCTION public.get_menu_item_counts_v1 IS
  'Menü kalem aktif/pasif/toplam sayısı (owner/admin only). 20260803000004 ile stub durumundan çıkarıldı, ownership kontrolü eklendi.';

-- Owner: kendi işletmesinin plan kademesi + her özelliğin limit/kullanım özeti.
CREATE OR REPLACE FUNCTION public.get_my_plan_v1(
  p_business_id uuid
)
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

REVOKE ALL ON FUNCTION public.get_my_plan_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_plan_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_my_plan_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.get_my_plan_v1 IS
  'Owner: işletmenin plan kademesi + özellik limit/kullanım özeti. Called by: app/sahip/ayarlar/plan.';
