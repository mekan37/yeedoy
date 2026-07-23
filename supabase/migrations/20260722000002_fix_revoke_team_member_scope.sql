-- revoke_team_member_v1'in mevcut hali sadece p_membership_id ile eşleşen
-- satırı iptal ediyordu, bu satırın gerçekten p_business_id'ye (veya onun
-- zincirine) ait olduğunu hiç doğrulamıyordu. has_business_permission_v1
-- kontrolü sadece çağıranın p_business_id üzerinde team_manage yetkisi
-- olduğunu doğruluyor — p_membership_id'nin başka bir işletmeye ait olup
-- olmadığını değil. Sonuç: herhangi bir işletme sahibi/yöneticisi, bir
-- membership_id UUID'sini bilerek (veya tahmin ederek) SİSTEMDEKİ HERHANGİ
-- BİR işletmenin ekip üyeliğini iptal edebiliyordu (cross-tenant IDOR).
-- Bu fonksiyon önceden hiçbir yerden çağrılmıyordu (dead code); artık
-- app/sahip/ekip/ekip-islemleri.ts:removeTeamMember tarafından çağrılıyor,
-- bu yüzden düzeltme kritik hale geldi.
--
-- upsert_team_member_v1'deki (bkz. 00000000000000_base_schema.sql) aynı
-- business_id/chain_id kapsamlama mantığı burada da uygulanıyor.
CREATE OR REPLACE FUNCTION "public"."revoke_team_member_v1"("p_business_id" "uuid", "p_membership_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_chain_id uuid;
  v_updated_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  select b.chain_id into v_chain_id from public.businesses b where b.id = p_business_id;

  update public.business_team_memberships
  set
    revoked_at = now(),
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

COMMENT ON FUNCTION public.revoke_team_member_v1 IS 'Ekip üyeliğini iptal eder — üyeliğin çağıranın yetkili olduğu işletme/zincire ait olduğunu doğrular (cross-tenant IDOR düzeltmesi, 2026-07-22). Called by: app/sahip/ekip/ekip-islemleri.ts.';
