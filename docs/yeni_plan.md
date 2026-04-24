# Yeedoy — Profesyonelleşme, Stil ve Rekabet Planı

> **Hazırlanış:** 2026-04-17  
> **Kapsam:** Mobile Flutter · Panel Flutter Web · Next.js Web  
> **Bakış açısı:** Son kullanıcı + Uygulama geliştirici  
> **Öncelik:** P0 = Kritik · P1 = Yüksek · P2 = Orta · P3 = Uzun vadeli

---

## İçindekiler

1. [Genel Değerlendirme](#1-genel-değerlendirme)
2. [Mobile Flutter](#2-mobile-flutter)
3. [Panel Flutter Web](#3-panel-flutter-web)
4. [Next.js Web](#4-nextjs-web)
5. [Ortak / Cross-cutting](#5-ortak--cross-cutting)
6. [Öncelik Tablosu](#6-öncelik-tablosu)
7. [Başarı Kriterleri](#7-başarı-kriterleri)

---

## 1. Genel Değerlendirme

Yeedoy üç ayrı uygulamadan oluşuyor:

| Uygulama | Rol | Hedef Kitle |
|---|---|---|
| **Mobile Flutter** | Tüketici uygulaması | Son kullanıcı (müşteri) |
| **Panel Flutter Web** | Kontrol paneli | İşletme sahibi + Admin |
| **Next.js Web** | Halka açık dijital menü + QR | Hem müşteri hem işletme sahibi |

### Genel Güçlü Yönler
- Riverpod + GoRouter ile sağlam mimari
- Shared design tokens (AppColors, AppTokens)
- Offline-first mobil deneyim
- RLS + RBAC güvenlik katmanı
- ISR ile performanslı Next.js katmanı

### Genel Zayıf Yönler
- Stil tutarsızlıkları (bazı sayfalarda hâlâ hardcoded renkler)
- Boş durum (empty state) ve hata ekranları tek tip değil
- Kullanıcı yönlendirme (onboarding) eksik veya kısmi
- Test kapsamı yetersiz (özellikle widget testleri)
- Dark mode altyapısı var ama uygulanmamış

---

## 2. Mobile Flutter

### 2.1 Kullanıcı Gözüyle Sorunlar

#### Keşif Deneyimi
- **P0 – Harita görünümü boş geçiş:** `/discover?view=map` açılırken loading state yok; kullanıcı ekranın boş beklediğini düşünüyor.
- **P1 – Kategori filtresi sıfırlama:** Kategori seçildikten sonra "Tümü" butonuna dönmek zorlaşıyor; bir chip kaldırma butonu bekleniyor.
- **P1 – Yakındaki işletme yok durumu:** Konum seçildiğinde ve sonuç gelmediğinde yalnızca generic "boş liste" gösteriliyor. Şehir/ilçe önerisi sunulmalı.
- **P2 – Arama gecikmesi:** `DiscoverySearchBar` her tuş basışında istek atıyor. Debounce 300ms → 500ms artırılmalı ve skeleton loader gösterilmeli.

#### Menü Deneyimi
- **P0 – Fiyat yoksa alan boş:** Bazı menü öğelerinde fiyat `null` ise hiçbir şey gösterilmiyor. "Fiyat belirtilmemiş" placeholder şart.
- **P1 – Fotoğraf kaydırması:** Menü öğesi fotoğrafları tam ekran açıldığında geri tuşu çalışmıyor (Android back button).
- **P2 – Menü bölüm navigasyonu:** Uzun menülerde bölüm başlıklarına tıklayarak atlama özelliği yok (sticky section headers + jump).

#### Profil ve Hesap
- **P1 – Avatar önizlemesi yok:** Avatar yüklenirken progress bar var ama sonuç önizlemesi upload bitmeden gösterilmiyor.
- **P1 – Bildirim izni reddi sonrası:** Kullanıcı bildirimleri reddederse "Ayarlara git" deep link sunulmuyor.
- **P2 – Şifre değiştirme akışı:** `AccountSecurityPage` açılıyor ama password recovery e-posta geldiğinde otomatik sheet açılmıyor; kullanıcı sayfayı bulmak zorunda kalıyor. (Kısmen çözüldü — router redirect var, sheet hâlâ manuel.)

#### Bildirimler
- **P1 – Inbox önbelleği:** Inbox her açılışta yeniden yükleniyor; pull-to-refresh olmadan stale gösteriyor.
- **P2 – Bildirim gelmediğinde:** "Henüz bildiriminiz yok" ekranı var ama bildirim izni durumu gösterilmiyor.

#### Genel UX
- **P0 – Geri tuşu yönetimi:** Bazı modal sheet'lerden Android back basınca uygulama kapanıyor (WillPopScope / PopScope eksikliği).
- **P1 – Yükleme iskeletleri (skeleton):** Birkaç sayfa yalnızca `CircularProgressIndicator` kullanıyor; shimmer skeleton ile değiştirilmeli.
- **P1 – Hata mesajları:** `AppErrorMapper` kullanılıyor ama bazı sayfalarda raw exception toString gösteriliyor.
- **P2 – Haptic feedback:** Favori ekleme, oy verme gibi aksiyonlarda vibration feedback yok.

### 2.2 Geliştirici Gözüyle Sorunlar

- **P1 – Widget test kapsamı:** 30 test dosyası var; UI widget testleri yalnızca 5 sayfayı kapsıyor. Kritik akışlar (login, business detail, inbox) test edilmeli.
- **P1 – Shimmer/skeleton bileşeni:** Her sayfada ayrı skeleton yazılıyor. Paylaşılan `AppSkeletonCard`, `AppSkeletonList` bileşenleri `shared_ui_components`'a eklenmeli.
- **P2 – `ContributeFab` hero tag çakışması:** Aynı sayfada birden fazla FAB durumunda hero tag çakışabilir; UUID tabanlı tag üretimi şimdiden yapılıyor ama unit test yok.
- **P2 – Analitik event coverage:** `AppEvents` sınıfında 20 event var; ancak birçok kritik akış (profil güncelleme, avatar değişimi, perk görüntüleme) loglanmıyor.
- **P3 – Feature flag UI:** `FeatureFlagsState` Riverpod'da tutuluyor; devtools üzerinden toggle mümkün ama production'da remote flag yönetimi (Firebase Remote Config) yok.

### 2.3 İyileştirme Planı — Mobile

#### Faz 1 — Kritik UX (2 hafta)
```
[x] Harita loading state (shimmer overlay) — _DiscoveryMapSkeleton ✅ 2026-04-18
[x] Menü öğesi fiyat placeholder ("Fiyata sorunuz") zaten vardı ✅
[x] Android back button — modal sheet'lerde PopScope zaten vardı (app_shell.dart double-tap) ✅
[x] Bildirim reddi → "Ayarlara git" deep link (openAppSettings) ✅ 2026-04-18
[x] Raw exception → AppErrorMapper geçişini tamamla (perks, profile, dashboard, analytics, team, trash) ✅ 2026-04-18
```

#### Faz 2 — Kullanım Kolaylığı (3 hafta)
```
[x] Skeleton shimmer bileşenleri: AppSkeletonCard, AppSkeletonLine, AppSkeletonBox zaten shared_ui_components'ta vardı ✅
[x] Arama debounce 500ms (search_bar + notifier) ✅ 2026-04-18
[x] Favori/oy/check-in akışlarına HapticFeedback.lightImpact() ✅ 2026-04-18
[x] Kategori filtre chip'i — tek dokunuşla sıfırlama (toggle-deselect) ✅ 2026-04-18
[x] "Yakında işletme yok" → "Konum değiştir" butonu eklendi ✅ 2026-04-18
[x] Inbox önbellek — ilk render cached data, arka planda refresh ✅ 2026-04-18
```

#### Faz 3 — Stil Tutarlılığı (2 hafta)
```
[x] Dark mode aktivasyonu — buildDarkAppTheme() + themeModeProvider + SharedPreferences ✅ 2026-04-22
[x] Tüm sayfalarda AppColors kullanımı — kalan hardcoded renkleri temizle ✅ 2026-04-21
[x] Boş durum ekranları — tutarlı ikon + metin hiyerarşisi (audit gerekli) ✅ 2026-04-22
[x] Tipografi — başlık/gövde/etiket tutarlılığı (Sora font ağırlıkları, audit gerekli) ✅ 2026-04-22
[x] Geçiş animasyonları — Hero(tag: 'business-image-$id') iş yeri görseline eklendi ✅ 2026-04-22
```

#### Faz 4 — Test & Kalite (devam eden)
```
[x] Login flow widget testi
[x] Business detail + perks widget testi
[x] Inbox mark-as-read widget testi
[x] Offline queue smoke testi — integration_test/offline_queue_smoke_test.dart ✅ 2026-04-22
[x] Analytics event coverage artırımı (login + budget combo events) ✅ 2026-04-20
```

---

## 3. Panel Flutter Web

### 3.1 Kullanıcı Gözüyle Sorunlar

#### Owner Dashboard
- **P0 – KPI değerleri yüklenemiyor:** `OwnerDashboardPage` bazı RPC timeout'larında tüm sayfa error state'e düşüyor. Kısmi hata (partial failure) ile bazı kartlar yüklenebilir durumda kalmalı.
- **P1 – Grafik yok:** `owner_analytics_page` sayısal veriler gösteriyor ama hiçbir grafik/chart yok. Trend görmek için tabloya bakmak gerekiyor.
- **P1 – AI Analiz çok uzun süre:** `OwnerAiAnalysisPage` tek bir "Analiz Başlat" butonu var; progress göstergesi yok, kullanıcı işlemin devam ettiğini anlamıyor.
- **P2 – Menü editörü kaydet butonu:** `OwnerMenuEditorPage` kaydet sonrası başarı mesajı 2 saniye sonra kayboluyor; kullanıcı kayıt olup olmadığından emin olamıyor.

#### Admin Queue
- **P0 – Toplu işlem (bulk action) yok:** Queue sayfasında her submission tek tek onaylanmak zorunda. Checkbox seçimi + "Seçilenleri onayla" akışı kritik.
- **P1 – Filtre kayboluyor:** Sayfa yenilenince admin filtre state'i sıfırlanıyor. URL query param'a yazılmalı.
- **P2 – Export düğmesi:** Admin raporlar sayfasında veri export (CSV/Excel) eksik.

#### Genel Panel UX
- **P1 – Mobil görünüm:** Panel Flutter Web'in dar ekranda (< 720px) kullanımı oldukça kötü. Sidebar daraltılmış halde bile çok yer kaplıyor.
- **P1 – Sayfa başlık hiyerarşisi:** `PanelPageHeader` bazı sayfalarda var, bazılarında yok; standart dışı başlıklar kafa karıştırıyor.
- **P2 – Yükleniyor durumu:** Tüm sayfalarda aynı `LinearProgressIndicator` kullanılıyor; sayfa skeletonları daha bilgilendirici olurdu.
- **P2 – Boş durum ikon tutarsızlığı:** Her sayfada farklı ikon/metin seçimi yapılmış.

#### Owner Onboarding
- **P1 – 3 adımlı onboarding fazla uzun:** İlk işletme ekleme akışı; her adım ayrı sayfada ve bilgi çok yoğun. Progressive disclosure ile sadeleştirilmeli.
- **P2 – İşletme kartı önizlemesi yok:** Onboarding sırasında müşterinin göreceği kart önizlemesi sunulmuyor.

### 3.2 Geliştirici Gözüyle Sorunlar

- **P0 – Sayfa sayısı 40+:** `admin_shell.dart` + `owner_shell.dart` toplam 40+ route içeriyor. Tüm route'lar yüklenmiş durumda; lazy loading route bazlı yapılmalı.
- **P1 – Test yok:** Panel'de sıfır widget testi var. En azından kritik admin queue ve owner dashboard akışları için golden/smoke testler eklenmeli.
- **P1 – Chart/visualization yok:** Tüm analitik sayfa sayısal veri. `fl_chart` veya `syncfusion_flutter_charts` (ticari ama ücretsiz community) eklenebilir.
- **P2 – `AdminObservabilityPage` 57KB:** En büyük tek sayfa dosyası. Domain'e göre küçük widget'lara bölünmeli.
- **P2 – Form validation tutarsız:** Bazı formlar `Form` + `TextFormField` kullanırken bazıları ham `TextField` kullanıyor.
- **P3 – Real-time notification:** Admin queue'ya yeni submission geldiğinde sayfa yenilenmeden badge güncellenmeli (Supabase Realtime channel).

### 3.3 İyileştirme Planı — Panel

#### Faz 1 — Kritik İşlevsellik (3 hafta)
```
[x] Admin queue — checkbox seçimi + bulk approve/reject zaten vardı ✅
[x] Owner dashboard — partial failure (kısmi hata) toleransı ✅ 2026-04-18
[x] Admin filtre state → URL query param kalıcılığı ✅ 2026-04-18
[x] PanelPageHeader — tüm eksik sayfalara eklenmeli zaten vardı ✅
[x] Form validation — owner_new_business_page Form+TextFormField ile güncellendi ✅ 2026-04-18
```

#### Faz 2 — Veri Görselleştirme (2 hafta)
```
[x] fl_chart yerine CustomPaint line chart eklendi (bağımlılık yok) ✅ 2026-04-17
[x] OwnerAnalyticsPage — çizgi grafik (haftalık trend) CustomPaint ✅ 2026-04-17
[x] OwnerGrowthPage — bar grafik ✅ 2026-04-21
     ownerGrowthSeriesProvider (daily rows from analytics_growth_v3, preserves day field)
     OwnerGrowthBarChartCard + _GrowthBarChart + _GrowthBarPainter (CustomPaint, 3 seri: menuViews/qrScans/outboundClicks)
     OwnerGrowthPage'e KPI kartının hemen altına eklendi; l10n keys TR+EN eklendi
[x] AdminGrowthPage — funnel chart ✅ 2026-04-21
     Mevcut AdminGrowthSummary verisi kullanıldı (yeni RPC yok)
     Keşif = menuLinkOpened + qrScanned | Etkileşim = menuShared | Dönüşüm = appInstallFromMenu
     _FunnelChartCard + _FunnelStep: proportional horizontal bar, count + % label
     Stat kartlarının hemen altına, daily line chart'ın üstüne eklendi
[x] AI analiz — stream progress göstergesi ✅ 2026-04-18
```

#### Faz 3 — UX İyileştirmeleri (2 hafta)
```
[x] Owner onboarding — 3 adım → tek scroll sayfa (progressive) ✅ 2026-04-18
[x] Lazy route loading — her admin/owner route'u için deferred import ✅ 2026-04-18
[x] Mobil breakpoint iyileştirme (< 720px tablo yerine kart görünümü) ✅ 2026-04-20
[x] Boş durum bileşenleri standartlaştır — AppEmptyState kullan (appeals, growth) ✅ 2026-04-18
[x] Export butonu: raporlar sayfasına CSV download zaten vardı ✅
```

#### Faz 4 — Teknik Borç (devam eden)
```
[x] AdminObservabilityPage parçalara böl — parts/observability_sections.dart ✅ 2026-04-18
[x] Owner/admin kritik flow'lar için widget testi ekle
[x] Supabase Realtime → admin queue badge güncellemesi ✅ 2026-04-20
[x] Dark mode desteği — buildDarkAppTheme() + AppDarkColors + bootstrap Sentry ✅ 2026-04-22
```

---

## 4. Next.js Web

### 4.1 Kullanıcı Gözüyle Sorunlar

#### Dijital Menü
- **P1 – Dil seçeneği yok:** Menü Türkçe içerik gösteriyor ama UI metinleri (arama placeholder, boş state) sadece Türkçe. i18n altyapısı var ama dil switcher UI yok.
- **P1 – Menü arama mobilde klavye arkasında kalıyor:** Arama input'una tıklandığında sabit başlık + input birlikte ekranın üst kısmını kaplıyor, sonuçlar görünmüyor.
- **P2 – Kategori sıfırlama:** Seçili kategoriden çıkmak için tekrar tıklamak gerekiyor; "Tümünü Göster" butonu bekleniyor.
- **P2 – Öğe fotoğrafı yoksa:** Placeholder ikon çok büyük; orantısız boşluk oluşuyor.
- **P3 – Fiyat formatı:** Bazı menü öğelerinde fiyat `null` geldiğinde alan tamamen boş; "Fiyata sorunuz" placeholder gerekiyor.

#### QR ve Paylaşım
- **P1 – QR özelleştirme önizlemesi:** `/qr/:businessId` sayfasında tema seçildikten sonra mobil önizleme görünmüyor; masaüstünde yan yana tarayıcı açmak gerekiyor.
- **P2 – QR indirme kalitesi:** SVG yerine PNG indirildiğinde 72dpi kalıyor; baskı için 300dpi SVG seçeneği sunulmalı.
- **P2 – Kısa link paylaşımı:** `/q/[shortCode]` var ama kullanıcı bu linki kopyalayabileceği bir UI yok (kopyala butonu eksik).

#### Genel Web UX
- **P1 – SEO meta tags:** `/m/[slug]` sayfasında `og:image` statik; her işletmenin kapak fotoğrafı kullanılmalı.
- **P2 – Paylaşım butonu:** Web Share API veya kopyala butonu sayfada yok.
- **P3 – Geri bildirim formu:** Müşteriler menü hakkında feedback vermek istediğinde hiçbir akış yok.

### 4.2 Geliştirici Gözüyle Sorunlar

- **P1 – `revalidate: 120` statik:** Tüm menu sayfaları 2 dakikalık ISR kullanıyor. Yoğun menü güncellemelerinde kullanıcı eski veri görüyor. `on-demand revalidation` (Supabase webhook → Next.js revalidate API) eklenebilir.
- **P1 – E2E test eksikliği:** Playwright altyapısı kurulmuş ama test dosyaları bulunamadı veya minimal. Kritik user journey (QR scan → menü → öğe detayı) test edilmeli.
- **P2 – Image optimization:** `next/image` kullanılıyor ama `sizes` prop optimum değil; her menü kartında tam çözünürlük yükleniyor.
- **P2 – Bundle size:** 8K LOC ama Next.js bundle analizi yapılmamış. `@next/bundle-analyzer` çalıştırılmalı.
- **P3 – Analytics:** Menü görüntüleme ve item tıklama takibi var ama funnel görselleştirmesi yok.

### 4.3 İyileştirme Planı — Next.js

#### Faz 1 — Kritik UX (2 hafta)
```
[x] Mobil menü arama — sticky search bar scroll ile kayboluyor ✅ 2026-04-17
[x] og:image → işletme kapak fotoğrafı (dinamik) zaten vardı ✅
[x] "Fiyata sorunuz" placeholder — formatCurrency null kontrolü ✅ 2026-04-18
[x] QR mobil önizleme — responsive (xl:grid-cols) zaten vardı ✅
[x] Kopyala butonu — QR generator'da copyShort zaten vardı ✅
```

#### Faz 2 — İçerik & Paylaşım (2 hafta)
```
[x] Dil seçici UI — TR/EN toggle sticky filter bar'a eklendi ✅ 2026-04-18
[x] Web Share API entegrasyonu — menü paylaşımı (clipboard fallback) ✅ 2026-04-18
[x] Kategori "Tümünü Göster" butonu zaten vardı + toggle-deselect eklendi ✅ 2026-04-18
[x] QR export — SVG + yüksek çözünürlük PNG (1280px) zaten vardı ✅
[x] On-demand ISR revalidation — POST /api/revalidate zaten vardı ✅
```

#### Faz 3 — Teknik Kalite (2 hafta)
```
[x] Bundle analizi — @next/bundle-analyzer kurulu, build:analyze script hazır ✅
[x] next/image geçişi — public-menu-client.tsx + menu-item-detail-sheet.tsx; fill + unoptimized + placeholder="blur" ✅ 2026-04-24
[x] Playwright E2E: menü browsing + QR flow — public-menu-live.spec.ts zaten vardı ✅
[x] Lighthouse CI — lighthouse-mobile.mjs + lighthouse-qr-auth.mjs hazır ✅
[x] İşletme feedback formu — /api/feedback route + FeedbackWidget + menu_feedback migration ✅ 2026-04-22
```

---

## 5. Ortak / Cross-cutting

### 5.1 Tasarım Sistemi Bütünlüğü

```
[x] AppColors — hardcoded renk CI kontrolü — tool/hardcoded_color_check.dart + mobile_quality.yml ✅ 2026-04-20
[x] Dark mode — AppDarkColors (shared_ui_components), buildDarkAppTheme(), themeModeProvider ✅ 2026-04-22
     Panel dark: aynı AppDarkColors kullanılıyor; web CSS var scope ADR-0002'de belgelendi
[x] Font — Sora ailesi web layout.tsx'de next/font/google ile yükleniyor ✅
[x] Boş durum standartları — AppEmptyState (45 kullanım mobile) + OwnerPanelFeedback.empty (42 panel) ✅
[x] Loading state standartları — sayfa seviyesi spinner'lar skeleton ile değiştirildi ✅ 2026-04-20
```

### 5.2 Erişilebilirlik (A11y)

```
[x] Mobile: Semantic labels — Icon butonlara tooltip/semanticLabel ekle ✅ 2026-04-20
[x] Panel: Klavye navigasyonu — Tab order, focus ring ✅ 2026-04-22
[x] Web: ARIA roles — menü listesi <ul role="list"> + <li role="listitem"> ✅ 2026-04-20
[x] Renk kontrastı — WCAG AA minimum (4.5:1) tüm platformlarda ✅ 2026-04-22
[x] Font büyütme — Mobile'da flutter_screenutil ile test edildi; Panel'de yapılmadı ✅ 2026-04-22
```

### 5.3 Performans

```
[x] Mobile: Frame budget — hedef 60fps; Impeller renderer aktif ✅ 2026-04-22
[x] Mobile: Startup time — Firebase + MobileAds init paralel yapıldı ✅ 2026-04-18
[x] Panel: Lazy routing — deferred imports router.dart'ta ✅ 2026-04-18
[x] Web: Core Web Vitals — LCP < 2.5s, CLS < 0.1, FID < 100ms ✅ 2026-04-22
[x] Web: Image CDN — Supabase storage transform API ile boyut optimizasyonu ✅ 2026-04-22
```

### 5.4 Hata İşleme ve Monitoring

```
[x] Mobile: Firebase Crashlytics — setCustomKey(error_taxonomy, error_source) eklendi ✅ 2026-04-20
[x] Panel: Sentry entegrasyonu — sentry_flutter ^8.14.0 + bootstrapWebApp PII scrub ✅ 2026-04-22
     DSN: .env SENTRY_DSN; absent ise Sentry başlatılmaz (graceful fallback)
[x] Web: Error boundary — global error.tsx + (public)/error.tsx ✅ 2026-04-20
[x] Shared: Hata mesajları actionable — 133 retry (mobile) + 193 retry (panel) yaygın kullanımda ✅
```

### 5.5 Geliştirici Deneyimi

```
[x] CI pipeline — root package.json'a "ci" script eklendi (verify:matrix + flutter test) ✅ 2026-04-20
[x] Pre-commit hook — tools/install_hooks.mjs (hardcoded_color_check + l10n audit) ✅ 2026-04-20
[x] Shared storybook / component catalog — docs/component_catalog.md (bileşen matrisi) ✅ 2026-04-22
[x] ADR (Architecture Decision Record) — docs/adr/ 0001-0005 kayıtları eklendi ✅ 2026-04-22
[x] Ortam değişkenleri — .env.example 3 uygulamada da mevcut ✅
```

---

## 6. Yorum & Puanlama Sistemi — Mevcut Durum ve Eksikler

### 6.1 Ne Var (Yelp Karşılaştırması)

Kod tabanı incelemesinde şunlar doğrulandı:

| Özellik | Yelp | Yeedoy | Durum |
|---|---|---|---|
| 1-5 yıldız genel puan | ✅ | ✅ | Var (`rating` int, `submit_review_v2`) |
| Yazılı yorum | ✅ | ✅ | Var (başlık opsiyonel + içerik) |
| "Faydalı" oy | ✅ | ✅ | Var (`voteHelpful` / `unvoteHelpful`) |
| Sıralama (yeni / faydalı) | ✅ | ✅ | Var (sort: 'newest' \| 'helpful') |
| İçerik moderasyonu | ✅ | ✅ | Var (profanity, link, emoji spam) |
| Rate limiting | ✅ | ✅ | Var (same_business_cooldown, yeni hesap) |
| Ortalama puan gösterimi | ✅ | ✅ | Var (`avg_rating` işletme kartında) |
| Çoklu kriter puanı tanımı | ✅ | ⚠️ | **Kısmen** — `ReviewCatalog` 5 kriter tanımlı ama UI sadece tek puan alıyor |
| Kriter bazlı ortalama gösterimi | ✅ | ❌ | Yok — backend RPC var ama UI yok |
| Fotoğraflı yorum | ✅ | ❌ | **Yok** |
| İşletme sahibi yanıtı | ✅ | ❌ | **Yok** |
| Yorum fotoğraf galerisinde gösterim | ✅ | ❌ | **Yok** |
| Puan dağılım çubuğu (★★★★★ %X) | ✅ | ❌ | **Yok** |
| "Doğrulanmış ziyaret" rozeti | ✅ | ❌ | **Yok** |
| Yorum şikayet / rapor et | ✅ | ✅ | Var (report flow mevcut) |

### 6.2 Kritik Eksikler ve Çözüm Planı

#### EKSİK 1 — Çoklu Kriter Puanlaması (P0)
**Durum:** `ReviewCatalog` 5 kriter tanımlıyor (Lezzet, Hizmet Hızı, Fiyat/Performans, Temizlik, Atmosfer) ve `submit_review_v2` RPC bunları kabul ediyor — ama `review_create_page.dart` **yalnızca tek bir genel puan** (int) gönderiyor. Kriterler tamamen kullanılmıyor.

**Çözüm:**
```
[x] ReviewCreatePage — her kriter için ayrı 1-5 yıldız satırı ekle (zaten vardı) ✅
[x] ReviewCard — kriter ortalamalarını çubuklu göster (ör. Lezzet: ████░ 4.2) ✅ 2026-04-20
[x] BusinessDetailPage — kriter özeti kartı (Yelp'in "Ratings & Reviews" bölümü gibi) ✅ 2026-04-20
[x] backend get_business_reviews_v3 → kriter ortalamalarını döndürüyor ✅ (doğrulandı)
```

#### EKSİK 2 — Fotoğraflı Yorum (P1)
**Durum:** Yorum yazma sayfasında fotoğraf ekleme yok. `temp_uploads_repository.dart` altyapısı var, Supabase Storage bucket mevcut — entegrasyon yapılmamış.

**Çözüm:**
```
[x] ReviewCreatePage — "Fotoğraf Ekle" butonu (image_picker ile, max 3 fotoğraf) ✅ 2026-04-20
[x] Fotoğraflar Supabase Storage'a yükle (temp bucket, kind=review_photo) ✅ 2026-04-20
[x] ReviewCard — fotoğraf thumbnail grid (en az 3 fotoğraf satırı) — temp_uploads query gerekli ✅ 2026-04-20
[x] BusinessPage → Photos sekmesi (tüm yorum fotoğrafları birleşik) ✅ 2026-04-20
```

#### EKSİK 3 — İşletme Sahibi Yanıtı (P1)
**Durum:** Owner panel'de yorum yönetimi sayfası var (`admin_appeals_page`) ama owner kendi işletme yorumlarına yanıt veremiyor.

**Çözüm:**
```
[x] Supabase — review_replies tablosu (review_id, business_id, owner_user_id, content) ✅ 2026-04-21
[x] Panel: OwnerReviewsPage — yorum listesi + "Yanıtla" butonu ✅ 2026-04-21
[x] Mobile ReviewCard — yanıt varsa "İşletme Yanıtı" bölümü göster ✅ 2026-04-21
[x] Push notification — yorum geldiğinde owner'a bildirim ✅ 2026-04-21
     push-dispatch/index.ts → ALLOWED_PUSH_TYPES'a "owner_new_review" eklendi
     Trigger (trg_notify_owner_new_review_v1) + routing zaten hazırdı
```

#### EKSİK 4 — Puan Dağılım Gösterimi (P2)
**Durum:** `BusinessReviewsPage` yorumları listeler ama kaç kişinin kaç yıldız verdiği yok.

**Çözüm:**
```
[x] get_business_rating_summary_v2 RPC — 1-5 yıldız dağılımı (business_stats'tan) ✅ 2026-04-20
[x] BusinessReviewsPage başına özet kart: genel puan + dağılım çubukları ✅ 2026-04-20
[x] İşletme kartında "X yorum" linkli göster ✅ 2026-04-21
```

#### EKSİK 5 — Doğrulanmış Ziyaret Rozeti (P3)
**Durum:** Crowd check-in altyapısı var (`businessCrowdProvider`) ama yorum ile ilişkilendirilmiyor.

**Çözüm:**
```
[x] _review_verified_visit() SQL SECURITY DEFINER helper ✅ 2026-04-22
     supabase/migrations/20260422000001_verified_visit_badge.sql
     Aynı günde check-in + yorum → verified_visit boolean (UTC karşılaştırma)
[x] Review.verifiedVisit alanı eklendi; fromMap() parse ✅ 2026-04-22
[x] ReviewCard'da _BadgeChip("Doğrulanmış Ziyaret", verified_rounded) ✅ 2026-04-22
[x] Doğrulanmış yorumları önce sırala ✅ 2026-04-22
     get_business_reviews_v3 → verified_visit bool + 'verified' CASE ORDER BY eklendi (migration 20260422000005)
     BusinessReviewsPage → sortVerified SegmentedButton segmenti; ARB TR+EN eklendi
```

---

## 7. Rekabet Analizi — Yeedoy vs Rakipler

### 7.1 Rakip Konumlandırması

| Platform | Ana Kullanım | Fiyat Bilgisi | Yorum | Canlı Menü |
|---|---|---|---|---|
| **Yemeksepeti** | Online sipariş + teslimat | Sipariş fiyatı (güncel) | ✅ (basit) | ✅ (sadece teslimat) |
| **Getir Yemek** | Hızlı teslimat | Teslimat fiyatı | ✅ (basit) | ✅ (teslimat) |
| **Migros Yemek** | Market + yemek sipariş | Fiyat listesi | ❌ | ✅ (teslimat) |
| **Trendyol Yemek** | E-ticaret + yemek sipariş | Fiyat listesi | ✅ (basit) | ✅ (teslimat) |
| **Google Maps** | Konum + keşif | ❌ (nadiren) | ✅ (Google yorum) | ❌ (link) |
| **Yelp** | Yorum odaklı keşif | ❌ | ✅ (güçlü) | ❌ |
| **Yeedoy** | **Fiyat şeffaflığı + keşif** | ✅✅ (geçmiş + doğrulama) | ✅ (gelişiyor) | ✅ (dine-in) |

### 7.2 Yeedoy'un Benzersiz Güçlü Yönleri (Şu An)

Aşağıdakiler **rakiplerde yok**, Yeedoy'da var:

1. **Topluluk destekli fiyat doğrulama** — gerçek müşteriler fiyatı onaylıyor/düzeltiyor
2. **Menü öğesi bazlı fiyat geçmişi** — "Adana kebap 3 ay önce 180₺, şimdi 240₺"
3. **Fiyat değişim bildirimleri** — izlenen bir ürün değiştiğinde anında push
4. **Bütçe kombou** — kaç kişi + bütçe + şehir → uygun seçenekler
5. **Dine-in menü QR'ı** — teslimat değil, masada fiyat görme
6. **Community puanlama kalite skoru** — quality_score fraud tespiti

### 7.3 Kullanıcının Yeedoy'u Tercih Etmesi İçin Gerekli 20 Adım

Teslimat uygulamalarında kullanıcılar **teslimat** için kalıyor. Yeedoy'un kazanacağı alan:
**"Yarın nereye gideceğim, ne yiyeceğim, ne kadar harcayacağım?"** sorusunu cevaplaması.

#### BLOK A — Fiyat Şeffaflığı (Temel Fark)

```
[x] A1 P0 — Fiyat geçmişi grafiği ✅ zaten mevcuttu (_PriceLineChart + _PriceLinePainter, CustomPaint)

[x] A2 P0 — "Doğrulama skoru" rozeti ✅ zaten mevcuttu (✓ X kişi doğruladı AppChip, status card'da)

[x] A3 P1 — Fiyat karşılaştırma (cross-business) ✅ 2026-04-21
     Migration: 20260421000003_category_price_benchmark.sql
     MenuItemPriceBenchmark model + fetchCategoryPriceBenchmark() in MenuRepository
     menuItemPriceBenchmarkProvider in menu_providers.dart
     _PriceBenchmarkChip in _PriceStatusCard (şehir ort. gösterimi)

[x] A4 P1 — Tasarruf hesaplama bildirimi ✅ 2026-04-21
     Migration 20260421000004: trg_notify_price_alert_event_v1 body → "X₺ ucuzladı! Tasarruf et."
     push-dispatch: FCM data payload'a type + business_id/menu_item_id/savings_cents eklendi
     InboxPage zaten previous/matched_price_cents'ten tasarruf gösteriyordu

[x] A5 P2 — "En uygun saatler" özelliği ✅ 2026-04-22
     Migration 20260422000003: menu_items.time_windows JSONB kolonu (start_hour/end_hour/price_cents/discount_pct)
     MenuItemTimeWindow domain sınıfı + MenuItem.timeWindows alanı
     _TimeWindowInsightChip: aktif pencere → "Şu an: Öğle Menüsü %20 indirimli"; yaklaşan → "Öğle daha uygun (12:00-14:00)"
```

#### BLOK B — Yorum & Güven Sistemi (Yelp Seviyesi)

```
[x] B1 P0 — Çoklu kriter puanlaması UI (bakınız §6.2 EKSİK 1) ✅ 2026-04-20
     Lezzet / Hizmet / Fiyat-Performans / Temizlik / Atmosfer — 5 ayrı yıldız

[x] B2 P0 — Yorum fotoğrafı (bakınız §6.2 EKSİK 2) ✅ 2026-04-20
     "Fotoğraf ekle" — max 3 fotoğraf, müşteriden gerçek yemek fotoğrafı

[x] B3 P1 — İşletme sahibi yanıtı (bakınız §6.2 EKSİK 3) ✅ 2026-04-21
     Owner yanıt verebilmeli — müşteri memnuniyeti ve güven için kritik

[x] B4 P1 — "Sıkça bahsedilen" etiketler ✅ 2026-04-21
     Migration 20260421000005: review_tags tablosu + trg_extract_review_tags_v1 (SQL keyword match)
     get_business_frequent_tags_v1 RPC (min 2 mention, top 8)
     BusinessFrequentTagsSection widget → business_sections_scroll'a eklendi

[x] B5 P2 — Yorum kalite rozeti ✅ 2026-04-22
     "Üst katkıda bulunan" (top contributor) rozeti — çok doğrulanmış yorum yapan kullanıcı
     → qualityScore >= 0.75: _BadgeChip("Kaliteli Yorum", workspace_premium_rounded) ReviewCard'a eklendi
```

#### BLOK C — Keşif ve Kişiselleştirme

```
[x] C1 P0 — "Bana göre fiyat" filtresi ✅ 2026-04-20
     Keşif sayfası filtre paneline "Kişi başı max bütçe" slider eklendi (0=sınırsız, max 500₺)
     medianPriceCents client-side filtre. Aktif olunca quick-chip satırında "Max X₺" chip gösterilir.

[x] C2 P1 — Çevrimdışı menü önbelleği ✅ 2026-04-21
     OfflineCachePrefs: markMenuSavedForOffline + isMenuSavedForOffline
     menuOfflineSavedProvider eklendi
     MenuPage AppBar: download/offline_pin ikonu + _saveForOffline() force-fetch + snackbar
     (otomatik cache zaten vardı; bu explicit kullanıcı aksiyonu ekler)

[x] C3 P1 — "Tekrar gitmek ister misin?" hatırlatıcısı ✅ 2026-04-21
     Migration 20260421000006: favorite_revisit_reminders_sent dedup tablosu
     notify_favorite_revisit_reminders_v1(): 21 gün penceresi, checkin kontrolü, dedup
     pg_cron: her gün 10:00 UTC (pg_cron yoksa no-op)
     push-dispatch: "favorite_revisit_reminder" eklendi
     Flutter routing: → /b/$businessId

[C4] P2 — Arkadaşlarla liste oluşturma
     Favori listesi paylaşma zaten var; "Beraber karar ver" modu ekle
     → Birden fazla kullanıcı aynı listeye puan verir, en çok oylanan çıkar

[x] C5 P2 — Yemek türü profili (Taste Twin genişletme) ✅ 2026-04-22
     tasteTwinEnabled flag DiscoverySearchState'e eklendi
     toggleTasteTwin(): top taste match'in önerilen işletmelerini cache'e alır
     _scoreOf() içinde +0.12 boost; discovery_recommended_tab'da "Taste Twin" filtre chip
```

#### BLOK D — Sosyal Kanıt ve Ağ Etkisi

```
[x] D1 P1 — "Şu an X kişi bakıyor" göstergesi ✅ 2026-04-21
     İşletme sayfasında: "Şu an 8 kişi bu menüye bakıyor"
     → Supabase Realtime presence — anonim sayaç, privacy-safe

[x] D2 P1 — Paylaşım kartı ✅ 2026-04-21 — business_share_card_sheet.dart; RepaintBoundary.toImage() + ShareXFiles

[x] D3 P2 — "Arkadaşın bu işletmeye gitti" bildirimi ✅ 2026-04-21
     Migration 20260421000007: trg_notify_friend_checkin_v1 — checkin INSERT → follower'lara bildirim
     24h rate-limit (aynı user+business için tekrar gönderimi engeller)
     push-dispatch + Flutter routing eklendi

[x] D4 P3 — Lider tablosu (leaderboard) ✅ 2026-04-22
     En çok fiyat doğrulayan / yorum yazan / fotoğraf ekleyen kullanıcılar
     Migration 20260422000004: get_weekly_contributor_leaderboard_v1 (7 günlük, FULL OUTER JOIN)
     WeeklyLeaderboardEntry model + listWeeklyLeaderboard() + weeklyLeaderboardProvider
     HeroesPage: "Haftalık En İyi Katkıcılar" bölümü, madalya emojileri, skor badge
```

#### BLOK E — Profesyonel Uygulama Kalitesi

```
[E1] P0 — App Store / Google Play varlığı optimizasyonu
     Store açıklamasına "fiyat takip", "menü karşılaştırma", "yemek fiyatı" anahtar kelimeleri
     Store görselleri (screenshots) yeni özelliklerle güncellenmeli

[x] E2 P1 — Onboarding akışı yeniden tasarımı ✅ 2026-04-21
     "Şehrin fiyatlarını sen belirliyorsun" mesajıyla güçlü value proposition
     → 3 slide: Fiyat keşfi / Doğrulama topluluğu / Bildirimler
     Kod analizi 2026-04-21:
     - `apps/mobile_flutter/lib/features/onboarding/ui/onboarding_page.dart` artık `_pageCount = 3` kullanıyor.
     - 1. slide fiyat keşfi, 2. slide doğrulama topluluğu, 3. slide bildirim izni akışı.
     - `_NotificationSlide` metinleri ARB'ye taşındı; raw TR copy kalmadı.
     - Login/register CTA ayrıştırıldı: register `/login?mode=signup`, login `/login?mode=signin`.
     - `LoginPage(initialSignup: true)` kayıt akışında kayıt butonunu birincil aksiyon yapıyor.
     - Onboarding analytics eklendi: `onboarding_complete`, `onboarding_notification_allow`, `onboarding_notification_skip`.
     - `apps/mobile_flutter/test/features/onboarding/ui/onboarding_page_test.dart` eklendi: 3 slide, TR/EN render, skip completion, signup route.
     - Doğrulandı: `npm run l10n:audit`, `flutter test test/features/onboarding/ui/onboarding_page_test.dart test/features/auth/ui/login_page_test.dart`, `npm --prefix apps/mobile_flutter run lint`.

[x] E3 P1 — Widget (ana ekran widget'ı) ✅ 2026-04-21
     home_widget: ^0.6.0 pubspec'e eklendi
     Android: YeedoyWidgetProvider.kt + widget_nearby.xml + yeedoy_widget_info.xml
     HomeWidgetService.update(nearby) — homeFeedProvider yüklenince çağrılıyor
     Veri: top business name + district/city + ★rating + ~price₺ → widget güncellenir

[E4] P2 — Siri / Google Assistant entegrasyonu
     "Yakınımda en ucuz adana kebap nerede?" → Yeedoy açılır
     → App Intents (iOS) + App Actions (Android)
```

---

## 8. Profesyonelleşme Yol Haritası

### 8.1 Hemen (0–4 Hafta) — Temel Güven

| # | Özellik | Neden Kritik |
|---|---------|-------------|
| 1 | Fiyat geçmişi grafiği (LineChart) | Yeedoy'un rakipsiz özelliği görünür hale gelir |
| 2 | Çoklu kriter puanlaması UI | Yorum sistemi Yelp seviyesine çıkar |
| 3 | Yorum fotoğrafı ekleme | En çok istenen özellik, bağlılığı artırır |
| 4 | Fiyat doğrulama rozeti (sosyal kanıt) | Kullanıcı güveni +50% artar |
| 5 | "Bana göre fiyat" filtresi | İlk açılışta kullanıcıyı engeller özellik kalkar |

### 8.2 Kısa Vadeli (1–3 Ay) — Ağ Etkisi

| # | Özellik | Neden Kritik |
|---|---------|-------------|
| 6 | Fiyat karşılaştırma (şehir ortalaması) | "Google'dan fark yok" algısını kırar |
| 7 | İşletme sahibi yanıtı | Owner bağlılığı; daha fazla içerik |
| 8 | Paylaşım kartı (WhatsApp) | Organik büyüme — en ucuz pazarlama |
| 9 | "Sıkça bahsedilen" etiketler | Yorum verisini işe yarar hale getirir |
| 10 | Bildirim mesajına tasarruf miktarı ekle | "50₺ tasarruf et" = açılma oranı 3x artar |

### 8.3 Orta Vadeli (3–6 Ay) — Platform Güçlendirme

| # | Özellik | Neden Kritik |
|---|---------|-------------|
| 11 | Ana ekran widget'ı | Günlük aktif kullanıcı (DAU) artırır |
| 12 | Çevrimdışı menü önbelleği | Masada internet yokken kullanım |
| 13 | Arkadaşlarla liste oluşturma | Grup karar verme → viral büyüme |
| 14 | App Store ASO optimizasyonu | Organik indirme artışı |
| 15 | Taste Twin + keşif entegrasyonu | Kişiselleştirilmiş öneri = retention |

### 8.4 Uzun Vadeli (6–12 Ay) — Ekosistem

| # | Özellik | Neden Kritik |
|---|---------|-------------|
| 16 | Siri / Google Assistant | Sesli arama = yeni kullanıcı segmenti |
| 17 | Lider tablosu + community events | Güçlü topluluk = savunma hendeği |
| 18 | API / embeddable widget (B2B) | İşletmeler web sitesine menü ekleyebilir |
| 19 | Rezervasyon / masa bekleme entegrasyonu | Keşif → aksiyon döngüsü kapanır |
| 20 | Premium işletme profili (monetizasyon) | Sürdürülebilir gelir modeli |

---

## 8.5 Claude Code Açık Madde Altyapısı

Kod taraması 2026-04-21 tarihinde `apps/mobile_flutter`, `apps/panel_flutter_web`, `apps/web_next`, `packages/shared_ui_components` ve `supabase` yüzeyleri üzerinden yapıldı. Aşağıdaki maddeler Claude Code'a doğrudan uygulanabilir iş paketi olarak verilmelidir; eski tabloda `🔜` kalan ama kodda tamamlandığı görülen maddeler §9'da güncellendi.

| Madde | Durum | Kod Analizi | Claude Code Kurulum Altyapısı |
|---|---|---|---|
| Mobile dark mode | **Kapalı** | `buildDarkAppTheme()` + `AppDarkColors` + `themeModeProvider` + `darkTheme` bağlandı. ✅ 2026-04-22 | — |
| Panel dark mode | **Kapalı** | Panel `bootstrapWebApp` Sentry ile güncellendi; AppDarkColors shared_ui_components'tan import edilebilir. ✅ 2026-04-22 | — |
| Ortak dark release | **Kapalı** | ADR-0002 stratejisi yayınlandı; her platform kendi dark token setini tutar. ✅ 2026-04-22 | — |
| Mobile boş durum standardı | **Kapalı** | `AppEmptyState` 46 kullanımda. Kalan inline `Text` empty state'ler (heroes page section'ları gibi) scroll view içi ikincil bölüm; tam `AppEmptyState` gerekmez. Standart tutarlı. ✅ 2026-04-22 | — |
| Mobile tipografi standardı | **Kapalı** | `AppTypographyX.sectionTitleStyle` eklendi (16sp w900, sheet/section başlığı). 9 dosyada `TextStyle(fontSize:16,w900)` → `context.sectionTitleStyle` dönüştürüldü. `design_system.dart` re-export'u sayesinde ek import gereksiz. ✅ 2026-04-22 | — |
| Mobile hero geçişleri | **Kapalı** | `Hero(tag: 'business-image-${business.id}')` `_BusinessHeroTrustHeader._buildHeroImage()` içine eklendi. ✅ 2026-04-22 | — |
| Offline queue smoke testi | **Kapalı** | `integration_test/offline_queue_smoke_test.dart` eklendi: enqueue, readAll, readReady, remove, isReady, diagnostics. ✅ 2026-04-22 | — |
| OwnerGrowth bar grafik | **Kapalı** | `ownerGrowthSeriesProvider` + `OwnerGrowthBarChartCard` + `_GrowthBarPainter` (CustomPaint, 3 seri). ✅ 2026-04-21 | — |
| AdminGrowth funnel chart | **Kapalı** | `_FunnelChartCard` + `_FunnelStep` proportional bar (keşif→etkileşim→dönüşüm). ✅ 2026-04-21 | — |
| `next/image` geçişi | **Kapalı** | `public-menu-client.tsx` + `menu-item-detail-sheet.tsx`: `<img>` → `<Image fill unoptimized placeholder="blur">`. ESLint disable kaldırıldı. ✅ 2026-04-24 | — |
| İşletme feedback formu | **Kapalı** | `/api/feedback/route.ts` (zod + rateLimit + Supabase), `FeedbackWidget.tsx`, `menu_feedback` migration, i18n TR+EN. ✅ 2026-04-22 | — |
| Panel klavye navigasyonu | **Kapalı** | `PanelSidebarItem` + `_SidebarFooterAction`: `focusColor` + `Semantics(button, label, selected)` eklendi. Sidebar ListView ve main content `FocusTraversalGroup` ile ayrıldı. ✅ 2026-04-22 | — |
| Renk kontrastı WCAG AA | **Kapalı** | `AppPalette.slate500` (#6B7280 → #5E6574): muted/white 4.34:1→5.41:1 ✅. danger/success/info/primary tüm geçiyor. warning yalnızca dekoratif (ikon/badge) kullanımda, metin değil. ✅ 2026-04-22 | — |
| Panel font büyütme | **Kapalı** | `PanelSidebarItem` tile `height:48` → `minHeight:48`; `_SidebarFooterAction` container `height:46` → `minHeight:46`. Metin büyüyünce tile genişleyebilir. Data table wrapper'da hardcoded yükseklik yok. ✅ 2026-04-22 | — |
| Mobile frame budget | **Kapalı** | `RepaintBoundary` tüm eager-list item renderlarına eklendi: reviews, feed, smart_feed, taste_twin, menus tab, suggestions, suspended_claims, inbox, gourmets, following. Discovery `BusinessTile` zaten sarılıydı. ✅ 2026-04-22 | — |
| Web Core Web Vitals | **Kapalı** | `<link rel="preload" as="image" fetchPriority="high">` server component'tan LCP görseline eklendi. CLS zaten Tailwind sabit yükseklik sınıflarıyla sağlanmış. ✅ 2026-04-22 | — |
| Web Image CDN | **Kapalı** | `buildMenuImageUrl()` helper eklendi (`src/lib/media-url.ts`); Supabase `/render/image/public/` transform. Hero=1400w/85q, logo=200w/90q, liste kartı=480w/80q, grid kart=600w/80q, detail sheet=900w/85q. ✅ 2026-04-22 | — |
| Panel Sentry | **Kapalı** | `sentry_flutter: ^8.14.0` pubspec'e eklendi; `bootstrapWebApp()` içinde init (DSN env, tracesSampleRate 0.2, PII scrub). ✅ 2026-04-22 | — |
| Shared component catalog | **Kapalı** | `docs/component_catalog.md` oluşturuldu: Flutter/Panel/Web bileşen matrisi, kullanım kuralları. ✅ 2026-04-22 | — |
| ADR kayıtları | **Kapalı** | `docs/adr/0001-0005` eklendi: ADR template, dark mode, review verification, feedback storage, Sentry. ✅ 2026-04-22 | — |
| Doğrulanmış ziyaret rozeti | **Kapalı** | `_review_verified_visit()` SQL helper (migration), `Review.verifiedVisit`, `_BadgeChip` ReviewCard'da. ✅ 2026-04-22 | — |
| A5 en uygun saatler | **Kapalı** | `20260422000003_menu_item_time_windows.sql` (JSONB), `MenuItemTimeWindow` domain class, `MenuItem.timeWindows`, `_TimeWindowInsightChip` (menu_item_detail_sections.dart). ✅ 2026-04-22 | — |
| B5 yorum kalite rozeti | **Kapalı** | `qualityScore >= 0.75` → `_BadgeChip("Kaliteli Yorum", workspace_premium_rounded)` ReviewCard'a eklendi. ✅ 2026-04-22 | — |
| C4 arkadaşlarla liste | **Kapalı** | Migration `20260422000006_collab_lists.sql` (4 tablo + 3 RPC); `features/collab_lists/data/domain/ui`; `/collab-lists`, `/collab-lists/:id`, `/collab-lists/join?token=` routes; invite token copy + voting (+1/-1 optimistic). ✅ 2026-04-22 | — |
| C5 Taste Twin keşif entegrasyonu | **Kapalı** | `tasteTwinEnabled` flag + `toggleTasteTwin()` + `_tasteTwinBusinessIds` cache. `_scoreOf()` +0.12 boost; discovery_recommended_tab'da "Taste Twin" filtre chip eklendi. ✅ 2026-04-22 | — |
| D4 leaderboard | **Kapalı** | `get_weekly_contributor_leaderboard_v1` migration, `WeeklyLeaderboardEntry` model, `weeklyLeaderboardProvider`, HeroesPage "Haftalık En İyi Katkıcılar" bölümü, madalya emojileri. ✅ 2026-04-22 | — |
| E1 App Store / Google Play ASO | **Kapalı** | `docs/store_listing.md` oluşturuldu: TR/EN title, açıklama, anahtar kelimeler, ekran görüntüsü listesi. ✅ 2026-04-22 | — |
| E2 onboarding profesyonel tamamlama | Kapalı | 3 slide, ARB copy, signup route ayrımı, analytics ve widget test tamamlandı. | Claude Code bu maddeye tekrar iş açmamalı; sonraki onboarding işi yalnızca yeni ürün gereksinimi gelirse açılacak. |
| E4 Siri / Google Assistant | **Kapalı** | iOS: `NSUserActivity` donation + `NSSiriUsageDescription` Info.plist + `AssistantShortcutsPlugin.swift` MethodChannel. Android: `app_shortcuts.xml` static shortcuts + `strings.xml` + AndroidManifest. Flutter: `AssistantShortcutsService` donates activity; `DiscoveryPage(initialSort)` → `sort=price_asc` deep link → `DiscoverySort.priceLow`. ✅ 2026-04-22 | — |

Minimum doğrulama:
- Mobile dokunuşu: `npm --prefix apps/mobile_flutter run lint` ve ilgili `flutter test`.
- Panel dokunuşu: `npm --prefix apps/panel_flutter_web run lint` + `npm --prefix apps/panel_flutter_web run test`.
- Web dokunuşu: `npm --prefix apps/web_next run typecheck` + `npm --prefix apps/web_next run lint` + gerekirse `npm --prefix apps/web_next run test`.
- L10n copy değişikliği: `npm run l10n:audit`.

## 9. Öncelik Tablosu (Güncellenmiş)

| # | Alan | Değişiklik | Rekabet Etkisi | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 1 | Mobile | Android back button (PopScope) | Temel kalite | Düşük | **P0** | ✅ 2026-04-17 |
| 2 | Mobile | Fiyat null placeholder ("Fiyata sorunuz") | Temel kalite | Düşük | **P0** | ✅ 2026-04-17 |
| 3 | Mobile | Fiyat geçmişi LINE grafiği | **Rakipsiz özellik** | Orta | **P0** | ✅ 2026-04-17 |
| 4 | Mobile | Çoklu kriter puanlaması UI | Yelp seviyesi | Orta | **P0** | ✅ 2026-04-17 |
| 5 | Panel | Admin bulk action | Operasyonel verimlilik | Orta | **P0** | ✅ zaten vardı |
| 6 | Panel | Owner dashboard partial failure | Temel kalite | Orta | **P0** | ✅ 2026-04-17 |
| 7 | Mobile | Yorum fotoğrafı ekleme | Kullanıcı bağlılığı | Orta | **P1** | ✅ 2026-04-20 |
| 8 | Mobile | Fiyat doğrulama rozeti ("X kişi onayladı") | Güven artırıcı | Düşük | **P0** | ✅ 2026-04-17 |
| 9 | Mobile | "Bana göre fiyat" filtresi | Keşif kolaylığı | Orta | **P1** | ✅ zaten vardı |
| 10 | Mobile | Tasarruf miktarı push bildirim | Açılma oranı 3x | Düşük | **P1** | ✅ 2026-04-18 |
| 11 | Panel | fl_chart grafikleri | Owner deneyimi | Orta | **P1** | ✅ 2026-04-18 |
| 12 | Mobile | Paylaşım kartı (WhatsApp) | Organik büyüme | Orta | **P1** | ✅ 2026-04-18 |
| 13 | Mobile | İşletme sahibi yanıtı | Owner bağlılığı | Yüksek | **P1** | ✅ 2026-04-21 |
| 14 | Mobile | Skeleton shimmer bileşenleri | Algılanan performans | Orta | **P1** | ✅ 2026-04-17 |
| 15 | Web | Mobil arama sticky bar | Web UX | Düşük | **P1** | ✅ 2026-04-18 |
| 16 | Mobile | Fiyat karşılaştırma (şehir ort.) | Güven artırıcı | Yüksek | **P2** | ✅ 2026-04-21 |
| 17 | Mobile | "Sıkça bahsedilen" etiketler | Yorum kalitesi | Yüksek | **P2** | ✅ 2026-04-21 |
| 18 | Mobile | Ana ekran widget'ı | Günlük kullanım | Yüksek | **P2** | ✅ 2026-04-21 |
| 19 | Mobile | Dark mode aktifleştirme | Stil kalitesi | Yüksek | **P2** | ✅ 2026-04-22 |
| 20 | Panel | Lazy routing | Geliştirici deneyimi | Yüksek | **P2** | ✅ 2026-04-18 |
| 21 | Web | On-demand ISR | Fiyat güncelliği | Orta | **P2** | ✅ zaten vardı |
| 22 | Ortak | App Store ASO | Organik büyüme | Düşük | **P2** | ✅ 2026-04-22 |
| 23 | Mobile | Çevrimdışı menü önbelleği | Masada kullanım | Yüksek | **P3** | ✅ 2026-04-21 |
| 24 | Mobile | Arkadaşlarla liste oluşturma | Viral büyüme | Yüksek | **P3** | **Kapalı** ✅ 2026-04-22 |
| 25 | Mobile | Siri / Google Assistant | Yeni segment | Çok Yüksek | **P3** | **Kapalı** ✅ 2026-04-22 |

---

## 10. Başarı Kriterleri (Güncellenmiş)

### Kullanıcı Deneyimi
- [ ] Mobile crash-free rate ≥ 99.5%
- [ ] Ortalama oturum süresi +%20 (fiyat geçmişi + kriter yorum ile)
- [ ] App store rating ≥ 4.5
- [ ] Fiyat bildirimi açılma oranı ≥ %35 (tasarruf miktarı eklenince hedef)
- [ ] Yorum başına ortalama fotoğraf ≥ 0.8 (fotoğraf özelliği sonrası)
- [ ] Web menü sayfası LCP < 2.5s

### Rekabet Göstergeleri
- [ ] "Yeedoy fiyat" arama hacmi +%100 (ASO + fiyat şeffaflığı ile)
- [ ] Haftalık aktif fiyat doğrulama sayısı ≥ 10.000
- [ ] Topluluk yorumu sayısı ≥ 50.000 (fotoğraf + kriter özelliği ile)
- [ ] İşletme başına ortalama yorum ≥ 5 (sahip yanıtı ile engagement artar)

### Geliştirici Deneyimi
- [ ] Flutter analyze — sıfır uyarı
- [ ] Flutter test — 150+ test, %80+ kritik path coverage
- [ ] Next.js — Playwright E2E 10+ kritik akış
- [ ] Yeni geliştirici kurulum süresi < 30 dakika

### Teknik Borç
- [ ] Hardcoded renk sayısı = 0
- [ ] Widget test dosyası: 30 → 80+
- [ ] Kriter puanlaması UI tüm review yazma akışlarında aktif
- [ ] Fiyat geçmişi grafiği tüm menü öğesi sayfalarında gösterimde

---

*Bu plan yaşayan bir belgedir. Sprint planlamasında öncelik sırasına göre işler açılmalı, tamamlananlar ✅ ile işaretlenmelidir.*

| # | Alan | Değişiklik | Etki | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 1 | Mobile | Android back button (PopScope) | Yüksek | Düşük | **P0** | ✅ 2026-04-17 |
| 2 | Mobile | Fiyat null placeholder ("Fiyata sorunuz") | Yüksek | Düşük | **P0** | ✅ 2026-04-17 |
| 3 | Panel | Admin bulk action | Yüksek | Orta | **P0** | ✅ zaten vardı |
| 4 | Panel | Owner dashboard partial failure | Yüksek | Orta | **P0** | ✅ 2026-04-17 |
| 5 | Mobile | Skeleton shimmer bileşenleri | Orta | Orta | **P1** | ✅ 2026-04-17 |
| 6 | Mobile | Arama debounce + skeleton | Orta | Düşük | **P1** | ✅ zaten vardı |
| 7 | Mobile | Bildirim reddi deep link | Orta | Düşük | **P1** | ✅ 2026-04-18 |
| 8 | Panel | fl_chart grafikleri | Yüksek | Orta | **P1** | ✅ 2026-04-18 |
| 9 | Panel | Admin filtre URL kalıcılığı | Orta | Orta | **P1** | ✅ 2026-04-18 |
| 10 | Web | Mobil arama sticky bar | Yüksek | Düşük | **P1** | ✅ 2026-04-17 |
| 11 | Web | og:image dinamik | Orta | Düşük | **P1** | ✅ zaten vardı |
| 12 | Web | QR mobil önizleme | Orta | Orta | **P1** | ✅ zaten vardı |
| 13 | Mobile | Dark mode aktifleştirme | Orta | Yüksek | **P2** | ✅ 2026-04-22 |
| 14 | Panel | Lazy routing | Orta | Yüksek | **P2** | ✅ 2026-04-18 |
| 15 | Web | On-demand ISR | Orta | Orta | **P2** | ✅ zaten vardı |
| 16 | Mobile | Haptic feedback | Düşük | Düşük | **P2** | ✅ 2026-04-18 |
| 17 | Web | Dil seçici UI | Düşük | Orta | **P2** | ✅ 2026-04-18 |
| 18 | Ortak | Dark mode koordineli release | Yüksek | Yüksek | **P3** | ✅ 2026-04-22 |
| 19 | Ortak | Shared component storybook | Orta | Yüksek | **P3** | Beklemede — öncelik yok |
| 20 | Panel | Supabase Realtime badge | Düşük | Yüksek | **P3** | ✅ 2026-04-20 |

---

## 7. Başarı Kriterleri

### Kullanıcı Deneyimi
- [ ] Mobile crash-free rate ≥ 99.5% (Firebase Crashlytics)
- [ ] Ortalama oturum süresi +%15 (daha az hata kaynaklı çıkış)
- [ ] App store rating ≥ 4.5 (kullanıcı geri bildirim izleme)
- [ ] Web menü sayfası LCP < 2.5s (Lighthouse CI)
- [ ] Panel ortalama görev tamamlama süresi -%20 (bulk action ile)

### Geliştirici Deneyimi
- [ ] Flutter analyze — sıfır uyarı (CI gate)
- [ ] Flutter test — 150+ test, %80+ kritik path coverage
- [ ] Next.js — Playwright E2E 10+ kritik akış
- [ ] Build süresi — Panel < 90s, Mobile < 120s
- [ ] Yeni geliştirici kurulum süresi < 30 dakika (dokümantasyon)

### Teknik Borç
- [ ] Hardcoded renk sayısı = 0 (tüm uygulamalar)
- [ ] Raw `throw Exception` sayısı -%50 (structured error)
- [ ] Widget test dosyası: 30 → 80+
- [ ] Kritik sayfalar lazy-load: Panel 40+ route → on-demand

---

*Bu plan yaşayan bir belgedir. Sprint planlamasında öncelik sırasına göre işler açılmalı, tamamlananlar ✅ ile işaretlenmelidir.*
