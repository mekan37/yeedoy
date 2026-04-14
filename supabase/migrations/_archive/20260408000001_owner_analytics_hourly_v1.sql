-- list_owner_analytics_hourly_v1
-- Returns per-hour analytics for a business over the last N hours (default 24,
-- max 72). Used by the owner analytics page "Son 24 Saat" granularity view.
--
-- Response shape:
-- {
--   "summary": { qr_scans, menu_opens, category_views, item_clicks, source_total },
--   "hourly":  [{ hour: 0-23, qr_scans, menu_opens, menu_views, item_clicks }]
-- }

create or replace function public.list_owner_analytics_hourly_v1(
  p_business_id uuid,
  p_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hours  integer    := greatest(1, least(coalesce(p_hours, 24), 72));
  v_since  timestamptz := date_trunc('hour', now()) - make_interval(hours => v_hours - 1);
  v_summary jsonb;
  v_hourly  jsonb;
begin
  if p_business_id is null then
    raise exception 'missing_business_id';
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'business_read')) then
    raise exception 'forbidden';
  end if;

  -- Aggregate summary for the window
  select jsonb_build_object(
    'qr_scans',       count(*) filter (where e.event_name = 'qr_scanned'),
    'menu_opens',     count(*) filter (where e.event_name = 'menu_link_opened'),
    'category_views', count(*) filter (
      where e.event_name = 'menu_view'
        and coalesce(
          nullif(trim(e.meta->>'category_name'), ''),
          nullif(trim(mi.catalog_category_name), '')
        ) is not null
    ),
    'item_clicks', count(*) filter (
      where e.event_name = 'menu_view'
        and coalesce(
          nullif(trim(e.meta->>'menu_item_id'), ''),
          nullif(trim(e.meta->>'menu_item_name'), '')
        ) is not null
    ),
    'source_total', count(*) filter (
      where e.event_name in ('menu_link_opened', 'qr_scanned', 'menu_view')
    )
  )
  into v_summary
  from public.analytics_events e
  left join public.menu_items mi
    on mi.id::text = nullif(trim(e.meta->>'menu_item_id'), '')
  where e.business_id = p_business_id
    and e.created_at >= v_since;

  -- Hourly series (one row per hour bucket)
  with hourly as (
    select
      h.ts                                                                         as bucket,
      count(*) filter (where e.event_name = 'qr_scanned')::int                   as qr_scans,
      count(*) filter (where e.event_name = 'menu_link_opened')::int              as menu_opens,
      count(*) filter (where e.event_name = 'menu_view')::int                     as menu_views,
      count(*) filter (
        where e.event_name = 'menu_view'
          and coalesce(
            nullif(trim(e.meta->>'menu_item_id'), ''),
            nullif(trim(e.meta->>'menu_item_name'), '')
          ) is not null
      )::int                                                                       as item_clicks
    from generate_series(
      v_since,
      date_trunc('hour', now()),
      interval '1 hour'
    ) as h(ts)
    left join public.analytics_events e
      on  e.business_id = p_business_id
      and e.created_at >= v_since
      and date_trunc('hour', e.created_at) = h.ts
    group by h.ts
    order by h.ts
  )
  select jsonb_agg(
    jsonb_build_object(
      'hour',       extract(hour from bucket)::int,
      'qr_scans',   qr_scans,
      'menu_opens',  menu_opens,
      'menu_views',  menu_views,
      'item_clicks', item_clicks
    )
  )
  into v_hourly
  from hourly;

  return jsonb_build_object(
    'summary', coalesce(v_summary, '{}'::jsonb),
    'hourly',  coalesce(v_hourly, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.list_owner_analytics_hourly_v1(uuid, integer) to authenticated;
