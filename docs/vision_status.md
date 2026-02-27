# Yeedoy Vizyon Uyum Raporu (Kod Tabanli)

Tarih: 2026-02-27  
Kapsam: Sadece `C:\yeedoy` altindaki mevcut kod ve birinci parti dokumanlar (`node_modules` ve `.next` haric).

## Kisa Sonuc

Yeedoy, kod tabanina gore sadece QR menu degil; fiyat dogrulama + topluluk katki + canli menu sistemi olarak konumlanabilecek durumda. Cekirdek mekaniklerin buyuk bolumu mobilde ve Supabase katmaninda var. Public web tarafinda seffaflik ozeti eklendi, ancak detayli gecmis/kanit katmani hala mobil kadar derin degil.

## Vizyon-Durum Matrisi

| Vizyon Basligi | Durum | Kod Kaniti | Not |
|---|---|---|---|
| Fiyat dogrulama ve guven | Guclu | `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`, `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`, `supabase/migrations/20260313_000001_menu_price_confidence.sql`, `supabase/migrations/20260322000012_data_quality_engine.sql` | Fiyat statusu, history, confidence, suggestion akislari var. |
| Seffaflik (fiyat gecmisi, son guncelleme, dogrulama izi) | Guclu (mobil) / Gelisiyor (web) | `apps/mobile_flutter/lib/features/business/ui/business_page.dart`, `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`, `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx` | Web public sayfada son guncelleme + confidence + 90 gun trend ozeti var; detayli item bazli gecmis kartlari hala eksik. |
| Canli menu (kategori, filtre, gorsel, QR erisim) | Guclu | `apps/web_next/src/ui/sections/public-menu-client.tsx`, `apps/web_next/app/api/qr/route.tsx`, `apps/web_next/app/q/[code]/page.tsx`, `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart` | QR uretim + menu render + mobil QR parse mevcut. |
| Topluluk katkisi (fiyat guncelleme, raporlama, onay) | Guclu | `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`, `apps/mobile_flutter/lib/features/menus/ui/components/verify_price_bottom_sheet.dart`, `apps/panel_flutter_web/lib/features/admin/ui/admin_price_suggestions_page.dart` | Katki ve moderasyon zinciri kurulu. |
| Guclu kesif (sehir/ilce, trend, favori, profil) | Guclu | `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`, `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`, `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart` | Kesif ve favori/profil omurgasi aktif. |
| Isletme paneli + QR olusturma | Guclu | `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`, `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`, `apps/web_next/app/api/qr/route.tsx` | Isletme icin menu+QR akisi calisiyor. |
| Admin paneli | Guclu (Flutter panel) / Yonlendirme (Next) | `apps/panel_flutter_web/lib/app_admin.dart`, `apps/panel_flutter_web/lib/features/admin/ui/*`, `apps/web_next/app/admin/page.tsx`, `apps/web_next/src/lib/panelUrl.ts` | Next `admin/owner/menu-builder` route'lari panel webe yonlenir; admin operasyonun tek kaynagi Flutter webdir. |
| Panel web giris/landing (normal hosting) | Guclu | `apps/panel_flutter_web/lib/app/router.dart`, `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`, `apps/panel_flutter_web/lib/features/auth/ui/business_login_page.dart`, `apps/panel_flutter_web/lib/features/auth/ui/business_register_page.dart` | `/` landing + `/isletme-giris` + `/isletme-kayit` + owner/admin role bazli yonlendirme aktif; panel kapsam disi route'lar kaldirildi. |
| Gozlemlenebilirlik (monitoring/perf/prefs UI) | Gelisiyor | `apps/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart`, `apps/panel_flutter_web/lib/core/monitoring/request_trace.dart`, `apps/panel_flutter_web/lib/core/perf/perf_slo.dart`, `apps/panel_flutter_web/lib/core/storage/*` | Admin panelde request trace + perf SLO + prefs explorer tani ekrani eklendi. |
| Test kapsami dengesi | Gelisiyor | `apps/mobile_flutter/test/*`, `apps/mobile_flutter/integration_test/*`, `apps/panel_flutter_web/test/*`, `apps/web_next/test/*`, `apps/web_next/package.json` | Next tarafinda component + API route unit testleri eklendi; kapsamin genisletilmesi gerekiyor. |
| Dokuman ve guvenlik hijyeni | Kismi | `apps/web_next/.env.example`, `tools/l10n_audit.mjs`, `apps/mobile_flutter/lib/l10n/app_en.arb`, `apps/mobile_flutter/lib/l10n/app_tr.arb` | L10n mojibake temizlendi ve audit'e otomatik kontrol eklendi. Web env example placeholder formatina cekildi. |

