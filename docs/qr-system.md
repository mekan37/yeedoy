# QR Menu Sistemi (Gercek Uygulama)

Bu dokuman QR Studio, short redirect ve public menu dagitim zincirinin tek teknik kaynagidir.

Su konular burada tutulmaz:

- uygulama sahipligi ve genel urun sinirlari
- detayli tablo veya RPC envanteri
- deploy, smoke veya incident adimlari
- UI token ve branding sisteminin tum tasarim detaylari

Tek kaynaklar:

- uygulama sinirlari: `docs/apps.md`
- veri modeli ve RPC envanteri: `docs/data-model.md`
- deploy modeli: `docs/deploy.md`
- smoke ve incident: `docs/runbook.md`
- UI token ve branding dili: `docs/ui-style.md`

## 1) QR Uretimi

- Route: `/qr/[businessId]`
- UI: `QrGeneratorClient`
- Veri yazimi: yalnizca `business_menu_presentation_settings`
- Erisim: owner/admin session + business yetkisi zorunlu
- Panelden varsayilan acilis: `/qr/:businessId?lang=tr&theme=bold`

Kanit:
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/src/ui/sections/qr-generator.tsx`
- `apps/web_next/src/lib/qr-access.ts`

## 2) QR Sayfasi Davranisi

`/qr/[businessId]` akisi:

1. Session yoksa `/login?redirect=/qr/{businessId}?lang=...&theme=...` yonlendirmesi yapilir.
2. Session varsa `can_manage_business_v1` ile business yetkisi dogrulanir.
3. Isletme ve menu verisini okur.
4. Canonical public link uretir: `/m/{publicSlugOrId}?lang={locale}&theme={brandMode}`
5. Deterministic short link uretir: `/q/{code}?lang={locale}&theme={brandMode}`
6. Studio icinde `minimal | bold | elegant | photo-heavy | dark-modern` template'leri ve `tr | en` language switcher ile preview canli guncellenir.
7. `background mode`, `accent`, `header layout`, `card style`, `font scale` ve goster/gizle toggle'lari ayarlanir.
8. Logo / cover / background gorselleri yuklenebilir veya mevcut `business_media` / saved URL havuzundan secilebilir.
9. `Preview` linki uretilir: `/m/{publicSlugOrId}?theme=...&preview=1`
10. `Reset to Default` ile kayitli DB ayarlarina tek tusla donulebilir.
11. Kaydet butonu sadece `business_menu_presentation_settings` tablosina yazar.
12. Kayit sonrasi canonical public menu path'i ve `/qr/{businessId}` route cache'i invalidate edilir; DB'deki yeni `template_key` / `default_lang` hemen gorunur.
13. QR gorselini istemci tarafinda PNG/SVG olarak uretir.
14. Kullaniciya indirme, public menu linki kopyalama ve preview linki kopyalama aksiyonlari sunar.

Kanit:
- `apps/web_next/app/login/page.tsx`
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/src/lib/qr-access.ts`
- `apps/web_next/src/lib/short-code.ts`
- `apps/web_next/src/ui/sections/qr-generator.tsx`

Kalici ayar tablosu:

- `public.business_menu_presentation_settings`
- Alanlar:
  - `business_id`
  - `default_lang`
  - `template_key`
  - `settings jsonb`
  - `logo_url`
  - `cover_url`
  - `background_url`
  - `created_at`
  - `updated_at`

RLS:

- `SELECT`: public read
- `INSERT/UPDATE/DELETE`: `authenticated` + `can_manage_business_v1(business_id)`

## 3) Panel Session Handoff

- Route: `POST /auth/panel-handoff`
- Kaynak: `apps/panel_flutter_web`
- Tasinan veri: `access_token`, `refresh_token`, `business_id`, `lang`, `theme`
- Hedef: Next SSR auth cookie yazimi ve `/qr/[businessId]?lang=...&theme=...` yonlendirmesi

Kanit:
- `apps/web_next/app/auth/panel-handoff/route.ts`
- `apps/panel_flutter_web/lib/core/web/web_utils_web.dart`
- `apps/panel_flutter_web/lib/core/navigation/public_menu_url.dart`
- `apps/panel_flutter_web/lib/features/owner_businesses/ui/owner_businesses_page.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/admin_businesses_page.dart`

## 4) Kisa Route (QR Redirect)

