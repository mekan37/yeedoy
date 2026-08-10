-- Sadakat v1 Faz 2 — owner'ın kendi programının (taslak dahil) durumunu okuması.
-- bkz. docs/superpowers/plans/2026-08-10-sadakat-faz2-owner-web-ui.md

CREATE OR REPLACE FUNCTION public.get_business_loyalty_program_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_result jsonb;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'id', id,
    'mode', mode,
    'name', name,
    'reward_desc', reward_desc,
    'reward_threshold', reward_threshold,
    'is_active', is_active
  ) INTO v_result
  FROM public.loyalty_programs
  WHERE id = v_program_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_loyalty_program_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_loyalty_program_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_business_loyalty_program_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.get_business_loyalty_program_v1 IS
  'Owner/personel: kendi işletmesinin (taslak dahil) sadakat programını okur. Called by: app/sahip/pazarlama/sadakat.';
