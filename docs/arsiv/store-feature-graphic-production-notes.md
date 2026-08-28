# Feature Graphic Uretim Notlari

> **Tarih:** 2026-06-05
> **Durum:** 1200x500 PNG uretildi

---

## Uretilen Dosya

| Dosya | Boyut | Mod | Hedef |
|---|---|---|---|
| `store-assets/feature/yeedoy-feature-graphic-1200x500.png` | 1200x500 | RGB (alfa yok) | Google Play feature graphic |

---

## Tasarim Kararlari

**Arka plan:** Sag'a dogru hafif gradient — #7F1D1D → daha acik kirmizi

**Sol bolum:**
- Yeedoy app icon (store-assets/icon/yeedoy-master-icon-1024.png kaynagindan)
- 260x260 boyutunda, beyaz piksellerden saydam yapildi, marka rengi uzerine paste edildi

**Sag bolum (x=430'dan):**
- Baslik: "Yeedoy" — Sora Bold 52px, beyaz
- Alt baslik: "Restoran fiyatlarini / toplulukla kesfet" — Sora SemiBold 36px, beyaz
- Aciklama: "Menu fiyatlari - Harita kesfi - QR menu" — Sora Regular 28px, acik pembe (#FFDDDD)

**Secilen slogan:** "Restoran fiyatlarini toplulukla kesfet"

---

## Kullanilan Kaynaklar

| Kaynak | Dosya |
|---|---|
| App icon | `store-assets/icon/yeedoy-master-icon-1024.png` |
| Sora Bold | `deploy/admin/assets/assets/fonts/Sora-Bold.ttf` |
| Sora SemiBold | `deploy/admin/assets/assets/fonts/Sora-SemiBold.ttf` |
| Sora Regular | `deploy/admin/assets/assets/fonts/Sora-Regular.ttf` |

---

## Uretim Kodu

```python
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1200, 500
img = Image.new('RGB', (W, H), (127, 29, 29))
draw = ImageDraw.Draw(img)

# Gradient arka plan
for x in range(W):
    t = x / W
    r = int(127 + t * 40)
    g = int(29 + t * 10)
    b = int(29 + t * 10)
    draw.line([(x, 0), (x, H)], fill=(r, g, b))

# Sol icon
icon_src = Image.open('store-assets/icon/yeedoy-master-icon-1024.png').convert('RGBA')
# Beyaz pikselleri saydam yap
data = icon_src.getdata()
new_data = [(255,255,255,0) if (i[0]>230 and i[1]>230 and i[2]>230) else i for i in data]
icon_src.putdata(new_data)
icon_resized = icon_src.resize((260, 260), Image.LANCZOS)
img.paste(icon_resized, (80, 120), icon_resized)

# Fontlar
sora_bold = ImageFont.truetype('Sora-Bold.ttf', 52)
sora_semibold = ImageFont.truetype('Sora-SemiBold.ttf', 36)
sora_regular = ImageFont.truetype('Sora-Regular.ttf', 28)

draw.text((430, 120), 'Yeedoy', font=sora_bold, fill=(255,255,255))
draw.text((430, 200), 'Restoran fiyatlarini', font=sora_semibold, fill=(255,255,255))
draw.text((430, 248), 'toplulukla kesfet', font=sora_semibold, fill=(255,255,255))
draw.text((430, 330), 'Menu fiyatlari - Harita kesfi - QR menu', font=sora_regular, fill=(255,220,220))

img.save('yeedoy-feature-graphic-1200x500.png', 'PNG', optimize=True)
```

---

## Kalite Kontrol

| Kontrol | Sonuc |
|---|---|
| Boyut | 1200x500 px |
| Renk modu | RGB (alfa yok) |
| Dosya boyutu | 37 KB |
| Metin okunabilir mi? | Kontrol edilmeli (gorsel inceleme) |
| Logo kesiliyor mu? | Hayir |
| Store policy uyumu | Abartili iddia yok |

---

## Dikkat / Iyilestirme Firsatlari

- Metinde Turkce karakter (i, o, u) yerine Latin karakter kullanildi — font encoding sorun cikarmasin diye kasitli.
  Eger Turkce karakter gerekiyorsa: `draw.text(..., 'Restoranları', ...)` kullan, Sora destekliyor.
- Gradient cok ince, sade gorunumlu. Istege gore farkli renk tonu denenebilir.
- Sol ikona "beyaz silme" yontemi kullaniyor — ikon icindeki beyaz alanlari da siliyor olabilir;
  dogrudan SVG kaynaktan render etmek daha temiz sonuc verir.

---

## Sonraki Adimlar

| # | Is | Oncelik |
|---|---|---|
| 1 | Feature graphic'i goruntuleyip onayla | KRITIK |
| 2 | Turkce karakter gerekiyorsa metni guncelle | ORTA |
| 3 | Google Play Console'a yukle | KRITIK |
| 4 | Android/iOS screenshot setleri | YUKSEK |

---

## Ilgili Dokumanlar

- `docs/store-icon-feature-graphic-brief.md`
- `docs/store-icon-production-notes.md`
- `docs/store-screenshot-capture-guide.md`
