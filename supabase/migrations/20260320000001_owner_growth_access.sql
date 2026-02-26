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
    if p_business_id is null or not public.is_owner_of_business(p_business_id) then
      raise exception 'not authorized';
    end if;
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
