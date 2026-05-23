# Mobil Test Stratejisi

Bu belge `uygulamalar/mobil` test yuzeyinin tek kaynagidir.

Kapsam:

- integration smoke
- golden / snapshot testleri
- API contract testleri
- load test
- release gate iliskisi

## 1. Golden Path Integration

- Dosya: `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart`
- Mevcut kapsam:
  - cold start -> onboarding
  - `/sahip` panel devir
  - auth guard -> `/favoriler`
  - `/yasal` route smoke
  - discovery -> business -> menu -> menu item -> review route smoke
  - business report bottom sheet acilisi
  - review submit denemesinde login redirect (anon fail path)
  - runtime feature flags gate smoke:
    - `enablePhotoFeed=false` iken `/akis` -> `/kesif`
    - tum deneysel flagler kapali iken `/labs` -> `/kesif`
    - `enablePhotoFeed=true` iken `/labs` -> `LabsPage`
    - `enablePhotoFeed=true` iken `/akis` -> `SmartFeedPage`
    - `enableLabs=false` iken `/liderler` -> `/kesif`
    - `enableLabs=true` iken `/labs` -> `LabsPage`
    - `enableLabs=true` iken `/liderler` -> `HeroesPage`
  - deep-link / QR route smoke:
    - `/menu/:menuId?src=qr&businessId=:businessId` -> `PublicMenuSharePage`
  - dev-tools push payload simulator smoke:
    - `/dev-tools` uzerinden `Run price change sample` -> `MenuItemPage`
- Son durum:
  - `2026-03-06` tarihinde gercek Android cihazda (`SM G935F`) calistirildi
  - Komut: `flutter test integration_test/golden_paths_integration_test.dart -d ce11160bb9d5ca2e01`
- Not:
  - cekirdek navigasyon ayrimi sonrasi deneysel yuzeylerin tek giris noktasi `LabsPage` kabul edilir; bottom-nav home branch'i feed'e sapmaz

## 1.1 Canli Backend Write Smoke (Opt-in)

- Dosya: `uygulamalar/mobil/integration_test/live_write_smoke_integration_test.dart`
- Kapsam:
  - auth ile review write denemesi
  - auth ile menu price suggestion write denemesi
  - auth ile business report write denemesi
  - auth ile favorites add/remove + state restore denemesi
  - logout sonrasi unauth write fail path
- Varsayilan:
  - kapali (`RUN_LIVE_WRITE_SMOKE=false`)
- Calistirma:
  - `flutter test integration_test/live_write_smoke_integration_test.dart --dart-define=RUN_LIVE_WRITE_SMOKE=true --dart-define=LIVE_SUPABASE_URL=https://<project>.supabase.co --dart-define=LIVE_SUPABASE_ANON_KEY=<anon> --dart-define=LIVE_SMOKE_EMAIL=<email> --dart-define=LIVE_SMOKE_PASSWORD=<password> --dart-define=LIVE_SMOKE_BUSINESS_ID=<business_uuid> --dart-define=LIVE_SMOKE_MENU_ITEM_ID=<menu_item_uuid>`

## 1.2 Embed Smoke

- Integration:
  - Dosya: `uygulamalar/mobil/integration_test/yerlestir_smoke_integration_test.dart`
  - Kapsam: invalid URL fallback (`EmbedViewerPage`) crashsiz acilis
  - Son durum:
    - `2026-03-06` tarihinde gercek Android cihazda (`SM G935F`) calistirildi
    - Komut: `flutter test integration_test/yerlestir_smoke_integration_test.dart -d ce11160bb9d5ca2e01`
- Widget:
  - Dosya: `uygulamalar/mobil/test/features/yerlestir/ui/yerlestir_viewer_page_test.dart`
  - Kapsam:
    - invalid URL fallback UI
    - invalid YouTube source icin fallback mesaji

## 1.3 Manual Push Simulator

- Dosya: `uygulamalar/mobil/lib/features/devtools/ui/developer_tools_page.dart`
- Kapsam:
  - `favorite_price_changed` -> menu item detail
  - `review_reply` -> business reviews
  - `owner_business_reported` -> business detail
- Not:
  - Bu arac native FCM transport'unu degil, ayni payload parser + global route intent akisini dogrular.

## 1.4 Android Native Debug Push Bridge

- Android native bridge:
  - `uygulamalar/mobil/android/uygulama/src/main/kotlin/com/yeedoy/uygulama/MainActivity.kt`
  - `uygulamalar/mobil/lib/features/notifications/domain/android_debug_push_bridge.dart`
- Yardimci script:
  - `uygulamalar/mobil/tool/android_debug_push.ps1`
- Kapsam:
  - `adb shell am start` ile gelen explicit debug intent payload'i native tarafta alinip `EventChannel` uzerinden Flutter'a aktarilir
  - payload mevcut `resolvePushTapRoute` + `pushTapIntentProvider` zinciri ile ayni route akisini kullanir
- Calistirma:
  - terminal 1: `flutter run -d ce11160bb9d5ca2e01 -t lib/mobil_giris.dart`
  - terminal 2: `pwsh -File uygulamalar/mobil/tool/android_debug_push.ps1 -DeviceId ce11160bb9d5ca2e01 -Sample price-change`
