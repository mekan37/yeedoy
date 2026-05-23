-- M4: Menu item translation upsert/fetch RPCs

-- ── Upsert ───────────────────────────────────────────────────────────────────
-- Owner can upsert a translation for a menu item they own.

create or replace function public.upsert_menu_item_translation_v1(
  p_item_id  uuid,
  p_locale   text,
  p_name     text,
  p_description text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _business_id uuid;
  _row menu_translations%rowtype;
begin
  -- Verify caller owns the business that owns this menu item
  select b.id into _business_id
  from business_claims bc
  join businesses b on b.id = bc.business_id
  join menus       m  on m.business_id = b.id
  join menu_sections ms on ms.menu_id = m.id
  join menu_items  mi on mi.section_id = ms.id
  where mi.id = p_item_id
    and bc.user_id = auth.uid()
    and bc.is_active = true
  limit 1;

  if _business_id is null then
    raise exception 'unauthorized';
  end if;

  insert into menu_translations (entity_type, entity_id, locale, name, description)
  values ('item', p_item_id, p_locale, p_name, p_description)
  on conflict (entity_id, locale)
    where entity_type = 'item'
  do update set
    name        = excluded.name,
    description = excluded.description;

  select * into _row
  from menu_translations
  where entity_type = 'item'
    and entity_id = p_item_id
    and locale = p_locale;

  return jsonb_build_object(
    'id',          _row.id,
    'locale',      _row.locale,
    'name',        _row.name,
    'description', _row.description
  );
end;
$$;

-- ── Fetch translations for an item ───────────────────────────────────────────

create or replace function public.get_menu_item_translations_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _result jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object(
    'locale',      locale,
    'name',        name,
    'description', description
  )), '[]'::jsonb)
  into _result
  from menu_translations
  where entity_type = 'item'
    and entity_id = p_item_id;

  return _result;
end;
$$;

-- Add unique constraint if not already present
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'menu_translations_entity_id_locale_unique'
  ) then
    alter table menu_translations
      add constraint menu_translations_entity_id_locale_unique
      unique (entity_type, entity_id, locale);
  end if;
end;
$$;
