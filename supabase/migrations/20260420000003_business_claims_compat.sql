-- Compatibility alias for newer owner/admin flows that reference business_claims.
-- The canonical table in the base schema is public.owner_claims.
create or replace view public.business_claims
with (security_invoker = true)
as
select
  id,
  business_id,
  user_id,
  status,
  admin_note,
  created_at,
  reviewed_at,
  full_name,
  phone,
  evidence_url,
  note,
  handled_by,
  handled_at,
  assigned_to,
  assigned_at,
  auto_moderated
from public.owner_claims;

grant select, insert, update, delete on public.business_claims to anon;
grant select, insert, update, delete on public.business_claims to authenticated;
grant select, insert, update, delete on public.business_claims to service_role;
