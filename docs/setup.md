# Kurulum ve Çalıştırma (Kaynak Doküman)

Bu doküman doğrudan `package.json`, `pubspec.yaml`, giriş dosyaları ve `.env.example` içeriklerinden üretilmiştir.

## Gereksinimler

- Node.js 20+
- npm 10+
- Flutter SDK (Dart 3.10.x ile uyumlu)

## Monorepo Kökünden Çalışma

```bash
npm install
npm run dev
```

Kök script kaynakları:

- `package.json` (repo kökü)

## Ortam Değişkenleri

### Mobil

- Dosya: `apps/mobile_flutter/.env`
- Örnek: `apps/mobile_flutter/.env.example`

### Panel

- Dosya: `apps/panel_flutter_web/.env`
- Örnek: `apps/panel_flutter_web/.env.example`

### Web Next

- Dosya: `apps/web_next/.env.local`
- Örnek: `apps/web_next/.env.example`

Not:

- Bu repo snapshot'ında bazı `.env.example` dosyalarında gerçek anahtar benzeri değerler bulunuyor; yayın öncesi temizlenmesi gerekir.

## Uygulama Bazında Komutlar

### Mobil (`apps/mobile_flutter`)

```bash
flutter pub get
flutter run -t lib/main_mobile.dart
```

Script karşılığı:

- `apps/mobile_flutter/package.json` -> `dev`, `build`, `lint`

### Panel (`apps/panel_flutter_web`)

Admin:

```bash
flutter pub get
flutter run -d chrome -t lib/main_web_admin.dart
```

Owner:

```bash
flutter run -d chrome -t lib/main_web_owner.dart
```

Script karşılığı:

- `apps/panel_flutter_web/package.json` -> `dev`, `dev:owner`, `build`, `lint`

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

Script kaynağı:

- `apps/web_next/package.json`

## Doğrulama Komutları

Kök doğrulama scriptleri:

```bash
npm run verify:matrix:lint
npm run verify:matrix:build
npm run verify:matrix
```

Kaynak:

- repo kökü `package.json`

## Test Durumu

- `apps/web_next`:
  - `test` script'i var ama `test:smoke` -> `typecheck + lint` yapıyor.
  - Repo içinde `*.test*` / `*.spec.*` dosyası bulunamadı.
- `apps/mobile_flutter`:
  - `test/` ve `integration_test/` altında test dosyaları mevcut.
- `apps/panel_flutter_web`:
  - `test/` altında test dosyaları mevcut.
  - `integration_test/` klasörü bulunamadı.

## Platform Notu

Kök `clean` ve bazı `build:*` scriptleri PowerShell komutları içerir. Windows dışı CI/CD ortamlarında eşdeğer script gerekebilir.

Kaynak:

- repo kökü `package.json`
