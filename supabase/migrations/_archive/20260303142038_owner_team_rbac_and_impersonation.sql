begin;

create table if not exists public.business_team_memberships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid null references public.businesses(id) on delete cascade,
  chain_id uuid null references public.chains(id) on delete cascade,
  user_id uuid null references auth.users(id) on delete set null,
  invite_email text null,
  role text not null check (role in ('owner', 'manager', 'editor', 'staff', 'viewer')),
  created_by uuid null references auth.users(id) on delete set null,
  accepted_at timestamptz null,
  revoked_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (((business_id is not null)::integer + (chain_id is not null)::integer) = 1),
  check (user_id is not null or nullif(trim(coalesce(invite_email, '')), '') is not null)
);

create index if not exists idx_business_team_memberships_business_id
  on public.business_team_memberships(business_id);

create index if not exists idx_business_team_memberships_chain_id
  on public.business_team_memberships(chain_id);

create index if not exists idx_business_team_memberships_user_id
  on public.business_team_memberships(user_id);

create index if not exists idx_business_team_memberships_invite_email
  on public.business_team_memberships(lower(invite_email));

alter table public.business_team_memberships enable row level security;

drop policy if exists business_team_memberships_self_read on public.business_team_memberships;
create policy business_team_memberships_self_read
on public.business_team_memberships
for select
to authenticated
using (
  public.is_admin()
  or user_id = auth.uid()
);

drop policy if exists business_team_memberships_admin_all on public.business_team_memberships;
create policy business_team_memberships_admin_all
on public.business_team_memberships
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create or replace function public.business_role_rank_v1(p_role text)
returns integer
language sql
immutable
set search_path = public
as $$
  select case lower(coalesce(p_role, ''))
    when 'owner' then 500
    when 'manager' then 400
    when 'editor' then 300
    when 'staff' then 200
    when 'viewer' then 100
    else 0
  end;
$$;

create or replace function public.business_role_has_permission_v1(
  p_role text,
  p_permission text
)
returns boolean
language sql
immutable
set search_path = public
as $$
  select case lower(coalesce(p_permission, ''))
    when 'business_read' then public.business_role_rank_v1(p_role) >= 100
    when 'analytics_view' then public.business_role_rank_v1(p_role) >= 100
    when 'media_upload' then public.business_role_rank_v1(p_role) >= 200
    when 'qr_manage' then public.business_role_rank_v1(p_role) >= 300
    when 'menu_write' then public.business_role_rank_v1(p_role) >= 300
    when 'business_write' then public.business_role_rank_v1(p_role) >= 400
    when 'team_manage' then public.business_role_rank_v1(p_role) >= 400
    else false
  end;
$$;

create or replace function public.get_business_role_v1(
  p_business_id uuid,
  p_actor_user_id uuid default null,
  p_role_override text default null
)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
  v_override text := lower(nullif(trim(coalesce(p_role_override, '')), ''));
  v_role text;
begin
  if p_business_id is null then
    return null;
  end if;

  if auth.uid() is null then
    return null;
  end if;

  if p_actor_user_id is not null and not public.is_admin() then
    return null;
  end if;

  v_actor_id := coalesce(p_actor_user_id, auth.uid());

  if public.is_admin() and p_actor_user_id is null and v_override is null then
    return 'owner';
  end if;

  if v_override is not null
     and v_override in ('owner', 'manager', 'editor', 'staff', 'viewer')
     and public.is_admin() then
    return v_override;
  end if;

  with candidate_roles as (
    select 'owner'::text as role
    from public.owner_claims oc
    where oc.business_id = p_business_id
      and oc.user_id = v_actor_id
      and oc.status = 'approved'

    union all

    select cm.role
    from public.businesses b
    join public.chain_memberships cm
      on cm.chain_id = b.chain_id
    where b.id = p_business_id
      and cm.user_id = v_actor_id

    union all

    select btm.role
    from public.businesses b
    join public.business_team_memberships btm
      on (
        (btm.business_id = b.id)
        or (btm.chain_id is not null and btm.chain_id = b.chain_id)
      )
    where b.id = p_business_id
      and btm.revoked_at is null
      and btm.user_id = v_actor_id
  )
  select cr.role
  into v_role
  from candidate_roles cr
  order by public.business_role_rank_v1(cr.role) desc
  limit 1;

  return v_role;
