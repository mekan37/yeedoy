-- Extend price alert events with previous price + district average context.

alter table public.alert_events
  add column if not exists previous_price_cents int,
  add column if not exists district_avg_price_cents int;
create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text,
  p_previous_price_cents int default null,
  p_district_avg_price_cents int default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    matched_price_cents,
    previous_price_cents,
    district_avg_price_cents
  )
  select
    a.user_id,
    a.id,
    p_business_id,
    p_menu_item_id,
    p_price_cents,
    p_previous_price_cents,
    p_district_avg_price_cents
  from public.price_alerts a
  where a.is_active = true
    and (a.query is null or a.query = '' or p_item_name ilike '%' || a.query || '%')
    and (a.max_price_cents is null or p_price_cents <= a.max_price_cents)
    and (a.city is null or a.city = '' or a.city = p_city)
    and (a.district is null or a.district = '' or a.district = p_district)
    and (a.category is null or a.category = '' or a.category = p_category)
  on conflict do nothing;
end;
$$;
create or replace function public.handle_price_alerts_for_history_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item_name text;
  v_business_id uuid;
  v_city text;
  v_district text;
  v_category text;
  v_price int;
  v_prev_price int;
  v_district_avg int;
begin
  if coalesce(new.source, '') not in ('suggestion', 'owner', 'admin', 'verified') then
    return new;
  end if;

  select mi.name, mi.business_id, b.city, b.district, b.category
    into v_item_name, v_business_id, v_city, v_district, v_category
  from public.menu_items mi
  join public.businesses b on b.id = mi.business_id
  where mi.id = new.menu_item_id;

  v_price := coalesce(new.new_price_cents, new.price_cents);
  if v_item_name is null or v_business_id is null or v_price is null then
    return new;
  end if;

  select h.price_cents
    into v_prev_price
  from public.menu_item_price_history h
  where h.menu_item_id = new.menu_item_id
    and h.created_at < new.created_at
  order by h.created_at desc
  limit 1;

  if coalesce(v_district, '') <> '' then
    select avg(h.price_cents)::int
      into v_district_avg
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where lower(mi.name) = lower(v_item_name)
      and b.district = v_district
      and h.created_at >= now() - interval '30 days'
      and h.price_cents is not null;
  end if;

  perform public.check_price_alerts_for_item_v1(
    new.menu_item_id,
    v_business_id,
    v_item_name,
    v_price,
    v_city,
    v_district,
    v_category,
    v_prev_price,
    v_district_avg
  );

  return new;
end;
$$;
drop function if exists public.list_my_alert_events_v1(int, int);
create function public.list_my_alert_events_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  alert_id uuid,
  business_id uuid,
  menu_item_id uuid,
  matched_price_cents int,
  previous_price_cents int,
  district_avg_price_cents int,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    e.id,
    e.alert_id,
    e.business_id,
    e.menu_item_id,
    e.matched_price_cents,
    e.previous_price_cents,
    e.district_avg_price_cents,
    e.created_at
  from public.alert_events e
  where e.user_id = auth.uid()
  order by e.created_at desc
  limit p_limit offset p_offset;
$$;
