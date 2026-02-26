begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media-private',
  'menu-media-private',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists menu_media_private_insert_auth on storage.objects;
create policy menu_media_private_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'menu-media-private'
    and owner = auth.uid()
    and name like 'critical/business/%'
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );

drop policy if exists menu_media_private_read_owner_admin on storage.objects;
create policy menu_media_private_read_owner_admin
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

drop policy if exists menu_media_private_update_owner_admin on storage.objects;
create policy menu_media_private_update_owner_admin
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  )
  with check (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

drop policy if exists menu_media_private_delete_owner_admin on storage.objects;
create policy menu_media_private_delete_owner_admin
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

create or replace function public.trg_hide_reported_business_media_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_type = 'business_media' and new.target_id is not null then
    update public.business_media
       set is_hidden = true,
           status = 'pending',
           moderation_note = coalesce(moderation_note, 'auto_hidden_by_report')
     where id::text = new.target_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_hide_reported_business_media_v1 on public.reports;
create trigger trg_hide_reported_business_media_v1
after insert on public.reports
for each row execute function public.trg_hide_reported_business_media_v1();

commit;

