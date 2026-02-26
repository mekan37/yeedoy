-- Price alerts + alert events + trigger

create table if not exists public.price_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  city text null,
  district text null,
  query text not null,
  max_price_cents int not null,
  currency text not null default 'TRY',
  category text null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists price_alerts_user_active_idx
  on public.price_alerts (user_id, is_active);

create table if not exists public.alert_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  alert_id uuid not null references public.price_alerts(id) on delete cascade,
  business_id uuid not null references public.businesses(id),
  menu_item_id uuid null,
  matched_price_cents int not null,
  created_at timestamptz not null default now(),
  created_day date not null default (now()::date)
);

alter table public.alert_events
  add column if not exists created_day date;

update public.alert_events
  set created_day = created_at::date
  where created_day is null;

alter table public.alert_events
  alter column created_day set default (now()::date),
  alter column created_day set not null;

create unique index if not exists alert_events_dedupe_idx
  on public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    created_day
  );

-- RLS
alter table public.price_alerts enable row level security;
alter table public.alert_events enable row level security;

drop policy if exists price_alerts_owner_select on public.price_alerts;
create policy price_alerts_owner_select on public.price_alerts
  for select using (user_id = auth.uid());

drop policy if exists price_alerts_owner_insert on public.price_alerts;
create policy price_alerts_owner_insert on public.price_alerts
  for insert with check (user_id = auth.uid());

drop policy if exists price_alerts_owner_update on public.price_alerts;
create policy price_alerts_owner_update on public.price_alerts
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists price_alerts_owner_delete on public.price_alerts;
create policy price_alerts_owner_delete on public.price_alerts
  for delete using (user_id = auth.uid());

drop policy if exists alert_events_owner_select on public.alert_events;
create policy alert_events_owner_select on public.alert_events
  for select using (user_id = auth.uid());

drop policy if exists alert_events_owner_insert on public.alert_events;
create policy alert_events_owner_insert on public.alert_events
  for insert with check (user_id = auth.uid());

-- alert matching function
create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text
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
    matched_price_cents
  )
  select
    a.user_id,
    a.id,
    p_business_id,
    p_menu_item_id,
    p_price_cents
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

-- trigger: call alerts on verified price changes (history insert)
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

  perform public.check_price_alerts_for_item_v1(
    new.menu_item_id,
    v_business_id,
    v_item_name,
    v_price,
    v_city,
    v_district,
    v_category
  );

  return new;
end;
$$;

drop trigger if exists trg_price_alerts_history on public.menu_item_price_history;
create trigger trg_price_alerts_history
  after insert on public.menu_item_price_history
  for each row execute function public.handle_price_alerts_for_history_v1();

-- RPCs
create or replace function public.create_price_alert_v1(
  p_query text,
  p_max_price_cents int,
  p_city text default null,
  p_district text default null,
  p_currency text default 'TRY',
  p_category text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.price_alerts(
    user_id, city, district, query, max_price_cents, currency, category, is_active
  )
  values (
    auth.uid(), p_city, p_district, p_query, p_max_price_cents, p_currency, p_category, true
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

create or replace function public.list_my_alerts_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  city text,
  district text,
  query text,
  max_price_cents int,
  currency text,
  category text,
  is_active boolean,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.city,
    a.district,
    a.query,
    a.max_price_cents,
    a.currency,
    a.category,
    a.is_active,
    a.created_at
  from public.price_alerts a
  where a.user_id = auth.uid()
  order by a.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.list_my_alert_events_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  alert_id uuid,
  business_id uuid,
  menu_item_id uuid,
  matched_price_cents int,
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
    e.created_at
  from public.alert_events e
  where e.user_id = auth.uid()
  order by e.created_at desc
  limit p_limit offset p_offset;
$$;
