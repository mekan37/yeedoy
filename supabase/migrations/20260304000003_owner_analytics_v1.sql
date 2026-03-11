create or replace function public.list_owner_analytics_v1(
  p_business_id uuid,
  p_days integer default 30,
  p_compare_branches boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_days integer := greatest(1, least(coalesce(p_days, 30), 365));
  v_since timestamptz := now() - make_interval(days => v_days);
  v_chain_id uuid;
  v_summary jsonb;
  v_daily jsonb;
  v_top_items jsonb;
  v_top_categories jsonb;
  v_source_breakdown jsonb;
  v_branch_compare jsonb := '[]'::jsonb;
begin
  if p_business_id is null then
    raise exception 'missing_business_id';
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'business_read')) then
    raise exception 'forbidden';
  end if;

  select b.chain_id
  into v_chain_id
  from public.businesses b
  where b.id = p_business_id;

  with scoped_events as (
    select e.*
    from public.analytics_events e
    where e.business_id = p_business_id
      and e.created_at >= v_since
  )
  select jsonb_build_object(
    'qr_scans', count(*) filter (where event_name = 'qr_scanned'),
    'menu_opens', count(*) filter (where event_name = 'menu_link_opened'),
    'category_views', count(*) filter (
      where event_name = 'menu_view'
        and coalesce(
          nullif(trim(e.meta->>'category_name'), ''),
          nullif(trim(mi.catalog_category_name), '')
        ) is not null
    ),
    'item_clicks', count(*) filter (
      where event_name = 'menu_view'
        and coalesce(nullif(trim(e.meta->>'menu_item_id'), ''), nullif(trim(e.meta->>'menu_item_name'), '')) is not null
    ),
    'source_total', count(*) filter (where event_name in ('menu_link_opened', 'qr_scanned', 'menu_view'))
  )
  into v_summary
  from scoped_events e
  left join public.menu_items mi
    on mi.id::text = nullif(trim(e.meta->>'menu_item_id'), '');

  with daily as (
    select
      d.day::date as day,
      count(*) filter (where e.event_name = 'qr_scanned')::int as qr_scans,
      count(*) filter (where e.event_name = 'menu_link_opened')::int as menu_opens,
      count(*) filter (where e.event_name = 'menu_view')::int as menu_views,
      count(*) filter (
        where e.event_name = 'menu_view'
          and coalesce(nullif(trim(e.meta->>'menu_item_id'), ''), nullif(trim(e.meta->>'menu_item_name'), '')) is not null
      )::int as item_clicks
    from generate_series(
      (current_date - v_days + 1)::date,
      current_date::date,
      interval '1 day'
    ) as d(day)
    left join public.analytics_events e
      on e.business_id = p_business_id
     and e.created_at >= v_since
     and date_trunc('day', e.created_at) = d.day
    group by d.day
    order by d.day
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'day', to_char(day, 'YYYY-MM-DD'),
        'qr_scans', qr_scans,
        'menu_opens', menu_opens,
        'menu_views', menu_views,
        'item_clicks', item_clicks
      )
      order by day
    ),
    '[]'::jsonb
  )
  into v_daily
  from daily;

  with item_events as (
    select
      coalesce(
        nullif(trim(e.meta->>'menu_item_name'), ''),
        nullif(trim(mi.name), ''),
        e.meta->>'menu_item_id'
      ) as item_name,
      count(*)::int as total_views
    from public.analytics_events e
    left join public.menu_items mi
      on mi.id::text = nullif(trim(e.meta->>'menu_item_id'), '')
    where e.business_id = p_business_id
      and e.created_at >= v_since
      and e.event_name = 'menu_view'
      and coalesce(
        nullif(trim(e.meta->>'menu_item_name'), ''),
        nullif(trim(mi.name), ''),
        e.meta->>'menu_item_id'
      ) is not null
    group by 1
    order by total_views desc, item_name asc
    limit 10
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'label', item_name,
        'count', total_views
      )
      order by total_views desc, item_name asc
    ),
    '[]'::jsonb
  )
  into v_top_items
  from item_events;

  with category_events as (
    select
      coalesce(
        nullif(trim(e.meta->>'category_name'), ''),
        nullif(trim(mi.catalog_category_name), '')
      ) as category_name,
      count(*)::int as total_views
    from public.analytics_events e
    left join public.menu_items mi
      on mi.id::text = nullif(trim(e.meta->>'menu_item_id'), '')
    where e.business_id = p_business_id
      and e.created_at >= v_since
      and e.event_name = 'menu_view'
      and coalesce(
        nullif(trim(e.meta->>'category_name'), ''),
        nullif(trim(mi.catalog_category_name), '')
      ) is not null
    group by 1
    order by total_views desc, category_name asc
    limit 10
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'label', category_name,
        'count', total_views
      )
      order by total_views desc, category_name asc
    ),
    '[]'::jsonb
  )
  into v_top_categories
  from category_events;

  with sources as (
    select
      case
        when e.event_name = 'qr_scanned' then 'qr_short_link'
        when coalesce(nullif(trim(e.source), ''), '') = '' then 'normal'
        else trim(e.source)
      end as source_label,
      count(*)::int as total_count
    from public.analytics_events e
    where e.business_id = p_business_id
      and e.created_at >= v_since
      and e.event_name in ('menu_link_opened', 'qr_scanned', 'menu_view')
    group by 1
    order by total_count desc, source_label asc
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'label', source_label,
        'count', total_count
      )
      order by total_count desc, source_label asc
    ),
    '[]'::jsonb
  )
  into v_source_breakdown
  from sources;

  if p_compare_branches and v_chain_id is not null then
    with accessible_branches as (
      select
        b.id,
        coalesce(nullif(trim(b.branch_label), ''), nullif(trim(b.name), ''), b.id::text) as label
      from public.businesses b
      where b.chain_id = v_chain_id
        and public.has_business_permission_v1(b.id, 'business_read')
    ),
    branch_metrics as (
      select
        ab.id as business_id,
        ab.label,
        count(*) filter (where e.event_name = 'menu_link_opened')::int as menu_opens,
        count(*) filter (where e.event_name = 'qr_scanned')::int as qr_scans,
        count(*) filter (where e.event_name = 'menu_view')::int as menu_views
      from accessible_branches ab
      left join public.analytics_events e
        on e.business_id = ab.id
       and e.created_at >= v_since
      group by ab.id, ab.label
      order by menu_opens desc, qr_scans desc, ab.label asc
    )
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'business_id', business_id,
          'label', label,
          'menu_opens', menu_opens,
          'qr_scans', qr_scans,
          'menu_views', menu_views,
          'selected', business_id = p_business_id
        )
        order by menu_opens desc, qr_scans desc, label asc
      ),
      '[]'::jsonb
    )
    into v_branch_compare
    from branch_metrics;
  end if;

  return jsonb_build_object(
    'summary', coalesce(v_summary, '{}'::jsonb),
    'daily', coalesce(v_daily, '[]'::jsonb),
    'top_items', coalesce(v_top_items, '[]'::jsonb),
    'top_categories', coalesce(v_top_categories, '[]'::jsonb),
    'source_breakdown', coalesce(v_source_breakdown, '[]'::jsonb),
    'branch_compare', coalesce(v_branch_compare, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.list_owner_analytics_v1(uuid, integer, boolean) to authenticated;
