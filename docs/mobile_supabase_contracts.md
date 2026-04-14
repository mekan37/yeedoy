# Mobil Supabase Kontratlari

Bu belge `apps/mobile_flutter` tarafinin gercekte kullandigi Supabase kontratlarinin tek kaynagidir.

Kapsam:

- auth modeli
- tablolar
- RPC'ler
- storage yuzeyleri
- mobil icin beklenen erisim sinirlari

Bu belge migration veya policy dosyasi degildir. Schema degisikligi buradan yapilmaz.

## Auth

Mobil istemci:

- `supabase_flutter`

Bootstrap:

- `apps/mobile_flutter/lib/main.dart`

Session storage:

- `apps/mobile_flutter/lib/core/security/secure_local_storage.dart`

Beklenti:

- mobile auth session local ve guvenli tutulur
- authenticated akislar user-scoped RLS ile calisir

## Tablolar

Kodda gozlenen tablo kullanimlari:

### Public / ortak read yuzeyleri

- `businesses`
- `businesses_with_stats`
- `business_hours`
- `menus`
- `menu_sections`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `business_price_index_v1`

### Auth / user-scoped yuzeyler

- `favorites`
- `notifications`
- `reports`
- `review_votes`
- `user_profiles`
- `price_alerts`
- `business_suggestions`
- `owner_claims`
- `menu_item_price_suggestions`
- `menu_item_suggestions`
- `temp_uploads`
- `group_offers`

### Diger read yuzeyleri

- `business_amenities`
- `embeds`
- `feed_events`
- `menu_item_price_status_v1`

Kanit ornekleri:

- `apps/mobile_flutter/lib/features/discovery/data/search_repository.dart`
- `apps/mobile_flutter/lib/features/notifications/data/inbox_repository.dart`
- `apps/mobile_flutter/lib/features/profile/data/profile_repository.dart`
- `apps/mobile_flutter/lib/features/contribute/data/temp_uploads_repository.dart`

## RPC Envanteri

### Analytics / telemetry

- `log_event_v1`

Kanit:

- `apps/mobile_flutter/lib/core/analytics/analytics_repository.dart`

### Discovery / search

- `search_businesses_v1`
- `get_home_feed_v1`
- `get_daily_picks`
- `get_city_districts_v1`
- `get_nearby_campaign_stories_v1`
- sponsorlu discovery RPC akisi

Kanit:

- `apps/mobile_flutter/lib/features/discovery/data/search_repository.dart`
- `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart`

### Business

- `get_business_detail_v1`
- `get_business_new_items_v1`
- `get_business_amenities_v1`
- `owner_update_business_amenities_v1`
- `get_business_trending_items_v1`
- `get_business_crowd_v1`
- `submit_presence_v2`
- `submit_presence_v1`
- `get_business_recent_checkins_v1`
- `submit_report_v1`
- `submit_report_v2`

Not:

- mobil istemci artik `submit_report_v2` kullanir ve `p_idempotency_key` gonderir
- `submit_report_v1` legacy kontrat olarak kalir
- replay tarafinda ayni key yeniden gelirse server cache'lenmis cevabi dondurur; `rate_limited_24h` yalnizca truly yeni rapor denemeleri icin anlamlidir
- mobile artik `submit_presence_v2` ile presence submit write'inda da explicit idempotency kullanir
- `submit_presence_v1` legacy kontrat olarak kalir

Kanit:

- `apps/mobile_flutter/lib/features/business/data/*`

### Menus

- `get_menu_by_business_v1`
- `get_menu_sections_v1`
- `get_menu_items_v1`
- `public_menu_share_view_v1`
- `search_menu_items_v1`
- `pick_one_menu_item_v1`
- `get_menu_item_context_v1`
- `bump_food_catalog_popularity_v1`

Kanit:

- `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart`
- `apps/mobile_flutter/lib/features/menus/data/menu_item_search_repository.dart`
- `apps/mobile_flutter/lib/features/menus/data/menu_item_context_repository.dart`

### Reviews

- `get_business_reviews_v2`
- `submit_review_v1`
- `submit_review_v2`

Not:

- mobil istemci review create icin deterministic `idempotency_key` uretir ve queue kaydina yazar
- mobil artik `submit_review_v2` kullanir ve `p_idempotency_key` gonderir
- `submit_review_v1` legacy kontrat olarak kalir
- replay tarafinda ayni key yeniden gelirse server ayni review sonucunu dondurur; `same_business_cooldown` yalnizca truly yeni denemeler icin anlamlidir

Kanit:

- `apps/mobile_flutter/lib/features/reviews/data/reviews_repository.dart`

### Favorites

- `set_favorite_v2`
- `toggle_favorite_v1`
- `list_favorites_v1` ve ilgili favori RPC'leri
- `upsert_collection_share_v1`
- `get_collection_share_by_slug_v1`

Kanit:

- `apps/mobile_flutter/lib/features/favorites/data/*`

### Notifications

- `mark_notification_read_v1`
- `mark_all_notifications_read_v1`
- `register_user_device_v1`
- `unregister_user_device_v1`

Kanit:

- `apps/mobile_flutter/lib/features/notifications/data/inbox_repository.dart`

### Profile

- `get_my_profile_stats`
- `get_my_reputation_score_v1`
- `get_my_weekly_missions`
- `get_my_achievements_v1`
- `get_my_achievements_v2`
- `get_my_profile_progress_v1`
- `get_my_daily_micro_task_v1`
- `get_my_trust_graph_v1`
- `get_my_behavior_segment_v1`
- `get_my_silent_quality_score_v1`
- `get_my_diet_profile_v1`
- `upsert_my_diet_profile_v1`

