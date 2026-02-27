# QR Menu Sistemi (Gercek Uygulama)

## 1) QR Uretimi

- Dashboard route: `/dashboard/businesses/[id]/qr`
- UI: `QrGenerator`
- API: `POST /api/qr`

Kanit:
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/src/ui/sections/qr-generator.tsx`
- `apps/web_next/app/api/qr/route.tsx`

## 2) API Davranisi

`/api/qr` akisi:

1. Isletmeyi yukler.
2. Hedef URL uretir: `/b/{slugOrId}?lang={locale}`
3. QR'yi `svg` / `png` / `poster_pdf` formatinda olusturur.
4. `menu-assets` bucket'ina yukler.
5. Public URL doner.

Kanit:
- `apps/web_next/app/api/qr/route.tsx`

## 3) Kisa Route (QR Redirect)

- Route: `/q/[code]`
- `businesses.slug == code` kontrolu ile `/b/{slug}?lang=tr` redirect.
- Eslesme yoksa `notFound()`.

Kanit:
- `apps/web_next/app/q/[code]/page.tsx`

Not:
- Ayrik bir short-link tablosu bulunmadi; route slug lookup yapiyor.

## 4) Public Menu Render

- Route: `/b/[slug]`
- `businesses`, `menu_categories`, `menu_items`, `menu_translations` cekilip `PublicMenuClient` ile render ediliyor.

Kanit:
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/src/ui/sections/public-menu-client.tsx`

## 5) Mobil QR Entegrasyonu

Mobilde QR icerigi parse edilerek dahili route'a cevriliyor:

- `/menu/{menuId}`
- `/b/{businessId}`
- `/b/{businessId}/menu/{menuId}`

Eslesmeyen durumda QR gorseli review icin gecici upload ediliyor.

Kanit:
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`

## 6) Aciklar

- Web public menude fiyat confidence/history UI katmani yok.
- Kisa kod sistemi slug'a bagli; ayrik kod yasam dongusu yok.

Kanit:
- `apps/web_next/src/ui/sections/public-menu-client.tsx`
- `apps/web_next/app/q/[code]/page.tsx`
