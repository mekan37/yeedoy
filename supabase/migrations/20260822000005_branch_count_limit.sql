CREATE OR REPLACE FUNCTION public.owner_add_business_to_chain_v1(
  p_chain_id uuid, p_business_id uuid, p_branch_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_sort integer;
  v_owner_business_id uuid;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: eklenecek işletme size ait değil' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  SELECT b.id INTO v_owner_business_id
  FROM public.businesses b
  WHERE b.chain_id = p_chain_id AND public._is_approved_owner_of_business(b.id)
  LIMIT 1;

  IF v_owner_business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized: bu zincir üzerinde yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  -- Plan limiti, zincirin mevcut sahibi işletmesinin kademesine göre kontrol edilir
  -- (eklenen işletmenin kendi kademesi değil — zincirin limiti zincir sahibinin planına bağlı).
  PERFORM public._check_plan_limit_v1(v_owner_business_id, 'branch_count');

  SELECT COALESCE(MAX(chain_sort_order), -1) + 1 INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  UPDATE public.businesses
  SET chain_id = p_chain_id,
      branch_label = NULLIF(trim(coalesce(p_branch_label, '')), ''),
      chain_sort_order = v_next_sort
  WHERE id = p_business_id;
END;
$$;
