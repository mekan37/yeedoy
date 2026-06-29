CREATE OR REPLACE FUNCTION public.get_business_chain_info_v1(p_business_id uuid)
RETURNS TABLE(chain_id uuid, chain_name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT c.id, c.name
  FROM public.businesses b
  JOIN public.chains c ON c.id = b.chain_id
  WHERE b.id = p_business_id
    AND b.chain_id IS NOT NULL
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_business_chain_info_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_chain_info_v1(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_business_chain_info_v1(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_business_chain_info_v1 IS
  'Returns chain info for a business if it belongs to one. Called by: business_chain_repository.dart';
