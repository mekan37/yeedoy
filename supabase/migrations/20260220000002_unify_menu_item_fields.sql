-- Canonical menu item schema alignment (phase 1 / non-breaking).
-- Target canonical fields:
-- id, business_id, name, description, price_cents, currency, tags, image_url,
-- is_available, sort_order, created_at, updated_at

begin;

alter table public.menu_items
  add column if not exists sort_order integer;

update public.menu_items
set sort_order = coalesce(sort_order, 0)
where sort_order is null;

alter table public.menu_items
  alter column sort_order set default 0,
  alter column sort_order set not null;

update public.menu_items
set price_cents = 0
where price_cents is null or price_cents < 0;

alter table public.menu_items
  alter column price_cents set default 0,
  alter column price_cents set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menu_items_price_cents_nonnegative_ck'
  ) then
    alter table public.menu_items
      add constraint menu_items_price_cents_nonnegative_ck
      check (price_cents >= 0);
  end if;
end $$;

update public.menu_items
set currency = 'TRY'
where currency is null or btrim(currency) = '';

alter table public.menu_items
  alter column currency set default 'TRY',
  alter column currency set not null;

update public.menu_items
set is_available = true
where is_available is null;

alter table public.menu_items
  alter column is_available set default true,
  alter column is_available set not null;

update public.menu_items
set tags = '[]'::jsonb
where tags is null or jsonb_typeof(tags) <> 'array';

alter table public.menu_items
  alter column tags set default '[]'::jsonb,
  alter column tags set not null;

insert into public.menu_categories (business_id, sort_order, is_active)
select distinct i.business_id, 0, true
from public.menu_items i
where i.category_id is null
  and not exists (
    select 1
    from public.menu_categories c
    where c.business_id = i.business_id
  );

insert into public.menu_translations (entity_type, entity_id, locale, name, description)
select
  'category'::public.translation_entity_type,
  c.id,
  'tr',
  'Genel',
  null
from public.menu_categories c
where not exists (
  select 1
  from public.menu_translations t
  where t.entity_type = 'category'
    and t.entity_id = c.id
    and t.locale = 'tr'
);

update public.menu_items i
set category_id = (
  select c2.id
  from public.menu_categories c2
  where c2.business_id = i.business_id
  order by c2.sort_order asc, c2.created_at asc
  limit 1
)
where i.category_id is null;

create index if not exists idx_menu_items_business_category_sort_order
  on public.menu_items (business_id, category_id, sort_order);

commit;
