# Yeedoy Performans Notlari

Bu dosya `docs/panel_perf.md`, `docs/panel_scale.md` ve `docs/web_next_perf.md` kaynaklarinin birlestirilmis halidir.

---

## Bolum 1: Panel Flutter Web — Performans Raporu

Bu bolum `panel_flutter_web` icin sprint bazli web release performans takibi icin kullanilir. Her sprint sonunda ayni olcum komutlariyla guncellenmelidir.

### Snapshot

- Tarih: `2026-03-04`
- Commit: `4da7acf`
- Uygulama: `apps/panel_flutter_web`

### Perf Budget

| Surface | Budget | Guncel | Durum |
| --- | ---: | ---: | --- |
| Owner `main.dart.js` | `< 4,200,000` bytes | `4,624,648` bytes | Butce asimi |
| Admin `main.dart.js` | `< 4,000,000` bytes | `4,234,652` bytes | Butce asimi |

### Build Komutlari

```powershell
flutter build web --release --target lib/main_web_owner.dart --dart-define=DEV_TOOLS_ENABLED=false
flutter build web --release --target lib/main_web_admin.dart --dart-define=DEV_TOOLS_ENABLED=false
```

### Owner Release Metrikleri

| Metrik | Deger |
| --- | ---: |
| `main.dart.js` | `4,624,648` bytes |
| Toplam `build/web` | `38,316,771` bytes |

#### Top 10 Chunk

| Siralama | Dosya | Boyut (bytes) |
| --- | --- | ---: |
| 1 | `main.dart.js_18.part.js` | `532,437` |
| 2 | `main.dart.js_20.part.js` | `532,259` |
| 3 | `main.dart.js_19.part.js` | `532,259` |
| 4 | `main.dart.js_31.part.js` | `125,250` |
| 5 | `main.dart.js_27.part.js` | `125,230` |
| 6 | `main.dart.js_23.part.js` | `125,071` |
| 7 | `main.dart.js_55.part.js` | `92,263` |
| 8 | `main.dart.js_69.part.js` | `70,939` |
| 9 | `main.dart.js_58.part.js` | `70,928` |
| 10 | `main.dart.js_64.part.js` | `61,966` |

### Admin Release Metrikleri

| Metrik | Deger |
| --- | ---: |
| `main.dart.js` | `4,234,652` bytes |
| Toplam `build/web` | `38,116,879` bytes |

#### Top 10 Chunk

| Siralama | Dosya | Boyut (bytes) |
| --- | --- | ---: |
| 1 | `main.dart.js_18.part.js` | `532,437` |
| 2 | `main.dart.js_20.part.js` | `532,259` |
| 3 | `main.dart.js_19.part.js` | `532,259` |
| 4 | `main.dart.js_31.part.js` | `125,250` |
| 5 | `main.dart.js_27.part.js` | `125,230` |
| 6 | `main.dart.js_23.part.js` | `125,071` |
| 7 | `main.dart.js_55.part.js` | `92,263` |
| 8 | `main.dart.js_69.part.js` | `70,939` |
| 9 | `main.dart.js_58.part.js` | `70,928` |
| 10 | `main.dart.js_64.part.js` | `61,966` |

### Notlar

- Owner build butce asimi: `+424,648` bytes.
- Admin build butce asimi: `+234,652` bytes.
- Owner ile admin arasindaki `main.dart.js` farki: `389,996` bytes.
- Build sirasinda bloklamayan bir font uyarisi var: `CupertinoIcons` family referansi asset olarak bulunmuyor.
- Owner build wasm dry-run uyarisi `image` paketinden geliyor; admin build wasm dry-run basarili.
- Gercek `AdminVirtualTableCard` sanallastirmasi bugun yalnizca `/admin/business-submissions` ekraninda aktiftir.

### Bu Sprintteki Delta

| Surface | Onceki `main.dart.js` | Guncel `main.dart.js` | Delta |
| --- | ---: | ---: | ---: |
| Owner | `4,681,752` | `4,624,648` | `-57,104` |
| Admin | `4,159,017` | `4,234,652` | `+75,635` |

Yorum:
- Owner tarafinda ek route-level deferred import (`/owner/analytics`) ilk yuk JS'ini anlamsiz bicimde dusturdu.
- Admin tarafinda `AdminVirtualTable`, yeni pagination akisi ve ek chunk sinirlari toplam bundle dagiliminizi degistirdi; ilk yuk JS'i butce altina inmedi.
- Toplam `build/web` boyutu, daha fazla deferred parca ve yeni liste altyapisi nedeniyle artti; bu metrik tek basina ilk yuk maliyetini temsil etmez.

### Onceliklendirilen Sonraki 3 Adim

