# App Icon ve Feature Graphic Uretim Briefi

> **Hazirlanma:** 2026-06-05
> **Durum:** Tasarim icin hazir — aksiyon bekliyor
> **Amac:** Store-grade icon ve feature graphic uretimi icin teknik ve tasarim rehberi

---

## 1. Mevcut Kaynak Durumu

| Asset | Dosya | Durum |
|---|---|---|
| SVG icon kaynagi | `uygulamalar/mobil/assets/brand/yeedoy-icon.svg` | Mevcut |
| SVG mark (transparent) | `uygulamalar/mobil/assets/brand/yeedoy-mark-transparent.svg` | Mevcut |
| SVG wordmark | `uygulamalar/mobil/assets/brand/yeedoy-wordmark.svg` | Mevcut |
| PNG icon (shared) | `packages/shared_ui_components/assets/brand/yeedoy-icon.svg` | Mevcut |
| 1024x1024 PNG | `uygulamalar/mobil/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | Mevcut — kalite dogrulanmali |
| Feature graphic | — | Yok |
| Store-grade master PNG | `store-assets/icon/` | Henuz yok |

**Oncelikli aksiyon:** `Icon-App-1024x1024@1x.png` dosyasini ac ve kalitesini kontrol et.
- Placeholder veya dusuk kaliteyse: SVG'den yeniden uret (asagidaki Bolum 2 talimatlari).
- Yuksek kaliteli ve opaque arka planliysa: App Store Connect'e dogrudan yuklenebilir.

---

## 2. 1024x1024 Master Icon Gereksinimleri (iOS App Store)

### 2.1 Teknik Spesifikasyon

```
Boyut:          1024 x 1024 px (kesin)
Format:         PNG
Renk uzayi:     sRGB
Alfa kanali:    OLMAMALI (iOS App Store Connect reddeder)
Arka plan:      Opaque — beyaz (#FFFFFF) veya marka rengi (#7F1D1D)
Kose yuvarlama: Manuel EKLEME — store otomatik uygular
Dosya hedefi:   store-assets/icon/yeedoy-master-icon-1024.png
```

### 2.2 Uretim Adimlari

**Secnek A — Inkscape (ucretsiz, CLI):**
```bash
inkscape \
  --export-filename=store-assets/icon/yeedoy-master-icon-1024.png \
  --export-width=1024 \
  --export-height=1024 \
  uygulamalar/mobil/assets/brand/yeedoy-icon.svg
```

**Secnek B — ImageMagick (mevcut alpha varsa flatten et):**
```bash
magick convert \
  -background "#7F1D1D" \
  -flatten \
  -resize 1024x1024 \
  uygulamalar/mobil/assets/brand/yeedoy-icon.svg \
  store-assets/icon/yeedoy-master-icon-1024.png
```

**Secnek C — Figma (manuel):**
1. Figma'da yeni frame ac: 1024x1024 px
2. `yeedoy-icon.svg` dosyasini import et
3. Arka plan: `#7F1D1D` (Fill, opaque)
4. Alfa kanalini kapat — Export ayarlari: PNG, 1x, no alpha
5. Export et: `yeedoy-master-icon-1024.png`

### 2.3 Kalite Kontrol Listesi

```
Uretim sonrasi kontroller:
  [ ] Boyut tam 1024x1024 px
  [ ] Alfa kanali yok (seffaf piksel yok)
  [ ] Renk uzayi sRGB
  [ ] Logo net ve kirlenmemis (anti-aliasing OK)
  [ ] Arka plan opaque (beyaz veya #7F1D1D)
  [ ] Dosya boyutu < 1 MB (tipik 100-500 KB)
```

---

## 3. 512x512 High-Res Icon (Google Play)

### 3.1 Teknik Spesifikasyon

```
Boyut:       512 x 512 px
Format:      PNG veya JPG (PNG tercih)
Alfa kanali: Izine bagli (PNG32 desteklenir)
Kose:        Google otomatik uygular — ekleme
Hedef:       store-assets/icon/yeedoy-play-icon-512.png
```

### 3.2 Uretim Komutu

```bash
inkscape \
  --export-filename=store-assets/icon/yeedoy-play-icon-512.png \
  --export-width=512 \
  --export-height=512 \
  uygulamalar/mobil/assets/brand/yeedoy-icon.svg
```

### 3.3 Mevcut Android Adaptive Icon Durumu

```
Foreground katmani:
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png
  (432x432 px — xxxhdpi icin dogru)

Adaptive XML:
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml (API 26+)

Raster fallback'ler:
  mipmap-hdpi / mipmap-xhdpi / mipmap-xxhdpi / mipmap-xxxhdpi
  ic_launcher.png + ic_launcher_round.png

Not: Raster fallback'ler API 25 ve altisi icin kullanilir (eski cihazlar).
512x512 high-res icon sadece Play Store listing icin gerekli — app bundle'dan ayri.
```

---

## 4. Feature Graphic Briefi (Google Play)

### 4.1 Teknik Spesifikasyon

```
Boyut:       1200 x 500 px (kesin)
Format:      PNG veya JPG (JPG onerilir — kucuk dosya boyutu)
Alfa kanali: Desteklenmiyor (JPG zaten opaque)
Kullanim:    Play Store listing en ust banner (opsiyonel ama ASO icin onemi yuksek)
Hedef:       store-assets/feature/yeedoy-feature-graphic-1200x500.png
```

### 4.2 Gorsel Yerlestirme

```
[<-- 480 px sol bolge -->][<-- 720 px sag bolge -->]

Sol bolge (% 40):
  - Yeedoy logosu (yeedoy-mark-transparent.svg veya yeedoy-icon.svg)
  - Logo boyutu: ~200x200 px, dikey center
  - Bosluk: Sol ve ustten 48 px padding

Sag bolge (% 60):
  - Ana slogan (buyuk, Sora Bold)
  - Ikincil aciklama (kucuk, Sora Regular)
  - Opsiyonel: kucuk bir telefon mockup illustration

Arka plan:
  Gradient: #7F1D1D -> #991B1B (soldan saga, hafif)
  Veya: #7F1D1D flat (daha sade)

Metin renkleri:
  Baslik: #FFFFFF (beyaz, Sora Bold 40-48 sp)
  Aciklama: rgba(255,255,255,0.80) (Sora Regular 20-24 sp)
```

### 4.3 Slogan Secenekleri

**Turkce (TR):**
```
A: "Yakınındaki fiyatları keşfet"
B: "Menü fiyatları, şeffaf"
C: "Restoranları topluluğunla keşfet"
D: "Topluluk destekli fiyat takip"
```

**Ingilizce (EN):**
```
A: "Discover prices near you"
B: "Menu prices, transparent"
C: "Community-driven restaurant discovery"
D: "Track restaurant prices together"
```

Oneri: Play Store locale'e gore dogru dili secin. TR pazar icin A veya D.

### 4.4 Icerik Kisitlamalari (Store Policy)

```
Yasaklananlar:
  - Markadan bagimsiz gercek kisi fotograflari
  - "1 numarali", "#1 uygulama" ifadeleri (ranking claim)
  - Abartili garantiler ("hic hata yok", "100% dogru")
  - Yaniltici fiyat bilgileri

Izin verilenler:
  - Uygulama UI ekran gorselleri
  - Stilize illustrasyonlar
  - Marka logo ve wordmark
  - Slogan (gercekci, dogrulanabilir)
```

---

## 5. AI Image Generation Promptlari

Figma veya tasarimci yoksa AI gorsel uretimi icin hazir promptlar:

### Prompt 1 — Master App Icon

```
Minimalist app icon for "Yeedoy", a Turkish restaurant price discovery app.
Deep red background (#7F1D1D), white stylized letter Y or fork/price-tag symbol.
Clean, modern, flat design. No text inside the icon. 1024x1024 pixels.
No rounded corners (will be applied by the store automatically).
Sora font influence, professional and trustworthy aesthetic.
Simple enough to be recognizable at 48x48 px.
```

### Prompt 2 — Feature Graphic

```
Google Play Store feature graphic, 1200x500 pixels.
Deep red gradient background (#7F1D1D to #991B1B, left to right).
Left third: Yeedoy app logo (white, minimal).
Right two-thirds: Clean smartphone illustration showing a restaurant menu with
price tags and star ratings. White headline text "Yakınındaki fiyatları keşfet"
(Turkish: "Discover prices near you"), Sora Bold font.
Modern, minimal, professional. Turkish market, warm but clean aesthetic.
No people photos, no stock photography.
```

### Prompt 3 — Minimal Alternate Icon

```
Minimalist app icon alternative for a restaurant app.
White background, deep red (#7F1D1D) abstract fork + price-tag combined icon mark.
Premium, modern restaurant app aesthetic. 1024x1024 pixels.
Clean vector style. Suitable for both light and dark OS themes.
High contrast, simple geometry.
```

---

## 6. Dizin Yapisi ve Isimlendirme Standardi

```
store-assets/
  icon/
    yeedoy-master-icon-1024.png    <- iOS App Store + kayit
    yeedoy-play-icon-512.png       <- Google Play high-res icon
    yeedoy-icon-review.png         <- Boyut onizleme (side-by-side, opsiyonel)
  feature/
    yeedoy-feature-graphic-1200x500.png
  screenshots/
    android/
      01-discovery.png
      02-map.png
      ...
    ios/
      01-discovery.png
      02-map.png
      ...
```

### .gitignore Onerisi

Binary PNG store assetleri repo'ya commit edilmemeli — buyuk dosyalar git gecmisini sikilastirir.

```gitignore
# store-assets/ dizini — Git LFS veya harici depolama kullan
store-assets/

# Sadece SVG kaynaklari repo'da kalsin:
# uygulamalar/mobil/assets/brand/*.svg  <- zaten tracked
```

SVG kaynaklari (`assets/brand/`) zaten repo'da takip ediliyor ve uretimlerin kaynagi olarak yeterli.

---

## 7. Aksiyon Listesi

| # | Aksiyon | Oncelik | Araç | Tahmini Sure |
|---|---|---|---|---|
| 1 | `Icon-App-1024x1024@1x.png` kalite kontrol | Kritik | Gorsel inceleme | 5 dakika |
| 2 | SVG'den 1024x1024 store-grade PNG uret | Yuksek | Inkscape / ImageMagick | 30 dakika |
| 3 | Google Play 512x512 high-res icon uret | Yuksek | SVG export | 15 dakika |
| 4 | Feature graphic 1200x500 tasarla | Orta | Figma / Canva | 2-4 saat |
| 5 | `store-assets/` dizinini `.gitignore`'a ekle | Dusuk | Metin editoru | 5 dakika |
| 6 | Uretilen assetleri Play Console + App Store Connect'e yukle | Yuksek | Tarayici | 30 dakika |

---

## 8. Ilgili Dokumanlar

- `docs/store-assets-release-plan.md` — Tam release plan, icon + screenshot + beta akisi
- `docs/store-screenshot-capture-guide.md` — Screenshot cekme rehberi
- `docs/store_listing.md` — ASO copy (TR + EN)
- `docs/store-data-safety-iarc.md` — Data Safety & IARC taslak

---

**Versiyon:** 1.0
**Hazirlanma Tarihi:** 2026-06-05
**Hazırlayan:** Frontend Developer
**Durum:** Tasarim ekibine aktarilmaya hazir
