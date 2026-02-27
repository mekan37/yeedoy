# QR Menü Sistemi (Gerçek Implementasyon)

Bu doküman yalnızca mevcut kodu açıklar.

## 1) QR Varlık Üretimi (Owner Dashboard)

Akış:

1. Kullanıcı `dashboard/businesses/[id]/qr` sayfasına gider.
2. UI, `QrGenerator` bileşeni ile `/api/qr` endpoint'ini çağırır.
3. API, QR içeriğini üretir (SVG/PNG/PDF) ve `menu-assets` storage bucket'ına yükler.
4. API public URL döner; UI dosyayı açar/indirir.

Kanıt:

- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/src/ui/sections/qr-generator.tsx`
- `apps/web_next/app/api/qr/route.tsx`

## 2) QR İçeriği ve Hedef URL

`/api/qr` içindeki hedef URL üretimi:

- `target = {NEXT_PUBLIC_APP_URL}/b/{slugOrId}?lang={locale}`
- `slug` varsa slug, yoksa `business_id` kullanılır.

Kanıt:

- `apps/web_next/app/api/qr/route.tsx`

## 3) Kısa Link Route'u

`/q/[code]` sayfası:

- `businesses.slug == code` kontrolü yapar.
- Eşleşme varsa `/b/{slug}?lang=tr` yönlendirmesi yapar.
- Yoksa `notFound()`.

Kanıt:

- `apps/web_next/app/q/[code]/page.tsx`

Not:

- Bu route'ta "code -> ayrı kısa link tablosu" bulunmuyor; doğrudan `businesses.slug` lookup kullanılıyor.

## 4) Public Menü Render

`/b/[slug]` sayfası:

- `businesses` tablosundan aktif işletmeyi alır.
- `menu_categories`, `menu_items`, `menu_translations` verisini çeker.
- `PublicMenuClient` ile menüyü render eder.

Kanıt:

- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/src/ui/sections/public-menu-client.tsx`

## 5) Mobilde QR Okuma ile Dahili Route Çözümü

Mobil katkı akışında QR içeriği okunur ve dahili route'a çevrilir:

- `/menu/{menuId}`
- `/b/{businessId}`
- `/b/{businessId}/menu/{menuId}`

Eşleşmezse QR görseli "review" için yüklenir.

Kanıt:

- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`

## 6) Menü Linki Telemetri/Check-in

Mobil `PublicMenuSharePage` içinde:

- `src=qr` ise `qr_scanned` analitik olayı loglanır.
- Aynı durumda `log_checkin_v1` RPC çağrısı yapılır.

Kanıt:

- `apps/mobile_flutter/lib/features/menus/ui/public_menu_share_page.dart`

## 7) Şu Anki Kapsam Dışı / Bulunamayanlar

- Ayrı bir "short_links" tablosu veya kod üretip saklayan DB yapısı bulunamadı.
- Web tarafında `/menu/{menuId}` public route'u Next içinde yok; public route ana ekseni `/b/[slug]`.

Kanıt:

- `apps/web_next/app/q/[code]/page.tsx`
- `apps/web_next/app` route envanteri
