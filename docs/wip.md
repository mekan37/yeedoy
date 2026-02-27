# WIP / Eksik Parca Listesi (Kod Kanitli)

## Urun Yuzeyi Aciklari

1. Next admin sayfasi placeholder.
   - Kanit: `apps/web_next/app/admin/page.tsx`
2. Next owner ve menu-builder route'lari redirect.
   - Kanit: `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`
3. Web public menu tarafinda detayli item bazli fiyat gecmisi/kanit paneli yok (su an ozet kart var).
   - Kanit: `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx`
4. Flutter panel web landing/business auth akisi yeni eklendi; metinler su an hardcoded ASCII.
   - Kanit: `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`, `apps/panel_flutter_web/lib/features/auth/ui/business_login_page.dart`, `apps/panel_flutter_web/lib/features/auth/ui/business_register_page.dart`

## Icerik/L10n Aciklari

1. Acik kritik l10n mojibake kalmadi; otomatik kontrol aktif.
   - Kanit: `tools/l10n_audit.mjs`

## Guvenlik/Operasyon Aciklari

1. `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` bos.
2. `panel_flutter_web` icin production domain/env dokumani hala eksik (normal hosting + Next baglantisi).

Kanit:
- `supabase/remote_schema.sql`
- `supabase/remote_schema_latest.sql`
- `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`

## Test Aciklari

1. Web Next tarafinda test dosyasi bulunamadi; script smoke ile sinirli.
   - Kanit: `apps/web_next/package.json`, `apps/web_next` test dosya taramasi
2. Panelde `integration_test` klasoru bulunamadi.
   - Kanit: `apps/panel_flutter_web/test/*`, `apps/panel_flutter_web/integration_test` (bulunamadi)

## Mevcut Ama Kullanilmayan/Kismi Bagli

1. `qr_menu_next/` artifact klasoru.
2. `apps/panel_flutter_web/lib/web_order/web_order_app.dart` placeholder.
3. `packages/shared` package yapisi eksik (`package.json` yok).

## Kapatma Kriteri

Bu dosya maddeleri kapanmis sayilmasi icin:

- Kod degisikligi + ilgili test/dogrulama
- Dokuman guncellemesi (`docs/vision_status.md`, `docs/roadmap.md`)
