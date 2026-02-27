# Veri Modeli (Supabase) - Kaynak Doküman

Bu doküman, yalnızca repo içindeki SQL migration ve uygulama sorgularına dayanır.

## Kaynaklar

- Migration dosyaları: `supabase/migrations/*.sql`
- Uygulama sorguları:
  - `apps/mobile_flutter/lib/**/*.dart`
  - `apps/panel_flutter_web/lib/**/*.dart`
  - `apps/web_next/app/**/*.ts*`
  - `apps/web_next/src/lib/**/*.ts`

Not:

- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` boş.
- Bu yüzden tablo/RPC çıkarımı migration + kod sorgularından yapılmıştır.

## Uygulamalarda Aktif Kullanılan Çekirdek Tablolar

### Menü ve işletme ekseni

- `businesses`
- `menus`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_translations`

Kanıt:

- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/menu/page.tsx`
- `apps/web_next/app/api/menu/category/route.ts`
- `apps/web_next/app/api/menu/item/route.ts`
- `apps/web_next/app/api/menu/item-variant/route.ts`
- `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`

### Yetki ve yönetim

- `admin_users`
- `owner_claims`
- `business_submissions`

Kanıt:

- `apps/web_next/middleware.ts`
- `apps/web_next/src/lib/auth.ts`
- `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`
- `apps/web_next/app/api/businesses/route.ts`

### Etkileşim ve topluluk

- `favorites`
- `notifications`
- `reports`
- `business_suggestions`
- `group_requests`
- `group_offers`
- `price_alerts`
- `visits`

Kanıt:

- `apps/mobile_flutter/lib/features/favorites/data/favorites_repository.dart`
- `apps/mobile_flutter/lib/features/notifications/data/inbox_repository.dart`
- `apps/mobile_flutter/lib/features/suggestions/data/suggestions_repository.dart`
- `apps/mobile_flutter/lib/features/group_requests/data/group_requests_repository.dart`
- `apps/mobile_flutter/lib/features/price_alerts/data/price_alerts_repository.dart`
- `apps/panel_flutter_web/lib/features/visits/data/visits_repo.dart`

## Uygulamalarda Aktif Kullanılan Önemli RPC'ler

### Web Next

- `is_admin`
- `is_owner_of_business`
- `owner_list_my_businesses_v2`
- `owner_submit_new_business_v1`

Kanıt:

- `apps/web_next/middleware.ts`
- `apps/web_next/src/lib/auth.ts`
- `apps/web_next/app/(dashboard)/dashboard/page.tsx`
- `apps/web_next/app/api/businesses/route.ts`

### Mobile Flutter (örnek ana RPC kümeleri)

- Keşif: `get_daily_picks`, `get_city_districts_v1`
- Menü: `get_menu_sections_v1`, `search_menu_items_v1`
- Fiyat alarmı: `create_price_alert_v1`, `list_my_alerts_v1`
- Sosyal/labs: `get_taste_matches_hybrid_v1`, `list_group_requests_v1`

Kanıt:

- `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`
- `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`
- `apps/mobile_flutter/lib/features/price_alerts/data/price_alerts_repository.dart`
- `apps/mobile_flutter/lib/features/taste_twin/data/taste_twin_repository.dart`
- `apps/mobile_flutter/lib/features/group_requests/data/group_requests_repository.dart`

### Panel Flutter Web (örnek ana RPC kümeleri)

- Rol/yetki: `current_user_role_v1`, `is_admin`
- Admin: `admin_get_queues_counts_v1`, `admin_list_receipt_submissions_v1`
- Owner: `owner_list_perks_v1`, `owner_set_perk_status_v1`

Kanıt:

- `apps/panel_flutter_web/lib/core/security/app_role_providers.dart`
- `apps/panel_flutter_web/lib/src/features/admin/data/admin_repository.dart`
- `apps/panel_flutter_web/lib/src/features/admin/data/admin_receipt_submissions_repository.dart`
- `apps/panel_flutter_web/lib/features/perks/data/perk_repository.dart`

## Migrationlarda Tanımlı (Örnek) Tablo Seti

Migration taramasında oluşturma ifadesi görülen tablolar arasında şunlar vardır:

- `public.business_submissions`
- `public.menu_item_variants`
- `public.business_amenities`
- `public.alert_events`
- `public.price_alerts`
- `public.edge_rate_limit_events`
- `public.notifications`
- `public.sponsorships`
- `public.sponsorship_packages`
- `public.sponsorship_leads`
- `public.storage_deletion_queue`
- `public.user_location_prefs`

Kaynak:

- `supabase/migrations/*.sql`

Not:

- Uygulamada kullanılan bazı çekirdek tabloların (`businesses`, `menus`, `menu_items`, `menu_categories`) bu repo snapshot'ında "ilk create" migration'ı görünmüyor. Bu tablolar mevcut ve sorgulanıyor, fakat başlangıç DDL'i bu çalışma alanında bulunamadı.

## RLS/Politika Görünümü (Örnek)

Migrationlarda görülen politika örnekleri:

- `price_alerts_owner_insert` / `price_alerts_owner_select` / `price_alerts_owner_update` / `price_alerts_owner_delete`
- `business_submissions_owner_insert` / `business_submissions_admin_all`
- `group_requests_owner_insert` / `group_requests_owner_select`
- `user_location_prefs_*`

Kaynak:

- `supabase/migrations/*.sql`
