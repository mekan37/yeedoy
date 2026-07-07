-- get_my_profile_stats_v1: followers_count eklendi (yeni sütun)
-- DROP gerekiyor çünkü RETURNS TABLE değişiyor (PostgreSQL buna izin vermez CREATE OR REPLACE ile).
-- followers_count: Koleksiyonlar DB'ye taşınınca gerçek sum hesabı gelecek; şimdilik 0.

drop function if exists public.get_my_profile_stats_v1();

create function public.get_my_profile_stats_v1()
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
  with my_reviews as (
    select id, helpful_count
    from public.reviews
    where user_id = auth.uid()
  )
  select
    (select count(*)::int from my_reviews)                                  as reviews_count,
    (select coalesce(sum(helpful_count), 0)::int from my_reviews)           as helpful_received,
    (select count(*)::int from public.favorites where user_id = auth.uid()) as favorites_count,
    (select count(*)::int from public.visits   where user_id = auth.uid())  as visits_count,
    (
      (select count(*)::int from my_reviews) * 5
      + (select coalesce(sum(helpful_count), 0)::int from my_reviews) * 2
      + (select count(*)::int from public.favorites where user_id = auth.uid())
      + (select count(*)::int from public.visits   where user_id = auth.uid()) * 1
    )                                                                        as contribution_score,
    0::integer                                                               as followers_count;
$$;

comment on function public.get_my_profile_stats_v1() is
  'Profil stat kartları özeti. followers_count: şimdilik 0, koleksiyonlar DB taşınınca implementasyon yapılacak. Called by: profile_repository.dart';

revoke all on function public.get_my_profile_stats_v1() from public;
grant execute on function public.get_my_profile_stats_v1() to authenticated;
