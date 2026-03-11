alter table public.businesses
  add column if not exists reservation_url text,
  add column if not exists order_yemeksepeti_url text,
  add column if not exists order_trendyolgo_url text,
  add column if not exists order_getir_url text;
alter table public.analytics_events
  drop constraint if exists analytics_events_event_name_check;
alter table public.analytics_events
  add constraint analytics_events_event_name_check
  check (
    event_name = any (
      array[
        'menu_shared'::text,
        'qr_scanned'::text,
        'menu_link_opened'::text,
        'app_install_from_menu'::text,
        'business_reservation_click'::text,
        'business_order_click'::text,
        'business_whatsapp_click'::text,
        'business_phone_click'::text
      ]
    )
  );
create or replace function public.log_event_v1(
  p_event_name text,
  p_business_id uuid default null,
  p_menu_id uuid default null,
  p_source text default null,
  p_client_id text default null,
  p_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_name text := coalesce(trim(p_event_name), '');
  v_client text := nullif(trim(p_client_id), '');
  v_key text;
  v_today date := current_date;
  v_current_count int;
  v_user_id uuid := coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if v_event_name not in (
    'menu_shared',
    'qr_scanned',
    'menu_link_opened',
    'app_install_from_menu',
    'business_reservation_click',
    'business_order_click',
    'business_whatsapp_click',
    'business_phone_click'
  ) then
    return jsonb_build_object('ok', false, 'code', 'invalid_event');
  end if;

  if v_event_name = 'menu_link_opened' and v_client is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if v_event_name = 'menu_link_opened' then
    v_key := format('menu_link_opened:%s:%s', v_client, v_today::text);
    select count into v_current_count
    from public.user_rate_limits
    where key = v_key;

    if coalesce(v_current_count, 0) >= 200 then
      return jsonb_build_object('ok', false, 'code', 'rate_limited');
    end if;

    insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
    values (v_key, v_user_id, 'menu_link_opened', v_today, 1, now())
    on conflict (key) do update
      set count = public.user_rate_limits.count + 1,
          updated_at = now();
  end if;

  insert into public.analytics_events (
    event_name,
    business_id,
    menu_id,
    source,
    client_id,
    user_id,
    meta
  ) values (
    v_event_name,
    p_business_id,
    p_menu_id,
    p_source,
    v_client,
    auth.uid(),
    coalesce(p_meta, '{}'::jsonb)
  );

  return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.analytics_growth_v2(
  p_days integer default 30,
  p_business_id uuid default null
)
returns table(
  day date,
  menu_link_opened integer,
  qr_scanned integer,
  menu_shared integer,
  app_install_from_menu integer,
  business_reservation_click integer,
  business_order_click integer,
  business_whatsapp_click integer,
  business_phone_click integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  return query
  select
    d.day::date,
    sum(case when e.event_name = 'menu_link_opened' then 1 else 0 end)::int as menu_link_opened,
    sum(case when e.event_name = 'qr_scanned' then 1 else 0 end)::int as qr_scanned,
    sum(case when e.event_name = 'menu_shared' then 1 else 0 end)::int as menu_shared,
    sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu,
    sum(case when e.event_name = 'business_reservation_click' then 1 else 0 end)::int as business_reservation_click,
    sum(case when e.event_name = 'business_order_click' then 1 else 0 end)::int as business_order_click,
    sum(case when e.event_name = 'business_whatsapp_click' then 1 else 0 end)::int as business_whatsapp_click,
    sum(case when e.event_name = 'business_phone_click' then 1 else 0 end)::int as business_phone_click
  from generate_series(
    (current_date - greatest(p_days, 1) + 1)::date,
    current_date::date,
    interval '1 day'
  ) as d(day)
  left join public.analytics_events e
    on date_trunc('day', e.created_at) = d.day
   and (p_business_id is null or e.business_id = p_business_id)
  group by d.day
  order by d.day;
end;
$$;
grant all on function public.analytics_growth_v2(integer, uuid) to anon;
grant all on function public.analytics_growth_v2(integer, uuid) to authenticated;
grant all on function public.analytics_growth_v2(integer, uuid) to service_role;
create or replace function public.owner_update_business_commerce_links_v1(
  p_business_id uuid,
  p_reservation_url text default null,
  p_order_yemeksepeti_url text default null,
  p_order_trendyolgo_url text default null,
  p_order_getir_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_authorized');
  end if;

  update public.businesses
  set
    reservation_url = nullif(trim(coalesce(p_reservation_url, '')), ''),
    order_yemeksepeti_url = nullif(trim(coalesce(p_order_yemeksepeti_url, '')), ''),
    order_trendyolgo_url = nullif(trim(coalesce(p_order_trendyolgo_url, '')), ''),
    order_getir_url = nullif(trim(coalesce(p_order_getir_url, '')), ''),
    updated_at = now()
  where id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$$;
grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to anon;
grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to authenticated;
grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to service_role;
