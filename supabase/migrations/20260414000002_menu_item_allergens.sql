-- ─────────────────────────────────────────────────────────────────────────────
-- menu_item_allergens
-- Stores the 14 EU allergens for each menu item (contains / may_contain).
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.menu_item_allergens (
  item_id      uuid    not null references public.menu_items(id) on delete cascade,
  allergen     text    not null,          -- AllergenType.code
  risk_level   text    not null default 'contains'
               check (risk_level in ('contains', 'may_contain')),
  detected_by  text    not null default 'manual'
               check (detected_by in ('ai', 'manual')),
  updated_at   timestamptz not null default now(),
  primary key (item_id, allergen)
);

-- index for fast per-item lookups
create index if not exists idx_menu_item_allergens_item
  on public.menu_item_allergens (item_id);

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table public.menu_item_allergens enable row level security;

-- Public read (customers can see allergen info on shared menus)
drop policy if exists "public_read_allergens" on public.menu_item_allergens;
create policy "public_read_allergens"
  on public.menu_item_allergens
  for select
  using (true);

-- Owner read: must own the business that owns the menu item
drop policy if exists "owner_read_allergens" on public.menu_item_allergens;
create policy "owner_read_allergens"
  on public.menu_item_allergens
  for select
  using (
    exists (
      select 1
      from public.menu_items mi
      join public.menu_sections ms on ms.id = mi.section_id
      join public.menus m          on m.id  = ms.menu_id
      join public.owner_claims oc  on oc.business_id = m.business_id
      where mi.id = item_id
        and oc.user_id = auth.uid()
        and oc.status  = 'approved'
    )
  );

-- ── RPC: owner_upsert_menu_item_allergens_v1 ─────────────────────────────────
-- Replaces all allergens for the given item in a single atomic call.
-- p_allergens: [{"allergen": "gluten", "risk_level": "contains", "detected_by": "ai"}, ...]

create or replace function public.owner_upsert_menu_item_allergens_v1(
  p_item_id    uuid,
  p_allergens  jsonb  -- array of {allergen, risk_level, detected_by}
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_entry       jsonb;
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

  -- Full replace: delete existing then insert fresh
  delete from menu_item_allergens where item_id = p_item_id;

  for v_entry in select * from jsonb_array_elements(p_allergens)
  loop
    insert into menu_item_allergens (item_id, allergen, risk_level, detected_by, updated_at)
    values (
      p_item_id,
      v_entry->>'allergen',
      coalesce(v_entry->>'risk_level', 'contains'),
      coalesce(v_entry->>'detected_by', 'manual'),
      now()
    );
  end loop;

  return jsonb_build_object('ok', true);
end;
$$;
