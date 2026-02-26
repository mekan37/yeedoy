create function public.owner_create_menu_v1(
  p_business_id uuid,
  p_title text,
  p_kind text default null,
  p_active_from timestamptz default null,
  p_active_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_kind text;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_active_from is not null and p_active_to is not null and p_active_from > p_active_to then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid active range');
  end if;

  v_kind := nullif(trim(p_kind), '');

  insert into public.menus(
    business_id, title, kind, status, created_by, active_from, active_to
  )
  values (
    p_business_id, v_title, v_kind, 'draft', auth.uid(), p_active_from, p_active_to
  )
  returning id into v_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.create', 'menus', v_menu_id, jsonb_build_object('business_id', p_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', v_menu_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_v1(
  p_menu_id uuid,
  p_title text default null,
  p_kind text default null,
  p_active_from timestamptz default null,
  p_active_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_kind text;
  v_business_id uuid;
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

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_active_from is not null and p_active_to is not null and p_active_from > p_active_to then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid active range');
  end if;

  v_title := nullif(trim(p_title), '');
  v_kind := nullif(trim(p_kind), '');

  update public.menus
  set
    title = coalesce(v_title, title),
    kind = coalesce(v_kind, kind),
    active_from = coalesce(p_active_from, active_from),
    active_to = coalesce(p_active_to, active_to),
    updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.update', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Updated');
end;
$function$;

create function public.owner_archive_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
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

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menus
  set status = 'archived',
      updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.archive', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Archived');
end;
$function$;

create function public.owner_publish_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
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

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menus
  set status = 'published',
      updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.publish', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Published');
end;
$function$;

create function public.owner_create_menu_section_v1(
  p_menu_id uuid,
  p_title text,
  p_sort_order integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_sort integer;
  v_section_id uuid;
  v_business_id uuid;
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

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_sort_order is null then
    select coalesce(max(sort_order), 0) + 1 into v_sort
    from public.menu_sections
    where menu_id = p_menu_id;
  else
    v_sort := p_sort_order;
  end if;

  insert into public.menu_sections(menu_id, title, sort_order, created_by)
  values (p_menu_id, v_title, v_sort, auth.uid())
  returning id into v_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.create', 'menu_sections', v_section_id, jsonb_build_object('menu_id', p_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', v_section_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_section_v1(
  p_section_id uuid,
  p_title text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_business_id uuid;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, s.menu_id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  update public.menu_sections
  set title = v_title,
      updated_at = now()
  where id = p_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.update', 'menu_sections', p_section_id, jsonb_build_object('menu_id', v_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_section_id, 'message', 'Updated');
end;
$function$;

create function public.owner_delete_menu_section_v1(
  p_section_id uuid,
  p_delete_items boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_menu_id uuid;
  v_has_items boolean;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, s.menu_id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  select exists(
    select 1 from public.menu_items where section_id = p_section_id
  ) into v_has_items;

  if v_has_items and not p_delete_items then
    return jsonb_build_object('ok', false, 'code', 'has_items', 'message', 'Section has items');
  end if;

  if p_delete_items then
    update public.menu_items
    set status = 'archived',
        updated_at = now()
    where section_id = p_section_id;
  end if;

  delete from public.menu_sections where id = p_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.delete', 'menu_sections', p_section_id, jsonb_build_object('menu_id', v_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_section_id, 'message', 'Deleted');
end;
$function$;

create function public.owner_reorder_menu_sections_v1(
  p_menu_id uuid,
  p_section_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_count int;
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

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_section_ids is null or array_length(p_section_ids, 1) is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Empty section list');
  end if;

  select count(*) into v_count
  from public.menu_sections
  where menu_id = p_menu_id
    and id = any(p_section_ids);

  if v_count <> array_length(p_section_ids, 1) then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Section list mismatch');
  end if;

  update public.menu_sections s
  set sort_order = r.ord
  from (
    select unnest(p_section_ids) as id, row_number() over () as ord
  ) r
  where s.id = r.id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.reorder', 'menu_sections', null, jsonb_build_object('menu_id', p_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Reordered');
end;
$function$;

create function public.owner_create_menu_item_v1(
  p_section_id uuid,
  p_name text,
  p_description text default null,
  p_price_cents integer default null,
  p_currency text default 'TRY',
  p_catalog_item_id bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_name text;
  v_desc text;
  v_currency text;
  v_item_id uuid;
  v_business_id uuid;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, m.id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_name := nullif(trim(p_name), '');
  if v_name is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Name required');
  end if;

  if p_price_cents is not null and p_price_cents < 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid price');
  end if;

  v_desc := nullif(trim(p_description), '');
  v_currency := nullif(trim(p_currency), '');
  if v_currency is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Currency required');
  end if;

  insert into public.menu_items(
    section_id,
    business_id,
    name,
    description,
    price_cents,
    currency,
    catalog_item_id,
    status,
    created_by
  )
  values (
    p_section_id,
    v_business_id,
    v_name,
    v_desc,
    p_price_cents,
    v_currency,
    p_catalog_item_id,
    'draft',
    auth.uid()
  )
  returning id into v_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.create',
      'menu_items',
      v_item_id,
      jsonb_build_object('menu_id', v_menu_id, 'section_id', p_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', v_item_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_item_v1(
  p_item_id uuid,
  p_name text default null,
  p_description text default null,
  p_price_cents integer default null,
  p_currency text default null,
  p_catalog_item_id bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_name text;
  v_desc text;
  v_currency text;
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_price_cents is not null and p_price_cents < 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid price');
  end if;

  v_name := nullif(trim(p_name), '');
  v_desc := nullif(trim(p_description), '');
  v_currency := nullif(trim(p_currency), '');

  update public.menu_items
  set
    name = coalesce(v_name, name),
    description = coalesce(v_desc, description),
    price_cents = coalesce(p_price_cents, price_cents),
    currency = coalesce(v_currency, currency),
    catalog_item_id = coalesce(p_catalog_item_id, catalog_item_id),
    updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.update',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Updated');
end;
$function$;

create function public.owner_archive_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menu_items
  set status = 'archived',
      updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.archive',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Archived');
end;
$function$;

create function public.owner_publish_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menu_items
  set status = 'published',
      updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.publish',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Published');
end;
$function$;

-- NOTE: menu_items tablosunda sort_order bulunmadığı için
-- owner_reorder_menu_items_v1 oluşturulmadı. Gerekirse schema'ya sort_order eklenmeli.

-- Smoke tests (örnek çağrılar)
-- select public.owner_create_menu_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Öğle', null, null, null);
-- select public.owner_update_menu_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Güncel', null, null, null);
-- select public.owner_archive_menu_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_publish_menu_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_create_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Ana yemekler', null);
-- select public.owner_update_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Başlangıçlar');
-- select public.owner_delete_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, false);
-- select public.owner_reorder_menu_sections_v1('00000000-0000-0000-0000-000000000000'::uuid, array['00000000-0000-0000-0000-000000000000'::uuid]);
-- select public.owner_create_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Köfte', 'Not', 25000, 'TRY', null);
-- select public.owner_update_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Köfte', 'Not', 26000, 'TRY', null);
-- select public.owner_archive_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_publish_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid);




