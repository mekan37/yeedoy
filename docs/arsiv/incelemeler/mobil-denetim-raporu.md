# Mobile Audit Report

Tarih: 2026-03-04  
Kapsam: `uygulamalar/mobil`  
Yontem: kod tabani + `pubspec.yaml` + mevcut `docs/` referanslari uzerinden kanitli audit.  
Not: UTF-8 / ARB kalitesi, localization metadata ve ceviri polish bu turda secondary kabul edildi. Gozlenen sorunlar release blocker olarak yalnizca gerekli yerde not edildi.

## 1) Executive Summary

- Mobil uygulama gercekte bir consumer app: kesif, isletme, menu, urun, yorum, favori, profil, bildirim ve topluluk katkisi akislari aktif. Kanit: `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`
- Owner ve admin operasyonlari mobilde yok; `/owner*` ve `/admin*` rotalari mobilde `'/panel-web'` uzerinden panel akisina yonleniyor. Kanit: `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`
- En guclu bugunku urun omurgasi: discovery -> business -> menu -> item -> verify/report/review -> favorites/profil. Kanit: `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`, `uygulamalar/mobil/lib/features/business/ui/business_page.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
- QR ve public menu baglantisi mobilde tuketim odakli: QR scan / deep-link cozumleme var, fakat QR Studio / owner panel akislari mobilde degil. Kanit: `uygulamalar/mobil/lib/core/linking/yeedoy_route_resolver.dart`, `uygulamalar/mobil/lib/features/katki/ui/katki_entry.dart`, `uygulamalar/mobil/lib/features/menus/ui/public_menu_share_page.dart`
- V2/deneysel alanlar zaten kodda mevcut: `smart_feed`, `taste_twin`, `group_requests`, `top_businesses`, `heroes`, `gourmets`, `budget_combos`, `suspended_meals`, `perks`, `embeds`, sponsorlu kesif. Kanit: `uygulamalar/mobil/lib/features/*`
- Mobil bootstrap production-grade temeller tasiyor: Supabase auth, secure local storage, Firebase Analytics/Crashlytics/Performance, Mobile Ads ve dotenv init birlikte calisiyor. Kanit: `uygulamalar/mobil/lib/uygulama_girisi.dart`
- Supabase kullanimi yogun ve RPC-centric. Discovery, menu, profile, taste, group requests ve alerts alanlari agirlikla RPC ile okunuyor; bu, backend kontratini dogru dokumante etmeden gelisimi riskli yapar. Kanit: `uygulamalar/mobil/lib/features/**/*deposu*.dart`
- Offline destegi artik merkezi hale geliyor; SQLite-backed snapshot store, unified mutation queue, replay servisi, connectivity-restore tetigi ve client-side idempotency standardi var. Cekirdek katki write'larinda explicit server-side idempotency, action-bazli retry/backoff ve devtools queue diagnostics + conflict policy + suggested action operator gorunurlugu saglandi; `favorite`, `price vote`, `follow`, `photo vote`, `price alert create`, `group offer vote` ve `presence submit` de explicit desired-state/idempotent write kapsamina alindi. Panel `/admin/observability` artik `offline_mutation_outcome` event'lerini operator yuzeyinde aciyor; threshold ve escalation persistence kurallari runtime calibration ile deploy'suz ayarlanabiliyor. `offline_write_guard_check.dart` yeni write yuzeylerinin registry disinda kalmasini CI seviyesinde blokluyor. Kanit: `uygulamalar/mobil/lib/core/storage/yerel_db/sqflite_yerel_db_deposu.dart`, `uygulamalar/mobil/lib/core/storage/offline_mutation_queue.dart`, `uygulamalar/mobil/lib/core/storage/offline_mutation_idempotency.dart`, `uygulamalar/mobil/lib/core/storage/offline_sync_service.dart`, `uygulamalar/mobil/lib/core/network/connectivity_restore_service.dart`, `uygulamalar/mobil/lib/core/storage/offline_queue_diagnostics.dart`, `uygulamalar/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart`, `uygulamalar/mobil/tool/offline_write_guard_check.dart`, `supabase/migrations/20260325000004_review_report_idempotency_v1.sql`, `supabase/migrations/20260325000005_business_suggestion_idempotency_v1.sql`, `supabase/migrations/20260325000007_menu_suggestion_idempotency_v1.sql`, `supabase/migrations/20260325000008_secondary_interaction_idempotency_v1.sql`, `supabase/migrations/20260325000009_follow_and_photo_vote_idempotency_v1.sql`, `supabase/migrations/20260325000010_admin_offline_mutation_observability_v1.sql`, `supabase/migrations/20260325000011_price_alert_idempotency_v1.sql`, `supabase/migrations/20260325000012_group_offer_vote_and_presence_idempotency_v1.sql`
- Skor dili 13.6 kapsaminda toparlandi; mobil artik topluluga acik puanlari `kullanici guveni` ve `veri guveni` omurgasina oturtuyor. Profilde destek sinyalleri ayri anlatiliyor, business/menu/item ekranlarinda `trust`, `confidence` ve `value score` kavramlari ortak rehber sheet ile aciklaniyor. Kanit: `uygulamalar/mobil/lib/features/shared/ui/components/community_score_explainer_sheet.dart`, `uygulamalar/mobil/lib/features/profil/ui/profil_page.dart`, `uygulamalar/mobil/lib/features/business/ui/business_page.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_page.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
- Performans riski en cok asiri buyuk ekran dosyalarinda: `discovery_page.dart`, `menu_item_page.dart`, `business_page.dart`. Bunlar state, layout ve network davranisini tek dosyada topluyor. Kanit: dosya boyutlari ve path'ler
- Embed / media / OCR tarafi mobil build maliyetini artiriyor: `webview_flutter`, `youtube_player_iframe`, `google_ml_kit`, `image_picker`, `share_plus`. Bunlar aktif ama yalnizca belirli akislar icin gerekli. Kanit: `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/yerlestir/ui/yerlestir_viewer_page.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_ocr_flow.dart`
- En buyuk release blocker artik signing kodu degil, gercek `android/key.properties` ve keystore secret'larinin release ortamina baglanmasi. Kod tarafi debug signing'den cikartildi ve `assembleRelease` bu eksiklikte bilincli olarak fail ediyor. Kanit: `uygulamalar/mobil/android/uygulama/build.gradle.kts`, `uygulamalar/mobil/android/key.properties.example`
- Build flavor / stage / prod ayrimi net degil. Repo icinde `productFlavors`, `fastlane`, `codemagic`, `appdistribution` veya paralel mobil release zinciri kaniti yok. Kanit: `uygulamalar/mobil/package.json`, `uygulamalar/mobil/android/uygulama/build.gradle.kts`
- Test paketi var. Router tabanli smoke kapsamı genisletildi, deep-link/QR route smoke gercek Android cihazda dogrulandi, devtools payload simulator smoke eklendi, Android native debug push bridge hazirlandi ve `flutter run` + `android_debug_push.ps1` ile gercek cihazda Flutter/router katmanina kadar dogrulandi; true FCM transport/iOS push tap e2e kapsami halen sinirli. Kanit: `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart`, `uygulamalar/mobil/integration_test/live_write_smoke_integration_test.dart`, `uygulamalar/mobil/lib/features/devtools/ui/developer_tools_page.dart`, `uygulamalar/mobil/lib/features/notifications/domain/push_notification_service.dart`, `uygulamalar/mobil/lib/features/notifications/domain/android_debug_push_bridge.dart`, `uygulamalar/mobil/android/uygulama/src/main/kotlin/com/yeedoy/uygulama/MainActivity.kt`, `uygulamalar/mobil/tool/android_debug_push.ps1`, `uygulamalar/mobil/test/core/linking/yeedoy_route_resolver_test.dart`, `uygulamalar/mobil/test/features/notifications/domain/notification_target_path_resolver_test.dart`
- Mobile dokumanlari olusturuldu/guncellendi; bundan sonra drift riski release checklist + test strategy + setup dokumanlarinin birlikte guncel tutulmasina bagli. Kanit: `docs/mobil-release-kontrol-listesi.md`, `docs/mobil-test-stratejisi.md`, `docs/setup.md`
- En buyuk firsat: mevcut consumer omurgasi guclu; kisa vadede offline minimum, release hardening, Supabase contract dokumani ve performans ayrisma ile uygulama ciddi sekilde stabil hale gelir.

## 2) Urun Akis Haritasi (User Journeys)

### 2.1 Mevcut Ana Journey

1. Discovery
   - Giris genelde `'/kesif'` veya shell icindeki home yuzeyi.
   - Kanit: `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
2. Business
   - Discovery sonucu veya deep link ile `'/isletme/:id'`.
   - Kanit: `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`, `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
