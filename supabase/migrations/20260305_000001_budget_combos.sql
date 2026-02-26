create or replace function public.get_budget_combos_v1(
  p_city text,
  p_district text,
  p_party_size int,
  p_budget_total_cents int,
  p_category text default null,
  p_limit int default 30
)
returns table(
  business_id uuid,
  business_name text,
  combo jsonb,
  total_cents int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with base_businesses as (
    select b.id, b.name
    from public.businesses b
    where b.city = p_city
      and (p_district is null or b.district = p_district)
      and (p_category is null or b.category = p_category)
  ),
  main_items as (
    select
      b.id as business_id,
      mi.id as menu_item_id,
      mi.name,
      mi.price_cents,
      mi.currency,
      row_number() over (
        partition by b.id
        order by coalesce(v.verified_ratio, 0) desc,
                 mi.price_cents asc nulls last,
                 mi.created_at desc
      ) as rn
    from base_businesses b
    join public.menu_items mi on mi.business_id = b.id
    left join public.menu_item_value_score_v1 v on v.menu_item_id = mi.id
    left join public.menu_sections s on s.id = mi.section_id
    where mi.status = 'published'
      and mi.price_cents is not null
      and not (
        (s.title is not null and lower(s.title) like any(
          array['%icecek%','%icki%','%drink%','%beverage%']
        ))
        or (lower(mi.name) like any(
          array[
            '%cola%','%soda%','%gazoz%','%su%','%ayran%','%limonata%','%cay%','%kahve%','%juice%','%smoothie%','%bira%','%wine%','%sarap%'
          ]
        ))
      )
  ),
  mains as (
    select * from main_items where rn <= 3
  ),
  drink_items as (
    select
      b.id as business_id,
      mi.id as menu_item_id,
      mi.name,
      mi.price_cents,
      mi.currency,
      row_number() over (
        partition by b.id
        order by mi.price_cents asc nulls last, mi.created_at desc
      ) as rn
    from base_businesses b
    join public.menu_items mi on mi.business_id = b.id
    left join public.menu_sections s on s.id = mi.section_id
    where mi.status = 'published'
      and mi.price_cents is not null
      and (
        (s.title is not null and lower(s.title) like any(
          array['%icecek%','%icki%','%drink%','%beverage%']
        ))
        or (lower(mi.name) like any(
          array[
            '%cola%','%soda%','%gazoz%','%su%','%ayran%','%limonata%','%cay%','%kahve%','%juice%','%smoothie%','%bira%','%wine%','%sarap%'
          ]
        ))
      )
  ),
  drinks as (
    select * from drink_items where rn <= 2
  ),
  combos_main_only as (
    select
      b.id as business_id,
      b.name as business_name,
      jsonb_build_object(
        'main', jsonb_build_object(
          'id', m.menu_item_id,
          'name', m.name,
          'price_cents', m.price_cents,
          'currency', m.currency
        ),
        'drink', null
      ) as combo,
      (m.price_cents * p_party_size)::int as total_cents
    from base_businesses b
    join mains m on m.business_id = b.id
  ),
  combos_with_drink as (
    select
      b.id as business_id,
      b.name as business_name,
      jsonb_build_object(
        'main', jsonb_build_object(
          'id', m.menu_item_id,
          'name', m.name,
          'price_cents', m.price_cents,
          'currency', m.currency
        ),
        'drink', jsonb_build_object(
          'id', d.menu_item_id,
          'name', d.name,
          'price_cents', d.price_cents,
          'currency', d.currency
        )
      ) as combo,
      ((m.price_cents + d.price_cents) * p_party_size)::int as total_cents
    from base_businesses b
    join mains m on m.business_id = b.id
    join drinks d on d.business_id = b.id
  ),
  all_combos as (
    select * from combos_main_only
    union all
    select * from combos_with_drink
  )
  select business_id, business_name, combo, total_cents
  from all_combos
  where total_cents <= p_budget_total_cents
  order by total_cents asc
  limit p_limit;
$$;