Kanit:

- `apps/mobile_flutter/lib/features/profile/data/*`

### Community / graph / feed

- `discover_gourmets_v1`
- `get_my_following_v1`
- `set_follow_v2`
- `toggle_follow_v1`
- `get_my_feed_v1`
- `get_heroes_v1`
- `get_taste_matches_hybrid_v1`
- `taste_recommendations_from_match_v2`
- `get_taste_overlap_examples_v1`
- `get_signal_overlap_examples_v1`
- `get_taste_divergence_examples_v1`
- `get_user_public_profile_v1`
- `ensure_my_profile_v1`
- `get_smart_feed_v1`
- `get_smart_feed_v2`

Kanit:

- `apps/mobile_flutter/lib/features/gourmets/data/*`
- `apps/mobile_flutter/lib/features/heroes/data/*`
- `apps/mobile_flutter/lib/features/taste_twin/data/*`
- `apps/mobile_flutter/lib/features/smart_feed/data/*`

### Group requests

- `create_group_request_v1`
- `list_group_requests_v1`
- `list_open_requests_for_business_v1`
- `submit_group_offer_v1`
- `accept_group_offer_v1`
- `close_group_request_v1`
- `set_group_offer_vote_v2`
- `vote_group_offer_v1`

Not:

- mobile artik `set_group_offer_vote_v2` ile group offer vote write'inda da desired-state explicit idempotency kullanir
- `vote_group_offer_v1` legacy compatibility fallback olarak kalir

Kanit:

- `apps/mobile_flutter/lib/features/group_requests/data/group_requests_repository.dart`

### Alerts / suggestions / suspended

- `create_price_alert_v2`
- `create_price_alert_v1`
- `list_my_alerts_v1`
- `list_my_alert_events_v1`
- `set_menu_item_photo_vote_v2`
- `set_menu_item_price_vote_v2`
- `submit_business_suggestion`
- `submit_business_suggestion_v2`
- `submit_menu_item_suggestion_v2`
- `submit_menu_item_price_suggestion_v5`

Not:

- queue-backed contribution write'lari `idempotency_key` ile queue'lanir; menu item suggestion gibi online-only write'lar ayni tokeni dogrudan RPC'ye tasir
- business suggestion write'lari icin mobile `submit_business_suggestion_v2` uzerinden `p_idempotency_key` gonderir
- explicit server-side idempotency artik business suggestion/review/report/menu price suggestion/menu item suggestion write'larinda vardir
- `submit_menu_item_price_suggestion_v5` ve `submit_menu_item_suggestion_v2` ayni logical payload tekrarinda cache'lenmis sonucu dondurur
- mobile artik `create_price_alert_v2` ile price alert create write'inda da explicit idempotency kullanir
- mobile artik `set_favorite_v2` ve `set_menu_item_price_vote_v2` ile favorite/price vote write'larinda da desired-state idempotency kullanir
- mobile artik `set_follow_v2` ve `set_menu_item_photo_vote_v2` ile follow/photo vote write'larinda da desired-state idempotency kullanir
- `create_price_alert_v1`, `toggle_favorite_v1`, `vote_menu_item_price_v1`, `toggle_follow_v1` ve `vote_menu_item_photo_v1` legacy compatibility fallback olarak kalir
- `get_my_suspended_claims_v1`
- `get_my_suspended_claim_badge_v1`
- `get_budget_combos_v1`
- `get_active_perks_v1`
- `get_business_compare_v1`

Kanit:

- `apps/mobile_flutter/lib/features/price_alerts/data/*`
- `apps/mobile_flutter/lib/features/suggestions/data/*`
- `apps/mobile_flutter/lib/features/suspended_meals/data/*`
- `apps/mobile_flutter/lib/features/budget_combos/data/*`
- `apps/mobile_flutter/lib/features/perks/data/*`
- `apps/mobile_flutter/lib/features/compare/domain/compare_provider.dart`

## Storage

### Temp uploads

- bucket: `temp`
- path pattern: `temp_uploads/{businessId}/...`
- tablo kaydi: `temp_uploads`

Kanit:

- `apps/mobile_flutter/lib/features/contribute/data/temp_uploads_repository.dart`

### Menu/photo upload adapter

- edge function endpoint: `/functions/v1/wp-upload-user`
- aktif adapter:
  - `apps/mobile_flutter/lib/core/media/media_upload_client.dart`
  - `apps/mobile_flutter/lib/core/media/media_upload_client_io.dart`
  - `apps/mobile_flutter/lib/core/media/media_upload_client_web.dart`
- repository:
  - `apps/mobile_flutter/lib/core/media/media_upload_repository.dart`

Not:

- Backend kontrati ayni kalir, ama mobile UI/controller katmani artik `media upload` dili kullanmalidir.
- Aktif mobile call site'larda `wp_upload` importu kalmamistir ve legacy wrapper dosyalari kaldirilmistir.

## Erisim Beklentisi

Beklenen kategoriler:

- public read
- authenticated user-scoped read/write
- limited owner-style helper RPC

Mobilden admin panel seviyesinde write veya global read beklenmemelidir.

## Drift Kurali

Yeni bir mobile feature:

1. yeni tablo okuyorsa
2. yeni RPC cagiriyorsa
3. yeni storage bucket/path kullaniyorsa

bu belge ayni sprintte guncellenmelidir.
