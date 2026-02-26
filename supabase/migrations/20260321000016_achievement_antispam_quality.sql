create table if not exists public.user_achievement_awards (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  award_date date not null default (now() at time zone 'utc')::date,
  awarded_at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb,
  primary key (user_id, achievement_id, award_date)
);

alter table public.user_achievement_awards enable row level security;

drop policy if exists user_achievement_awards_read_own on public.user_achievement_awards;
create policy user_achievement_awards_read_own
on public.user_achievement_awards
for select
to authenticated
using (user_id = auth.uid());

create index if not exists user_achievement_awards_user_idx
  on public.user_achievement_awards(user_id, awarded_at desc);

create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted int := 0;
  v_title text;
  v_xp int := 20;
  v_progress record;
  v_today date := (now() at time zone 'utc')::date;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  -- Anti-spam: same achievement can never be awarded twice in the same UTC day.
  if exists (
    select 1
    from public.user_achievement_awards a
    where a.user_id = p_user_id
      and a.achievement_id = trim(p_achievement_id)
      and a.award_date = v_today
  ) then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false;
  end if;

  insert into public.user_achievement_awards(user_id, achievement_id, award_date, meta)
  values (p_user_id, trim(p_achievement_id), v_today, coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  select a.title, coalesce(a.xp, 20)
    into v_title, v_xp
  from public.achievements a
  where a.id = trim(p_achievement_id);

  select *
    into v_progress
  from public.apply_profile_xp_v1(p_user_id, v_xp);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp,
        'level', coalesce(v_progress.level, 1),
        'total_xp', coalesce(v_progress.total_xp, v_xp),
        'leveled_up', coalesce(v_progress.leveled_up, false)
      )
    );
  end if;

  return true;
end;
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
begin
  if p_user_id is null then
    return;
  end if;

  -- Only approved/published non-shadow reviews are quality signals.
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
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view'];
  end if;

  -- Rejected or shadowed suggestions must not contribute.
  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos
       where created_by = $1
         and coalesce(is_shadow, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  -- Only validly closed reports count; open/noise reports do not.
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
      'reason', v_reason
    )
  );

  return jsonb_build_object('ok', true, 'deleted', v_deleted > 0);
end;
$$;

grant execute on function public.admin_reset_user_achievement_v1(uuid, text, text) to authenticated;
