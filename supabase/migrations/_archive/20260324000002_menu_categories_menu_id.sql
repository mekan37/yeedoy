-- Bind QR categories to a concrete menu so one business can host multiple menus.

alter table public.menu_categories
  add column if not exists menu_id uuid references public.menus(id) on delete cascade;

-- Backfill existing rows: attach each category to latest non-archived menu of same business.
with latest_menu as (
  select distinct on (m.business_id)
    m.business_id,
    m.id as menu_id
  from public.menus m
  where m.status <> 'archived'
  order by m.business_id, m.updated_at desc, m.created_at desc
)
update public.menu_categories c
set menu_id = lm.menu_id
from latest_menu lm
where c.menu_id is null
  and c.business_id = lm.business_id;

create index if not exists idx_menu_categories_menu_id_sort_order
  on public.menu_categories (menu_id, sort_order);
