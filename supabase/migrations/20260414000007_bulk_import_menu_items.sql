-- ─────────────────────────────────────────────────────────────────────────────
-- owner_bulk_import_menu_items_v1
-- Bulk-inserts sections + items from an Excel/CSV upload.
-- p_rows: [{"section":"Çorbalar","name":"Mercimek","description":"...","price_cents":7500,"is_available":true}, ...]
-- Returns: {ok, inserted, sections_created, skipped, errors:[{row, reason}]}
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.owner_bulk_import_menu_items_v1(
  p_menu_id uuid,
  p_rows    jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id     uuid;
  v_section_id      uuid;
  v_row             jsonb;
  v_section_name    text;
  v_item_name       text;
  v_description     text;
  v_price_cents     int;
  v_is_available    bool;
  v_row_idx         int := 0;
  v_inserted        int := 0;
  v_sections_made   int := 0;
  v_skipped         int := 0;
  v_errors          jsonb := '[]'::jsonb;
  v_section_cache   jsonb := '{}'::jsonb;  -- section_name → section_id
  v_section_sort    int;
begin
  -- Ownership check
  select m.business_id into v_business_id
  from menus m
  where m.id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'menu_not_found');
  end if;

  if not exists (
    select 1 from owner_claims
    where business_id = v_business_id
      and user_id     = auth.uid()
      and status      = 'approved'
  ) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  -- Pre-load existing sections into cache
  select jsonb_object_agg(lower(trim(title)), id::text)
  into v_section_cache
  from menu_sections
  where menu_id = p_menu_id;

  v_section_cache := coalesce(v_section_cache, '{}'::jsonb);

  -- Process current max sort_order for sections
  select coalesce(max(sort_order), -1) into v_section_sort
  from menu_sections where menu_id = p_menu_id;

  -- Process each row
  for v_row in select * from jsonb_array_elements(p_rows)
  loop
    v_row_idx := v_row_idx + 1;

    v_section_name := trim(v_row->>'section');
    v_item_name    := trim(v_row->>'name');

    -- Skip empty rows
    if v_section_name is null or v_section_name = ''
       or v_item_name is null or v_item_name = '' then
      v_skipped := v_skipped + 1;
      continue;
    end if;

    -- Validate name length
    if length(v_item_name) < 2 then
      v_errors := v_errors || jsonb_build_object(
        'row', v_row_idx, 'reason', 'Ürün adı çok kısa'
      );
      v_skipped := v_skipped + 1;
      continue;
    end if;

    v_description  := coalesce(trim(v_row->>'description'), '');
    v_price_cents  := coalesce((v_row->>'price_cents')::int, 0);
    v_is_available := coalesce((v_row->>'is_available')::bool, true);

    if v_price_cents < 0 then
      v_errors := v_errors || jsonb_build_object(
        'row', v_row_idx, 'reason', 'Fiyat negatif olamaz'
      );
      v_skipped := v_skipped + 1;
      continue;
    end if;

    -- Find or create section
    if v_section_cache ? lower(v_section_name) then
      v_section_id := (v_section_cache->>lower(v_section_name))::uuid;
    else
      v_section_sort := v_section_sort + 1;
      insert into menu_sections (menu_id, title, sort_order)
      values (p_menu_id, v_section_name, v_section_sort)
      returning id into v_section_id;
      v_section_cache := v_section_cache || jsonb_build_object(lower(v_section_name), v_section_id::text);
      v_sections_made := v_sections_made + 1;
    end if;

    -- Insert item
    insert into menu_items
      (section_id, business_id, name, description, price_cents, currency, is_available, sort_order)
    select
      v_section_id,
      v_business_id,
      v_item_name,
      v_description,
      v_price_cents,
      'TRY',
      v_is_available,
      coalesce((select max(sort_order) from menu_items where section_id = v_section_id), -1) + 1;

    v_inserted := v_inserted + 1;
  end loop;

  return jsonb_build_object(
    'ok',               true,
    'inserted',         v_inserted,
    'sections_created', v_sections_made,
    'skipped',          v_skipped,
    'errors',           v_errors
  );
end;
$$;
