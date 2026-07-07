# Tasarım: Rozet Sistemi, Stat Kartları, Ziyaret Takibi

**Tarih:** 2026-07-07  
**Platform:** Flutter Mobile + Next.js Web  
**Durum:** Onaylandı

---

## 1. Kapsam

Dört birbirine bağlı özellik:

1. **Stat kartları** — 5'e genişlet ve tıklanabilir yap  
2. **Ziyaret takibi** — işletme açılışında `visits` tablosuna kayıt  
3. **Kullanıcı rozetleri** — metalik tier sistemi; profil + yorum kartı  
4. **İşletme rozetleri** — hesaplanan başarım rozetleri + paylaşılabilir sertifika  

---

## 2. Görsel Stil: Metalik Madalya (Stil B)

Tüm rozetler için seçilen görsel dil:

| Tier | Renk | Kullanım |
|---|---|---|
| Altın | `radial-gradient(#fde68a → #f59e0b → #92400e)` | En zorlu başarımlar |
| Gümüş | `radial-gradient(#f3f4f6 → #9ca3af → #4b5563)` | Orta seviye |
| Bronz | `radial-gradient(#fcd9bd → #d97706 → #7c2d12)` | Başlangıç |
| Özel (mor) | `radial-gradient(#ddd6fe → #8b5cf6 → #4c1d95)` | Gizli/easter egg |

Rozet şekli: dolu daire + metalik radial gradient + iç parıltı (`inset 0 1px 1px rgba(255,255,255,0.5)`).

**Flutter:** `BoxDecoration` gradient + `BoxShadow`.  
**Web:** CSS `radial-gradient` + `box-shadow`.

---

## 3. Stat Kartları

### 3.1 Mevcut → Hedef

| # | Stat | Kaynak alan | Navigasyon |
|---|---|---|---|
| 1 | Favori Mekan | `favoritesCount` | `context.go('/favorites')` |
| 2 | Yorum | `reviewsCount` | `context.push('/my-reviews')` |
| 3 | Ziyaret Edildi | `visitsCount` | `context.push('/my-visits')` |
| 4 | Beğeni | `helpfulReceived` | bilgi bottom sheet |
| 5 | Takipçi | `followersCount` | bilgi bottom sheet |

### 3.2 Model Değişikliği

`ProfileStats` — `followersCount` alanı eklenir:
```dart
final int followersCount;
```

`get_my_profile_stats_v1` SQL'e eklenecek satır (yeni migration):
```sql
(
  select coalesce(sum(followers_count), 0)::int
  from public.favorite_collections
  where user_id = auth.uid()
) as followers_count
```

### 3.3 UI Değişikliği

`_ProfileStatsRow` → `_StatCellIcon` kaldırılır.  
Yeni: `_ClickableStatCell` — her hücre `GestureDetector` + `InkWell` + ripple.

Layout: `Expanded` × 5, `VerticalDivider` araya.

### 3.4 `/my-visits` Sayfası (yeni)

`uygulamalar/mobil/lib/features/profile/ui/my_visits_page.dart`

- Supabase: `visits` tablosu ← JOIN `businesses(id, name, logo_url, address)` WHERE `user_id = auth.uid()` ORDER BY `created_at DESC`
- Her satır: işletme logosu + adı + adresi + ziyaret tarihi → tıklanınca `/b/:id`
- Router'a `GoRoute(path: '/my-visits', ...)` eklenir
- Kullanıcı giriş yapmamışsa redirect to `/login?redirect=/my-visits`

---

## 4. Ziyaret Takibi

### 4.1 Mekanizma

`business_state_views.dart:_trackBusinessPageView` içine, analytics logından sonra:

```dart
final uid = ref.read(supabaseProvider).auth.currentUser?.id;
if (uid != null) {
  await ref.read(supabaseProvider).from('visits').upsert(
    {'user_id': uid, 'business_id': businessId},
    onConflict: 'user_id,business_id',
  );
}
```

