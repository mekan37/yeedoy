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
- Skor dili iki ana katmana indirgenmistir: `topluluk guveni` (kullanici guveni) ve `veri guveni` (menu/fiyat guveni)

Kanit:
- `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`
- `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`
- `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart`

## Isletmeye Etkisi (Kodda Olan)

- Public menu linki uretme
- QR olusturma, PNG/SVG indirme, link kopyalama
- SEO ve paylasim icin tekil public menu sayfasi

Kanit:
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/src/ui/sections/qr-generator.tsx`
- `apps/web_next/app/(public)/m/[slug]/page.tsx`

Not:
- Semantik public route `/m/[businessId]` olsa da mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` olarak kalir.
- Owner/admin CRUD ekranlari `apps/web_next` icinde tutulmaz.
- Isletme yonetimi ve menu yazma akislarinin sahibi `apps/panel_flutter_web` uygulamasidir.
- Uygulama sinirlari ve teknik sahiplik icin tek kaynak `docs/apps.md` dosyasidir.

## Admin/Operasyon Etkisi (Kodda Olan)

- Rapor, claim, suggestion, sponsorship, verified, audit gibi ekranlar
- Fiyat oneri moderasyonu

Kanit:
- `apps/panel_flutter_web/lib/app_admin.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/*`

## Kritik Not

Vizyon uyumu detaylari ve aciklar icin ana rapor:
- `docs/vision_status.md`

UI token, template ve branding dili icin:
- `docs/ui-style.md`
