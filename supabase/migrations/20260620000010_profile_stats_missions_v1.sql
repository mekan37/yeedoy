-- get_my_profile_stats_v1 ve get_my_weekly_missions_v1
--
-- Eski versiyonsuz RPC'lerin _v1 sürümleri.
-- Flutter profile_repository.dart bu isimleri çağırmaktadır.
-- Eski fonksiyonlara DEPRECATED yorumu eklendi; 90 gün sonra drop planlanabilir.

create or replace function public.get_my_profile_stats_v1()
returns table(
  reviews_count      integer,
  helpful_received   integer,
  favorites_count    integer,
  visits_count       integer,
  contribution_score integer
)
language sql
stable
security definer
set search_path = public
as $$
  with my_reviews as (
    select id, helpful_count
    from public.reviews
    where user_id = auth.uid()
  )
  select
    (select count(*)::int from my_reviews)                               as reviews_count,
    (select coalesce(sum(helpful_count), 0)::int from my_reviews)        as helpful_received,
    (select count(*)::int from public.favorites where user_id = auth.uid()) as favorites_count,
    (select count(*)::int from public.visits   where user_id = auth.uid()) as visits_count,
    (
      (select count(*)::int from my_reviews) * 5
      + (select coalesce(sum(helpful_count), 0)::int from my_reviews) * 2
      + (select count(*)::int from public.favorites where user_id = auth.uid())
      + (select count(*)::int from public.visits   where user_id = auth.uid()) * 1
    )                                                                    as contribution_score;
$$;

comment on function public.get_my_profile_stats_v1() is
  'Oturumdaki kullanıcının profil istatistikleri. Called by: profile_repository.dart';

revoke all on function public.get_my_profile_stats_v1() from public;
grant execute on function public.get_my_profile_stats_v1() to authenticated;

-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.get_my_weekly_missions_v1()
returns table(
  week_start      date,
  reviews_done    integer,
  visits_done     integer,
  votes_done      integer,
  reviews_goal    integer,
  visits_goal     integer,
  votes_goal      integer,
  completed_count integer
)
language sql
stable
security definer
set search_path = public
as $$
  with w as (
    select date_trunc('week', now())::date as week_start
  ),
  reviews as (
    select count(*)::int as c
    from public.reviews r, w
    where r.user_id = auth.uid()
      and r.created_at >= w.week_start
  ),
  visits as (
    select count(*)::int as c
    from public.visits v, w
    where v.user_id = auth.uid()
      and v.created_at >= w.week_start
  ),
  votes as (
    select count(*)::int as c
    from public.review_votes rv, w
    where rv.user_id = auth.uid()
      and rv.created_at >= w.week_start
  )
  select
    (select week_start from w)  as week_start,
    (select c from reviews)     as reviews_done,
    (select c from visits)      as visits_done,
    (select c from votes)       as votes_done,
    1                           as reviews_goal,
    3                           as visits_goal,
    3                           as votes_goal,
    (
      (case when (select c from reviews) >= 1 then 1 else 0 end) +
      (case when (select c from visits)  >= 3 then 1 else 0 end) +
      (case when (select c from votes)   >= 3 then 1 else 0 end)
    )::int                      as completed_count;
$$;

comment on function public.get_my_weekly_missions_v1() is
  'Oturumdaki kullanıcının haftalık görev ilerlemesi. Called by: profile_repository.dart';

revoke all on function public.get_my_weekly_missions_v1() from public;
grant execute on function public.get_my_weekly_missions_v1() to authenticated;

-- Eski versiyonsuz fonksiyonlara DEPRECATED yorumu
comment on function public.get_my_profile_stats() is
  'DEPRECATED 2026-06-20: use get_my_profile_stats_v1';
comment on function public.get_my_weekly_missions() is
  'DEPRECATED 2026-06-20: use get_my_weekly_missions_v1';
