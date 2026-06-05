# Screenshot Production Status

> **Tarih:** 2026-06-05
> **Durum:** Android emulator mevcut — Firebase hatas nedeniyle screenshot alinamadi

---

## Android

| Kontrol | Sonuc |
|---|---|
| Emulator | Pixel_9_Pro mevcut (emulator-5554) |
| Cihaz boyutu | 1280x2856 px (Pixel 9 Pro) |
| Screenshot alindi mi? | HAYIR |
| Sebep | Firebase initialize hatasi — app crash/splash donuyor |
| Bozuk dosyalar commit edildi mi? | HAYIR (temizlendi) |

### Firebase Hatasi

Ajan flutter build sirasinda Firebase initialization hatasina carpisdi.
`Firebase.initializeApp()` emulator ortaminda `google-services.json` gerektiriyor.

**Cozum (manuel):**
1. Emulatorun gercek Google Play Services destekledigi dogrulanmali (Pixel_9_Pro AVD genellikle Play Store destekler)
2. Veya `--dart-define=USE_FIREBASE_MOCK=true` ile mock Firebase build al
3. Veya profile build yerine release build dene:
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Manuel Screenshot Adimlari (Firebase duzeltildikten sonra)

```bash
# 1. Emulatori baslat
flutter emulators --launch Pixel_9_Pro

# 2. Emulator hazir mi bekle
adb wait-for-device

# 3. Demo mode (temiz statusbar)
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false

# 4. Uygulamayi yukle ve calistir (release)
cd C:/yeedoy/uygulamalar/mobil
flutter run --release -d emulator-5554

# 5. Her ekranda screenshot al
adb exec-out screencap -p > store-assets/screenshots/android/android_01_discovery_list.png
# ... diger ekranlar

# 6. Demo mode kapat
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

### Cekilen Ekranlar (Hedef)

| # | Dosya | Durum |
|---|---|---|
| 1 | android_01_discovery_list.png | Cekrilmedi |
| 2 | android_02_map_view.png | Cekrilmedi |
| 3 | android_03_business_detail.png | Cekrilmedi |
| 4 | android_04_menu_prices.png | Cekrilmedi |
| 5 | android_05_price_index.png | Cekrilmedi |
| 6 | android_06_favorites_alerts.png | Cekrilmedi |
| 7 | android_07_qr_menu.png | Cekrilmedi |
| 8 | android_08_reviews_community.png | Cekrilmedi |

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
