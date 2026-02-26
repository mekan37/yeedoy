# Dağıtım

## Mobil Flutter
- APK:
  - `flutter build apk --release -t apps/mobile_flutter/lib/main_mobile.dart`
- iOS (opsiyonel):
  - `flutter build ipa --release -t apps/mobile_flutter/lib/main_mobile.dart`

## Panel Flutter Web
- Admin:
  - `flutter build web --release --target apps/panel_flutter_web/lib/main_web_admin.dart`
- Owner:
  - `flutter build web --release --target apps/panel_flutter_web/lib/main_web_owner.dart`

## Web Next
- Build:
  - `npm --prefix apps/web_next run build`
- Start:
  - `npm --prefix apps/web_next run start`

## Kök Kısayollar
- `npm run build`
- `npm run build:all`
