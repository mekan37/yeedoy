-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: 20260707000003_business_badges_reviews_v4
-- Purpose:
--   1. get_business_badges_v1  — instant badge computation for a business
--   2. get_business_reviews_v4 — extends v3 with author's top badge (LEFT JOIN LATERAL)
--   3. DEPRECATED comment on get_business_reviews_v3
-- ─────────────────────────────────────────────────────────────────────────────


-- ═══════════════════════════════════════════════════════════════════════════
-- 1. get_business_badges_v1
-- ═══════════════════════════════════════════════════════════════════════════

create or replace function public.get_business_badges_v1(p_business_id uuid)
returns table(badge_id text, title text, color text, tier text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_visit_count       integer;
  v_unique_users      integer;
  v_night_pct         numeric;
  v_avg_quality       numeric;
  v_avg_rating        numeric;
  v_quality_count     integer;
  v_photo_count       integer;
  v_menu_count        integer;
  v_price_count       integer;
  v_price_approval    numeric;
  v_is_verified       boolean;
  v_months_active     integer;
  v_week_rank_pct     numeric;
  v_month_unique      integer;
begin
  -- Ziyaret sayıları
  select count(*)::int, count(distinct user_id)::int
  into v_visit_count, v_unique_users
  from public.visits
  where business_id = p_business_id;

  -- Gece ziyaret oranı (20:00+)
  select
    case when v_visit_count > 0
      then (count(*) filter (where extract(hour from checked_in_at) >= 20))::numeric / v_visit_count
      else 0 end
  into v_night_pct
  from public.visits
  where business_id = p_business_id;

  -- Kalite ve rating ortalaması
  -- 2026-07-23 fix: reviews.quality_score diye bir kolon hiç olmadı — bu
  -- fonksiyon (LANGUAGE plpgsql olduğu için CREATE sırasında değil, ancak
  -- fiilen çağrıldığında) her zaman hata fırlatıyordu, yani quality_score'a
  -- bağlı rozetler ("Kaliteli Yorum Mekanı", "Gurme Seçimi", "Sadık
  -- Topluluk") hiçbir zaman gerçekten hesaplanamadı/verilemedi. Normalize
  -- edilmiş bir kalite skoru için gerçek bir kaynak olmadığından,
  -- v_avg_quality ve v_quality_count kasıtlı olarak 0 bırakıldı — bu üç
  -- rozet koşulu hiç tetiklenmez, mevcut/tarihsel "hiç verilmedi" durumunu
  -- korur, yeni bir ürün kararı icat etmez.
  v_avg_quality := 0;
  v_quality_count := 0;

  select coalesce(avg(rating), 0)
  into v_avg_rating
  from public.reviews
  where business_id = p_business_id and status = 'approved';

  -- Fotoğraf sayısı (business_media tablosu - approved)
  select count(*)::int into v_photo_count
  from public.business_media
  where business_id = p_business_id and status = 'approved';

  -- Menü öğe sayısı (fiyatı olan)
  select count(*)::int into v_menu_count
  from public.menu_items
  where business_id = p_business_id and price_cents is not null;

  -- Fiyat katkısı sayısı ve onay oranı
  select
    count(*)::int,
    case when count(*) > 0
      then (count(*) filter (where status = 'approved'))::numeric / count(*)
      else 0 end
  into v_price_count, v_price_approval
  from public.menu_item_price_suggestions
  where business_id = p_business_id;

  -- Doğrulanmış işletme?
  select exists(
    select 1 from public.owner_claims
    where business_id = p_business_id and status = 'approved'
  ) into v_is_verified;

  -- Kaç ay aktif? (ilk ziyaretten itibaren)
  select coalesce(ceil(extract(epoch from (now() - min(checked_in_at))) / 2592000)::int, 0)
  into v_months_active
  from public.visits
  where business_id = p_business_id;

  -- Aylık benzersiz ziyaretçi (son 30 gün)
  select count(distinct user_id)::int into v_month_unique
  from public.visits
  where business_id = p_business_id
    and checked_in_at >= now() - interval '30 days';

  -- Haftalık percentile rank: bu işletme son 7 günde tüm işletmeler arasında kaçıncı %'de?
  -- percent_rank() = 0..1; >=0.9 → top 10%
  select coalesce(
    (
      select pct_rank
      from (
        select business_id,
               percent_rank() over (order by cnt) as pct_rank
        from (
          select business_id, count(*) as cnt
          from public.visits
          where checked_in_at >= now() - interval '7 days'
          group by business_id
        ) weekly_counts
      ) ranked
      where business_id = p_business_id
    ),
    0
  ) into v_week_rank_pct;

  -- ── Badge koşulları ──────────────────────────────────────────────────────
  -- 2026-07-23 fix: "return next row(...)" geçersiz PL/pgSQL sözdizimiydi —
  -- RETURNS TABLE(...) OUT parametreli bir fonksiyonda RETURN NEXT parametre
  -- alamaz; OUT değişkenlerine atama yapıp boş RETURN NEXT çağrılması gerekir.

  if coalesce(v_week_rank_pct, 0) >= 0.9 then
    badge_id := 'biz_weekly_top'; title := 'Haftanın Favorisi'; color := '#B45309'; tier := 'gold';
    return next;
  end if;

  if coalesce(v_month_unique, 0) >= 200 then
    badge_id := 'biz_monthly_star'; title := 'Aylık Yıldız'; color := '#D97706'; tier := 'gold';
    return next;
  end if;

  if coalesce(v_unique_users, 0) >= 50 then
    badge_id := 'biz_explorer_magnet'; title := 'Keşifçi Mıknatısı'; color := '#0284C7'; tier := 'silver';
    return next;
  end if;

  if coalesce(v_night_pct, 0) >= 0.4 and coalesce(v_visit_count, 0) >= 20 then
    badge_id := 'biz_night_hub'; title := 'Gece Hayatı Merkezi'; color := '#6D28D9'; tier := 'special';
    return next;
  end if;

  if coalesce(v_avg_quality, 0) >= 0.75 and coalesce(v_quality_count, 0) >= 5 then
    badge_id := 'biz_quality_reviews'; title := 'Kaliteli Yorum Mekanı'; color := '#B45309'; tier := 'gold';
    return next;
  end if;

  if coalesce(v_quality_count, 0) >= 5 and coalesce(v_avg_rating, 0) >= 4.2 then
    badge_id := 'biz_gourmet_pick'; title := 'Gurme Seçimi'; color := '#D97706'; tier := 'gold';
    return next;
  end if;

  if coalesce(v_photo_count, 0) >= 20 then
    badge_id := 'biz_photo_rich'; title := 'Fotoğraf Zengini'; color := '#0891B2'; tier := 'silver';
    return next;
  end if;

  if coalesce(v_menu_count, 0) >= 30 then
    badge_id := 'biz_rich_menu'; title := 'Zengin Menü'; color := '#0369A1'; tier := 'silver';
    return next;
  end if;

  if coalesce(v_price_count, 0) >= 10 then
    badge_id := 'biz_price_transparent'; title := 'Fiyat Şeffaflığı'; color := '#15803D'; tier := 'bronze';
    return next;
  end if;

  if coalesce(v_price_approval, 0) >= 0.8 and coalesce(v_price_count, 0) >= 5 then
    badge_id := 'biz_trusted_data'; title := 'Güvenilir Veri'; color := '#0E7490'; tier := 'silver';
    return next;
  end if;

  if coalesce(v_is_verified, false) then
    badge_id := 'biz_verified'; title := 'Doğrulanmış Mekan'; color := '#7C3AED'; tier := 'special';
    return next;
  end if;

  if coalesce(v_months_active, 0) >= 12 then
    badge_id := 'biz_veteran_1y'; title := 'Köklü Mekan'; color := '#92400E'; tier := 'gold';
    return next;
  end if;

  if coalesce(v_months_active, 0) >= 24 and coalesce(v_quality_count, 0) >= 3 then
    badge_id := 'biz_loyal_community'; title := 'Sadık Topluluk'; color := '#78350F'; tier := 'gold';
    return next;
  end if;
end;
$$;

revoke all on function public.get_business_badges_v1(uuid) from public;
grant execute on function public.get_business_badges_v1(uuid) to anon, authenticated;
comment on function public.get_business_badges_v1 is
  'İşletme başarım rozetlerini hesaplar. MVP: anında hesaplanır. Called by: business_badges_repository.dart, BusinessBadges.tsx';


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. get_business_reviews_v4
--    Extends v3 with author's top badge via LEFT JOIN LATERAL on user_achievements.
--    New params: p_min_rating (filter by minimum rating), p_verified (filter verified only).
-- ═══════════════════════════════════════════════════════════════════════════

create or replace function public.get_business_reviews_v4(
  p_business_id  uuid,
  p_sort         text    default 'recent',
  p_limit        integer default 20,
  p_offset       integer default 0,
  p_min_rating   integer default null,
  p_verified     boolean default null
)
returns table (
  id                 uuid,
  business_id        uuid,
  user_id            uuid,
  rating             integer,
  title              text,
  content            text,
  helpful_count      integer,
  created_at         timestamptz,
  status             text,
  quality_score      numeric,
  verified_visit     boolean,
  r_taste            integer,
  r_service          integer,
  r_price_value      integer,
  r_cleanliness      integer,
  r_atmosphere       integer,
  -- v4 additions: author's top badge
  author_badge_id    text,
  author_badge_title text,
  author_badge_color text,
  author_badge_tier  text
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      coalesce(r.helpful_count, 0)::integer          as helpful_count,
      r.created_at,
      coalesce(r.status, 'published')                as status,
      -- 2026-07-23 fix: reviews.quality_score diye bir kolon hiç olmadı;
      -- 20260523000005_perf_rpc_query_fixes.sql'deki established convention
      -- ile aynı — helpful_count quality_score yerine kullanılıyor.
      coalesce(r.helpful_count, 0)::numeric           as quality_score,
      -- Inline verified_visit check using composite index (avoids N+1 per-row call)
      exists (
        select 1
        from public.visits v
        where v.user_id     = r.user_id
          and v.business_id = r.business_id
          and v.checked_in_at >= date_trunc('day', r.created_at)
          and v.checked_in_at <  date_trunc('day', r.created_at) + interval '1 day'
      )                                              as verified_visit,
      rr.r_taste,
      rr.r_service,
      rr.r_price_value,
      rr.r_cleanliness,
      rr.r_atmosphere
    from public.reviews r
    left join public.review_ratings rr on rr.review_id = r.id
    where r.business_id = p_business_id
      and coalesce(r.status, 'published') not in ('rejected', 'spam')
      and (p_min_rating is null or r.rating >= p_min_rating)
  )
  select
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score,
    b.verified_visit,
    b.r_taste,
    b.r_service,
    b.r_price_value,
    b.r_cleanliness,
    b.r_atmosphere,
    top_badge.id    as author_badge_id,
    top_badge.title as author_badge_title,
    top_badge.color as author_badge_color,
    top_badge.tier  as author_badge_tier
  from base b
  left join lateral (
    select a.id, a.title, a.color, a.condition->>'tier' as tier
    from public.user_achievements ua
    join public.achievements a on a.id = ua.achievement_id
    where ua.user_id = b.user_id
    order by a.xp desc
    limit 1
  ) top_badge on true
  where (p_verified is null or b.verified_visit = p_verified)
  order by
    case when lower(coalesce(p_sort, 'recent')) = 'verified'
      then (b.verified_visit)::int else null end desc,
    case when lower(coalesce(p_sort, 'recent')) = 'helpful'
      then b.quality_score else null end desc,
    case when lower(coalesce(p_sort, 'recent')) = 'helpful'
      then b.helpful_count else null end desc,
    b.created_at desc
  limit  greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

revoke all on function public.get_business_reviews_v4(uuid, text, integer, integer, integer, boolean) from public;
grant execute on function public.get_business_reviews_v4(uuid, text, integer, integer, integer, boolean) to anon, authenticated, service_role;
comment on function public.get_business_reviews_v4 is
  'v4: author top badge JOIN eklendi. Called by: reviews_repository.dart';


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Deprecate get_business_reviews_v3
-- ═══════════════════════════════════════════════════════════════════════════

comment on function public.get_business_reviews_v3(uuid, text, integer, integer) is
  'DEPRECATED 2026-07-07: use get_business_reviews_v4. Remove after 2026-10-07.
   Business reviews with multi-criterion ratings and verified_visit flag.
   p_sort: newest | helpful | verified.';
