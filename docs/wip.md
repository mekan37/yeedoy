# WIP / Eksik Parca Listesi (Kod Kanitli)

## Urun Yuzeyi Aciklari

1. Next admin sayfasi placeholder.
   - Kanit: `apps/web_next/app/admin/page.tsx`
2. Next owner ve menu-builder route'lari redirect.
   - Kanit: `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`
3. Web public menu sayfasinda fiyat confidence/history sunumu yok.
   - Kanit: `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx`

## Icerik/L10n Aciklari

1. ARB ve generated l10n dosyalarinda mojibake metinler var.
   - Kanit:
   - `apps/mobile_flutter/lib/l10n/app_en.arb`
   - `apps/mobile_flutter/lib/l10n/app_tr.arb`
   - `apps/mobile_flutter/lib/l10n/app_localizations_en.dart`
   - `apps/mobile_flutter/lib/l10n/app_localizations_tr.dart`

## Guvenlik/Operasyon Aciklari

1. `apps/web_next/.env.example` dosyasinda gercek key benzeri degerler var.
2. `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` bos.

Kanit:
- `apps/web_next/.env.example`
- `supabase/remote_schema.sql`
- `supabase/remote_schema_latest.sql`

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