`visits` tablosu unique index `visits_user_business_unique (user_id, business_id)` zaten mevcut — upsert güvenli, duplicate olmaz.  
RLS `visits_insert_own` zaten izin veriyor — yeni RPC gerekmez.

### 4.2 Etki

`get_my_profile_stats_v1` `visits_count` alanı bu tablodan sayar → stat kart otomatik güncellenir.

---

## 5. Kullanıcı Rozetleri

### 5.1 Rozet Listesi (Genişletilmiş)

#### Ziyaret 🗺️
| ID | Başlık | Koşul | Tier |
|---|---|---|---|
| `first_visit` | İlk Adım | 1. işletme ziyareti | Bronz |
| `explorer_5` | Kaşif | 5 farklı işletme | Bronz |
| `district_15` | Semt Turisti | 15 farklı işletme | Gümüş |
| `city_50` | Şehir Gezgini | 50 farklı işletme | Altın |
| `night_gourmet_10` | Gece Kuşu | 10 ziyaret 20:00+ | Gümüş |
| `weekend_wanderer_8` | Hafta Sonu Kaçamakçısı | 8 hf.sonu ziyaret | Bronz |

#### Yorum & Katkı ✍️
| ID | Başlık | Koşul | Tier |
|---|---|---|---|
| `first_review` | İlk Yorumcu | 1. yorum | Bronz |
| `reviewer_5` | Anlatıcı | 5 yorum | Bronz |
| `gourmet_pen_20` | Gurme Kalemi | 20 yorum | Gümüş |
| `legend_reviewer_50` | Efsane Yorumcu | 50 yorum | Altın |
| `quality_voice` | Kaliteli Ses | 3+ kaliteli yorum | Altın |
| `helpful_10` | Beğenilen | 10 kişi faydalı buldu | Gümüş |

#### Fiyat & Veri 💰
| ID | Başlık | Koşul | Tier |
|---|---|---|---|
| `price_detective_5` | Fiyat Dedektifi | 5 fiyat katkısı | Bronz |
| `budget_expert_20` | Bütçe Uzmanı | 20 onaylı fiyat | Gümüş |
| `price_champion_50` | Fiyat Şampiyonu | 50 onaylı fiyat | Altın |
| `accuracy_90` | Doğrulukçu | %90+ onay oranı ≥ 10 katkıda | Altın |

#### Fotoğraf 📸
| ID | Başlık | Koşul | Tier |
|---|---|---|---|
| `lens_3` | Objektif | 3 fotoğraf | Bronz |
| `viewfinder_15` | Vizör | 15 fotoğraf | Gümüş |
| `photo_master_50` | Fotoğraf Ustası | 50 fotoğraf | Altın |

#### Sosyal 🤝
| ID | Başlık | Koşul | Tier |
|---|---|---|---|
| `first_follower` | İlk Takipçi | 1 koleksiyon takipçisi | Bronz |
| `social_5` | Sosyal Kelebek | 5 takipçi | Gümüş |
| `community_star_20` | Topluluk Yıldızı | 20 takipçi | Altın |

#### Gizli / Özel 🔮 (mor, `is_hidden: true`)
| ID | Başlık | Koşul |
|---|---|---|
| `menu_archivist_1` | Menü Arşivisti | İlk menü katkısı |
| `chance_hunter_3` | Şans Avcısı | 3 kampanya kullanımı |
| `deep_menu_diver_30` | Derin Menü Dalgıcı | 30 menü öğesi inceledi |
| `silent_quality_10` | Sessiz Kalite | Hiç reddedilmeden 10 katkı |
| `night_gourmet_5` | Gece Gurme | 5 gece ziyareti + yorum |

### 5.2 DB Değişikliği

`achievements` tablosuna eksik rozetler `INSERT` ile eklenir (yeni migration).  
`get_my_achievements_v2` RPC tier alanını döndürecek şekilde güncellenir ya da `tier` alanı `condition` JSONB içine gömülür (mevcut yapıya uyumlu).

