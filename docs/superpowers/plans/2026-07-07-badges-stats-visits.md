# Rozet Sistemi, Stat Kartları, Ziyaret Takibi — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Profil stat kartlarını 5'e çıkar ve tıklanabilir yap; işletme açılışında ziyaret kaydı tut; kullanıcılara metalik tier rozet sistemi ekle; işletmelere TripAdvisor tarzı başarım rozetleri ve paylaşılabilir sertifika ekle.

**Architecture:** Üç Supabase migration (profile_stats, achievements, business_badges+reviews_v4), Flutter mobile değişiklikleri (model → domain → UI), minimal Next.js bileşeni (business badge chips). İşletme rozetleri anında hesaplanır (MVP), cache sonradan eklenir.

**Tech Stack:** Flutter 3 + Riverpod, Supabase PostgreSQL RPC, GoRouter, Next.js 15 App Router, `package:share_plus`

---

## Dosya Haritası

| Durum | Dosya |
|---|---|
| Yeni | `supabase/migrations/20260707000001_profile_stats_followers.sql` |
| Yeni | `supabase/migrations/20260707000002_achievements_extended.sql` |
| Yeni | `supabase/migrations/20260707000003_business_badges_reviews_v4.sql` |
| Değişti | `uygulamalar/mobil/lib/features/profile/domain/profile_stats.dart` |
| Değişti | `uygulamalar/mobil/lib/features/profile/data/profile_repository.dart` |
| Değişti | `uygulamalar/mobil/lib/features/profile/domain/achievement.dart` |
| Yeni | `uygulamalar/mobil/lib/features/profile/ui/my_visits_page.dart` |
| Değişti | `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` |
| Değişti | `uygulamalar/mobil/lib/features/shared/ui/achievements/achievement_visuals.dart` |
| Değişti | `uygulamalar/mobil/lib/features/reviews/domain/review.dart` |
| Değişti | `uygulamalar/mobil/lib/features/reviews/data/reviews_repository.dart` |
| Değişti | `uygulamalar/mobil/lib/features/reviews/ui/business_reviews_page.dart` |
| Değişti | `uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart` |
| Değişti | `uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart` |
| Yeni | `uygulamalar/mobil/lib/features/business/data/business_badges_repository.dart` |
| Yeni | `uygulamalar/mobil/lib/features/business/domain/business_badges_provider.dart` |
| Yeni | `uygulamalar/mobil/lib/features/business/ui/business_badge_certificate.dart` |
| Değişti | `uygulamalar/mobil/lib/app/router.dart` |
| Yeni | `uygulamalar/web/src/ui/business/BusinessBadges.tsx` |
| Yeni | `uygulamalar/web/src/lib/businessBadges.ts` |

---

### Task 1: DB — profile_stats v1'e followers_count ekle

**Files:**
- Create: `supabase/migrations/20260707000001_profile_stats_followers.sql`

Bu task `get_my_profile_stats_v1` fonksiyonunu `followers_count` alanıyla güncelleyen migration'ı yazar. Mevcut fonksiyon `supabase/migrations/20260620000010_profile_stats_missions_v1.sql` içinde tanımlı.

- [ ] **Step 1: Migration dosyasını oluştur**

`supabase/migrations/20260707000001_profile_stats_followers.sql` dosyasını oluştur:

```sql
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
```

- [ ] **Step 2: Migration'ı uygula**

```bash
supabase db reset
# veya sadece yeni migration için:
supabase migration up
```

Beklenen: hata yok, fonksiyon güncellenmiş.

- [ ] **Step 3: Fonksiyonu test et**

Supabase SQL Editor'da (authenticated kullanıcı olarak):
```sql
select * from get_my_profile_stats_v1();
```

Beklenen: 6 sütun döner, `followers_count` dahil.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260707000001_profile_stats_followers.sql
git commit -m "feat(db): get_my_profile_stats_v1 — followers_count eklendi"
```

---

### Task 2: DB — Yeni rozetler ekle (achievements_extended)

**Files:**
- Create: `supabase/migrations/20260707000002_achievements_extended.sql`

`achievements` tablosuna 28 kullanıcı rozetinin eksik olanlarını INSERT eder. Tier bilgisi `condition` JSONB alanına `{"tier": "bronze"}` şeklinde eklenir (tabloda `tier` sütunu yok, bu JSONB pattern mevcut yapıya uyumlu).

- [ ] **Step 1: Migration dosyasını oluştur**

`supabase/migrations/20260707000002_achievements_extended.sql` içeriği:

```sql
-- Yeni rozetleri ekle (varsa güncelle). tier → condition JSONB içinde saklanır.
-- INSERT OR IGNORE pattern: id unique constraint'e göre çakışmada atlanır.

insert into public.achievements
  (id, title, description, icon, color, xp, is_hidden, condition)
