create or replace function public.owner_delete_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_archive_menu_v1(p_menu_id);
end;
$function$;
create or replace function public.owner_delete_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_archive_menu_item_v1(p_item_id);
end;
$function$;
create or replace function public.public_menu_share_view_v1(
  p_menu_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  with menu_base as (
    select
      m.id,
      m.business_id,
      m.title,
      m.kind,
      m.status,
      m.active_from,
      m.active_to,
      m.created_at,
      m.updated_at
    from public.menus m
    where m.id = p_menu_id
      and m.status = 'published'
  ),
  sections as (
    select
      s.id,
      s.menu_id,
      s.title,
      s.sort_order
    from public.menu_sections s
    join menu_base m on m.id = s.menu_id
    order by s.sort_order asc, s.created_at asc
  ),
  items as (
    select
      i.id,
      i.section_id,
      i.business_id,
      i.name,
      i.description,
      i.price_cents,
      i.currency,
      i.calories,
      i.is_vegan,
      i.is_vegetarian,
      i.is_gluten_free,
      i.is_lactose_free,
      i.is_halal,
      i.status,
      i.catalog_item_id
    from public.menu_items i
    join sections s on s.id = i.section_id
    where i.status = 'published'
    order by i.created_at asc
  )
  select jsonb_build_object(
    'menu', (select to_jsonb(m) from menu_base m),
    'sections', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'title', s.title,
          'sort_order', s.sort_order,
          'items', coalesce((
            select jsonb_agg(to_jsonb(i))
            from items i
            where i.section_id = s.id
          ), '[]'::jsonb)
        )
      )
      from sections s
    ), '[]'::jsonb)
  );
$function$;
