# Karekod Menu Sistemi (Gercek Uygulama)

Bu dokuman QR Studio, short redirect ve public menu dagitim zincirinin tek teknik kaynagidir.

Su konular burada tutulmaz:

- uygulama sahipligi ve genel urun sinirlari
- detayli tablo veya RPC envanteri
- deploy, smoke veya incident adimlari
- UI token ve branding sisteminin tum tasarim detaylari

Tek kaynaklar:

- uygulama sinirlari: `docs/mimari-kurallari.md`
- veri modeli ve RPC envanteri: `docs/veri-modeli.md`
- deploy modeli: `docs/dagitim.md`
- smoke ve incident: `docs/operasyon-kilavuzu.md`

## 1) QR Uretimi

- Route: `/karekod/[businessId]`
- UI: `QrGeneratorClient`
- Veri yazimi: yalnizca `business_menu_presentation_settings`
- Erisim: owner/admin session + business yetkisi zorunlu
- Panelden varsayilan acilis: `/karekod/:businessId?lang=tr&theme=bold`

Kanit:
- `uygulamalar/web/uygulama/karekod/[businessId]/page.tsx`
- `uygulamalar/web/src/ui/bolumler/karekod-uretici.tsx`
- `uygulamalar/web/src/lib/karekod-erisimi.ts`

## 2) QR Sayfasi Davranisi

`/karekod/[businessId]` akisi:

1. Session yoksa `/giris?redirect=/karekod/{businessId}?lang=...&theme=...` yonlendirmesi yapilir.
2. Session varsa `can_manage_business_v1` ile business yetkisi dogrulanir.
3. Isletme ve menu verisini okur.
4. Canonical public link uretir: `/m/{publicSlugOrId}?lang={locale}&theme={brandMode}`
5. Deterministic short link uretir: `/kod/{code}?lang={locale}&theme={brandMode}`
6. Studio icinde `minimal | bold | elegant | photo-heavy | dark-modern` template'leri ve `tr | en` language switcher ile preview canli guncellenir.
7. `background mode`, `accent`, `header layout`, `card style`, `font scale` ve goster/gizle toggle'lari ayarlanir.
8. Logo / cover / background gorselleri yuklenebilir veya mevcut `business_media` / saved URL havuzundan secilebilir.
9. `Preview` linki uretilir: `/m/{publicSlugOrId}?theme=...&preview=1`
10. `Reset to Default` ile kayitli DB ayarlarina tek tusla donulebilir.
11. Kaydet butonu sadece `business_menu_presentation_settings` tablosina yazar.
12. Kayit sonrasi canonical public menu path'i ve `/karekod/{businessId}` route cache'i invalidate edilir; DB'deki yeni `template_key` / `default_lang` hemen gorunur.
13. QR gorselini istemci tarafinda PNG/SVG olarak uretir.
14. Kullaniciya indirme, public menu linki kopyalama ve preview linki kopyalama aksiyonlari sunar.

Kanit:
- `uygulamalar/web/uygulama/giris/page.tsx`
- `uygulamalar/web/uygulama/karekod/[businessId]/page.tsx`
- `uygulamalar/web/src/lib/karekod-erisimi.ts`
- `uygulamalar/web/src/lib/kisa-kod.ts`
- `uygulamalar/web/src/ui/bolumler/karekod-uretici.tsx`

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

## 3) Owner/Admin QR Akisi

- Owner route: `/sahip/karekod`
- Public QR preview route: `/karekod/[businessId]`
- Kaynak: `uygulamalar/web`
- Hedef: owner/admin kullanicisinin public menu ve kisa QR linklerini tek Next.js yuzeyinden uretmesi.

Kanit:
- `uygulamalar/web/uygulama/sahip/karekod/page.tsx`
- `uygulamalar/web/uygulama/karekod/[businessId]/page.tsx`
- `uygulamalar/web/src/ui/bolumler/karekod-uretici.tsx`
- `uygulamalar/web/src/lib/menu-baglantilari.ts`

