# Uygulamalar ve Sorumluluklar (Kaynak Doküman)

Bu doküman yalnızca yerel repo (`C:\yeedoy`) incelemesine dayanır.

## Repo Uygulama Envanteri

`apps/` altında mevcut klasörler:

- `apps/mobile_flutter`
- `apps/panel_flutter_web`
- `apps/web_next`

Kaynak: `apps/` klasör envanteri.

## 1) `apps/mobile_flutter`

Amaç: Son kullanıcıya yönelik mobil deneyim.

Teknik yığın:

- Flutter + Dart (`pubspec.yaml`)
- Riverpod, GoRouter, Supabase Flutter, Firebase, ML Kit vb.

Ana sorumluluklar:

- Keşif ve işletme görüntüleme.
- Menü/fiyat görüntüleme.
- Yorum, favori, bildirim, profil.
- Katkı akışları (fiyat önerisi, QR okuma ile yönlendirme vb).
- Labs/sosyal akışlar (`taste_twin`, `group_requests`, `heroes`, `gourmets`).

Kanıt dosyaları:

- `apps/mobile_flutter/pubspec.yaml`
- `apps/mobile_flutter/lib/app/router.dart`
- `apps/mobile_flutter/lib/features/*`

## 2) `apps/panel_flutter_web`

Amaç: Owner/Admin paneli (aktif çalışan panel).

Teknik yığın:

- Flutter Web + Dart (`pubspec.yaml`)
- Riverpod, GoRouter, Supabase Flutter

Ana sorumluluklar:

- Owner route'ları: `/owner/...`
- Admin route'ları: `/admin/...`
- Moderasyon, öneri/suggestion, claim, sponsorship, audit vb operasyon ekranları.

Kanıt dosyaları:

- `apps/panel_flutter_web/pubspec.yaml`
- `apps/panel_flutter_web/lib/app/router.dart`
- `apps/panel_flutter_web/lib/app_admin.dart`
- `apps/panel_flutter_web/lib/src/features/admin/ui/*`

Not:

- `apps/panel_flutter_web/lib/web_order/web_order_app.dart` "TODO" placeholder içeriyor.
- `main_web_order.dart` var ancak kök scriptlerde kullanılmıyor.

Kanıt:

- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
- `apps/panel_flutter_web/lib/main_web_order.dart`
- `apps/panel_flutter_web/package.json`

## 3) `apps/web_next`

Amaç: Public web + QR menü + işletme dashboard yüzeyi.

Teknik yığın:

- Next.js 15 + React 19 + TypeScript
- Supabase SSR/client
- TailwindCSS

Ana sorumluluklar:

- Public route'lar: `/`, `/b/[slug]`, `/q/[code]`
- Auth: `/login`
- Dashboard: `/dashboard/...`
- Menü editör API'leri: `/api/menu/*`
- QR üretim API'si: `/api/qr`

Kanıt dosyaları:

- `apps/web_next/package.json`
- `apps/web_next/next.config.mjs`
- `apps/web_next/middleware.ts`
- `apps/web_next/app/**/*`
- `apps/web_next/app/api/**/*`

Not:

- `/admin` sayfası yetki kontrolü içeriyor ama içerik placeholder.
- `/owner` ve `/menu-builder` route'ları dashboard'a redirect ediyor.

Kanıt:

- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`

## Ortak Paketler (`packages/*`)

Envanter:

- `api_client`
- `l10n_assets`
- `shared`
- `shared_config`
- `shared_types`
- `ui_tokens`

Durum gözlemi:

- `@yeedoy/*` paket adları tanımlı ancak uygulama kodunda doğrudan import görünmüyor.
- `packages/shared` içinde schema/type dosyaları var ama kendi `package.json` dosyası yok.

Kanıt:

- `packages/*` içeriği
- `packages/*/package.json`
- Import taraması: `apps` ve `packages` içinde `@yeedoy/...` eşleşmesi yok

## Kullanılmayan / Kısmi Bağlı Unsurlar

- `qr_menu_next/` kaynak uygulama değil; yalnızca artifact klasörleri (`.next`, `node_modules`) bulunuyor.
- Panelde `web_order` uygulaması placeholder.
- Next tarafında bazı yüzeyler yönlendirme/placeholder aşamasında.

Kanıt:

- `qr_menu_next/*`
- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
