# Store Icon Uretim Notlari

> **Tarih:** 2026-06-05
> **Durum:** 1024x1024 ve 512x512 uretildi

---

## Kalite Kontrol Sonucu

### Mevcut `Icon-App-1024x1024@1x.png` (iOS AppIcon seti)

| Kontrol | Sonuc |
|---|---|
| Boyut | 1024x1024 px |
| Renk modu | RGBA (alfa kanali VAR) |
| Dosya boyutu | 58 KB |
| Store icin uygun? | **HAYIR** — App Store Connect alfa kanali reddeder |

**Sorun:** iOS build icin gecerli ama App Store Connect'e 1024x1024 olarak yuklenecek dosyanin alfa kanali olmamali.

### Mevcut `yeedoy-icon.png` (brand assets)

| Kontrol | Sonuc |
|---|---|
| Boyut | 821x834 px (kare degil) |
| Renk modu | RGBA |
| Dosya boyutu | 437 KB |
| Store icin uygun? | **HAYIR** — boyut uyumsuz |

---

## Uretilen Store-Grade Dosyalar

### Uretim Yontemi

Kaynak: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`

Python/Pillow ile:
1. RGBA -> RGB donusum (alfa kanali kaldirildi)
2. Beyaz arka plan (#FFFFFF) uzerinde flatten
3. PNG optimize kaydi

```python
from PIL import Image

src = Image.open('Icon-App-1024x1024@1x.png').convert('RGBA')
bg = Image.new('RGB', (1024, 1024), (255, 255, 255))
bg.paste(src, mask=src.split()[3])
bg.save('yeedoy-master-icon-1024.png', 'PNG', optimize=True)

bg512 = bg.resize((512, 512), Image.LANCZOS)
bg512.save('yeedoy-play-icon-512.png', 'PNG', optimize=True)
```

### Uretilen Dosyalar

| Dosya | Boyut | Mod | Kullanim |
|---|---|---|---|
| `store-assets/icon/yeedoy-master-icon-1024.png` | 1024x1024 | RGB (alfa yok) | App Store Connect + Play Store |
| `store-assets/icon/yeedoy-play-icon-512.png` | 512x512 | RGB (alfa yok) | Google Play high-res icon |

---

## Dikkat: Beyaz Arka Plan

Mevcut Yeedoy ikonu seffaf arka planlidir (RGBA). Bu PR'da **beyaz (#FFFFFF)** arka plan kullanildi.

Eger marka tercihi farkli bir arka plan rengi ise (ornegin #7F1D1D deep red):
```python
bg = Image.new('RGB', (1024, 1024), (127, 29, 29))  # #7F1D1D
```
komutuyla yeniden uretilmelidir.

---

## Araclar

| Arac | Durum |
|---|---|
| Python Pillow | Kullanildi |
| Inkscape | Yuklu degil |
| ImageMagick | Yuklu degil |

---

## Sonraki Adimlar

| # | Is | Durum |
|---|---|---|
| 1 | 1024x1024 App Store Connect'e yukle | Hazir |
| 2 | 512x512 Google Play high-res icon yukle | Hazir |
| 3 | Arka plan rengi onay (beyaz vs marka rengi) | Belirsiz |
| 4 | Feature graphic 1200x500 uret | Yapilmadi |
| 5 | App Store Connect ikonu dogrulama | Manuel |

---

## Ilgili Dokumantasyon

- `docs/store-icon-feature-graphic-brief.md` — uretim brief
- `docs/store-screenshot-capture-guide.md` — screenshot rehberi
- `docs/store-assets-release-plan.md` — release plani
