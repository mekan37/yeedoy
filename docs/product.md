# Yeedoy Ürün Tanımı (Kaynak Doküman)

Bu doküman, yalnızca `C:\yeedoy` içindeki mevcut kod ve dosyalara dayanır.

## Yeedoy Nedir?

Yeedoy, tek bir ürün değil; aynı veri modelini kullanan çoklu istemci yapısıdır:

- Mobil tarafta topluluk odaklı keşif, fiyat doğrulama/öneri, favori, bildirim ve sosyal etkileşim akışları.
- Web tarafta işletme için dijital menü yönetimi ve QR menü yayınlama akışı.
- Admin/owner tarafta moderasyon, onay, operasyon ve işletme yönetim ekranları.

Bu nedenle sistem "sadece QR menü" değildir; kodda QR menü yanında fiyat şeffaflığı ve topluluk katkısı akışları da aktif olarak bulunur.

## Son Kullanıcı İçin Ne İfade Eder?

Mobil kullanıcı için uygulama; işletme keşfi, menü/fiyat görme, fiyat değişimi ve katkı akışlarını tek yerde sunar.

Kod kanıtları:

- Route ve ekranlar: `apps/mobile_flutter/lib/app/router.dart`
- Keşif: `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- İşletme detayı: `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- Menü: `apps/mobile_flutter/lib/features/menus/ui/menu_page.dart`
- Yorum ve değerlendirme: `apps/mobile_flutter/lib/features/reviews/ui/*`
- Favoriler: `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`
- Bildirimler: `apps/mobile_flutter/lib/features/notifications/ui/inbox_page.dart`
- Fiyat alarmı: `apps/mobile_flutter/lib/features/price_alerts/*`
- Topluluk/labs: `group_requests`, `taste_twin`, `heroes`, `gourmets` klasörleri

## İşletme İçin Ne İfade Eder?

İşletme tarafında odak, menü oluşturma/yönetim ve QR ile menüyü yayına alma akışıdır.

Kod kanıtları:

- İşletme dashboard: `apps/web_next/app/(dashboard)/dashboard/page.tsx`
- İşletme listesi/başvuru: `apps/web_next/app/(dashboard)/dashboard/businesses/page.tsx`
- Menü editörü: `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`
- QR üretici: `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- QR API: `apps/web_next/app/api/qr/route.tsx`
- İşletme başvurusu API: `apps/web_next/app/api/businesses/route.ts`

## Admin İçin Ne İfade Eder?

Admin yetki kontrolleri ve operasyon ekranları iki yerde görünür:

- Flutter panelde kapsamlı admin ekranları (`/admin/...`): `apps/panel_flutter_web/lib/app/router.dart`
- Next.js tarafında `/admin` route'u şu an placeholder içeriklidir: `apps/web_next/app/admin/page.tsx`

## Koda Göre Öne Çıkan Modüller

- Keşif, işletme, menü, menü öğesi, yorum, favori, profil, bildirim.
- Katkı ve fiyat doğrulama/öneri.
- Fiyat alarmı.
- Grup istekleri.
- Taste Twin / Heroes / Gourmets (labs/sosyal akışlar).
- QR menü paylaşımı ve QR varlık üretimi.
- Admin moderasyon ve owner operasyonu.

Ana kanıtlar:

- `apps/mobile_flutter/lib/app/router.dart`
- `apps/panel_flutter_web/lib/app/router.dart`
- `apps/web_next/app/**/*`
- `apps/web_next/app/api/**/*`

## Kısıtlar ve Net Durum

- `apps/web_next/app/owner/page.tsx` ve `apps/web_next/app/menu-builder/page.tsx` doğrudan `/dashboard/businesses` yönlendirmesi yapıyor; ayrı tam sayfa modülü değil.
- `apps/web_next/app/admin/page.tsx` yetki kontrolü içeriyor ama metin olarak "araçlar burada konumlanacak" seviyesinde.
- `qr_menu_next/` klasöründe kaynak kod değil, build/artifact (`.next`, `node_modules`) bulunuyor.

Kanıtlar:

- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
- `apps/web_next/app/admin/page.tsx`
- `qr_menu_next/.next`, `qr_menu_next/node_modules`
