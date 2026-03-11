create or replace function public.recompute_user_achievements_v1(p_user_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
  v_silent_views int := 0;
  v_night_views int := 0;
  v_serendipity_clicks int := 0;
  v_weekend_views int := 0;
  v_stale_updates int := 0;
  v_unique_menu_item_views int := 0;
  v_pizza_unique_rated_count int := 0;
  v_price_verified_streak_days int := 0;
  v_district_unique_rated_count int := 0;
  v_combo_review_price_photo int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];

    if to_regclass('public.businesses') is not null then
      execute
        'select count(distinct r.business_id)
         from public.reviews r
         join public.businesses b on b.id = r.business_id
         where r.user_id = $1
           and r.rating is not null
           and r.business_id is not null
           and r.status = any($2)
           and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false
           and lower(coalesce(b.category, '''')) like ''%pizza%'''
        into v_pizza_unique_rated_count using p_user_id, array['approved','published'];

      execute
        'select coalesce(max(cnt), 0)::int
         from (
           select count(distinct r.business_id)::int as cnt
           from public.reviews r
           join public.businesses b on b.id = r.business_id
           where r.user_id = $1
             and r.rating is not null
             and r.business_id is not null
             and r.status = any($2)
             and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false
             and nullif(trim(b.district), '''') is not null
           group by b.district
         ) x'
        into v_district_unique_rated_count using p_user_id, array['approved','published'];
    end if;
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)'
      into v_silent_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(hour from (created_at at time zone ''Europe/Istanbul'')) between 0 and 3'
      into v_night_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = ''discovery_business_click''
         and coalesce(source, '''') = any($2)'
      into v_serendipity_clicks using p_user_id, array['discover', 'serendipity', 'discover_list'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(isodow from (created_at at time zone ''Europe/Istanbul'')) in (6,7)'
      into v_weekend_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(distinct coalesce((meta->>''menu_item_id''), ''''))
       from public.analytics_events
       where user_id = $1
         and event_name = ''menu_view''
         and coalesce((meta->>''menu_item_id''), '''') <> '''''
      into v_unique_menu_item_views using p_user_id;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions s
       where s.created_by = $1
         and s.status::text = any($2)
         and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];

    execute
      'with verified_days as (
         select distinct (created_at at time zone ''Europe/Istanbul'')::date as d
         from public.menu_item_price_suggestions s
         where s.created_by = $1
           and s.status::text = any($2)
           and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false
       ),
       grouped as (
         select d, d - (row_number() over(order by d))::int as grp
         from verified_days
       )
       select coalesce(max(streak_len), 0)::int
       from (
         select count(*)::int as streak_len
         from grouped
         group by grp
       ) s'
      into v_price_verified_streak_days using p_user_id, array['approved','accepted','handled','verified'];

    if to_regclass('public.menu_items') is not null then
      execute
        'select count(*) from public.menu_item_price_suggestions s
         join public.menu_items mi on mi.id = s.menu_item_id
         where s.created_by = $1
           and s.status::text = any($2)
           and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false
           and mi.updated_at <= now() - interval ''365 days'''
        into v_stale_updates using p_user_id, array['approved','accepted','handled','verified'];
    end if;
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos p
       where p.created_by = $1
         and coalesce((to_jsonb(p)->>''is_shadow'')::boolean, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports r
       where coalesce(r.user_id, r.reporter_user_id) = $1
         and coalesce(r.status, '''') = any($2)
         and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

  v_combo_review_price_photo :=
    (case when v_review_count > 0 then 1 else 0 end) +
    (case when v_price_verified_count > 0 then 1 else 0 end) +
    (case when v_menu_photo_count > 0 then 1 else 0 end);

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
          and r.status = any($2)
          and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id, array['approved','published'];
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
  if v_pizza_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'pizza_master_10');
  end if;
  if v_price_verified_streak_days >= 3 then
    perform public.award_achievement_v1(p_user_id, 'combo_price_streak_3');
  end if;
  if v_district_unique_rated_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'combo_district_master_5');
  end if;
  if v_combo_review_price_photo >= 3 then
    perform public.award_achievement_v1(p_user_id, 'combo_full_contributor');
  end if;

  if v_silent_views >= 20 and v_review_count = 0 then
    perform public.award_achievement_v1(p_user_id, 'silent_follower_20');
  end if;
  if v_night_views >= 5 then
    perform public.award_achievement_v1(p_user_id, 'night_gourmet_5');
  end if;
  if v_stale_updates >= 1 then
    perform public.award_achievement_v1(p_user_id, 'menu_archivist_1');
  end if;
  if v_serendipity_clicks >= 10 then
    perform public.award_achievement_v1(p_user_id, 'chance_hunter_10');
  end if;
  if v_weekend_views >= 8 then
    perform public.award_achievement_v1(p_user_id, 'weekend_wanderer_8');
  end if;
  if v_unique_menu_item_views >= 30 then
    perform public.award_achievement_v1(p_user_id, 'deep_menu_diver_30');
  end if;
end;
$function$;

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
$function$;
