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
   - Durum: Tamamlandi (`/`, `/isletme-giris`, `/isletme-kayit` + role bazli yonlendirme + deep-link/yetki testleri)
2. Next panel gecis kararini netlestir
   - Durum: Tamamlandi (`/admin`, `/owner`, `/menu-builder` -> panel web yonlendirme)
3. Next test katmanini smoke ustune cikar
   - Durum: Baslangic tamamlandi (vitest + component/API route unit testleri)
4. Supabase schema snapshot bosluklarini kapat
   - Durum: Tamamlandi (`supabase/remote_schema.sql`, `supabase/remote_schema_latest.sql`)

## P2 (Orta Vade)

1. Monitoring/perf/prefs icin gorunur tani UI
   - Durum: Tamamlandi (`/admin/observability`)
2. `qr_menu_next/` artifact klasor temizligi
   - Durum: Tamamlandi
3. `packages/shared` konsolidasyonu
   - Durum: Tamamlandi (kaldirildi; `apps/web_next/src/shared/*` tek kaynak)
4. Root PowerShell scriptlerine cross-platform alternatif
   - Durum: Tamamlandi (`tools/workspace_ops.mjs` + root `package.json` script guncellemesi)
5. Panel + Next production domain/env sozlesmesi
   - Durum: Tamamlandi (`docs/deploy.md` -> `Domain ve ENV Sozlesmesi`)

## Referans

- `docs/vision_status.md`
- `docs/wip.md`
