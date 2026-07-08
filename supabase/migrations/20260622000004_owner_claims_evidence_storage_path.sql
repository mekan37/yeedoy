-- owner_claims.evidence_storage_path: durable reference to the uploaded
-- evidence object, independent of the signed URL stored in evidence_url
-- (which expires after 30 days — owner-panel-claim-flow-final-blockers-report.md
-- P1). Admin review screens regenerate a fresh signed URL from this path on
-- demand instead of relying on the stored (possibly expired) evidence_url.
alter table public.owner_claims
  add column if not exists evidence_storage_path text;

drop function if exists public.submit_owner_claim_v1(uuid, text, text, text, text);

create or replace function public.submit_owner_claim_v1(
  p_business_id uuid,
  p_full_name text,
  p_phone text,
  p_evidence_url text default null,
  p_note text default null,
  p_evidence_storage_path text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_claim_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  select exists(
    select 1
    from public.owner_claims
    where user_id = v_uid
      and business_id = p_business_id
      and created_at >= now() - interval '7 days'
  ) into v_recent_exists;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_7d');
  end if;

  insert into public.owner_claims(
    user_id, business_id, full_name, phone, evidence_url, note, status, evidence_storage_path
  ) values (
    v_uid, p_business_id,
    nullif(trim(p_full_name),''),
    nullif(trim(p_phone),''),
    nullif(trim(p_evidence_url),''),
    nullif(trim(p_note),''),
    'pending',
    nullif(trim(p_evidence_storage_path),'')
  )
  returning id into v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'already_submitted');
end;
$$;