### 5.3 Flutter — `Achievement` Model

`tier` alanı eklenir:
```dart
final String tier; // 'bronze' | 'silver' | 'gold' | 'special'
```

### 5.4 Flutter — Görsel

`achievement_visuals.dart`'a `medalGradient(String tier) → Gradient` helper eklenir.

```dart
// AchievementMedalWidget: daire + gradient + iç parıltı + icon
class AchievementMedalWidget extends StatelessWidget {
  final Achievement item;
  final double size;
  ...
}
```

### 5.5 Profil Sayfasında Top Badges Strip

`_ProfileHeroCard` içinde `_ProfileStatsRow` altına:
```
_TopBadgesStrip  →  kilit açılmış ilk 3 rozet (boş ise gizlenir)
```

Her rozet: `AchievementMedalWidget(size: 44)` + kısa başlık.  
Tümünü Gör → `/achievements` sayfasına yönlendirir (mevcut `AchievementsGrid` kullanılır).

### 5.6 Yorum Kartında Kullanıcı Rozeti

`get_business_reviews_v3` return tipi genişleyeceğinden yeni **`get_business_reviews_v4`** oluşturulur (v3 90 gün deprecated olarak kalır). LEFT JOIN:
```sql
left join lateral (
  select a.id, a.title, a.color, a.xp
  from user_achievements ua
  join achievements a on a.id = ua.achievement_id
  where ua.user_id = r.user_id
  order by a.xp desc
  limit 1
) top_badge on true
```
Review modeline eklenir:
```dart
final String? authorBadgeId;
final String? authorBadgeTitle;
final String? authorBadgeColor;
final String? authorBadgeTier;
```

Yorum kartında kullanıcı adının yanında küçük metalik pill:
```
[🥈 Gurme Kalemi]  ← gümüş renk, 10px, font-weight 700
```

---

## 6. İşletme Rozetleri

### 6.1 Rozet Listesi

| ID | Başlık | Koşul | Renk Teması |
|---|---|---|---|
| `biz_weekly_top` | Haftanın Favorisi | Haftalık ziyarette ilk %10 | Altın |
| `biz_monthly_star` | Aylık Yıldız | Ay içinde 200+ benzersiz ziyaret | Altın |
| `biz_explorer_magnet` | Keşifçi Mıknatısı | 50+ benzersiz kullanıcı | Gümüş |
| `biz_night_hub` | Gece Hayatı Merkezi | Ziyaretlerin %40+ 20:00 sonrası | Özel |
| `biz_quality_reviews` | Kaliteli Yorum Mekanı | Ort. quality score ≥ 0.75 | Altın |
| `biz_gourmet_pick` | Gurme Seçimi | 5+ kaliteli yorum + ort. rating ≥ 4.2 | Altın |
| `biz_photo_rich` | Fotoğraf Zengini | 20+ onaylı fotoğraf | Gümüş |
| `biz_rich_menu` | Zengin Menü | 30+ menü öğesi, fiyatlar dolu | Gümüş |
| `biz_price_transparent` | Fiyat Şeffaflığı | 10+ onaylı fiyat katkısı | Bronz |
| `biz_trusted_data` | Güvenilir Veri | Fiyat onay oranı ≥ %80 | Gümüş |
| `biz_verified` | Doğrulanmış Mekan | Owner talebi onaylandı | Özel |
| `biz_veteran_1y` | Köklü Mekan | Yeedoy'da 1 yıl+ aktif | Altın |
| `biz_loyal_community` | Sadık Topluluk | 2 yıl+ aktif, düzenli yorum | Altın |

### 6.2 DB

