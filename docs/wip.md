# WIP / Eksik Parca Listesi (Kod Kanitli)

## Urun Yuzeyi Aciklari

1. Next admin sayfasi placeholder.
   - Kanit: `apps/web_next/app/admin/page.tsx`
2. Next owner ve menu-builder route'lari redirect.
   - Kanit: `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`

## Icerik/L10n Aciklari

1. Acik kritik l10n mojibake kalmadi; otomatik kontrol aktif.
   - Kanit: `tools/l10n_audit.mjs`

## Guvenlik/Operasyon Aciklari

1. Acik kritik operasyon maddesi kalmadi.

Not:
- Root build/clean scriptlerinin PowerShell bagimliligi kapanmistir (`tools/workspace_ops.mjs`).
- Production domain/env sozlesmesi eklendi (`docs/deploy.md`).

## Test Aciklari

1. Panelde `integration_test` iskeleti eklendi ancak calistirma ortami eksik.
   - Kanit: `apps/panel_flutter_web/integration_test/app_smoke_test.dart`
   - Not: Web `integration_test` desteklemiyor; proje icinde Windows desktop hedefi de yok.
2. Web Next e2e kapsami baslangic seviyesinde (auth + redirect smoke).
   - Kanit: `apps/web_next/e2e/auth-and-routing.spec.ts`, `apps/web_next/playwright.config.ts`, `apps/web_next/package.json`

## Mevcut Ama Kullanilmayan/Kismi Bagli

1. Acik kritik artifact klasoru kalmadi (`qr_menu_next/` kaldirildi).
2. `packages/shared` kaldirildi; aktif paylasilan schema kaynagi `apps/web_next/src/shared/*`.

## Kapatma Kriteri

Bu dosya maddeleri kapanmis sayilmasi icin:

- Kod degisikligi + ilgili test/dogrulama
- Dokuman guncellemesi (`docs/vision_status.md`, `docs/roadmap.md`)
