# Store Screenshot Çekim Rehberi

> **Hazırlanma:** 2026-06-05
> **Durum:** Hazir — uygulama v1.0 yayini oncesi screenshot cakim kilavuzu
> **Kapsam:** 8 senaryo × 2 platform (Android + iOS) = 16 screenshot

---

## 1. Cihaz ve Boyut Gereksinimleri

### 1.1 Google Play Store (Zorunlu)

| Parametre | Deger |
|---|---|
| **Boyut** | 1080×1920 px (9:16 dikey — onerilir) |
| **Min kenar** | 320 px |
| **Max kenar** | 3840 px |
| **Format** | PNG veya JPG |
| **Adet** | 2 minimum, 8 maksimum |
| **Onerilen emulator** | Pixel 6 / API 34 — 1080×2400 px |

### 1.2 App Store (iOS) — Zorunlu Boyutlar

| Cihaz | Boyut | Durum |
|---|---|---|
| **iPhone 6.5" (14 Plus / 15 Plus)** | 1284×2778 px | Zorunlu |
| **iPhone 5.5" (8 Plus)** | 1242×2208 px | Zorunlu |
| **iPad 12.9"** | 2048×2732 px | Opsiyonel |

### 1.3 Arac Onerileri

**Android:**
```bash
# Android Studio emulator baslat (Pixel 6, API 34)
# Sonra screenshot al:
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/android_XX_name.png
```

**iOS:**
```bash
# Xcode Simulator ac (iPhone 15 Plus, iOS 17.x)
# Sonra screenshot al:
xcrun simctl io booted screenshot ./screenshots/ios_XX_name.png
```

---

## 2. On Hazirlik — Checklist

Cekime baslamadan once asagidaki adimlar tamamlanmis olmalidir:

- [ ] Demo hesap giris yapilmis (`test@yeedoy.com` veya gercek hesap)
- [ ] Konum izni verilmis — test koordinatlari:
  - Istanbul Kadikoy: `40.9833, 29.0333`
  - Istanbul Beyoglu: `41.0333, 28.9833`
- [ ] Notification izni verilmis
- [ ] En az 3-5 gercek isletme favorilenmis (Favoriler ekrani icin)
- [ ] Gercek + gorselli bir Istanbul isletmesi secilmis (detay ekrani icin)
- [ ] Fiyat gecmisi olan bir isletme belirlenmis (trend ekrani icin)
- [ ] Gecerli bir QR menu URL'i hazir (QR ekrani icin)
- [ ] Statusbar temizligi:
  - Saat: `09:41`
  - Batarya: tam sarj (100%)
  - Sinyal: tam cekis
  - Bildirim badge: sifir
- [ ] Mod: **Aydinlik mod** (store standardi)
- [ ] Dil: **Turkce** (birincil; EN versiyonlari icin dilden sonra tekrar cek)

---

## 3. Screenshot Listesi — 8 Senaryo

### Screenshot 1 — Discovery / Kesif Listesi

| Alan | Deger |
|---|---|
| **Sira** | 1 |
| **Baslik (TR)** | "Yakınındaki restoranları keşfet" |
| **Baslik (EN)** | "Discover restaurants nearby" |
| **Ekran / Route** | `/discover` — Liste tab aktif |
| **Platform** | Android + iOS |
| **On kosul** | Konum izni verilmis, Istanbul koordinati yuklenmis, isletme listesi gorunur |
| **Aciklama** | Fiyat rozetleri (₺ / ₺₺ / ₺₺₺), puan yildizlari, mesafe bilgisi, liste gorunumu |
| **Dosya adi** | `android_01_discovery_list.png` / `ios_01_discovery_list.png` |

**Kontrol edilecekler:**
- En az 4-5 isletme listede gorunmeli
- Her isletme kartinda fiyat rozeti olmali
- Arama cubugu gorunur olmali
- Filter chipleri (kategori, mesafe) gorunur olmali

---

### Screenshot 2 — Harita Gorunumu

| Alan | Deger |
|---|---|
| **Sira** | 2 |
| **Baslik (TR)** | "Haritadan çevrendeki fiyatları gör" |
| **Baslik (EN)** | "Explore prices on the map" |
| **Ekran / Route** | `/discover` → Harita tab VEYA `/c/:slug` harita modu |
| **Platform** | Android + iOS |
| **On kosul** | Konum izni, harita yuklenmis, pin'ler gorunur |
| **Aciklama** | Harita uzerinde isletme pin'leri, yakinlik cemberi, alt liste onizlemesi |
| **Dosya adi** | `android_02_map_view.png` / `ios_02_map_view.png` |

