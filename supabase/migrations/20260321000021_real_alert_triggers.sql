-- Real alert trigger hardening: favorites only, meaningful delta, verified changes.

create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text,
  p_previous_price_cents int default null,
  p_district_avg_price_cents int default null,
  p_is_verified_change boolean default true
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if coalesce(p_is_verified_change, false) is false then
    return;
  end if;

  -- Ignore noisy updates unless there is at least 10% delta.
  if p_previous_price_cents is not null
     and p_previous_price_cents > 0
     and p_price_cents > 0
     and abs(p_price_cents - p_previous_price_cents)::numeric / p_previous_price_cents::numeric < 0.10
  then
    return;
  end if;

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
    and exists (
      select 1
      from public.favorites f
      where f.user_id = a.user_id
        and f.business_id = p_business_id
    )
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
  v_is_verified_change boolean := false;
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

  -- Verified change rule: trusted source OR an approved suggestion close to this update.
  v_is_verified_change := coalesce(new.source, '') in ('verified', 'admin', 'owner')
    or exists (
      select 1
      from public.menu_item_price_suggestions s
      where s.menu_item_id = new.menu_item_id
        and s.suggested_price_cents = v_price
        and s.status::text = any(array['approved', 'accepted', 'handled', 'verified'])
        and s.created_at >= new.created_at - interval '24 hours'
    );

  if v_is_verified_change is false then
    return new;
  end if;

  if v_prev_price is not null
     and v_prev_price > 0
     and abs(v_price - v_prev_price)::numeric / v_prev_price::numeric < 0.10
  then
    return new;
  end if;

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
    v_district_avg,
    v_is_verified_change
  );

  return new;
end;
$$;

create or replace function public.trg_notify_price_alert_event_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_item_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  select mi.name into v_item_name
  from public.menu_items mi
  where mi.id = new.menu_item_id;

  perform public.notify_user_v1(
    new.user_id,
    'favorite_price_changed',
    '⚠️ Fiyat değişimi',
    coalesce(v_business_name, 'İşletme') || ' mekanında ' || coalesce(v_item_name, 'ürün') || ' fiyatı değişti.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'alert_event_id', new.id,
      'matched_price_cents', new.matched_price_cents,
      'previous_price_cents', new.previous_price_cents,
      'district_avg_price_cents', new.district_avg_price_cents,
      'meaningful_change', true,
      'verified_change', true
    )
  );

  return new;
end;
$$;
