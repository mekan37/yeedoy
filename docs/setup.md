# Kurulum ve Calistirma (Koddan Dogrulandi)

Bu dokuman komutlari repo scriptleri ve mevcut uygulama yapisina gore guncellenmistir.

## Gereksinimler

- Node.js 20+
- npm 10+
- Flutter SDK

## Monorepo Koku

```bash
npm install
```

Kanit: `package.json` (repo root)

## Uygulama Bazli

### Mobile (`apps/mobile_flutter`)

```bash
flutter pub get
flutter run -t lib/main_mobile.dart
```

Android release:

```bash
flutter build apk --release -t lib/main_mobile.dart
```

Not:
- Signing secret kaynagi iki sekilde verilebilir:
  - `apps/mobile_flutter/android/key.properties` (lokal fallback)
  - env secret'lari: `ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`
- Secret eksiginde `assembleRelease` bilincli olarak fail eder.
- Mobile release smoke ve go/no-go adimlarinin tek kaynagi `docs/mobile_release_checklist.md` dosyasidir.
- Mobile CI ve iOS readiness workflow sozlesmesinin tek kaynagi `docs/mobile_ci_ios_readiness.md` dosyasidir.
- Mobilin kullandigi Supabase kontratlari icin `docs/mobile_supabase_contracts.md` dosyasina bakin.
- Mimari ve urun kapsami icin `docs/mobile_architecture.md` ve `docs/mobile_features_matrix.md` kullanilmalidir.

iOS readiness audit:

```bash
cd apps/mobile_flutter
dart tool/ios_readiness_check.dart
```

Not:
- Bu audit repo icindeki iOS varliklarini denetler; bugunku repo icerigine gore `Podfile`, entitlements, export template ve push capability kanitlari mevcuttur.
- Kalan risk signed release asset'lari ve gercek cihaz smoke kanitidir.
- Repo-root `mobile_readiness` workflow'u ayni denetimi macOS runner uzerinde tekrarlar; signed iOS IPA dry-run acildiginda secret audit'e ek olarak provisioning profile / entitlements / export options uyumunu da denetler.
- Ayni workflow, basarili signed dry-run sonrasinda IPA/APK artifact'ini run sonucunda indirilebilir hale getirir.

Canli backend write smoke (opt-in):

```bash
flutter test apps/mobile_flutter/integration_test/live_write_smoke_integration_test.dart \
  --dart-define=RUN_LIVE_WRITE_SMOKE=true \
  --dart-define=LIVE_SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=LIVE_SUPABASE_ANON_KEY=<anon> \
  --dart-define=LIVE_SMOKE_EMAIL=<email> \
  --dart-define=LIVE_SMOKE_PASSWORD=<password> \
  --dart-define=LIVE_SMOKE_BUSINESS_ID=<business_uuid> \
  --dart-define=LIVE_SMOKE_MENU_ITEM_ID=<menu_item_uuid>
```

### Panel (`apps/panel_flutter_web`)

```bash
flutter pub get
flutter run -d chrome -t lib/main_web_owner.dart
```

Admin odakli calisma:

```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

Panel icin hizli kontrol komutlari:

```bash
flutter analyze
flutter build web --release --dart-define=DEV_TOOLS_ENABLED=false --target lib/main_web_owner.dart
npm run test:smoke
```

Not:
- `/admin/dev-tools` yalnizca debug veya `DEV_TOOLS_ENABLED=true` iken erisilebilir.
- Panel owner/admin yonlendirmesi ayni Flutter Web uygulamasi icinde calisir.
- Panel smoke `integration_test` ile degil, derlenmis `lib/main_web_smoke.dart` artifact'i ustunde Playwright ile kosar.

### Web Next (`apps/web_next`)

Repo kokunden:

```bash
npm --prefix apps/web_next run dev
```

veya uygulama klasorunde:

```bash
cd apps/web_next
npm run dev
```

Ek komutlar:

```bash
npm --prefix apps/web_next run lint
npm --prefix apps/web_next run typecheck
npm --prefix apps/web_next run build
npm --prefix apps/web_next run start
npm --prefix apps/web_next run test:unit
npm --prefix apps/web_next run test:e2e
npm --prefix apps/web_next run test:e2e:live
```

Not:
- `apps/web_next` yalnizca public menu + QR + analytics katmanidir.
- Owner/admin CRUD akislarini burada aramayin; bunlar panel uygulamasindadir.
- App bazli giris dokumanlari:
  - `apps/panel_flutter_web/README.md`
  - `apps/web_next/README.md`

## Test Durumu

- Mobile: test + integration_test dosyalari var.
- Panel: test + Playwright `e2e` smoke dosyalari var.
- Web Next: smoke, unit ve e2e scriptleri var.

Kanit:
- `apps/mobile_flutter/test/*`
- `apps/mobile_flutter/integration_test/*`
- `apps/panel_flutter_web/test/*`
- `apps/panel_flutter_web/e2e/*`
- `apps/web_next/test/*`
- `apps/web_next/e2e/*`

Not:
- Playwright ilk kurulumda `npx playwright install chromium` isteyebilir.
- Panel smoke Playwright binary'sini `apps/web_next/node_modules` altindan kullanir.

## Ortam Degiskenleri

Env sozlesmesi bu dokumanin konusu degildir. Tek kaynak:

- `docs/deploy.md`

Hizli dosya haritasi:

- Mobile: `apps/mobile_flutter/.env.example`
- Panel: `apps/panel_flutter_web/.env.example`
- Web: `apps/web_next/.env.example` -> `.env.local`

Not:
- Playwright smoke degiskenleri ve production domain beklentileri de `docs/deploy.md` icinde tutulur.
- Repo-root workflow omurgasi artik istemci bazinda aciktir:
  - `mobile_quality`
  - `mobile_readiness`
  - `panel_quality`
  - `web_quality`
- Panel browser smoke ve gercek cihaz mobile smoke halen manuel/opsiyonel katmanda tutulur.
- Panel browser smoke CI'da opsiyonel `run_playwright_smoke` girisi ile ayrik tutulur.

## Platform Notu

- Kok `clean`, `build:owner`, `build:admin`, `build:next`, `build:all` scriptleri `tools/workspace_ops.mjs` uzerinden calisir.
- Bu helper Windows/Linux/macOS ortamlari icin ortak davranis saglar.
