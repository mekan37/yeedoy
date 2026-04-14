# Mobil Lokal DB ve Offline Plani

Tarih: 2026-03-07  
Kapsam: `apps/mobile_flutter` local DB tabanli offline mode degerlendirmesi

## 1) Problem Ozeti

Mevcut durumda:

- read path cache: `RequestCache` + memory TTL + `SharedPreferences`
- write path queue: verify + submission queue
- tam bir local read-model / sync katmani yok

Bu nedenle:

- buyuk read payload'larda cache invalidation/discovery kisitli
- offline-first davranis tum feature'larda ayni degil
- mutation replay ve read snapshot tek storage modelinde birlesmiyor

Ara adim (2026-03-05):

- deneysel read akislarina (`smart_feed`, `taste_twin`, `gourmets`, `group_requests`, `suspended_meals`, `budget_combos`) request cache + invalidate/force-refresh yayildi
- bu adim local DB oncesi read tutarliligini artirir; fakat disk-backed offline source-of-truth ihtiyacini ortadan kaldirmaz

Ara adim (2026-03-06):

- gecis adapter'i olarak `SharedPrefsLocalDbStore` eklendi
- `discovery`, `business detail`, `business menus`, `menu sections` ve `menu items` read path'leri ortak local snapshot store'a write-through + fallback baglandi
- app root seviyesinde `OfflineSyncService` ile verify/submission queue replay + expired snapshot prune foreground/resume tetigine baglandi
- `DeveloperToolsPage` icine snapshot count + prune operasyonu eklendi
- bu adim tam typed DB migration'i degil; fakat low-connectivity davranisini merkezi hale getirir

Ara adim (2026-03-07):

- `SqfliteLocalDbStore` ile SQLite tabanli bucket tablolar devreye alindi
- Android/iOS runtime provider artik once SQLite store'u dener; web ve init failure durumunda `SharedPrefsLocalDbStore` fallback olarak kalir
- mevcut `SharedPreferences` snapshot'lari ilk acilista SQLite tablolarina migrate edilir
- `ConnectivityRestoreService` ile periyodik/resume probe sonucunda offline -> online gecisi tespit edilip replay zorlanir
- replay sonuclari ve connectivity state degisimi telemetry event'lerine baglandi
- verify/submission queue kayitlari ortak `offlineMutationQueue` bucket'ina tasindi
- retry metadata (`retry_count`, `last_error`, `next_retry_at`) unified queue kaydinda tutulur hale geldi
- replay tarafinda retry / resolve-conflict / drop ayrimi yapan temel hata siniflandirma kurali eklendi
- action-bazli idempotency key standardi eklendi; ayni logical payload yeniden queue'ya girince ayni kayit guncellenir
- `submit_review_v2`, `submit_report_v2` ve `submit_business_suggestion_v2` ile review/report/business suggestion write'larinda explicit server-side idempotency devreye alindi
- bu adimla read snapshot persistence ve replay tetikleme sertlesti; menu price suggestion/menu item suggestion sonrasi favorite, price vote, follow ve photo vote da explicit server-side idempotency'ye alindi, conflict policy devtools/runbook diline ve panel observability yuzeyine tasindi

## 2) Hedef Mimari

Tek local DB katmani uzerinde:

1. read model snapshot'lari
2. offline mutation queue
3. sync metadata (cursor, last_sync_at, retry state)

P2/P2.1 iskeleti bu sprintte eklendi:

- model: `apps/mobile_flutter/lib/core/storage/local_db/local_db_models.dart`
- abstraction: `apps/mobile_flutter/lib/core/storage/local_db/local_db_store.dart`
- memory adapter: `apps/mobile_flutter/lib/core/storage/local_db/memory_local_db_store.dart`
- disk-backed gecis adapter'i: `apps/mobile_flutter/lib/core/storage/local_db/shared_prefs_local_db_store.dart`
- sqlite adapter'i: `apps/mobile_flutter/lib/core/storage/local_db/sqflite_local_db_store.dart`
- provider baglantisi: `apps/mobile_flutter/lib/core/storage/local_db/local_db_provider.dart`
- connectivity replay servisi: `apps/mobile_flutter/lib/core/network/connectivity_restore_service.dart`
- test: `apps/mobile_flutter/test/core/storage/local_db/memory_local_db_store_test.dart`

