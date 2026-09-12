-- P1: Bir talep once onaylanip (owner_claims.status='approved' +
-- business_team_memberships satiri eklenip) sonra ayni claim_id'ye reject
-- cagirildiginda, owner_claims "rejected" oluyordu ama business_team_memberships
-- satiri hala aktif kaliyordu — kullanici owner erisimini korumaya devam
-- ediyordu, panelde "Reddedildi" gorunse bile. Reject dali artik onceden
-- verilmis owner erisimini de idempotent sekilde geri aliyor.

CREATE OR REPLACE FUNCTION public.admin_decide_owner_claim_v1(
  p_claim_id uuid,
  p_decision text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_claim record;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_decision not in ('approved', 'rejected') then
    raise exception 'invalid_decision: %', p_decision using errcode = 'P0003';
  end if;

  select business_id, user_id
  into   v_claim
  from   public.owner_claims
  where  id = p_claim_id;

  if not found then
    raise exception 'not_found: owner_claims.id = %', p_claim_id using errcode = 'P0001';
  end if;

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_note
  where id = p_claim_id;

  if p_decision = 'approved' then
    -- Onaylandıysa: henüz aktif üyeliği yoksa owner satırı ekle (idempotent)
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
  else
    -- Reddedildiyse (daha önce onaylanmış olsa bile): verilmiş owner
    -- erişimini geri al — idempotent, zaten yoksa hiçbir satırı etkilemez.
    update public.business_team_memberships
    set revoked_at = now()
    where business_id = v_claim.business_id
      and user_id     = v_claim.user_id
      and role        = 'owner'
      and revoked_at  is null;
  end if;

  perform public.log_admin_action_v1(
    case
      when p_decision = 'approved' then 'claim.approve'
      else 'claim.reject'
    end,
    'owner_claims',
    p_claim_id,
    jsonb_build_object(
      'decision', p_decision,
      'admin_note', p_note,
      'business_id', v_claim.business_id,
      'user_id', v_claim.user_id
    )
  );
end;
$$;

COMMENT ON FUNCTION public.admin_decide_owner_claim_v1(uuid, text, text) IS
  'Claim onayla/reddet; decision whitelist + not-found guard. Onayda business_team_memberships owner satırı eklenir (idempotent). Reddedilirse (daha önce onaylanmış olsa bile) owner satırı revoke edilir (idempotent). Called by: app/api/admin/claims/actions.ts';
