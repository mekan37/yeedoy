# Admin Isletme Basvurulari

Bu dokuman `/admin/business-submissions` ekraninin veri ve UI sozlesmesini aciklar.

## Amac

Bu ekran yeni isletme basvurularini incelemek ve hizli onay/red akisi vermek icin kullanilir.

## UI Sozlesmesi

Ekran bugun admin listeleri icinde en ileri olcekleme uygulanan yuzeydir.

Mevcut ozellikler:

- arama
- durum filtresi
- tarih araligi
- siralanabilir kolonlar
- server-side pagination
- toplu secim
- toplu approve/reject
- local saved views
- `AdminVirtualTableCard`

Kanit:
- `apps/panel_flutter_web/lib/features/admin/ui/admin_business_submissions_page.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/widgets/admin_table.dart`

## Veri Sozlesmesi

Listeleme dogrudan su RPC ile yapilir:

- `admin_list_business_submissions_v2`

Parametreler:

- `p_status`
- `p_limit`
- `p_offset`
- `p_q`
- `p_date_from`
- `p_date_to`
- `p_sort_key`
- `p_sort_ascending`

Repository:

- `apps/panel_flutter_web/lib/features/admin/data/admin_business_submissions_repository.dart`

Liste sonucu `total_count` ile birlikte doner; istemci tam dataset cekip filtrelemez.

## Onay ve Red Aksiyonu

Write akislar su RPC zincirleriyle korunur:

- `admin_approve_business_submission_v1`
- `admin_reject_business_submission_v1`

Bu write'lar admin API write wrapper'i uzerinden audit ve gerekce zincirini korur.

## Performans Notu

Bu ekran bugun panelde gercek sanal satir govdesi kullanan referans implementasyondur.

Yani:

- yalnizca gorunur satirlar build edilir
- page window ve TTL cache birlikte calisir
- bu yuzey diger admin listeleri icin ornek kabul edilir

Ilgili olcekleme kaydi:

- `docs/panel_scale.md`
- `docs/panel_perf.md`
