begin;
-- Secure bucket for user photos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media',
  'menu-media',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;
-- Storage object policies (for direct SDK usage if any).
drop policy if exists menu_media_read_all on storage.objects;
create policy menu_media_read_all
  on storage.objects
  for select
  to public
  using (bucket_id = 'menu-media');
drop policy if exists menu_media_insert_auth on storage.objects;
create policy menu_media_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'menu-media'
    and owner = auth.uid()
    and name like 'business/%'
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );
drop policy if exists menu_media_update_own_or_admin on storage.objects;
create policy menu_media_update_own_or_admin
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  )
  with check (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  );
drop policy if exists menu_media_delete_own_or_admin on storage.objects;
create policy menu_media_delete_own_or_admin
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  );
-- Moderation fields.
alter table public.menu_item_photos
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  add column if not exists is_hidden boolean not null default false,
  add column if not exists moderation_note text;
alter table public.business_media
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  add column if not exists is_hidden boolean not null default false,
  add column if not exists moderation_note text;
create index if not exists idx_menu_item_photos_status_hidden
  on public.menu_item_photos(status, is_hidden, created_at desc);
create index if not exists idx_business_media_status_hidden
  on public.business_media(status, is_hidden, created_at desc);
create or replace function public.add_menu_item_photo_v1(
  p_menu_item_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'supabase_storage'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_photo_id uuid;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  v_rate := public.consume_rate_limit_v1('menu_photo', 20);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'menu_photo_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by,
    is_shadow,
    status,
    is_hidden
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid(),
    v_shadow,
    'pending',
    false
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id, 'shadowed', v_shadow, 'pending', true);
end;
$function$;
create or replace function public.get_menu_item_photos_v1(
  p_menu_item_id uuid,
  p_limit integer default 12
) returns table(
  id uuid,
  url text,
  url_large text,
  url_thumb text,
  provider text,
  created_at timestamp with time zone,
  up_votes integer,
  down_votes integer,
  score integer,
  my_vote smallint
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.url,
    p.url_large,
    p.url_thumb,
    p.provider,
    p.created_at,
    p.up_votes,
    p.down_votes,
    (p.up_votes - p.down_votes) as score,
    (select v.vote from public.menu_item_photo_votes v
      where v.photo_id = p.id and v.user_id = auth.uid()
      limit 1) as my_vote
  from public.menu_item_photos p
  where p.menu_item_id = p_menu_item_id
    and (
      (p.status = 'approved' and p.is_hidden is not true and p.is_shadow is not true)
      or p.created_by = auth.uid()
      or public.is_admin()
    )
  order by p.created_at desc
  limit greatest(p_limit, 0);
$$;
-- Reported photo => hidden + pending.
create or replace function public.trg_hide_reported_menu_photo_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_type = 'menu_item_photo' and new.menu_item_photo_id is not null then
    update public.menu_item_photos
    set is_hidden = true,
        status = 'pending',
        moderation_note = coalesce(moderation_note, 'auto_hidden_by_report')
    where id = new.menu_item_photo_id;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_hide_reported_menu_photo_v1 on public.reports;
create trigger trg_hide_reported_menu_photo_v1
after insert on public.reports
for each row execute function public.trg_hide_reported_menu_photo_v1();
-- Admin moderation endpoint.
create or replace function public.admin_set_menu_item_photo_moderation_v1(
  p_photo_id uuid,
  p_status text,
  p_is_hidden boolean default false,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  if p_status not in ('pending', 'approved', 'rejected') then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  update public.menu_item_photos
  set status = p_status,
      is_hidden = coalesce(p_is_hidden, false),
      moderation_note = nullif(trim(coalesce(p_note, '')), '')
  where id = p_photo_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;
grant all on function public.admin_set_menu_item_photo_moderation_v1(uuid, text, boolean, text) to authenticated;
grant all on function public.admin_set_menu_item_photo_moderation_v1(uuid, text, boolean, text) to service_role;
commit;
