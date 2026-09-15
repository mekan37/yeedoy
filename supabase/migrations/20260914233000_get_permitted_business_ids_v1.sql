-- "8 paralel implementasyon" RBAC konsolidasyonu — owner-panel denetiminde
-- ertelenen ana kalem. hasOwnerBusiness/getOwnerBusinessIds (TS,
-- src/lib/veri/owner/sahip-isletmeleri.ts, 43 dosyada kullanılıyor)
-- yalnızca owner_claims'e bakıyordu — business_team_memberships üzerinden
-- eklenen ekip üyeleri (manager/editor/staff/viewer) TS tarafında "hiç
-- işletmesi yokmuş" gibi görünüyordu (is_owner() genişletmesiyle panele
-- girebiliyorlardı ama içeride hiçbir işletme listelenmiyordu).
--
-- get_business_role_v1 zaten doğru 3-kaynaklı modeli (owner_claims ∪
-- chain_memberships ∪ business_team_memberships) uyguluyor ama yalnızca
-- TEK bir business_id için rol döndürüyor — TS tarafının ihtiyacı olan
-- "hangi işletmelerde en az X izni var" LİSTE sorgusu yok. Bu RPC aynı
-- 3-kaynaklı mantığı LİSTE olarak sunuyor; TS'te rol/rank mantığını
-- yeniden yazmak yerine tek gerçek kaynağı (get_business_role_v1'in
-- kullandığı aynı tablolar + business_role_rank_v1/business_role_has_permission_v1)
-- tekrar kullanıyor.
create or replace function public.get_permitted_business_ids_v1(p_permission text)
returns uuid[]
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return array[]::uuid[];
  end if;

  if public.is_admin() then
    return coalesce((select array_agg(id) from public.businesses), array[]::uuid[]);
  end if;

  return coalesce((
    with candidate as (
      select oc.business_id as business_id, 'owner'::text as role
      from public.owner_claims oc
      where oc.user_id = v_uid and oc.status = 'approved'

      union all

      select b.id as business_id, cm.role
      from public.chain_memberships cm
      join public.businesses b on b.chain_id = cm.chain_id
      where cm.user_id = v_uid

      union all

      select b.id as business_id, btm.role
      from public.business_team_memberships btm
      join public.businesses b
        on (btm.business_id = b.id) or (btm.chain_id is not null and btm.chain_id = b.chain_id)
      where btm.user_id = v_uid and btm.revoked_at is null
    ),
    best as (
      select business_id, max(public.business_role_rank_v1(role)) as best_rank
      from candidate
      group by business_id
    )
    select array_agg(business_id) from best
    where public.business_role_has_permission_v1(
      case best_rank
        when 500 then 'owner'
        when 400 then 'manager'
        when 300 then 'editor'
        when 200 then 'staff'
        else 'viewer'
      end,
      p_permission
    )
  ), array[]::uuid[]);
end;
$function$;

revoke all on function public.get_permitted_business_ids_v1(text) from public;
grant execute on function public.get_permitted_business_ids_v1(text) to authenticated;
revoke execute on function public.get_permitted_business_ids_v1(text) from anon;
