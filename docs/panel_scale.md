# Panel Ölçekleme Notları

Bu doküman `panel_flutter_web` tarafında `10k+` işletme ve yüksek moderasyon hacmi için uygulanan temel ölçekleme kararlarını özetler.

## Hedef

- Büyük owner/admin listelerinde ilk render maliyetini sınırlamak
- Her sayfada aynı anda render edilen satır/widget sayısını düşük tutmak
- Tekrarlanan sorgularda gereksiz RPC çağrısını azaltmak
- Ağır route'ları ilk yükten ayırmak

## Uygulanan Strateji

### 1. Owner listelerinde sliver tabanlı render

`/owner/businesses` ve `/owner/menus` ekranlarında uzun kart listeleri artık `SliverList` ile çizilir.

Bu sayede:

- sadece görünür kartlar build edilir
- scroll sırasında widget maliyeti sabit kalır
- franchise senaryosunda çok şubeli görünüm daha stabil çalışır

### 2. Admin listelerinde sanal gövde + sayfa penceresi

`AdminTable` altyapısına eklenen `AdminVirtualTableCard`, başlık dışındaki satır gövdesini `ListView.builder` ile çizer.

- sabit satır yüksekliği ile sadece görünür satırlar build edilir
- `cacheExtent` kontrollüdür
- yatay kaydırma korunur
- dataset tamamı widget ağacına taşınmaz

Bu model bugun yalnizca `/admin/business-submissions` ekraninda gercek sanal govde olarak aktiftir. `/admin/businesses`, `/admin/reports`, `/admin/queue` ve `/admin/claims` halen klasik `AdminTableCard` veya sayfa penceresi modeliyle calisir; tum admin liste yuzeylerinin sanallastirildigi varsayilmamalidir.

### 3. Memory + TTL query cache

Şu repository yüzeylerinde bellek içi TTL cache vardır:

- admin businesses
- admin business submissions
- admin reports
- owner businesses
- owner menus

Kural:

- liste sorguları kısa TTL ile cache'e alınır
- write aksiyonları ilgili prefix'i invalidate eder
- filtre / offset / limit parametreleri cache anahtarına girer

Bu sayede:

- geri/ileri gezintide tekrar RPC maliyeti düşer
- saved view uygulanınca aynı sorgu kısa sürede tekrar kullanılır
- moderasyon ekranlarında debounce sonrası gereksiz ağ çağrısı azalır

#### Ornek cache anahtari mantigi

Tipik anahtar yapisi:

- `admin_business_submissions:{status}:{limit}:{offset}:{query}:{dateFrom}:{dateTo}:{sortKey}:{sortAscending}`
- `admin_businesses:{query}:{city}:{district}:{cursor}:{limit}`
- `owner_menus:{businessId}:{status}:{query}`

Bu modelde filtre ve sayfa penceresi degisirse yeni anahtar uretilir; ayni sorgu TTL icinde tekrarlandiginda bellekten doner.

#### Invalidation kurali

Write akislarinda ilgili prefix temizlenir:

- business submission approve/reject -> `admin_business_submissions:`
- business verify veya assignment degisimi -> `admin_businesses:`
- owner menu create/update/publish/delete -> `owner_menus:`
- owner business degisiklikleri -> `owner_businesses:`

Bu sayede global cache wipe yerine sadece ilgili liste ailesi temizlenir.

### 4. Server-side pagination standardı

`/admin/business-submissions` artık istemci tarafında yüzlerce satır çekip filtrelemez. Bunun yerine:

- arama
- durum
- tarih aralığı
- sıralama
- sayfa numarası
- sayfa başına satır sayısı

parametreleri doğrudan RPC katmanına gider ve `total_count` ile birlikte sayfa veri kümesi döner.

Bu yaklaşım `10k+` kayıt senaryosunda hem ağ trafiğini hem de build/render maliyetini kontrol altında tutar.

### 5. Route-level deferred import genişletmesi

Ek olarak şu route'lar lazy load edilir:

- `/owner/businesses`
- `/owner/menus`
- `/owner/onboarding`
- `/owner/analytics`
- `/admin/queue`
- `/admin/reports`
- `/admin/businesses`
- `/admin/business-submissions`
- `/admin/claims`

Bu sayede admin/owner ana shell ilk açılışta daha az sayfa kodu indirir.

### 6. Aktif lazy split envanteri

Route seviyesi disinda, agir alt akislar da gec yuklenir:

- `OwnerMenuEditorPage` editor acilisi deferred gelir
- menu editor icinde `pdf`, `qr`, `share` ve `embed preview` akislarinin her biri ayri lazy boundary kullanir
- `EmbedViewerPage` provider secimi deterministiktir:
  - varsayilan hafif yol: iframe/html embed
  - YouTube URL'leri: deferred `youtube_player_iframe`
  - gerekli fallback durumlari: deferred `webview_flutter`

Kanit:
- `apps/panel_flutter_web/lib/shared/ui/components/deferred_page_loader.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_pdf_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_qr_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_share_flow.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/menu_editor_embed_flow.dart`
- `apps/panel_flutter_web/lib/features/embed/ui/embed_viewer_page.dart`

## 10k Mock Senaryosu

CLI ortamında gerçek browser FPS ölçümü alınmadı. Bunun yerine kod seviyesinde şu bounded-window varsayımı hedeflendi:

- owner listeleri: görünür kart + küçük cache extent
- admin tabloları: aktif sayfa satırları
- data erişimi: server-side limit/offset + TTL cache

Bu modelde performans kırılması, toplam kayıt sayısından çok:

- aktif sayfa boyutu
- aynı anda çizilen widget sayısı
- filtre sonrası tekrarlanan ağ çağrısı

üzerinden kontrol edilir.

## Operasyonel Sonuç

- Büyük dataset büyüdükçe ilk scroll maliyeti lineer artmamalı
- Tekrar açılan admin sorguları TTL içinde cache'den dönmeli
- Route açılışında ağır admin modülleri başlangıç bundle'ına yük bindirmemeli

## Sonraki Adımlar

1. `AdminVirtualTableCard` standardını `queue`, `claims`, `reports` ve `businesses` ekranlarına yay.
2. `queue` ve `claims` için `total_count` dönen tam server pagination RPC'lerini çıkar.
3. Browser tarafında profile build ile gerçek scroll FPS ve input latency ölçümü alınmalıdır.
