-- Task 1 code-quality review buldu: added_count gerçek satır sayısını yansıtmıyordu
-- ve zincirde zaten olan işletmeler yeniden seçilince chain_sort_order'ları
-- gereksiz yere sona kayıyordu. Bu düzeltme sadece chain_id IS NULL olan
-- işletmeleri işler (aynı zincirde olan seçim no-op'tur) ve GET DIAGNOSTICS
-- ile gerçek etkilenen satır sayısını döner.

CREATE OR REPLACE FUNCTION public.admin_add_businesses_to_chain_v1(
  p_chain_id      uuid,
  p_business_ids  uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conflict_text  text;
  v_next_sort      integer;
  v_id             uuid;
  v_row_count      integer;
  v_added_count    integer := 0;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_ids IS NULL OR array_length(p_business_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'validation_error: en az bir işletme seçilmeli' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
    RAISE EXCEPTION 'not_found: zincir bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  SELECT string_agg(format('%s (%s)', b.name, c.name), ', ')
    INTO v_conflict_text
  FROM public.businesses b
  JOIN public.chains c ON c.id = b.chain_id
  WHERE b.id = ANY(p_business_ids)
    AND b.chain_id IS NOT NULL
    AND b.chain_id != p_chain_id;

  IF v_conflict_text IS NOT NULL THEN
    RAISE EXCEPTION 'validation_error: şu işletmeler zaten başka bir zincirde: %', v_conflict_text
      USING ERRCODE = 'P0003';
  END IF;

  SELECT COALESCE(MAX(chain_sort_order), -1) INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  FOREACH v_id IN ARRAY p_business_ids LOOP
    v_next_sort := v_next_sort + 1;
    UPDATE public.businesses
    SET chain_id = p_chain_id, chain_sort_order = v_next_sort
    WHERE id = v_id AND chain_id IS NULL;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    IF v_row_count = 0 THEN
      v_next_sort := v_next_sort - 1;
    ELSE
      v_added_count := v_added_count + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('ok', true, 'added_count', v_added_count);
END;
$$;

COMMENT ON FUNCTION public.admin_add_businesses_to_chain_v1 IS
  'Admin: seçilen işletmeleri bir zincire ekler (farklı bir zincirdeyse reddeder, aynı zincirdeyse no-op). Called by: app/yonetici/isletmeler/isletme-zincir-islemleri.ts.';
