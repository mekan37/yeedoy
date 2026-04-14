# Mobil Release Kontrol Listesi

Bu belge `apps/mobile_flutter` release oncesi kontrol listesi icin tek kaynaktir.

## 1. Env ve Config

- `.env` icinde `SUPABASE_URL` dolu mu?
- `.env` icinde `SUPABASE_ANON_KEY` dolu mu?
- Firebase config dosyalari ortama uygun mu?
- `DEV_TOOLS_ENABLED` benzeri debug-only davranislar prod disi mi?
- Android package id ve iOS bundle id dogru mu?

Kanit girisleri:

- `apps/mobile_flutter/lib/main.dart`
- `apps/mobile_flutter/README.md`
- `docs/mobile_ci_ios_readiness.md`

## 2. Signing ve Build

### Android

- Release signing debug key kullanmiyor mu?
- Signing secret kaynagi net mi?
  - `android/key.properties` (lokal fallback) veya
  - env secret'lari (`ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`)
- `apps/mobile_flutter/android/key.properties.example` baz alinarak doldurma kurali dokumante mi?
- Gercek keystore/secret akisi tanimli mi?
- `flutter build apk --release -t lib/main_mobile.dart` temiz calisiyor mu?

Kritik not:

- `apps/mobile_flutter/android/app/build.gradle.kts` artik debug signing'e dusmez.
- Signing secret'lari hem `android/key.properties` hem env uzerinden okunur; env degerleri varsa onceliklidir.
- Secret yoksa release build bilincli olarak fail etmelidir.
- 2026-03-05 dogrulamasi: `flutter build apk --release -t lib/main_mobile.dart` komutu secret eksiginde beklenen sekilde fail etti ve zorunlu env adlarini acikca yazdi.

### iOS

- Bundle id dogru mu?
- Signing/capabilities tanimli mi?
- TestFlight veya benzeri dagitim yolu net mi?
- `dart tool/ios_readiness_check.dart` sonucu en azindan beklenen `WARN/PASS` seviyesinde mi?

Kritik not:

- Repo-root `mobile_readiness` workflow'u ayni audit'i macOS runner uzerinde calistirir.
- Repo icinde `ios/Podfile`, `Runner.entitlements`, `ExportOptions.plist` template'i ve `remote-notification` background mode artik bulunur.
- Bugunku kalan iOS boslugu repo iskeleti degil; signed release asset'lari, `GoogleService-Info.plist` yonetimi ve gercek cihaz smoke kanitidir.
- `mobile_readiness` icindeki IPA artifact'i build kanitidir; TestFlight dagitimi yerine gecmez.
- iOS release hazirligi icin tek referans belge `docs/mobile_ci_ios_readiness.md` dosyasidir.

## 2.1 CI ve Readiness Workflow

- `mobile_quality` workflow'u:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test test`
  - `dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json`
- `mobile_readiness` workflow'u:
  - `dart tool/ios_readiness_check.dart`
  - `dart run tool/release_gate_check.dart <metrics_path>`
  - `dart tool/ios_signing_check.dart --ci` (`placeholder`, Team ID formatı, base64 decode kontrolu dahil)
  - `dart tool/ios_signing_assets_check.dart`
  - provisioning profile plist decode + export options contract audit
  - export method'e gore `aps-environment` normalization
  - opsiyonel signed iOS IPA dry-run + IPA artifact upload
  - opsiyonel Android release dry-run + APK artifact upload
- GitHub tarafinda gerekli Android secret'lari:
  - `ANDROID_RELEASE_KEYSTORE_BASE64`
  - `ANDROID_RELEASE_STORE_PASSWORD`
  - `ANDROID_RELEASE_KEY_ALIAS`
  - `ANDROID_RELEASE_KEY_PASSWORD`
