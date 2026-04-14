create or replace function public.approve_menu_item_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  s record;
  v_item_id uuid;
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  select * into s
  from public.menu_item_suggestions
  where id = p_suggestion_id and status = 'pending';

  if s is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if s.action = 'create' then
    insert into public.menu_items(
      section_id, business_id, name, description, price_cents, currency, calories,
      is_vegan, is_vegetarian, is_gluten_free, is_lactose_free, is_halal,
      status, created_by,
      catalog_item_id
    )
    values (
      (s.payload->>'section_id')::uuid,
      s.business_id,
      coalesce(s.payload->>'name',''),
      s.payload->>'description',
      nullif(s.payload->>'price_cents','')::int,
      coalesce(s.payload->>'currency','TRY'),
      nullif(s.payload->>'calories','')::int,
      coalesce((s.payload->>'is_vegan')::boolean,false),
      coalesce((s.payload->>'is_vegetarian')::boolean,false),
      coalesce((s.payload->>'is_gluten_free')::boolean,false),
      coalesce((s.payload->>'is_lactose_free')::boolean,false),
      coalesce((s.payload->>'is_halal')::boolean,false),
      'published',
      s.created_by,
      nullif(s.payload->>'catalog_item_id','')::bigint
    )
    returning id into v_item_id;

  elsif s.action = 'price_update' then
    update public.menu_items
    set price_cents = nullif(s.payload->>'price_cents','')::int,
        currency = coalesce(s.payload->>'currency','TRY'),
        updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;

  elsif s.action = 'update' then
    update public.menu_items
    set
      name = coalesce(s.payload->>'name', name),
      description = coalesce(s.payload->>'description', description),
      price_cents = coalesce(nullif(s.payload->>'price_cents','')::int, price_cents),
      calories = coalesce(nullif(s.payload->>'calories','')::int, calories),
      is_vegan = coalesce((s.payload->>'is_vegan')::boolean, is_vegan),
      is_vegetarian = coalesce((s.payload->>'is_vegetarian')::boolean, is_vegetarian),
      is_gluten_free = coalesce((s.payload->>'is_gluten_free')::boolean, is_gluten_free),
      is_lactose_free = coalesce((s.payload->>'is_lactose_free')::boolean, is_lactose_free),
      is_halal = coalesce((s.payload->>'is_halal')::boolean, is_halal),
      catalog_item_id = coalesce(nullif(s.payload->>'catalog_item_id','')::bigint, catalog_item_id),
      updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;

  elsif s.action = 'delete' then
    update public.menu_items set status = 'archived', updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;
  end if;

  update public.menu_item_suggestions
  set status = 'approved',
      handled_by = auth.uid(),
      handled_at = now(),
      admin_note = v_note
  where id = p_suggestion_id;

  return jsonb_build_object('ok', true, 'menu_item_id', v_item_id);
end;
$function$;
create or replace function public.reject_owner_claim(
  p_claim_id uuid,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_is_admin boolean;
  v_note text;
begin
  select exists(select 1 from public.admin_users where user_id = auth.uid())
  into v_is_admin;

  if not v_is_admin then
    raise exception 'not_authorized';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set status = 'rejected',
      admin_note = v_note,
      reviewed_at = now()
  where id = p_claim_id;
end;
$function$;
create or replace function public.submit_suspended_meal_claim_v1(
  p_suspended_meal_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_status public.suspended_meal_status;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_note := nullif(trim(p_note), '');

  select status into v_status
  from public.suspended_meals
  where id = p_suspended_meal_id;

  if v_status is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_status <> 'active' then
    return jsonb_build_object('ok', false, 'error', 'not_active');
  end if;

  -- aynı kullanıcı aynı mealâ€™e tekrar claim atamasın
  if exists (
    select 1 from public.suspended_meal_claims
    where suspended_meal_id = p_suspended_meal_id
      and claimant_user_id = auth.uid()
  ) then
    return jsonb_build_object('ok', false, 'error', 'already_claimed');
  end if;

  insert into public.suspended_meal_claims(suspended_meal_id, claimant_user_id, note)
  values (p_suspended_meal_id, auth.uid(), v_note);

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.submit_business_suggestion(
  p_name text,
  p_category text,
  p_address text,
  p_city text,
  p_district text,
  p_note text default null
)
returns bigint
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_id bigint;
  v_note text;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  v_note := nullif(trim(p_note), '');

  insert into public.business_suggestions(
    user_id, name, category, address, city, district, note
  ) values (
    v_uid, p_name, p_category, p_address, p_city, p_district, v_note
  )
  returning id into v_id;

  return v_id;
end;
$function$;
