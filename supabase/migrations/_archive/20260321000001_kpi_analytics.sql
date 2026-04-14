alter table public.analytics_events
  drop constraint if exists analytics_events_event_name_check;
alter table public.analytics_events
  add constraint analytics_events_event_name_check check (
    event_name = any (
      array[
        'menu_shared',
        'qr_scanned',
        'menu_link_opened',
        'app_install_from_menu',
        'business_reservation_click',
        'business_phone_click',
        'business_whatsapp_click',
        'business_order_click',
        'business_directions_click',
        'business_page_view',
        'menu_view',
        'discovery_impression',
        'discovery_business_click',
        'business_impression',
        'price_suggestion_submitted'
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
set search_path to 'public'
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
    'business_phone_click',
    'business_whatsapp_click',
    'business_order_click',
    'business_directions_click',
    'business_page_view',
    'menu_view',
    'discovery_impression',
    'discovery_business_click',
    'business_impression',
    'price_suggestion_submitted'
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
  )
  values (
    v_event_name,
    p_business_id,
    p_menu_id,
    nullif(trim(p_source), ''),
    v_client,
    v_user_id,
    coalesce(p_meta, '{}'::jsonb)
  );

  return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.admin_kpi_summary_v1(p_days integer default 30)
returns table(
  dau integer,
  dau_prev integer,
  wau integer,
  wau_prev integer,
  discovery_impressions integer,
  discovery_impressions_prev integer,
  discovery_clicks integer,
  discovery_clicks_prev integer,
  discovery_ctr double precision,
  discovery_ctr_prev double precision,
  business_views integer,
  business_views_prev integer,
  menu_views integer,
  menu_views_prev integer,
  menu_view_rate double precision,
  menu_view_rate_prev double precision,
  price_suggestions integer,
  price_suggestions_prev integer,
  price_verification_rate double precision,
  price_verification_rate_prev double precision,
  reports_avg_resolution_minutes double precision,
  reports_avg_resolution_minutes_prev double precision
)
language sql
as $$
with
  events as (
    select *
    from public.analytics_events
    where created_at >= now() - (p_days::text || ' days')::interval
  ),
  discovery_impressions_cte as (
    select
      coalesce(sum(nullif((meta->>'count'), '')::int), count(*))::int as impressions
    from events
    where event_name = 'discovery_impression'
  ),
  prev_events as (
    select *
    from public.analytics_events
    where created_at >= now() - ((p_days * 2)::text || ' days')::interval
      and created_at < now() - (p_days::text || ' days')::interval
  ),
  discovery_impressions_prev_cte as (
    select
      coalesce(sum(nullif((meta->>'count'), '')::int), count(*))::int as impressions
    from prev_events
    where event_name = 'discovery_impression'
  ),
  discovery_clicks_cte as (
    select count(*)::int as clicks
    from events
    where event_name = 'discovery_business_click'
  ),
  discovery_clicks_prev_cte as (
    select count(*)::int as clicks
    from prev_events
    where event_name = 'discovery_business_click'
  ),
  business_views_cte as (
    select count(*)::int as views
    from events
    where event_name = 'business_page_view'
  ),
  business_views_prev_cte as (
    select count(*)::int as views
    from prev_events
    where event_name = 'business_page_view'
  ),
  menu_views_cte as (
    select count(*)::int as views
    from events
    where event_name = 'menu_view'
  ),
  menu_views_prev_cte as (
    select count(*)::int as views
    from prev_events
    where event_name = 'menu_view'
  ),
  price_suggestions_cte as (
    select count(*)::int as cnt
    from events
    where event_name = 'price_suggestion_submitted'
  ),
  price_suggestions_prev_cte as (
    select count(*)::int as cnt
    from prev_events
    where event_name = 'price_suggestion_submitted'
  )
select
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '1 day'
      and client_id is not null
      and client_id <> ''
  ) as dau,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '2 days'
      and created_at < now() - interval '1 day'
      and client_id is not null
      and client_id <> ''
  ) as dau_prev,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '7 days'
      and client_id is not null
      and client_id <> ''
  ) as wau,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '14 days'
      and created_at < now() - interval '7 days'
      and client_id is not null
      and client_id <> ''
  ) as wau_prev,
  d.impressions as discovery_impressions,
  dp.impressions as discovery_impressions_prev,
  c.clicks as discovery_clicks,
  cp.clicks as discovery_clicks_prev,
  case when d.impressions > 0 then c.clicks::double precision / d.impressions else 0 end as discovery_ctr,
  case when dp.impressions > 0 then cp.clicks::double precision / dp.impressions else 0 end as discovery_ctr_prev,
  bv.views as business_views,
  bvp.views as business_views_prev,
  mv.views as menu_views,
  mvp.views as menu_views_prev,
  case when bv.views > 0 then mv.views::double precision / bv.views else 0 end as menu_view_rate,
  case when bvp.views > 0 then mvp.views::double precision / bvp.views else 0 end as menu_view_rate_prev,
  ps.cnt as price_suggestions,
  psp.cnt as price_suggestions_prev,
  case when mv.views > 0 then ps.cnt::double precision / mv.views else 0 end as price_verification_rate,
  case when mvp.views > 0 then psp.cnt::double precision / mvp.views else 0 end as price_verification_rate_prev,
  (
    select coalesce(avg(extract(epoch from (handled_at - created_at)) / 60.0), 0)
    from public.reports
    where handled_at is not null
      and created_at >= now() - (p_days::text || ' days')::interval
  ) as reports_avg_resolution_minutes,
  (
    select coalesce(avg(extract(epoch from (handled_at - created_at)) / 60.0), 0)
    from public.reports
    where handled_at is not null
      and created_at >= now() - ((p_days * 2)::text || ' days')::interval
      and created_at < now() - (p_days::text || ' days')::interval
  ) as reports_avg_resolution_minutes_prev
from discovery_impressions_cte d
cross join discovery_impressions_prev_cte dp
cross join discovery_clicks_cte c
cross join discovery_clicks_prev_cte cp
cross join business_views_cte bv
cross join business_views_prev_cte bvp
cross join menu_views_cte mv
cross join menu_views_prev_cte mvp
cross join price_suggestions_cte ps
cross join price_suggestions_prev_cte psp;
$$;
create or replace function public.owner_kpi_summary_v1(
  p_business_id uuid,
  p_days integer default 30
)
returns table(
  business_views integer,
  outbound_clicks integer,
  directions_clicks integer,
  search_impressions integer
)
language sql
as $$
with events as (
  select *
  from public.analytics_events
  where business_id = p_business_id
    and created_at >= now() - (p_days::text || ' days')::interval
)
select
  (select count(*) from events where event_name = 'business_page_view')::int as business_views,
  (select count(*) from events where event_name in (
      'business_reservation_click',
      'business_phone_click',
      'business_whatsapp_click',
      'business_order_click'
    ))::int as outbound_clicks,
  (select count(*) from events where event_name = 'business_directions_click')::int as directions_clicks,
  (select count(*) from events where event_name = 'business_impression')::int as search_impressions;
$$;
grant all on function public.admin_kpi_summary_v1(p_days integer) to anon, authenticated, service_role;
grant all on function public.owner_kpi_summary_v1(p_business_id uuid, p_days integer) to anon, authenticated, service_role;
