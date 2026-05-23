# Veri Modeli (Supabase) - Kod Tabanli Ozet

Bu dokuman migrationlar, mevcut uygulama sorgulari ve canli schema kesfi uzerinden guncellenmistir.

Bu dokuman tablo, RPC ve veri eksenlerinin tek envanter kaynagidir.

Su konular burada tutulmaz:

- route ve istemci mimarisi
- UI ekran hiyerarsisi
- release veya smoke operasyon notlari
- mobile tarafinin exhaustive tablo/RPC kontrat listesi

Tek kaynaklar:

- mobile tablo/RPC kontratlari: `docs/mobil-supabase-kontratlari.md`
- rol ve izin modeli: `docs/rol-yetki-matrisi.md`
- QR/public menu link zinciri: `docs/karekod-sistemi.md`
- deploy ve runbook: `docs/dagitim.md`, `docs/operasyon-kilavuzu.md`

Not:

- Bu belge tum sistem icin ortak veri eksenini ozetler.
- Mobile tarafi icin exhaustive tablo/RPC listesi burada tekrar edilmez; tek kaynak `docs/mobil-supabase-kontratlari.md` dosyasidir.

## Kaynaklar

- `supabase/migrations/*.sql`
- `uygulamalar/mobil/lib/**/*`
- `uygulamalar/web/uygulama/**/*`
- `uygulamalar/web/src/lib/**/*`

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
- `uygulamalar/web/src/lib/veri/menu-read.ts`
- `uygulamalar/web/src/lib/public-menu-page.ts`
- `uygulamalar/web/uygulama/(public)/m/[slug]/page.tsx`
- `uygulamalar/web/uygulama/sunucu/izleme/route.ts`

Not:
- `businesses` tablosunda `slug` ve canonical public route icin `public_slug` alanlari bulunur.
- Web public route modeli `public_slug -> slug -> businessId` fallback zinciriyle calisir.
- Eski UUID tabanli linkler backward-compatible redirect ile korunur.
- Semantik public route `/m/[publicSlugOrId]` olsa da mevcut App Router klasor yolu `uygulamalar/web/uygulama/(public)/m/[slug]/...` seklindedir.

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
- `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
- `uygulamalar/web/uygulama/admin/price-suggestions/page.tsx`
- `uygulamalar/web/uygulama/admin/reports/page.tsx`
- `uygulamalar/web/uygulama/admin/receipt-submissions/page.tsx`

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
- `uygulamalar/mobil/lib/features/favoriler/data/favoriler_deposu.dart`
- `uygulamalar/mobil/lib/features/notifications/data/gelen-kutusu_deposu.dart`
- `uygulamalar/mobil/lib/features/price_alerts/data/price_alerts_deposu.dart`
- `uygulamalar/mobil/lib/features/group_requests/data/group_requests_deposu.dart`

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
- `uygulamalar/web/uygulama/admin/sponsorships/page.tsx`
- `uygulamalar/web/uygulama/admin/sponsorship-packages/page.tsx`
- `uygulamalar/web/uygulama/owner/growth/page.tsx`
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
- `uygulamalar/web/src/lib/veri/menu-read.ts`
- `uygulamalar/web/uygulama/kod/[code]/route.ts`
- `uygulamalar/web/uygulama/sunucu/izleme/route.ts`

### B2B Export / Data Product

- `admin_export_anonymous_trends_csv_v1`
- `admin_export_regional_price_index_csv_v1`
- `admin_export_menu_inflation_csv_v1`
- `admin_export_price_anomalies_csv_v1`

Not:

- bu RPC'ler admin paneldeki `/admin/b2b-exports` ekranina veri verir
- teknik olarak hepsi CSV dondurur, fakat urun seviyesinde ayni ticari sinifa ait degildir

Kanit:
- `uygulamalar/web/uygulama/admin/b2b-exports/page.tsx`
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
- `analytics_events` tablosundaki `offline_mutation_outcome` event'leri web admin tarafinda `admin_list_offline_mutation_outcomes_v1` ile operasyon ekranina tasinabilir

Kanit:
- `uygulamalar/mobil/lib/features/menus/data/menu_deposu.dart`
- `supabase/migrations/20260313_000001_menu_price_confidence.sql`
- `supabase/migrations/20260321000020_real_world_confidence.sql`
- `supabase/migrations/20260322000012_data_quality_engine.sql`

### Owner/Admin Erisim

- `is_admin`
- `is_owner_of_business`
- `owner_list_my_businesses_v2`
- `owner_submit_new_business_v1`

Kanit:
- `uygulamalar/web/uygulama/owner/**`
- `uygulamalar/web/uygulama/admin/**`
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

Bu durum `uygulamalar/web` public menu akisinin anon key ile calismasini saglar.

## Sinir Notu

Bu dosya veri envanteri sunar; QR, canonical ve public menu link sirasi icin `docs/karekod-sistemi.md` esas alinmalidir.


