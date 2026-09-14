-- Sahip Paneli Güvenlik Denetimi P2: apply_menu_ai_analysis_v1, analiz
-- kaydının business_id'sini doğruluyordu ama p_section_id'nin GERÇEKTEN o
-- business_id'ye ait olduğunu hiç kontrol etmiyordu. Business A'nın
-- sahibi, kendi bekleyen analizini Business B'ye ait bir section_id ile
-- çağırıp yeni ürünü Business B'nin menü ağacına ekleyebilirdi
-- (business_id sütunu A'yı gösterirken section B'ye ait olur — menü
-- bütünlüğünü bozan bir IDOR).
create or replace function public.apply_menu_ai_analysis_v1(p_analysis_id uuid, p_section_id uuid)
 returns uuid
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_analysis   public.menu_item_ai_analysis%rowtype;
  v_menu_id    uuid;
  v_section_business_id uuid;
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

  SELECT ms.menu_id, m.business_id INTO v_menu_id, v_section_business_id
  FROM public.menu_sections ms
  JOIN public.menus m ON m.id = ms.menu_id
  WHERE ms.id = p_section_id;

  IF v_menu_id IS NULL THEN
    RAISE EXCEPTION 'not_found: bölüm bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_section_business_id IS DISTINCT FROM v_analysis.business_id THEN
    RAISE EXCEPTION 'not_found: bölüm bu işletmeye ait değil' USING ERRCODE = 'P0001';
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
$function$;
