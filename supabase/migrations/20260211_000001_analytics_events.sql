create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  event_name text not null,
  business_id uuid null references public.businesses(id) on delete set null,
  menu_id uuid null references public.menus(id) on delete set null,
  source text null,
  client_id text null,
  user_id uuid null,
  meta jsonb not null default '{}'::jsonb
);
alter table public.analytics_events
  add constraint analytics_events_event_name_check
  check (event_name in ('menu_shared','qr_scanned','menu_link_opened','app_install_from_menu'));
create index if not exists analytics_events_event_name_created_at_idx
  on public.analytics_events (event_name, created_at desc);
create index if not exists analytics_events_business_created_at_idx
  on public.analytics_events (business_id, created_at desc);
create index if not exists analytics_events_menu_created_at_idx
  on public.analytics_events (menu_id, created_at desc);
create index if not exists analytics_events_client_created_at_idx
  on public.analytics_events (client_id, created_at desc);
alter table public.analytics_events enable row level security;
create or replace function public.log_event_v1(
  p_event_name text,
  p_business_id uuid default null,
  p_menu_id uuid default null,
  p_source text default null,
  p_client_id text default null,
  p_meta jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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
    'app_install_from_menu'
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
$function$;
create or replace function public.analytics_growth_v1(
  p_days int default 30,
  p_business_id uuid default null
) returns table(
  day date,
  menu_link_opened int,
  qr_scanned int,
  menu_shared int,
  app_install_from_menu int
)
language plpgsql
security definer
set search_path to 'public'
as $function$
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
    sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu
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
$function$;
