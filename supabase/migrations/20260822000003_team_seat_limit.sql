-- upsert_team_member_v1 yalnizca YENI uyelik (INSERT dali) icin limit kontrolu yapmali —
-- mevcut bir uyeligi guncellemek (rol degisikligi, yeniden davet) koltuk tuketmiyor.
-- Fonksiyon jsonb {ok,code} dondurdugu icin _check_plan_limit_v1'in P0003 firlatmasi
-- yakalanip ayni sozlesmeye cevriliyor.
CREATE OR REPLACE FUNCTION public.upsert_team_member_v1(
  p_business_id uuid, p_email text, p_role text, p_scope text DEFAULT 'this_business'::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text := lower(nullif(trim(coalesce(p_email, '')), ''));
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
  v_user_id uuid;
  v_membership_id uuid;
  v_is_new boolean := false;
BEGIN
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

  v_is_new := v_membership_id is null;

  IF v_is_new THEN
    BEGIN
      PERFORM public._check_plan_limit_v1(p_business_id, 'team_seat_count');
    EXCEPTION WHEN SQLSTATE 'P0003' THEN
      RETURN jsonb_build_object('ok', false, 'code', 'plan_limit_exceeded', 'feature_key', 'team_seat_count');
    END;
  END IF;

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
END;
$$;
