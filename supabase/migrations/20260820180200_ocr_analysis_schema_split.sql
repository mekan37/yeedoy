-- OCR analiz şeması: alerjen/kalori üretimi buradan tamamen kaldırıldı
-- (deterministik kural motoruna dayanan ai-allergen-detect/ai-nutrition-estimate
-- ile çakışıyordu — OCR'ın kör tahminleri hiçbir kontrolden geçmeden
-- menu_item_allergens'a "detected_by=ai" olarak yazılıyordu). OCR'ın tek işi
-- artık isim/açıklama/fiyat/kategori çıkarmak; alerjen/kalori sahibin
-- "AI ile doldur" ile ayrıca tetiklediği, gerçek kural motoruna dayanan
-- bağımsız akıştan geliyor.

ALTER TABLE public.menu_item_ai_analysis
  ADD COLUMN description_text text,
  ADD COLUMN category_name    text,
  ADD COLUMN price_cents      integer,
  ADD COLUMN currency         text NOT NULL DEFAULT 'TRY';

-- apply_menu_ai_analysis_v1: artık allergens_json'a hiç dokunmuyor (kural
-- motoruna dayanmayan, kontrolsüz AI tahminini gerçek işletme verisine
-- yazmıyoruz); gerçek OCR-çıkarımlı fiyat/döviz kullanılıyor (önceden 0/'TRY'
-- sabitti).
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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_analysis
  FROM public.menu_item_ai_analysis
  WHERE id = p_analysis_id
    AND status = 'pending_review'
  FOR UPDATE;

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
    business_id, section_id, name, description, is_available,
    price_cents, currency, sort_order
  )
  VALUES (
    v_analysis.business_id, p_section_id, v_analysis.normalized_text,
    v_analysis.description_text, true,
    coalesce(v_analysis.price_cents, 0), coalesce(v_analysis.currency, 'TRY'), v_sort_order
  )
  RETURNING id INTO v_item_id;

  UPDATE public.menu_item_ai_analysis
  SET status = 'applied', menu_item_id = v_item_id
  WHERE id = p_analysis_id
    AND status = 'pending_review';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: analiz durumu beklenmedik şekilde değişti' USING ERRCODE = 'P0001';
  END IF;

  RETURN v_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) FROM anon;
COMMENT ON FUNCTION public.apply_menu_ai_analysis_v1 IS
  'Owner: bir AI analiz önerisini gerçek menu_items satırına dönüştürür (isim/açıklama/fiyat/kategori — alerjen/kalori artık buradan gelmiyor, sahip ayrıca "AI ile doldur" ile tetikler). Called by: app/sahip/menu/ocr.';

-- list_menu_ai_analysis_v1: yeni alanları da döndürsün.
CREATE OR REPLACE FUNCTION public.list_menu_ai_analysis_v1(
  p_business_id uuid,
  p_ocr_job_id  uuid DEFAULT NULL,
  p_status      text DEFAULT NULL,
  p_limit       int DEFAULT 50,
  p_offset      int DEFAULT 0
)
RETURNS TABLE (
  id               uuid,
  ocr_job_id       uuid,
  source_text      text,
  normalized_text  text,
  description_text text,
  category_name    text,
  price_cents      integer,
  currency         text,
  confidence       numeric,
  requires_review  boolean,
  status           text,
  created_at       timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT a.id, a.ocr_job_id, a.source_text, a.normalized_text,
           a.description_text, a.category_name, a.price_cents, a.currency,
           a.confidence, a.requires_review, a.status, a.created_at
    FROM public.menu_item_ai_analysis a
    WHERE a.business_id = p_business_id
      AND (p_ocr_job_id IS NULL OR a.ocr_job_id = p_ocr_job_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) FROM anon;
COMMENT ON FUNCTION public.list_menu_ai_analysis_v1 IS
  'Owner/admin: bir OCR taramasının AI analiz sonuçlarını listeler (isim/açıklama/fiyat/kategori). Called by: app/sahip/menu/ocr.';
