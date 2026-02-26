create or replace function public.public_menu_share_view_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_status text;
  v_menu jsonb;
  v_business jsonb;
  v_sections jsonb;
begin
  select m.status
    into v_status
  from public.menus m
  where m.id = p_menu_id;

  if v_status is null then
    return jsonb_build_object('ok', false);
  end if;

  if v_status = 'archived' then
    return jsonb_build_object('ok', false);
  end if;

  if v_status <> 'published' then
    return jsonb_build_object('ok', false);
  end if;

  select to_jsonb(m)
    into v_menu
  from (
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
  ) m;

  select to_jsonb(b)
    into v_business
  from (
    select
      b.id,
      b.name,
      b.logo_url
    from public.businesses b
    join public.menus m on m.business_id = b.id
    where m.id = p_menu_id
  ) b;

  with sections as (
    select
      s.id,
      s.menu_id,
      s.title,
      s.sort_order
    from public.menu_sections s
    where s.menu_id = p_menu_id
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
  select coalesce(
    jsonb_agg(
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
    ),
    '[]'::jsonb
  )
  into v_sections
  from sections s;

  return jsonb_build_object(
    'ok', true,
    'menu', v_menu,
    'business', v_business,
    'sections', v_sections
  );
end;
$function$;
