# Yeedoy Vizyon Uyum Raporu (Kod Tabanli)

Tarih: 2026-02-27  
Kapsam: Sadece `C:\yeedoy` altindaki mevcut kod ve birinci parti dokumanlar (`node_modules` ve `.next` haric).

## Kisa Sonuc

Yeedoy, kod tabanina gore sadece QR menu degil; fiyat dogrulama + topluluk katki + canli menu sistemi olarak konumlanabilecek durumda. Cekirdek mekaniklerin buyuk bolumu mobilde ve Supabase katmaninda var. En buyuk acik, bu seffaflik katmaninin web public yuzeyde ayni gucle sunulamamasi.

## Vizyon-Durum Matrisi

| Vizyon Basligi | Durum | Kod Kaniti | Not |
|---|---|---|---|
| Fiyat dogrulama ve guven | Guclu | `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`, `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`, `supabase/migrations/20260313_000001_menu_price_confidence.sql`, `supabase/migrations/20260322000012_data_quality_engine.sql` | Fiyat statusu, history, confidence, suggestion akislari var. |
| Seffaflik (fiyat gecmisi, son guncelleme, dogrulama izi) | Guclu (mobil) / Kismi (web) | `apps/mobile_flutter/lib/features/business/ui/business_page.dart`, `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`, `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx` | Mobilde guclu; web public sayfada fiyat gecmisi/confidence katmani yok. |
| Canli menu (kategori, filtre, gorsel, QR erisim) | Guclu | `apps/web_next/src/ui/sections/public-menu-client.tsx`, `apps/web_next/app/api/qr/route.tsx`, `apps/web_next/app/q/[code]/page.tsx`, `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart` | QR uretim + menu render + mobil QR parse mevcut. |
| Topluluk katkisi (fiyat guncelleme, raporlama, onay) | Guclu | `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`, `apps/mobile_flutter/lib/features/menus/ui/components/verify_price_bottom_sheet.dart`, `apps/panel_flutter_web/lib/src/features/admin/ui/admin_price_suggestions_page.dart` | Katki ve moderasyon zinciri kurulu. |
| Guclu kesif (sehir/ilce, trend, favori, profil) | Guclu | `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`, `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`, `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart` | Kesif ve favori/profil omurgasi aktif. |
| Isletme paneli + QR olusturma | Guclu | `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`, `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`, `apps/web_next/app/api/qr/route.tsx` | Isletme icin menu+QR akisi calisiyor. |
| Admin paneli | Guclu (Flutter panel) / Kismi (Next) | `apps/panel_flutter_web/lib/app_admin.dart`, `apps/panel_flutter_web/lib/src/features/admin/ui/*`, `apps/web_next/app/admin/page.tsx` | Next `/admin` placeholder; asil admin panel Flutter webde. |
| Gozlemlenebilirlik (monitoring/perf/prefs UI) | Kismi | `apps/mobile_flutter/lib/core/monitoring/request_trace.dart`, `apps/mobile_flutter/lib/core/perf/firebase_perf_trace.dart`, `docs/devtools.md` | Altyapi var, ayri kapsamli tani ekranlari yok. |
| Test kapsami dengesi | Kismi | `apps/mobile_flutter/test/*`, `apps/mobile_flutter/integration_test/*`, `apps/panel_flutter_web/test/*`, `apps/web_next/package.json` | Next tarafinda unit/integration test dosyasi yok; `test` scripti smoke (lint+typecheck). |
| Dokuman ve guvenlik hijyeni | Kismi | `apps/web_next/.env.example`, `apps/mobile_flutter/lib/l10n/app_en.arb`, `apps/mobile_flutter/lib/l10n/app_tr.arb` | Web env example icinde gercek key benzeri degerler var; l10n mojibake var. |

## Oncelikli Aciklar

1. L10n metinlerinde mojibake bozulmasi var (`app_en.arb`, `app_tr.arb`, uretilen `app_localizations_*.dart`).
2. `apps/web_next/.env.example` icinde gercek key benzeri degerler var.
3. Web public menu deneyiminde fiyat gecmisi ve confidence/seffaflik katmani yok.
4. Next `/admin`, `/owner`, `/menu-builder` rotalari urun vaatine gore tam degil (placeholder veya redirect).
5. Dokuman setinde onceki turde kalan encoding bozukluklari vardi; bu turda duzeltildi.

## Yapilmasi Gerekenler (P0/P1/P2)

### P0

- L10n mojibake temizligi: ARB kaynaklarini duzelt, tekrar `gen-l10n` uret, audit scriptine mojibake kontrolu ekle.
- `apps/web_next/.env.example` dosyasinda keyleri placeholder'a cek.
- Web public `/b/[slug]` sayfasina en azindan son guncelleme + confidence + fiyat degisim ozeti ekle.

### P1

- Next `admin/owner/menu-builder` stratejisini netlestir:
  - Ya Flutter panel tek kaynak olacak, Next rotalari kaldirilacak/yonlendirilecek.
  - Ya Next tarafina tam ekranlar tasinacak.
- Next tarafina en az birim/smoke ustu test katmani ekle (or: component + API route testleri).
- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` dosyalarini bos kalmaktan cikar.

### P2

- Monitoring/perf/prefs icin daha gorunur tani ekranlari ekle.
- `qr_menu_next/` artifact klasorunu kaldir.
- `packages/shared` klasoru icin net karar: package'a donustur veya kaldir.

## Koda Dayali Genel Degerlendirme

Yeedoy'un bugunku kodu, "fiyat seffafligi + topluluk dogrulama + canli QR menu" vizyonuna temel urun seviyesinde yakindir. En buyuk fark, bu guclu yeteneklerin web public deneyimde esit seviyede gorunur olmamasi ve Next panel gecisinin yari-yolda kalmasidir.
