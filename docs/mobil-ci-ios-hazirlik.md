# Mobil CI ve iOS Hazirlik Durumu

Bu belge `uygulamalar/mobil` icin CI workflow'larini ve iOS release readiness kontrolunu tanimlar.

## 1. Workflow Envanteri

### `.github/workflows/mobile_quality.yml`

Amac:

- pull request ve `main` push akisinda temel kalite kapisini otomatiklestirmek

Calistirdigi adimlar:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test test`
4. `dart tool/offline_write_guard_check.dart`
5. `dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json`

Not:

- bu workflow `integration_test` veya canli write smoke kosmaz
- amac hizli merge kapisi saglamaktir

### `.github/workflows/mobile_readiness.yml`

Amac:

- manuel readiness denetimlerini tek workflow altinda toplamak

Job'lar:

1. `ios_readiness_audit`
   - `dart tool/ios_readiness_check.dart`
   - iOS proje dosyalari, entitlements ve push readiness kanitlarini denetler
2. `release_gate_audit`
   - `dart run tool/release_gate_check.dart <metrics_path>`
   - rollout/distribution karari icin metrik JSON'unu merkezi workflow seviyesinde denetler
3. `ios_release_dry_run`
   - manuel `workflow_dispatch` input'i ile calisir
   - `ios_readiness_audit` ve `release_gate_audit` gectikten sonra calisir
   - signing secret'lari varsa signed `ipa` dry-run uretir
   - CI tarafinda certificate, provisioning profile ve opsiyonel `GoogleService-Info.plist` payload'ini decode eder
   - `dart tool/ios_signing_check.dart --ci` ile secret sozlesmesini denetler
   - bu audit placeholder deger, Team ID formati ve base64 decode edilebilirlik kontrolu de yapar
   - `dart tool/ios_signing_assets_check.dart` ile provisioning profile / entitlements / export options uyumunu denetler
   - export method'e gore `aps-environment` degerini CI icinde normalize eder (`development` veya `production`)
   - basarili kosumda IPA ve CI icin uretilen `ExportOptions.ci.plist` artifact olarak yuklenir
   - GitHub job summary icinde export method, Firebase mode ve uretilen IPA yolu yazilir
   - build sonrasi keychain, provisioning profile, decoded certificate ve gecici plist dosyalarini temizler
4. `android_release_dry_run`
   - manuel `workflow_dispatch` input'i ile calisir
   - `ios_readiness_audit` ve `release_gate_audit` gectikten sonra calisir
   - release keystore secret'lari varsa `flutter build apk --release -t lib/mobil_giris.dart` kosar

## 2. Gerekli GitHub Secret'lari

Android release dry-run icin:

- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_RELEASE_STORE_PASSWORD`
- `ANDROID_RELEASE_KEY_ALIAS`
- `ANDROID_RELEASE_KEY_PASSWORD`

iOS signed release dry-run icin:

- `IOS_APPLE_TEAM_ID`
- `IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- opsiyonel: `IOS_GOOGLE_SERVICE_INFO_BASE64`

Not:

- `ANDROID_RELEASE_STORE_FILE` workflow icinde `android/uygulama/ci-release.keystore` olarak yazilir
- iOS tarafinda export method ve Firebase config mode `workflow_dispatch` input'i ile verilir

## 3. iOS Readiness Audit Kurallari

`uygulamalar/mobil/tool/ios_readiness_check.dart` su alanlari denetler:

1. `ios/Runner.xcworkspace`
2. `ios/Runner.xcodeproj/project.pbxproj`
3. `ios/Runner/Info.plist`
4. `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
5. `ios/Podfile`
6. entitlements dosyasi varligi
7. `aps-environment` entitlement'i
8. `Associated Domains` entitlement'i
9. `GoogleService-Info.plist`
10. `ExportOptions.plist`
11. `PRODUCT_BUNDLE_IDENTIFIER`
12. `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`
13. `remote-notification` background mode

Sonuc kodlari:

- `IOS_READINESS: PASS`
- `IOS_READINESS: WARN`
- `IOS_READINESS: BLOCK`

