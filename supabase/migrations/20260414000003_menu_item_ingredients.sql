-- ─────────────────────────────────────────────────────────────────────────────
-- menu_item_ingredients + menu_item_diet_tags
-- AI-detected ingredient list and derived diet/lifestyle tags per menu item.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Ingredient list ───────────────────────────────────────────────────────────

create table if not exists public.menu_item_ingredients (
  item_id     uuid    not null references public.menu_items(id) on delete cascade,
  name        text    not null,
  confidence  text    not null default 'certain'
              check (confidence in ('certain', 'likely', 'uncertain')),
  category    text    not null default 'other'
              check (category in (
                'meat','poultry','seafood','dairy','egg',
                'vegetable','fruit','grain','legume',
                'fat_oil','spice','sauce','nut','other'
              )),
  sort_order  int     not null default 0,
  primary key (item_id, name)
);

create index if not exists idx_menu_item_ingredients_item
  on public.menu_item_ingredients (item_id);

-- ── Diet / lifestyle summary tags ─────────────────────────────────────────────

create table if not exists public.menu_item_diet_tags (
  item_id        uuid primary key references public.menu_items(id) on delete cascade,
  is_vegan       bool,       -- null = uncertain
  is_vegetarian  bool,
  is_gluten_free bool,
  is_dairy_free  bool,
  detected_by    text not null default 'ai'
                 check (detected_by in ('ai', 'manual')),
  updated_at     timestamptz not null default now()
);

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table public.menu_item_ingredients enable row level security;
alter table public.menu_item_diet_tags   enable row level security;

drop policy if exists "public_read_ingredients" on public.menu_item_ingredients;
create policy "public_read_ingredients"
  on public.menu_item_ingredients for select using (true);

drop policy if exists "public_read_diet_tags" on public.menu_item_diet_tags;
create policy "public_read_diet_tags"
  on public.menu_item_diet_tags for select using (true);

-- ── RPC: owner_upsert_menu_item_ingredients_v1 ───────────────────────────────
-- Atomically replaces ingredient list + diet tags for an item.
-- p_ingredients: [{"name":"...", "confidence":"certain","category":"legume","sort_order":0}, ...]
-- p_diet:        {"is_vegan":false,"is_vegetarian":true,"is_gluten_free":true,"is_dairy_free":false}

create or replace function public.owner_upsert_menu_item_ingredients_v1(
  p_item_id     uuid,
  p_ingredients jsonb,
  p_diet        jsonb,
  p_detected_by text default 'ai'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_entry       jsonb;
  v_idx         int := 0;
begin
  -- Ownership check
  select m.business_id into v_business_id
  from menu_items mi
  join menu_sections ms on ms.id = mi.section_id
  join menus m          on m.id  = ms.menu_id
  where mi.id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'item_not_found');
  end if;

  if not exists (
    select 1 from owner_claims
    where business_id = v_business_id
      and user_id     = auth.uid()
      and status      = 'approved'
  ) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  -- Replace ingredients
  delete from menu_item_ingredients where item_id = p_item_id;

  for v_entry in select * from jsonb_array_elements(p_ingredients)
  loop
    insert into menu_item_ingredients
      (item_id, name, confidence, category, sort_order)
    values (
      p_item_id,
      v_entry->>'name',
      coalesce(v_entry->>'confidence', 'certain'),
      coalesce(v_entry->>'category', 'other'),
      v_idx
    );
    v_idx := v_idx + 1;
  end loop;

  -- Upsert diet tags
  insert into menu_item_diet_tags
    (item_id, is_vegan, is_vegetarian, is_gluten_free, is_dairy_free, detected_by, updated_at)
  values (
    p_item_id,
    (p_diet->>'is_vegan')::bool,
    (p_diet->>'is_vegetarian')::bool,
    (p_diet->>'is_gluten_free')::bool,
    (p_diet->>'is_dairy_free')::bool,
    p_detected_by,
    now()
  )
  on conflict (item_id) do update set
    is_vegan       = excluded.is_vegan,
    is_vegetarian  = excluded.is_vegetarian,
    is_gluten_free = excluded.is_gluten_free,
    is_dairy_free  = excluded.is_dairy_free,
    detected_by    = excluded.detected_by,
    updated_at     = now();

  return jsonb_build_object('ok', true);
end;
$$;
