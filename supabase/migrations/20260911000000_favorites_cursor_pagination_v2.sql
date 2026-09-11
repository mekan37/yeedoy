-- B52: get_my_favorites_v1's offset pagination drifts when the favorites
-- list is mutated (add/remove) while a user is scrolling, causing skipped
-- or duplicated cards. Replace with keyset (cursor) pagination, ordered by
-- (created_at, business_id) as a stable, collision-free tie-breaker.
CREATE OR REPLACE FUNCTION public.get_my_favorites_v2(
  p_limit integer DEFAULT 50,
  p_after_favorited_at timestamptz DEFAULT NULL,
  p_after_business_id uuid DEFAULT NULL
)
RETURNS TABLE(business_id uuid, favorited_at timestamp with time zone)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  select
    f.business_id,
    f.created_at as favorited_at
  from public.favorites f
  where f.user_id = auth.uid()
    and (
      p_after_favorited_at is null
      or (f.created_at, f.business_id) < (p_after_favorited_at, p_after_business_id)
    )
  order by f.created_at desc, f.business_id desc
  limit greatest(p_limit, 0);
$function$;

-- New functions get an implicit EXECUTE grant to PUBLIC (plain Postgres
-- default) unless explicitly revoked — REVOKE FROM anon alone does not
-- remove access inherited via PUBLIC membership. See rpc-and-route-handler-
-- standards skill's RPC template.
revoke all on function public.get_my_favorites_v2(integer, timestamptz, uuid) from public;
grant execute on function public.get_my_favorites_v2(integer, timestamptz, uuid) to authenticated;
