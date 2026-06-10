# Keşfet (Discovery) Sayfası — Üst Bölüm Redesign

**Tarih:** 2026-06-10
**Kapsam:** `uygulamalar/mobil/lib/features/discovery/` — yalnızca premium layout
(`usePremiumLayout == true`, `_buildPremiumDiscoveryLayout`) içindeki **üst bölüm**.
**Referans:** Kullanıcının paylaştığı "Keşfet" mockup görseli (krem arka plan,
"Merhaba 👋" başlığı, yuvarlak kategori çipleri, yatay işletme kartları, promo banner).

## 1. Amaç ve Kapsam

Mevcut Keşfet sayfasının üst kısmını (karşılama + arama + kategori seçimi +
"senin için" listesi + promo) mockup'a yakın, daha sıcak/kişisel bir görünüme
taşımak. Sayfanın geri kalanı (filtreler sheet'i, harita, sıralama, sponsorlu
bölüm, fresh links, serendipity, haftalık/aylık şeritler, tab bar) **değişmeden**
kalır.

**Kapsam dışı:**
- Eski (Material2/non-premium, `usePremiumLayout == false`) layout
- Tab bar (Önerilen / Kampanyalar / Yemekler)
- Backend/RPC değişiklikleri — gerçek işletme fotoğrafı eklenmesi bu işin
  kapsamında değil; mevcut `CategoryAssets` stok görselleri kullanılmaya devam eder
- Harita görünümü, Filtreler sheet'i, Sıralama menüsü, Sponsorlu bölüm,
  Serendipity kart, "Bu hafta/ay en iyiler" şeritleri

## 2. Sayfa Yapısı (yeni sıralama)

`_buildPremiumDiscoveryLayout` içindeki `SliverList` sırası şu şekilde değişir:

1. **`_DiscoveryGreetingHeader`** (yeni) — "Merhaba [isim] 👋" + "Bugün ne yemek istersin?"
2. Arama kutusu (mevcut `TextField`, **değişmez**)
3. **Kategori çipleri** (yeni: `CategoryQuickFilters` hibrit/yuvarlak stil, "Öne Çıkanlar" dahil)
4. `WeatherHintBar(compact: true)` (mevcut, yerinde kalır — kategori çiplerinin altına kayar)
5. Filtre çipleri satırı (mevcut `_PremiumFilterChip` listesi: Bütçe/Doğrulanmış/Açık Şimdi/Taste Twin/Max Bütçe — **değişmez**, sadece bir sıra aşağı kayar)
6. Fresh Links bölümü (mevcut, koşullu — **değişmez**)
7. **"Senin için keşfet"** başlığı (eski "Yakındaki Mekanlar" başlığının yerini alır) + yeniden tasarlanmış yatay işletme kartları
8. **`_DiscoveryPromoBanner`** (yeni) — "Bugün ne yiyelim? 🎉" kartı, `_WhatToEatSheet`'i açar
9. Reklamlı kart listesi devamı (`_buildNearbyCardsWithAds`, mevcut mantık — **değişmez**)

Mevcut `AppBar` (`AppAppBar`: app adı + `_LocationPill` + bildirim zili) **dokunulmaz**.

## 3. Yeni Komponentler

### 3.1 `_DiscoveryGreetingHeader`

- Konum: `discovery_recommended_tab.dart` içine private widget veya
  `discovery_cards.dart`'a eklenecek (`part of` dosyası).
- İçerik:
  - Satır 1: "Merhaba {isim} 👋" — isim `authStateProvider`/`publicProfile.displayName`
    üzerinden alınır (bkz. `lib/features/auth/domain/auth_providers.dart`).
    İsim `null`/boşsa "Merhaba 👋" (isimsiz varyant).
  - Satır 2: "Bugün ne yemek istersin?" — sabit alt başlık.
- Stil: `Theme.of(context).textTheme.headlineSmall` (satır 1, `fontWeight: w900`),
  `textTheme.bodyMedium` + `AppColors.muted` (satır 2). Inline renk/boyut yok —
  mevcut `AppTypography`/`textTheme` kullanılacak.
- Yeni ARB anahtarları (TR + EN, `app_tr.arb` / `app_en.arb` + sync script):
  - `discoveryGreetingHello` → `"Merhaba {name} 👋"` (placeholder: `name`)
  - `discoveryGreetingHelloAnon` → `"Merhaba 👋"`
  - `discoveryGreetingSubtitle` → `"Bugün ne yemek istersin?"`

### 3.2 Kategori Çipleri (hibrit yuvarlak stil — Seçenek B)

