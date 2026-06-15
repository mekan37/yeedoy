# Top İşletmeler Sayfası Yeniden Tasarımı

## Amaç

Mevcut `/top-businesses` sayfası (sadece isim + kategori + yıldız gösteren basit kart listesi) kullanıcıdan gelen mockup'a göre yeniden tasarlanacak: karşılama başlığı, promosyon banner'ı, kategori filtre çipleri ve görselli/sıra rozetli/mesafeli ranked liste. "Örnek Yeedoy" işletmesi (`2e9be57b-62cd-4f5f-bb4b-0d665994765c`) gerçekçi test verisiyle bu listede üst sıralarda görünecek.

## Kapsam

- Mevcut route (`/top-businesses`), giriş noktaları (drawer linki, Discovery "Bu Hafta/Bu Ay En İyiler" linkleri) ve `period=week|month` parametresi **korunur**.
- `TopBusinessesPage` ve `TopBusinessCard` içerikleri yeniden tasarlanır.
- `get_top_businesses_period_v1` SQL fonksiyonu genişletilir (görsel, konum, mesafe, daha düşük min_reviews eşiği).
- "Örnek Yeedoy" için seed migration (yorumlar) eklenir.

## Mimari ve Veri Akışı

### 1. SQL: `get_top_businesses_period_v1` (yeni migration)

`CREATE OR REPLACE` ile genişletilir (dönen kolonlar değiştiği için `RETURNS TABLE` değişimi gerekiyorsa önce `DROP FUNCTION IF EXISTS` ile eski overload kaldırılır — `search_nearby_price_open` migrasyonundaki desen).

**Yeni imza:**
```sql
get_top_businesses_period_v1(
  p_period text,
  p_limit integer default 6,
  p_min_reviews integer default 0,   -- 2'den 0'a düşürüldü
  p_user_lat double precision default null,
  p_user_lng double precision default null
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  avg_rating double precision,
  reviews_count integer,
  score double precision,
  image_url text,
  lat double precision,
  lng double precision,
  distance_km double precision
)
```

