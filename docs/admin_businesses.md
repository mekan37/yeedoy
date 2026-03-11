# Admin Businesses Operasyon Yuzeyi

Bu dokuman `/admin/businesses` ekraninin operasyon sozlesmesini ve mevcut tablo davranisini aciklar.

## Amac

`/admin/businesses`, admin panelde isletme kayitlarini aramak, incelemek, atamak ve toplu moderasyon aksiyonlari uygulamak icin ana operasyon ekranidir.

## UI Sozlesmesi

Ekran `AdminTable` standardini kullanir ve su yuzeyleri verir:

- arama
- durum filtresi
- sehir ve ilce filtresi
- tarih araligi
- siralanabilir kolonlar
- sayfalama
- toplu secim
- local saved views

Kanit:
- `apps/panel_flutter_web/lib/features/admin/ui/admin_businesses_page.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/widgets/admin_table.dart`

## Bulk Aksiyonlar

Ekranda su toplu aksiyonlar vardir:

- approve
- reject
- assign to me
- clear assignment
- status change

Bu akislar mevcut admin write zincirini korur; yeni ayri bir operasyon backend'i tanimlamaz.

## Satir Bazli Aksiyonlar

Her business satiri uzerinden su akislar acilabilir:

- duzenleme
- birlestirme
- `Dijital Menu & QR`
- `Public Menu Linki`

Bu nedenle ekran yalnizca listeleme degil, ayni zamanda admin operator launchpad'i gibi davranir.

## Durum Yonetimi

Liste yuzeyinde asagidaki standard uygulanir:

- loading: `OwnerPanelFeedback.loading`
- error: `PermissionDeniedView` veya hata karti
- empty: tablo bos durumu

Not:
- Bu ekran henuz `AdminVirtualTableCard` kullanmaz.
- Buyuk veri icin temel strateji `server-side page window + TTL cache` modelidir.

## Veri Katmani

Listeleme ve write akislarinin sahibi:

- `apps/panel_flutter_web/lib/features/admin/data/admin_businesses_repository.dart`
- `apps/panel_flutter_web/lib/features/admin/domain/admin_businesses_controller.dart`

Saved view state'i:

- `apps/panel_flutter_web/lib/core/storage/admin_table_saved_views_prefs.dart`

## Operasyon Notlari

- `/admin/businesses`, unified queue yerine business kaydina odakli derin operasyon ekranidir.
- Queue triage icin `docs/moderation_queue.md`, business kaydi operasyonu icin bu dokuman esas alinmalidir.