values
  -- Ziyaret
  ('first_visit',      'İlk Adım',                 '1. işletme ziyareti',                          'location-dot',  '#78716C', 20,  false, '{"type":"visit_count","target":1,"tier":"bronze"}'),
  ('explorer_5',       'Kaşif',                     '5 farklı işletme ziyareti',                    'compass',       '#0D9488', 40,  false, '{"type":"visit_count","target":5,"tier":"bronze"}'),
  ('district_15',      'Semt Turisti',              '15 farklı işletme ziyareti',                   'map',           '#0891B2', 80,  false, '{"type":"visit_count","target":15,"tier":"silver"}'),
  ('city_50',          'Şehir Gezgini',             '50 farklı işletme ziyareti',                   'city',          '#B45309', 200, false, '{"type":"visit_count","target":50,"tier":"gold"}'),
  ('night_gourmet_10', 'Gece Kuşu',                 '10 ziyaret 20:00+ saatte',                     'moon',          '#6D28D9', 100, false, '{"type":"night_visit","target":10,"tier":"silver"}'),
  -- Yorum & Katkı
  ('reviewer_5',       'Anlatıcı',                  '5 yorum yaz',                                  'comment',       '#16A34A', 50,  false, '{"type":"review_count","target":5,"tier":"bronze"}'),
  ('gourmet_pen_20',   'Gurme Kalemi',              '20 yorum yaz',                                 'pen-nib',       '#0284C7', 120, false, '{"type":"review_count","target":20,"tier":"silver"}'),
  ('legend_reviewer_50','Efsane Yorumcu',           '50 yorum yaz',                                 'feather',       '#B45309', 300, false, '{"type":"review_count","target":50,"tier":"gold"}'),
  ('quality_voice',    'Kaliteli Ses',              '3+ kaliteli yorum (quality_score ≥ 0.75)',     'star',          '#D97706', 150, false, '{"type":"quality_review","target":3,"tier":"gold"}'),
  ('helpful_10',       'Beğenilen',                 '10 kişi yorumunu faydalı buldu',               'thumbs-up',     '#0369A1', 100, false, '{"type":"helpful_count","target":10,"tier":"silver"}'),
  -- Fiyat & Veri
  ('price_detective_5','Fiyat Dedektifi',           '5 fiyat katkısı',                              'tags',          '#15803D', 50,  false, '{"type":"price_count","target":5,"tier":"bronze"}'),
  ('budget_expert_20', 'Bütçe Uzmanı',              '20 onaylı fiyat katkısı',                      'coins',         '#0E7490', 120, false, '{"type":"price_count","target":20,"tier":"silver"}'),
  ('price_champion_50','Fiyat Şampiyonu',           '50 onaylı fiyat katkısı',                      'trophy',        '#92400E', 300, false, '{"type":"price_count","target":50,"tier":"gold"}'),
  ('accuracy_90',      'Doğrulukçu',               '%90+ onay oranı (≥10 katkı)',                  'bullseye',      '#B45309', 200, false, '{"type":"price_accuracy","target":90,"tier":"gold"}'),
  -- Fotoğraf
  ('lens_3',           'Objektif',                  '3 fotoğraf yükle',                             'camera',        '#6B7280', 30,  false, '{"type":"photo_count","target":3,"tier":"bronze"}'),
  ('viewfinder_15',    'Vizör',                     '15 fotoğraf yükle',                            'image',         '#0284C7', 100, false, '{"type":"photo_count","target":15,"tier":"silver"}'),
  ('photo_master_50',  'Fotoğraf Ustası',           '50 fotoğraf yükle',                            'camera-retro',  '#92400E', 280, false, '{"type":"photo_count","target":50,"tier":"gold"}'),
  -- Sosyal
  ('first_follower',   'İlk Takipçi',              'İlk koleksiyon takipçisi',                     'user-plus',     '#6D28D9', 30,  false, '{"type":"follower_count","target":1,"tier":"bronze"}'),
  ('social_5',         'Sosyal Kelebek',            '5 koleksiyon takipçisi',                       'users',         '#7C3AED', 100, false, '{"type":"follower_count","target":5,"tier":"silver"}'),
  ('community_star_20','Topluluk Yıldızı',          '20 koleksiyon takipçisi',                      'star',          '#5B21B6', 300, false, '{"type":"follower_count","target":20,"tier":"gold"}'),
  -- Gizli / Özel
  ('chance_hunter_3',  'Şans Avcısı',              '3 kampanya kullanımı',                         'compass',       '#F9A825', 60,  true,  '{"type":"campaign_use","target":3,"tier":"special"}'),
  ('silent_quality_10','Sessiz Kalite',             'Hiç reddedilmeden 10 katkı',                  'shield-halved', '#374151', 150, true,  '{"type":"silent_quality","target":10,"tier":"special"}'),
  ('night_gourmet_5',  'Gece Gurme',               '5 gece ziyareti + yorum',                     'moon',          '#283593', 120, true,  '{"type":"night_review","target":5,"tier":"special"}')
on conflict (id) do update
  set title       = excluded.title,
      description = excluded.description,
      icon        = excluded.icon,
      color       = excluded.color,
      xp          = excluded.xp,
      is_hidden   = excluded.is_hidden,
      condition   = excluded.condition;

-- Mevcut rozetlerin tier bilgisini de condition'a ekle (yoksa)
update public.achievements
set condition = condition || '{"tier":"bronze"}'::jsonb
where id in ('first_review','first_rating','first_discovery','price_hunter_5',
             'observer_3','lens_3','price_detective_5','explorer_5',
             'reviewer_5','weekend_wanderer_8')
  and not (condition ? 'tier');

update public.achievements
set condition = condition || '{"tier":"silver"}'::jsonb
where id in ('traveler_10','helpful_10','district_15','night_gourmet_10',
             'viewfinder_15','budget_expert_20','social_5','gourmet_pen_20',
             'district_gourmet_top10','detective_10')
  and not (condition ? 'tier');

update public.achievements
set condition = condition || '{"tier":"gold"}'::jsonb
where id in ('city_50','legend_reviewer_50','quality_voice','price_champion_50',
             'accuracy_90','photo_master_50','community_star_20',
             'trusted_contributor','pizza_master_10','deep_menu_diver_30',
             'combo_price_streak_3','combo_district_master_5','combo_full_contributor')
  and not (condition ? 'tier');

update public.achievements
set condition = condition || '{"tier":"special"}'::jsonb
where id in ('silent_follower_20','menu_archivist_1','chance_hunter_10',
             'night_gourmet_5','chance_hunter_3','silent_quality_10')
  and not (condition ? 'tier');
```

- [ ] **Step 2: Migration'ı uygula**

```bash
supabase migration up
```

Beklenen: hata yok. `achievements` tablosunda 30+ satır.

- [ ] **Step 3: Veriyi doğrula**

```sql
select id, title, condition->>'tier' as tier from achievements order by id;
```

Beklenen: Her satırda `tier` değeri var.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260707000002_achievements_extended.sql
git commit -m "feat(db): rozet listesi genişletildi, tier condition JSONB'ye eklendi"
```

---

### Task 3: DB — get_business_badges_v1 + get_business_reviews_v4

**Files:**
- Create: `supabase/migrations/20260707000003_business_badges_reviews_v4.sql`

İki yeni RPC: (1) işletme rozetlerini hesaplayan `get_business_badges_v1`, (2) yorum listesine yazar top badge JOIN'i ekleyen `get_business_reviews_v4`. V3 deprecated comment alır.

- [ ] **Step 1: Migration dosyasını oluştur**

`supabase/migrations/20260707000003_business_badges_reviews_v4.sql`:

