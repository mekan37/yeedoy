insert into public.achievements (
  id,
  title,
  description,
  icon,
  color,
  xp,
  is_hidden,
  condition
)
values (
  'pizza_master_10',
  'Pizza Ustasi',
  '10 farkli pizza mekanini puanla',
  'local_pizza',
  '#F97316',
  55,
  false,
  '{"type":"category_unique_rated_business_count","category":"pizza","value":10}'::jsonb
)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  xp = excluded.xp,
  is_hidden = excluded.is_hidden,
  condition = excluded.condition;
drop function if exists public.get_my_achievements_v2();
create function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz,
  current_value int,
  target_value int
)
language sql
security definer
set search_path to 'public'
as $$
  with me as (
    select auth.uid() as uid
  ),
  metrics as (
    select
      (select count(*)::int
       from public.reviews r, me
       where r.user_id = me.uid
         and r.status = any(array['approved','published'])) as review_count,
      (select count(*)::int
       from public.analytics_events e, me
       where e.user_id = me.uid
         and e.event_name = any(array['discovery_business_click', 'business_view', 'business_page_view'])) as business_view_count,
      (select count(*)::int
       from public.menu_item_price_suggestions s, me
       where s.created_by = me.uid
         and s.status::text = any(array['approved','accepted','handled','verified'])) as price_verified_count,
      coalesce(public.get_my_reputation_score_v1(), 0)::int as reputation_score
  )
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at,
    coalesce(
      case (a.condition->>'type')
        when 'review_count' then m.review_count
        when 'business_view_count' then m.business_view_count
        when 'price_verified_count' then m.price_verified_count
        when 'reputation_score' then m.reputation_score
        when 'unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r, me
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
        )
        when 'category_unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r
          join public.businesses b on b.id = r.business_id
          join me on true
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
            and lower(coalesce(b.category, '')) like '%' || lower(coalesce(a.condition->>'category', '')) || '%'
        )
        else null
      end,
      case when ua.user_id is not null then coalesce((a.condition->>'value')::int, 0) else 0 end
    ) as current_value,
    coalesce((a.condition->>'value')::int, 0) as target_value
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  cross join metrics m
  where not coalesce(a.is_hidden, false)
     or ua.user_id is not null
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;
create or replace function public.get_my_daily_micro_task_v1()
returns table(
  task_key text,
  title text,
  description text,
  current_value int,
  target_value int,
  completed boolean
)
language sql
security definer
set search_path to 'public'
as $$
  with me as (
    select auth.uid() as uid
  ),
  d as (
    select (extract(doy from now() at time zone 'Europe/Istanbul')::int % 3) as idx
  ),
  metrics as (
    select
      (select count(*)::int
       from public.menu_item_price_suggestions s, me
       where s.created_by = me.uid
        and s.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')
        and s.status::text = any(array['approved','accepted','handled','verified'])) as price_verified_today,
      (select count(*)::int
       from public.analytics_events e, me
       where e.user_id = me.uid
         and e.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')
         and e.event_name = any(array['discovery_business_click', 'business_page_view', 'business_view'])) as discovered_today,
      (select count(*)::int
       from public.review_votes v, me
       where v.user_id = me.uid
         and v.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')) as helpful_today
  )
  select
    case d.idx
      when 0 then 'verify_price_once'
      when 1 then 'discover_business_once'
      else 'helpful_vote_once'
    end as task_key,
    case d.idx
      when 0 then 'Bugün 1 fiyat doğrula'
      when 1 then 'Bugün yeni bir mekan keşfet'
      else 'Bugün bir yorumu faydalı bul'
    end as title,
    case d.idx
      when 0 then '10 saniye sürer, veri kalitesini artırır.'
      when 1 then 'Kısa bir keşif, öneri kalitesine katkı sağlar.'
      else 'Kaliteli yorumu öne çıkar, topluluğa destek ol.'
    end as description,
    case d.idx
      when 0 then least(m.price_verified_today, 1)
      when 1 then least(m.discovered_today, 1)
      else least(m.helpful_today, 1)
    end as current_value,
    1 as target_value,
    case d.idx
      when 0 then m.price_verified_today >= 1
      when 1 then m.discovered_today >= 1
      else m.helpful_today >= 1
    end as completed
  from d
  cross join metrics m;
$$;
grant execute on function public.get_my_daily_micro_task_v1() to authenticated;
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
  v_pizza_unique_rated_count int := 0;
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

    if to_regclass('public.businesses') is not null then
      execute
        'select count(distinct r.business_id)
         from public.reviews r
         join public.businesses b on b.id = r.business_id
         where r.user_id = $1
           and r.rating is not null
           and r.business_id is not null
           and r.status = any($2)
           and coalesce(r.is_shadow, false) = false
           and lower(coalesce(b.category, '''')) like ''%pizza%'''
        into v_pizza_unique_rated_count using p_user_id, array['approved','published'];
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
  if v_pizza_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'pizza_master_10');
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
