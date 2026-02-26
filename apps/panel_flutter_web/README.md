# panel_flutter_web

Flutter Web owner/admin panel uygulaması.

## Kurulum
1. `.env.example` dosyasını `.env` olarak kopyala.
2. Supabase ve URL değişkenlerini doldur.

Admin paneli:

```bash
flutter pub get
flutter run -d chrome -t lib/main_web_admin.dart
```

Owner paneli:

```bash
flutter run -d chrome -t lib/main_web_owner.dart
```

## Build

```bash
flutter build web --release --target lib/main_web_admin.dart
```

## Analiz

```bash
flutter analyze
```

## Not
- `/admin/dev-tools` yalnızca debug veya `DEV_TOOLS_ENABLED=true` iken erişilebilir.
