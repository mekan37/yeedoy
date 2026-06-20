-- admin_decide_owner_claim_v1: onay sonrası business_team_memberships'e owner satırı ekle.
-- Önceki versiyon yalnızca owner_claims.status'ü güncelliyordu;
-- is_owner_of_business() business_team_memberships üzerinden çalıştığı için
-- kullanıcı onaylanmasına rağmen panel erişimi kazanamıyordu.

CREATE OR REPLACE FUNCTION public.admin_decide_owner_claim_v1(
  p_claim_id uuid,
  p_decision text,
  p_note     text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_claim record;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select business_id, user_id
  into   v_claim
  from   public.owner_claims
  where  id = p_claim_id;

  if not found then
    raise exception 'not_found: Talep bulunamadı' using errcode = 'P0001';
  end if;

  update public.owner_claims
  set
    status     = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_note
  where id = p_claim_id;

  -- Onaylandıysa: henüz aktif üyeliği yoksa owner satırı ekle
  if p_decision = 'approved' then
    insert into public.business_team_memberships (
      business_id,
      user_id,
      role,
      created_by,
      accepted_at
    )
    select
      v_claim.business_id,
      v_claim.user_id,
      'owner',
      auth.uid(),
      now()
    where not exists (
      select 1
      from   public.business_team_memberships
      where  business_id = v_claim.business_id
        and  user_id     = v_claim.user_id
        and  revoked_at  is null
    );
  end if;

  perform public.log_admin_action_v1(
    case when p_decision = 'approved' then 'claim.approve' else 'claim.reject' end,
    'owner_claims',
    p_claim_id,
    jsonb_build_object(
      'decision',    p_decision,
      'admin_note',  p_note,
      'business_id', v_claim.business_id,
      'user_id',     v_claim.user_id
    )
  );
end;
$$;

COMMENT ON FUNCTION public.admin_decide_owner_claim_v1(uuid, text, text) IS
  'Claim onayla/reddet. Onayda business_team_memberships owner satırı eklenir. Called by: app/api/admin/claims/actions.ts';