**Mantık değişiklikleri:**
- `agg` CTE'sindeki `having count(*) >= p_min_reviews` koşulu kalır ama varsayılan parametre 0 olduğu için tüm işletmeler (0 yorumlu dahil) dahil olabilir. 0 yorumlu işletmeler için `avg_rating = 0`, `reviews_count = 0`, `score = 0` olur — bu yüzden `agg` CTE'si `reviews r` üzerinden `inner join` değil, `businesses b` tablosundan başlayıp `left join` ile yorumları eklemeli (mevcut sorgu `agg`'den `join businesses` yapıyordu — bu artık `businesses`'tan başlayıp `left join agg` olacak şekilde tersine çevrilir).
- `image_url`: `coalesce(b.hero_image_url, b.cover_image_url, b.image_url, b.logo_url)` (businesses tablosundaki mevcut görsel kolonları — mobile tarafındaki `_buildHeroImage` fallback sırasıyla aynı).
- `lat`, `lng`: `b.lat`, `b.lng`.
- `distance_km`: `p_user_lat`/`p_user_lng` null değilse `search_nearby_businesses_v3`'teki haversine formülü ile hesaplanır, null ise `distance_km` de null döner.
- `order by score desc, reviews_count desc` (0 puanlılar mantıklı şekilde sona düşer; aralarında yorum sayısı tie-break).
- `b.is_active = true` filtresi eklenir (mevcut sorguda yoktu, diğer RPC'lerle tutarlılık için).

### 2. Repository: `top_businesses_repository.dart`

`fetchTopBusinesses` imzasına `double? userLat`, `double? userLng` eklenir; cache key'e dahil edilmez (konum sık değişmez, TTL 10dk zaten kısa — ama basitlik için cache key'e lat/lng'i 1 ondalık hassasiyetle eklemek yerine, konum varsa cache'i bypass etmek yerine **cache key'e dahil etmiyoruz**: konum sadece mesafe gösterimi için, sıralamayı etkilemiyor — yani aynı dönem için tek bir cache girdisi yeterli, distance_km client tarafında ayrıca hesaplanabilir).

> Karar: Mesafe hesaplamasını **SQL'de** yapıyoruz (RPC parametresi olarak lat/lng gönderiyoruz) çünkü `search_nearby_businesses_v3` ile aynı haversine formülünü tekrar yazmak istemiyoruz ve tek seferlik bir RPC çağrısı yeterli. Cache key'e `lat`/`lng`'i 2 ondalık hassasiyetle (yaklaşık ~1km) ekliyoruz — bu hem doğruluğu korur hem de konum küçük değişimlerde gereksiz yeniden istek atılmasını önler.

`fetchTopBusinesses` parametreleri: `period`, `limit = 5` (mockup 5 satır gösteriyor — varsayılan 6'dan 5'e düşürülür), `minReviews = 0`, `userLat`, `userLng`, `force`.

### 3. Domain Model: `top_business.dart`

```dart
class TopBusiness {
  TopBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.district,
    required this.avgRating,
    required this.reviewsCount,
    required this.score,
    this.imageUrl,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? category;
  final String? city;
  final String? district;
  final double avgRating;
  final int reviewsCount;
  final double score;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final double? distanceKm;

  factory TopBusiness.fromMap(Map<String, dynamic> m) => TopBusiness(
    id: m['id'] as String,
    name: (m['name'] ?? '').toString(),
    category: m['category'] as String?,
    city: m['city'] as String?,
    district: m['district'] as String?,
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    score: (m['score'] as num?)?.toDouble() ?? 0,
    imageUrl: m['image_url'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    distanceKm: (m['distance_km'] as num?)?.toDouble(),
  );
}
```

### 4. Controller: `top_businesses_page_controller.dart`

Mevcut `topBusinessesListProvider(period)` provider'ı, `discoverySearchProvider`'ın state'inden `userLat`/`userLng` okuyup repository çağrısına geçirecek şekilde güncellenir (provider `ref.watch(discoverySearchProvider.select((s) => (s.userLat, s.userLng)))`). Konum yoksa (`null`), RPC `distance_km = null` döner ve UI mesafe satırını gizler.

## Sayfa Bileşenleri (`top_businesses_page.dart`)

`AppScaffold` + `RefreshIndicator` yapısı korunur. `body` içeriği:

```
ListView
├─ _TopBusinessesHeader (karşılama + bildirim zili)
├─ _TopBusinessesPromoBanner
├─ _CategoryFilterChips (Tümü / Yeme & İçme / Kafeler / Tatlı / Diğer)
└─ ranked list: _TopBusinessListTile (1..N), her biri TopBusinessCard
```

### `_TopBusinessesHeader`

- Sol: "Merhaba! 👋" (üstte, muted, 12sp) + sayfa başlığı (`t.bestBusinessesThisWeek`/`bestBusinessesThisMonth`, w900, 18sp) altta
- Sağ: `NotificationsBell` → `context.go('/inbox')` (mevcut `_DiscoveryTopBar`'daki IconButton ile aynı desen)

### `_TopBusinessesPromoBanner`

- `AppCard` benzeri, `AppColors.primary` → `AppColors.primary.withValues(alpha: 0.7)` gradyan arka plan, beyaz metin
- Sol: `Icons.emoji_events_rounded` (kupa), 28px, beyaz
- Sağ: `Expanded(Text('En çok değerlendirilen ve favorilenen işletmeleri keşfet!'))`, w800, beyaz, 13sp
- Dekoratif yıldız ikonları **eklenmeyecek** (YAGNI — mockup'taki süs öğeleri, fonksiyonel değer katmıyor)

### `_CategoryFilterChips`

- `Wrap` içinde `ChoiceChip`/`AppChip` benzeri 5 çip: Tümü, Yeme & İçme, Kafeler, Tatlı, Diğer
- Local state (`StatefulWidget` veya `useState` benzeri — `ConsumerStatefulWidget`): seçili kategori grubu
- Kategori grup eşlemesi (CategoryAssets slug'larına göre, normalize edilmiş karşılaştırma):
  - **Yeme & İçme**: `restoran`/`restaurant`, `balik`/`fish`/`et`/`meat`/`balik et`/`fish meat`, `kahvalti`/`breakfast`
  - **Kafeler**: `kafe`/`cafe`
  - **Tatlı**: `tatlici`/`dessert`
  - **Diğer**: eşlemeye girmeyen her şey (`mekan`/`venue` dahil)
  - **Tümü**: filtre yok
- Filtre, RPC sonucundaki listeyi **client-side** süzer (ekstra RPC çağrısı yok — liste zaten küçük, max `limit` kadar)
- Bir kategori seçiliyken liste boşalırsa: mevcut `t.topBusinessesNotEnoughData` mesajı gösterilir

### `TopBusinessCard` (yeniden tasarım)

Satır düzeni (`Row`):

1. **Görsel + sıra rozeti** (sol, 64x64):
   - `ClipRRect(borderRadius: 12)` içinde `AppNetworkImage(url: item.imageUrl, variant: small)`, `imageUrl` null/boşsa `Image.asset(CategoryAssets.resolve(item.category))`
   - `Positioned(top: -4, left: -4)`: dairesel rozet, içinde `rank` (1-tabanlı index), ilk 3 için `AppColors.primary` arka plan + beyaz metin, 4+ için `AppColors.cardAlt` arka plan + `AppColors.textStrong` metin

2. **Orta bilgi** (`Expanded`):
   - İşletme adı (w900, 14sp, 1 satır ellipsis)
   - Kategori · ilçe/şehir (mevcut `_locText`, muted, 12sp, 1 satır ellipsis)
   - Mesafe + süre satırı (sadece `item.distanceKm != null` ise): `Icons.directions_walk` + `"${distanceKm.toStringAsFixed(1)} km · ~${minutes} dk"`, muted, 11sp
     - `minutes = (distanceKm / 4.5 * 60).round().clamp(1, 999)` (4.5 km/h ortalama yürüme hızı)

3. **Sağ kolon** (`Column`, `crossAxisAlignment: end`):
   - Üstte: favori kalbi — mevcut `_FavoriteToggleButton` widget'ı (business_header.dart'taki ile aynı `isFavoritedProvider`/`favoritesControllerProvider` mantığı; bu widget `business_header.dart`'ta private (`_FavoriteToggleButton`) olduğu için **top_businesses** içine kendi küçük kopyası yazılır — favori ikonu + toggle, overlay olmadan, `Icons.favorite`/`favorite_border`, `AppColors.danger`/`AppColors.text`)
   - Altta: `Row`: yıldız ikonu + `avgRating > 0 ? avgRating.toStringAsFixed(1) : '-'` (w900) + `(${reviewsCount})` (muted, 11sp)
   - En altta: dairesel puan rozeti — mevcut `TrustScoreIndicator(score: (avgRating * 10).round().clamp(0, 100), size: 36, showLabel: false)` (business_header.dart `_TopStatCard`'da kullanılan bileşenin aynısı, `lib/features/shared/ui/components/` içinde tanımlı)

Kart tıklaması: `onTap: () => context.go('/b/${item.id}')` (mevcut davranış korunur).

`badge` parametresi (haftalık/aylık rozet metni) artık ayrı bir köşe etiketi olarak gösterilmez (mockup'ta yok) — bunun yerine sayfa başlığında zaten "Bu Hafta/Bu Ay En İyiler" belirtiliyor, period seçimi için küçük bir `SegmentedButton`/iki sekmeli toggle başlığın altına eklenir (mevcut `period` query param ile route üzerinden geçiş — `context.go('/top-businesses?period=week|month')`).

## "Örnek Yeedoy" Seed Migration

Yeni migration dosyası `supabase/migrations/20260615000006_seed_top_business_demo_reviews.sql`:

- "Örnek Yeedoy" (`2e9be57b-62cd-4f5f-bb4b-0d665994765c`) için `reviews` tablosuna 3 adet test yorumu eklenir: `status='approved'`, `rating` sırasıyla `5, 5, 4`, `content` her biri için kısa demo metni (örn. `'Harika bir deneyim, tekrar geleceğim!'`), `created_at` = `now() - interval '1 day'`, `now() - interval '2 days'`, `now() - interval '3 days'` (son 7 gün içinde, hem `week` hem `month` filtresine girer)
- `user_id`: `(select id from auth.users order by created_at asc limit 1)` — `reviews.user_id` nullable olduğu için tek bir mevcut kullanıcı (genelde ilk/seed admin) 3 satırda da kullanılır, ekstra kullanıcı oluşturulmaz
- Beklenen sonuç: `avg_rating = (5+5+4)/3 ≈ 4.67`, `reviews_count = 3`, `score = 4.67 * ln(4) ≈ 6.47`
- Migration uygulandıktan sonra `execute_sql` ile `select * from get_top_businesses_period_v1('week', 5, 0, null, null)` çalıştırılıp "Örnek Yeedoy"'un üst 5 içinde olduğu doğrulanır. Eğer mevcut verilerde daha yüksek skorlu 5+ işletme varsa, bu adımda rating'ler `5,5,5` olarak güncellenir (score ≈ 6.93) — yine de üst 5'e girmiyorsa, en yüksek skorlu işletmenin skorunun hemen üzerine çıkacak şekilde rating sayısı/değeri ayarlanır.

## Hata Yönetimi

- Mevcut `error`/`loading`/`empty` durumları (`AppErrorMapper`, retry butonu, `topBusinessesNotEnoughData`) korunur.
- Konum izni verilmemişse (`userLat`/`userLng` null): mesafe satırı gizlenir, sayfanın geri kalanı normal çalışır — ek hata mesajı gösterilmez.

## L10n

Yeni metinler için ARB anahtarları eklenir (TR + EN):
- `topBusinessesGreeting` ("Merhaba! 👋" / "Hello! 👋")
- `topBusinessesPromoText` ("En çok değerlendirilen ve favorilenen işletmeleri keşfet!" / "Discover the most reviewed and favorited businesses!")
- `categoryFilterAll`, `categoryFilterFoodDrink`, `categoryFilterCafes`, `categoryFilterDessert`, `categoryFilterOther` (Tümü/Yeme & İçme/Kafeler/Tatlı/Diğer + EN karşılıkları) — eğer bu anahtarlar zaten başka bir özellikte mevcutsa onlar tekrar kullanılır, yoksa eklenir.

## Test Planı

- `flutter analyze` — yeni/değişen dosyalar için 0 hata
- Manuel test: `/top-businesses?period=week` ve `?period=month` açılır, liste görsel/rozet/mesafe/favori/puan dairesi ile render olur
- "Örnek Yeedoy" listede (ideal olarak üst sıralarda) görünüyor
- Kategori çipleri ile filtreleme çalışıyor, boş sonuç durumunda mesaj gösteriliyor
- Konum izni reddedildiğinde mesafe satırı olmadan sayfa normal render oluyor
- Favori kalbi toggle çalışıyor (giriş yapılmamışsa `showQuickLoginSheet` açılıyor — mevcut davranış)
