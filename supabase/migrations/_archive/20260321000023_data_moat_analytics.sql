create or replace function public.get_business_price_history_v1(
  p_business_id uuid,
  p_days integer default 60,
  p_limit integer default 120
) returns table(
  business_id uuid,
  menu_item_id uuid,
  menu_item_name text,
  price_cents integer,
  changed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    mi.business_id,
    h.menu_item_id,
    mi.name as menu_item_name,
    h.price_cents,
    h.created_at as changed_at
  from public.menu_item_price_history h
  join public.menu_items mi on mi.id = h.menu_item_id
  where mi.business_id = p_business_id
    and h.price_cents is not null
    and h.price_cents > 0
    and h.created_at >= now() - make_interval(days => greatest(p_days, 1))
  order by h.created_at desc
  limit greatest(p_limit, 1);
$$;
grant all on function public.get_business_price_history_v1(uuid, integer, integer) to anon;
grant all on function public.get_business_price_history_v1(uuid, integer, integer) to authenticated;
grant all on function public.get_business_price_history_v1(uuid, integer, integer) to service_role;
create or replace function public.get_regional_price_index_v2(
  p_city text default null,
  p_district text default null,
  p_limit integer default 12
) returns table(
  category text,
  median_price_cents integer,
  avg_price_cents integer,
  sample_count integer,
  updated_in_30d integer
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      b.category,
      mi.price_cents,
      mi.updated_at
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where b.is_active = true
      and mi.price_cents is not null
      and mi.price_cents > 0
      and (p_city is null or b.city = p_city)
      and (p_district is null or b.district = p_district)
  )
  select
    coalesce(category, 'Genel') as category,
    percentile_disc(0.5) within group (order by price_cents)::int as median_price_cents,
    round(avg(price_cents))::int as avg_price_cents,
    count(*)::int as sample_count,
    count(*) filter (where updated_at >= now() - interval '30 days')::int as updated_in_30d
  from base
  group by category
  order by median_price_cents desc nulls last
  limit greatest(p_limit, 1);
$$;
grant all on function public.get_regional_price_index_v2(text, text, integer) to anon;
grant all on function public.get_regional_price_index_v2(text, text, integer) to authenticated;
grant all on function public.get_regional_price_index_v2(text, text, integer) to service_role;
create or replace function public.get_menu_price_anomalies_v1(
  p_city text default null,
  p_district text default null,
  p_days integer default 30,
  p_min_change_pct numeric default 40,
  p_limit integer default 20
) returns table(
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  menu_item_name text,
  city text,
  district text,
  first_price_cents integer,
  last_price_cents integer,
  change_pct numeric,
  last_changed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with hist as (
    select
      b.id as business_id,
      b.name as business_name,
      b.city,
      b.district,
      h.menu_item_id,
      mi.name as menu_item_name,
      h.price_cents,
      h.created_at,
      row_number() over (partition by h.menu_item_id order by h.created_at asc) as rn_first,
      row_number() over (partition by h.menu_item_id order by h.created_at desc) as rn_last
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where h.created_at >= now() - make_interval(days => greatest(p_days, 1))
      and h.price_cents is not null
      and h.price_cents > 0
      and b.is_active = true
      and (p_city is null or b.city = p_city)
      and (p_district is null or b.district = p_district)
  ),
  first_last as (
    select
      business_id,
      business_name,
      city,
      district,
      menu_item_id,
      menu_item_name,
      max(case when rn_first = 1 then price_cents end)::int as first_price_cents,
      max(case when rn_last = 1 then price_cents end)::int as last_price_cents,
      max(case when rn_last = 1 then created_at end) as last_changed_at
    from hist
    group by business_id, business_name, city, district, menu_item_id, menu_item_name
  )
  select
    fl.business_id,
    fl.business_name,
    fl.menu_item_id,
    fl.menu_item_name,
    fl.city,
    fl.district,
    fl.first_price_cents,
    fl.last_price_cents,
    round((((fl.last_price_cents - fl.first_price_cents)::numeric / nullif(fl.first_price_cents, 0)::numeric) * 100), 1) as change_pct,
    fl.last_changed_at
  from first_last fl
  where fl.first_price_cents is not null
    and fl.last_price_cents is not null
    and fl.first_price_cents > 0
    and abs(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100) >= greatest(p_min_change_pct, 1)
  order by abs(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100) desc
  limit greatest(p_limit, 1);
$$;
grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to anon;
grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to authenticated;
grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to service_role;
create or replace function public.admin_export_price_anomalies_csv_v1(
  p_days int default 30,
  p_threshold_pct numeric default 40
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with rows as (
    select *
    from public.get_menu_price_anomalies_v1(
      p_city => null,
      p_district => null,
      p_days => p_days,
      p_min_change_pct => p_threshold_pct,
      p_limit => 5000
    )
  )
  select
    'business_name,city,district,menu_item_name,first_price_cents,last_price_cents,change_pct,last_changed_at' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s,%s,%s',
          replace(coalesce(r.business_name, ''), ',', ' '),
          replace(coalesce(r.city, ''), ',', ' '),
          replace(coalesce(r.district, ''), ',', ' '),
          replace(coalesce(r.menu_item_name, ''), ',', ' '),
          coalesce(r.first_price_cents::text, ''),
          coalesce(r.last_price_cents::text, ''),
          coalesce(r.change_pct::text, ''),
          coalesce(to_char(r.last_changed_at, 'YYYY-MM-DD HH24:MI:SS'), '')
        ),
        E'\n'
      ),
      ''
    )
  into v_csv
  from rows r;

  return v_csv;
end;
$$;
grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to anon;
grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to authenticated;
grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to service_role;