3. Menu
   - `'/isletme/:id/menu/:menuId'`, `'/menu/:menuId'`, `'/isletme/:id/menu-item/:itemId'`.
   - Kanit: `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_page.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
4. Item
   - Fiyat, photo, varyant, history, verify, report akislari item seviyesinde.
   - Kanit: `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
5. Review / Vote / Contribute
   - Review yazma, helpful vote, report, QR scan, receipt/menu OCR, gecici upload.
   - Kanit: `uygulamalar/mobil/lib/features/reviews/ui/review_create_page.dart`, `uygulamalar/mobil/lib/features/reviews/data/reviews_deposu.dart`, `uygulamalar/mobil/lib/features/business/data/report_deposu.dart`, `uygulamalar/mobil/lib/features/katki/ui/katki_entry.dart`, `uygulamalar/mobil/lib/features/menus/ui/menu_ocr_flow.dart`
6. Profile
   - Profil, achievements, stats, missions, feed, claim/oneriion history, inbox.
   - Kanit: `uygulamalar/mobil/lib/features/profil/ui/profil_page.dart`, `uygulamalar/mobil/lib/features/notifications/ui/gelen-kutusu_page.dart`

### 2.2 MVP Kapsami

- Discovery
- Business detail
- Menu / menu item
- Review / report / favorites
- Login / profile
- QR ile route acma
- Fiyat verify / suggestion

Kanit:
- `uygulamalar/mobil/lib/features/kesify/*`
- `uygulamalar/mobil/lib/features/business/*`
- `uygulamalar/mobil/lib/features/menus/*`
- `uygulamalar/mobil/lib/features/reviews/*`
- `uygulamalar/mobil/lib/features/favoriler/*`
- `uygulamalar/mobil/lib/features/profil/*`
- `uygulamalar/mobil/lib/features/katki/*`

### 2.3 V2 / Genisleme Kapsami

- `smart_feed`
- `taste_twin`
- `group_requests`
- `top_businesses`
- `gourmets`
- `heroes`
- `budget_combos`
- `price_alerts`
- `suspended_meals`
- `embeds`
- sponsorlu kesif / native ads

Kanit:
- `uygulamalar/mobil/lib/features/smart_feed/*`
- `uygulamalar/mobil/lib/features/taste_twin/*`
- `uygulamalar/mobil/lib/features/group_requests/*`
- `uygulamalar/mobil/lib/features/en-iyiler_businesses/*`
- `uygulamalar/mobil/lib/features/gurmelers/*`
- `uygulamalar/mobil/lib/features/liderler/*`
- `uygulamalar/mobil/lib/features/butce_combos/*`
- `uygulamalar/mobil/lib/features/price_alerts/*`
- `uygulamalar/mobil/lib/features/suspended_meals/*`
- `uygulamalar/mobil/lib/features/yerlestir/*`
- `uygulamalar/mobil/lib/features/ads/*`
- `uygulamalar/mobil/lib/features/monetization/*`

### 2.4 Owner / Admin Siniri

- Admin islemleri mobilde olmamali; kod zaten boyle davraniyor.
- Owner business/menu CRUD, team, queue, audit, QR Studio, restore/trash/versioning panelde kalmali.
- Mobilde owner/admin yerine panel handoff var.

Kanit:
- `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`
- `uygulamalar/panel_flutter_web/lib/features/admin/ui/*`
- `uygulamalar/panel_flutter_web/lib/features/owner*/*`

### 2.5 QR Menu / Next Baglanti Noktalari

- QR veya deeplink tarama mobilde `yeedoy_route_resolver` + `contribute_entry` akisi ile cozuluyor.
- Public menu paylasim ve web baglantisi mobilde tuketiliyor.
- QR Studio / owner presentation ayarlari mobilde degil, panel + Next tarafinda.

Kanit:
- `uygulamalar/mobil/lib/features/katki/ui/katki_entry.dart`
- `uygulamalar/mobil/lib/features/menus/ui/public_menu_share_page.dart`
- `uygulamalar/web/uygulama/(public)/m/[slug]/page.tsx`
- `uygulamalar/panel_flutter_web/lib/core/navigation/public_menu_url.dart`

## 3) Kod Yapisi ve Modul Haritasi

### 3.1 App Seviyesi

- Giris: `uygulamalar/mobil/lib/uygulama_girisi.dart`
- Shell: `uygulamalar/mobil/lib/uygulama/uygulama_kabugu.dart`
- Router: `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`
- Theme source-of-truth:
  - `uygulamalar/mobil/lib/uygulama/tema/renkler.dart`
  - `uygulamalar/mobil/lib/uygulama/tema/uygulama_tokenleri.dart`
  - `uygulamalar/mobil/lib/uygulama/tema/uygulama_tipografisi.dart`
  - `uygulamalar/mobil/lib/uygulama/tema/uygulama_temasi.dart`

### 3.2 Feature Modulleri

| Modul | Amac | Giris ekranlari | State | Repo / data | Not |
|---|---|---|---|---|---|
| `ads` | Native reklam kartlari | discovery/business icine gomulu | Riverpod `Notifier` | `native_ad_controller.dart` | aktif |
| `auth` | login / auth guards | `login_page.dart` | Riverpod provider + widget state | `auth_service.dart` | aktif |
| `budget_combos` | butce odakli menu onerileri | `budget_combo_results_page.dart` | FutureProvider | `budget_combos_deposu.dart` | aktif |
| `business` | business detail, amenities, crowd, reports | `business_page.dart` | buyuk StatefulWidget + Riverpod | `business_detail_deposu.dart`, `report_deposu.dart`, digerleri | en agir modullerden biri |
| `chains` | zincir / sube sayfasi | `chain_page.dart` | widget state + Supabase call | UI icinden dogrudan | aktif ama yalin |
| `compare` | business karsilastirma | `compare_page.dart` | Riverpod | `compare_provider.dart` | aktif |
| `contribute` | QR scan, route parse, upload girisi | `contribute_entry.dart` | widget state | `temp_uploads_deposu.dart` | aktif |
| `devtools` | dahili debug ayarlari | `developer_tools_page.dart` | widget state + prefs | core prefs/config | dev/debug |
| `discovery` | ana kesif, search, sponsored, campaigns, city filters | `discovery_page.dart` | buyuk StatefulWidget + Riverpod notifier | `discovery_deposu.dart`, `search_deposu.dart` | en agir modul |
| `embed` | external embed gosterimi | `embed_viewer_page.dart` | StatefulWidget | `embed_deposu.dart` | webview/youtube agir |
| `favorites` | favori listeleri ve paylasim | `favorites_page.dart` | widget state + Riverpod | `favorites_deposu.dart`, `collection_share_deposu.dart`, `collection_social_deposu.dart` | aktif |
| `gourmets` | gourmet kesif, following, feed | `gourmets_page.dart`, `following_page.dart`, `feed_page.dart` | Riverpod | `gourmet_deposu.dart`, `feed_deposu.dart`, `follow_deposu.dart` | V2 |
| `group_requests` | grup talebi ve teklif akislari | `my_group_requests_page.dart`, `group_request_wizard_page.dart`, `group_request_detail_page.dart` | Riverpod + widget state | `group_requests_deposu.dart` | V2 |
| `heroes` | topluluk/hero leaderboard | `heroes_page.dart` | Riverpod | `hero_deposu.dart` | aktif |
| `legal` | policy/yasal surface | `legal_page.dart` | Stateless | config + local data | aktif |
| `menus` | menu, item, OCR, share, price verify, photo | `menu_page.dart`, `menu_item_page.dart`, `public_menu_share_page.dart` | AsyncNotifier + widget state | `menu_deposu.dart`, `core/media/*`, `food_catalog_deposu.dart` | en kritik veri alani |
| `monetization` | sponsorlu isletme provider | dogrudan sayfa yok | FutureProvider | `sponsored_businesses_provider.dart` | discovery tarafinda kullaniliyor |
| `notifications` | inbox + device token kaydi | `inbox_page.dart` | Riverpod `AsyncNotifier` | `inbox_deposu.dart`, `push_notification_service.dart` | aktif |
| `onboarding` | ilk kullanici akisi | `onboarding_page.dart` | widget state | local prefs / location | aktif |
| `perks` | aktif kampanya/perk listesi | business icine gomulu | FutureProvider | `perk_deposu.dart` | aktif ama kucuk |
| `price_alerts` | fiyat alarmi | sheet/tab icinden | Riverpod | `price_alerts_deposu.dart` | aktif |
| `profile` | profil, stats, achievements, settings | `profile_page.dart`, `profile_settings_page.dart` | Riverpod + widget state | `profile_deposu.dart`, `diet_profile_deposu.dart` | aktif |
| `reviews` | review list/create/helpful vote | `business_reviews_page.dart`, `review_create_page.dart` | Riverpod | `reviews_deposu.dart` | aktif |
| `shared` | ortak UI kit / widgets / visuals | gomulu | reusable | yok | cift tarafli kullanim yuksek |
| `smart_feed` | personalize feed | `smart_feed_page.dart` | Riverpod | `smart_feed_deposu.dart` | V2 |
| `splash` | acilis ekrani | `splash_page.dart` | Stateless | yok | aktif |
| `suggestions` | business suggestion / benim onerilerim | `suggest_business_page.dart`, `my_suggestions_page.dart` | widget state + Riverpod | `suggestions_deposu.dart` | aktif |
| `suspended_meals` | askida yemek claim takibi | `my_suspended_claims_page.dart` | Riverpod | `my_suspended_claim_deposu.dart` | V2 |
| `taste_twin` | taste graph/match | `taste_twin_page.dart` | Riverpod | `taste_twin_deposu.dart` | V2 |
| `top_businesses` | donemsel en iyi isletmeler | `top_businesses_page.dart` | Riverpod | `top_businesses_deposu.dart` | aktif |

