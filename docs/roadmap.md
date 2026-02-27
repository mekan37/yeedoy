# Yol Haritasi (Onceliklendirilmis)

Bu liste yalnizca koddan gorulen aciklara dayanir.

## P0 (Hemen)

1. L10n mojibake temizligi
   - Dosyalar: `apps/mobile_flutter/lib/l10n/app_en.arb`, `apps/mobile_flutter/lib/l10n/app_tr.arb`
   - Etki: UX metin kalitesi ve guven algisi
2. Web env example guvenlik temizligi
   - Dosya: `apps/web_next/.env.example`
   - Etki: Secret hygiene ve operasyon guvenligi
3. Web public seffaflik katmani
   - Hedef: `/b/[slug]` sayfasina fiyat confidence/history ozeti
   - Dosyalar: `apps/web_next/app/(public)/b/[slug]/page.tsx`, `apps/web_next/src/ui/sections/public-menu-client.tsx`

## P1 (Kisa Vade)

1. Next panel gecis kararini netlestir
   - `/admin`, `/owner`, `/menu-builder` stratejisi
2. Next test katmanini smoke ustune cikar
   - Unit/integration test dosyalari eklenmeli
3. Supabase schema snapshot bosluklarini kapat
   - `supabase/remote_schema.sql`, `supabase/remote_schema_latest.sql`

## P2 (Orta Vade)

1. Monitoring/perf/prefs icin gorunur tani UI
2. `qr_menu_next/` artifact klasor temizligi
3. `packages/shared` konsolidasyonu
4. Root PowerShell scriptlerine cross-platform alternatif

## Referans

- `docs/vision_status.md`
- `docs/wip.md`
