-- Owner bir OCR/AI analiz önerisini kabul ettiğinde: gerçek bir menu_items
-- satırı oluşturur, önerilen alerjenleri owner_upsert_menu_item_allergens_v1
-- ile detected_by='ai' olarak kaydeder, kalori alanlarını calorie_source='ai_estimated'
-- ile set eder, analiz satırını 'applied' olarak işaretler.

CREATE OR REPLACE FUNCTION public.apply_menu_ai_analysis_v1(
  p_analysis_id uuid,
  p_section_id  uuid
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_analysis   public.menu_item_ai_analysis%rowtype;
  v_menu_id    uuid;
  v_item_id    uuid;
  v_sort_order int;
  v_allergens  jsonb;
  v_allergen_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_analysis
  FROM public.menu_item_ai_analysis
  WHERE id = p_analysis_id
    AND status = 'pending_review';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: analiz bulunamadı veya zaten işlem görmüş' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = v_analysis.business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT menu_id INTO v_menu_id
  FROM public.menu_sections
  WHERE id = p_section_id;

  IF v_menu_id IS NULL THEN
    RAISE EXCEPTION 'not_found: bölüm bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public._check_plan_limit_v1(v_analysis.business_id, 'menu_item_count');

  SELECT count(*) INTO v_sort_order
  FROM public.menu_items
  WHERE section_id = p_section_id;

  INSERT INTO public.menu_items (
    business_id, section_id, name, is_available,
    price_cents, currency, sort_order,
    calories_min, calories_max, calorie_source
  )
  VALUES (
    v_analysis.business_id, p_section_id, v_analysis.normalized_text, true,
    0, 'TRY', v_sort_order,
    v_analysis.calorie_min, v_analysis.calorie_max,
    CASE WHEN v_analysis.calorie_min IS NOT NULL THEN 'ai_estimated' ELSE 'unknown' END
  )
  RETURNING id INTO v_item_id;

  SELECT jsonb_agg(jsonb_build_object(
    'allergen', value,
    'risk_level', 'contains',
    'detected_by', 'ai'
  ))
  INTO v_allergens
  FROM jsonb_array_elements_text(v_analysis.allergens_json);

  IF v_allergens IS NOT NULL THEN
    v_allergen_result := public.owner_upsert_menu_item_allergens_v1(v_item_id, v_allergens);
    IF NOT COALESCE((v_allergen_result->>'ok')::boolean, false) THEN
      RAISE EXCEPTION 'allergen_upsert_failed: %', v_allergen_result->>'error' USING ERRCODE = 'P0003';
    END IF;
  END IF;

  UPDATE public.menu_item_ai_analysis
  SET status = 'applied', menu_item_id = v_item_id
  WHERE id = p_analysis_id;

  RETURN v_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) FROM anon;
COMMENT ON FUNCTION public.apply_menu_ai_analysis_v1 IS
  'Owner: bir AI analiz önerisini gerçek menu_items satırına dönüştürür (alerjenler dahil, detected_by=ai). Called by: app/sahip/menu/ocr.';

-- Reddetme — sadece durum güncellemesi.
CREATE OR REPLACE FUNCTION public.reject_menu_ai_analysis_v1(
  p_analysis_id uuid
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.menu_item_ai_analysis a
  SET status = 'rejected'
  WHERE a.id = p_analysis_id
    AND a.status = 'pending_review'
    AND EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = a.business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: analiz bulunamadı, yetkiniz yok veya zaten işlem görmüş' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.reject_menu_ai_analysis_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_menu_ai_analysis_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.reject_menu_ai_analysis_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.reject_menu_ai_analysis_v1 IS
  'Owner: bir AI analiz önerisini reddeder. Called by: app/sahip/menu/ocr.';