`uygulamalar/mobil/tool/ios_signing_check.dart` signed release secret modelini denetler:

- `IOS_APPLE_TEAM_ID`
- distribution certificate payload + password
- provisioning profile payload
- export method
- `flutterfire_options` veya `google_service_info` secimine gore Firebase config modeli
- `DEVELOPMENT_TEAM = $(APPLE_TEAM_ID)` wiring kaniti
- placeholder secret degerlerinin reddi
- Apple Team ID format kontrolu (`[A-Z0-9]{10}`)
- base64 payload'larin decode edilebilirlik ve minimum boyut kontrolu

`uygulamalar/mobil/tool/ios_signing_assets_check.dart` ise decoded signing asset'larinin projeyle uyumunu denetler:

- provisioning profile `TeamIdentifier` -> `IOS_APPLE_TEAM_ID`
- provisioning profile `application-identifier` -> `<TEAM_ID>.<BUNDLE_ID>`
- provisioning profile `aps-environment` -> export method'e gore beklenen push ortami
- `Runner.entitlements` icindeki `aps-environment` degeri
- olusturulan `ExportOptions.ci.plist` icindeki `method` ve `teamID`
- `google_service_info` modunda `GoogleService-Info.plist` varligi

## 4. Bugunku Durum

Repo icindeki bugunku iOS kanitlari:

- `PRODUCT_BUNDLE_IDENTIFIER = com.yeedoy.app` var
- `Runner.xcworkspace` ve paylasilan `Runner.xcscheme` var
- `ios/Podfile` var
- `ios/Runner/Runner.entitlements` var
- `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` baglanti kaniti var
- `aps-environment` ve `Associated Domains` entitlement'lari var
- `ios/ExportOptions.plist` template'i var
- `Info.plist` icinde `remote-notification` background mode var
- repo icinde `ios/Runner/GoogleService-Info.plist` gorunmuyor

Sonuc:

- repo icerigine gore iOS readiness artik `BLOCK` yerine `WARN` seviyesine inmis durumdadir
- kalan ana bosluk signed release asset'lari ve gercek iOS cihaz smoke kanitidir
- workflow bunu macOS runner uzerinde merkezi readiness denetimi olarak gosterecektir
- signed dry-run acildiginda ekip IPA artifact'ini workflow artifact listesinden indirip build kanitini gorebilir; bu adim TestFlight dagitimi ile karistirilmamalidir

## 5. Lokal Komutlar

Mobile kalite:

```bash
cd uygulamalar/mobil
flutter pub get
flutter analyze
flutter test test
dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json
```

iOS readiness:

```bash
cd uygulamalar/mobil
dart tool/ios_readiness_check.dart
```

Android release dry-run:

```bash
cd uygulamalar/mobil
flutter build apk --release -t lib/mobil_giris.dart
```

iOS signing audit:

```bash
cd uygulamalar/mobil
dart tool/ios_signing_check.dart
```

iOS signing asset audit:

- bu arac genelde CI icinde, decode edilmis provisioning profile plist ve export options plist hazirlandiktan sonra calisir
- beklenen env:
  - `IOS_APPLE_TEAM_ID`
  - `IOS_EXPORT_METHOD`
  - `IOS_PROVISIONING_PROFILE_PLIST_PATH`
  - `IOS_EXPORT_OPTIONS_PLIST_PATH`

```bash
cd uygulamalar/mobil
dart tool/ios_signing_assets_check.dart
```

## 6. Sonraki iOS Kapatma Adimlari

1. `GoogleService-Info.plist` repo disi secret/CI artifact olarak mi yoksa FlutterFire options-only modelle mi yonetilecegini netlestir
2. Apple Team / provisioning / signing kanitlarini CI secret'lariyla doldurup `ios_release_dry_run` job'unu gercek artefaktla calistir
3. gercek iOS cihazla deep-link ve push-tap smoke tekrarini yap
4. TestFlight upload/asli dagitim adimini signed dry-run sonrasinda ayrik workflow veya operator runbook'u ile sonlandir