- Route: `/q/[code]`
- Runtime: `edge`
- Kod `businessId`'den deterministic uretilir.
- Eslesen kod `/api/track` uzerinden `page_view` eventi yollar.
- `source=qr_short_link` ve `meta.event_alias=qr_scanned` ile redirect kaynagi korunur.
- Event meta'sina redirect hazirlama suresi (`redirect_ms`) de yazilir.
- Ardindan public menu rotasina redirect eder; public slug varsa canonical `/m/{publicSlug}` adresinde sonlanir.

Kanit:
- `apps/web_next/app/q/[code]/route.ts`
- `apps/web_next/src/lib/short-code.ts`

## 5) Public Menu Render

- Ana route: `/m/[publicSlugOrId]`
- Kategori route: `/m/[publicSlugOrId]/c/[categoryId]`
- Urun route: `/m/[publicSlugOrId]/i/[itemId]`

Okunan temel kaynaklar:
- `businesses`
- `business_menu_presentation_settings`
- `menus`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `menu_translations`
- `business_media`

Sunum davranisi:

- Varsayilan `lang` ve `theme` DB'den okunur.
- `?lang=` ve `?theme=` parametreleri varsa override eder.
- `?preview=1` varsa route preview modunda render olur; DB yazimi yapmaz.
- Gecersiz `theme` normalize edilerek canonical URL temizlenir.
- UUID veya legacy slug path'i ile gelen istekler canonical `public_slug` path'ine redirect edilir.
- Logo / cover / background fallback zinciri:
  1. `business_menu_presentation_settings`
  2. `business_media`
  3. `businesses.logo_url` / `businesses.cover_url`

Kanit:
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/c/[categoryId]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/i/[itemId]/page.tsx`
- `apps/web_next/src/lib/db/menu-read.ts`

Not:
- Canonical public route slug merkezlidir; teknik klasor yolu yine `apps/web_next/app/(public)/m/[slug]/...` seklindedir.

## 6) Analytics

Toplanan event tipleri:

- `page_view`
- `category_view`
- `item_view`
- `item_click`

Davranis:

- Public eventler `/api/track` uzerinden toplanir.
- IP saklanmaz.
- Rate limit middleware seviyesinde uygulanir.
- Panel session handoff da middleware rate limit altindadir.
- Kisa link redirect'i ayri tablo yazimi yapmaz; `page_view` + `source=qr_short_link` + `meta.event_alias=qr_scanned` semantigi kullanir.

Kanit:
- `apps/web_next/app/api/track/route.ts`
- `apps/web_next/middleware.ts`

## 7) Mobil QR Entegrasyonu

Mobilde QR icerigi parse edilerek dahili route'a cevriliyor:

- `/menu/{menuId}`
- `/b/{businessId}`
- `/b/{businessId}/menu/{menuId}`

Eslesmeyen durumda QR gorseli review icin gecici upload ediliyor.

Kanit:
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`

## 8) Aciklar

- Kisa linkler icin ayrik tablo yok; kod `businessId` uzerinden deterministiktir.
- Panel disi dogrudan QR acilisinda owner login sayfasina yonlendirme kullanilir; login sonrasi ayni `/qr/:businessId` rotasina geri donulur.
- Legacy `/b/[slug]` route'u sadece UUID gelirse `/m/[businessId]`'ye yonlenir.
- Paneldeki `Dijital Menü & QR` ve `Public Menü Linki` butonlari QR render etmez; yalnizca `apps/web_next` rotalarini acar.
- Upload route'u `POST /api/media/upload` ile calisir; kabul edilen mime tipleri `image/jpeg`, `image/png`, `image/webp`, max boyut `5MB` ve storage path'i `businesses/{businessId}/branding/{type}/{uuid}.{ext}` formatindadir.
- Storage object'leri uzun cache omru ile saklanir; public render tarafinda `updated_at` bazli `?v=` param'i ile cache bust uygulanir.
- Live smoke'ta owner upload + save zinciri route seviyesinde dogrulanmistir; yetkisiz kullanici hem upload hem settings write icin `403` alir.
- Canli bucket kesfi: public upload/read bucket `menu-media`, private bucket `menu-media-private`.

## Sinir Notu

Bu dosya QR/public menu akisina odaklanir; panel owner/admin operasyon ekranlari veya media upload adapter detaylari burada buyutulmaz.