**Kontrol edilecekler:**
- En az 5-8 pin haritada gorunmeli
- Kullanicinin konumu mavi nokta ile isaretli
- Alt kisimda isletme kartlari gorunmeli (bottom sheet)
- Harita tipi: standart (satellite degil)

---

### Screenshot 3 — Isletme Detay

| Alan | Deger |
|---|---|
| **Sira** | 3 |
| **Baslik (TR)** | "Fiyat, yorum, menü — tek ekranda" |
| **Baslik (EN)** | "Prices, reviews and menu — all in one" |
| **Ekran / Route** | `/b/:id` — isletme detay sayfasi (scroll ust kisim) |
| **Platform** | Android + iOS |
| **On kosul** | Gorselli, puanli, yorumlu ve fiyat rozetli bir Istanbul isletmesi |
| **Aciklama** | Hero gorseli, isletme adi, puan (yildiz + sayi), fiyat rozeti, acik/kapali badge |
| **Dosya adi** | `android_03_business_detail.png` / `ios_03_business_detail.png` |

**Kontrol edilecekler:**
- Hero gorseli tam genislikte gorunmeli
- Puan + yorum sayisi gorunur olmali
- Fiyat rozeti (₺/₺₺/₺₺₺) gorunmeli
- "Acik" veya saat bilgisi gorunmeli
- Menüye git butonu gorunmeli

---

### Screenshot 4 — Menu ve Fiyat Rozeti

| Alan | Deger |
|---|---|
| **Sira** | 4 |
| **Baslik (TR)** | "Menü fiyatlarını anında gör" |
| **Baslik (EN)** | "See menu prices instantly" |
| **Ekran / Route** | `/b/:id/menu/:menuId` — menu sayfasi |
| **Platform** | Android + iOS |
| **On kosul** | Fiyatli menu ogeleri olan isletme, fotografi olan urunler tercih edilir |
| **Aciklama** | Menu ogeleri listesi, fiyatlar, urun fotograflari, kategori basliklari |
| **Dosya adi** | `android_04_menu_prices.png` / `ios_04_menu_prices.png` |

**Kontrol edilecekler:**
- En az 4-6 menu ogesi gorunmeli
- Her ogede fiyat acikca gorunmeli (TRY veya ₺)
- Kategori baslik ayirici gorunmeli
- En az 1-2 ogede fotograf olmali
- Fiyat rozeti (ucuz/orta/pahali renk kodu) gorunmeli

---

### Screenshot 5 — Fiyat Endeksi / Trend Grafigi

| Alan | Deger |
|---|---|
| **Sira** | 5 |
| **Baslik (TR)** | "Fiyat trendini takip et" |
| **Baslik (EN)** | "Track price trends over time" |
| **Ekran / Route** | `/b/:id` isletme detay sayfasi → asagi scroll → Fiyat Endeksi kart bolumu |
| **Platform** | Android + iOS |
| **On kosul** | Fiyat gecmisi (en az 30 gun) olan isletme |
| **Aciklama** | Zaman serisi cizgi grafigi, min/max etiketler, son 90 gun, fiyat artis/dusus gostergesi |
| **Dosya adi** | `android_05_price_trend.png` / `ios_05_price_trend.png` |

**Kontrol edilecekler:**
- Grafik render edilmis olmali (bos ekran olmamali)
- X ekseni: tarih etiketleri
- Y ekseni: TRY tutarlari
- Artis/dusus icin farkli renk (yesil/kirmizi)
- Kart basliginda "Fiyat Endeksi" veya benzeri yazi gorunmeli

---

### Screenshot 6 — Favoriler ve Fiyat Bildirimi

| Alan | Deger |
|---|---|
| **Sira** | 6 |
| **Baslik (TR)** | "Fiyat değişince bildirim al" |
| **Baslik (EN)** | "Get notified when prices change" |
| **Ekran / Route** | `/favorites` — favoriler sayfasi |
| **Platform** | Android + iOS |
| **On kosul** | 3-5 isletme favorilenmis, bildirim izni verilmis |
| **Aciklama** | Favori isletme listesi, fiyat rozetleri, bildirim etkin badge |
| **Dosya adi** | `android_06_favorites_alert.png` / `ios_06_favorites_alert.png` |

