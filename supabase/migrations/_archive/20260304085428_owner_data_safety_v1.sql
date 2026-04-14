begin;

alter table public.menu_item_photos
  add column if not exists deleted_at timestamptz,
  add column if not exists deleted_by uuid;

create index if not exists idx_menu_item_photos_deleted_at
  on public.menu_item_photos (business_id, deleted_at desc)
  where deleted_at is not null;

create table if not exists public.menu_snapshots (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  source_menu_id uuid not null references public.menus(id) on delete cascade,
  menu_version integer not null default 1,
  snapshot_reason text not null default 'publish',
  snapshot_json jsonb not null,
  created_at timestamptz not null default now(),
  created_by uuid
);

create index if not exists idx_menu_snapshots_source_menu_created
  on public.menu_snapshots (source_menu_id, created_at desc);

create index if not exists idx_menu_snapshots_business_created
  on public.menu_snapshots (business_id, created_at desc);

alter table public.menu_snapshots enable row level security;

create or replace function public.create_menu_snapshot_v1(
  p_menu_id uuid,
  p_reason text default 'publish'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_snapshot_id uuid;
  v_snapshot jsonb;
  v_menu record;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select *
  into v_menu
  from public.menus
  where id = p_menu_id;

  v_business_id := v_menu.business_id;
  if v_business_id is null then
    raise exception 'menu_not_found';
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    raise exception 'forbidden';
  end if;

  v_snapshot := jsonb_build_object(
    'menu',
    jsonb_build_object(
      'title', v_menu.title,
      'kind', v_menu.kind,
      'active_from', v_menu.active_from,
      'active_to', v_menu.active_to,
      'status', v_menu.status,
      'version', coalesce(v_menu.version, 1),
      'source', coalesce(v_menu.source, 'owner'),
      'confidence_score', coalesce(v_menu.confidence_score, 0)
    ),
    'sections',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title', s.title,
            'sort_order', s.sort_order,
            'items',
            coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'name', i.name,
                    'description', i.description,
                    'price_cents', i.price_cents,
                    'currency', i.currency,
                    'catalog_item_id', i.catalog_item_id,
                    'sort_order', i.sort_order,
                    'is_available', i.is_available,
                    'image_url', i.image_url,
                    'tags', coalesce(i.tags, '[]'::jsonb),
                    'category_id', i.category_id
                  )
                  order by coalesce(i.sort_order, 0), i.created_at, i.name
                )
                from public.menu_items i
                where i.section_id = s.id
                  and i.is_available = true
              ),
              '[]'::jsonb
            )
          )
          order by s.sort_order, s.created_at
        )
        from public.menu_sections s
        where s.menu_id = p_menu_id
      ),
      '[]'::jsonb
    )
  );

  insert into public.menu_snapshots(
    business_id,
    source_menu_id,
    menu_version,
    snapshot_reason,
    snapshot_json,
    created_by
  )
  values (
    v_business_id,
    p_menu_id,
    coalesce(v_menu.version, 1),
    coalesce(nullif(trim(p_reason), ''), 'publish'),
    v_snapshot,
    auth.uid()
  )
  returning id into v_snapshot_id;

  return v_snapshot_id;
end;
$$;

create or replace function public.owner_publish_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_snapshot_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_snapshot_id := public.create_menu_snapshot_v1(p_menu_id, 'publish');

  update public.menus
  set status = 'published',
      updated_at = now()
  where id = p_menu_id;

  return jsonb_build_object(
    'ok', true,
    'id', p_menu_id,
    'message', 'Published',
    'snapshot_id', v_snapshot_id
  );
end;
$function$;

