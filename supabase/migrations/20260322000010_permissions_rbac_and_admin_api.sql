begin;

create or replace function public.get_app_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_claim jsonb := auth.jwt();
  v_role text;
begin
  v_role := lower(coalesce(
    v_claim -> 'app_metadata' ->> 'role',
    v_claim -> 'user_metadata' ->> 'role',
    'user'
  ));
  if v_role not in ('user', 'owner', 'admin') then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;

create or replace function public.can_access_business_v1(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_business_id is not null
    and (
      public.is_admin()
      or public.is_owner_of_business(p_business_id)
    );
$$;

create or replace function public.assert_owner_scope_v1(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_business_id is null then
    raise exception 'missing_business_id';
  end if;

  if not public.can_access_business_v1(p_business_id) then
    raise exception 'forbidden_scope';
  end if;
end;
$$;

create or replace function public.admin_apply_user_safety_action_v1(
  p_user_id uuid,
  p_action text,
  p_minutes integer default 60,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(trim(coalesce(p_action, '')));
  v_until timestamptz := now() + make_interval(mins => greatest(p_minutes, 1));
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if v_reason is null then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  insert into public.user_safety_actions(user_id, updated_at)
  values (p_user_id, now())
  on conflict (user_id) do nothing;

  if v_action = 'soft_limit' then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'auto_pending' then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'shadow_ban' then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, now()), v_until),
          auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = true
    where user_id = p_user_id;
  elsif v_action = 'clear' then
    update public.user_safety_actions
      set soft_limited_until = null,
          auto_pending_until = null,
          shadow_banned_until = null,
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = false
    where user_id = p_user_id;
  else
    return jsonb_build_object('ok', false, 'error', 'bad_action');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'user.safety_action',
    'user_profiles',
    p_user_id::text,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'action', v_action,
      'minutes', greatest(p_minutes, 1),
      'reason', v_reason
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.get_app_role_v1() to authenticated;
grant all on function public.can_access_business_v1(uuid) to authenticated;
grant all on function public.assert_owner_scope_v1(uuid) to authenticated;
grant all on function public.admin_apply_user_safety_action_v1(uuid, text, integer, text) to authenticated;

commit;
