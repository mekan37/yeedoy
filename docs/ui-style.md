# UI Style Sistemi (Mobile -> Web)

Bu belge `apps/mobile_flutter/lib/app/theme` altindaki theme kaynaklarinin `apps/web_next` tarafina nasil tasindigini aciklar.

## Source of Truth

Mobile theme dosyalari:

- `apps/mobile_flutter/lib/app/theme/colors.dart`
- `apps/mobile_flutter/lib/app/theme/app_tokens.dart`
- `apps/mobile_flutter/lib/app/theme/app_typography.dart`
- `apps/mobile_flutter/lib/app/theme/app_theme.dart`

Web token yuzeyi:

- `apps/web_next/src/styles/tokens.css`
- `apps/web_next/tailwind.config.js`
- `apps/web_next/src/styles/globals.css`

Not:
- `packages/ui_tokens` artik `apps/web_next` icin aktif source-of-truth degildir.
- Web app kendi local `tokens.css` dosyasini kullanir; degerler mobile theme ile esitlenmistir.
- `apps/panel_flutter_web` ise ayni paleti Flutter `AppColors`, `AppTokens` ve `buildAppTheme()` uzerinden kullanir.

Panel token yuzeyi:

- `apps/panel_flutter_web/lib/app/theme/colors.dart`
- `apps/panel_flutter_web/lib/app/theme/app_tokens.dart`
- `apps/panel_flutter_web/lib/app/theme/app_theme.dart`

## Token Haritasi

### Renkler

Mobile `colors.dart` -> Web `tokens.css`

- `AppColors.primary` -> `--yd-color-primary`
- `AppColors.accent` -> `--yd-color-primary-strong`
- `AppColors.wine` -> `--yd-color-primary-deep`
- `AppColors.textPrimary` / `textSecondary` -> `--yd-color-text-strong`, `--yd-color-text`
- `AppColors.background` / `surface` -> `--yd-color-bg`, `--yd-color-card`
- `AppColors.border` -> `--yd-color-border`
- status renkleri -> `--yd-color-success`, `--yd-color-warning`, `--yd-color-danger`, `--yd-color-info`

### Spacing

Mobile `app_tokens.dart`

- `4, 8, 12, 16, 20, 24` -> `--yd-space-1` ... `--yd-space-6`

### Radius

Mobile `app_tokens.dart`

- `12, 16, 20, 24` -> `--yd-radius-sm`, `--yd-radius-md`, `--yd-radius-lg`, `--yd-radius-xl`

### Motion

Mobile `app_tokens.dart`

- `150ms`, `180ms`, `220ms` -> `--yd-duration-fast`, `--yd-duration-medium`, `--yd-duration-slow`

### Typography

Mobile `app_typography.dart`

- semantic baslik ve govde olcekleri -> `--yd-font-size-*`
- satir yukseklikleri -> `--yd-line-tight`, `--yd-line-snug`, `--yd-line-body`
- font ailesi webde `Sora` + fallback ile `--yd-font-family`

## Tailwind Kullanimi

`apps/web_next/tailwind.config.js` bu CSS variable setini su yuzeylere map eder:

- `colors`
- `spacing`
- `borderRadius`
- `boxShadow`
- `fontFamily`
- `fontSize`
- `transitionDuration`

Bu sayede componentler token isimleriyle yazilir:

- `bg-card`
- `text-textStrong`
- `shadow-yd2`
- `rounded-xl`

## Panel Kullanimi

`apps/panel_flutter_web` tarafinda ayni marka dili Flutter tema uzantilarina map edilir:

- `AppColors.primary / primarySoft / primaryStrong`
- `AppTokens.space*`
- `AppTokens.radius*`
- `FilledButtonTheme`, `OutlinedButtonTheme`, `CardTheme`

Bu sayede paneldeki `Dijital Menü & QR` butonlari ile `apps/web_next` QR Studio ayni renk, radius ve yuzey hissini paylasir.

## Tasarim Prensipleri

`apps/web_next` tarafinda tum sayfalarda ayni dil korunur:

- wine/red tonlu premium vurgu
- yumusak ama belirgin kart yuzeyleri
- buyuk radius ve yumusak shadow
- mobile-first spacing
- yuksek kontrastli basliklar
- sticky category bar, bottom-sheet item detail, guclu bos/error/loading yuzeyleri

## Sayfa Yuzeyleri

Bu token sistemi su yuzeylerde kullanilir:

- public menu hero
- template varyasyonlari (`minimal`, `bold`, `elegant`, `photo-heavy`, `dark-modern`)
- sticky category tabs
- search + filter kartlari
- menu item kartlari
- item detail sheet
- QR generator
- template thumbnail picker
- preview link / unsaved state / reset controls
- login gate
- not-found / error / loading ekranlari

Performans notu:

- `QR branding paneli` ve `menu item detail sheet` lazy split edilerek ilk route yuklemesinden ayrildi.
- Interaktif client surface'lerde `next/image` / `next/link` runtime maliyeti azaltildi; bu sayede `/m` ve `/qr` first load JS 147 kB'den 138 kB'ye indi.

## Neden Ayrik Local Tokens?

Sebep:

- Next public app'in tema surumu panel/mobil release'lerinden bagimsiz kontrol edilebilsin
- Source-of-truth map'i repoda gorunur ve denetlenebilir olsun
- `apps/web_next` deploy'u icin gereksiz package bagimliligi azaltilsin

## Template Sistemi

Public menu ve QR Studio artik ortak template registry kullanir:

- `apps/web_next/src/lib/templates/registry.ts`
- `apps/web_next/src/lib/templates/schema.ts`
- `apps/web_next/src/lib/presentation-view.ts`

Desteklenen template'ler:

- `minimal`
- `bold`
- `elegant`
- `photo-heavy`
- `dark-modern`

Kalici veri modeli:

- `public.business_menu_presentation_settings.template_key`
- `public.business_menu_presentation_settings.settings`

`settings` icindeki ana varyasyonlar:

- `backgroundMode`: `solid | gradient | image`
- `accentPreset`: `brand | slate | forest | amber | rose | custom`
- `headerLayout`: `left | centered`
- `cardStyle`: `compact | comfortable`
- `fontScale`: `normal | large`
- `showFeatured`, `showTags`, `showAllergens`, `showCurrencySymbol`, `showLastUpdated`

Override kurali:

- Public menu varsayilan template/dil bilgisini DB'den alir.
- `?theme=` ve `?lang=` query paramlari gecici override katmanidir.
- Gecersiz theme degeri canonical URL'de normalize edilir.

## Branding Gorselleri

QR Studio branding gorsellerini su kaynaklardan kullanir:

1. `business_menu_presentation_settings.logo_url / cover_url / background_url`
2. `business_media`
3. `businesses.logo_url / cover_url`

Yukleme kontrati:

- Route: `POST /api/media/upload`
- Bucket: `menu-media`
- Path: `businesses/{businessId}/branding/{type}/{uuid}.{ext}`
- Mime: `image/jpeg`, `image/png`, `image/webp`
- Max: `5MB`

Cache ve guvenlik notu:

- Storage path'i business bazinda izoledir.
- Public render URL'leri `updated_at` bazli `?v=` param'i ile cache-bust edilir.
- `next/image remotePatterns` yalnizca site host'u ve Supabase host'u ile sinirlidir.
