-- A5: Push campaign open rate tracking
-- Adds a lightweight RPC to increment opened_count on a push_campaigns row.
-- Called best-effort from mobile on notification tap → web /api/track/push-open.

create or replace function public.increment_push_campaign_open_v1(
  p_campaign_id uuid
)
returns void
language sql
security definer
set search_path = public
as $$
  update push_campaigns
  set opened_count = coalesce(opened_count, 0) + 1
  where id = p_campaign_id;
$$;

-- Callable by authenticated users (mobile on push tap) and service_role (Next.js route).
-- Best-effort analytics — no sensitive data involved.
grant execute on function public.increment_push_campaign_open_v1 to authenticated, service_role;
