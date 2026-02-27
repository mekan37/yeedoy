# WIP / Eksik Parca Listesi (Kod Kanitli)

## Urun Yuzeyi Aciklari

1. Next admin sayfasi placeholder.
   - Kanit: `apps/web_next/app/admin/page.tsx`
2. Next owner ve menu-builder route'lari redirect.
   - Kanit: `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`
3. Web public menu tarafinda detayli item bazli fiyat gecmisi/kanit paneli yok (su an ozet kart var).
   - Kanit: `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx`

## Icerik/L10n Aciklari

1. Acik kritik l10n mojibake kalmadi; otomatik kontrol aktif.
   - Kanit: `tools/l10n_audit.mjs`

## Guvenlik/Operasyon Aciklari

1. `panel_flutter_web` icin production domain/env dokumani hala eksik (normal hosting + Next baglantisi).

Kanit:
- `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`

Not:
- Root build/clean scriptlerinin PowerShell bagimliligi kapanmistir (`tools/workspace_ops.mjs`).

## Test Aciklari

1. Panelde `integration_test` klasoru bulunamadi.
   - Kanit: `apps/panel_flutter_web/test/*`, `apps/panel_flutter_web/integration_test` (bulunamadi)
2. Web Next test kapsami baslangic seviyesinde (component + API route unit test var, e2e yok).
   - Kanit: `apps/web_next/test/*`, `apps/web_next/package.json`

## Mevcut Ama Kullanilmayan/Kismi Bagli

1. Acik kritik artifact klasoru kalmadi (`qr_menu_next/` kaldirildi).
2. `packages/shared` kaldirildi; aktif paylasilan schema kaynagi `apps/web_next/src/shared/*`.

## Kapatma Kriteri

Bu dosya maddeleri kapanmis sayilmasi icin:

- Kod degisikligi + ilgili test/dogrulama
- Dokuman guncellemesi (`docs/vision_status.md`, `docs/roadmap.md`)
