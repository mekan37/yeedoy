-- Migration: Fix storage bucket policies for menu-media and temp buckets
-- Problem 1: Buckets were recreated (2026-06-09) and policies may be missing
-- Problem 2: INSERT policy restricts path to 'business/%' but mobile uploads to 'user-avatars/%'
-- Problem 3: UPDATE/DELETE policies use `owner = auth.uid()` (UUID type, always NULL in new Supabase)
--            Must use `owner_id = auth.uid()::text` instead
-- ============================================================

begin;

-- ── 1. Ensure buckets exist ──────────────────────────────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media', 'menu-media', true, 5242880,
  array['image/jpeg','image/jpg','image/png','image/webp']
)
on conflict (id) do update
  set public             = true,
      file_size_limit    = 5242880,
      allowed_mime_types = array['image/jpeg','image/jpg','image/png','image/webp'];

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'temp', 'temp', true, 10485760,
  array['image/jpeg','image/jpg','image/png','image/webp']
)
on conflict (id) do update
  set public             = true,
      file_size_limit    = 10485760,
      allowed_mime_types = array['image/jpeg','image/jpg','image/png','image/webp'];

-- ── 2. Drop ALL existing menu-media policies (clean slate) ───────────────────
drop policy if exists "menu_media_read_all"            on storage.objects;
drop policy if exists "menu_media_insert_auth"         on storage.objects;
drop policy if exists "menu_media_update_own_or_admin" on storage.objects;
drop policy if exists "menu_media_delete_own_or_admin" on storage.objects;

-- ── 3. Drop ALL existing temp policies ──────────────────────────────────────
drop policy if exists "temp_read_all"    on storage.objects;
drop policy if exists "temp_insert_auth" on storage.objects;
drop policy if exists "temp_delete_auth" on storage.objects;

-- ── 4. Recreate menu-media policies ─────────────────────────────────────────

-- SELECT: public read (covers CDN, app image loading, web)
create policy "menu_media_read_all"
  on storage.objects
  for select
  to public
  using (bucket_id = 'menu-media');

-- INSERT: authenticated users may upload to any path inside menu-media
--   Allowed paths:
--     business/...        (menu photos, business images)
--     user-avatars/...    (profile avatar — was previously blocked!)
--   File type restricted to images only
create policy "menu_media_insert_auth"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'menu-media'
    and (
      name like 'business/%'
      or name like 'user-avatars/%'
    )
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );

-- UPDATE: owner (via owner_id text column) OR admin
--   NOTE: `owner` (UUID) is always NULL in Supabase Storage >=2.x
--         `owner_id` (text) contains auth.uid()::text when authenticated user uploads
create policy "menu_media_update_own_or_admin"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner_id = auth.uid()::text or public.is_admin())
  )
  with check (
    bucket_id = 'menu-media'
    and (owner_id = auth.uid()::text or public.is_admin())
  );

-- DELETE: owner (via owner_id text) OR admin
create policy "menu_media_delete_own_or_admin"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner_id = auth.uid()::text or public.is_admin())
  );

-- ── 5. Recreate temp policies ────────────────────────────────────────────────

-- SELECT: public read
create policy "temp_read_all"
  on storage.objects
  for select
  to public
  using (bucket_id = 'temp');

-- INSERT: authenticated, any path inside temp
create policy "temp_insert_auth"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'temp'
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );

-- DELETE: owner (via owner_id text) OR admin
create policy "temp_delete_auth"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'temp'
    and (owner_id = auth.uid()::text or public.is_admin())
  );

commit;