```sql
-- ── get_business_badges_v1 ────────────────────────────────────────────────────
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
  select
    count(*)::int,
    count(distinct user_id)::int
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
  select
    coalesce(avg(quality_score), 0),
    coalesce(avg(rating), 0),
    count(*) filter (where quality_score >= 0.75)
  into v_avg_quality, v_avg_rating, v_quality_count
  from public.reviews
  where business_id = p_business_id and status = 'approved';

  -- Fotoğraf sayısı
  select count(*)::int into v_photo_count
  from public.media
  where business_id = p_business_id and status = 'approved';

  -- Menü öğe sayısı (fiyatı olan)
  select count(*)::int into v_menu_count
  from public.menu_items
  where business_id = p_business_id and price_cents is not null;

  -- Fiyat katkısı onay oranı
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

  -- Kaç ay aktif?
  select ceil(extract(epoch from (now() - min(created_at))) / 2592000)::int
  into v_months_active
  from public.visits
  where business_id = p_business_id;

  -- Aylık benzersiz ziyaretçi (son 30 gün)
  select count(distinct user_id)::int into v_month_unique
  from public.visits
  where business_id = p_business_id
    and checked_in_at >= now() - interval '30 days';

  -- Haftalık rank % (basitleştirilmiş: toplam ziyaret içindeki oran)
  select
    case when total > 0
      then rank_visits::numeric / total
      else 1 end
  into v_week_rank_pct
  from (
    select
      sum(case when v2.business_id = p_business_id then cnt else 0 end) as rank_visits,
      sum(cnt) as total
    from (
      select business_id, count(*) as cnt
      from public.visits
      where checked_in_at >= now() - interval '7 days'
      group by business_id
    ) v2
  ) sub;

  -- ── Rozet koşulları ───────────────────────────────────────────────────────

  -- biz_weekly_top: haftalık ziyarette ilk %10
  if v_week_rank_pct >= 0.9 then
    return next row('biz_weekly_top', 'Haftanın Favorisi', '#B45309', 'gold');
  end if;

  -- biz_monthly_star: ay içinde 200+ benzersiz ziyaret
  if v_month_unique >= 200 then
    return next row('biz_monthly_star', 'Aylık Yıldız', '#D97706', 'gold');
  end if;

  -- biz_explorer_magnet: 50+ benzersiz kullanıcı
  if v_unique_users >= 50 then
    return next row('biz_explorer_magnet', 'Keşifçi Mıknatısı', '#0284C7', 'silver');
  end if;

  -- biz_night_hub: ziyaretlerin %40+ 20:00 sonrası
  if v_night_pct >= 0.4 and v_visit_count >= 20 then
    return next row('biz_night_hub', 'Gece Hayatı Merkezi', '#6D28D9', 'special');
  end if;

  -- biz_quality_reviews: avg quality_score >= 0.75
  if v_avg_quality >= 0.75 and v_quality_count >= 5 then
    return next row('biz_quality_reviews', 'Kaliteli Yorum Mekanı', '#B45309', 'gold');
  end if;

  -- biz_gourmet_pick: 5+ kaliteli yorum + avg rating >= 4.2
  if v_quality_count >= 5 and v_avg_rating >= 4.2 then
    return next row('biz_gourmet_pick', 'Gurme Seçimi', '#D97706', 'gold');
  end if;

  -- biz_photo_rich: 20+ onaylı fotoğraf
  if v_photo_count >= 20 then
    return next row('biz_photo_rich', 'Fotoğraf Zengini', '#0891B2', 'silver');
  end if;

  -- biz_rich_menu: 30+ fiyatlı menü öğesi
  if v_menu_count >= 30 then
    return next row('biz_rich_menu', 'Zengin Menü', '#0369A1', 'silver');
  end if;

  -- biz_price_transparent: 10+ onaylı fiyat katkısı
  if v_price_count >= 10 then
    return next row('biz_price_transparent', 'Fiyat Şeffaflığı', '#15803D', 'bronze');
  end if;

  -- biz_trusted_data: fiyat onay oranı >= %80
  if v_price_approval >= 0.8 and v_price_count >= 5 then
    return next row('biz_trusted_data', 'Güvenilir Veri', '#0E7490', 'silver');
  end if;

  -- biz_verified: owner talebi onaylandı
  if v_is_verified then
    return next row('biz_verified', 'Doğrulanmış Mekan', '#7C3AED', 'special');
  end if;

  -- biz_veteran_1y: 1 yıl+ aktif (12+ ay)
  if v_months_active >= 12 then
    return next row('biz_veteran_1y', 'Köklü Mekan', '#92400E', 'gold');
  end if;

  -- biz_loyal_community: 24+ ay aktif + düzenli yorum
  if v_months_active >= 24 and v_quality_count >= 3 then
    return next row('biz_loyal_community', 'Sadık Topluluk', '#78350F', 'gold');
  end if;
end;
$$;

revoke all on function public.get_business_badges_v1(uuid) from public;
grant execute on function public.get_business_badges_v1(uuid) to anon, authenticated;
comment on function public.get_business_badges_v1 is
  'İşletme rozetlerini hesaplar. MVP: anında hesaplanır. Called by: business_badges_repository.dart, BusinessBadges.tsx';

-- ── get_business_reviews_v4 ───────────────────────────────────────────────────
-- v3'e göre fark: LEFT JOIN ile yazar top badge eklendi (author_badge_* alanları).
-- v3: 90 gün deprecated.

create or replace function public.get_business_reviews_v4(
  p_business_id uuid,
  p_limit       integer default 20,
  p_offset      integer default 0,
  p_sort        text    default 'recent',  -- 'recent' | 'helpful' | 'verified'
  p_min_rating  integer default null,
  p_verified    boolean default null
)
returns table(
  id               uuid,
  business_id      uuid,
  user_id          uuid,
  rating           integer,
  title            text,
  content          text,
  helpful_count    integer,
  created_at       timestamptz,
  status           text,
  quality_score    numeric,
  verified_visit   boolean,
  r_taste          integer,
  r_service        integer,
  r_price_value    integer,
  r_cleanliness    integer,
  r_atmosphere     integer,
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
  select
    r.id,
    r.business_id,
    r.user_id,
    r.rating,
    r.title,
    r.content,
    r.helpful_count,
    r.created_at,
    r.status,
    r.quality_score,
    r.verified_visit,
    r.r_taste,
    r.r_service,
    r.r_price_value,
    r.r_cleanliness,
    r.r_atmosphere,
    top_badge.id    as author_badge_id,
    top_badge.title as author_badge_title,
    top_badge.color as author_badge_color,
    top_badge.condition->>'tier' as author_badge_tier
  from public.reviews r
  left join lateral (
    select a.id, a.title, a.color, a.condition
    from public.user_achievements ua
    join public.achievements a on a.id = ua.achievement_id
    where ua.user_id = r.user_id
    order by a.xp desc
    limit 1
  ) top_badge on true
  where r.business_id = p_business_id
    and r.status = 'approved'
    and (p_min_rating is null or r.rating >= p_min_rating)
    and (p_verified   is null or r.verified_visit = p_verified)
  order by
    case p_sort
      when 'helpful'  then r.helpful_count::float * -1
      when 'verified' then (case when r.verified_visit then 0 else 1 end)::float
      else extract(epoch from r.created_at) * -1
    end
  limit  p_limit
  offset p_offset;
$$;

revoke all on function public.get_business_reviews_v4(uuid, integer, integer, text, integer, boolean) from public;
grant execute on function public.get_business_reviews_v4(uuid, integer, integer, text, integer, boolean) to anon, authenticated;
comment on function public.get_business_reviews_v4 is
  'v4: author top badge JOIN eklendi. Called by: reviews_repository.dart';

comment on function public.get_business_reviews_v3(uuid, integer, integer, text, integer, boolean) is
  'DEPRECATED 2026-07-07: use get_business_reviews_v4. Remove after 2026-10-07.';
$$;
```

**Not:** `comment on function ... v3 ...` satırı hata verirse kaldırın, v3 imzasını `\df` ile doğrulayın.

- [ ] **Step 2: Migration'ı uygula**