## P0 Uygulama Durumu (2026-02-27)

1. Tamamlandi: L10n mojibake temizligi yapildi (`app_en.arb`, `app_tr.arb`, generated dosyalar).
2. Tamamlandi: `tools/l10n_audit.mjs` icine mojibake marker kontrolu eklendi.
3. Tamamlandi: Web public `/b/[slug]` sayfasina seffaflik ozeti eklendi (son guncelleme, confidence, 90 gun trend).
4. Tamamlandi: `apps/web_next/.env.example` degerleri placeholder formatina cekildi.

## Yapilmasi Gerekenler (P0/P1/P2)

### P0

- Acik P0 kalmadi.

### P1

- [x] `panel_flutter_web` icin deep-link testleri ve yetki-hata UX sertlestirmesi.
  - Kod: `apps/panel_flutter_web/lib/features/auth/domain/business_auth_redirect.dart`
  - Uygulama: `apps/panel_flutter_web/lib/features/auth/ui/business_login_page.dart`, `apps/panel_flutter_web/lib/app/router.dart`
  - Test: `apps/panel_flutter_web/test/web/auth/business_auth_redirect_test.dart`, `apps/panel_flutter_web/test/web/security/route_sanitizer_test.dart`, `apps/panel_flutter_web/test/web/security/admin_permissions_test.dart`
- [x] Next `admin/owner/menu-builder` stratejisi netlestirildi: Flutter panel tek kaynak.
  - Next yonlendirme: `apps/web_next/app/admin/page.tsx`, `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`
  - Ortak panel URL helper: `apps/web_next/src/lib/panelUrl.ts`
  - Middleware sadeleme: `apps/web_next/middleware.ts` (korunan route yalnizca `/dashboard`)
- [x] Next tarafina birim/smoke ustu test katmani eklendi (component + API route).
  - Test altyapisi: `apps/web_next/vitest.config.ts`, `apps/web_next/vitest.setup.ts`
  - Component testi: `apps/web_next/test/ui/button.test.tsx`
  - API route testi: `apps/web_next/test/api/businesses-route.test.ts`
  - Script guncellemesi: `apps/web_next/package.json` (`test:unit`, `test`)
- [x] `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` dosyalari migration-derived snapshot ile dolduruldu.

- Acik P1 kalmadi.

### P2

- [x] Monitoring/perf/prefs icin daha gorunur tani ekranlari eklendi.
  - Route: `apps/panel_flutter_web/lib/app/router.dart` (`/admin/observability`)
  - Ekran: `apps/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart`
- [x] `qr_menu_next/` artifact klasoru kaldirildi.
- [x] `packages/shared` klasoru kaldirildi (aktif kod importu yoktu; `apps/web_next/src/shared/*` aktif olarak kullaniliyor).

- Acik P2 kalmadi.

## Koda Dayali Genel Degerlendirme

Yeedoy'un bugunku kodu, "fiyat seffafligi + topluluk dogrulama + canli QR menu" vizyonuna temel urun seviyesinde yakindir. En buyuk fark, mobildeki derin seffaflik katmaninin web publicte hala daha ozet seviyede kalmasi ve Next panel gecisinin yari-yolda olmasidir.
