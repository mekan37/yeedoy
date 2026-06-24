# mobile_flutter

Flutter mobil tüketici uygulaması.

## Kurulum
1. `.env.example` dosyasını `.env` olarak kopyala.
2. Supabase ve URL değerlerini doldur.
3. Çalıştır:

```bash
flutter pub get
flutter run -t lib/main_mobile.dart
```

Ek referanslar:

- Release checklist: `docs/mobile_release_checklist.md`
- CI ve iOS readiness: `docs/mobile_ci_ios_readiness.md`
- Supabase kontratlari: `docs/mobile_supabase_contracts.md`

## Build

```bash
flutter build apk --release -t lib/main_mobile.dart
```

Not:
- Release signing icin iki yol vardir:
  - `android/key.properties` (lokal fallback)
  - env secret'lari (`ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`)
- Ornek key format: `android/key.properties.example`
- Ayrintili checklist: `docs/mobile_release_checklist.md`

PowerShell ornegi:

```powershell
$env:ANDROID_RELEASE_STORE_FILE="..\keystores\release.keystore"
$env:ANDROID_RELEASE_STORE_PASSWORD="***"
$env:ANDROID_RELEASE_KEY_ALIAS="release"
$env:ANDROID_RELEASE_KEY_PASSWORD="***"
flutter build apk --release -t lib/main_mobile.dart
```

## iOS Readiness

```bash
dart tool/ios_readiness_check.dart
```

Not:

- Bu script `ios/Podfile`, `.entitlements`, `aps-environment`, `Associated Domains`, `GoogleService-Info.plist`, `ExportOptions.plist` ve bundle id kanitlarini denetler.
- Repo iskeleti tarafinda `Podfile`, `Runner.entitlements`, `ExportOptions.plist` template'i ve push capability kanitlari artik vardir.
- `dart tool/ios_signing_check.dart` artik sadece env varligini degil, placeholder secret degerlerini, Apple Team ID formatini ve base64 payload decode edilebilirligini de denetler.
- Signed release tarafinda ikinci kapi olarak `dart tool/ios_signing_assets_check.dart` provisioning profile / entitlements / export options uyumunu denetler; bu arac genelde `mobile_readiness` workflow'u icinde decode edilmis CI asset'lariyla calisir.
- `mobile_readiness` signed dry-run acildiginda IPA artifact'ini workflow sonucunda yukler; bu build kanitidir, TestFlight dagitimi degildir.
- Kalan iOS riski signed release asset'lari, `GoogleService-Info.plist` yonetimi ve gercek cihaz smoke kanitidir; detayli durum icin `docs/mobile_ci_ios_readiness.md` dosyasina bakin.

## Analiz

```bash
flutter analyze
```

## Smoke Test

Router/cold-start smoke:

```bash
flutter test integration_test/golden_paths_integration_test.dart
```

Yerel kalite kapisi:

```bash
flutter test test
dart tool/offline_write_guard_check.dart
dart tool/ios_signing_check.dart
dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json
```

Canli backend write smoke (opt-in):

```bash
flutter test integration_test/live_write_smoke_integration_test.dart ^
  --dart-define=RUN_LIVE_WRITE_SMOKE=true ^
  --dart-define=LIVE_SUPABASE_URL=https://<project>.supabase.co ^
  --dart-define=LIVE_SUPABASE_ANON_KEY=<anon> ^
  --dart-define=LIVE_SMOKE_EMAIL=<email> ^
  --dart-define=LIVE_SMOKE_PASSWORD=<password> ^
  --dart-define=LIVE_SMOKE_BUSINESS_ID=<business_uuid> ^
  --dart-define=LIVE_SMOKE_MENU_ITEM_ID=<menu_item_uuid>
```

## Not
- Developer Tools ekranı `DEV_TOOLS_ENABLED` ve debug koşuluyla açılır.
- Repo-root GitHub Actions tarafinda istemci bazli `mobile_quality` ve `mobile_readiness` workflow'lari bulunur.