Yeni fonksiyon:
```sql
create or replace function public.get_business_badges_v1(p_business_id uuid)
returns table(badge_id text, title text, color text, tier text)
language plpgsql security definer set search_path = public
as $$
begin
  -- Her rozet için koşul hesaplanır ve sadece kazanılanlar döner
  ...
end;
$$;
```

Haftalık/aylık rozetler için periyodik hesaplama → `business_badge_cache` tablosu + cron/pg_cron veya Edge Function (MVP'de anında hesaplanır, sonradan cache'e taşınır).

### 6.3 Flutter — İşletme Detay Sayfası

`business_header.dart` → header altına rozet chip satırı:
```
[🏆 Haftanın Favorisi] [⭐ Kaliteli Yorum] [📍 Keşifçi Mıknatısı]
```
3'ten fazlaysa `+N daha` tıklanınca tam liste bottom sheet açar.

### 6.4 Flutter — Sertifika / Paylaşım

`BusinessBadgeCertificate` widget → `RepaintBoundary` içinde:
- Lacivert/mor gradient arka plan
- İşletme adı + adres + tarih
- Rozet kartları (badge grid)
- Yeedoy logosu + "yeedoy.com · Doğrulanmış Veri"

`Share.shareXFiles([png])` ile paylaşılır.  
Route: `/b/:id` sayfasında badge chip'e uzun basılı tut → sertifika sheet.

### 6.5 Web (Next.js) — İşletme Rozet Çipleri

`src/ui/business/BusinessBadges.tsx` → `get_business_badges_v1` RPC çağırır.  
Pill chip'ler: menü sayfası header altında gösterilir.

---

## 7. Etkilenen Dosyalar

### Flutter Mobile
```
lib/features/profile/
  domain/profile_stats.dart              +followersCount
  domain/profile_stats_provider.dart     değişmez
  data/profile_repository.dart           fetchMyStats güncellenir
  domain/achievement.dart                +tier alanı
  ui/profile_page.dart                   _ProfileStatsRow → 5 stat, _TopBadgesStrip
  ui/my_visits_page.dart                 YENİ
  ui/components/achievements_grid.dart   AchievementMedalWidget kullanır

lib/features/shared/ui/achievements/
  achievement_visuals.dart               medalGradient helper + AchievementMedalWidget

lib/features/reviews/
  data/review.dart                       +authorBadge alanları
  ui/business_reviews_page.dart          yorum kartında badge pill

lib/features/business/
  ui/parts/business_state_views.dart     visit upsert eklenir
  ui/parts/business_header.dart          rozet chip satırı
  ui/business_badge_certificate.dart     YENİ
  data/business_badges_repository.dart   YENİ
  domain/business_badges_provider.dart   YENİ
```

### Next.js Web
```
src/ui/business/BusinessBadges.tsx       YENİ
src/lib/businessBadges.ts                get_business_badges_v1 wrapper
```

### Supabase
```
supabase/migrations/
  YYYYMMDD_profile_stats_followers.sql   followers_count kolonu get_my_profile_stats_v1'e
  YYYYMMDD_achievements_extended.sql     yeni rozetler INSERT + tier alanı
  YYYYMMDD_business_badges_v1.sql        get_business_badges_v1 + get_business_reviews_v4 (badge join, v3 deprecated)
```

---

## 8. Kısıtlar & Kararlar

- **Yorum rozeti için N+1 yok:** RPC JOIN ile tek sorguda çekilir.
- **İşletme rozetleri MVP'de anında hesaplanır** (cache yok); yük yüksek olursa `business_badge_cache` tablosu sonradan eklenir.
- **Sertifika PNG üretimi:** Flutter `RenderRepaintBoundary.toImage()` kullanılır; web paylaşımı için `html2canvas` değil, Next.js'te server-side opengraph image yeterli.
- **Ziyaret upsert hata sessizce yutulur** (`try/catch`) — analytics birincil, ziyaret ikincil.
- **Rozetler DB-driven:** `achievements` tablosuna yeni rozet eklemek Flutter kodu değiştirmez.
