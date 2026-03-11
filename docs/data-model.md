# Veri Modeli (Supabase) - Kod Tabanli Ozet

Bu dokuman migrationlar, mevcut uygulama sorgulari ve canli schema kesfi uzerinden guncellenmistir.

Bu dokuman tablo, RPC ve veri eksenlerinin tek envanter kaynagidir.

Su konular burada tutulmaz:

- route ve istemci mimarisi
- UI ekran hiyerarsisi
- release veya smoke operasyon notlari
- mobile tarafinin exhaustive tablo/RPC kontrat listesi

Tek kaynaklar:

- sistem mimarisi ve route akisi: `docs/architecture.md`
- mobile mimari ve urun siniri: `docs/mobile_architecture.md`, `docs/mobile_features_matrix.md`
- mobile tablo/RPC kontratlari: `docs/mobile_supabase_contracts.md`
- ekran bazli operasyon sozlesmeleri: `docs/admin_businesses.md`, `docs/admin_business_submissions.md`, `docs/moderation_queue.md`, `docs/audit.md`
- deploy ve runbook: `docs/deploy.md`, `docs/runbook.md`

Not:

- Bu belge tum sistem icin ortak veri eksenini ozetler.
- Mobile tarafi icin exhaustive tablo/RPC listesi burada tekrar edilmez; tek kaynak `docs/mobile_supabase_contracts.md` dosyasidir.

## Kaynaklar

- `supabase/migrations/*.sql`
- `apps/mobile_flutter/lib/**/*`
- `apps/panel_flutter_web/lib/**/*`
- `apps/web_next/app/**/*`
- `apps/web_next/src/lib/**/*`

## Cekirdek Tablo Kullanimlari

### Public Menu Ekseni

- `businesses`
- `business_hours`
- `business_media`
- `menus`
- `menu_sections`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `menu_translations`
- `analytics_events`

Kanit:
- `apps/web_next/src/lib/db/menu-read.ts`
- `apps/web_next/src/lib/public-menu-page.ts`
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/app/api/track/route.ts`

Not:
- `businesses` tablosunda `slug` ve canonical public route icin `public_slug` alanlari bulunur.
- Web public route modeli `public_slug -> slug -> businessId` fallback zinciriyle calisir.
- Eski UUID tabanli linkler backward-compatible redirect ile korunur.
- Semantik public route `/m/[publicSlugOrId]` olsa da mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` seklindedir.

### Katki/Moderasyon Ekseni

- `menu_item_price_suggestions`
- `reports`
- `client_mutation_idempotency_keys`
- `owner_claims`
- `business_submissions`
- `admin_users`
- `receipt_submissions`
- `receipt_matches`

Kanit:
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- `apps/panel_flutter_web/lib/features/admin/data/admin_price_suggestions_repository.dart`
- `apps/panel_flutter_web/lib/features/admin/data/admin_reports_repository.dart`
- `apps/panel_flutter_web/lib/features/admin/data/admin_receipt_submissions_repository.dart`

Not:

- `receipt_submissions` artik yalnizca image kaniti degil, operator review durumu da tasir:
  - `review_status`
  - `review_note`
  - `reviewed_at`
  - `reviewed_by`
- admin workbench tarafinda `admin_list_receipt_submissions_v2`, `admin_get_receipt_submission_summary_v1`, `admin_list_receipt_submission_matches_v1` ve `admin_list_receipt_submission_batch_opportunities_v1` bu ekseni operasyona cevirir

### Etkilesim Ekseni

- `favorites`
- `notifications`
- `price_alerts`
- `group_requests`
- `group_offers`
- `visits`

Kanit:
- `apps/mobile_flutter/lib/features/favorites/data/favorites_repository.dart`
- `apps/mobile_flutter/lib/features/notifications/data/inbox_repository.dart`
- `apps/mobile_flutter/lib/features/price_alerts/data/price_alerts_repository.dart`
- `apps/mobile_flutter/lib/features/group_requests/data/group_requests_repository.dart`

### Monetization / Sponsorship Ekseni

- `sponsorship_packages`
- `sponsorships`
- `sponsorship_leads`
- `sponsorship_impressions_daily`
- `business_premium`

Not:

- `sponsorship_packages` tablosu artik yalnizca gosterim etiketi degil, yapisal satis verisi de tasir:
  - `price_cents`
  - `currency_code`
  - `inventory_limit`