**Kontrol edilecekler:**
- En az 3 isletme listede gorunmeli
- Her kart: isletme adi, fiyat rozeti, puan
- "Bildirim Ac" veya zil ikonu gorunmeli (varsa)
- Liste bos olmamali

---

### Screenshot 7 — QR Menu

| Alan | Deger |
|---|---|
| **Sira** | 7 |
| **Baslik (TR)** | "QR kodla menüye anında eriş" |
| **Baslik (EN)** | "Open the menu with QR scan" |
| **Ekran / Route** | `/menu/:menuId` — public_menu_share_page (giris gerektirmez) |
| **Platform** | Android + iOS |
| **On kosul** | Gecerli bir QR menu URL'i, isletmenin aktif menusu olmali |
| **Aciklama** | QR ile acilan menu, isletme adi/logosu, menu ogeleri, temiz tasarim |
| **Dosya adi** | `android_07_qr_menu.png` / `ios_07_qr_menu.png` |

**Kontrol edilecekler:**
- Sayfa auth olmadan acilmali (tarayici/uygulama icinde)
- Isletme logosu veya adi ustte gorunmeli
- Menu ogesi listesi fiyatlarla gorunmeli
- Yeedoy "Powered by" branding gorunebilir (varsa)
- Temiz, sade tasarim (public menu stili)

---

### Screenshot 8 — Topluluk / Yorumlar

| Alan | Deger |
|---|---|
| **Sira** | 8 |
| **Baslik (TR)** | "Toplulukla fiyatları doğrula" |
| **Baslik (EN)** | "Verify prices with the community" |
| **Ekran / Route** | `/feed` veya `/b/:id` isletme yorumlar bolumu |
| **Platform** | Android + iOS |
| **On kosul** | Yorumlu isletme, feed'de en az 3-4 yorum karti gorunur |
| **Aciklama** | Yorum kartlari, kullanici puanlari, "X kisi onayladi" rozeti, fiyat onay badge |
| **Dosya adi** | `android_08_community_reviews.png` / `ios_08_community_reviews.png` |

**Kontrol edilecekler:**
- En az 3 yorum karti ekranda gorunmeli
- Her yorumda puan (yildiz) + tarih olmali
- "Dogrulanmis Ziyaret" veya benzeri badge gorunmeli (varsa)
- Yorum yazan avatar/isim gorunmeli (anonim de olabilir)
- Fiyat onay rozeti veya "X kisi fiyati onayladi" gorunmeli (varsa)

---

## 4. Dosya Adlandirma Standardi

```
Format:  [platform]_[sira]_[aciklama].[uzanti]
Ornekler:
  android_01_discovery_list.png
  android_02_map_view.png
  ios_01_discovery_list.png
  ios_02_map_view.png

Dizi oneri:
  assets/store/android/screenshots/
  assets/store/ios/screenshots/
  assets/store/icons/
```

Tam dizin agaci:

```
assets/
  store/
    android/
      screenshots/
        android_01_discovery_list.png
        android_02_map_view.png
        android_03_business_detail.png
        android_04_menu_prices.png
        android_05_price_trend.png
        android_06_favorites_alert.png
        android_07_qr_menu.png
        android_08_community_reviews.png
    ios/
      screenshots/
        ios_01_discovery_list.png
        ios_02_map_view.png
        ios_03_business_detail.png
        ios_04_menu_prices.png
        ios_05_price_trend.png
        ios_06_favorites_alert.png
        ios_07_qr_menu.png
        ios_08_community_reviews.png
    icons/
      icon_1024x1024.png       <- Master PNG (uretilmeli)
      feature_1200x500.png     <- Google Play feature graphic (uretilmeli)
```

---

## 5. App Icon Gereksinimleri

### 5.1 Uretilmesi Gereken Dosyalar

```
assets/store/icons/icon_1024x1024.png     <- Master PNG — YOK, uretilmeli
assets/store/icons/feature_1200x500.png  <- Google Play feature graphic — YOK, uretilmeli
```

### 5.2 Mevcut (build icin yeterli)

```
uygulamalar/mobil/ios/Runner/Assets.xcassets/AppIcon.appiconset/   <- var
uygulamalar/mobil/android/app/src/main/res/mipmap-xxxhdpi/         <- var
uygulamalar/mobil/android/app/src/main/res/mipmap-anydpi-v33/      <- adaptive icon var
```

### 5.3 1024x1024 Master PNG Uretim Kurallari

