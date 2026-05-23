-- ─────────────────────────────────────────────────────────────────────────────
-- menu_item_variant_groups + menu_item_variant_options
-- Rich variant system: unlimited groups per item, unlimited options per group.
-- Categories: portion | sauce | extra | doneness | custom
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.menu_item_variant_groups (
  id          uuid    primary key default gen_random_uuid(),
  item_id     uuid    not null references public.menu_items(id) on delete cascade,
  name        text    not null,
  group_type  text    not null default 'custom'
              check (group_type in ('portion','sauce','extra','doneness','custom')),
  selection   text    not null default 'single'
              check (selection in ('single','multiple')),
  is_required bool    not null default false,
  sort_order  int     not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists idx_variant_groups_item
  on public.menu_item_variant_groups (item_id, sort_order);

create table if not exists public.menu_item_variant_options (
  id                   uuid    primary key default gen_random_uuid(),
  group_id             uuid    not null
                       references public.menu_item_variant_groups(id) on delete cascade,
  label                text    not null,
  price_modifier_cents int     not null default 0,  -- signed: +add / -discount / 0 free
  is_default           bool    not null default false,
  is_available         bool    not null default true,
  sort_order           int     not null default 0,
  created_at           timestamptz not null default now()
);

create index if not exists idx_variant_options_group
  on public.menu_item_variant_options (group_id, sort_order);

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table public.menu_item_variant_groups  enable row level security;
alter table public.menu_item_variant_options enable row level security;

drop policy if exists "public_read_variant_groups" on public.menu_item_variant_groups;
create policy "public_read_variant_groups"
  on public.menu_item_variant_groups for select using (true);

drop policy if exists "public_read_variant_options" on public.menu_item_variant_options;
create policy "public_read_variant_options"
  on public.menu_item_variant_options for select using (true);

-- ── Ownership helper ─────────────────────────────────────────────────────────

create or replace function public._variant_item_owner_check(p_item_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from menu_items mi
    join menu_sections ms on ms.id = mi.section_id
    join menus m          on m.id  = ms.menu_id
    join owner_claims oc  on oc.business_id = m.business_id
    where mi.id   = p_item_id
      and oc.user_id = auth.uid()
      and oc.status  = 'approved'
  );
$$;

-- ── RPC: upsert group ────────────────────────────────────────────────────────

create or replace function public.owner_upsert_variant_group_v1(
  p_item_id    uuid,
  p_group_id   uuid    default null,   -- null = create new
  p_name       text    default '',
  p_group_type text    default 'custom',
  p_selection  text    default 'single',
  p_is_required bool   default false,
  p_sort_order int     default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not _variant_item_owner_check(p_item_id) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  if p_group_id is not null then
    update menu_item_variant_groups set
      name        = p_name,
      group_type  = p_group_type,
      selection   = p_selection,
      is_required = p_is_required,
      sort_order  = p_sort_order
    where id = p_group_id and item_id = p_item_id
    returning id into v_id;
  else
    insert into menu_item_variant_groups
      (item_id, name, group_type, selection, is_required, sort_order)
    values
      (p_item_id, p_name, p_group_type, p_selection, p_is_required, p_sort_order)
    returning id into v_id;
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

-- ── RPC: delete group (cascades options) ─────────────────────────────────────

create or replace function public.owner_delete_variant_group_v1(
  p_group_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item_id uuid;
begin
  select item_id into v_item_id
  from menu_item_variant_groups where id = p_group_id;

  if v_item_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if not _variant_item_owner_check(v_item_id) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  delete from menu_item_variant_groups where id = p_group_id;
  return jsonb_build_object('ok', true);
end;
$$;

-- ── RPC: upsert option ───────────────────────────────────────────────────────

create or replace function public.owner_upsert_variant_option_v1(
  p_group_id             uuid,
  p_option_id            uuid    default null,
  p_label                text    default '',
  p_price_modifier_cents int     default 0,
  p_is_default           bool    default false,
  p_is_available         bool    default true,
  p_sort_order           int     default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item_id uuid;
  v_id      uuid;
begin
  select item_id into v_item_id
  from menu_item_variant_groups where id = p_group_id;

  if v_item_id is null then
    return jsonb_build_object('ok', false, 'error', 'group_not_found');
  end if;

  if not _variant_item_owner_check(v_item_id) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  -- If new default, clear existing defaults in group (single-select groups)
  if p_is_default then
    update menu_item_variant_options
    set is_default = false
    where group_id = p_group_id;
  end if;

  if p_option_id is not null then
    update menu_item_variant_options set
      label                = p_label,
      price_modifier_cents = p_price_modifier_cents,
      is_default           = p_is_default,
      is_available         = p_is_available,
      sort_order           = p_sort_order
    where id = p_option_id and group_id = p_group_id
    returning id into v_id;
  else
    insert into menu_item_variant_options
      (group_id, label, price_modifier_cents, is_default, is_available, sort_order)
    values
      (p_group_id, p_label, p_price_modifier_cents, p_is_default, p_is_available, p_sort_order)
    returning id into v_id;
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

-- ── RPC: delete option ───────────────────────────────────────────────────────

create or replace function public.owner_delete_variant_option_v1(
  p_option_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item_id uuid;
  v_group_id uuid;
begin
  select g.item_id, o.group_id
  into v_item_id, v_group_id
  from menu_item_variant_options o
  join menu_item_variant_groups  g on g.id = o.group_id
  where o.id = p_option_id;

  if v_item_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if not _variant_item_owner_check(v_item_id) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  delete from menu_item_variant_options where id = p_option_id;
  return jsonb_build_object('ok', true);
end;
$$;