### 3.3 Bos / Stub / Olu Kalan Parcalar

| Path | Durum | Neden |
|---|---|---|
| `uygulamalar/mobil/lib/uygulama/splash/` | bos klasor | klasor var, icinde dosya yok |
| `uygulamalar/mobil/integration_test/*` | aktif smoke | `golden_paths` route zinciri + runtime gate + deep-link/QR route smoke + devtools payload simulator smoke ve `live_write_smoke` opt-in backend write smoke mevcut; Android native debug push bridge eklendi, true FCM transport/iOS e2e genisletmesi kaldi |

### 3.4 Kaldirilmali Listesi

Bu bolum "hemen sil" degil, audit karari olarak okunmali:

- `uygulamalar/mobil/lib/uygulama/splash/`
  - Bos klasor, kod faydasi yok.

## 4) Supabase Entegrasyonu (Gercek Kullanim)

Bu liste repo cagrilarindan turetilmis gozlenen kullanimdir; tam DB envanteri degildir.

### 4.1 Auth Modeli

- Mobil Supabase istemcisi `supabase_flutter` ile bootstrap oluyor.
- Session local storage icin `SecureLocalStorage` kullaniliyor:
  - mobilde `flutter_secure_storage`
  - web fallback olarak `SharedPreferencesLocalStorage`

Kanit:
- `uygulamalar/mobil/lib/uygulama_girisi.dart`
- `uygulamalar/mobil/lib/core/security/secure_local_storage.dart`

### 4.2 Gozlenen Tablolar

Okuma / yazma kaniti olan tablolar:

- `businesses`
- `businesses_with_stats`
- `business_hours`
- `business_amenities`
- `business_suggestions`
- `business_price_index_v1` (view benzeri okuma)
- `menus`
- `menu_sections`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `menu_item_price_suggestions`
- `menu_item_price_status_v1` (view)
- `menu_item_suggestions`
- `favorites`
- `notifications`
- `owner_claims`
- `reports`
- `review_votes`
- `user_profiles`
- `feed_events`
- `price_alerts`
- `embeds`
- `group_offers`
- `temp_uploads`
- storage bucket `temp`

Kanit ornekleri:
- `uygulamalar/mobil/lib/features/kesify/data/arama_deposu.dart`
- `uygulamalar/mobil/lib/features/menus/data/menu_deposu.dart`
- `uygulamalar/mobil/lib/features/notifications/data/gelen-kutusu_deposu.dart`
- `uygulamalar/mobil/lib/features/profil/data/profil_deposu.dart`
- `uygulamalar/mobil/lib/features/katki/data/temp_uploads_deposu.dart`

### 4.3 Gozlenen RPC'ler

Mobilde dogrudan gozlenen RPC'ler:

- `log_event_v1`
- `get_active_perks_v1`
- `get_business_compare_v1`
- `discover_gourmets_v1`
- `get_my_following_v1`
- `toggle_follow_v1`
- `get_my_feed_v1`
- `get_user_location_prefs_v1`
- `upsert_user_location_prefs_v1` inferans: `user_location_deposu.dart`
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
- `get_budget_combos_v1`
- `mark_notification_read_v1`
- `mark_all_notifications_read_v1`
- `register_user_device_v1`
- `unregister_user_device_v1`
- `search_businesses_v1` / trigram search akisi
- `get_home_feed_v1`
- `get_daily_picks`
- `get_city_districts_v1`
- `get_sponsored_businesses_v1` inferansi `discovery_deposu.dart` icinden
- `set_favorite_v2`
- `toggle_favorite_v1`
- `list_favorites_v1`
- `favorite_counts_v1` benzeri favori RPC'leri
- `upsert_collection_share_v1`
- `get_collection_share_by_slug_v1`
- `get_top_businesses_period_v1`
- `create_group_request_v1`
- `list_group_requests_v1`
- `list_open_requests_for_business_v1`
- `submit_group_offer_v1`
- `accept_group_offer_v1`
- `close_group_request_v1`
- `set_group_offer_vote_v2`
- `vote_group_offer_v1`
- `get_heroes_v1`
- `get_menu_by_business_v1`
- `get_menu_sections_v1`
- `get_menu_items_v1`
- `public_menu_share_view_v1`
- `bump_food_catalog_popularity_v1`
- `search_menu_items_v1`
- `pick_one_menu_item_v1`
- `get_menu_item_context_v1`
- `set_menu_item_price_vote_v2`
- `create_price_alert_v1`
- `list_my_alerts_v1`
- `list_my_alert_events_v1`
- `get_business_reviews_v2`
- `submit_review_v1`
- `submit_review_v2`
- `get_my_suspended_claims_v1`
- `get_my_suspended_claim_badge_v1`
- `submit_business_suggestion`
- `submit_business_suggestion_v2`
- `submit_menu_item_suggestion_v2`
- `submit_menu_item_price_suggestion_v5`
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
- `uygulamalar/mobil/lib/features/menus/data/menu_deposu.dart`
- `uygulamalar/mobil/lib/features/profil/data/profil_deposu.dart`
- `uygulamalar/mobil/lib/features/taste_twin/data/taste_twin_deposu.dart`

### 4.4 RLS Gereksinimleri

Koddan cikan muhtemel RLS siniflari:

- Public read beklenenler:
  - `businesses_with_stats`, `businesses`, `menus`, `menu_items`, `menu_item_variants`, `business_hours`, `embeds`in bazi akislarinda read
- Auth/user-scoped beklenenler:
  - `favorites`, `notifications`, `owner_claims`, `reports`, `review_votes`, `user_profiles`, `price_alerts`, `business_suggestions`, `temp_uploads`
- Owner/admin scoped olmasi gereken ama mobilde tuketilen yardimci akislar:
  - `owner_update_business_amenities_v1`

Bu siniflandirma koddan cikan inferanstir; RLS dogrulamasi icin Supabase policy audit gerekir.

### 4.5 Storage Kullanimi

- Gecici katkilar:
  - bucket: `temp`
  - path: `temp_uploads/{businessId}/...`
  - tablo: `temp_uploads`
  - kanit: `uygulamalar/mobil/lib/features/katki/data/temp_uploads_deposu.dart`
- Menu / photo upload:
  - edge function: `/functions/v1/media-upload-user`
  - aktif adapter: `uygulamalar/mobil/lib/core/media/media_upload_client_io.dart`, `media_upload_client_web.dart`
  - Bu katman storage detayini dogrudan expose etmiyor ama backend upload kontratina bagli.

## 5) Veri Akisi / Cache / Offline

### 5.1 Mevcut Durum

- In-memory TTL cache var. Kanit: `uygulamalar/mobil/lib/core/cache/ttl_memory_cache.dart`
- `SharedPreferences` tabanli disk cache var. Kanit: `uygulamalar/mobil/lib/core/storage/offline_cache_prefs.dart`
- bucket bazli SQLite local DB var. Kanit: `uygulamalar/mobil/lib/core/storage/yerel_db/sqflite_yerel_db_deposu.dart`
- Saklanan ana veri tipleri:
  - discovery feed
  - recent businesses
  - business detail
  - business menus
  - menu sections
  - menu items
  - favorites snapshot
  - categories snapshot
