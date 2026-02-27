# Veri Modeli (Supabase) - Kod Tabanli Ozet

Bu dokuman migration ve uygulama sorgularindan uretilmistir.

## Kaynaklar

- `supabase/migrations/*.sql`
- `apps/mobile_flutter/lib/**/*`
- `apps/panel_flutter_web/lib/**/*`
- `apps/web_next/app/**/*`
- `apps/web_next/src/lib/**/*`

## Cekirdek Tablo Kullanimlari

### Isletme/Menu Ekseni

- `businesses`
- `menus`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_translations`

Kanit:
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`
- `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`

### Katki/Moderasyon Ekseni

- `menu_item_price_suggestions`
- `reports`
- `owner_claims`
- `business_submissions`
- `admin_users`

Kanit:
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- `apps/panel_flutter_web/lib/src/features/admin/data/admin_price_suggestions_repository.dart`
- `apps/panel_flutter_web/lib/src/features/admin/data/admin_reports_repository.dart`
- `apps/web_next/src/lib/auth.ts`

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

## Kritik RPC Kumelemesi

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
- `apps/web_next/middleware.ts`
- `apps/web_next/src/lib/auth.ts`
- `apps/web_next/app/(dashboard)/dashboard/page.tsx`
- `apps/web_next/app/api/businesses/route.ts`

## Bilinen Bosluklar

- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` bos oldugu icin tam snapshot burada yok.
- Cekirdek tablolarin ilk olusum migrationlari bu klasorde tam tarihsel zincirde gorunmuyor olabilir.

Aksiyon:
- En azindan bir tam schema snapshot uretip repoda tut.
