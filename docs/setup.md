# Kurulum

## Gereksinimler
- Flutter SDK (stable)
- Node.js 20+
- npm 10+
- Supabase proje bilgileri

## Kökten çalışma

```bash
npm install
npm run dev
```

## Uygulama Bazında

### Mobil (Flutter)

```bash
cd apps/mobile_flutter
flutter pub get
flutter run -t lib/main_mobile.dart
```

### Panel (Flutter Web)

```bash
cd apps/panel_flutter_web
flutter pub get
flutter run -d chrome -t lib/main_web_admin.dart
```

### Web (Next.js)

```bash
cd apps/web_next
npm install
npm run dev
```
