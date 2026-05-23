-- M4: Bulk menu item translations listing RPC for OwnerTranslationsPage

create or replace function public.list_menu_item_translations_v1(
  p_business_id uuid,
  p_menu_id     uuid  default null,
  p_locale      text  default 'en',
  p_limit       int   default 100,
  p_offset      int   default 0
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  with rows as (
    select
      mi.id        as item_id,
      mi.name      as item_name_tr,
      mi.description as item_desc_tr,
      ms.title     as section_name,
      ms.sort_order as section_order,
      mi.sort_order as item_order,
      m.id         as menu_id,
      m.title      as menu_title,
      t.name       as trans_name,
      t.description as trans_desc
    from menu_items mi
    join menu_sections ms on ms.id = mi.section_id
    join menus m on m.id = ms.menu_id
    left join menu_translations t
      on t.entity_id = mi.id
      and t.entity_type = 'item'
      and t.locale = p_locale
    where m.business_id = p_business_id
      and m.status != 'archived'
      and (p_menu_id is null or m.id = p_menu_id)
    order by m.title, ms.sort_order, mi.sort_order
    limit p_limit offset p_offset
  ),
  counted as (
    select count(*) as total
    from menu_items mi
    join menu_sections ms on ms.id = mi.section_id
    join menus m on m.id = ms.menu_id
    where m.business_id = p_business_id
      and m.status != 'archived'
      and (p_menu_id is null or m.id = p_menu_id)
  )
  select jsonb_build_object(
    'total', (select total from counted),
    'items', coalesce(
      (select jsonb_agg(
        jsonb_build_object(
          'item_id',      r.item_id,
          'item_name_tr', r.item_name_tr,
          'item_desc_tr', r.item_desc_tr,
          'trans_name',   r.trans_name,
          'trans_desc',   r.trans_desc,
          'section_name', r.section_name,
          'menu_id',      r.menu_id,
          'menu_title',   r.menu_title
        )
      ) from rows r),
      '[]'::jsonb
    )
  )
$$;

grant execute on function public.list_menu_item_translations_v1 to authenticated;
