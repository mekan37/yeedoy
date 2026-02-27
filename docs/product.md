# Yeedoy Urun Tanimi (Kaynak Dokuman)

Bu dokuman sadece `C:\yeedoy` kod tabanina dayanir.

## Yeedoy Nedir?

Yeedoy, restoran/kafe menu bilgisini tek basina gosteren bir QR cozumunden daha fazlasidir. Kod tabaninda uc eksen birlikte calisir:

1. Canli menu dagitimi (web public + QR)
2. Fiyat dogrulama ve degisim takibi (ozellikle mobil)
3. Topluluk katkisi ve moderasyon (mobil + admin panel)

Bu nedenle urun tanimi kod seviyesinde su sekildedir:

Yeedoy, menu/fiyat bilgisini topluluk ve dogrulama katmani ile seffaflastiran, QR ile erisilebilir dijital kesif platformudur.

## Son Kullaniciya Etkisi (Kodda Olan)

- Isletme kesfi, sehir/ilce bazli filtreleme, trend akislar
- Menu item bazinda fiyat, dogrulama, confidence ve gecmis gorunumu
- Fiyat bildirme/duzeltme ve katkida bulunma akislari
- Favori/kolleksiyon/paylasim, profil ve bildirimler

Kanit:
- `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`
- `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`
- `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart`

## Isletmeye Etkisi (Kodda Olan)

- Isletme dashboard
- Menu editor
- QR varlik uretimi (SVG/PNG/PDF) ve paylasim

Kanit:
- `apps/web_next/app/(dashboard)/dashboard/page.tsx`
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/app/api/qr/route.tsx`

## Admin/Operasyon Etkisi (Kodda Olan)

- Rapor, claim, suggestion, sponsorship, verified, audit gibi ekranlar
- Fiyat oneri moderasyonu

Kanit:
- `apps/panel_flutter_web/lib/app_admin.dart`
- `apps/panel_flutter_web/lib/src/features/admin/ui/*`

## Kritik Not

Vizyon uyumu detaylari ve aciklar icin ana rapor:
- `docs/vision_status.md`