create or replace function public.list_owner_menu_versions_v1(
  p_menu_id uuid
)
returns table(
  snapshot_id uuid,
  menu_id uuid,
  menu_version integer,
  snapshot_reason text,
  created_at timestamptz,
  section_count integer,
  item_count integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.id as snapshot_id,
    s.source_menu_id as menu_id,
    s.menu_version,
    s.snapshot_reason,
    s.created_at,
    jsonb_array_length(coalesce(s.snapshot_json->'sections', '[]'::jsonb))::int as section_count,
    coalesce(
      (
        select sum(jsonb_array_length(coalesce(section_row->'items', '[]'::jsonb)))::int
        from jsonb_array_elements(coalesce(s.snapshot_json->'sections', '[]'::jsonb)) section_row
      ),
      0
    ) as item_count
  from public.menu_snapshots s
  join public.menus m on m.id = s.source_menu_id
  where s.source_menu_id = p_menu_id
    and (
      public.is_admin()
      or public.has_business_permission_v1(m.business_id, 'business_read')
    )
  order by s.created_at desc;
$$;

create or replace function public.owner_restore_menu_version_v1(
  p_snapshot_id uuid,
  p_archive_current_menu_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_snapshot record;
  v_new_menu_id uuid;
  v_new_section_id uuid;
  v_menu jsonb;
  v_section jsonb;
  v_item jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select *
  into v_snapshot
  from public.menu_snapshots
  where id = p_snapshot_id;

  if v_snapshot.id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Snapshot not found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_snapshot.business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_archive_current_menu_id is not null then
    update public.menus
    set status = 'archived',
        updated_at = now()
    where id = p_archive_current_menu_id
      and business_id = v_snapshot.business_id;
  end if;

  v_menu := coalesce(v_snapshot.snapshot_json->'menu', '{}'::jsonb);

  insert into public.menus(
    business_id,
    title,
    status,
    created_by,
    kind,
    active_from,
    active_to,
    source,
    confidence_score
  )
  values (
    v_snapshot.business_id,
    coalesce(nullif(trim(v_menu->>'title'), ''), 'Geri yüklenen menü'),
    'published',
    auth.uid(),
    nullif(trim(v_menu->>'kind'), ''),
    nullif(v_menu->>'active_from', '')::time,
    nullif(v_menu->>'active_to', '')::time,
    coalesce(nullif(trim(v_menu->>'source'), ''), 'owner'),
    coalesce((v_menu->>'confidence_score')::numeric, 0)
  )
  returning id into v_new_menu_id;

  for v_section in
    select value
    from jsonb_array_elements(coalesce(v_snapshot.snapshot_json->'sections', '[]'::jsonb))
  loop
    insert into public.menu_sections(
      menu_id,
      title,
      sort_order,
      created_by
    )
    values (
      v_new_menu_id,
      coalesce(nullif(trim(v_section->>'title'), ''), 'Bölüm'),
      coalesce((v_section->>'sort_order')::int, 0),
      auth.uid()
    )
    returning id into v_new_section_id;

    for v_item in
      select value
      from jsonb_array_elements(coalesce(v_section->'items', '[]'::jsonb))
    loop
      insert into public.menu_items(
        section_id,
        business_id,
        name,
        description,
        price_cents,
        currency,
        catalog_item_id,
        created_by,
        category_id,
        is_available,
        image_url,
        tags,
        sort_order
      )
      values (
        v_new_section_id,
        v_snapshot.business_id,
        coalesce(nullif(trim(v_item->>'name'), ''), 'Ürün'),
        nullif(trim(v_item->>'description'), ''),
        nullif(v_item->>'price_cents', '')::int,
        coalesce(nullif(trim(v_item->>'currency'), ''), 'TRY'),
        nullif(v_item->>'catalog_item_id', '')::bigint,
        auth.uid(),
        nullif(v_item->>'category_id', '')::uuid,
        coalesce((v_item->>'is_available')::boolean, true),
        nullif(trim(v_item->>'image_url'), ''),
        coalesce(v_item->'tags', '[]'::jsonb),
        coalesce((v_item->>'sort_order')::int, 0)
      );
    end loop;
  end loop;

  perform public.create_menu_snapshot_v1(v_new_menu_id, 'restore');

  return jsonb_build_object(
    'ok', true,
    'menu_id', v_new_menu_id,
    'message', 'Restored'
  );
end;
$$;

create or replace function public.list_owner_menu_trash_v1(
  p_business_id uuid
)
returns table(
  entity_type text,
  entity_id uuid,
  title text,
  subtitle text,
  occurred_at timestamptz,
  menu_id uuid,
  menu_item_id uuid,
  photo_url text
)
language sql
stable
security definer
set search_path = public
as $$
  with permission_check as (
    select
      public.is_admin() as is_admin,
      public.has_business_permission_v1(p_business_id, 'business_read') as can_read
  )
  select *
  from (
    select
      'menu'::text as entity_type,
      m.id as entity_id,
      m.title,
      'Menü'::text as subtitle,
      coalesce(m.updated_at, m.created_at) as occurred_at,
      m.id as menu_id,
      null::uuid as menu_item_id,
      null::text as photo_url
    from public.menus m, permission_check pc
    where m.business_id = p_business_id
      and m.status = 'archived'
      and (pc.is_admin or pc.can_read)

    union all

    select
      'item'::text as entity_type,
      i.id as entity_id,
      i.name as title,
      coalesce(ms.title, 'Bölüm') || ' • ' || coalesce(m.title, 'Menü') as subtitle,
      coalesce(i.updated_at, i.created_at) as occurred_at,
      ms.menu_id as menu_id,
      i.id as menu_item_id,
      null::text as photo_url
    from public.menu_items i
    join public.menu_sections ms on ms.id = i.section_id
    join public.menus m on m.id = ms.menu_id,
    permission_check pc
    where i.business_id = p_business_id
      and i.is_available = false
      and (pc.is_admin or pc.can_read)

    union all

    select
      'photo'::text as entity_type,
      p.id as entity_id,
      coalesce(mi.name, 'Ürün fotoğrafı') as title,
      'Fotoğraf'::text as subtitle,
      p.deleted_at as occurred_at,
      ms.menu_id as menu_id,
      p.menu_item_id,
      coalesce(nullif(p.url_thumb, ''), nullif(p.url_large, ''), p.url) as photo_url
    from public.menu_item_photos p
    join public.menu_items mi on mi.id = p.menu_item_id
    join public.menu_sections ms on ms.id = mi.section_id,
    permission_check pc
    where p.business_id = p_business_id
      and p.deleted_at is not null
      and (pc.is_admin or pc.can_read)
  ) rows
  order by occurred_at desc nulls last;
$$;

create or replace function public.owner_restore_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menus
  set status = 'draft',
      updated_at = now()
  where id = p_menu_id
    and status = 'archived';

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_archived');
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id);
end;
$$;

create or replace function public.owner_restore_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menu_items
  set is_available = true,
      updated_at = now()
  where id = p_item_id
    and is_available = false;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_archived');
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id);
end;
$$;

