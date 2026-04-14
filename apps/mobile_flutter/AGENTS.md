# Mobile App Kurallari

Bu app son kullanici akislarina bakar. Owner/admin operasyonu buraya eklenmez.

## Kanonik Yapi

- Entry: `lib/main_mobile.dart`
- Router: `lib/app/router.dart`
- State: Riverpod
- Tema: `lib/app/theme/*`
- L10n: `lib/l10n/*.arb`
- Feature katmanlari: `data/domain/ui`

## Yazim Kurali

- Supabase erisimi repository'de kalir.
- Yeni provider/controller `domain` altina gider.
- Yeni sayfa `ui/*_page.dart` olur.
- Ortak primitive icin once `features/shared/ui` ve `packages/shared_ui_components` bak.
- Kullanici metni ARB'ye eklenir; inline string buyutulmaz.

## Responsive

- `ScreenUtilInit` korunur.
- Genis yuzeylerde mevcut `720/1040` max-width kalibini kullan.
- `LayoutBuilder` ve `ConstrainedBox` tercih et.

## Validation

```bash
npm --prefix apps/mobile_flutter run lint
```

Test gerekiyorsa dokunulan alana yakin testleri veya mevcut `flutter test` cizgisini calistir.