- GitHub tarafinda gerekli iOS secret'lari:
  - `IOS_APPLE_TEAM_ID`
  - `IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64`
  - `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
  - `IOS_PROVISIONING_PROFILE_BASE64`
  - opsiyonel `IOS_GOOGLE_SERVICE_INFO_BASE64`

## 3. Smoke

Minimum smoke akislari:

1. App launch -> splash -> discovery
2. Login
3. Discovery search
4. Business detail acilisi
5. Menu ve item detail acilisi
6. Review submit veya draft handling
7. Report submit
8. Favorites add/remove
9. Inbox acilisi
10. QR / deep link resolve
11. Push tap route resolve

Not:

- `integration_test/golden_paths_integration_test.dart` artik route zinciri + review submit-login redirect + report sheet smoke kapsar.
- Gercek backend write smoke icin `integration_test/live_write_smoke_integration_test.dart` kullanilir (opt-in, cihaz/emulator).
- Canli write smoke, review/report/menu price suggestion write ve unauth fail-path kontrolu yapar.
- Native FCM olmayan manuel payload kontrolu icin `'/dev-tools'` altindaki `Push Payload Simulator` kullanilabilir.
- Android native intent seviyesinde manuel payload kontrolu icin `apps/mobile_flutter/tool/android_debug_push.ps1` kullanilabilir.
- Ornek:
  - `flutter run -d ce11160bb9d5ca2e01 -t lib/main_mobile.dart`
  - `pwsh -File apps/mobile_flutter/tool/android_debug_push.ps1 -DeviceId ce11160bb9d5ca2e01 -Sample price-change`

## 4. Telemetry ve Crash

- Crashlytics aktif mi?
- Firebase Performance trace'leri buildte calisiyor mu?
- `log_event_v1` kritik eventleri gonderiyor mu?
- Push token register/unregister yolu calisiyor mu?
- Push tap event'leri (`notification_open`, `price_change_push_open`, `comment_reply_push_open`) goruluyor mu?
- Offline replay event'leri (`offline_sync_run`, `offline_mutation_outcome`, `connectivity_restored`, `connectivity_state_change`) goruluyor mu?
- Panel `/admin/observability` icindeki offline alert calibration degerleri beklenen threshold profilini yansitiyor mu?

Kanit:

- `apps/mobile_flutter/lib/main.dart`
- `apps/mobile_flutter/lib/core/analytics/analytics_repository.dart`
- `apps/mobile_flutter/lib/features/notifications/domain/push_notification_service.dart`

## 5. Backend Kontrat Kontrolu

- Kritik RPC'ler canli schema ile uyumlu mu?
- `docs/mobile_supabase_contracts.md` guncel mi?
- Yeni feature varsa ilgili tablo/RPC buraya eklendi mi?

## 6. Offline ve Cache

- Discovery stale cache fallback calisiyor mu?
- Business detail offline fallback calisiyor mu?
- Menu offline fallback calisiyor mu?
- Offline verify queue bozulmadi mi?
- Submission queue replay session restore ve connectivity restore sonrasi calisiyor mu?
- Verify ve submission kayitlari unified mutation queue icinde tutuluyor mu?
- Retry metadata (`retry_count`, `last_error`, `next_retry_at`) mantikli ilerliyor mu?
- Retry pencereleri hata kategorisine gore mantikli mi? (`network`, `auth`, `rate limit`, `server`)
- Ayni logical payload tekrarlandiginda duplicate queue item uretilmiyor mu?
- SQLite snapshot migration/fallback ilk acilista veri kaybetmeden tamamlandi mi?
- Devtools snapshot count/prune sayilari mantikli gorunuyor mu?
- Devtools offline queue diagnostics ekraninda `Retrying`, `Blocked until retry`, `Next retry`, `Top retry reasons`, `Conflict policy`, `Attention items` ve `Suggested action` alanlari beklenen tabloyu veriyor mu?
- Panel `/admin/observability` ekranindaki `Offline mutation outcomes` karti replay sonucunu (`success|retry|resolve|drop`) son `24h` penceresinde gosterebiliyor mu?
- Panel health summary esikleri mantikli mi? runtime calibration profili beklenen warning/alarm bandini yansitiyor mu?

Kanit:

- `apps/mobile_flutter/lib/core/storage/offline_cache_prefs.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/local_db_provider.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/sqflite_local_db_store.dart`
- `apps/mobile_flutter/lib/core/storage/offline_mutation_queue.dart`
- `apps/mobile_flutter/lib/features/menus/data/offline_verify_queue.dart`
- `apps/mobile_flutter/lib/core/storage/offline_submission_queue.dart`
- `apps/mobile_flutter/lib/core/storage/offline_sync_service.dart`
- `apps/mobile_flutter/lib/core/network/connectivity_restore_service.dart`
- `apps/mobile_flutter/lib/features/business/data/business_detail_repository.dart`

## 7. Performans

- Launch cold start kabul edilebilir mi?
- Discovery scroll jank var mi?
- Business/menu/item sayfalari ilk acilista takiliyor mu?
- Image cache davranisi normal mi?
- Native ad veya sponsorlu blok layout'u bozuyor mu?

Oncelikli risk dosyalari:

- `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`

## 8. Test Komutlari

Minimum:

```bash
flutter analyze
flutter test
flutter test test/core/contracts/discovery_api_contract_test.dart
dart run tool/offline_write_guard_check.dart
```

CI/local readiness audit:

```bash
dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json
dart tool/ios_readiness_check.dart
```

Opsiyonel ama onerilen:

```bash
flutter test --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart
flutter test integration_test
```

Canli backend write smoke (opt-in):

```bash
flutter test integration_test/live_write_smoke_integration_test.dart \
  --dart-define=RUN_LIVE_WRITE_SMOKE=true \
  --dart-define=LIVE_SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=LIVE_SUPABASE_ANON_KEY=<anon> \
  --dart-define=LIVE_SMOKE_EMAIL=<email> \
  --dart-define=LIVE_SMOKE_PASSWORD=<password> \
  --dart-define=LIVE_SMOKE_BUSINESS_ID=<business_uuid> \
  --dart-define=LIVE_SMOKE_MENU_ITEM_ID=<menu_item_uuid>
