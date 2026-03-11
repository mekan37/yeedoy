create or replace function public.get_chain_overview_v2(
  p_chain_id uuid,
  p_lat double precision default null,
  p_lng double precision default null,
  p_limit integer default 20
) returns table(
  chain_id uuid,
  chain_name text,
  chain_description text,
  business_id uuid,
  business_name text,
  branch_label text,
  city text,
  district text,
  address text,
  is_open_now boolean,
  distance_km double precision,
  avg_price_cents integer,
  chain_avg_price_cents integer,
  price_delta_pct numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with branch_prices as (
    select
      b.id as business_id,
      percentile_disc(0.5) within group (order by mi.price_cents)::int as avg_price_cents
    from public.businesses b
    left join public.menu_items mi
      on mi.business_id = b.id
     and mi.price_cents is not null
     and mi.price_cents > 0
    where b.chain_id = p_chain_id
      and b.is_active = true
    group by b.id
  ),
  chain_price as (
    select
      percentile_disc(0.5) within group (order by bp.avg_price_cents)::int as chain_avg_price_cents
    from branch_prices bp
    where bp.avg_price_cents is not null
  )
  select
    ch.id as chain_id,
    ch.name as chain_name,
    ch.description as chain_description,
    b.id as business_id,
    b.name as business_name,
    coalesce(b.branch_label, '') as branch_label,
    b.city,
    b.district,
    b.address,
    null::boolean as is_open_now,
    case
      when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
      else round((st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      ) / 1000.0)::numeric, 2)::double precision
    end as distance_km,
    bp.avg_price_cents,
    cp.chain_avg_price_cents,
    case
      when cp.chain_avg_price_cents is null or cp.chain_avg_price_cents <= 0 or bp.avg_price_cents is null
        then null
      else round((((bp.avg_price_cents - cp.chain_avg_price_cents)::numeric / cp.chain_avg_price_cents::numeric) * 100), 1)
    end as price_delta_pct
  from public.businesses b
  join public.chains ch on ch.id = b.chain_id
  left join branch_prices bp on bp.business_id = b.id
  left join chain_price cp on true
  where b.chain_id = p_chain_id
    and b.is_active = true
  order by
    case when p_lat is null or p_lng is null then null else
      st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      )
    end asc nulls last,
    b.name asc
  limit greatest(p_limit, 1);
$$;
grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to anon;
grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to authenticated;
grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to service_role;
create or replace function public.analytics_growth_v3(
  p_days integer default 30,
  p_business_id uuid default null
) returns table(
  day date,
  menu_link_opened integer,
  qr_scanned integer,
  menu_shared integer,
  app_install_from_menu integer,
  business_reservation_click integer,
  business_order_click integer,
  business_whatsapp_click integer,
  business_phone_click integer,
  price_dropoff_estimate integer,
  district_price_gap_pct numeric,
  district_price_position text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if p_business_id is null or not public.is_owner_of_business(p_business_id) then
      raise exception 'not authorized';
    end if;
  end if;

  return query
  with events as (
    select
      d.day::date as day,
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
  ),
  business_ctx as (
    select
      b.id,
      b.city,
      b.district
    from public.businesses b
    where b.id = p_business_id
    limit 1
  ),
  business_price as (
    select percentile_disc(0.5) within group (order by mi.price_cents)::numeric as median_price_cents
    from public.menu_items mi
    where mi.business_id = p_business_id
      and mi.price_cents is not null
      and mi.price_cents > 0
  ),
  district_price as (
    select percentile_disc(0.5) within group (order by mi.price_cents)::numeric as median_price_cents
    from business_ctx bc
    join public.businesses b on b.city = bc.city and b.district = bc.district and b.is_active = true
    join public.menu_items mi on mi.business_id = b.id
    where mi.price_cents is not null
      and mi.price_cents > 0
  ),
  gap as (
    select
      case
        when bp.median_price_cents is null or dp.median_price_cents is null or dp.median_price_cents <= 0
          then null
        else round((((bp.median_price_cents - dp.median_price_cents) / dp.median_price_cents) * 100)::numeric, 1)
      end as district_price_gap_pct
    from business_price bp
    cross join district_price dp
  )
  select
    e.day,
    e.menu_link_opened,
    e.qr_scanned,
    e.menu_shared,
    e.app_install_from_menu,
    e.business_reservation_click,
    e.business_order_click,
    e.business_whatsapp_click,
    e.business_phone_click,
    greatest(
      0,
      round(
        greatest(
          0,
          e.menu_link_opened - (
            e.business_reservation_click +
            e.business_order_click +
            e.business_whatsapp_click +
            e.business_phone_click
          )
        ) * case
          when gap.district_price_gap_pct is null then 0.10
          when gap.district_price_gap_pct <= 0 then 0.08
          else least(0.65, gap.district_price_gap_pct / 100.0)
        end
      )::int
    ) as price_dropoff_estimate,
    gap.district_price_gap_pct,
    case
      when gap.district_price_gap_pct is null then 'unknown'
      when gap.district_price_gap_pct >= 8 then 'higher'
      when gap.district_price_gap_pct <= -8 then 'lower'
      else 'similar'
    end as district_price_position
  from events e
  left join gap on true
  order by e.day;
end;
$$;
grant all on function public.analytics_growth_v3(integer, uuid) to anon;
grant all on function public.analytics_growth_v3(integer, uuid) to authenticated;
grant all on function public.analytics_growth_v3(integer, uuid) to service_role;
