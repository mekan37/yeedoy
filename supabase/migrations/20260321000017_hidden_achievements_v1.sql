alter table public.achievements
  add column if not exists is_hidden boolean not null default false;

update public.achievements
set is_hidden = coalesce(is_hidden, false)
where true;

insert into public.achievements(
  id, title, description, icon, color, xp, is_hidden, condition
)
values
  (
    'silent_follower_20',
    'Sessiz Takipci',
    '20 isletmeye bak, hic yorum yazma',
    'visibility',
    '#64748B',
    35,
    true,
    '{"type":"silent_follower","views":20,"reviews":0}'
  ),
  (
    'night_gourmet_5',
    'Gece Gurmesi',
    '00:00-04:00 arasi 5 mekan incele',
    'bedtime',
    '#1D4ED8',
    45,
    true,
    '{"type":"night_views","value":5}'
  ),
  (
    'menu_archivist_1',
    'Menu Arsivcisi',
    '1 yil eski menude fiyat dogrulama katkisi yap',
    'history_edu',
    '#7C3AED',
    60,
    true,
    '{"type":"stale_menu_update","days":365,"value":1}'
  ),
  (
    'chance_hunter_10',
    'Tesaduf Avcisi',
    'Arama yapmadan kesfetten 10 mekan ac',
    'explore',
    '#F59E0B',
    45,
    true,
    '{"type":"serendipity_click","value":10}'
  ),
  (
    'weekend_wanderer_8',
    'Hafta Sonu Kesfedicisi',
    'Hafta sonu 8 mekan incele',
    'event',
    '#06B6D4',
    35,
    true,
    '{"type":"weekend_business_view","value":8}'
  ),
  (
    'deep_menu_diver_30',
    'Derin Menu Avcisi',
    '30 farkli menu urunu goruntule',
    'restaurant_menu',
    '#10B981',
    40,
    true,
    '{"type":"unique_menu_item_view","value":30}'
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  xp = excluded.xp,
  is_hidden = excluded.is_hidden,
  condition = excluded.condition;

create or replace function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  where not coalesce(a.is_hidden, false)
     or ua.user_id is not null
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
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
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];
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
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];

    if to_regclass('public.menu_items') is not null then
      execute
        'select count(*) from public.menu_item_price_suggestions s
         join public.menu_items mi on mi.id = s.menu_item_id
         where s.created_by = $1
           and s.status = any($2)
           and coalesce(s.is_shadow, false) = false
           and mi.updated_at <= now() - interval ''365 days'''
        into v_stale_updates using p_user_id, array['approved','accepted','handled','verified'];
    end if;
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos
       where created_by = $1
         and coalesce(is_shadow, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1
         and coalesce(status, '''') = any($2)
         and coalesce(is_shadow, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

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
          and coalesce(r.is_shadow, false) = false
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

  -- Hidden achievements.
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
$$;

create or replace function public.admin_reset_user_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_deleted int := 0;
  v_award_deleted int := 0;
  v_reason text := nullif(trim(p_reason), '');
  v_target_id text := coalesce(p_user_id::text, '') || ':' || coalesce(trim(p_achievement_id), '');
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'bad_request');
  end if;

  delete from public.user_achievements ua
  where ua.user_id = p_user_id
    and ua.achievement_id = trim(p_achievement_id);
  get diagnostics v_deleted = row_count;

  delete from public.user_achievement_awards a
  where a.user_id = p_user_id
    and a.achievement_id = trim(p_achievement_id);
  get diagnostics v_award_deleted = row_count;

  perform public.recompute_profile_progress_v1(p_user_id);

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'achievement.reset',
    'user_achievements',
    v_target_id,
    jsonb_build_object(
      'user_id', p_user_id,
      'achievement_id', trim(p_achievement_id),
      'deleted', v_deleted > 0,
      'award_rows_deleted', v_award_deleted,
      'reason', v_reason
    )
  );

  return jsonb_build_object(
    'ok', true,
    'deleted', v_deleted > 0,
    'award_rows_deleted', v_award_deleted
  );
end;
$$;
