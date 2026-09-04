# /m/[slug] Dil Desteği Tasarımı

## Sorun

`/m/[slug]` — QR ile taranan, 42K+ işletmenin kullandığı asıl public menü sayfası — `?lang=` parametresini kabul ediyor ve bunu `normalized.lang` olarak hesaplıyor, ama:

1. **Menü öğesi çevirileri hiç gösterilmiyor.** `MenuDuzen` bileşeni ürün adı/açıklamasını (`item.name`/`item.description`) doğrudan ham haliyle kullanıyor — `getTranslationValue()` hiç çağrılmıyor. Bu oturumda kurulup canlı API çağrılarıyla doğrulanan otomatik menü çevirisi pipeline'ı (Gemini/Groq/Cloudflare, `menu_translations` tablosuna yazıyor) bu yüzden **hiçbir gerçek ziyaretçiye hiç ulaşmıyor**.
2. **Kategori adı çevirisi sessizce no-op.** Tek çeviri denemesi `locale: 'tr'` sabit yazılmış — ziyaretçinin gerçek dili ne olursa olsun her zaman Türkçe satırı arıyor.
3. **Arayüz metinleri (chrome) hiç lokalize değil.** Breadcrumb, arama kutusu, buton etiketleri, alerjen sözlüğü, "Tükendi"/"Açık"/"Kapalı" gibi durum metinleri `menu-duzen.tsx` içinde (619 satır) tamamen sabit Türkçe.
4. **Görünür dil seçici yok.** `?lang=en` sadece elle URL yazılırsa devreye giriyor, keşfedilemez.

`src/lib/ceviri.ts`'deki `copy.tr`/`copy.en` sözlüğü (tam parite, 64 anahtar) tam bu sayfa için yazılmış görünen anahtarlar içeriyor (`searchPlaceholder`, `allCategories`, `unavailable`, `soldOut`, `openNow`, `closedNow`, `category`...) ama şu an hiç bu sayfaya bağlanmamış — sadece QR üretici ve geri bildirim widget'ında kullanılıyor.

## Kapsam dışı (bilinçli)

- Site geneli i18n (`<html lang>`, hreflang, sitemap, diğer ~80 public sayfa) — ayrı, bilinçli bir karardı (Türkçe-birincil tasarım), bu işin parçası değil.
- `kategoriIkonu()`'nun İngilizce kategori adlarını tanıması — İngilizce isimler genel ikona düşer, kozmetik, düzeltilmeyecek.
- Cookie/session bazlı dil hatırlama — sayfa `revalidate = 300` ile statik/ISR, cookie okumak dinamik render'a zorlar. Sadece URL parametresi (`?lang=`) kullanılacak, zaten var olan `buildBusinessMenuHref`/`normalizeDisplayParams` altyapısıyla.

## Veri akışı düzeltmesi

`app/(genel)/m/[slug]/page.tsx`'teki `renderPublicMenuRoute` zaten `normalized.lang`'i hesaplıyor (satır ~184-194) ama `MenuDuzen`'e hiç geçmiyor. Eklenecek:

```typescript
const labels = copy[normalized.lang]; // ceviri.ts'ten, FeedbackWidget'ın zaten kullandığı desen

<MenuDuzen
  data={data}
  isOpenNow={isOpenNow}
  todayHours={todayHours}
  businessName={businessName}
  lang={normalized.lang}
  labels={labels}
/>
```

`MenuDuzen` içinde:
- Kategori adı: `getTranslationValue({ entityType: 'category', locale: lang, ... })` — `'tr'` sabiti kaldırılır.
- Ürün adı/açıklaması: her `UrunKarti`/`UrunSatiri` render noktasında `getTranslationValue({ entityType: 'item', entityId: item.id, locale: lang, field: 'name'|'description', fallback: item.name|item.description })` çağrılır. Çeviri yoksa (satır `menu_translations`'ta hiç yoksa) otomatik olarak Türkçe'ye düşer — veri kaybı riski yok, sadece mevcut davranışın aynısı.

## Arayüz metinleri

`ceviri.ts`'deki `copy` sözlüğüne eksik anahtarlar eklenir (hem `tr` hem `en`):
- Breadcrumb: `breadcrumbDiscover` ("Keşfet"), `breadcrumbRestaurants` ("Restoranlar"), `breadcrumbMenu` zaten `pageView`/`category` gibi yakın anahtarlar var, yeni özel anahtar eklenir.
- Aksiyon butonları: `favoriteButton` ("Favori"), `shareButton` ("Paylaş"), `reserveTableButton` ("Masa Ayırt").
- Sidebar: `menuCategoriesTitle` ("Menü Kategorileri"), `featuredCategoryLabel` ("Öne Çıkanlar" — sözde kategori, gerçek kategori değil), `promoBannerTitle`/`promoBannerBody`.
- Liste: `showMoreButton` ("Daha fazla göster"), `noSearchResultsPrefix`/`noSearchResultsSuffix` (tırnak içindeki sorguyla birleşecek), `noSearchResultsHint`.
- Durum: `verifiedBusinessLabel` ("Doğrulanmış İşletme"), `priceOnRequest` ("Fiyata sorunuz").
- Alerjen sözlüğü: `ALLERGEN_LABEL` objesi `menu-duzen.tsx`'ten `ceviri.ts`'e taşınır, `{tr: {...}, en: {...}}` şekline genişletilir (14 anahtar, İngilizce karşılıkları standart alerjen terimleri — Gluten, Milk, Eggs, Fish, Shellfish, Peanuts, Tree Nuts, Soy, Celery, Mustard, Sesame, Sulphites, Lupin, Molluscs).
- `fiyat()` yardımcı fonksiyonu artık `labels.priceOnRequest` parametresi alır (saf fonksiyon olmaktan çıkmaz, sadece bir parametre eklenir).

`unavailable`/`soldOut`/`allCategories`/`searchPlaceholder`/`category`/`openNow`/`closedNow` gibi zaten var olan anahtarlar doğrudan kullanılır, yeniden yazılmaz.

## Dil seçici

İşletme başlığının yanında (`<h1>{businessName}</h1>`'in hemen sağında/altında), küçük iki link:

```tsx
<Link href={buildBusinessMenuHref({ business, lang: 'tr', theme, src, preview })}>TR</Link>
<Link href={buildBusinessMenuHref({ business, lang: 'en', theme, src, preview })}>EN</Link>
```

Aktif dil vurgulanır (kalın/renkli), diğeri link. `buildBusinessMenuHref` zaten `lang` parametresini destekliyor — yeni bir fonksiyon gerekmiyor. Bu linkler server component'te (`page.tsx`) inşa edilip prop olarak geçirilir ya da `MenuDuzen` içinde `business`/`theme`/`src`/`preview` prop'larından client tarafında inşa edilir (implementasyon planında netleştirilecek, ikisi de teknik olarak eşdeğer).

## Doğrulama

`pnpm run typecheck` + `pnpm run lint`. Canlı tarayıcı testi: gerçek çevrilmiş bir işletme/ürün bulunup (varsa) `?lang=en` ile açılıp hem ürün adının hem arayüz metinlerinin İngilizce geldiği, seçiciye tıklayınca `?lang=tr`'ye dönüldüğü doğrulanacak. Çevirisi olmayan bir işletme için `?lang=en`'de ürün adının Türkçe'ye (fallback) düştüğü ama chrome'un İngilizce kaldığı doğrulanacak (karma durum, beklenen davranış).