create or replace function public.owner_soft_delete_menu_item_photo_v1(
  p_photo_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_item_photos
  where id = p_photo_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menu_item_photos
  set deleted_at = now(),
      deleted_by = auth.uid()
  where id = p_photo_id
    and deleted_at is null;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'already_deleted');
  end if;

  return jsonb_build_object('ok', true, 'id', p_photo_id);
end;
$$;

create or replace function public.owner_restore_menu_item_photo_v1(
  p_photo_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_item_photos
  where id = p_photo_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menu_item_photos
  set deleted_at = null,
      deleted_by = null
  where id = p_photo_id
    and deleted_at is not null;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_deleted');
  end if;

  return jsonb_build_object('ok', true, 'id', p_photo_id);
end;
$$;

create or replace function public.owner_force_delete_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  delete from public.menus
  where id = p_menu_id
    and status = 'archived';

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_archived');
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id);
end;
$$;

create or replace function public.owner_force_delete_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  delete from public.menu_items
  where id = p_item_id
    and is_available = false;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_archived');
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id);
end;
$$;

create or replace function public.owner_force_delete_menu_item_photo_v1(
  p_photo_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_item_photos
  where id = p_photo_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  delete from public.menu_item_photos
  where id = p_photo_id
    and deleted_at is not null;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_deleted');
  end if;

  return jsonb_build_object('ok', true, 'id', p_photo_id);
end;
$$;

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
    and p.deleted_at is null
    and (
      (p.status = 'approved' and p.is_hidden is not true and p.is_shadow is not true)
      or p.created_by = auth.uid()
      or public.is_admin()
    )
  order by p.created_at desc
  limit greatest(p_limit, 0);
$$;

grant execute on function public.create_menu_snapshot_v1(uuid, text) to authenticated;
grant execute on function public.list_owner_menu_versions_v1(uuid) to authenticated;
grant execute on function public.owner_restore_menu_version_v1(uuid, uuid) to authenticated;
grant execute on function public.list_owner_menu_trash_v1(uuid) to authenticated;
grant execute on function public.owner_restore_menu_v1(uuid) to authenticated;
grant execute on function public.owner_restore_menu_item_v1(uuid) to authenticated;
grant execute on function public.owner_soft_delete_menu_item_photo_v1(uuid) to authenticated;
grant execute on function public.owner_restore_menu_item_photo_v1(uuid) to authenticated;
grant execute on function public.owner_force_delete_menu_v1(uuid) to authenticated;
grant execute on function public.owner_force_delete_menu_item_v1(uuid) to authenticated;
grant execute on function public.owner_force_delete_menu_item_photo_v1(uuid) to authenticated;

commit;;
