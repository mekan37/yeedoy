-- Migration: claim-evidence storage bucket and policies
-- Purpose: Owner claim evidence uploads for the web owner-claim flow.
-- Notes:
--   - Bucket is private; evidence may contain sensitive business documents.
--   - Web upload route writes paths as: {auth.uid()}/{timestamp}-kanit.{ext}
--   - Users can upload only under their own UUID prefix.
--   - Users can read/sign their own object; admins can read/sign all evidence.
--   - Users cannot update/delete evidence objects. Admins may update/delete for moderation cleanup.

begin;

-- Ensure the private bucket exists and remains aligned with the web route limits.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'claim-evidence',
  'claim-evidence',
  false,
  10485760,
  array['image/jpeg','image/jpg','image/png','image/webp','application/pdf']
)
on conflict (id) do update
  set name               = 'claim-evidence',
      public             = false,
      file_size_limit    = 10485760,
      allowed_mime_types = array['image/jpeg','image/jpg','image/png','image/webp','application/pdf'];

-- Clean slate for this bucket's policy names; keeps the migration repeatable.
drop policy if exists "claim_evidence_insert_own_prefix" on storage.objects;
drop policy if exists "claim_evidence_select_owner_or_admin" on storage.objects;
drop policy if exists "claim_evidence_update_admin_only" on storage.objects;
drop policy if exists "claim_evidence_delete_admin_only" on storage.objects;

-- Authenticated users may upload only into their own UUID folder.
create policy "claim_evidence_insert_own_prefix"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'claim-evidence'
    and split_part(name, '/', 1) = auth.uid()::text
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
      or lower(name) like '%.pdf'
    )
  );

-- Users need SELECT on their own object so the existing route can create a signed URL.
-- Admins need SELECT for claim review. The bucket itself remains private.
create policy "claim_evidence_select_owner_or_admin"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'claim-evidence'
    and (
      owner_id = auth.uid()::text
      or split_part(name, '/', 1) = auth.uid()::text
      or public.is_admin()
    )
  );

-- Evidence should not be mutable by claim submitters after upload.
create policy "claim_evidence_update_admin_only"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'claim-evidence'
    and public.is_admin()
  )
  with check (
    bucket_id = 'claim-evidence'
    and public.is_admin()
  );

-- Claim submitters cannot delete evidence, including their own or anyone else's.
create policy "claim_evidence_delete_admin_only"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'claim-evidence'
    and public.is_admin()
  );

-- Eski/yetersiz policy seti temizleniyor: claim_evidence_admin_select sadece
-- service_role'e bağlıydı (zaten RLS bypass ediyor, no-op) ve gerçek admin
-- (authenticated + is_admin()) için kanıt okuma izni yoktu. Yeni
-- claim_evidence_select_owner_or_admin bu boşluğu doğru şekilde kapatıyor.
drop policy if exists "claim_evidence_admin_select" on storage.objects;
drop policy if exists "claim_evidence_insert" on storage.objects;
drop policy if exists "claim_evidence_owner_select" on storage.objects;

commit;
