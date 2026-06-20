-- businesses_with_stats_mv: neighborhood kolonu eklendi
-- get_business_detail_v1: dönen JSON'a neighborhood dahil edildi
--
-- Flutter modeli (BusinessDetail, Business) zaten neighborhood: m['neighborhood'] as String?
-- parse ediyor; RPC dönmediği için daima null geliyordu. Bu migration ile
-- businesses.neighborhood -> view -> RPC -> model zinciri tamamlanıyor.

-- 1. businesses_with_stats_mv view'una neighborhood ekle
create or replace view public.businesses_with_stats_mv
with (security_invoker = true) as
select
  b.id,
  b.name,
  b.category,
  b.address,
  b.city,
  b.district,
  b.neighborhood,
  b.lat,
  b.lng,
  b.geog,
  coalesce(s.approved_reviews_count, 0)                              as reviews_count,
  case
    when coalesce(s.approved_reviews_count, 0) = 0 then 0::double precision
    else s.approved_rating_sum::double precision / s.approved_reviews_count::double precision
  end                                                                  as avg_rating,
  s.last_review_at
from public.businesses b
left join public.business_stats s on s.business_id = b.id;

comment on view public.businesses_with_stats_mv is
  'DEPRECATED: legacy view; NOT a drop candidate; verify external usage';

-- 2. get_business_detail_v1: neighborhood'ı v_stats JSON'una ekle
create or replace function public.get_business_detail_v1(
  p_business_id uuid,
  p_latest_reviews_limit integer default 5
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stats  jsonb;
  v_hist   jsonb;
  v_latest jsonb;
begin
  select to_jsonb(s)
  into v_stats
  from (
    select
      m.id,
      m.name,
      m.category,
      m.address,
      m.city,
      m.district,
      m.neighborhood,
      m.lat,
      m.lng,
      m.avg_rating,
      m.reviews_count
    from public.businesses_with_stats_mv m
    where m.id = p_business_id
    limit 1
  ) s;

  if v_stats is null then
    return jsonb_build_object('ok', false, 'error', 'business_not_found');
  end if;

  select jsonb_build_object(
    '5', coalesce(bs.rating_5, 0),
    '4', coalesce(bs.rating_4, 0),
    '3', coalesce(bs.rating_3, 0),
    '2', coalesce(bs.rating_2, 0),
    '1', coalesce(bs.rating_1, 0)
  )
  into v_hist
  from public.business_stats bs
  where bs.business_id = p_business_id;

  if v_hist is null then
    v_hist := jsonb_build_object('5', 0, '4', 0, '3', 0, '2', 0, '1', 0);
  end if;

  select coalesce(jsonb_agg(to_jsonb(r)), '[]'::jsonb)
  into v_latest
  from (
    select
      id,
      business_id,
      user_id,
      rating,
      title,
      content,
      helpful_count,
      created_at
    from public.reviews
    where business_id = p_business_id
      and status = 'approved'
    order by created_at desc
    limit greatest(p_latest_reviews_limit, 0)
  ) r;

  return jsonb_build_object(
    'ok',              true,
    'stats',           v_stats,
    'rating_breakdown', v_hist,
    'latest_reviews',  v_latest
  );
end;
$$;

comment on function public.get_business_detail_v1(uuid, integer) is
  'İşletme detayı + rating breakdown + son yorumlar. Called by: business_detail_repository.dart';
