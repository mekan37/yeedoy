-- Role and permission hardening:
-- - canonical app role RPC
-- - business manage permission RPC
-- - explicit businesses write policies

create or replace function public.current_user_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return 'user';
  end if;

  if public.is_admin() then
    return 'admin';
  end if;

  if exists (
    select 1
    from public.owner_claims oc
    where oc.user_id = v_uid
      and oc.status = 'approved'
  ) then
    return 'owner';
  end if;

  return 'user';
end;
$$;
revoke all on function public.current_user_role_v1() from public;
grant execute on function public.current_user_role_v1() to authenticated;
create or replace function public.can_manage_business_v1(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    case
      when auth.uid() is null then false
      else (public.is_admin() or public.is_owner_of_business(p_business_id))
    end;
$$;
revoke all on function public.can_manage_business_v1(uuid) from public;
grant execute on function public.can_manage_business_v1(uuid) to authenticated;
alter table if exists public.businesses enable row level security;
drop policy if exists businesses_insert_admin on public.businesses;
create policy businesses_insert_admin
on public.businesses
for insert
to authenticated
with check (public.is_admin());
drop policy if exists businesses_update_owner_admin on public.businesses;
create policy businesses_update_owner_admin
on public.businesses
for update
to authenticated
using (public.is_admin() or public.is_owner_of_business(id))
with check (public.is_admin() or public.is_owner_of_business(id));
drop policy if exists businesses_delete_admin on public.businesses;
create policy businesses_delete_admin
on public.businesses
for delete
to authenticated
using (public.is_admin());
