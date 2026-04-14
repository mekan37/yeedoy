begin;

alter table public.menu_categories
  add column if not exists sort_order integer;

update public.menu_categories
set sort_order = coalesce(sort_order, sort, 0)
where sort_order is null;

alter table public.menu_categories
  alter column sort_order set default 0,
  alter column sort_order set not null;

create or replace function public.menu_categories_sync_sort_columns_v1()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.sort_order is null and new.sort is not null then
      new.sort_order := new.sort;
    end if;
    if new.sort is null and new.sort_order is not null then
      new.sort := new.sort_order;
    end if;
    return new;
  end if;

  if new.sort_order is distinct from old.sort_order then
    new.sort := new.sort_order;
  elsif new.sort is distinct from old.sort then
    new.sort_order := new.sort;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_categories_sync_sort_columns on public.menu_categories;
create trigger trg_menu_categories_sync_sort_columns
before insert or update of sort, sort_order on public.menu_categories
for each row execute function public.menu_categories_sync_sort_columns_v1();

create index if not exists idx_menu_categories_business_id_sort_order
  on public.menu_categories (business_id, sort_order);

comment on column public.menu_categories.sort is 'DEPRECATED: replaced by sort_order';

commit;;
