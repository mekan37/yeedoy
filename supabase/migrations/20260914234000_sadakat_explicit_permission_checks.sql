-- Sahip Paneli Güvenlik Denetimi P3: sadakat RPC'lerinde yetkilendirme,
-- alakasız bir plan limiti yardımcısının (_check_plan_limit_v1) yan etkisine
-- bağlıydı — kırılgan bir desen (o yardımcının auth kontrolünü kaldırması/
-- taşıması sessizce yetki kontrolünü de kaldırırdı). create_loyalty_program_v1
-- HİÇ açık izin kontrolü yapmıyordu; tek koruması _check_plan_limit_v1
-- içindeki owner_claims-only kontroldü (rank 500 — tasarım niyeti olan
-- 'menu_write' rank>=300'den daha kısıtlıydı, bkz. 20260811000002'nin kendi
-- yorumu: "Program oluşturma/aktivasyon ... 'menu_write' (editor+)").
-- set_loyalty_program_active_v1'in tek-işletme dalı da aynı örtük deseni
-- kullanıyordu; zincir dalı zaten açık is_owner_of_business (=menu_write)
-- kontrolü yapıyordu — tutarsızlık buradan geliyordu.
CREATE OR REPLACE FUNCTION public.create_loyalty_program_v1(
  p_business_id      uuid,
  p_mode             text,
  p_name             text,
  p_reward_desc      text,
  p_reward_threshold int
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id   uuid;
  v_owner_biz  uuid;
  v_program_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NOT NULL THEN
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
  ELSE
    v_owner_biz := p_business_id;
  END IF;

  IF NOT public.has_business_permission_v1(v_owner_biz, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');

  IF p_mode NOT IN ('stamp','points') THEN
    RAISE EXCEPTION 'validation_error: geçersiz mode' USING ERRCODE = 'P0003';
  END IF;
  IF p_reward_threshold <= 0 THEN
    RAISE EXCEPTION 'validation_error: reward_threshold pozitif olmalı' USING ERRCODE = 'P0003';
  END IF;

  IF v_chain_id IS NOT NULL THEN
    INSERT INTO public.loyalty_programs (chain_id, mode, name, reward_desc, reward_threshold)
    VALUES (v_chain_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  ELSE
    INSERT INTO public.loyalty_programs (business_id, mode, name, reward_desc, reward_threshold)
    VALUES (p_business_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  END IF;

  RETURN v_program_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_loyalty_program_active_v1(
  p_program_id uuid,
  p_is_active  boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_owner_biz   uuid;
BEGIN
  SELECT business_id, chain_id INTO v_business_id, v_chain_id
  FROM public.loyalty_programs WHERE id = p_program_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: program bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    v_owner_biz := v_business_id;
    IF NOT public.has_business_permission_v1(v_owner_biz, 'menu_write') THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.is_owner_of_business(b.id)
    ) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  END IF;

  UPDATE public.loyalty_programs SET is_active = p_is_active WHERE id = p_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) FROM anon;

REVOKE ALL ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) FROM anon;

COMMENT ON FUNCTION public.create_loyalty_program_v1 IS
  'Owner/ekip (menu_write, editor+): sadakat programı oluşturur (is_active=false başlar). Açık izin kontrolü + premium plan kontrolü (_check_plan_limit_v1). Called by: app/sahip/pazarlama/sadakat.';
COMMENT ON FUNCTION public.set_loyalty_program_active_v1 IS
  'Owner/ekip (menu_write, editor+): programı aktif/pasif yapar. Açık izin kontrolü + premium plan kontrolü (_check_plan_limit_v1). Called by: app/sahip/pazarlama/sadakat.';