```bash
supabase migration up
```

Beklenen: hata yok, iki yeni fonksiyon oluştu.

- [ ] **Step 3: Fonksiyonları test et**

```sql
-- İşletme badge test (gerçek bir business_id ile):
select * from get_business_badges_v1('<herhangi bir business_id>');

-- Reviews v4 test:
select id, author_badge_id, author_badge_tier
from get_business_reviews_v4('<herhangi bir business_id>', 5, 0);
```

Beklenen: `get_business_badges_v1` 0-13 satır, `get_business_reviews_v4` yorum satırları + nullable badge sütunları.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260707000003_business_badges_reviews_v4.sql
git commit -m "feat(db): get_business_badges_v1 + get_business_reviews_v4 (author badge JOIN)"
```

---

### Task 4: Flutter — ProfileStats modeli + Achievement tier alanı

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/domain/profile_stats.dart`
- Modify: `uygulamalar/mobil/lib/features/profile/data/profile_repository.dart`
- Modify: `uygulamalar/mobil/lib/features/profile/domain/achievement.dart`

- [ ] **Step 1: ProfileStats'a followersCount ekle**

`profile_stats.dart` dosyasını şu şekle getir:

```dart
class ProfileStats {
  ProfileStats({
    required this.reviewsCount,
    required this.helpfulReceived,
    required this.favoritesCount,
    required this.contributionScore,
    required this.visitsCount,
    required this.followersCount,
  });

  final int reviewsCount;
  final int helpfulReceived;
  final int favoritesCount;
  final int contributionScore;
  final int visitsCount;
  final int followersCount;

  factory ProfileStats.fromMap(Map<String, dynamic> m) => ProfileStats(
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    helpfulReceived: (m['helpful_received'] as num?)?.toInt() ?? 0,
    favoritesCount: (m['favorites_count'] as num?)?.toInt() ?? 0,
    contributionScore: (m['contribution_score'] as num?)?.toInt() ?? 0,
    visitsCount: (m['visits_count'] as num?)?.toInt() ?? 0,
    followersCount: (m['followers_count'] as num?)?.toInt() ?? 0,
  );
}
```

- [ ] **Step 2: profile_repository.dart — fetchMyStats default değeri güncelle**

`profile_repository.dart` dosyasında `fetchMyStats()` içindeki fallback `ProfileStats(...)` çağrısına `followersCount: 0` ekle:

```dart
return ProfileStats(
  reviewsCount: 0,
  helpfulReceived: 0,
  favoritesCount: 0,
  contributionScore: 0,
  visitsCount: 0,
  followersCount: 0,
);
```

- [ ] **Step 3: Achievement'a tier alanı ekle**

`achievement.dart` dosyasını şu şekle getir:

```dart
class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorHex,
    required this.xp,
    required this.isHidden,
    required this.unlocked,
    required this.unlockedAt,
    required this.condition,
    required this.currentValue,
    required this.targetValue,
    required this.tier,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String colorHex;
  final int xp;
  final bool isHidden;
  final bool unlocked;
  final DateTime? unlockedAt;
  final Map<String, dynamic> condition;
  final int? currentValue;
  final int? targetValue;
  final String tier; // 'bronze' | 'silver' | 'gold' | 'special'

  factory Achievement.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString();
    const hiddenIds = {
      'silent_follower_20',
      'night_gourmet_5',
      'menu_archivist_1',
      'chance_hunter_10',
      'weekend_wanderer_8',
      'deep_menu_diver_30',
      'chance_hunter_3',
      'silent_quality_10',
    };
    final condition =
        (map['condition'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Achievement(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      icon: (map['icon'] ?? 'trophy').toString(),
      colorHex: (map['color'] ?? '#9CA3AF').toString(),
      xp: (map['xp'] as num?)?.toInt() ?? 20,
      isHidden: map['is_hidden'] == true || hiddenIds.contains(id),
      unlocked: map['unlocked'] == true,
      unlockedAt: DateTime.tryParse((map['unlocked_at'] ?? '').toString()),
      condition: condition,
      currentValue: (map['current_value'] as num?)?.toInt(),
      targetValue: (map['target_value'] as num?)?.toInt(),
      tier: (condition['tier'] as String?) ?? 'bronze',
    );
  }
}
```

- [ ] **Step 4: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata. Eğer hata varsa, `Achievement.tier` alanını kullanan yerleri güncelle.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/domain/profile_stats.dart \
        uygulamalar/mobil/lib/features/profile/data/profile_repository.dart \
        uygulamalar/mobil/lib/features/profile/domain/achievement.dart
git commit -m "feat(mobile): ProfileStats followersCount + Achievement tier alanı"
```

---

### Task 5: Flutter — AchievementMedalWidget (metalik gradient)

**Files:**
- Modify: `uygulamalar/mobil/lib/features/shared/ui/achievements/achievement_visuals.dart`

Metalik radial gradient helper ve daire rozet widget'ı ekler.

- [ ] **Step 1: achievement_visuals.dart'a medalGradient ve AchievementMedalWidget ekle**

Dosyanın sonuna (mevcut `_hexToColor` fonksiyonundan SONRA) ekle:

```dart
/// Tier'a göre metalik radial gradient döner.
Gradient medalGradient(String tier) {
  switch (tier) {
    case 'gold':
      return const RadialGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFF92400E)],
        stops: [0.0, 0.5, 1.0],
      );
    case 'silver':
      return const RadialGradient(
        colors: [Color(0xFFF3F4F6), Color(0xFF9CA3AF), Color(0xFF4B5563)],
        stops: [0.0, 0.5, 1.0],
      );
    case 'special':
      return const RadialGradient(
        colors: [Color(0xFFDDD6FE), Color(0xFF8B5CF6), Color(0xFF4C1D95)],
        stops: [0.0, 0.5, 1.0],
      );
    default: // bronze
      return const RadialGradient(
        colors: [Color(0xFFFCD9BD), Color(0xFFD97706), Color(0xFF7C2D12)],
        stops: [0.0, 0.5, 1.0],
      );
  }
}

/// Metalik daire rozet widget'ı.
class AchievementMedalWidget extends StatelessWidget {
  const AchievementMedalWidget({
    super.key,
    required this.achievement,
    this.size = 44,
  });

