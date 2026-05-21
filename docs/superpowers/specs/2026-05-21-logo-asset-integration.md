# Logo Asset Entegrasyonu

**Tarih:** 2026-05-21  
**Durum:** Onaylandı

## Özet

Yeedoy projesinde logo asset dosyaları eksik veya kullanılmıyor. Bu spec, yeni logo dosyalarının hem web hem Flutter tarafına entegre edilmesini tanımlar.

## Mevcut Sorunlar

1. `uygulamalar/web/app/layout.tsx` → `/favicon.svg` referansı var, dosya **mevcut değil**
2. `packages/shared_ui_components/lib/src/brand_assets.dart` → 5 asset yolu tanımlı, klasör **boş**
3. Büyük SVG'ler (`yeedoy_y_logo.svg`, `yeedoy_wordmark_logo.svg`) ~500KB — üretim için uygun değil

## Kaynak Dosyalar

`C:\Users\Mustafa\Downloads\yeedoy_logo_assets\` içinden kullanılacaklar:
- `yeedoy_y_logo_vector.svg` — küçük, temiz vektör Y markası (`#7F1D1D` + `#DC2626`)
- `yeedoy_wordmark_logo_vector.svg` — küçük, temiz vektör wordmark
- `yeedoy_y_logo_transparent.png` — şeffaf PNG Y markası
- `yeedoy_wordmark_logo_transparent.png` — şeffaf PNG wordmark

Kullanılmayacaklar: `yeedoy_y_logo.svg`, `yeedoy_wordmark_logo.svg` (~500KB, üretim için fazla büyük)

## Renk Uyumu

Vector SVG'ler `#7F1D1D` (primary) ve `#DC2626` (primary-strong) kullanıyor — proje token'larıyla birebir örtüşüyor.

---

## Web Değişiklikleri

### Kopyalanacak Dosyalar → `uygulamalar/web/public/`

| Kaynak | Hedef |
|---|---|
| `yeedoy_y_logo_vector.svg` | `public/favicon.svg` |
| `yeedoy_y_logo_vector.svg` | `public/logos/yeedoy-mark.svg` |
| `yeedoy_wordmark_logo_vector.svg` | `public/logos/yeedoy-wordmark.svg` |
| `yeedoy_y_logo_transparent.png` | `public/logos/yeedoy-mark.png` |
| `yeedoy_wordmark_logo_transparent.png` | `public/logos/yeedoy-wordmark.png` |

### Değiştirilmeyecekler

- `src/ui/marka/yeedoy-logo.tsx` — gradyanlı inline SVG bileşeni korunur
- `app/layout.tsx` — zaten `/favicon.svg` referansı var, değişiklik gerekmez

---

## Flutter Değişiklikleri

### Kopyalanacak Dosyalar → `packages/shared_ui_components/assets/brand/`

| Kaynak | Hedef | BrandAssets sabiti |
|---|---|---|
| `yeedoy_y_logo_vector.svg` | `assets/brand/yeedoy-icon.svg` | `BrandAssets.iconSvg` |
| `yeedoy_y_logo_vector.svg` | `assets/brand/yeedoy-mark-transparent.svg` | `BrandAssets.markSvg` |
| `yeedoy_wordmark_logo_vector.svg` | `assets/brand/yeedoy-wordmark.svg` | `BrandAssets.wordmarkSvg` |
| `yeedoy_y_logo_transparent.png` | `assets/brand/yeedoy-icon.png` | `BrandAssets.logo` |
| `yeedoy_y_logo_transparent.png` | `assets/brand/yeedoy-mark-transparent.png` | `BrandAssets.mark` |

### pubspec.yaml Güncellemesi

`packages/shared_ui_components/pubspec.yaml` → `flutter.assets` bölümü eklenir:

```yaml
flutter:
  assets:
    - assets/brand/yeedoy-icon.svg
    - assets/brand/yeedoy-mark-transparent.svg
    - assets/brand/yeedoy-wordmark.svg
    - assets/brand/yeedoy-icon.png
    - assets/brand/yeedoy-mark-transparent.png
```

### Değiştirilmeyecekler

- `packages/shared_ui_components/lib/src/yeedoy_logo.dart` — CustomPaint bileşeni korunur
- `packages/shared_ui_components/lib/src/brand_assets.dart` — sabit yollar zaten doğru
- `uygulamalar/mobil/lib/uygulama/marka/marka_bilesenleri.dart` — değişiklik gerekmez

---

## Test Kriterleri

- `http://localhost:3000/favicon.svg` → Y marka SVG dönmeli
- `http://localhost:3000/logos/yeedoy-mark.svg` → Y marka SVG dönmeli
- `http://localhost:3000/logos/yeedoy-wordmark.svg` → wordmark SVG dönmeli
- Flutter: `BrandAssets.iconSvg` yolu üzerinden asset yüklenebilmeli
- Flutter: `flutter analyze` hata vermemeli
