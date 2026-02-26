create or replace function public.admin_export_anonymous_trends_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with rows as (
    select
      to_char(date_trunc('day', e.created_at), 'YYYY-MM-DD') as day,
      coalesce(b.city, '-') as city,
      coalesce(b.district, '-') as district,
      e.event_name,
      count(*)::int as event_count
    from public.analytics_events e
    left join public.businesses b on b.id = e.business_id
    where e.created_at >= now() - make_interval(days => greatest(p_days, 1))
    group by 1, 2, 3, 4
    order by 1 desc, 2, 3, 4
  )
  select
    'day,city,district,event_name,event_count' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s',
          r.day,
          replace(r.city, ',', ' '),
          replace(r.district, ',', ' '),
          replace(r.event_name, ',', ' '),
          r.event_count::text
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

create or replace function public.admin_export_regional_price_index_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with current_window as (
    select
      b.city,
      b.district,
      avg(mi.price_cents)::numeric as avg_price_cents,
      percentile_cont(0.5) within group (order by mi.price_cents)::numeric as median_price_cents,
      count(*)::int as item_count
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.price_cents is not null
      and mi.price_cents > 0
      and mi.updated_at >= now() - make_interval(days => greatest(p_days, 1))
    group by b.city, b.district
  ),
  previous_window as (
    select
      b.city,
      b.district,
      avg(mi.price_cents)::numeric as prev_avg_price_cents
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.price_cents is not null
      and mi.price_cents > 0
      and mi.updated_at >= now() - make_interval(days => greatest(p_days * 2, 2))
      and mi.updated_at < now() - make_interval(days => greatest(p_days, 1))
    group by b.city, b.district
  ),
  rows as (
    select
      coalesce(c.city, '-') as city,
      coalesce(c.district, '-') as district,
      round(c.avg_price_cents)::int as avg_price_cents,
      round(c.median_price_cents)::int as median_price_cents,
      c.item_count,
      case
        when p.prev_avg_price_cents is null or p.prev_avg_price_cents = 0 then null
        else round(((c.avg_price_cents - p.prev_avg_price_cents) / p.prev_avg_price_cents) * 100.0, 2)
      end as change_pct
    from current_window c
    left join previous_window p
      on p.city = c.city and p.district = c.district
    order by c.avg_price_cents desc nulls last
  )
  select
    'city,district,avg_price_cents,median_price_cents,item_count,change_pct' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s',
          replace(r.city, ',', ' '),
          replace(r.district, ',', ' '),
          r.avg_price_cents::text,
          r.median_price_cents::text,
          r.item_count::text,
          coalesce(r.change_pct::text, '')
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

create or replace function public.admin_export_menu_inflation_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with hist as (
    select
      h.menu_item_id,
      mi.name as menu_item_name,
      b.city,
      b.district,
      h.price_cents,
      h.created_at,
      row_number() over (
        partition by h.menu_item_id
        order by h.created_at asc
      ) as rn_first,
      row_number() over (
        partition by h.menu_item_id
        order by h.created_at desc
      ) as rn_last
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where h.price_cents is not null
      and h.price_cents > 0
      and h.created_at >= now() - make_interval(days => greatest(p_days, 1))
  ),
  first_last as (
    select
      h1.menu_item_id,
      h1.menu_item_name,
      h1.city,
      h1.district,
      max(case when h1.rn_first = 1 then h1.price_cents end) as first_price_cents,
      max(case when h1.rn_last = 1 then h1.price_cents end) as last_price_cents
    from hist h1
    group by h1.menu_item_id, h1.menu_item_name, h1.city, h1.district
  ),
  rows as (
    select
      coalesce(fl.city, '-') as city,
      coalesce(fl.district, '-') as district,
      replace(fl.menu_item_name, ',', ' ') as menu_item_name,
      fl.first_price_cents::int as first_price_cents,
      fl.last_price_cents::int as last_price_cents,
      case
        when fl.first_price_cents is null or fl.first_price_cents = 0 then null
        else round(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100.0, 2)
      end as inflation_pct
    from first_last fl
    where fl.first_price_cents is not null
      and fl.last_price_cents is not null
    order by inflation_pct desc nulls last
    limit 5000
  )
  select
    'city,district,menu_item_name,first_price_cents,last_price_cents,inflation_pct' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s',
          r.city,
          r.district,
          r.menu_item_name,
          r.first_price_cents::text,
          r.last_price_cents::text,
          coalesce(r.inflation_pct::text, '')
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
