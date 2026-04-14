create or replace function public.get_business_profile_score_v1(
  p_business_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_menu_exists boolean;
  v_amenities_count int;
  v_media_count int;
  v_recent_update boolean;
  v_score int := 0;
  v_breakdown jsonb;
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object(
      'score', 0,
      'breakdown', jsonb_build_object('error', 'not_owner')
    );
  end if;

  select exists(
    select 1 from public.menus m
    where m.business_id = p_business_id
  ) into v_menu_exists;

  select count(*)
    into v_amenities_count
  from public.business_amenity_map bam
  where bam.business_id = p_business_id;

  select count(*)
    into v_media_count
  from public.business_media bm
  where bm.business_id = p_business_id;

  select exists(
    select 1
    from public.business_activity_log l
    where l.business_id = p_business_id
      and l.type = 'menu_update'
      and l.created_at >= now() - interval '7 days'
  ) into v_recent_update;

  if v_menu_exists then v_score := v_score + 40; end if;
  if v_amenities_count >= 2 then v_score := v_score + 20; end if;
  if v_media_count >= 3 then v_score := v_score + 20; end if;
  if v_recent_update then v_score := v_score + 20; end if;

  v_breakdown := jsonb_build_object(
    'menu', v_menu_exists,
    'amenities', v_amenities_count,
    'photos', v_media_count,
    'recent_update', v_recent_update
  );

  return jsonb_build_object(
    'score', v_score,
    'breakdown', v_breakdown
  );
end;
$function$;