  final Achievement achievement;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = appAchievementVisualForId(
      achievement.id,
      fallbackHex: achievement.colorHex,
    );
    final gradient = medalGradient(achievement.tier);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: achievement.unlocked ? gradient : null,
        color: achievement.unlocked ? null : const Color(0xFFE5E7EB),
        boxShadow: achievement.unlocked
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
                const BoxShadow(
                  color: Color(0x44FFFFFF),
                  blurRadius: 2,
                  offset: Offset(0, -1),
                ),
              ]
            : null,
      ),
      child: Center(
        child: FaIcon(
          visual.icon,
          size: size * 0.44,
          color: achievement.unlocked ? Colors.white : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
```

`Achievement` ve `FaIcon` için import ekle (dosyanın başına):
```dart
import '../../profile/domain/achievement.dart';
```

`package:font_awesome_flutter` zaten import edilmiş.

- [ ] **Step 2: Yeni rozet ID'lerini _achievementVisualById map'ine ekle**

Mevcut `_achievementVisualById` map'ine şu girişleri ekle (closing `};` öncesine):

```dart
  'first_visit': AppAchievementVisual(
    icon: FontAwesomeIcons.locationDot,
    color: Color(0xFF78716C),
  ),
  'explorer_5': AppAchievementVisual(
    icon: FontAwesomeIcons.compass,
    color: Color(0xFF0D9488),
  ),
  'district_15': AppAchievementVisual(
    icon: FontAwesomeIcons.map,
    color: Color(0xFF0891B2),
  ),
  'city_50': AppAchievementVisual(
    icon: FontAwesomeIcons.city,
    color: Color(0xFFB45309),
  ),
  'night_gourmet_10': AppAchievementVisual(
    icon: FontAwesomeIcons.moon,
    color: Color(0xFF6D28D9),
  ),
  'reviewer_5': AppAchievementVisual(
    icon: FontAwesomeIcons.comment,
    color: Color(0xFF16A34A),
  ),
  'gourmet_pen_20': AppAchievementVisual(
    icon: FontAwesomeIcons.penNib,
    color: Color(0xFF0284C7),
  ),
  'legend_reviewer_50': AppAchievementVisual(
    icon: FontAwesomeIcons.feather,
    color: Color(0xFFB45309),
  ),
  'quality_voice': AppAchievementVisual(
    icon: FontAwesomeIcons.star,
    color: Color(0xFFD97706),
  ),
  'helpful_10': AppAchievementVisual(
    icon: FontAwesomeIcons.thumbsUp,
    color: Color(0xFF0369A1),
  ),
  'price_detective_5': AppAchievementVisual(
    icon: FontAwesomeIcons.tags,
    color: Color(0xFF15803D),
  ),
  'budget_expert_20': AppAchievementVisual(
    icon: FontAwesomeIcons.coins,
    color: Color(0xFF0E7490),
  ),
  'price_champion_50': AppAchievementVisual(
    icon: FontAwesomeIcons.trophy,
    color: Color(0xFF92400E),
  ),
  'accuracy_90': AppAchievementVisual(
    icon: FontAwesomeIcons.bullseye,
    color: Color(0xFFB45309),
  ),
  'lens_3': AppAchievementVisual(
    icon: FontAwesomeIcons.camera,
    color: Color(0xFF6B7280),
  ),
  'viewfinder_15': AppAchievementVisual(
    icon: FontAwesomeIcons.image,
    color: Color(0xFF0284C7),
  ),
  'photo_master_50': AppAchievementVisual(
    icon: FontAwesomeIcons.cameraRetro,
    color: Color(0xFF92400E),
  ),
  'first_follower': AppAchievementVisual(
    icon: FontAwesomeIcons.userPlus,
    color: Color(0xFF6D28D9),
  ),
  'social_5': AppAchievementVisual(
    icon: FontAwesomeIcons.users,
    color: Color(0xFF7C3AED),
  ),
  'community_star_20': AppAchievementVisual(
    icon: FontAwesomeIcons.star,
    color: Color(0xFF5B21B6),
  ),
  'chance_hunter_3': AppAchievementVisual(
    icon: FontAwesomeIcons.compass,
    color: Color(0xFFF9A825),
  ),
  'silent_quality_10': AppAchievementVisual(
    icon: FontAwesomeIcons.shieldHalved,
    color: Color(0xFF374151),
  ),
```

- [ ] **Step 3: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/shared/ui/achievements/achievement_visuals.dart
git commit -m "feat(mobile): metalik rozet widget + yeni rozet ikonları eklendi"
```

---

### Task 6: Flutter — Stat kartlarını tıklanabilir yap (5 hücre)

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

`_ProfileHeroCard` içinde `_ProfileStatsRow` widget'ını 5 tıklanabilir stat hücresiyle değiştirir.

- [ ] **Step 1: profile_page.dart'ta _ProfileStatsRow'u bul ve güncelle**

`profile_page.dart` dosyasında `_ProfileHeroCard` sınıfını ve içindeki stats satırını bul. Mevcut `_StatCellIcon` kullanan kısmı şu widget'larla değiştir:

`_ProfileHeroCard` içinde stats bölümünü şu yapıya getir:

```dart
// profile_page.dart içinde eklenecek/değiştirilecek bölüm

class _ClickableStatCell extends StatelessWidget {
  const _ClickableStatCell({
    required this.count,
    required this.label,
    required this.onTap,
    this.tooltipMsg,
  });

  final int count;
  final String label;
  final VoidCallback? onTap;
  final String? tooltipMsg;

  @override
  Widget build(BuildContext context) {
    final cell = Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    if (tooltipMsg != null) {
      return Tooltip(message: tooltipMsg!, child: cell);
    }
    return cell;
  }
}

class _ProfileStatsRow extends ConsumerWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myProfileStatsProvider);
    return statsAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, _) => const SizedBox(height: 48),
      data: (stats) {
        return IntrinsicHeight(
          child: Row(
            children: [
              _ClickableStatCell(
                count: stats.favoritesCount,
                label: 'Favori\nMekan',
                onTap: () => context.go('/favorites'),
              ),
              const VerticalDivider(width: 1),
              _ClickableStatCell(
                count: stats.reviewsCount,
                label: 'Yorum',
                onTap: () => context.push('/my-reviews'),
              ),
              const VerticalDivider(width: 1),
              _ClickableStatCell(
                count: stats.visitsCount,
                label: 'Ziyaret\nEdildi',
                onTap: () => context.push('/my-visits'),
              ),
              const VerticalDivider(width: 1),
              _ClickableStatCell(
                count: stats.helpfulReceived,
                label: 'Beğeni',
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => const _HelpfulInfoSheet(),
                ),
                tooltipMsg: 'Yorumlarınıza gelen beğeni sayısı',
              ),
              const VerticalDivider(width: 1),
              _ClickableStatCell(
                count: stats.followersCount,
                label: 'Takipçi',
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => const _FollowerInfoSheet(),
                ),
                tooltipMsg: 'Koleksiyonlarınızı takip eden kişi sayısı',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Bilgi sheet'leri (basit açıklama, navigasyon yok)
class _HelpfulInfoSheet extends StatelessWidget {
  const _HelpfulInfoSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Beğeni Sayısı',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16,
                  color: AppColors.textStrong)),
          const SizedBox(height: 8),
          const Text('Yazdığınız yorumları diğer kullanıcılar kaç kez faydalı bulduğunu gösterir.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _FollowerInfoSheet extends StatelessWidget {
  const _FollowerInfoSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Takipçi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16,
                  color: AppColors.textStrong)),
          const SizedBox(height: 8),
          const Text('Oluşturduğunuz koleksiyonları takip eden toplam kişi sayısıdır.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
```

Mevcut `_ProfileStatsRow` sınıfını ve `_StatCellIcon` sınıfını tamamen kaldır (eğer sadece bu dosyada kullanılıyorsa).

- [ ] **Step 2: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata. `_StatCellIcon` başka yerde kullanılıyorsa kaldırmadan önce kontrol et.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(mobile): profil stat kartları 5'e çıkarıldı ve tıklanabilir yapıldı"
```

---

### Task 7: Flutter — my_visits_page + router

**Files:**
- Create: `uygulamalar/mobil/lib/features/profile/ui/my_visits_page.dart`
- Modify: `uygulamalar/mobil/lib/app/router.dart`

- [ ] **Step 1: my_visits_page.dart dosyasını oluştur**

`uygulamalar/mobil/lib/features/profile/ui/my_visits_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/network/supabase_provider.dart';

// Provider: kullanıcının ziyaret listesi
final _myVisitsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return const [];
  final rows = await supabase
      .from('visits')
      .select('checked_in_at, businesses!inner(id, name, logo_url, address)')
      .eq('user_id', uid)
      .order('checked_in_at', ascending: false)
      .limit(100);
  return (rows as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
});

