create or replace function public.get_user_reputation_score_v2(p_user_id uuid)
 returns integer
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_score int := 50;
  v_approved int := 0;
  v_rejected int := 0;
begin
  if p_user_id is null then
    return 0;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status::text = any($2)'
      into v_approved using p_user_id, array['approved','accepted','handled','verified'];
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status::text = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 3) - (v_rejected * 5);
  end if;

  if to_regclass('public.business_suggestions') is not null then
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','accepted'];
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 4) - (v_rejected * 6);
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','published'];
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 1) - (v_rejected * 3);
  end if;

  if v_score < 0 then v_score := 0; end if;
  if v_score > 100 then v_score := 100; end if;
  return v_score;
end;
$function$;;
