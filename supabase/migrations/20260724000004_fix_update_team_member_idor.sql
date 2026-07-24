-- KRİTİK: update_team_member_v1'de cross-tenant IDOR — revoke_team_member_v1'de
-- daha önce düzeltilen (20260722000002) aynı hatanın kardeşi, gözden kaçmış.
--
-- Yetki kontrolü çağıranın p_business_id üzerinde team_manage yetkisi olup
-- olmadığına bakıyordu, ama UPDATE'in WHERE koşulu sadece id = p_membership_id
-- idi — hedef üyeliğin GERÇEKTEN o işletmeye/zincire ait olduğu hiç
-- doğrulanmıyordu. Bir işletmeyi yöneten biri, başka bir işletmeye ait
-- membership_id'yi bilirse o üyeliği kendi işletmesine taşıyıp rolünü
-- yükseltebiliyordu.
--
-- Düzeltme: revoke_team_member_v1 ile aynı desen — WHERE koşuluna hedef
-- üyeliğin business_id/chain_id'sinin p_business_id/v_chain_id ile eşleştiğini
-- doğrulayan koşul eklendi, UPDATE'in gerçekten bir satır etkileyip
-- etkilemediği (RETURNING) kontrol edilip 'not_found' dönülüyor.

CREATE OR REPLACE FUNCTION public.update_team_member_v1(
  p_business_id uuid,
  p_membership_id uuid,
  p_role text,
  p_scope text DEFAULT 'this_business'::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
  v_updated_id uuid;
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
    and revoked_at is null
    and (
      business_id = p_business_id
      or (v_chain_id is not null and chain_id = v_chain_id)
    )
  returning id into v_updated_id;

  if v_updated_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

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
$function$;