```

## 8.1 Release Gate Metrik Sozlesmesi

Release gate script'i:

- `apps/mobile_flutter/tool/release_gate_check.dart`

Calistirma:

```bash
dart run apps/mobile_flutter/tool/release_gate_check.dart <metrics.json>
```

Ornek dry-run:

```bash
dart run apps/mobile_flutter/tool/release_gate_check.dart apps/mobile_flutter/tool/release_gate_metrics_example.json
```

Beklenen `metrics.json` iskeleti:

```json
{
  "crash_free_rate": 0.998,
  "jank_rate": 0.006,
  "startup_p95_ms": 1800,
  "home_tti_p95_ms": 1000,
  "search_hit_p95_ms": 220,
  "search_miss_p95_ms": 700,
  "embed_open_p95_ms": 950,
  "security": {
    "zero_trust_write": true,
    "waf_ip_reputation": true,
    "device_fingerprint_soft": true,
    "pii_minimized": true,
    "security_review_checklist_done": true
  },
  "release_ops": {
    "backend_feature_flags": true,
    "kill_switch_ready": true,
    "api_versioning_enforced": true,
    "current_rollout_percent": 5,
    "stages": [1, 5, 20, 100],
    "crash_free_rate": 0.999,
    "jank_rate": 0.005,
    "home_tti_p95_ms": 980,
    "embed_open_p95_ms": 900,
    "edge_429_rate": 0.01
  }
}
```

Kararlar:

- `PASS`: release devam eder
- `BLOCK`: release durur
- `ACTION: ROLLOUT_NEXT_STAGE_X`: bir sonraki rollout asamasina gec
- `ACTION: AUTO_ROLLBACK_TRIGGER`: otomatik rollback tetikle
- `ACTION: ROLLBACK_RECOMMENDED`: SLO bazli rollback onerisi

## 9. Release Notes Formati

- Surum
- Commit/tag
- Platform
- Ozet degisiklikler
- Bilinen riskler
- Feature flags
- Smoke sonucu
- Rollback notu

## 10. Go / No-Go

Release verilmemeli eger:

- Android release debug signing ile cikiyorsa
- login/discovery/business/menu smoke kiriksa
- Supabase kontrat drift'i varsa
- Crash/telemetry tamamen kapaliysa
- push token kaydi kritik sekilde bozulmussa
