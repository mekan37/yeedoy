-- Multi-menu roadmap phase-1:
-- 1) Product-level variants (size/gramaj/portion)
-- 2) Owner edits on menu_items price are persisted into price history

create table if not exists public.menu_item_variants (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  label text not null,
  price_cents integer not null check (price_cents >= 0),
  currency text not null default 'TRY',
  is_default boolean not null default false,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_menu_item_variants_item_sort
  on public.menu_item_variants (menu_item_id, sort_order, created_at);

create unique index if not exists uq_menu_item_variants_default_per_item
  on public.menu_item_variants (menu_item_id)
  where is_default = true;

alter table public.menu_item_variants enable row level security;

drop policy if exists menu_item_variants_owner_all on public.menu_item_variants;
create policy menu_item_variants_owner_all
on public.menu_item_variants
for all
to authenticated
using (
  is_admin()
  or exists (
    select 1
    from public.menu_items mi
    where mi.id = menu_item_variants.menu_item_id
      and is_owner_of_business(mi.business_id)
  )
)
with check (
  is_admin()
  or exists (
    select 1
    from public.menu_items mi
    where mi.id = menu_item_variants.menu_item_id
      and is_owner_of_business(mi.business_id)
  )
);

drop policy if exists menu_item_variants_public_read on public.menu_item_variants;
create policy menu_item_variants_public_read
on public.menu_item_variants
for select
to public
using (
  is_available = true
  and exists (
    select 1
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.id = menu_item_variants.menu_item_id
      and b.is_active = true
  )
);

create or replace function public.get_menu_item_variants_v1(
  p_menu_item_id uuid
)
returns table (
  id uuid,
  menu_item_id uuid,
  label text,
  price_cents integer,
  currency text,
  is_default boolean,
  is_available boolean,
  sort_order integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.id,
    v.menu_item_id,
    v.label,
    v.price_cents,
    v.currency,
    v.is_default,
    v.is_available,
    v.sort_order
  from public.menu_item_variants v
  where v.menu_item_id = p_menu_item_id
  order by v.sort_order asc, v.created_at asc;
$$;

grant all on function public.get_menu_item_variants_v1(uuid) to anon;
grant all on function public.get_menu_item_variants_v1(uuid) to authenticated;
grant all on function public.get_menu_item_variants_v1(uuid) to service_role;

create or replace function public.trg_menu_items_owner_price_history_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (
       coalesce(new.price_cents, -1) <> coalesce(old.price_cents, -1)
       or coalesce(new.currency, '') <> coalesce(old.currency, '')
     )
  then
    insert into public.menu_item_price_history (
      menu_item_id,
      price_cents,
      currency,
      source,
      created_by
    )
    values (
      new.id,
      new.price_cents,
      coalesce(new.currency, 'TRY'),
      'owner_edit',
      auth.uid()
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_menu_items_owner_price_history_v1 on public.menu_items;
create trigger trg_menu_items_owner_price_history_v1
after update of price_cents, currency on public.menu_items
for each row
execute function public.trg_menu_items_owner_price_history_v1();