1. `AdminVirtualTableCard` standardini `queue`, `reports`, `claims` ve `businesses` ekranlarina yay.
2. En buyuk shared chunk bloklari icin feature attribution cikar; `pdf`, `qr_flutter`, `webview_flutter`, `youtube_player_iframe`, `share_plus` ve admin moderation kodu hangi boundary icinde kaldigini netlestir.
3. `CupertinoIcons` referansini ya gercekten ekle ya da kaldir; ardindan font ve icon dependency yuzeyini tekrar ol.

### Guncelleme Kurali

- Bu bolum her sprint sonunda yeni tarih, commit ve olcumlerle guncellenmelidir.
- Butce asimi varsa ilgili PR veya sprint raporunda sebep ve plan notu birakilmalidir.

---

## Bolum 2: Panel Flutter Web — Olcekleme Kararlari

Bu bolum `panel_flutter_web` tarafinda `10k+` isletme ve yuksek moderasyon hacmi icin uygulanan temel olcekleme kararlarini ozetler.

### Hedef

- Buyuk owner/admin listelerinde ilk render maliyetini sinirlamak
- Her sayfada ayni anda render edilen satir/widget sayisini dusuk tutmak
- Tekrarlanan sorgularda gereksiz RPC cagrisini azaltmak
- Agir route'lari ilk yukten ayirmak

### 1. Owner Listelerinde Sliver Tabanli Render

`/owner/businesses` ve `/owner/menus` ekranlarinda uzun kart listeleri `SliverList` ile cizilir.

Avantajlar:
- Sadece gorunen kartlar build edilir
- Scroll sirasinda widget maliyeti sabit kalir
- Franchise senaryosunda cok subeli gorunum daha stabil calisir

### 2. Admin Listelerinde Sanal Govde + Sayfa Penceresi

`AdminTable` altyapisina eklenen `AdminVirtualTableCard`, baslik disindaki satir govdesini `ListView.builder` ile cizer.

- Sabit satir yuksekligi ile sadece gorunen satirlar build edilir
- `cacheExtent` kontrollüdur
- Yatay kaydirma korunur
- Dataset tamami widget agacina tasinmaz

Aktif ekranlar: `/admin/businesses`, `/admin/business-submissions`, `/admin/reports`, `/admin/claims`.
`/admin/queue` halen klasik `AdminTableCard` veya sayfa penceresi modeliyle calisir.

### 3. Memory + TTL Query Cache

Bellek ici TTL cache olan repository yuzeyleri:
- admin businesses
- admin business submissions
- admin reports
- owner businesses
- owner menus

Kurallar:
- Liste sorgulari kisa TTL ile cache'e alinir
- Write aksiyonlari ilgili prefix'i invalidate eder
- Filtre / offset / limit parametreleri cache anahtarina girer

Ornek cache anahtari yapisi:
- `admin_business_submissions:{status}:{limit}:{offset}:{query}:{dateFrom}:{dateTo}:{sortKey}:{sortAscending}`
- `admin_businesses:{query}:{city}:{district}:{cursor}:{limit}`
- `owner_menus:{businessId}:{status}:{query}`

Invalidation kurali — Write akislarinda ilgili prefix temizlenir:
- business submission approve/reject -> `admin_business_submissions:`
- business verify veya assignment degisimi -> `admin_businesses:`
- owner menu create/update/publish/delete -> `owner_menus:`
- owner business degisiklikleri -> `owner_businesses:`

### 4. Server-Side Pagination Standardi

`/admin/business-submissions` istemci tarafinda yuzlerce satir cekip filtrelemez. Bunun yerine arama, durum, tarih araligi, siralama, sayfa numarasi ve sayfa basi satir sayisi parametreleri dogrudan RPC katmanina gider ve `total_count` ile birlikte sayfa veri kumesi doner.

### 5. Route-Level Deferred Import Genisletmesi

Lazy load edilen route'lar:
- `/owner/businesses`, `/owner/menus`, `/owner/onboarding`, `/owner/analytics`
- `/admin/queue`, `/admin/reports`, `/admin/businesses`, `/admin/business-submissions`, `/admin/claims`

### 6. Aktif Lazy Split Envanteri

Route seviyesi disinda agir alt akislar da gec yuklenir:
- `OwnerMenuEditorPage` editor acilisi deferred gelir
- Menu editor icinde `pdf`, `qr`, `share` ve `embed preview` akislarinin her biri ayri lazy boundary kullanir
- `EmbedViewerPage` provider secimi deterministiktir:
  - Varsayilan hafif yol: iframe/html embed
  - YouTube URL'leri: deferred `youtube_player_iframe`
  - Gerekli fallback durumlari: deferred `webview_flutter`

