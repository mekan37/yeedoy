-- Storage deletion queue + temp upload cleanup wiring

create table if not exists public.storage_deletion_queue (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  reason text not null,
  scheduled_at timestamptz not null default now(),
  processed_at timestamptz null,
  attempts int not null default 0,
  last_error text null
);
create index if not exists storage_deletion_queue_pending_idx
  on public.storage_deletion_queue (processed_at, scheduled_at)
  where processed_at is null;
create index if not exists storage_deletion_queue_reason_idx
  on public.storage_deletion_queue (reason, scheduled_at desc);
create unique index if not exists storage_deletion_queue_dedupe_idx
  on public.storage_deletion_queue (bucket, path, reason)
  where processed_at is null;
alter table public.storage_deletion_queue enable row level security;
drop policy if exists storage_deletion_queue_admin_select on public.storage_deletion_queue;
create policy storage_deletion_queue_admin_select
on public.storage_deletion_queue
for select
to authenticated
using (coalesce(public.is_admin(), false));
drop policy if exists storage_deletion_queue_admin_write on public.storage_deletion_queue;
create policy storage_deletion_queue_admin_write
on public.storage_deletion_queue
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));
grant all on public.storage_deletion_queue to service_role;
create or replace function public.promote_temp_upload_to_menu_asset_v1(
  p_temp_upload_id uuid,
  p_asset_type text,
  p_menu_version int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_temp public.temp_uploads%rowtype;
  v_menu_asset_id uuid;
  v_asset_type text;
begin
  if v_actor is null then
    raise exception 'auth_required';
  end if;

  select *
    into v_temp
  from public.temp_uploads t
  where t.id = p_temp_upload_id
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'temp_upload_not_found');
  end if;

  if not (
    coalesce(public.is_admin(), false)
    or coalesce(public.is_owner_of_business(v_temp.business_id), false)
  ) then
    raise exception 'not_authorized';
  end if;

  if v_temp.status <> 'pending' then
    return jsonb_build_object('ok', false, 'error', 'temp_upload_not_pending');
  end if;

  v_asset_type := lower(trim(coalesce(p_asset_type, 'menu_page')));
  if v_asset_type not in ('menu_page', 'menu_pdf', 'thumbnail') then
    return jsonb_build_object('ok', false, 'error', 'invalid_asset_type');
  end if;

  insert into public.menu_assets (
    business_id,
    menu_version,
    asset_type,
    storage_bucket,
    storage_path,
    source,
    created_by
  )
  values (
    v_temp.business_id,
    greatest(coalesce(p_menu_version, 1), 1),
    v_asset_type,
    v_temp.storage_bucket,
    v_temp.storage_path,
    'user_promoted',
    v_actor
  )
  returning id into v_menu_asset_id;

  update public.temp_uploads t
  set
    status = 'promoted',
    reviewed_by = v_actor,
    reviewed_at = now()
  where t.id = v_temp.id;

  if coalesce(v_temp.storage_path, '') <> '' then
    insert into public.storage_deletion_queue (bucket, path, reason)
    values (
      coalesce(nullif(v_temp.storage_bucket, ''), 'temp'),
      v_temp.storage_path,
      'promoted_cleanup'
    )
    on conflict do nothing;
  end if;

  return jsonb_build_object(
    'ok', true,
    'menu_asset_id', v_menu_asset_id,
    'temp_upload_id', v_temp.id
  );
end;
$$;
grant execute on function public.promote_temp_upload_to_menu_asset_v1(uuid, text, int)
  to authenticated, service_role;
create or replace function public.mark_expired_temp_uploads_v1(
  p_limit int default 500
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
begin
  with target as (
    select
      t.id,
      t.storage_bucket,
      t.storage_path
    from public.temp_uploads t
    where t.status in ('pending', 'rejected')
      and t.expires_at < now()
    order by t.expires_at asc
    limit greatest(coalesce(p_limit, 500), 1)
  ),
  updated as (
    update public.temp_uploads t
    set
      status = 'expired',
      reviewed_at = coalesce(t.reviewed_at, now())
    where t.id in (select id from target)
    returning t.id
  ),
  queued as (
    insert into public.storage_deletion_queue (bucket, path, reason)
    select
      coalesce(nullif(target.storage_bucket, ''), 'temp'),
      target.storage_path,
      'ttl_cleanup'
    from target
    join updated on updated.id = target.id
    where coalesce(target.storage_path, '') <> ''
    on conflict do nothing
    returning id
  )
  select count(*) into v_count
  from updated;

  return v_count;
end;
$$;
grant execute on function public.mark_expired_temp_uploads_v1(int) to service_role;
