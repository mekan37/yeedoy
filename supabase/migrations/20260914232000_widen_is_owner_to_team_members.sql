-- Canlı Supabase Güvenlik & Bütünlük Denetimi P2-9: is_owner() yalnızca
-- owner_claims'e bakıyordu — business_team_memberships üzerinden eklenmiş
-- ekip üyeleri (manager/editor/staff/viewer) /sahip panelinin proxy.ts'teki
-- TEK guard'ından (rpc('is_owner')) hiç geçemiyordu, panele hiç giremiyordu.
--
-- Bilinçli kapsam sınırlaması: is_owner() yalnızca bu TEK panel-giriş
-- guard'ında kullanılıyor (proxy.ts:233, kod tabanında başka hiçbir
-- call-site yok — doğrulandı). hasOwnerBusiness/getOwnerBusinessIds
-- (src/lib/veri/owner/sahip-isletmeleri.ts, 47 ayrı dosyada TEK
-- write-guard katmanı olarak kullanılıyor) TAMAMEN AYRI bir kod parçası —
-- bu migration ONU GENİŞLETMİYOR. O daha geniş "8 paralel implementasyon"
-- RBAC mimari konsolidasyonu bilinçli olarak ayrı, kendi başına bir işe
-- ertelendi (per-call-site audit gerektiriyor, [[feedback_dont_blindly_broaden_shared_auth_helpers]]).
--
-- Panele girebilmek ile panel İÇİNDE hangi eylemleri yapabilmek FARKLI
-- sorular: panele artık her aktif ekip üyesi girebiliyor, ama her sayfa/
-- RPC kendi has_business_permission_v1 kontrolünü zaten ayrı yapıyor
-- (örn. team_manage, menu_write) — bu migration yalnızca "kapıdan geçme"
-- kuralını gerçek yetki modeliyle hizalıyor, içerideki granüler
-- yetkilendirmeyi değiştirmiyor.
create or replace function public.is_owner()
returns boolean
language sql
stable security definer
set search_path to 'public'
as $function$
  select exists (
    select 1 from public.owner_claims
    where user_id = auth.uid() and status = 'approved'
  ) or exists (
    select 1 from public.business_team_memberships
    where user_id = auth.uid()
      and revoked_at is null
      and accepted_at is not null
  );
$function$;
