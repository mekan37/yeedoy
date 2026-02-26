create function public.admin_approve_price_suggestion_v1(
  p_suggestion_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.admin_approve_menu_price_suggestion_v1(p_suggestion_id);
end;
$function$;

create function public.admin_reject_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_reason text;
begin
  v_reason := nullif(trim(p_reason), '');

  return public.admin_reject_menu_price_suggestion_v1(p_suggestion_id, v_reason);
end;
$function$;

create function public.owner_list_price_suggestions_v1(
  p_business_id uuid,
  p_status text,
  p_limit integer,
  p_offset integer
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if to_regprocedure('public.get_owner_price_suggestions_v1(uuid,text,integer,integer)') is not null then
    return query
    select *
    from public.get_owner_price_suggestions_v1(
      p_business_id,
      p_status,
      p_limit,
      p_offset
    );
  else
    return query
    select
      l.suggestion_id,
      l.status,
      l.created_at,
      s.business_id,
      b.name as business_name,
      l.menu_item_id,
      l.item_name,
      l.current_price_cents,
      l.suggested_price_cents,
      l.currency,
      l.created_by
    from public.owner_list_menu_price_suggestions_v1(
      p_business_id,
      p_status,
      p_limit,
      p_offset
    ) l
    join public.menu_item_price_suggestions s on s.id = l.suggestion_id
    join public.businesses b on b.id = s.business_id;
  end if;
end;
$function$;

-- Mini doğrulama (örnek çağrılar)
-- select public.admin_approve_price_suggestion_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.admin_reject_price_suggestion_v1('00000000-0000-0000-0000-000000000000'::uuid, 'test');
-- select * from public.owner_list_price_suggestions_v1(null, 'pending', 10, 0);


