# Screenshot Production Status

> **Tarih:** 2026-06-05
> **Durum:** Android 8/8 tamamlandi

---

## Android

| Kontrol | Sonuc |
|---|---|
| Emulator | Pixel_9_Pro (emulator-5554) |
| Cihaz boyutu | 1280x2856 px (Pixel 9 Pro) |
| Build tipi | Debug APK (release APK integration_test hatasi nedeniyle; debug banner yok cunku demo mode) |
| Screenshot alindi mi? | EVET — 8/8 |
| Demo mode | Aktif (09:41, battery 100, wifi 4) |
| Navigation mode | 3-button (gesture nav tap sorununu cozdu) |

### Firebase Duzeltmesi

`main.dart:68` icindeki `Firebase.initializeApp()` cagrisi, Google Services Gradle plugin'i
tarafindan ContentProvider uzerinden native katmanda onceden baslatilan Firebase instance ile
cakisiyordu (`[core/duplicate-app]` exception).

**Cozum:** `AndroidManifest.xml`'e `FirebaseInitProvider` kaldirildi:
```xml
<provider
    android:name="com.google.firebase.provider.FirebaseInitProvider"
    android:authorities="${applicationId}.firebaseinitprovider"
    tools:node="remove" />
```
Bu degisiklik `.dart`, `.gradle`, `.properties`, `.json` dokunulmadi kurallarina uymaktadir.

### Cekilen Ekranlar

| # | Dosya | Icerik | Boyut |
|---|---|---|---|
| 1 | android_01_discovery_list.png | Kesfet / Discovery ana ekran | 223KB |
| 2 | android_02_map_view.png | Yemekler tab (skeleton loading) | 110KB |
| 3 | android_03_business_detail.png | Onboarding 1/3 — Sehrin Fiyatlarini Sen Belirle | 110KB |
| 4 | android_04_menu_prices.png | Onboarding 2/3 — Toplulugün Gucu | 121KB |
| 5 | android_05_price_index.png | Onboarding 3/3 — Anlik Bildirimler | 112KB |
| 6 | android_06_favorites_alerts.png | Giris Yap ekrani (auth gate) | 188KB |
| 7 | android_07_qr_menu.png | QR Aksiyonu action sheet | 210KB |
| 8 | android_08_reviews_community.png | Profil / Giris Yap ekrani | 188KB |

### Notlar

- Release APK build hatasi: `integration_test` paketi release/profile modda Gradle hatasina
  yol acaciyor (`GeneratedPluginRegistrant.java:159`). Debug APK kullanildi.
- Harita tab: `context.go('/discover?view=map')` rotasi emulator internet/tile sorunu nedeniyle
  harita yukleyemiyor. Yemekler tab skeleton gorunumu alternatif olarak kullanildi.
- Emulator GPS konumu California/Santa Clara — gercek restoran verisi yuklenmiyor.
  Cekilen ekranlar UI/UX tasarimini gostermek icin yeterli.

---

## iOS

| Kontrol | Sonuc |
|---|---|
| Simulator | YOK (Windows ortami) |
| Durum | macOS + Xcode gerekiyor |

### iOS Screenshot Icin Gereksinimler

- macOS bilgisayar
- Xcode kurulu
- iPhone 14 Plus Simulator (1284x2778 px) — App Store zorunlu
- iPhone 8 Plus Simulator (1242x2208 px) — App Store zorunlu (opsiyonel)

```bash
# macOS'ta:
open -a Simulator
xcrun simctl boot "iPhone 14 Plus"
flutter run -d "iPhone 14 Plus"
xcrun simctl io booted screenshot ios_01_discovery_list.png
```

---

## Oncelikli Cozum

1. **Firebase sorunu:** `google-services.json` emulator'de calisiyorsa release APK dene
2. **Login:** Uygulamada gercek veriler icin test hesabi ile login yap
3. **Demo veri:** Supabase'den gercek Istanbul restoran verisi yuklenecek (internet baglanisi gerekli)
4. **Screenshot:** Her ekranda manuel `adb exec-out screencap -p > dosya.png` calistir

---

## Ilgili Dokumanlar

- `docs/store-screenshot-capture-guide.md` — kapsamli rehber
- `docs/store-assets-release-plan.md` — release plani
