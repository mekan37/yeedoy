-- ─────────────────────────────────────────────────────────────────────────────
-- ADMIN İŞLETME ZİNCİRLEME
-- Admin panelinde checkbox ile seçilen işletmeleri bir zincire ekler.
-- Owner tarafındaki owner_add_business_to_chain_v1 sadece onaylı sahiplik
-- gerektirdiği için admin panelinde kullanılamıyor — bu RPC is_admin() ile
-- yetkilendirilmiş, herhangi bir işletmeyi herhangi bir zincire ekleyebilir.
-- ─────────────────────────────────────────────────────────────────────────────

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

  -- Çakışma kontrolü: seçilenlerden biri zaten FARKLI bir zincirdeyse tüm işlem reddedilir
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
    WHERE id = v_id AND (chain_id IS NULL OR chain_id = p_chain_id);
  END LOOP;

  RETURN jsonb_build_object('ok', true, 'added_count', array_length(p_business_ids, 1));
END;
$$;

REVOKE ALL ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM anon;
COMMENT ON FUNCTION public.admin_add_businesses_to_chain_v1 IS
  'Admin: seçilen işletmeleri bir zincire ekler (farklı bir zincirdeyse reddeder). Called by: app/yonetici/isletmeler/isletme-zincir-islemleri.ts.';
