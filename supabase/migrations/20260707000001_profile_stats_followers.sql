-- get_my_profile_stats_v1: followers_count eklendi (favorite_collections toplamı)
create or replace function public.get_my_profile_stats_v1()
returns table(
  reviews_count      integer,
  helpful_received   integer,
  favorites_count    integer,
  visits_count       integer,
  contribution_score integer,
  followers_count    integer
)
language sql
stable
security definer
set search_path = public
as $$
  with uid as (select auth.uid() as id),
       my_reviews as (
         select id, helpful_count
         from public.reviews
         where user_id = (select id from uid)
       )
  select
    (select count(*)::int from my_reviews)                                        as reviews_count,
    (select coalesce(sum(helpful_count), 0)::int from my_reviews)                 as helpful_received,
    (select count(*)::int from public.favorites
       where user_id = (select id from uid))                                      as favorites_count,
    (select count(*)::int from public.visits
       where user_id = (select id from uid))                                      as visits_count,
    (
      select coalesce(
        (select count(*)::int * 10 from my_reviews)
        + (select count(*)::int * 5 from public.visits where user_id = (select id from uid))
        + (select count(*)::int * 3 from public.favorites where user_id = (select id from uid)),
        0
      )
    )                                                                             as contribution_score,
    (select coalesce(sum(followers_count), 0)::int
       from public.favorite_collections
       where user_id = (select id from uid))                                      as followers_count;
$$;

revoke all on function public.get_my_profile_stats_v1() from public;
grant execute on function public.get_my_profile_stats_v1() to authenticated;
comment on function public.get_my_profile_stats_v1 is
  'Profil stat kartları için özet. v1: followers_count eklendi 2026-07-07. Called by: profile_repository.dart';
