-- add new_item to feed_events type check
DO $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events drop constraint feed_events_type_check;
  end if;
  alter table public.feed_events
    add constraint feed_events_type_check
    check (type in ('menu_update','story_posted','price_verified','sponsored','new_item'));
end $$;

create or replace function public.handle_menu_item_new_feed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.status = 'published' then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (
      new.business_id,
      'new_item',
      new.id,
      jsonb_build_object(
        'title', 'Yeni urun eklendi',
        'item_name', new.name,
        'price_cents', new.price_cents,
        'currency', new.currency
      )
    );
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_menu_items_new_feed on public.menu_items;
create trigger trg_menu_items_new_feed
after insert on public.menu_items
for each row
execute function public.handle_menu_item_new_feed();

create or replace function public.get_business_new_items_v1(
  p_business_id uuid,
  p_limit int default 6
)
returns table(
  menu_item_id uuid,
  item_name text,
  price_cents int,
  currency text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents,
    mi.currency,
    mi.created_at
  from public.menu_items mi
  where mi.business_id = p_business_id
    and mi.status = 'published'
    and mi.created_at >= now() - interval '7 days'
  order by mi.created_at desc
  limit p_limit;
$$;
