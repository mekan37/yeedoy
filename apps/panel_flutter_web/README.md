# panel_flutter_web

Flutter Web owner/admin panel uygulaması.

## Kurulum
1. `.env.example` dosyasını `.env` olarak kopyala.
2. Supabase ve URL değişkenlerini doldur.

Varsayilan web giris (landing + owner/admin yonlendirme):

```bash
flutter pub get
flutter run -d chrome -t lib/main_web_owner.dart
```

Admin odakli calisma:

```bash
flutter run -d chrome -t lib/main_web_admin.dart
```

## Build

```bash
flutter build web --release --target lib/main_web_owner.dart
```

## Analiz

```bash
flutter analyze
```

## Not
- `/admin/dev-tools` yalnızca debug veya `DEV_TOOLS_ENABLED=true` iken erişilebilir.

## Production ENV ve Domain Notu

Runtime `.env` zorunlu alanlar:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Opsiyonel/cross-app alanlar (`.env.example` ile uyum):

- `BASE_URL_WEB_NEXT`
- `BASE_URL_PANEL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DEV_TOOLS_ENABLED`

Compile-time (`--dart-define`) alanlar:

- `PLAY_STORE_URL`, `APP_STORE_URL`, `WEB_NEXT_URL`
- `APP_NAME`, `APP_SLUG`, `WEB_DOMAIN`, `DEEPLINK_SCHEME`, `DEV_TOOLS_ENABLED`

Detayli sozlesme ve Next entegrasyon notlari icin:

- `docs/deploy.md` -> `Domain ve ENV Sozlesmesi`
