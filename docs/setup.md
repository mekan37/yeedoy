# Kurulum ve Calistirma (Koddan Dogrulandi)

Bu dokuman komutlari dogrudan repo scriptlerinden alinmistir.

## Gereksinimler

- Node.js 20+
- npm 10+
- Flutter SDK (Dart 3.10.x uyumlu)

## Monorepo Koku

```bash
npm install
npm run dev
```

Kanit: `package.json` (repo root)

## Uygulama Bazli

### Mobile (`apps/mobile_flutter`)

```bash
flutter pub get
flutter run -t lib/main_mobile.dart
```

Script: `apps/mobile_flutter/package.json`

### Panel (`apps/panel_flutter_web`)

Web site + owner/admin akisi (varsayilan):

```bash
flutter pub get
flutter run -d chrome -t lib/main_web_owner.dart
```

Admin odakli ayri calisma (opsiyonel):

```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

Script: `apps/panel_flutter_web/package.json`

### Web Next (`apps/web_next`)

```bash
npm install
npm run dev
```

Ek komutlar:

```bash
npm run lint
npm run typecheck
npm run build
npm run start
```

Script: `apps/web_next/package.json`

## Dogrulama Matrisi

```bash
npm run verify:matrix:lint
npm run verify:matrix:build
npm run verify:matrix
```

Kanit: `package.json` (repo root)

## Test Durumu

- Mobile: test + integration_test dosyalari var.
- Panel: test dosyalari var, `integration_test` klasoru bulunamadi.
- Web Next: smoke + unit test scriptleri var (`test:smoke`, `test:unit`, `test`).

Kanit:
- `apps/mobile_flutter/test/*`, `apps/mobile_flutter/integration_test/*`
- `apps/panel_flutter_web/test/*`
- `apps/web_next/package.json`, `apps/web_next/test/*`

## Ortam Degiskenleri

- Mobile: `apps/mobile_flutter/.env.example`
- Panel: `apps/panel_flutter_web/.env.example`
- Web: `apps/web_next/.env.example` -> `.env.local`

Onemli not:
- `apps/web_next/.env.example` placeholder formatina cekildi.
- Production domain/env sozlesmesi: `docs/deploy.md` (`Domain ve ENV Sozlesmesi`).

## Platform Notu

- Kök `clean`, `build:owner`, `build:admin`, `build:next`, `build:all` scriptleri `tools/workspace_ops.mjs` uzerinden calisir.
- Bu helper Node.js tabanlidir ve Windows/Linux/macOS ortamlari icin ortak davranis saglar.
