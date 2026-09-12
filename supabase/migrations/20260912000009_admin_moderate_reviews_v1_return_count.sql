-- P1: toplu-islemler route'unda reviews dali admin_moderate_reviews_v1'i
-- cagiriyordu ama fonksiyon RETURNS void oldugundan, gecersiz/var olmayan
-- review ID'leri sessizce atlaniyor ve route bunu asla fark edemiyordu
-- ("150 reddedildi" denip gercekte 110 satir degismis olabiliyordu).
DROP FUNCTION IF EXISTS public.admin_moderate_reviews_v1(uuid[], text);

CREATE FUNCTION public.admin_moderate_reviews_v1(p_ids uuid[], p_status text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_status NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'validation_error: gecersiz status' USING ERRCODE = 'P0003';
  END IF;
  UPDATE public.reviews SET status = p_status WHERE id = ANY(p_ids);
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) FROM anon;