- Offline queue verify / suggestion + submission draft katmanlariyla genisledi. Kanit: `uygulamalar/mobil/lib/features/menus/data/offline_verify_queue.dart`, `uygulamalar/mobil/lib/core/storage/offline_submission_queue.dart`
- Genel unified mutation queue var ve verify/submission write'lari ayni bucket'ta tutuluyor.
- Lokal veritabani `sqflite` ile bucket store seviyesinde devrede; cekirdek katki write'larinda explicit server-side idempotency var, `favorite`, `price vote`, `follow` ve `photo vote` desired-state idempotency'ye tasindi, action-bazli retry/backoff ve devtools queue diagnostics + panel observability operator gorunurlugu sagliyor; ancak entity-level tablo ve daha kenar interaction write'lar tamamlanmadi.

### 5.2 Riskler

- Kullanici menu/business akisini kismi offline gorur, ama mutation'lar genis kapsamda korunmaz.
- Cache invalidation merkezi degil; feature bazli tutuluyor.
- `SharedPreferences` JSON cache buyudukce schema degisikligine karsi kirilgan olur.
- Offline queue sadece dar bir alani kapsadigi icin "katki yapip sonra gonder" deneyimi genellesmez.

### 5.3 Minimum Viable Offline Plani

1. Son gorulen `business detail + menu + item summary` kombinasyonunu version'li disk cache olarak sakla.
2. Discovery sonucunda ilk 20 business ozetini TTL ile tut ve stale badge goster.
3. `favorites`, `price alerts`, `profile stats` icin "last known state" gosterimi ekle.
4. Offline mutation queue'yu en az `report`, `review draft`, `business suggestion draft` seviyesine genislet.
5. Queue item'larina retry/backoff ve "pending sync" etiketi ekle.
6. Uzun vadede `SharedPreferences` yerine dogru bir lokal store dusun: `Drift` veya `Isar`.

## 6) Performans Incelemesi

### 6.1 Gozlenen Agir Noktalar

- `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
  - 178 KB civari, birden cok sliver, sponsored section, search, filters ve home feed mantigi ayni dosyada.
- `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
  - 88 KB civari, photo carousel, verify/report/history/value score ve prefetch akisi ayni sayfada.
- `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
  - 73 KB civari, business summary, review snippet, amenities, trends, reports, share, crowd verisi ayni yerde.
- `uygulamalar/mobil/lib/features/yerlestir/ui/yerlestir_viewer_page.dart`
  - `webview_flutter` + `youtube_player_iframe` tek dosyada yukleniyor.
- `uygulamalar/mobil/lib/features/menus/ui/menu_ocr_flow.dart`
  - `google_ml_kit` + `image_picker` + upload + OCR match akisi agir.

### 6.2 Mevcut Artılar

- Discovery sayfasi `CustomScrollView` / `SliverList` kullaniyor. Kanit: `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
- Ozel image cache manager var. Kanit: `uygulamalar/mobil/lib/core/media/app_image_cache_manager.dart`
- `precacheImageUrls` kullanim izleri var. Kanit: `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
- Firebase Performance ve app telemetry entegre. Kanit: `uygulamalar/mobil/lib/core/perf/firebase_perf_trace.dart`, `uygulamalar/mobil/lib/core/monitoring/app_telemetry.dart`

### 6.3 Riskler

- Buyuk ekran dosyalari widget ayrisma, rebuild sinirlama ve state izolasyonu acisindan zayif.
- `cached_network_image` kullanimi secici; tum kritik image yuzeyleri ortak cache manager kullanmiyor.
- Search/kesify/business arasi request coalescing ve merkezi cache katmani yok.
- Embed ve OCR gibi agir akislar acik aksiyonla tetiklense de kod parcasi uygulama icinde tek bundle seviyesinde kalir.
- App shell ve bazi ortak yuzeylerde token-disi hard-coded spacing/style kullanim devam ediyor.

### 6.4 Somut Oneriler

1. `discovery_page.dart` ekranini en az 4 alt surface'e bol.
   - Etki: HIGH
   - Dosya: `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
2. `business_page.dart` icindeki sections'i ayri ConsumerWidget siniflarina parcala; reviews, perks, crowd ve report alanlarini lazy render et.
   - Etki: HIGH
   - Dosya: `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
3. `menu_item_page.dart` icin tab/section bazli widget ayrisma yap; photo/history/value score kartlarini ayri provider ile izole et.
   - Etki: HIGH
   - Dosya: `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