## 4) Kisa Route (QR Redirect)

- Route: `/kod/[code]`
- Runtime: `edge`
- Kod `businessId`'den deterministic uretilir.
- Eslesen kod `/sunucu/izleme` uzerinden `page_view` eventi yollar.
- `source=qr_short_link` ve `meta.event_alias=qr_scanned` ile redirect kaynagi korunur.
- Event meta'sina redirect hazirlama suresi (`redirect_ms`) de yazilir.
- Ardindan public menu rotasina redirect eder; public slug varsa canonical `/m/{publicSlug}` adresinde sonlanir.

Kanit:
- `uygulamalar/web/uygulama/kod/[code]/route.ts`
- `uygulamalar/web/src/lib/kisa-kod.ts`

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
- `uygulamalar/web/uygulama/(public)/m/[slug]/page.tsx`
- `uygulamalar/web/uygulama/(public)/m/[slug]/c/[categoryId]/page.tsx`
- `uygulamalar/web/uygulama/(public)/m/[slug]/i/[itemId]/page.tsx`
- `uygulamalar/web/src/lib/veri/menu-read.ts`

Not:
- Canonical public route slug merkezlidir; teknik klasor yolu yine `uygulamalar/web/uygulama/(public)/m/[slug]/...` seklindedir.

## 6) Analytics

Toplanan event tipleri:

- `page_view`
- `category_view`
- `item_view`
- `item_click`

Davranis:

- Public eventler `/sunucu/izleme` uzerinden toplanir.
- IP saklanmaz.
- Rate limit middleware seviyesinde uygulanir.
- Panel devir oturumu da middleware rate limit altindadir.
- Kisa link redirect'i ayri tablo yazimi yapmaz; `page_view` + `source=qr_short_link` + `meta.event_alias=qr_scanned` semantigi kullanir.

Kanit:
- `uygulamalar/web/uygulama/sunucu/izleme/route.ts`
- `uygulamalar/web/middleware.ts`

## 7) Mobil QR Entegrasyonu

Mobilde QR icerigi parse edilerek dahili route'a cevriliyor:

- `/menu/{menuId}`
- `/isletme/{businessId}`
- `/isletme/{businessId}/menu/{menuId}`

Eslesmeyen durumda QR gorseli review icin gecici upload ediliyor.

Kanit:
- `uygulamalar/mobil/lib/features/katki/ui/katki_entry.dart`

## 8) Aciklar

- Kisa linkler icin ayrik tablo yok; kod `businessId` uzerinden deterministiktir.
- Panel disi dogrudan QR acilisinda owner login sayfasina yonlendirme kullanilir; login sonrasi ayni `/karekod/:businessId` rotasina geri donulur.
- Legacy `/isletme/[slug]` route'u sadece UUID gelirse `/m/[businessId]`'ye yonlenir.
- Paneldeki `Dijital Menü & QR` ve `Public Menü Linki` butonlari QR render etmez; yalnizca `uygulamalar/web` rotalarini acar.
- Upload route'u `POST /sunucu/medya/yukleme` ile calisir; kabul edilen mime tipleri `image/jpeg`, `image/png`, `image/webp`, max boyut `5MB` ve storage path'i `businesses/{businessId}/branding/{type}/{uuid}.{ext}` formatindadir.
- Storage object'leri uzun cache omru ile saklanir; public render tarafinda `updated_at` bazli `?v=` param'i ile cache bust uygulanir.
- Live smoke'ta owner upload + save zinciri route seviyesinde dogrulanmistir; yetkisiz kullanici hem upload hem settings write icin `403` alir.
- Canli bucket kesfi: public upload/read bucket `menu-media`, private bucket `menu-media-private`.

## Sinir Notu

Bu dosya QR/public menu akisina odaklanir; panel owner/admin operasyon ekranlari veya media upload adapter detaylari burada buyutulmaz.