Kanit dosyalari:
- `apps/panel_flutter_web/lib/shared/ui/components/deferred_page_loader.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_pdf_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_qr_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_share_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_embed_flow.dart`
- `apps/panel_flutter_web/lib/features/embed/ui/embed_viewer_page.dart`

### 10k Mock Senaryosu

Hedeflenen bounded-window varsayimi:
- Owner listeleri: gorunen kart + kucuk cache extent
- Admin tablolari: aktif sayfa satirlari
- Data erisimi: server-side limit/offset + TTL cache

Bu modelde performans kirilmasi, toplam kayit sayisindan cok aktif sayfa boyutu, ayni anda cizilen widget sayisi ve filtre sonrasi tekrarlanan ag cagrisi uzerinden kontrol edilir.

### Sonraki Adimlar (Olcekleme)

1. `AdminVirtualTableCard` standardini `queue` ekranina yay.
2. `queue` ve `claims` icin `total_count` donen tam server pagination RPC'lerini cikar.
3. Browser tarafinda profile build ile gercek scroll FPS ve input latency olcumu alinmalidir.

---

## Bolum 3: Web Next — Performans Raporu

Bu bolum yalnizca `apps/web_next` performans notlarini tutar.

Not: Tarihsel snapshot'lardaki ornek istek URL'leri UUID tabanli olabilir; bugunku canonical public route semantigi `/m/:publicSlugOrId` olup slug varsa final hedef slug path'idir.

- Tarih: `2026-03-03T06:33:42.631Z`
- Commit: `4da7acf`

### Build Ciktisi

- `/m/[slug]` first load JS: `109 kB`
- `/qr/[businessId]` first load JS: `110 kB`

### Public Menu Lighthouse

| Senaryo | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---:|---:|---:|---:|---|---|---|---|---|
| /m/:publicSlugOrId?theme=minimal | 91 | 100 | 96 | 90 | 1.2 s | 2.4 s | 180 ms | 0.005 | 5.2 s |
| /m/:publicSlugOrId?theme=photo-heavy | 94 | 100 | 96 | 90 | 1.2 s | 2.5 s | 220 ms | 0.006 | 1.4 s |
| /m/:publicSlugOrId?theme=dark-modern | 95 | 100 | 96 | 90 | 1.2 s | 2.5 s | 170 ms | 0.006 | 1.4 s |

### Login Gate Lighthouse

| Senaryo | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS |
|---|---:|---:|---:|---:|---|---|---|---|
| /login?redirect=/qr/:businessId | 97 | 100 | 96 | 100 | 1.2 s | 2.4 s | 70 ms | 0 |

### Authenticated QR Studio Lighthouse

| Senaryo | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS |
|---|---:|---:|---:|---:|---|---|---|---|
| /qr/:businessId?theme=bold | 97 | 98 | 100 | 100 | 0.7 s | 0.9 s | 190 ms | 0 |

### Bundle Audit Adresleri

- `apps/web_next/reports/bundle/latest/client.html`
- `apps/web_next/reports/bundle/latest/nodejs.html`
- `apps/web_next/reports/bundle/latest/edge.html`

### Kok Neden ve Uygulanan Duzeltmeler

Minimal tema regresyonunun temel nedeni LCP image discovery degil, client baslangic bundle'i ve render gecikmesiydi.

Ana bulgular (ortak chunk'a sizan zincir):
- `presentation-view.ts`
- `presentation-accent.ts`
- `templates/registry.ts`
- `templates/schema.ts`

Ek maliyet yuzeyleri:
- `public-menu-client.tsx`
- `qr-generator.tsx`
- Client bundle'a sizan i18n string tablolari

Yapilan ana duzeltmeler:
1. Client'a tasinan string tablolar server prop'a cekildi.
2. Theme definition ve blur placeholder verileri server tarafinda resolve edildi.
3. Template fallback lookup, agir registry zinciri yerine daha hafif statik map ile kuruldu.
4. QR branding ve menu detail alt akislarinda lazy split korundu.

Sonuc:
- `/m/[slug]` first load JS: `138 kB` -> `109 kB`
- `/qr/[businessId]` first load JS: `138 kB` -> `110 kB`
- `minimal` Lighthouse: `88` -> `91+`
- `Authenticated QR Studio` Lighthouse: `97`

### Lighthouse Rapor Dosyalari

- `apps/web_next/reports/lighthouse/latest/menu-minimal.report.html`
- `apps/web_next/reports/lighthouse/latest/menu-photo-heavy.report.html`
- `apps/web_next/reports/lighthouse/latest/menu-dark-modern.report.html`
- `apps/web_next/reports/lighthouse/latest/login.report.html`
- `apps/web_next/reports/lighthouse/latest/qr-auth.report.html`
