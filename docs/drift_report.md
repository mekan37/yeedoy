# Docs Drift Report

Tarih: `2026-03-04`  
Kapsam: `apps/panel_flutter_web`, `apps/web_next`, `tool/`, `test/`

Bu rapor `docs/` klasorunu source-of-truth kabul ederek son drift temizligi sonrasi kalan uyumsuzluklari listeler.

## 1) Bu Turda Kapatilan Drift Maddeleri

- `docs/devtools.md`
  - Durum: kapatildi
  - Yapilan: panel `lib/src/...` path'i gercek `lib/features/...` yoluna cekildi

- `docs/data-model.md`
  - Durum: kapatildi
  - Yapilan:
    - panel admin repo kanit path'leri duzeltildi
    - `app/q/[code]/page.tsx` referansi `app/q/[code]/route.ts` olarak guncellendi
    - semantik route `businessId`, dosya yolu `[slug]` notu eklendi

- `docs/product.md`
  - Durum: kapatildi
  - Yapilan: panel admin UI kaniti `lib/features/admin/ui/*` olarak duzeltildi

- `docs/architecture.md`
  - Durum: kapatildi
  - Yapilan:
    - `q/[code]` route handler referansi duzeltildi
    - Supabase client katmani hibrit gerceklikle belgelendi
    - semantik route `businessId`, dosya yolu `[slug]` standardi eklendi

- `docs/module_visibility_matrix.md`
  - Durum: kapatildi
  - Yapilan: `q/[code]` kaniti `route.ts` ile duzeltildi ve route semantik notu standartlastirildi

- `docs/vision_status.md`
  - Durum: kapatildi
  - Yapilan:
    - `q/[code]` kaniti `route.ts` olarak guncellendi
    - backlog tekrarini azaltmak icin aciklar `docs/roadmap.md` dosyasina baglandi
    - tamamlanan islerin tarihsel kaydi `docs/release_index.md` altina ayrildi

- Public menu route standardi
  - Durum: kapatildi
  - Yapilan: `apps.md`, `architecture.md`, `data-model.md`, `module_visibility_matrix.md`, `product.md`, `qr-system.md`, `roadmap.md`, `vision_status.md` icinde tek ifade standardi kullanildi:
    - semantik route: `/m/[businessId]`
    - mevcut dosya yolu: `app/(public)/m/[slug]/...`
    - short redirect implementation: `app/q/[code]/route.ts`

- Panel liste olcekleme dokumani
  - Durum: kapatildi
  - Yapilan:
    - `docs/panel_scale.md` ve `docs/panel_perf.md` icinde `AdminVirtualTableCard` kapsami sertlestirildi
    - aktif lazy split envanteri ve embed provider split stratejisi eklendi

- Test smoke tanimi
  - Durum: kapatildi
  - Yapilan: `docs/test_strategy.md` icinde panel smoke modeli `e2e/panel-smoke.spec.cjs` tabanli Playwright browser suite olarak netlestirildi

- Eksik operasyon dokumanlari
  - Durum: kapatildi
  - Yapilan:
    - `docs/admin_businesses.md`
    - `docs/admin_business_submissions.md`
    - `docs/apps.md` icine owner business context bar davranisi
    - `docs/release_index.md` ile tarihsel release belgeleri tek noktadan indekslendi

## 2) Docs -> Code mismatch

### HIGH

- Acik madde yok.

### MED

- Acik madde yok.

### LOW

- `docs/release/*`
  - Durum: tarihsel release snapshot dokumanlari aktif kod akisinin disinda kalabilir
  - Risk: `LOW`
  - Onerilen aksiyon: Bu dosyalari tarihsel kayit olarak koru, fakat kalici source-of-truth olarak `deploy.md` ve `runbook.md` kullan.

## 3) Code -> Docs missing

### HIGH

- Acik madde yok.

### MED

- Acik madde yok.

### LOW

- `apps/panel_flutter_web/lib/core/cache/memory_ttl_cache.dart`
  - Durum: teknik davranis ozetlenmis durumda
  - Risk: `LOW`
  - Onerilen aksiyon: Gerekirse ileride `docs/panel_scale.md` icine cache key ve invalidation ornekleri eklenebilir.

## 4) Conflicting docs

### HIGH

- Acik madde yok.

### MED

- `docs/deploy.md` ve `docs/runbook.md`
  - Durum: sinir ayrimi duzeltildi
  - Risk: `LOW`
  - Onerilen aksiyon: `deploy.md` yalnizca env/domain/deploy modeli, `runbook.md` ise smoke/incident adimlari olarak korunmali.

### LOW

- `docs/roadmap.md` ve `docs/vision_status.md`
  - Durum: tekrar azaltildi, ancak benzer basliklar gelecekte yeniden dagilabilir
  - Risk: `LOW`
  - Onerilen aksiyon: Acik ve yapilacak maddeleri yalniz `roadmap.md` tasimaya devam et.

## Ozet

Bu tur sonrasi acik `HIGH` seviyede docs drift maddesi kalmadi. Kalan maddeler isimlendirme ve belge siniri koruma seviyesindedir; kod ve operasyon akisini yanlis yonlendirecek kirik path veya route kaniti bulunmuyor.