class MyVisitsPage extends ConsumerWidget {
  const MyVisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(_myVisitsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziyaret Ettiğim Mekanlar'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textStrong,
        elevation: 0,
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Hata: $e',
              style: const TextStyle(color: AppColors.textMuted)),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Henüz ziyaret kaydın yok.',
                      style: TextStyle(color: AppColors.textMuted)),
                  SizedBox(height: 4),
                  Text('Bir işletme sayfasını açınca burada görünür.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visits.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final row = visits[i];
              final biz = (row['businesses'] as Map?)?.cast<String, dynamic>() ?? {};
              final bizId = (biz['id'] ?? '').toString();
              final name = (biz['name'] ?? 'İşletme').toString();
              final address = (biz['address'] ?? '').toString();
              final logoUrl = biz['logo_url']?.toString();
              final visitedAt = DateTime.tryParse(
                  (row['checked_in_at'] ?? '').toString());
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceAlt,
                  backgroundImage:
                      logoUrl != null ? NetworkImage(logoUrl) : null,
                  child: logoUrl == null
                      ? const Icon(Icons.store, color: AppColors.textMuted)
                      : null,
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong)),
                subtitle: Text(
                  address.isNotEmpty
                      ? address
                      : visitedAt != null
                          ? _formatDate(visitedAt)
                          : '',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: visitedAt != null && address.isNotEmpty
                    ? Text(
                        _formatDate(visitedAt),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      )
                    : null,
                onTap: bizId.isNotEmpty
                    ? () => context.push('/b/$bizId')
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Bugün';
    }
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
```

- [ ] **Step 2: router.dart'a /my-visits rotası ekle**

`uygulamalar/mobil/lib/app/router.dart` dosyasında profil rotalarının bulunduğu bölüme ekle:

```dart
GoRoute(
  path: '/my-visits',
  builder: (context, state) => const MyVisitsPage(),
),
```

Ve import ekle (dosyanın başına, diğer profile importlarının yanına):
```dart
import '../features/profile/ui/my_visits_page.dart';
```

- [ ] **Step 3: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/my_visits_page.dart \
        uygulamalar/mobil/lib/app/router.dart
git commit -m "feat(mobile): my_visits_page oluşturuldu, /my-visits rotası eklendi"
```

---

### Task 8: Flutter — Ziyaret takibi (visit upsert)

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart`

İşletme sayfası açıldığında `visits` tablosuna upsert eklenir. Analytics logdan sonra çalışır; hata sessizce yutulur.

- [ ] **Step 1: _trackBusinessPageView fonksiyonunu güncelle**

`business_state_views.dart` içindeki `_trackBusinessPageView` fonksiyonunu bul (satır ~499) ve güncelle:

```dart
Future<void> _trackBusinessPageView({
  required WidgetRef ref,
  required String businessId,
}) async {
  final clientId = await getAnalyticsClientId();
  await ref
      .read(analyticsRepositoryProvider)
      .logEvent(
        eventName: 'business_page_view',
        businessId: businessId,
        source: 'business_page',
        clientId: clientId,
      );
  // Ziyareti kaydet (hata analytics'i etkilemez)
  try {
    final uid = ref.read(supabaseProvider).auth.currentUser?.id;
    if (uid != null) {
      await ref.read(supabaseProvider).from('visits').upsert(
        {'user_id': uid, 'business_id': businessId},
        onConflict: 'user_id,business_id',
      );
    }
  } catch (_) {
    // Sessizce yut — ziyaret kaydı analytics'ten ikincil öncelikli
  }
}
```

`supabaseProvider` import'u mevcut değilse ekle:
```dart
import '../../../core/network/supabase_provider.dart';
```

- [ ] **Step 2: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart
git commit -m "feat(mobile): işletme sayfası açılışında ziyaret upsert eklendi"
```

---

