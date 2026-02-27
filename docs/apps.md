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

Baslica sorumluluklar:
- Discovery, business, menu, review, favorites, profile
- Fiyat dogrulama/onerme
- QR scan ile route cozumu

Kanit:
- `apps/mobile_flutter/lib/features/discovery/*`
- `apps/mobile_flutter/lib/features/menus/*`
- `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`

## 2) `apps/panel_flutter_web`

Amac: Admin ve owner operasyon paneli (kapsamli panel burada).

Teknik yigin:
- Flutter Web/Dart
- Riverpod, GoRouter, Supabase

Kanit:
- `apps/panel_flutter_web/pubspec.yaml`
- `apps/panel_flutter_web/lib/app_admin.dart`
- `apps/panel_flutter_web/lib/app/router.dart`

Baslica sorumluluklar:
- Admin operasyon ekranlari
- Owner isletme/menu is akislari

Ek not:
- `web_order` girisi var ama placeholder.
- `main_web_order.dart` root scriptlerde kullanilmiyor.

Kanit:
- `apps/panel_flutter_web/lib/main_web_order.dart`
- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
- `package.json` (repo root)

## 3) `apps/web_next`

Amac: Isletme dashboard + QR menu web yuzeyi.

Teknik yigin:
- Next.js 15 + React 19 + TypeScript
- Supabase SSR/client

Kanit:
- `apps/web_next/package.json`
- `apps/web_next/next.config.mjs`

Baslica sorumluluklar:
- Dashboard business/menu/QR akisi
- Public menu route: `/b/[slug]`
- QR short route: `/q/[code]`

Kanit:
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/app/q/[code]/page.tsx`

Dikkat:
- `/admin` sayfasi placeholder metin seviyesinde.
- `/owner` ve `/menu-builder` dashboard'a redirect.

Kanit:
- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`

## Ortak Paketler

`packages/` altinda:
- `api_client`, `l10n_assets`, `shared`, `shared_config`, `shared_types`, `ui_tokens`

Durum:
- `packages/shared` icinde `package.json` yok.
- Kodda `@yeedoy/*` importu bulunamadi.

Kanit:
- `packages/*`
- `packages/shared/README.md`
- `apps` ve `packages` genel import taramasi
