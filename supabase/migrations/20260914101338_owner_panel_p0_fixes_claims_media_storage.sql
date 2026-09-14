-- Sahip Paneli Güvenlik Denetimi — P0 düzeltmeleri.
--
-- P0-1: owner_claims RLS INSERT politikası status/handled_by'ı hiç
-- kısıtlamıyordu; herhangi bir authenticated kullanıcı tek bir PostgREST
-- isteğiyle ("status":"approved") herhangi bir işletmenin "onaylı sahibi"
-- olabiliyordu — panelin tüm yetki zinciri (is_owner(), hasOwnerBusiness,
-- plan limitleri, RPC guard'ları) bu tek tabloya dayandığı için bu,
-- platform genelinde tam tenant ele geçirmeye denk geliyordu.
alter table owner_claims
  add constraint owner_claims_status_check check (status in ('pending','approved','rejected'));

drop policy if exists owner_claims_insert_access on owner_claims;
create policy owner_claims_insert_access on owner_claims
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending' and handled_by is null and handled_at is null);

-- Defense in depth: WITH CHECK'in ötesinde, ileride bir politika
-- regresyonu aynı açığı yeniden açarsa bile INSERT'i her zaman pending'e
-- zorlayan bir trigger.
create or replace function owner_claims_force_pending_on_insert()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin() then
    new.status := 'pending';
    new.handled_by := null;
    new.handled_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists owner_claims_force_pending on owner_claims;
create trigger owner_claims_force_pending
  before insert on owner_claims
  for each row execute function owner_claims_force_pending_on_insert();

-- P0-2: add_business_media_v1 canlıda 20260911080428_add_business_media_v1_ownership_check
-- ile zaten düzeltilmiş (denetim raporu 08 Eylül, fix 11 Eylül — rapor
-- bu konuda artık güncel değil). Kalan hijyen: anon bu mutasyon RPC'sini
-- çağırmak için hiçbir meşru sebebe sahip değil (auth.uid() is null
-- kontrolü zaten anon'u engelliyor, ama proje konvansiyonu gereği revoke
-- ediliyor).
revoke execute on function public.add_business_media_v1(uuid, text, text, text, text, text) from anon;

-- P0-3: menu-media bucket'ında "yalnızca bucket_id" kontrol eden gevşek
-- authenticated UPDATE/DELETE/INSERT politikaları, owner-scoped sıkı
-- politikalarla birlikte var oluyordu. Postgres permissive politikaları
-- OR'ladığı için gevşek politika tek başına herhangi bir authenticated
-- kullanıcının bucket'taki HERHANGİ bir nesneyi silmesine/üzerine
-- yazmasına izin veriyordu. Uygulamadaki tüm işletme-fotoğrafı yazmaları
-- service_role ile server route'lardan geçiyor (RLS'i zaten bypass
-- ediyor); authenticated rolünün bu bucket'a doğrudan yazması yalnızca
-- iki client-side avatar yükleyicisi tarafından, kendi
-- user-avatars/<uid>.webp path'ine kullanılıyor. Gevşek politikaları
-- kaldır, kalan INSERT politikasını çağıranın kendi avatar dosyasına
-- sabitle.
drop policy if exists menu_media_auth_update on storage.objects;
drop policy if exists menu_media_auth_delete on storage.objects;
drop policy if exists menu_media_auth_insert on storage.objects;

drop policy if exists menu_media_insert_auth on storage.objects;
create policy menu_media_insert_auth on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'menu-media'
    and name = 'user-avatars/' || (auth.uid())::text || '.webp'
  );
