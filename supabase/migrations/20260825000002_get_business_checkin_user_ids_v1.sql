-- "Doğrulanmış" (verified) review filter needs a signal that a reviewer actually
-- visited the business. business_checkins is the only such signal in the schema
-- (business_reviews/reviews have no verified_visit-style column), but its RLS is
-- admin-only (business_checkins_admin_all), so the public reviews tab cannot read
-- it directly. This RPC exposes only the set of user_ids who checked in — no
-- table_no/menu_id/client_id — safe for public consumption.
CREATE OR REPLACE FUNCTION public.get_business_checkin_user_ids_v1(p_business_id uuid)
RETURNS uuid[]
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT coalesce(array_agg(DISTINCT user_id), ARRAY[]::uuid[])
  FROM public.business_checkins
  WHERE business_id = p_business_id AND user_id IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION public.get_business_checkin_user_ids_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_checkin_user_ids_v1(uuid) TO anon, authenticated;
COMMENT ON FUNCTION public.get_business_checkin_user_ids_v1 IS 'Returns user_ids checked in at a business, for the "Doğrulanmış" review filter. Called by: isletme-detay-tablari.tsx.';
