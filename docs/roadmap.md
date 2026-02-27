# Yol Haritasi (Onceliklendirilmis)

Bu liste yalnizca koddan gorulen aciklara dayanir.

## P0 (Hemen)

1. Web env example guvenlik temizligi
   - Dosya: `apps/web_next/.env.example`
   - Durum: Tamamlandi (placeholder formatina cekildi)
   - Etki: Secret hygiene ve operasyon guvenligi

## P0 (Tamamlandi)

1. L10n mojibake temizligi + regen
   - Dosyalar: `apps/mobile_flutter/lib/l10n/app_en.arb`, `apps/mobile_flutter/lib/l10n/app_tr.arb`, `apps/mobile_flutter/lib/l10n/app_localizations_*.dart`
2. L10n audit guclendirme
   - Dosya: `tools/l10n_audit.mjs`
   - Not: Mojibake marker kontrolu eklendi
3. Web public seffaflik ozeti
   - Dosya: `apps/web_next/app/(public)/b/[slug]/page.tsx`
   - Not: Son guncelleme + confidence + 90 gun trend kartlari eklendi

## P1 (Kisa Vade)

1. Flutter panel web giris akisinin sertlestirilmesi
   - Durum: Cekirdek tamamlandi (`/`, `/isletme-giris`, `/isletme-kayit` + role bazli yonlendirme + panel kapsam disi route temizligi)
   - Kalan: deep-link testleri, yetki-hata UX iyilestirmesi
2. Next panel gecis kararini netlestir
   - `/admin`, `/owner`, `/menu-builder` stratejisi
3. Next test katmanini smoke ustune cikar
   - Unit/integration test dosyalari eklenmeli
4. Supabase schema snapshot bosluklarini kapat
   - `supabase/remote_schema.sql`, `supabase/remote_schema_latest.sql`

## P2 (Orta Vade)

1. Monitoring/perf/prefs icin gorunur tani UI
2. `qr_menu_next/` artifact klasor temizligi
3. `packages/shared` konsolidasyonu
4. Root PowerShell scriptlerine cross-platform alternatif

## Referans

- `docs/vision_status.md`
- `docs/wip.md`