## 3) Bucket Sozlesmesi

Ilk bucket seti:

- `discoveryFeed`
- `businessSnapshot`
- `menuSnapshot`
- `offlineMutationQueue`
- `telemetrySnapshot`

Bu bucket'lar migration sirasinda DB table namespace'ine birebir esitlenecek.

## 4) Storage Adapter Karari

Bugunku runtime adapter:

- Android/iOS: `SqfliteLocalDbStore`
  - bucket bazli SQLite tablolar
  - indexlenmis `expires_at_ms` ve `record_type` alanlari
  - ilk acilista shared-prefs snapshot migration'i
- Web/fallback: `SharedPrefsLocalDbStore`
  - init failure veya desteklenmeyen platform durumunda gecis katmani
  - sade JSON persistence

Sonraki olgunluk seviyesi:

- entity-level tablo ayrisma + gerekiyorsa `drift` migration ergonomisi
- per-action idempotency ve operator gorunurlugu ile queue davranisinin urunlestirilmesi

## 5) Migration Plani

### Faz 1 (P2/P3 gecis)

- tamamlandi: shared-prefs tabanli gecis adapter'i
- tamamlandi: `discoveryFeed`, `businessSnapshot`, `menuSnapshot` bucket'larina write-through + fallback
- tamamlandi: `SqfliteLocalDbStore` ile bucket tablolarinin SQLite tarafina alinmasi
- kalan:
  - entity-level query ihtiyaclari icin tablo ayrisma/indeks tuning
  - migration regression testlerinin genisletilmesi

### Faz 2

- tamamlandi: verify/submission queue kayitlarinin `offlineMutationQueue` bucket'ina tasinmasi
- queue state alanlari:
  - `status` (`pending|retrying`)
  - `retry_count`
  - `last_error`
  - `next_retry_at`
- tamamlandi: retry / resolve-conflict / drop kararinin replay sirasinda ayristirilmasi
- tamamlandi: action-bazli idempotency key standardi
- tamamlandi: report/review/business suggestion/menu price suggestion/menu item suggestion write'lari icin explicit server-side idempotency adoption'i
- tamamlandi: `favorite` ve `price vote` secondary interaction write'lari icin desired-state explicit server-side idempotency adoption'i
- tamamlandi: `follow` ve `photo vote` interaction write'lari icin desired-state explicit server-side idempotency adoption'i
- tamamlandi: `create_price_alert` write'i icin explicit server-side idempotency adoption'i
- tamamlandi: `group offer vote` ve `presence submit` write'lari icin explicit server-side idempotency adoption'i
- tamamlandi: devtools icinde operator-facing queue diagnostics gorunurlugu
- tamamlandi: future write regression'larini bloklamak icin `offline_write_guard_check.dart` registry kapisi

### Faz 3

- tamamlandi: app foreground/resume tetikli bounded replay service
- tamamlandi: connectivity restore sinyali
- tamamlandi: replay outcome telemetry iskeleti
- tamamlandi: action bazli retry/backoff politikasinin ayristirilmasi
- tamamlandi: failed/retrying queue item'lari icin operator aksiyon runbook'u
- tamamlandi: conflict policy'nin devtools ve runbook diline tasinmasi
- tamamlandi: replay outcome event'lerinin panel/ops dashboard yuzeyine tasinmasi
- tamamlandi: panel observability yuzeyine health summary / threshold mantiginin eklenmesi
- tamamlandi: panel runtime calibration yuzeyi ve escalation persistence kurallari
- operasyon notu:
  - gercek trafik geldikce paneldeki threshold degerleri yeniden kalibre edilir; bu deploy gerektirmeyen operator ayaridir

## 6) Basari Kriterleri

- discovery/business/menu icin offline read hit orani artisi
- replay success rate > %99 (recoverable hata disinda)
- duplicate mutation < %0.1
- user-visible offline hata mesajlarinda azalma

## 7) Riskler

- schema migration hatasi -> data loss
- queue replay race condition
- buyuk payload'larda disk bloat

## 8) Risk Azaltma

- migration testleri (forward/backward)
- bounded TTL + periodic prune
- write idempotency token zorunlulugu
- rollout feature flag ile asamali gecis