### Task 9: Flutter — Profil sayfasında _TopBadgesStrip

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`

Profil hero card'ına stat satırının altına ilk 3 kilit açılmış rozeti gösteren şerit ekler.

- [ ] **Step 1: _TopBadgesStrip widget'ı ekle**

`profile_page.dart` içine şu widget'ı ekle:

```dart
class _TopBadgesStrip extends ConsumerWidget {
  const _TopBadgesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(myAchievementsProvider);
    return achievementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (achievements) {
        final unlocked = achievements.where((a) => a.unlocked).take(3).toList();
        if (unlocked.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              ...unlocked.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AchievementMedalWidget(achievement: a, size: 44),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 56,
                        child: Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/achievements'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 32),
                ),
                child: const Text(
                  'Tümü',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

Import'ları ekle:
```dart
import '../domain/achievements_provider.dart';  // myAchievementsProvider
import '../../shared/ui/achievements/achievement_visuals.dart';
```

- [ ] **Step 2: _ProfileHeroCard içine _TopBadgesStrip yerleştir**

`_ProfileHeroCard` build metodunda `_ProfileStatsRow`'dan sonra `_TopBadgesStrip()` ekle:

```dart
const _ProfileStatsRow(),
const Divider(height: 1),
const _TopBadgesStrip(),
```

- [ ] **Step 3: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata. `myAchievementsProvider` farklı bir isimle tanımlıysa doğru ismi kullan.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/profile_page.dart
git commit -m "feat(mobile): profil sayfasına top badges strip eklendi"
```

---

### Task 10: Flutter — Yorum kartında kullanıcı rozet pill'i

**Files:**
- Modify: `uygulamalar/mobil/lib/features/reviews/domain/review.dart`
- Modify: `uygulamalar/mobil/lib/features/reviews/data/reviews_repository.dart`
- Modify: `uygulamalar/mobil/lib/features/reviews/ui/business_reviews_page.dart`

`get_business_reviews_v4` çağrısına geçer, `Review` modeline badge alanları ekler, yorum kartında kullanıcı adının yanında metalik pill gösterir.

- [ ] **Step 1: Review modeline badge alanları ekle**

`review.dart` dosyasını oku ve `Review` sınıfına şu alanları ekle:

```dart
final String? authorBadgeId;
final String? authorBadgeTitle;
final String? authorBadgeColor;
final String? authorBadgeTier;
```

`fromMap` factory'de parse et:
```dart
authorBadgeId:    map['author_badge_id']?.toString(),
authorBadgeTitle: map['author_badge_title']?.toString(),
authorBadgeColor: map['author_badge_color']?.toString(),
authorBadgeTier:  map['author_badge_tier']?.toString(),
```

Constructor'a da ekle (required değil, nullable):
```dart
this.authorBadgeId,
this.authorBadgeTitle,
this.authorBadgeColor,
this.authorBadgeTier,
```

- [ ] **Step 2: reviews_repository.dart'ta v4'e geç**

`reviews_repository.dart` dosyasında `get_business_reviews_v3` çağrısını `get_business_reviews_v4` ile değiştir:

```dart
// Eski:
final res = await _supabase.rpc('get_business_reviews_v3', params: {...});
// Yeni:
final res = await _supabase.rpc('get_business_reviews_v4', params: {...});
```

- [ ] **Step 3: business_reviews_page.dart'ta badge pill ekle**

Yorum kartında (`_ReviewCard` veya benzer widget) yazar adının yanına badge pill ekle. Kullanıcı adı satırını bul ve şu şekle getir:

```dart
Row(
  children: [
    Text(
      review.authorName ?? 'Kullanıcı',
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.textStrong,
      ),
    ),
    if (review.authorBadgeTitle != null) ...[
      const SizedBox(width: 6),
      _AuthorBadgePill(
        title: review.authorBadgeTitle!,
        tier: review.authorBadgeTier ?? 'bronze',
      ),
    ],
  ],
),
```

`_AuthorBadgePill` widget'ını aynı dosyaya ekle:

```dart
class _AuthorBadgePill extends StatelessWidget {
  const _AuthorBadgePill({required this.title, required this.tier});

  final String title;
  final String tier;

  Color get _pillColor {
    switch (tier) {
      case 'gold':    return const Color(0xFFF59E0B);
      case 'silver':  return const Color(0xFF9CA3AF);
      case 'special': return const Color(0xFF8B5CF6);
      default:        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _pillColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _pillColor.withOpacity(0.4)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _pillColor,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/reviews/domain/review.dart \
        uygulamalar/mobil/lib/features/reviews/data/reviews_repository.dart \
        uygulamalar/mobil/lib/features/reviews/ui/business_reviews_page.dart
git commit -m "feat(mobile): yorum kartında yazar rozet pill'i eklendi (v4 RPC)"
```

---

### Task 11: Flutter — İşletme rozet repository + provider + header chips

**Files:**
- Create: `uygulamalar/mobil/lib/features/business/data/business_badges_repository.dart`
- Create: `uygulamalar/mobil/lib/features/business/domain/business_badges_provider.dart`
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart`

- [ ] **Step 1: business_badges_repository.dart oluştur**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessBadge {
  const BusinessBadge({
    required this.badgeId,
    required this.title,
    required this.color,
    required this.tier,
  });

  final String badgeId;
  final String title;
  final String color;
  final String tier;

  factory BusinessBadge.fromMap(Map<String, dynamic> m) => BusinessBadge(
    badgeId: (m['badge_id'] ?? '').toString(),
    title:   (m['title']   ?? '').toString(),
    color:   (m['color']   ?? '#9CA3AF').toString(),
    tier:    (m['tier']    ?? 'bronze').toString(),
  );
}

class BusinessBadgesRepository {
  BusinessBadgesRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<List<BusinessBadge>> fetchBadges(String businessId) async {
    final res = await _supabase.rpc(
      'get_business_badges_v1',
      params: {'p_business_id': businessId},
    );
    final rows = (res as List?) ?? const [];
    return rows
        .whereType<Map>()
        .map((e) => BusinessBadge.fromMap(e.cast<String, dynamic>()))
        .toList();
  }
}
```

- [ ] **Step 2: business_badges_provider.dart oluştur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../data/business_badges_repository.dart';

final businessBadgesRepositoryProvider =
    Provider<BusinessBadgesRepository>((ref) {
  return BusinessBadgesRepository(ref.watch(supabaseProvider));
});

final businessBadgesProvider = FutureProvider.autoDispose
    .family<List<BusinessBadge>, String>((ref, businessId) {
  return ref
      .read(businessBadgesRepositoryProvider)
      .fetchBadges(businessId);
});
```

- [ ] **Step 3: business_header.dart'a rozet chip satırı ekle**

`business_header.dart` dosyasında header widget'ını bul. İşletme adı / adres bölümünün altına şu widget'ı ekle:

```dart
// import ekle:
import '../../domain/business_badges_provider.dart';
import '../../../../../features/shared/ui/achievements/achievement_visuals.dart';

// Sınıf veya metot içine:
_BusinessBadgeChips(businessId: business.id),
```

`_BusinessBadgeChips` widget'ını aynı dosyaya ekle:

```dart
class _BusinessBadgeChips extends ConsumerWidget {
  const _BusinessBadgeChips({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(businessBadgesProvider(businessId));
    return badgesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        final shown = badges.take(3).toList();
        final remaining = badges.length - shown.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...shown.map((b) => _BizBadgeChip(badge: b)),
              if (remaining > 0)
                GestureDetector(
                  onTap: () => _showAllBadgesSheet(context, badges),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAllBadgesSheet(BuildContext context, List<BusinessBadge> badges) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AllBadgesSheet(badges: badges),
    );
  }
}

class _BizBadgeChip extends StatelessWidget {
  const _BizBadgeChip({required this.badge});
  final BusinessBadge badge;

  Color get _color {
    final text = badge.color.replaceAll('#', '').trim();
    if (text.length != 6) return const Color(0xFF9CA3AF);
    final value = int.tryParse('FF$text', radix: 16);
    return value != null ? Color(value) : const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Text(
        badge.title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _AllBadgesSheet extends StatelessWidget {
  const _AllBadgesSheet({required this.badges});
  final List<BusinessBadge> badges;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tüm Rozetler',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...badges.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _BizBadgeChip(badge: b),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/data/business_badges_repository.dart \
        uygulamalar/mobil/lib/features/business/domain/business_badges_provider.dart \
        uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
git commit -m "feat(mobile): işletme rozet chip satırı eklendi"
```

---

### Task 12: Flutter — İşletme sertifika widget'ı + paylaşım

**Files:**
- Create: `uygulamalar/mobil/lib/features/business/ui/business_badge_certificate.dart`

`RepaintBoundary` içinde sertifika tasarımı + share_plus ile PNG paylaşımı.

- [ ] **Step 1: pubspec.yaml'da share_plus var mı kontrol et**

```bash
grep "share_plus" uygulamalar/mobil/pubspec.yaml
```

Yoksa ekle:
```yaml
share_plus: ^10.1.4
```
ve `flutter pub get` çalıştır.

- [ ] **Step 2: business_badge_certificate.dart oluştur**

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/colors.dart';
import '../domain/business_badges_provider.dart';
import 'business_badge_chip.dart'; // Task 11'de oluşturuldu

class BusinessBadgeCertificateSheet extends ConsumerStatefulWidget {
  const BusinessBadgeCertificateSheet({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.businessAddress,
  });

  final String businessId;
  final String businessName;
  final String businessAddress;

  @override
  ConsumerState<BusinessBadgeCertificateSheet> createState() =>
      _BusinessBadgeCertificateSheetState();
}

class _BusinessBadgeCertificateSheetState
    extends ConsumerState<BusinessBadgeCertificateSheet> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'sertifika.png')],
        text: '${widget.businessName} — Yeedoy Rozetleri',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(businessBadgesProvider(widget.businessId));
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _CertificateCard(
                    businessName: widget.businessName,
                    businessAddress: widget.businessAddress,
                    badgesAsync: badgesAsync,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: Text(_sharing ? 'Hazırlanıyor...' : 'Paylaş'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.businessName,
    required this.businessAddress,
    required this.badgesAsync,
  });

  final String businessName;
  final String businessAddress;
  final AsyncValue badgesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'YEEDOY',
            style: TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Başarım Sertifikası',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            businessName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (businessAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              businessAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          badgesAsync.when(
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, _) => const SizedBox.shrink(),
            data: (badges) {
              final list = (badges as List?) ?? const [];
              if (list.isEmpty) {
                return const Text(
                  'Henüz rozet kazanılmadı.',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: list.map<Widget>((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Text(
                      (b as dynamic).title as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'yeedoy.com · ${DateTime.now().year}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: İşletme header'ına uzun basılı tut ile sertifikayı aç**

`business_header.dart` içinde rozet chip'lerini gösteren bölüme `onLongPress` ekle:

```dart
// _BusinessBadgeChips build metodunda shown listesinin ilk chip'ini
// uzun basılı tut ile sertifika sheet'i açacak şekilde GestureDetector'a sar:
GestureDetector(
  onLongPress: () => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BusinessBadgeCertificateSheet(
      businessId: businessId,
      businessName: businessName,  // parent'tan parametre olarak geç
      businessAddress: businessAddress,
    ),
  ),
  child: _BizBadgeChip(badge: shown.first),
),
```

İmport ekle:
```dart
import '../business_badge_certificate.dart';
```

- [ ] **Step 4: Analiz çalıştır**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: 0 hata.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/business_badge_certificate.dart \
        uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
git commit -m "feat(mobile): işletme sertifika widget'ı ve paylaşım eklendi"
```

---

### Task 13: Web — BusinessBadges.tsx + businessBadges.ts

**Files:**
- Create: `uygulamalar/web/src/lib/businessBadges.ts`
- Create: `uygulamalar/web/src/ui/business/BusinessBadges.tsx`

Next.js web'de işletme rozet chip'lerini gösterir.

- [ ] **Step 1: businessBadges.ts oluştur**

`uygulamalar/web/src/lib/businessBadges.ts`:

```typescript
import { createSupabaseServerClient } from './supabaseServer';

export interface BusinessBadge {
  badge_id: string;
  title: string;
  color: string;
  tier: 'bronze' | 'silver' | 'gold' | 'special';
}

export async function getBusinessBadges(
  businessId: string,
): Promise<BusinessBadge[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('get_business_badges_v1', {
    p_business_id: businessId,
  });
  if (error || !data) return [];
  return data as BusinessBadge[];
}
```

- [ ] **Step 2: BusinessBadges.tsx oluştur**

`uygulamalar/web/src/ui/business/BusinessBadges.tsx` — Server Component (async):

```tsx
import { getBusinessBadges, BusinessBadge } from '../../lib/businessBadges';

interface Props {
  businessId: string;
}

function tierColor(tier: string): string {
  switch (tier) {
    case 'gold':    return '#B45309';
    case 'silver':  return '#6B7280';
    case 'special': return '#7C3AED';
    default:        return '#D97706';
  }
}

function BadgeChip({ badge }: { badge: BusinessBadge }) {
  const color = tierColor(badge.tier);
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        padding: '3px 10px',
        borderRadius: '999px',
        border: `1px solid ${color}55`,
        backgroundColor: `${color}18`,
        color,
        fontSize: '11px',
        fontWeight: 700,
        lineHeight: '1.4',
      }}
    >
      {badge.title}
    </span>
  );
}

export default async function BusinessBadges({ businessId }: Props) {
  const badges = await getBusinessBadges(businessId);
  if (badges.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-1.5 py-2">
      {badges.map((b) => (
        <BadgeChip key={b.badge_id} badge={b} />
      ))}
    </div>
  );
}
```

- [ ] **Step 3: BusinessBadges bileşenini işletme sayfasına ekle**

`uygulamalar/web` içinde işletme public menü sayfasını bul (muhtemelen `app/(public)/[slug]/page.tsx` veya benzer). Header bölümüne:

```tsx
import BusinessBadges from '../../../src/ui/business/BusinessBadges';

// İşletme adı/bilgilerinin altına:
<BusinessBadges businessId={business.id} />
```

- [ ] **Step 4: Typecheck çalıştır**

```bash
cd uygulamalar/web && npm run typecheck
```

Beklenen: 0 hata.

- [ ] **Step 5: Lint çalıştır**

```bash
cd uygulamalar/web && npm run lint
```

Beklenen: 0 uyarı / hata.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/lib/businessBadges.ts \
        uygulamalar/web/src/ui/business/BusinessBadges.tsx
git commit -m "feat(web): işletme rozet chip'leri işletme sayfasına eklendi"
```

---

## Son Doğrulama

- [ ] `cd uygulamalar/mobil && flutter analyze` — 0 hata
- [ ] `cd uygulamalar/web && npm run typecheck && npm run lint` — 0 hata
- [ ] DB: `select * from get_my_profile_stats_v1()` → 6 sütun (followers_count dahil)
- [ ] DB: `select count(*) from achievements where condition ? 'tier'` → 30+ satır
- [ ] DB: `select * from get_business_badges_v1('<test-id>')` → 0-13 satır, hata yok
- [ ] DB: `select author_badge_id from get_business_reviews_v4('<test-id>', 5, 0)` → hata yok
