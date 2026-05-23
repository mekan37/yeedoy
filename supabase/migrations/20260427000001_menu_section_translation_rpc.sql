-- M4: Menu section (category) title translation upsert/fetch RPCs

create or replace function public.upsert_menu_section_translation_v1(
  p_section_id uuid,
  p_locale     text,
  p_name       text
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
  -- Verify caller owns the business that owns this section
  select b.id into _business_id
  from business_claims bc
  join businesses b  on b.id = bc.business_id
  join menus       m  on m.business_id = b.id
  join menu_sections ms on ms.menu_id = m.id
  where ms.id = p_section_id
    and bc.user_id = auth.uid()
    and bc.is_active = true
  limit 1;

  if _business_id is null then
    raise exception 'unauthorized';
  end if;

  insert into menu_translations (entity_type, entity_id, locale, name, description)
  values ('category', p_section_id, p_locale, p_name, null)
  on conflict (entity_id, locale)
    where entity_type = 'category'
  do update set name = excluded.name;

  select * into _row
  from menu_translations
  where entity_type = 'category'
    and entity_id = p_section_id
    and locale = p_locale;

  return jsonb_build_object(
    'id',     _row.id,
    'locale', _row.locale,
    'name',   _row.name
  );
end;
$$;

-- Fetch existing section translation
create or replace function public.get_menu_section_translations_v1(
  p_section_id uuid
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    jsonb_object_agg(locale, name) filter (where locale is not null),
    '{}'::jsonb
  )
  from menu_translations
  where entity_type = 'category'
    and entity_id = p_section_id;
$$;

grant execute on function public.upsert_menu_section_translation_v1 to authenticated;
grant execute on function public.get_menu_section_translations_v1    to authenticated;
