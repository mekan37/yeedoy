-- Drop legacy menu_categories.sort after full canonical migration to sort_order.
-- Safe order: trigger -> sync function -> legacy index -> legacy column.

do $$
begin
  if exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'menu_categories'
      and t.tgname = 'trg_menu_categories_sync_sort_columns'
      and not t.tgisinternal
  ) then
    execute 'drop trigger trg_menu_categories_sync_sort_columns on public.menu_categories';
  end if;
end $$;
drop function if exists public.menu_categories_sync_sort_columns_v1();
drop index if exists public.idx_menu_categories_business_id;
alter table if exists public.menu_categories
  drop column if exists sort;