- Mevcut `CategoryQuickFilters`/`CategoryQuickFilterItem`/`_CategoryCard`
  komponentleri **yeniden kullanılır**, ancak `_CategoryCard` için yeni bir
  görsel varyant eklenir (ör. `CategoryQuickFiltersLayout.roundedRow` veya
  `_CategoryCard`'a `compactRound: bool` parametresi):
  - 52×52 px yuvarlak (`ClipOval`) görsel, altında etiket — yatay
    `ListView.separated`, mevcut `discoveryHomeCategories` veri kaynağı.
  - İlk öğe **"Öne Çıkanlar"**: `FontAwesomeIcons.star` ikonlu, `AppColors.primary`
    renginde 2px border ile vurgulanmış yuvarlak öğe (görsel yerine ikon —
    stok kategori görseli yok). Tıklanınca: aktif kategori filtresi temizlenir
    (varsayılan/önerilen listeye dönülür) — `discoverySearchProvider.notifier`
    üzerinden mevcut "kategori temizle" davranışı kullanılır.
  - Diğer öğeler (`Pide`, `Kebap`, `Tatlı`, ...): mevcut `discoveryHomeCategories`
    listesindeki `imagePool[0]` görseli yuvarlak kırpılır, `titleKey` ile
    etiketlenir, tıklanınca mevcut davranış (arama terimi set etme) korunur.
- Yeni ARB anahtarı: `discoveryFeaturedCategory` → `"Öne Çıkanlar"`
- İkonlar: `FontAwesomeIcons` paketinden (`font_awesome_flutter`, zaten
  bağımlılıkta mevcut ve `discovery_cards.dart` içinde `FontAwesomeIcons.star`
  olarak kullanılıyor) — emoji veya yeni asset **eklenmez**.

### 3.3 "Senin için keşfet" — Yatay İşletme Kartı (Seçenek B)

`_NearbyVerifiedSpotCard` (dikey, 16:9 görsel üstte) yerine yeni
`_ForYouBusinessCard` (yatay düzen) eklenir:

- Sol taraf (`Expanded`, dikey `Column`, `mainAxisAlignment: spaceBetween`):
  - Üst: işletme adı (`titleMedium`, `w900`), altında `"{kategori} • {mutfak}"`,
    altında `"{mesafe} • {tahmini süre}"` (mevcut `item.distanceKm` ve
    `t.distanceKm(...)` formatlayıcısı; tahmini süre için mevcut bir alan yoksa
    bu satır yalnızca mesafe gösterir — süre alanı `BusinessCardModel`'da yoksa
    eklenmez, kapsam dışı).
  - Alt satır: sol tarafta `_OpenStatusBadge` (mevcut `business_tile.dart`'taki
    "Açık"/"Kapalı" pill, `isOpenNow` null ise gizli), sağ tarafta
    `_PriceLevelBadge`/`_priceLevelBadge(priceLevel, medianPriceCents)` mantığı
    (mevcut `BusinessTile` statik metodu; `business_tile.dart`'tan import edilerek
    veya paylaşılan bir yardımcıya taşınarak yeniden kullanılır — kopya
    yazılmaz).
- Sağ taraf: 96×96 px `ClipRRect` (radius 14) görsel (`CategoryAssets.resolve`
  stok görseli, mevcut davranış), üzerinde:
  - Sol-üst overlay: rating rozeti — `FontAwesomeIcons.star` (`AppColors.star`)
    + `item.avgRating` (mevcut `_NearbyVerifiedSpotCard`'daki rozet stiliyle
    aynı: siyah yarı saydam pill).
  - Sağ-üst overlay: favori kalbi — `Icons.favorite`/`Icons.favorite_border`
    (mevcut `_NearbyVerifiedSpotCard` ile aynı, beyaz daire üzerinde).
- Kart tıklaması: mevcut `onTap` (işletme detay sayfasına gider) ve
  `onFavoriteTap` callback'leri korunur — `_buildNearbyCardsWithAds` içindeki
  çağrı `_NearbyVerifiedSpotCard(...)` yerine `_ForYouBusinessCard(...)` olacak
  şekilde güncellenir, parametre seti büyük ölçüde aynı kalır
  (`item`, `imageAsset`, `ratingLabel`, `isFavorite`, `onTap`, `onFavoriteTap`).
  `averageSpend` ve `updatedLabel`/`statusType` (fiyat doğrulama rozeti) yeni
  yatay düzende **gösterilmez** — bu bilgi kart arkasındaki detay sayfasında
  zaten mevcut.
- Bölüm başlığı: `nearbyVerifiedSpots` yerine yeni anahtar
  `discoverForYou` → `"Senin için keşfet"`.

### 3.4 `_DiscoveryPromoBanner`

- "Senin için keşfet" kart listesinden sonra, reklamlı kart listesinden önce
  eklenir.
- İçerik: `AppCard` (arka plan `AppColors.primarySoft`), sol tarafta başlık +
  alt metin, sağda `FontAwesomeIcons.arrowRight` ikonlu dairesel
  `IconButton`/`FilledButton` (renk `AppColors.primary`).
- Tıklama: `showModalBottomSheet(... builder: (_) => const _WhatToEatSheet())`
  — mevcut `_openWhatToEatSheet`/satır ~1753 ile aynı çağrı, yeni bir sheet
  yazılmaz.
- Metin için **mevcut** ARB anahtarları yeniden kullanılır (yeni anahtar
  gerekmez): `whatToEatTitle` ("Ne yesek?") başlık olarak, `whatToEatDescription`
  ("Tercihlerine göre öneriler") alt metin olarak.

## 4. Yeni ARB Anahtarları (özet)

| Anahtar | TR | EN |
|---|---|---|
| `discoveryGreetingHello` | "Merhaba {name} 👋" | "Hi {name} 👋" |
| `discoveryGreetingHelloAnon` | "Merhaba 👋" | "Hi 👋" |
| `discoveryGreetingSubtitle` | "Bugün ne yemek istersin?" | "What do you feel like eating today?" |
| `discoveryFeaturedCategory` | "Öne Çıkanlar" | "Featured" |
| `discoverForYou` | "Senin için keşfet" | "Discover for you" |

`app_tr.arb` + `app_en.arb` üzerine eklenip
`node packages/l10n_assets/scripts/sync-l10n.mjs` ile senkronize edilecek
(mevcut workflow — `tools/ceviri-denetimi.mjs` ile doğrulanır).

## 5. İkonlar

Tüm yeni ikonlar `font_awesome_flutter` (mevcut bağımlılık) üzerinden:
- "Öne Çıkanlar" çipi: `FontAwesomeIcons.star`
- Rating rozeti (yatay kart): `FontAwesomeIcons.star` (mevcut `AppColors.star` rengiyle, `_NearbyVerifiedSpotCard` ile birebir aynı stil)
- Promo banner ok butonu: `FontAwesomeIcons.arrowRight`
- Favori kalp: `Icons.favorite`/`Icons.favorite_border` (Material — mevcut davranışla tutarlı, değiştirilmez)
- "Açık/Kapalı" rozeti: mevcut `_OpenStatusBadge` (nokta + renk, ikon yok) — değişmez

Yeni asset/resim dosyası **eklenmez**.

## 6. Veri Akışı

Yeni veri kaynağı veya RPC değişikliği yok:
- Karşılama: `authStateProvider`/`publicProfile.displayName` (mevcut)
- Kategori çipleri: `discoveryHomeCategories` (mevcut, `categories_config.dart`)
- "Senin için keşfet": `discoverySearchProvider` → `st.items` (mevcut, aynı liste
  şu an "Yakındaki Mekanlar" altında render ediliyor)
- Promo banner: statik metin + mevcut `_WhatToEatSheet`

## 7. Test Planı

- `flutter analyze` (zorunlu — Flutter kod değişikliği)
- `flutter test` — mevcut discovery widget testleri (varsa) yeni komponent
  adlarına göre güncellenir; `_ForYouBusinessCard` için temel render testi
  (rating/favori/açık-kapalı/fiyat seviyesi rozetlerinin doğru koşullarda
  gösterildiği)
- `node tools/ceviri-denetimi.mjs` — yeni ARB anahtarları için i18n audit
- Manuel: `flutter run` ile Keşfet sayfasının üst bölümü mockup ile
  karşılaştırılır (isim var/yok durumları, kategori çipi tıklamaları,
  promo banner → "Ne yesek?" sheet açılışı)

## 8. Riskler / Açık Noktalar

- `_ForYouBusinessCard` yeni düzeninde "tahmini süre" (örn. "20-30 dk") mockup'ta
  var ama `BusinessCardModel`'da karşılığı yok → **gösterilmeyecek**, sadece
  mesafe gösterilecek. Bu netlik için maddeye eklendi (belirsizlik giderildi).
- `_priceLevelBadge` statik metodu şu an `business_tile.dart` içinde private
  (`_PriceLevelBadge`/`_priceLevelBadge`). Yeniden kullanım için ya `business_tile.dart`'tan
  export edilecek ya da paylaşılan bir yardımcıya taşınacak — implementasyon
  planında netleştirilecek, tasarım niyeti: **kod kopyalanmayacak**.
