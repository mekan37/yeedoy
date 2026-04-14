# Yeedoy Vizyon Uyum Raporu (Kod Tabanli)

Tarih: 2026-03-06  
Kapsam: `C:\yeedoy` altindaki mevcut kod ve canli Supabase schema kesfi.

## Kisa Sonuc

Yeedoy kod tabani, mobilde kesif + seffaflik + topluluk katkisi; panelde owner/admin operasyonlari; Next tarafinda ise public QR menu dagitimi olarak netlesmis durumda. Son turda `apps/web_next`, slug merkezli canonical public menu ve backward-compatible QR/public link modeliyle sertlestirildi.

## Kritik Kesif Sonucu

- `public.businesses.public_slug` migration ile tanimlandi ve canonical public link uretiminde kullaniliyor.
- Public URL modeli artik `public_slug -> slug -> businessId` fallback zinciriyle kuruluyor.
- Public read RLS su tablolar icin mevcut: `businesses`, `menus`, `menu_categories`, `menu_items`, `menu_sections`, `menu_item_variants`, `menu_item_photos`, `menu_translations`, `business_media`.
- Web analytics yazimi icin `log_event_v1` RPC kullanilabiliyor.

## Vizyon-Durum Matrisi

| Vizyon Basligi | Durum | Kod Kaniti | Not |
|---|---|---|---|
| Fiyat dogrulama ve guven | Guclu | `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`, `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`, `supabase/migrations/20260313_000001_menu_price_confidence.sql`, `supabase/migrations/20260322000012_data_quality_engine.sql` | Fiyat statusu, history, confidence, suggestion akislari mobil ve backend tarafinda var. |
| Seffaflik (fiyat gecmisi, son guncelleme, dogrulama izi) | Guclu | `apps/mobile_flutter/lib/features/business/ui/business_page.dart`, `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`, `apps/web_next/src/ui/sections/public-menu-client.tsx`, `apps/web_next/src/lib/public-menu-page.ts` | Web public sayfa canonical `public_slug` route'u ile render oluyor; eski UUID linkleri redirect ile korunuyor. |
| Canli menu (kategori, filtre, gorsel, QR erisim) | Guclu | `apps/web_next/app/(public)/m/[slug]/page.tsx`, `apps/web_next/app/(public)/m/[slug]/c/[categoryId]/page.tsx`, `apps/web_next/app/(public)/m/[slug]/i/[itemId]/page.tsx`, `apps/web_next/app/q/[code]/route.ts` | Public menu, kategori ve urun detay route'lari aktif. Dosya klasoru `[slug]` olsa da davranis canonical slug merkezlidir. |
| Topluluk katkisi (fiyat guncelleme, raporlama, onay) | Guclu | `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`, `apps/mobile_flutter/lib/features/menus/ui/components/verify_price_bottom_sheet.dart`, `apps/panel_flutter_web/lib/features/admin/ui/admin_price_suggestions_page.dart` | Katki ve moderasyon zinciri kurulu. |
| Guclu kesif (sehir/ilce, trend, favori, profil) | Guclu | `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`, `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart`, `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart` | Kesif ve favori/profil omurgasi aktif. |
| Public QR menu dagitimi | Guclu | `apps/web_next/app/qr/[businessId]/page.tsx`, `apps/web_next/app/auth/panel-handoff/route.ts`, `apps/web_next/src/ui/sections/qr-generator.tsx`, `apps/web_next/src/lib/short-code.ts` | QR olusturma Next'te; sayfa artik login + business yetkisi kontrollu. |
| Isletme paneli + CRUD | Guclu (Flutter panel) | `apps/panel_flutter_web/lib/app/router.dart`, `apps/panel_flutter_web/lib/features/*` | Owner/admin write akislari Next'e tasinmadi. |
| Admin paneli | Guclu (Flutter panel) | `apps/panel_flutter_web/lib/app_admin.dart`, `apps/panel_flutter_web/lib/features/admin/ui/*` | Operasyon tek kaynak olarak panel uygulamasinda. |
| Gozlemlenebilirlik | Gelisiyor | `apps/web_next/app/api/track/route.ts`, `apps/web_next/middleware.ts`, `apps/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart` | Public tarafta sade analytics var; merkezi dashboard yok. |
| Test kapsami dengesi | Guclu | `apps/web_next/test/*`, `apps/web_next/e2e/*`, `apps/web_next/package.json`, `apps/mobile_flutter/test/*`, `apps/panel_flutter_web/test/*` | Next tarafinda typecheck + lint + build + unit + e2e geciyor; opsiyonel live smoke test de var. |
| Dokuman ve guvenlik hijyeni | Gelisiyor | `apps/web_next/README.md`, `apps/web_next/.env.example`, `docs/deploy.md`, `docs/apps.md` | Web app kapsami ve env sozlesmesi guncellendi. |

## Durum Notu

Bu dosya backlog veya ayrintili tamamlanan is listesi tutmaz. Son snapshot'a giren tarihsel release detaylari icin:

- `docs/archive/history/release_index.md`

Acik ve sonraki adim listesi icin:

- `docs/roadmap.md`

## Yapilacaklarin Kaynagi

Acik ve sonraki adim listesi bu dokumanda tutulmaz. Tek backlog kaynagi:

- `docs/roadmap.md`

Bu dosya yalnizca mevcut durum ve kod kaniti raporu olarak kalir.

## Koda Dayali Genel Degerlendirme

Yeedoy'un bugunku ayrimi nettir:

- Mobil: kesif, seffaflik, katkı
- Panel: owner/admin operasyonu
- Next: public QR menu dagitimi

Bu ayrim performans, RLS ve urun kapsam acisindan daha temizdir. Next tarafindaki ana risk CRUD degil; canli schema degisimlerinin public route sozlesmesine etkisidir.
