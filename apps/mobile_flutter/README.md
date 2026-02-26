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

## Build

```bash
flutter build apk --release -t lib/main_mobile.dart
```

## Analiz

```bash
flutter analyze
```

## Not
- Developer Tools ekranı `DEV_TOOLS_ENABLED` ve debug koşuluyla açılır.
