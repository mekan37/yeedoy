-- Fix estimate_email_segment_v1: replace broken follower_id with user_id,
-- remove unreliable profiles.email join, add search_path and ownership guard.
--
-- Root cause: original definition joined profiles on bf.follower_id which does not
-- exist in business_follows; the correct column is user_id (see base_schema.sql
-- CREATE TABLE public.business_follows). The profiles.email join was also removed
-- because that column is not reliably populated — actual delivery uses
-- auth.admin.listUsers (service role) to resolve addresses, so a small overcount
-- in the estimate is acceptable.
--
-- Security: SET search_path = public prevents search_path injection.
-- Authorization: callers who are neither admin nor owner of the business receive 0
-- (consistent with "not authorized to see this number") without raising an exception,
-- matching the pattern used by other owner-facing estimate/stats RPCs.

CREATE OR REPLACE FUNCTION public.estimate_email_segment_v1(
  p_business_id uuid,
  p_segment     text DEFAULT 'all_followers'
)
RETURNS int
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT count(*)::int
  FROM public.business_follows bf
  WHERE bf.business_id = p_business_id
    AND bf.is_subscribed_email = true
    AND (public.is_admin() OR public.is_owner_of_business(p_business_id))
    AND (
      p_segment = 'all_followers'
      OR (p_segment = 'new_30d'      AND bf.created_at >= now() - interval '30 days')
      OR (p_segment = 'inactive_30d' AND bf.created_at <  now() - interval '30 days')
    );
$$;

COMMENT ON FUNCTION public.estimate_email_segment_v1(uuid, text) IS
  'Returns subscribed-email follower count for a given segment. '
  'Requires caller to be admin or owner of the business (returns 0 otherwise). '
  'Called by: app/owner/[businessId]/campaigns/page.tsx';