- Alfa kanali olmamali (iOS App Store Connect reddeder — opaque)
- Kose yuvarlatma ekleme (store otomatik uygular)
- Renk uzayi: sRGB
- Yeedoy logosu merkeze hizalanmali
- Sade, minimal arka plan (koyu kirmizi #7F1D1D veya beyaz)
- Kontrast oran: WCAG AA (4.5:1 minimum)
- Font: Sora (varsa tipografi kullanimi)

### 5.4 Feature Graphic 1200x500 Tasarim Onerisi

```
Sol: Yeedoy logosu (300x300, dikey merkez)
Sag: Slogan metni
     - Baslik:    "Yeedoy: Topluluk Destekli Fiyat Takip"
     - Alt metin: "Menu fiyatlarini sen belirliyorsun"
Arka plan: gradient (#7F1D1D → koyu slate)
Font: Sora Bold (baslik), Sora Regular (alt metin)
```

---

## 6. Text Overlay Sablonu

Her screenshot'a Figma / Canva ile eklenecek baslik katmani:

```
Konum:     Ustte, telefon cercevesi icinde (ekran ust 20%)
Baslik:    Sora Bold, 28-32sp, #FFFFFF (veya #7F1D1D arka plana gore)
Alt metin: Sora Regular, 16-18sp, #FFFFFF cc
Padding:   24px tum taraflardan
Arka plan: Hafif seffaf siyah gradyan (basligin arkasinda)
```

Alternatif: Telefon cercevesi DISINDA, alttaki bant alanda metin. Bu yaklasim daha guvenlidir cunku ekran icerigini kapatmaz.

---

## 7. Cekimden Once — Emulator / Simulator Kurulumu

### 7.1 Android (Android Studio)

```bash
# Emulator olustur:
# Android Studio -> Device Manager -> Create Device
# Secim: Pixel 6, API 34 (Android 14), 1080x2400

# Calistir:
flutter run -d emulator-5554 -t lib/main_mobile.dart

# Screenshot al:
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png "C:/yeedoy/assets/store/android/screenshots/android_01_discovery_list.png"
```

### 7.2 iOS (Xcode Simulator)

```bash
# Simulator ac:
# Xcode -> Open Simulator -> iPhone 15 Plus

# Calistir:
flutter run -d "iPhone 15 Plus" -t lib/main_mobile.dart

# Screenshot al:
xcrun simctl io booted screenshot "assets/store/ios/screenshots/ios_01_discovery_list.png"
```

### 7.3 Statusbar Temizleme (iOS Simulator)

```bash
# iOS simulator'da "Status Bar Override" kullan:
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4 \
  --cellularMode active
```

### 7.4 Statusbar Temizleme (Android Emulator)

Android emulator, AVD Manager uzerinden "System" ayarlarinda statusbar'i temizleyebilir. Ya da `adb shell am broadcast` komutu ile demo mode aktif edilir:

```bash
# Demo mode ac:
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4

# Demo mode kapat (cekimden sonra):
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

---

## 8. Mevcut Eksikler Ozeti

| Dosya / Asset | Durum | Oncelik |
|---|---|---|
| `assets/store/icons/icon_1024x1024.png` | Yok — uretilmeli | YUKSEK |
| `assets/store/icons/feature_1200x500.png` | Yok — uretilmeli | ORTA |
| 8x Android screenshot | Yok — cekilmeli | YUKSEK |
| 8x iOS screenshot (6.5") | Yok — cekilmeli | YUKSEK |
| 8x iOS screenshot (5.5") | Yok — opsiyonel | DUSUK |
| Demo isletme secimi (sabit slug) | Belirsiz | YUKSEK |
| Text overlay sablonu (Figma) | Yok | ORTA |
| Clean statusbar setup script | Yukarida taslak var | ORTA |

---

## 9. Ilgili Dokumanlar

| Belge | Icerik |
|---|---|
| `docs/store-assets-release-plan.md` | Release plani, screenshot specs, release notes sablonu |
| `docs/store_listing.md` | ASO copy (TR + EN), anahtar kelimeler |
| `docs/store-data-safety-iarc.md` | Data Safety + IARC taslak |
| `docs/mobile-release-readiness.md` | Tam release checklist |

---

**Versiyon:** 1.0
**Hazirlayan:** Frontend Developer
**Durum:** Aktif rehber — assetler eksik, yukardaki adimlarla tamamlanmali