- admin tarafinda package CRUD, revenue summary ve surface inventory bu eksenden uretilir
- owner tarafinda self-serve sponsorship katalogu ayni ekseni business baglaminda okur

Kanit:
- `apps/panel_flutter_web/lib/features/admin/data/admin_monetization_repository.dart`
- `apps/panel_flutter_web/lib/features/owner_monetization/data/owner_monetization_repository.dart`
- `supabase/migrations/20260203_000001_monetization_sponsorships.sql`
- `supabase/migrations/20260325000014_sponsorship_inventory_reporting_v1.sql`

## Kritik RPC Kumelemesi

### Public Menu / Analytics

- `get_menu_items_v1`
- `get_menu_item_variants_v1`
- `get_menu_item_photos_v1`
- `log_event_v1`
- `public_menu_share_view_v1`

Kanit:
- `apps/web_next/src/lib/db/menu-read.ts`
- `apps/web_next/app/q/[code]/route.ts`
- `apps/web_next/app/api/track/route.ts`

### B2B Export / Data Product

- `admin_export_anonymous_trends_csv_v1`
- `admin_export_regional_price_index_csv_v1`
- `admin_export_menu_inflation_csv_v1`
- `admin_export_price_anomalies_csv_v1`

Not:

- bu RPC'ler admin paneldeki `/admin/b2b-exports` ekranina veri verir
- urun hatti ve gizlilik siniri icin tek kaynak `docs/b2b_exports.md` dosyasidir
- teknik olarak hepsi CSV dondurur, fakat urun seviyesinde ayni ticari sinifa ait degildir

Kanit:
- `apps/panel_flutter_web/lib/features/admin/data/admin_b2b_exports_repository.dart`
- `supabase/migrations/20260321000009_b2b_exports.sql`
- `supabase/migrations/20260321000023_data_moat_analytics.sql`

### Fiyat Seffafligi / Guven

- `get_menu_item_price_history_v1`
- `get_menu_item_price_status_v1`
- `get_menu_item_value_score_v1`
- `submit_menu_item_price_suggestion_v2/v3/v4`
- `get_business_price_history_v1`
- `get_business_quality_score_v1`
- `get_business_reality_score_v1`
- `get_my_reputation_score_v1`
- `get_my_silent_quality_score_v1`

Not:
- mobile review/report/business suggestion/menu price suggestion/menu item suggestion write replay'i icin `client_mutation_idempotency_keys` tablosu kullanilir
- `submit_review_v2`, `submit_report_v2`, `submit_business_suggestion_v2`, `submit_menu_item_price_suggestion_v5`, `submit_menu_item_suggestion_v2`, `create_price_alert_v2` ve `submit_presence_v2` ayni `idempotency_key` ile gelen tekrar denemelerde cache'lenmis sonucu dondurur
- `set_favorite_v2`, `set_menu_item_price_vote_v2`, `set_follow_v2`, `set_menu_item_photo_vote_v2` ve `set_group_offer_vote_v2` secondary interaction write'larinda ayni ledger'i desired-state semantigi ile kullanir
- `analytics_events` tablosundaki `offline_mutation_outcome` event'leri panel tarafinda `admin_list_offline_mutation_outcomes_v1` ile operasyon ekranina tasinabilir

Kanit:
- `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`
- `supabase/migrations/20260313_000001_menu_price_confidence.sql`
- `supabase/migrations/20260321000020_real_world_confidence.sql`
- `supabase/migrations/20260322000012_data_quality_engine.sql`

### Owner/Admin Erisim

- `is_admin`
- `is_owner_of_business`
- `owner_list_my_businesses_v2`
- `owner_submit_new_business_v1`

Kanit:
- `apps/panel_flutter_web/lib/**/*`
- `supabase/migrations/*.sql`

## Public Read Notu

Canli schema kesfinde su tablolar icin public read RLS mevcut goruldu:

- `businesses`
- `menus`
- `menu_categories`
- `menu_items`
- `menu_sections`
- `menu_item_variants`
- `menu_item_photos`
- `menu_translations`
- `business_media`

Bu durum `apps/web_next` public menu akisinin anon key ile calismasini saglar.

## Sinir Notu

Bu dosya veri envanteri sunar; route davranisi, handoff, canonical ve public menu render sirasi icin `docs/architecture.md` esas alinmalidir.
