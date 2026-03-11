# Uygulamalar ve Sorumluluklar (Kod Tabanli)

## Uygulama Envanteri

`apps/` altinda uc aktif uygulama var:

- `apps/mobile_flutter`
- `apps/panel_flutter_web`
- `apps/web_next`

## 1) `apps/mobile_flutter`

Amac: Son kullanici odakli kesif + seffaflik + katki uygulamasi.

Teknik yigin:
- Flutter/Dart
- Riverpod, GoRouter
- Supabase + Firebase analitik/perf/crash

Kanit:
- `apps/mobile_flutter/pubspec.yaml`
- `apps/mobile_flutter/lib/app/router.dart`

Tek kaynak belgeler:
- `docs/mobile_architecture.md`
- `docs/mobile_features_matrix.md`
- `docs/mobile_supabase_contracts.md`
- `docs/mobile_release_checklist.md`

Baslica sorumluluklar:
- Discovery, business, menu, review, favorites, profile
- Fiyat dogrulama/onerme
- QR scan ile route cozumu
- Owner/admin operasyonlarini mobile yerine panel'e yonlendirme

Kanit:
- `apps/mobile_flutter/lib/features/discovery/*`
- `apps/mobile_flutter/lib/features/menus/*`
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`
- `apps/mobile_flutter/lib/app/router.dart`

Sinir:
- Admin ve owner CRUD/operasyon akislarinin yeri mobil degildir.
- `/admin*` ve `/owner*` route'lari mobilde panel handoff katmanina gider.

## 2) `apps/panel_flutter_web`

Amac: Admin ve owner operasyon paneli.

Teknik yigin:
- Flutter Web/Dart
- Riverpod, GoRouter, Supabase

Kanit:
- `apps/panel_flutter_web/pubspec.yaml`
- `apps/panel_flutter_web/lib/app_admin.dart`
- `apps/panel_flutter_web/lib/app/router.dart`

Tek kaynak belgeler:
- `apps/panel_flutter_web/README.md`
- `docs/test_strategy.md`
- `docs/analytics_owner.md`
- `docs/runbook.md`

Baslica sorumluluklar:
- Admin operasyon ekranlari
- Admin B2B export ve data product governance yuzeyi
- Owner isletme/menu CRUD akislari
- Owner operasyon dashboard'i (`/owner`) ve growth hub'i (`/owner/growth`)
- Yetki, moderasyon ve operasyonel paneller
- Owner'in `Dijital Menü & QR Studio` akisini panelden baslatmasi

Kanit:
- `apps/panel_flutter_web/lib/main_web_owner.dart`
- `apps/panel_flutter_web/lib/main_web_admin.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/*`
- `apps/panel_flutter_web/lib/core/navigation/public_menu_url.dart`
- `apps/panel_flutter_web/lib/features/owner_businesses/ui/owner_businesses_page.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/owner_menus_page.dart`
- `apps/panel_flutter_web/lib/features/owner_menu_management/ui/owner_menu_editor_page.dart`

Not:
- Panel QR gorseli render etmez.
- Panel public link uretirken `public_slug -> slug -> businessId` fallback zincirini kullanir; QR route ise businessId tabanli kalir.
- Owner/admin oturumu varsa `POST /auth/panel-handoff` ile session Next tarafina aktarilir.
- Varsayilan panel cikisi `/qr/:businessId?lang=tr&theme=bold` ve canonical public link icin `/m/:publicSlugOrId?lang=tr&theme=bold` kontratini kullanir.
- Template, accent renk ve branding gorsellerinin kalici kaydi panelde degil `apps/web_next` icindeki QR Studio'da yapilir.
- Panel icinde bilincli placeholder alanlari da vardir:
  - `assets/brand`
  - `lib/core/privacy`
  Detay: `docs/panel_placeholders.md`

## 3) `apps/web_next`

Amac: Public restoran QR menu katmani.

Teknik yigin:
- Next.js 15 + React 19 + TypeScript
- Tailwind + tema tokenlari
- Supabase SSR/client

Kanit:
- `apps/web_next/package.json`
- `apps/web_next/next.config.mjs`

Tek kaynak belgeler:
- `apps/web_next/README.md`
- `docs/ui-style.md`
- `docs/web_next_perf.md`
- `docs/runbook.md`

Baslica sorumluluklar:
- Public menu render
- Authenticated QR olusturma, link kopyalama, PNG/SVG indirme
- Business bazli template / branding ayarlarini kaydetme
- SEO metadata + JSON-LD + OG gorseli
- Privacy-friendly analytics toplama
- Owner icin business-bazli `QR Studio` yuzeyi

Aktif route'lar:
- `/`
- `/login`
- `/m/[publicSlugOrId]`
- `/m/[publicSlugOrId]/c/[categoryId]`
- `/m/[publicSlugOrId]/i/[itemId]`
- `/qr/[businessId]`
- `/q/[shortCode]`
- `/auth/panel-handoff`
- `/api/track`
- `/api/presentation-settings`
- `/api/media/upload`
- `/api/og`

Kanit:
- `apps/web_next/app/page.tsx`
- `apps/web_next/app/login/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/c/[categoryId]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/i/[itemId]/page.tsx`
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/app/auth/panel-handoff/route.ts`
- `apps/web_next/app/q/[code]/route.ts`
- `apps/web_next/app/api/track/route.ts`
- `apps/web_next/app/api/presentation-settings/route.ts`
- `apps/web_next/app/api/media/upload/route.ts`
- `apps/web_next/app/api/og/route.tsx`

Not:
- Public URL modeli slug merkezlidir: canonical path `public_slug`, fallback `slug`, son fallback `businessId`.
- Semantik public route `/m/[publicSlugOrId]` olsa da mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` seklindedir.
- `apps/web_next/app/(public)/b/[slug]/page.tsx` ve eski `/m/{businessId}` istekleri geriye donuk redirect katmanlari olarak korunur.
- `apps/web_next/app/qr/[businessId]/page.tsx` session yoksa `/login?redirect=...` yonlendirir; session varsa `can_manage_business_v1` ile business yetkisini dogrular.
- Panel uygulamasi, QR acilisinda Next'e session handoff yapar.
- Public menu varsayilan dili ve template'i `business_menu_presentation_settings` tablosundan okunur; query paramlari yalnizca override katmanidir.
- `preview=1` query'si QR Studio icinden kaydetmeden once canli menu onizlemesi icin kullanilir.
- QR Studio icinde `Reset to Default` ve `Unsaved changes` guard vardir.
- Branding gorselleri `menu-media` public bucket'ina `businesses/{businessId}/branding/...` path izolasyonu ile yuklenir.
- Ops ve incident teshisi icin birincil belge `docs/runbook.md` dosyasidir.
- QR gate/login yuzeyi mobil hedef boyutlari 44x44 standardina gore polish edilmistir.
- Admin/owner CRUD ekranlari Next.js'e tasinmamistir; bu akislar panel uygulamasinda kalir.
- UI token, template ve branding detaylari icin tekrar bu dokumani buyutmeyin; tek teknik kaynak `docs/ui-style.md` dosyasidir.

## Owner Panel UX Omurgasi

`apps/panel_flutter_web` owner akislarinda tum business-bagimli ekranlar ortak secili isletme baglamini kullanir.

Kanit:
- `apps/panel_flutter_web/lib/features/owner/ui/owner_shell.dart`
- `apps/panel_flutter_web/lib/shared/ui/components/owner_business_context_bar.dart`

Davranis:
- shell icinde ustte secili isletme context bar'i gorunur
- hizli business switcher ile aktif business degistirilir
- `/owner` operasyon merkezi kalite, trust ve owner aksiyonlarini toplar
- `/owner/growth` talep, gorunurluk, sponsorship katalogu ve sponsorship lead katmanini toplar
- `trash`, `growth`, `team`, `activity` gibi ekranlar secili business baglamina gore acilir
- `/owner/analytics` growth alaninin detay analitik alt sayfasi olarak calisir

## Ortak Paketler

`packages/` altinda:
- `api_client`
- `l10n_assets`
- `shared_config`
- `shared_types`
- `ui_tokens`

Durum:
- `packages/shared` kaldirildi.
- Web tarafinda aktif tema kaynagi `apps/mobile_flutter/lib/app/theme` -> `apps/web_next/src/styles/tokens.css` map'i uzerinden ilerler.
- `packages/ui_tokens` artik `apps/web_next` icin aktif source-of-truth degildir.
- Tasarim dili ve token haritasi icin tek kaynak `docs/ui-style.md` dosyasidir.

Kanit:
- `packages/*`
- `apps/mobile_flutter/lib/app/theme/*`
- `apps/web_next/src/styles/tokens.css`
- `apps/web_next/src/styles/globals.css`