end;
$$;

create or replace function public.has_business_permission_v1(
  p_business_id uuid,
  p_permission text,
  p_actor_user_id uuid default null,
  p_role_override text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when auth.uid() is null then false
    when public.is_admin() and p_actor_user_id is null and p_role_override is null then true
    else public.business_role_has_permission_v1(
      public.get_business_role_v1(p_business_id, p_actor_user_id, p_role_override),
      p_permission
    )
  end;
$$;

create or replace function public.can_view_business_v1(
  p_business_id uuid,
  p_actor_user_id uuid default null,
  p_role_override text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_business_permission_v1(
    p_business_id,
    'business_read',
    p_actor_user_id,
    p_role_override
  );
$$;

create or replace function public.can_manage_branch_v1(
  p_business_id uuid,
  p_actor_user_id uuid default null,
  p_role_override text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_business_permission_v1(
    p_business_id,
    'menu_write',
    p_actor_user_id,
    p_role_override
  );
$$;

create or replace function public.is_owner_of_business(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_business_permission_v1(p_business_id, 'menu_write');
$$;

create or replace function public.can_manage_business_v1(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_business_permission_v1(p_business_id, 'menu_write');
$$;

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
  ) or exists (
    select 1
    from public.chain_memberships cm
    where cm.user_id = v_uid
  ) or exists (
    select 1
    from public.business_team_memberships btm
    where btm.user_id = v_uid
      and btm.revoked_at is null
  ) then
    return 'owner';
  end if;

  return 'user';
end;
$$;

create or replace function public.owner_list_accessible_businesses_v1(
  p_limit integer default 50,
  p_offset integer default 0,
  p_actor_user_id uuid default null,
  p_role_override text default null
)
returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz,
  chain_id uuid,
  chain_name text,
  branch_label text,
  owner_role text
)
language sql
stable
security definer
set search_path = public
as $$
  with accessible as (
    select
      b.id as business_id,
      b.name as business_name,
      coalesce(b.city, '') as city,
      coalesce(b.district, '') as district,
      case
        when exists (
          select 1
          from public.owner_claims oc
          where oc.business_id = b.id
            and oc.user_id = coalesce(p_actor_user_id, auth.uid())
            and oc.status = 'approved'
        ) then 'approved'
        else 'team_access'
      end as claim_status,
      coalesce(
        (
          select min(oc.created_at)
          from public.owner_claims oc
          where oc.business_id = b.id
            and oc.user_id = coalesce(p_actor_user_id, auth.uid())
            and oc.status = 'approved'
        ),
        (
          select min(cm.created_at)
          from public.chain_memberships cm
          where cm.chain_id = b.chain_id
            and cm.user_id = coalesce(p_actor_user_id, auth.uid())
        ),
        (
          select min(btm.created_at)
          from public.business_team_memberships btm
          where btm.revoked_at is null
            and btm.user_id = coalesce(p_actor_user_id, auth.uid())
            and (
              btm.business_id = b.id
              or (btm.chain_id is not null and btm.chain_id = b.chain_id)
            )
        ),
        b.created_at
      ) as claimed_at,
      b.chain_id,
      ch.name as chain_name,
      coalesce(b.branch_label, '') as branch_label,
      public.get_business_role_v1(b.id, p_actor_user_id, p_role_override) as owner_role
    from public.businesses b
    left join public.chains ch on ch.id = b.chain_id
    where public.get_business_role_v1(b.id, p_actor_user_id, p_role_override) is not null
  )
  select *
  from accessible
  order by claimed_at desc, business_name asc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.list_team_members_v1(p_business_id uuid)
returns table(
  membership_id uuid,
  user_id uuid,
  email text,
  role text,
  scope text,
  status text,
  source text,
  created_at timestamptz,
  accepted_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with target_business as (
    select b.id, b.chain_id
    from public.businesses b
    where b.id = p_business_id
  )
  select *
  from (
    select
      null::uuid as membership_id,
      oc.user_id,
      lower(u.email::text) as email,
      'owner'::text as role,
      'this_business'::text as scope,
      'active'::text as status,
      'owner_claim'::text as source,
      oc.created_at,
      oc.reviewed_at as accepted_at
    from public.owner_claims oc
    join target_business tb on tb.id = oc.business_id
    left join auth.users u on u.id = oc.user_id
    where oc.status = 'approved'

    union all

    select
      null::uuid as membership_id,
      cm.user_id,
      lower(u.email::text) as email,
      cm.role,
      'all_branches'::text as scope,
      'active'::text as status,
      'chain_membership'::text as source,
      cm.created_at,
      cm.created_at as accepted_at
    from public.chain_memberships cm
    join target_business tb on tb.chain_id = cm.chain_id
    left join auth.users u on u.id = cm.user_id

    union all

    select
      btm.id as membership_id,
      btm.user_id,
      lower(coalesce(u.email::text, btm.invite_email)) as email,
      btm.role,
      case when btm.chain_id is not null then 'all_branches' else 'this_business' end as scope,
      case when btm.user_id is null then 'pending' else 'active' end as status,
      'team_membership'::text as source,
      btm.created_at,
      btm.accepted_at
    from public.business_team_memberships btm
    join target_business tb
      on (
        btm.business_id = tb.id
        or (btm.chain_id is not null and btm.chain_id = tb.chain_id)
      )
    left join auth.users u on u.id = btm.user_id
    where btm.revoked_at is null
  ) x
  where public.has_business_permission_v1(p_business_id, 'team_manage')
     or public.is_admin()
  order by
    case x.role
      when 'owner' then 1
      when 'manager' then 2
      when 'editor' then 3
      when 'staff' then 4
      else 5
    end,
    x.created_at asc;
$$;

create or replace function public.upsert_team_member_v1(
  p_business_id uuid,
  p_email text,
  p_role text,
  p_scope text default 'this_business'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(nullif(trim(coalesce(p_email, '')), ''));
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
  v_user_id uuid;
  v_membership_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  if v_email is null then
    return jsonb_build_object('ok', false, 'code', 'email_required');
  end if;

  if v_role not in ('owner', 'manager', 'editor', 'staff', 'viewer') then
    return jsonb_build_object('ok', false, 'code', 'invalid_role');
  end if;

  if v_scope not in ('this_business', 'all_branches') then
    return jsonb_build_object('ok', false, 'code', 'invalid_scope');
  end if;

  select b.chain_id
  into v_chain_id
  from public.businesses b
  where b.id = p_business_id;

  if v_scope = 'all_branches' and v_chain_id is null then
    return jsonb_build_object('ok', false, 'code', 'chain_required');
  end if;

  select u.id
  into v_user_id
  from auth.users u
  where lower(u.email::text) = v_email
  limit 1;

  select btm.id
  into v_membership_id
  from public.business_team_memberships btm
  where btm.revoked_at is null
    and (
      (
        v_scope = 'this_business'
        and btm.business_id = p_business_id
      ) or (
        v_scope = 'all_branches'
        and btm.chain_id = v_chain_id
      )
    )
    and (
      (v_user_id is not null and btm.user_id = v_user_id)
      or lower(coalesce(btm.invite_email, '')) = v_email
    )
  order by btm.created_at desc
  limit 1;

  if v_membership_id is null then
    insert into public.business_team_memberships(
      business_id,
      chain_id,
      user_id,
      invite_email,
      role,
      created_by,
      accepted_at
    )
    values (
      case when v_scope = 'this_business' then p_business_id else null end,
      case when v_scope = 'all_branches' then v_chain_id else null end,
      v_user_id,
      v_email,
      v_role,
      auth.uid(),
      case when v_user_id is not null then now() else null end
    )
    returning id into v_membership_id;
  else
    update public.business_team_memberships
    set
      business_id = case when v_scope = 'this_business' then p_business_id else null end,
      chain_id = case when v_scope = 'all_branches' then v_chain_id else null end,
      user_id = coalesce(v_user_id, user_id),
      invite_email = v_email,
      role = v_role,
      accepted_at = case
        when v_user_id is not null then coalesce(accepted_at, now())
        else accepted_at
      end,
      revoked_at = null,
      updated_at = now()
    where id = v_membership_id;
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.team.upsert',
    'business_team_memberships',
    v_membership_id,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'business_id', p_business_id,
      'email', v_email,
      'role', v_role,
      'scope', v_scope
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', v_membership_id, 'linked_user_id', v_user_id);
end;
$$;

create or replace function public.update_team_member_v1(
  p_business_id uuid,
  p_membership_id uuid,
  p_role text,
  p_scope text default 'this_business'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  if v_role not in ('owner', 'manager', 'editor', 'staff', 'viewer') then
    return jsonb_build_object('ok', false, 'code', 'invalid_role');
  end if;

  if v_scope not in ('this_business', 'all_branches') then
    return jsonb_build_object('ok', false, 'code', 'invalid_scope');
  end if;

  select b.chain_id
  into v_chain_id
  from public.businesses b
  where b.id = p_business_id;

  update public.business_team_memberships
  set
    business_id = case when v_scope = 'this_business' then p_business_id else null end,
    chain_id = case when v_scope = 'all_branches' then v_chain_id else null end,
    role = v_role,
    updated_at = now()
  where id = p_membership_id
    and revoked_at is null;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.team.update',
    'business_team_memberships',
    p_membership_id,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'business_id', p_business_id,
      'role', v_role,
      'scope', v_scope
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.revoke_team_member_v1(
  p_business_id uuid,
  p_membership_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  update public.business_team_memberships
  set
    revoked_at = now(),
    updated_at = now()
  where id = p_membership_id
    and revoked_at is null;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.team.revoke',
    'business_team_memberships',
    p_membership_id,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'business_id', p_business_id
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.admin_list_user_business_access_v1(
  p_user_id uuid,
  p_role_override text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz,
  chain_id uuid,
  chain_name text,
  branch_label text,
  owner_role text
)
language sql
stable
security definer
set search_path = public
as $$
  select *
  from public.owner_list_accessible_businesses_v1(
    p_limit => p_limit,
    p_offset => p_offset,
    p_actor_user_id => p_user_id,
    p_role_override => p_role_override
  )
  where public.is_admin();
$$;

create or replace function public.admin_log_impersonation_v1(
  p_target_user_id uuid,
  p_action text,
  p_role_override text default null,
  p_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(nullif(trim(coalesce(p_action, '')), ''));
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  if p_target_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'missing_target_user');
  end if;

  if v_action not in ('start', 'stop') then
    return jsonb_build_object('ok', false, 'code', 'invalid_action');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    case when v_action = 'start' then 'admin.impersonation.start' else 'admin.impersonation.stop' end,
    'auth.users',
    p_target_user_id,
    coalesce(p_meta, '{}'::jsonb) || jsonb_build_object(
      'actor_id', auth.uid(),
      'target_user_id', p_target_user_id,
      'role_override', lower(nullif(trim(coalesce(p_role_override, '')), ''))
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.business_role_rank_v1(text) to authenticated;
grant execute on function public.business_role_has_permission_v1(text, text) to authenticated;
grant execute on function public.get_business_role_v1(uuid, uuid, text) to authenticated;
grant execute on function public.has_business_permission_v1(uuid, text, uuid, text) to authenticated;
grant execute on function public.can_view_business_v1(uuid, uuid, text) to authenticated;
grant execute on function public.can_manage_branch_v1(uuid, uuid, text) to authenticated;
grant execute on function public.can_manage_business_v1(uuid) to authenticated;
grant execute on function public.current_user_role_v1() to authenticated;
grant execute on function public.owner_list_accessible_businesses_v1(integer, integer, uuid, text) to authenticated;
grant execute on function public.list_team_members_v1(uuid) to authenticated;
grant execute on function public.upsert_team_member_v1(uuid, text, text, text) to authenticated;
grant execute on function public.update_team_member_v1(uuid, uuid, text, text) to authenticated;
grant execute on function public.revoke_team_member_v1(uuid, uuid) to authenticated;
grant execute on function public.admin_list_user_business_access_v1(uuid, text, integer, integer) to authenticated;
grant execute on function public.admin_log_impersonation_v1(uuid, text, text, jsonb) to authenticated;

commit;;