4. `embed_viewer_page.dart` icinde provider secimini sertlestir; YouTube ve WebView controller init'ini buton/URL turune gore gec baslat.
   - Durum: P2 baslangic adimi tamamlandi (URL-provider bazli ayristirma + controller lifecycle izolasyonu).
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/features/yerlestir/ui/yerlestir_viewer_page.dart`
   - Ek dosyalar:
     - `uygulamalar/mobil/lib/features/yerlestir/ui/providers/yerlestir_provider_youtube.dart`
     - `uygulamalar/mobil/lib/features/yerlestir/ui/providers/yerlestir_provider_webview.dart`
5. `menu_ocr_flow.dart` icinde OCR sonucu parse + upload + match sheet akisini servis katmanina ayir.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/features/menus/ui/menu_ocr_flow.dart`
6. `AppImageCacheManager` sabit `400` obje limitini device class veya disk butcesine gore ayarlanabilir yap.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/core/media/app_image_cache_manager.dart`
7. Business ve menu detaylarinda image prefetch'i "visible range" ile sinirla; su an sayfa icinde agresif prefetch riski var.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart`
8. Search/kesify icin merkezi request cancellation ve stale request ignore katmani ekle.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/features/kesify/data/arama_deposu.dart`, `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
9. Sponsored / ads / native ad yuzeyleri ilk layout'u bloklamamali; loading placeholder standardini merkezi hale getir.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/features/ads/data/native_ad_controller.dart`, `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart`
10. `flutter_screenutil` ile token sistemi disindaki `const EdgeInsets/SizedBox/TextStyle` kullanimlarini azalt.
   - Etki: MED
   - Dosya: `uygulamalar/mobil/lib/uygulama/uygulama_kabugu.dart`, `uygulamalar/mobil/lib/features/zincirs/ui/zincir_page.dart`, `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
11. `google_fonts` sadece splash icin kullaniliyorsa, asset font ile tek kaynaga in.
   - Etki: LOW
   - Dosya: `uygulamalar/mobil/lib/features/splash/ui/splash_page.dart`, `uygulamalar/mobil/assets/fonts/*`
12. `analytics_deposu.logEvent()` icin background queue veya batch mekanizmasi dusun; fire-and-forget tamamen sessiz kayip olusturuyor.
   - Etki: LOW
   - Dosya: `uygulamalar/mobil/lib/core/analytics/analytics_deposu.dart`

## 7) Guvenlik / Gizlilik

### 7.1 Mevcut Pozitifler

- Supabase session secure storage ile tutuluyor. Kanit: `uygulamalar/mobil/lib/core/security/secure_local_storage.dart`
- Critical action guard var. Kanit: `uygulamalar/mobil/lib/core/security/critical_action_guard.dart`
- Edge rate limit guard var. Kanit: `uygulamalar/mobil/lib/core/security/edge_rate_limit_guard.dart`
- Write gatekeeper client var. Kanit: `uygulamalar/mobil/lib/core/security/write_gatekeeper_client.dart`
- Crashlytics ve Performance aktif. Kanit: `uygulamalar/mobil/lib/uygulama_girisi.dart`, `uygulamalar/mobil/lib/core/perf/firebase_perf_trace.dart`

### 7.2 Riskler

- Android release artik debug signing'e dusmuyor; fakat prod secret/keystore baglantisi kurulmadan release alinmaz. `flutter build apk --release -t lib/mobil_giris.dart` bu ortamda tam da bu nedenle fail etti.
  - Risk: HIGH
  - Kanit: `uygulamalar/mobil/android/uygulama/build.gradle.kts`, `uygulamalar/mobil/android/key.properties.example`
- Genel retry/backoff politikasi merkezi degil.
  - Risk: MED
  - Kanit: repo taramasinda merkezi `backoff` katmani gozlenmedi; rate limit guard var ama retry politikasi yok.
- `analytics_deposu.logEvent()` hatalari yutuyor; audit/telemetry kaybi sessiz olabilir.
  - Risk: MED
  - Kanit: `uygulamalar/mobil/lib/core/analytics/analytics_deposu.dart`
- Push service platform kararinda `kIsWeb ? 'web'` branch'i duruyor; product scope mobil oldugu icin gereksiz genislik ve yanlis kayit ihtimali yaratabilir.
  - Risk: LOW
  - Kanit: `uygulamalar/mobil/lib/features/notifications/domain/push_notification_service.dart`
- OCR / upload / report gibi write akislarinda PII veya raw error metinleri merkezi scrub politikasina bagli degil.
  - Risk: MED
  - Kanit: `uygulamalar/mobil/lib/core/errors/app_error_mapper.dart`, `uygulamalar/mobil/lib/core/media/media_upload_client_io.dart`

### 7.3 Gizlilik Notu

- Analytics ve telemetry var; ama tek kaynakli "hangi event hangi meta ile gidiyor" dokumani yok.
- `clientId`, `user_id`, `business_id` event meta'ya eklenebiliyor.
- Bu blocker degil, ama contract dokumani yoksa veri yonetimi riskli.

## 8) UI / Design System Uyumu

### 8.1 Source of Truth

- `uygulamalar/mobil/lib/uygulama/tema/renkler.dart`
- `uygulamalar/mobil/lib/uygulama/tema/uygulama_tokenleri.dart`
- `uygulamalar/mobil/lib/uygulama/tema/uygulama_tipografisi.dart`
- `uygulamalar/mobil/lib/uygulama/tema/uygulama_temasi.dart`

### 8.2 Uyum Durumu

- Tema temeli guclu.
- `ScreenUtilInit` ve token extension kullanimi mevcut. Kanit: `uygulamalar/mobil/lib/uygulama/uygulama.dart`, `uygulamalar/mobil/lib/uygulama/tema/uygulama_temasi.dart`
- Web tarafinin token esleme belgesi bile mobile theme'yi source-of-truth kabul ediyor. Kanit: `docs/ui-style.md`

### 8.3 Token Disi Kullanimin Kaniti

Ornekler:

- `uygulamalar/mobil/lib/uygulama/uygulama_kabugu.dart`
- `uygulamalar/mobil/lib/features/zincirs/ui/zincir_page.dart`
- `uygulamalar/mobil/lib/features/business/ui/business_page.dart`
- `uygulamalar/mobil/lib/features/ads/ui/native_ad_card.dart`
- `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`

Bu dosyalarda `TextStyle`, `EdgeInsets`, `SizedBox` ve benzeri hard-coded pattern'ler gozleniyor.

### 8.4 Tasarim Tutarliligi Icin Yapilacaklar

- Hard-coded spacing/text style noktalarini token uzantilarina indir.
- `shared/ui` icindeki ortak komponentleri oncele; buyuk sayfalarda yeni lokal pattern cikarilmasin.
- App shell ve router fallback yuzeylerini design system component'lerine tasi.
- Splash ekraninda asset font ile `GoogleFonts.sora` kullanimini tekle.

ARB / localization konusu:
- Secondary.
- Bu turda blocker degil.

## 9) Test / Release Readiness

### 9.1 Test Kapsami

Mevcut:

- Unit:
  - `uygulamalar/mobil/test/core/cache/ttl_memory_cache_test.dart`
  - `uygulamalar/mobil/test/core/quality/release_gate_test.dart`
  - `uygulamalar/mobil/test/core/growth/ab_experiments_test.dart`
- Contract:
  - `uygulamalar/mobil/test/core/contracts/kesify_api_contract_test.dart`
- UI quality:
  - `uygulamalar/mobil/test/ui/tasarim_sistemi_kalite_kapilari_test.dart`
- Golden:
  - `uygulamalar/mobil/test/ui/golden/basic_surfaces_golden_test.dart`
- Integration:
  - `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart`

### 9.2 Test Degerlendirmesi

- Unit ve contract coverage var; bu pozitif.
- Golden test env flag ile kapali. Kanit: `uygulamalar/mobil/test/ui/golden/basic_surfaces_golden_test.dart`
- Integration smoke gercek `YeedoyApp` router'ini ayaga kaldiriyor ve route zinciri + report sheet + review-login redirect kapsiyor. Kanit: `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart`
- Canli backend write smoke icin opt-in test eklendi: `review/report/menu price suggestion/favoriler add-remove` ve `unauth fail-path`. Kanit: `uygulamalar/mobil/integration_test/live_write_smoke_integration_test.dart`
- Gercek cihazda true FCM transport'tan gelen push tap payload -> hedef route e2e smoke halen genisletilmelidir (Android tarafinda native debug intent bridge var; iOS ve gercek FCM teslimati acigi suruyor).

### 9.3 Build / Release Durumu

- `README` ve `package.json` Android APK release akisini one cikarmaya devam ediyor.
  - Kanit: `uygulamalar/mobil/README.md`, `uygulamalar/mobil/package.json`
- Repo-root mobile CI/readiness workflow'lari ve iOS readiness dokumani artik var:
  - `.github/workflows/mobile_quality.yml`
  - `.github/workflows/mobile_readiness.yml`
  - `uygulamalar/mobil/tool/ios_readiness_check.dart`
  - `docs/mobil-ci-ios-hazirlik.md`
- Repo-root panel/web workflow omurgasi da artik var:
  - `.github/workflows/panel_quality.yml`
  - `.github/workflows/web_quality.yml`
- Panel integration smoke hedefi `chrome` cihazina alinmis; owner shell, owner businesses, owner business submissions, owner new business submit, owner menus, owner menu editor, owner trash, owner trash restore, owner onboarding, owner requests, owner suspended, owner activity, owner analytics, owner audit alias, owner growth, owner growth lead submit, owner team, owner price suggestions, admin dashboard, admin login redirect, admin search, admin queue, admin reports, admin businesses, admin receipt submissions ve admin observability browser smoke ayni Playwright suite'inde toplanmistir. Owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, queue assign, reports assign ve observability calibration save aksiyonlari da browser seviyesinde dogrulanir; son dogrulama `30 passed` olarak alinmistir.
- Flavor/stage/prod ayrimi kaniti yok.
- Android release signing artik debug key'e dusmuyor; blocker gercek keystore ve `android/key.properties` yoklugu.
- iOS tarafinda release readiness artik iskelet olarak dokumansiz degil; `Podfile`, entitlements, export template ve push capability kanitlari repo icinde var. Signed release secret modeli ve `ios_release_dry_run` workflow job'u da eklendi; workflow artik `ios_signing_check.dart` ile placeholder/format/base64 audit'i, `ios_signing_assets_check.dart` ile decoded provisioning profile + export options + `Runner.entitlements` uyumunu denetleyip export method'e gore `aps-environment` degerini normalize eder, basarili kosumda IPA artifact'ini yukler. Kalan ana risk gercek secret/provisioning materyali ve gercek cihaz smoke.

### 9.4 Release Blocker Listesi

- HIGH: Android release keystore secret'lari ortama baglanmamis olabilir
  - `uygulamalar/mobil/android/uygulama/build.gradle.kts`
  - `uygulamalar/mobil/android/key.properties.example`
- HIGH: Gercek cihazda true FCM transport'tan gelen push tap payload dahil tam e2e smoke henuz yok
  - `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart`
  - `uygulamalar/mobil/integration_test/live_write_smoke_integration_test.dart`
- MED: Stage/prod flavor yok
  - `uygulamalar/mobil/package.json`, `uygulamalar/mobil/android/uygulama/build.gradle.kts`
- MED: iOS signing/readiness omurgasi acildi; kalan bosluk signed release ve cihaz matrisi
  - `docs/mobil-ci-ios-hazirlik.md`
  - `uygulamalar/mobil/tool/ios_readiness_check.dart`

### 9.5 Release Notes Formati Onerisi

- Surum
- Commit / tag
- Platformlar: Android / iOS
- DB / RPC dependency notu
- Feature flags
- Known risks
- Rollback notu
- Smoke steps sonucu

## 10) Docs Hizalama Plani (docs/ ile)

### 10.1 Mevcut Mobile Referanslari Olan Dokumanlar

- `docs/apps.md`
- `docs/architecture.md`
- `docs/veri-modeli.md`
- `docs/devtools.md`
- `docs/module_visibility_matrix.md`
- `docs/product.md`
- `docs/setup.md`
- `docs/ui-style.md`
- `docs/vision_status.md`

### 10.2 Eksik Olan Tek Kaynak Dokumanlar

Kesin eklenmeli:

- `docs/mobile_architecture.md`
  - router, shell, auth, offline, telemetry, panel/web_next siniri
- `docs/mobile_features_matrix.md`
  - MVP / V2 / deneysel / panelde kalmali ayrimi
- `docs/mobil-release-kontrol-listesi.md`
  - Android/iOS signing, smoke, Crashlytics, push, env, rollback
- `docs/mobil-supabase-kontratlari.md`
  - mobile'in kullandigi tablolar, RPC'ler, storage yolları, auth/RLS beklentisi

### 10.3 Guncellenmesi Gereken Mevcut Dokumanlar

| Dosya | Ne eklenmeli / duzeltilmeli |
|---|---|
| `docs/apps.md` | mobile tarafinda owner/admin olmadigi daha net yazilmali |
| `docs/architecture.md` | mobile offline/cache, push, telemetry ve panel handoff siniri eklenmeli |
| `docs/veri-modeli.md` | mobile'in gercek RPC listesi ve write/read ayrimi eklenmeli |
| `docs/setup.md` | Android + iOS local run/build + env + signing prerequisites ayrilmali |
| `docs/ui-style.md` | mobile icinde token-disi kullanim temizleme backlog'u not edilmeli |
| `docs/operasyon-kilavuzu.md` | mobile release smoke adimlari panel/web ayri sekilde eklenmeli |
| `docs/devtools.md` | mobile devtools ekraninin scope'u ve prod disi kural netlestirilmeli |
| `docs/mobil-test-stratejisi.md` | integration/golden/contract/load test kapsami guncel tutulmali |

### 10.4 Docs -> Code Drift

Mobil acisindan en onemli drift'ler:

- Release checklist / test strategy / setup dosyalari artik mevcut; kod degistikce ayni sprintte guncellenmezse tekrar drift olusur.
- Signing secret kaynagi (key.properties vs env) ile gercek release pipeline sozlesmesi dokumanda ayni kalmalidir.
- Canli backend write smoke komutu ve gerekli `LIVE_*` dart-define'lari tek formatta tutulmalidir.

## 11) Net Aksiyon Listesi (Sprint Plan)

### P0 (1 hafta)

| Aksiyon | Etki | Zorluk | Ilgili dosya/klasor |
|---|---|---|---|
| Gercek Android keystore secret'larini bagla ve `assembleRelease` dogrulamasini gec | HIGH | M | `uygulamalar/mobil/android/uygulama/build.gradle.kts`, `uygulamalar/mobil/android/key.properties` |
| Gercek mobile smoke test yaz: splash -> login -> discovery -> business -> menu -> review/report | HIGH | M | `uygulamalar/mobil/integration_test/*` |
| `mobil-release-kontrol-listesi.md` olustur | HIGH | S | `docs/mobil-release-kontrol-listesi.md` |
| `mobil-supabase-kontratlari.md` olustur | HIGH | M | `docs/mobil-supabase-kontratlari.md` |
| Gercek business/menu/review write smoke'unu emulator/device uzerinde genislet | HIGH | M | `uygulamalar/mobil/integration_test/golden_paths_integration_test.dart` |

P0 durum notu (2026-03-05):

- Android signing:
  - `build.gradle.kts` env-secret akisini da destekliyor (`ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`).
  - `assembleRelease` secret eksiginde bilincli olarak fail edip zorunlu anahtarlari acikca yaziyor.
- Smoke:
  - `golden_paths_integration_test.dart` route zinciri + report sheet + review submit-login redirect smoke kapsamina genislendi.
  - `live_write_smoke_integration_test.dart` eklendi (opt-in): gercek backend review/report/menu/favoriler write + unauth fail-path.
- Dokuman:
  - `docs/mobil-release-kontrol-listesi.md`, `docs/mobil-test-stratejisi.md`, `docs/setup.md`, `uygulamalar/mobil/README.md` ilgili akislara gore guncellendi.

### P1 (2-4 hafta)

| Aksiyon | Etki | Zorluk | Ilgili dosya/klasor |
|---|---|---|---|
| `discovery_page.dart` ekranini alt surface'lere bol | HIGH | L | `uygulamalar/mobil/lib/features/kesify/ui/kesify_page.dart` |
| `business_page.dart` ekranini section bazli ayir | HIGH | L | `uygulamalar/mobil/lib/features/business/ui/business_page.dart` |
| `menu_item_page.dart` ekranini tab/section bazli ayir | HIGH | L | `uygulamalar/mobil/lib/features/menus/ui/menu_item_page.dart` |
| Merkezi request caching / invalidation katmani kur | HIGH | M | `uygulamalar/mobil/lib/core/cache/*`, `features/*/data/*` |
| Offline queue'yu report/review/oneriion draft icin genislet | HIGH | M | `uygulamalar/mobil/lib/features/*/data/*` |
| Mobile architecture dokumani yaz | MED | S | `docs/mobile_architecture.md` |
| Features matrix yaz ve MVP/V2 ayrimini netlestir | MED | S | `docs/mobile_features_matrix.md` |
| Push token lifecycle ve platform kaydini daralt | MED | S | `uygulamalar/mobil/lib/features/notifications/domain/push_notification_service.dart` |
| `analytics_deposu` icin daha guvenilir retry/batch tasarla | MED | M | `uygulamalar/mobil/lib/core/analytics/analytics_deposu.dart` |
| Token-disi design usage cleanup backlog'unu baslat | MED | M | `uygulamalar/mobil/lib/uygulama/uygulama_kabugu.dart`, `uygulamalar/mobil/lib/features/business/ui/business_page.dart` |

P1 hizli ilerleme notu (2026-03-05):

- `push_notification_service.dart` icinde token register/unregister sadece `android/ios` icin calisacak sekilde daraltildi.
- Mobil-disi platform branch'lerinin push kaydi yapmasi engellendi.
- Merkezi request cache/invalidation adimi tamamlandi:
  - `core/cache/request_cache.dart` eklendi
  - discovery/arama/menu deposu'leri ortak cache scope mekanizmasina tasindi
  - `search_deposu.clearCache()` + `discovery_search_notifier.refresh()` ile pull-to-refresh cache bypass akisi eklendi
  - `discovery_deposu.getBusiness()` TTL cache + explicit invalidate destegi aldi
  - `menu_deposu.clearReadCache()` eklendi ve business refresh akisina baglandi
- Discovery ekran ayristirma adimi baslatildi:
  - `discovery_page.dart` icindeki campaign/map/insight surface'leri ayri dosyalara tasindi:
    - `features/kesify/ui/surfaces/kesify_campaigns_tab.dart`
    - `features/kesify/ui/surfaces/kesify_map_surface.dart`
    - `features/kesify/ui/surfaces/kesify_insight_sections.dart`
  - Ana dosya satir sayisi `4527 -> 4049` seviyesine dusuruldu; sonraki adim `business_page.dart` ve `menu_item_page.dart` ayristirmasi.
- Business ekran ayristirma adimi baslatildi:
  - `business_page.dart` icindeki header/actions/trust/hours/menus/crowd/reviews/avantajlar/footer section siniflari ayri dosyaya tasindi:
    - `features/business/ui/sections/business_detail_sections.dart`
  - Ana dosya satir sayisi `2225 -> 1549` seviyesine dusuruldu; sonraki adim `menu_item_page.dart` ayristirmasi.
- Menu item ekran ayristirma adimi baslatildi:
  - `menu_item_page.dart` icindeki price history/status/value/photos section bloklari ayri dosyaya tasindi:
    - `features/menus/ui/sections/menu_item_detail_sections.dart`
  - Suggestion/catalog sheet bloklari da ayri dosyaya tasindi:
    - `features/menus/ui/sections/menu_item_suggestion_sections.dart`
  - Ana body/cart/skeleton bloklari da ayri dosyaya tasindi:
    - `features/menus/ui/sections/menu_item_core_sections.dart`
  - Ana dosya satir sayisi `2786 -> 250` seviyesine dusuruldu.
- Analytics deposu guvenilirlik adimi tamamlandi:
  - `core/analytics/analytics_deposu.dart` icine in-memory queue + retry/backoff + batch flush eklendi.
  - `logEvent` API'si korunarak basarisiz event'lerin yeniden gonderim denemesi merkezi hale getirildi.
  - `test/core/analytics/analytics_deposu_test.dart` ile kuyruklama, drop ve meta birlestirme davranislari test altina alindi.
- Offline queue genisletme adimi tamamlandi:
  - `core/storage/offline_submission_queue.dart` eklendi.
  - report/review/business suggestion write'lari offline durumda queue'ya alinacak sekilde guncellendi:
    - `features/business/data/report_deposu.dart`
    - `features/reviews/data/reviews_deposu.dart`
    - `features/oneriler/data/oneriler_deposu.dart`
  - UI tarafinda offline queue sonucu icin geri bildirim eklendi:
    - `features/shared/ui/widgets/report_bottom_sheet.dart`
    - `features/reviews/ui/review_create_page.dart`
    - `features/oneriler/ui/oneri_business_page.dart`
  - `test/core/storage/offline_submission_queue_test.dart` ile queue/flush davranislari test altina alindi.
- Mobile devtools queue operasyon adimi tamamlandi:
  - `features/devtools/ui/developer_tools_page.dart` icinde `Offline Queues` karti eklendi.
  - verify queue + submission queue sayilari anlik gosteriliyor ve tek tek/all flush aksiyonlari var.
  - flush sonrasi queue count provider'lari invalidate edilip kullaniciya snackbar geri bildirimi veriliyor.
- Token-disi design cleanup backlog'u baslatildi:
  - `uygulama/uygulama_kabugu.dart` icinde app bar title style tema tipografisine baglandi.
  - location pill spacing degerleri `AppTokens` uzerinden alinacak sekilde duzenlendi.
  - `features/business/ui/business_page.dart` icinde secili spacing/radius/padding noktalarinda `AppTokens` kullanimina gecildi.
  - `features/zincirs/ui/zincir_page.dart` icinde spacing/typography kullanimlari `AppTokens` + theme extension uzerine tasindi.

P1 checklist durum ozeti (2026-03-05):

| P1 Aksiyonu | Durum |
|---|---|
| `discovery_page.dart` ekranini alt surface'lere bol | Tamam |
| `business_page.dart` ekranini section bazli ayir | Tamam |
| `menu_item_page.dart` ekranini tab/section bazli ayir | Tamam |
| Merkezi request caching / invalidation katmani kur | Tamam |
| Offline queue'yu report/review/oneriion draft icin genislet | Tamam |
| Mobile architecture dokumani yaz | Tamam |
| Features matrix yaz ve MVP/V2 ayrimini netlestir | Tamam |
| Push token lifecycle ve platform kaydini daralt | Tamam |
| `analytics_deposu` icin daha guvenilir retry/batch tasarla | Tamam |
| Token-disi design usage cleanup backlog'unu baslat | Tamam |

### P2 (1-2 ay)

| Aksiyon | Etki | Zorluk | Ilgili dosya/klasor |
|---|---|---|---|
| Lokal DB tabanli gercek offline mode degerlendirmesi yap | HIGH | L | `uygulamalar/mobil/lib/core/storage/*` |
| Embed akislarini URL-provider bazli daha hafif hale getir | MED | M | `uygulamalar/mobil/lib/features/yerlestir/ui/yerlestir_viewer_page.dart` |
| OCR/upload akislarini servis ve queue mimarisine tasi | MED | L | `uygulamalar/mobil/lib/features/menus/ui/menu_ocr_flow.dart` |
| Native ads ve sponsorlu kesif icin performans/biz logic ayristirmasi yap | MED | M | `uygulamalar/mobil/lib/features/ads/*`, `discovery/*` |
| Search / discovery telemetry dashboard sozlesmesini yaz | MED | M | `uygulamalar/mobil/lib/core/monitoring/*` |
| Image cache policy'yi cihaz profiline gore optimize et | LOW | M | `uygulamalar/mobil/lib/core/media/app_image_cache_manager.dart` |
| `google_fonts` / asset font overlap'ini temizle | LOW | S | `uygulamalar/mobil/lib/features/splash/ui/splash_page.dart` |
| Mobile release pipeline'i CI ile standartlastir | HIGH | L | repo ops/CI |

P2 hizli ilerleme notu (2026-03-05):

- Embed akisi URL-provider bazli alt surface'lere ayrildi:
  - `features/yerlestir/ui/providers/yerlestir_provider_youtube.dart`
  - `features/yerlestir/ui/providers/yerlestir_provider_webview.dart`
- `embed_viewer_page.dart` icinde provider kararina gore render secimi sadeleştirildi; unknown provider dogrudan browser fallback, YouTube ve WebView lifecycle'i ayri widgetlarda yonetiliyor.
- Embed hardening adimi tamamlandi:
  - invalid URL ve invalid YouTube source icin widget testleri eklendi:
    - `test/features/yerlestir/ui/yerlestir_viewer_page_test.dart`
  - invalid URL fallback integration smoke eklendi:
    - `integration_test/yerlestir_smoke_integration_test.dart`
  - release gate metriklerine `embed_open_p95_ms` eklendi:
    - `lib/core/quality/release_gate.dart`
    - `tool/release_gate_check.dart`
  - lokal dry-run icin ornek metrik dosyasi eklendi:
    - `tool/release_gate_metrics_example.json`
    - komut: `dart run tool/release_gate_check.dart tool/release_gate_metrics_example.json`
- `test/core/linking/link_utils_test.dart` eklendi; normalize/provider/decision davranislari test altina alindi.
- Image cache policy adimi baslatildi:
  - `core/media/app_image_cache_manager.dart` profile-bazli policy (compact/balanced/aggressive) yapisina tasindi
  - `IMAGE_CACHE_PROFILE` dart-define override destegi eklendi
  - `test/core/media/app_image_cache_manager_test.dart` ile policy degerleri test altina alindi
- OCR servis ayristirma adimi baslatildi:
  - OCR parse/price extraction mantigi `features/menus/data/ocr_price_extractor.dart` dosyasina tasindi
  - `menu_ocr_flow.dart` UI akisinda OCR sonucu bu servis uzerinden kullaniliyor
  - `test/features/menus/data/ocr_price_extractor_test.dart` ile fiyat parse kurallari test altina alindi
- Native ads + sponsored discovery ayristirma adimi baslatildi:
  - ad insertion kurali `features/kesify/domain/kesify_feed_composer.dart` icine tasindi
  - discovery UI icinde ad slot karari composer uzerinden veriliyor (`shouldInsertDiscoveryAdAfterBusiness`)
  - sponsored query parametreleri `sponsoredDiscoveryParams(...)` helper'inda tek kaynaga toplandi
  - testler eklendi:
    - `test/features/kesify/domain/kesify_feed_composer_test.dart`
    - `test/features/monetization/domain/sponsored_businesses_provider_test.dart`
- Search/kesify telemetry dashboard sozlesmesi yazildi:
  - `docs/mobil-kesif-telemetri-kontrati.md` olusturuldu
  - event/source/meta + SLO + panel + alarm kurallari tek dokumanda toplandi
- Lokal DB tabanli offline mode degerlendirme + skeleton eklendi:
  - `docs/mobil-yerel-db-offline-plani.md` olusturuldu (faz/migration/risk plani)
  - core abstraction + memory adapter eklendi:
    - `core/storage/yerel_db/yerel_db_modelleri.dart`
    - `core/storage/yerel_db/yerel_db_deposu.dart`
    - `core/storage/yerel_db/bellek_yerel_db_deposu.dart`
    - `core/storage/yerel_db/yerel_db_saglayicisi.dart`
  - `test/core/storage/yerel_db/bellek_yerel_db_deposu_test.dart` ile temel davranislar test altina alindi
- Lokal DB / replay adimi ilerletildi:
  - `core/storage/yerel_db/paylasilan_tercihler_yerel_db_deposu.dart` ile disk-backed gecis adapter'i devreye alindi
  - `discovery`, `business detail`, `business menus`, `menu sections`, `menu items` read path'leri ortak snapshot store'a write-through + fallback baglandi
  - `core/storage/offline_sync_service.dart` ile verify/submission queue replay + expired snapshot prune app root foreground/resume tetigine alindi
  - `DeveloperToolsPage` snapshot count + prune aksiyonlari ile guncellendi
- Lokal DB / replay adimi sertlestirildi:
  - `core/storage/yerel_db/sqflite_yerel_db_deposu.dart` ile SQLite tabanli bucket tablolar devreye alindi
  - `core/storage/yerel_db/yerel_db_saglayicisi.dart` Android/iOS tarafinda SQLite, web/init-failure durumunda shared-prefs fallback kullanacak sekilde guncellendi
  - `core/network/connectivity_restore_service.dart` ile offline -> online probe ve replay tetigi eklendi
- `core/monitoring/app_telemetry.dart` + `core/analytics/app_events.dart` icinde `offline_sync_run`, `offline_mutation_outcome`, `connectivity_restored`, `connectivity_state_change` eventleri eklendi
- Unified mutation queue adimi devreye alindi:
  - `core/storage/offline_mutation_queue.dart` ile verify/submission kayitlari ortak `offlineMutationQueue` bucket'ina tasindi
  - replay sirasinda retry metadata (`retry_count`, `last_error`, `next_retry_at`) tutulmaya baslandi
  - hata siniflandirma temel olarak `retry`, `resolve-conflict`, `drop` kararlarina ayrildi
- Action-bazli idempotency standardi devreye alindi:
  - `core/storage/offline_mutation_idempotency.dart` ile deterministic `idempotency_key` + `payload_hash` uretiliyor
  - ayni logical payload tekrar queue'lanirsa yeni item acmak yerine mevcut kayit upsert ediliyor
  - `submit_menu_item_price_suggestion_v3` icin `client_id` otomatik dolduruluyor
- Server-side idempotency adoption'i genisletildi:
  - `supabase/migrations/20260325000004_review_report_idempotency_v1.sql` ile `client_mutation_idempotency_keys` tablosu eklendi
  - mobile artik `submit_review_v2` ve `submit_report_v2` uzerinden `p_idempotency_key` gonderiyor
  - `supabase/migrations/20260325000005_business_suggestion_idempotency_v1.sql` ile `submit_business_suggestion_v2` eklendi
  - mobile artik `submit_business_suggestion_v2` uzerinden de `p_idempotency_key` gonderiyor
- `supabase/migrations/20260325000007_menu_suggestion_idempotency_v1.sql` ile `submit_menu_item_suggestion_v2` ve `submit_menu_item_price_suggestion_v5` eklendi
- mobile artik menu suggestion ve menu price suggestion write'larinda da explicit `p_idempotency_key` gonderiyor
- `supabase/migrations/20260325000008_secondary_interaction_idempotency_v1.sql` ile `set_favorite_v2` ve `set_menu_item_price_vote_v2` eklendi
- mobile artik favorite ve price vote write'larinda da desired-state `p_idempotency_key` semantigi kullanuyor
- `supabase/migrations/20260325000009_follow_and_photo_vote_idempotency_v1.sql` ile `set_follow_v2` ve `set_menu_item_photo_vote_v2` eklendi
- mobile artik follow ve photo vote write'larinda da desired-state `p_idempotency_key` semantigi kullanıyor
- `supabase/migrations/20260325000011_price_alert_idempotency_v1.sql` ile `create_price_alert_v2` eklendi
- mobile artik price alert create write'larinda da explicit `p_idempotency_key` gonderiyor
- `supabase/migrations/20260325000012_group_offer_vote_and_presence_idempotency_v1.sql` ile `set_group_offer_vote_v2` ve `submit_presence_v2` eklendi
- mobile artik group offer vote ve presence submit write'larinda da explicit `p_idempotency_key` gonderiyor
- Devtools operator gorunurlugu genisletildi:
  - `DeveloperToolsPage` offline queue karti artik sadece count degil, retry/pending/bloklu ozetleri, top retry reasons, conflict policy, suggested action ve attention item listesi gosteriyor
  - `core/storage/offline_queue_diagnostics.dart` ile unified queue kayitlari operator okunabilir ozetlere indirgeniyor
  - `test/core/storage/offline_queue_diagnostics_test.dart` ile bucket'larin ve item onceliklendirmesinin dogrulugu kapsandi
- Panel operator gorunurlugu eklendi:
  - `supabase/migrations/20260325000010_admin_offline_mutation_observability_v1.sql` ile `admin_list_offline_mutation_outcomes_v1` RPC'si eklendi
  - `AdminObservabilityPage` artik `offline_mutation_outcome` event'lerini pencere bazli (`6h/24h/72h`) disposition, retry-category ve attention item gorunurlugu ile sunuyor
  - health summary karti retry/drop rate ve auth/server hotspot esiklerini (`15%/35%`, `8%/15%`, `>=3`) operatora acik hale getiriyor
- Retry/backoff policy action bazli hale getirildi:
  - `core/storage/offline_mutation_queue.dart` icinde network/auth/rate-limit/server siniflari ayrildi
  - verify vote, price suggestion ve submission write'lari farkli base/max pencereleri kullanir
  - `docs/operasyon-kilavuzu.md` icinde operator recovery akisi yazildi
- Deneysel/kismi akislarda request-cache hardening adimi tamamlandi:
  - deposu rollout: `smart_feed`, `taste_twin`, `gourmets`, `group_requests`, `suspended_meals`, `budget_combos`
  - force refresh baglantilari: `smart_feed_page`, `taste_twin_page`, `gourmets/takip/akis`, `group_requests`
  - follow/group mutation sonrasinda ilgili cache scope'lar invalidate edilip stale response riski azaltildi
- Runtime feature-flag rollout adimi tamamlandi:
  - router/shell/nav/drawer `FeatureFlags` static sabitleri yerine `featureFlagsProvider` state'i ile calisiyor
  - `golden_paths_integration_test.dart` icine feed/labs gate smoke senaryolari eklendi
- Deep-link/QR route smoke adimi genisletildi:
  - parse mantigi testlenebilir helper'a tasindi: `lib/core/linking/yeedoy_route_resolver.dart`
  - unit coverage eklendi: `test/core/linking/yeedoy_route_resolver_test.dart`
  - `golden_paths_integration_test.dart` icine `/menu/:menuId?src=qr` route smoke eklendi ve 2026-03-06'da gercek Android cihazda dogrulandi
- Push tap route handling adimi genisletildi:
  - push service `onMessageOpenedApp` + `getInitialMessage` ile route intent uretir: `lib/features/notifications/domain/push_notification_service.dart`
  - `inbox_deposu` ve push tap ayni resolver'i kullanir: `lib/features/notifications/domain/notification_target_path_resolver.dart`
  - push lifecycle + route intent listener'i app root seviyesine alindi; shell-disi rotalarda da yonlendirme kacirilmaz
  - `DeveloperToolsPage` icine payload simulator eklendi; native FCM olmadan manuel Android smoke kolaylasti
  - `MainActivity` + `android_debug_push_bridge.dart` ile `adb shell am start` tabanli native Android debug push bridge eklendi; explicit intent payload'i Flutter route intent akisina baglandi
  - `tool/android_debug_push.ps1` ile gercek cihazda `flutter run` uzerinden payload + route loglari (`[AndroidDebugPushBridge]`, `[GlobalPushIntentListener]`) dogrulandi
  - resolver unit coverage'i eklendi: `test/features/notifications/domain/notification_target_path_resolver_test.dart`
  - `golden_paths_integration_test.dart` icine devtools payload simulator smoke eklendi ve 2026-03-06'da gercek Android cihazda dogrulandi
- `google_fonts` / asset font overlap temizlendi:
  - `features/splash/ui/splash_page.dart` icinde `GoogleFonts.sora` kullanimi kaldirildi
  - uygulama tema fontu `uygulama/tema/uygulama_temasi.dart` icinde `fontFamily: 'Sora'` olarak tek kaynaga alindi
  - `pubspec.yaml` bagimliliklarindan `google_fonts` kaldirildi

## Kesin Eklenmeli Listesi

- Android + iOS gercek cihaz matrisinde true FCM transport push tap payload e2e (Android native debug bridge hazir, iOS dogrulama eksik)
- iOS signing / release runbook hardening
- Mobile release pipeline'inin panel/web ile birlikte daha merkezi hale getirilmesi
- Telemetry contract -> dashboard panel/query implementasyonu

## Mobilde Olmamali / Panelde Kalmali

- Admin queue, audit, unified moderation, impersonation
- Owner business/team/menu CRUD
- Owner trash / restore / versions
- Admin search / admin tables / admin businesses
- QR Studio / presentation settings / owner analytics operasyonlari

Kanit:
- `uygulamalar/mobil/lib/uygulama/yonlendirici.dart`
- `uygulamalar/panel_flutter_web/lib/features/admin/ui/*`
- `uygulamalar/panel_flutter_web/lib/features/owner*/*`

## Son Hukum

`uygulamalar/mobil` 2026-03-07 itibariyla audit baslangicina gore belirgin sekilde olgunlasti. P0/P1 kapsaminda signing guardrail, smoke kapsamı, dokuman seti, buyuk ekran ayristirmalari, cache/invalidation, offline queue ve devtools operasyonlari tamamlandi. P2 tarafinda da embed provider ayristirma + embed hardening (widget/integration smoke + perf gate), OCR servis ayristirma, ads/sponsored composer, telemetry contract, image cache policy, local DB skeleton, disk-backed snapshot store + foreground replay, SQLite-backed bucket store, connectivity restore replay/telemetry, deneysel/kismi akislarda request-cache hardening, runtime feature-flag rollout ve push tap intent route hardening adimlari devreye alindi.

Onceki auditteki kritik bloklarin buyuk kismi kapandi; kalan ana riskler:

1. iOS signing + gercek cihaz e2e matrisi (true FCM push tap payload + deep-link/QR iOS dahil)
2. Merkezi CI omurgasi acildi; kalan adim signed release kaniti, iOS secret/provisioning disiplini ve gercek cihaz rollout disiplini

Bu kalanlar kapaninca mobile tarafi consumer-scale production readiness seviyesine cikacaktir.




