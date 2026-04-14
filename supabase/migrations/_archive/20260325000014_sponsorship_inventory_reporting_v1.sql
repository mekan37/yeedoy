alter table public.sponsorship_packages
  add column if not exists price_cents integer not null default 0,
  add column if not exists currency_code text not null default 'TRY',
  add column if not exists inventory_limit integer not null default 1;

update public.sponsorship_packages
set inventory_limit = 1
where inventory_limit < 1;

drop function if exists public.admin_upsert_sponsorship_package_v1(
  uuid,
  text,
  text,
  integer,
  text,
  boolean
);

create or replace function public.admin_upsert_sponsorship_package_v1(
  p_id uuid default null,
  p_name text default null,
  p_surface text default null,
  p_duration_days integer default null,
  p_price_display text default null,
  p_is_active boolean default true,
  p_price_cents integer default 0,
  p_currency_code text default 'TRY',
  p_inventory_limit integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  if p_id is null then
    insert into public.sponsorship_packages(
      name,
      surface,
      duration_days,
      price_display,
      is_active,
      price_cents,
      currency_code,
      inventory_limit
    )
    values (
      p_name,
      p_surface,
      p_duration_days,
      p_price_display,
      p_is_active,
      greatest(coalesce(p_price_cents, 0), 0),
      coalesce(nullif(trim(p_currency_code), ''), 'TRY'),
      greatest(coalesce(p_inventory_limit, 1), 1)
    )
    returning id into v_id;
  else
    update public.sponsorship_packages
    set
      name = p_name,
      surface = p_surface,
      duration_days = p_duration_days,
      price_display = p_price_display,
      is_active = p_is_active,
      price_cents = greatest(coalesce(p_price_cents, 0), 0),
      currency_code = coalesce(nullif(trim(p_currency_code), ''), 'TRY'),
      inventory_limit = greatest(coalesce(p_inventory_limit, 1), 1)
    where id = p_id
    returning id into v_id;
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_get_sponsorship_summary_v1()
returns table(
  active_sponsorships integer,
  pending_sponsorships integer,
  open_leads integer,
  impressions_30d integer,
  unique_users_30d integer,
  estimated_active_revenue_cents bigint
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with active_sponsorships_cte as (
    select s.id, s.package_id
    from public.sponsorships s
    where s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
  ),
  perf_cte as (
    select
      coalesce(sum(i.impressions_count), 0)::int as impressions_30d,
      coalesce(sum(i.unique_users_count), 0)::int as unique_users_30d
    from active_sponsorships_cte a
    left join public.sponsorship_impressions_daily i
      on i.sponsorship_id = a.id
     and i.day >= current_date - 29
  ),
  revenue_cte as (
    select coalesce(sum(p.price_cents), 0)::bigint as estimated_active_revenue_cents
    from active_sponsorships_cte a
    join public.sponsorship_packages p on p.id = a.package_id
  )
  select
    (select count(*)::int from active_sponsorships_cte) as active_sponsorships,
    (
      select count(*)::int
      from public.sponsorships s
      where s.status = 'pending'
    ) as pending_sponsorships,
    (
      select count(*)::int
      from public.sponsorship_leads l
      where l.status = 'new'
    ) as open_leads,
    perf_cte.impressions_30d,
    perf_cte.unique_users_30d,
    revenue_cte.estimated_active_revenue_cents
  from perf_cte
  cross join revenue_cte
  where public.is_admin();
$function$;

create or replace function public.admin_list_sponsorship_inventory_v1()
returns table(
  surface text,
  active_packages integer,
  total_packages integer,
  inventory_limit integer,
  live_units integer,
  open_inventory_slots integer,
  pending_sponsorships integer,
  open_leads integer,
  impressions_30d integer,
  unique_users_30d integer,
  estimated_active_revenue_cents bigint
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with surfaces as (
    select surface::text as surface
    from (
      select p.surface from public.sponsorship_packages p
      union
      select s.surface from public.sponsorships s
      union
      select l.preferred_surface as surface from public.sponsorship_leads l
      union
      select bp.tier as surface from public.business_premium bp
    ) src
  ),
  package_cte as (
    select
      p.surface::text as surface,
      count(*)::int as total_packages,
      count(*) filter (where p.is_active)::int as active_packages,
      coalesce(sum(case when p.is_active then p.inventory_limit else 0 end), 0)::int as inventory_limit
    from public.sponsorship_packages p
    group by p.surface
  ),
  live_sponsorship_units as (
    select
      s.surface::text as surface,
      count(*)::int as live_units,
      coalesce(sum(p.price_cents), 0)::bigint as estimated_active_revenue_cents
    from public.sponsorships s
    join public.sponsorship_packages p on p.id = s.package_id
    where s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
    group by s.surface
  ),
  live_premium_units as (
    select
      bp.tier::text as surface,
      count(*)::int as live_units
    from public.business_premium bp
    where bp.status = 'active'
      and (bp.ends_at is null or bp.ends_at >= now())
    group by bp.tier
  ),
  live_units_cte as (
    select
      surface,
      sum(live_units)::int as live_units
    from (
      select surface, live_units from live_sponsorship_units
      union all
      select surface, live_units from live_premium_units
    ) combined
    group by surface
  ),
  pending_cte as (
    select
      s.surface::text as surface,
      count(*)::int as pending_sponsorships
    from public.sponsorships s
    where s.status = 'pending'
    group by s.surface
  ),
  lead_cte as (
    select
      l.preferred_surface::text as surface,
      count(*) filter (where l.status = 'new')::int as open_leads
    from public.sponsorship_leads l
    group by l.preferred_surface
  ),
  perf_cte as (
    select
      s.surface::text as surface,
      coalesce(sum(i.impressions_count), 0)::int as impressions_30d,
      coalesce(sum(i.unique_users_count), 0)::int as unique_users_30d
    from public.sponsorships s
    left join public.sponsorship_impressions_daily i
      on i.sponsorship_id = s.id
     and i.day >= current_date - 29
    where s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
    group by s.surface
  )
  select
    surfaces.surface,
    coalesce(package_cte.active_packages, 0) as active_packages,
    coalesce(package_cte.total_packages, 0) as total_packages,
    coalesce(package_cte.inventory_limit, 0) as inventory_limit,
    coalesce(live_units_cte.live_units, 0) as live_units,
    greatest(
      coalesce(package_cte.inventory_limit, 0) - coalesce(live_units_cte.live_units, 0),
      0
    )::int as open_inventory_slots,
    coalesce(pending_cte.pending_sponsorships, 0) as pending_sponsorships,
    coalesce(lead_cte.open_leads, 0) as open_leads,
    coalesce(perf_cte.impressions_30d, 0) as impressions_30d,
    coalesce(perf_cte.unique_users_30d, 0) as unique_users_30d,
    coalesce(live_sponsorship_units.estimated_active_revenue_cents, 0)::bigint
      as estimated_active_revenue_cents
  from surfaces
  left join package_cte on package_cte.surface = surfaces.surface
  left join live_units_cte on live_units_cte.surface = surfaces.surface
  left join pending_cte on pending_cte.surface = surfaces.surface
  left join lead_cte on lead_cte.surface = surfaces.surface
  left join perf_cte on perf_cte.surface = surfaces.surface
  left join live_sponsorship_units on live_sponsorship_units.surface = surfaces.surface
  where public.is_admin()
  order by
    case surfaces.surface
      when 'discovery' then 1
      when 'business_page' then 2
      when 'stories' then 3
      when 'verified' then 4
      when 'premium' then 5
      else 99
    end,
    surfaces.surface;
$function$;

create or replace function public.owner_get_sponsorship_catalog_v1(
  p_business_id uuid
)
returns table(
  package_id uuid,
  package_name text,
  surface text,
  duration_days integer,
  price_display text,
  price_cents integer,
  currency_code text,
  inventory_limit integer,
  surface_live_units integer,
  surface_open_slots integer,
  business_live_units integer,
  business_impressions_30d integer,
  business_unique_users_30d integer,
  latest_lead_status text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with access_cte as (
    select (public.is_admin() or public.is_owner_of_business(p_business_id)) as ok
  ),
  live_sponsorship_units as (
    select
      s.surface::text as surface,
      count(*)::int as live_units
    from public.sponsorships s
    where s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
    group by s.surface
  ),
  live_premium_units as (
    select
      bp.tier::text as surface,
      count(*)::int as live_units
    from public.business_premium bp
    where bp.status = 'active'
      and (bp.ends_at is null or bp.ends_at >= now())
    group by bp.tier
  ),
  surface_live_units_cte as (
    select
      surface,
      sum(live_units)::int as live_units
    from (
      select surface, live_units from live_sponsorship_units
      union all
      select surface, live_units from live_premium_units
    ) combined
    group by surface
  ),
  business_sponsorship_units as (
    select
      s.surface::text as surface,
      count(*)::int as business_live_units
    from public.sponsorships s
    where s.business_id = p_business_id
      and s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
    group by s.surface
  ),
  business_premium_units as (
    select
      bp.tier::text as surface,
      count(*)::int as business_live_units
    from public.business_premium bp
    where bp.business_id = p_business_id
      and bp.status = 'active'
      and (bp.ends_at is null or bp.ends_at >= now())
    group by bp.tier
  ),
  business_live_units_cte as (
    select
      surface,
      sum(business_live_units)::int as business_live_units
    from (
      select surface, business_live_units from business_sponsorship_units
      union all
      select surface, business_live_units from business_premium_units
    ) combined
    group by surface
  ),
  business_perf_cte as (
    select
      s.surface::text as surface,
      coalesce(sum(i.impressions_count), 0)::int as business_impressions_30d,
      coalesce(sum(i.unique_users_count), 0)::int as business_unique_users_30d
    from public.sponsorships s
    left join public.sponsorship_impressions_daily i
      on i.sponsorship_id = s.id
     and i.day >= current_date - 29
    where s.business_id = p_business_id
      and s.status = 'active'
      and (s.starts_at is null or s.starts_at <= now())
      and (s.ends_at is null or s.ends_at >= now())
    group by s.surface
  ),
  latest_lead_cte as (
    select distinct on (l.preferred_surface)
      l.preferred_surface::text as surface,
      l.status::text as latest_lead_status
    from public.sponsorship_leads l
    where l.business_id = p_business_id
    order by l.preferred_surface, l.created_at desc
  )
  select
    p.id as package_id,
    p.name as package_name,
    p.surface::text,
    p.duration_days,
    p.price_display,
    p.price_cents,
    p.currency_code,
    p.inventory_limit,
    coalesce(surface_live_units_cte.live_units, 0) as surface_live_units,
    greatest(
      p.inventory_limit - coalesce(surface_live_units_cte.live_units, 0),
      0
    )::int as surface_open_slots,
    coalesce(business_live_units_cte.business_live_units, 0) as business_live_units,
    coalesce(business_perf_cte.business_impressions_30d, 0) as business_impressions_30d,
    coalesce(business_perf_cte.business_unique_users_30d, 0) as business_unique_users_30d,
    latest_lead_cte.latest_lead_status
  from public.sponsorship_packages p
  cross join access_cte
  left join surface_live_units_cte on surface_live_units_cte.surface = p.surface
  left join business_live_units_cte on business_live_units_cte.surface = p.surface
  left join business_perf_cte on business_perf_cte.surface = p.surface
  left join latest_lead_cte on latest_lead_cte.surface = p.surface
  where access_cte.ok
    and p.is_active = true
  order by
    case p.surface
      when 'discovery' then 1
      when 'business_page' then 2
      when 'stories' then 3
      when 'verified' then 4
      when 'premium' then 5
      else 99
    end,
    p.price_cents,
    p.duration_days,
    p.name;
$function$;