- Son durum:
  - `2026-03-06` tarihinde gercek Android cihazda (`SM G935F`) dogrulandi
  - `flutter run` cikisinda `[AndroidDebugPushBridge]` payload log'u ve `[GlobalPushIntentListener] route=/isletme/.../menu-item/...` log'u goruldu
- Not:
  - Bu akıs native Android intent/tap seviyesini dogrular; gercek FCM transport teslimati ve iOS matrisini tek basina kapatmaz.

## 1.5 Offline Recovery ve Local DB

- Dosyalar:
  - `uygulamalar/mobil/test/core/storage/offline_mutation_queue_test.dart`
  - `uygulamalar/mobil/test/core/storage/offline_mutation_idempotency_test.dart`
  - `uygulamalar/mobil/test/core/storage/offline_queue_diagnostics_test.dart`
  - `uygulamalar/mobil/test/core/storage/yerel_db/bellek_yerel_db_deposu_test.dart`
  - `uygulamalar/mobil/test/core/storage/yerel_db/paylasilan_tercihler_yerel_db_deposu_test.dart`
  - `uygulamalar/mobil/test/core/storage/offline_submission_queue_test.dart`
  - `uygulamalar/mobil/test/core/storage/offline_sync_service_test.dart`
  - `uygulamalar/mobil/test/core/network/connectivity_restore_service_test.dart`
- Kapsam:
  - bucket bazli local snapshot store davranisi
  - legacy verify/submission queue migration'i
  - deterministic idempotency key uretimi
  - ayni logical payload icin duplicate queue item uretilmemesi
  - unified mutation queue retry metadata ve action-bazli backoff kaydi
  - secondary interaction write'larinda (`favorite`, `price vote`) desired-state idempotency kontrati
  - devtools queue diagnostics ozetlerinin, suggested action ipuclarinin ve item onceliklendirmesinin dogrulugu
  - expired snapshot prune
  - foreground/resume replay backoff ve queue flush davranisi
  - offline -> online gecisinde replay tetigi
  - connectivity state, replay ve mutation outcome telemetry event yolu
  - retry / resolve-conflict / drop kararinin queue replay'e etkisi
- Not:
  - SQLite store Android/iOS runtime'ta aktif, web veya init failure durumunda shared-prefs fallback devam eder.

## 2. Golden / Snapshot

- Dosya: `uygulamalar/mobil/test/ui/golden/basic_surfaces_golden_test.dart`
- Not:
  - golden testler varsayilan olarak kapali
  - sadece bilinclı olarak acilmalidir
- Calistirma:
  - `flutter test --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart`
- Guncelleme:
  - `flutter test --update-goldens --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart`

## 3. API Contract

- Dosya: `uygulamalar/mobil/test/core/contracts/kesify_api_contract_test.dart`
- Kapsam:
  - `home_feed_v1` payload parse kontrati
  - `search_businesses_v1` item kontrati
- Calistirma:
  - `flutter test test/core/contracts/kesify_api_contract_test.dart`

## 3.1 Notification Route Resolver

- Dosya: `uygulamalar/mobil/test/features/notifications/domain/notification_target_path_resolver_test.dart`
- Kapsam:
  - `type + data` -> hedef path cozumleme
  - guvensiz `target_path` degeri icin fallback davranisi
- Calistirma:
  - `flutter test test/features/notifications/domain/notification_target_path_resolver_test.dart`

## 4. Load Test

- Dosya: `uygulamalar/mobil/tool/load/k6_home_search_business.js`
- Arac: `k6`
- Calistirma:
  - `k6 run uygulamalar/mobil/tool/load/k6_home_search_business.js -e BASE_URL=https://<edge-base-url> -e AUTH_HEADER="Bearer <token>" -e BUSINESS_ID=<uuid>`
- Hedefler:
  - home p95 `< 1200ms`
  - search p95 `< 800ms`
  - business p95 `< 800ms`

## 5. Release Gate Iliskisi

- Release gate script'i: `uygulamalar/mobil/tool/release_gate_check.dart`
- Write guard script'i: `uygulamalar/mobil/tool/offline_write_guard_check.dart`
- Kapi metrikleri:
  - crash-free
  - jank rate
  - startup / home tti / search latency / embed open latency
  - security checklist
  - rollout sagligi / rollback karari
- write surface governance:
  - write RPC/direct-write registry disi yeni mutation merge edilmez
  - explicit idempotency gerektiren write'lar dosya seviyesinde `idempotency_key` sinyali tasimak zorundadir
- Detayli metrik sozlesmesi: `docs/mobil-release-kontrol-listesi.md`

## 6. Minimum Komut Seti

```bash
flutter analyze
flutter test
flutter test test/core/contracts/kesify_api_contract_test.dart
flutter test test/core/linking/yeedoy_route_resolver_test.dart
flutter test test/core/network/connectivity_restore_service_test.dart
flutter test test/core/storage/offline_mutation_idempotency_test.dart
flutter test test/core/storage/offline_mutation_queue_test.dart
flutter test test/core/storage/offline_sync_service_test.dart
flutter test integration_test/golden_paths_integration_test.dart
flutter test integration_test/yerlestir_smoke_integration_test.dart
dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json
dart run tool/offline_write_guard_check.dart
```

## 7. Kalan Bosluklar

- Native FCM transport'tan gelen push tap payload -> hedef route e2e smoke (ozellikle iOS matrisinde)
- Gercek release telemetry exportundan uretilmis metrics.json ile dry-run


