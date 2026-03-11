# Mobile Mimari

Bu belge `apps/mobile_flutter` icin mimari tek kaynaktir. Ayrintili tablo/RPC envanteri burada tutulmaz; onun tek kaynagi `docs/mobile_supabase_contracts.md` dosyasidir.

## Kapsam

- consumer mobile uygulamasi
- router, shell, auth, telemetry, offline/cache, push
- panel ve web_next siniri

Bu belge sunlari detaylandirmaz:

- admin/owner operasyon ekranlari
- panel queue/audit/RBAC davranislari
- web_next public QR Studio detaylari

## Ust Seviye

Mobil uygulama Flutter + Riverpod + GoRouter + Supabase + Firebase kombinasyonu ile calisir.

Ana giris dosyalari:

- `apps/mobile_flutter/lib/main.dart`
- `apps/mobile_flutter/lib/main_mobile.dart`
- `apps/mobile_flutter/lib/app/router.dart`
- `apps/mobile_flutter/lib/app/app_shell.dart`
- `apps/mobile_flutter/lib/app/theme/app_theme.dart` (fontFamily tek kaynagi: `Sora`)

## Uygulama Siniri

Mobil sadece son kullanici akislarina hizmet eder:

- discovery
- business detail
- menu / item
- review / report / favorites
- profile / inbox
- contribution / QR scan
- topluluk ve feed tabanli genisleme akislar

Mobilde olmamasi gereken akislar:

- admin operasyonlari
- owner business/menu/team CRUD
- owner QR Studio
- admin audit / unified queue / impersonation

Kanit:

- `apps/mobile_flutter/lib/app/router.dart`
- `apps/panel_flutter_web/lib/features/admin/ui/*`
- `apps/panel_flutter_web/lib/features/owner*/*`

## Bootstrap

App startup sirasinda:

1. Flutter binding ayaga kalkar
2. Mobile Ads initialize edilir
3. Firebase initialize edilir
4. `.env` okunur
5. `SUPABASE_URL` ve `SUPABASE_ANON_KEY` ile Supabase client kurulur
6. secure local storage baglanir
7. Crashlytics global hata yakalama aktif edilir
8. root provider scope ile app baslatilir

Kanit:

- `apps/mobile_flutter/lib/main.dart`
- `apps/mobile_flutter/lib/core/security/secure_local_storage.dart`

## Router ve Navigasyon

Router tek kaynagi:

- `apps/mobile_flutter/lib/app/router.dart`

Feature flag kapilari:

- router redirect kurallari `featureFlagsProvider` state'ini runtime okur
- `enablePhotoFeed` ve `enableLabs` varsayilan olarak kapalidir
- `enablePhotoFeed` kapaliysa `/feed`, `/gourmets`, `/following` ve bagli rota gruplari discovery'e duser
- `enableLabs` kapaliysa labs rota grubu (`labs`, `heroes`, `taste_twin`, `group_requests`, `budget_combos`, `compare`, `my_suspended`, `chain`) discovery'e duser
- cekirdek alt navigation artik deneysel feed'e sapmaz; ana branch her zaman `/discover` olarak kalir
- deneysel yuzeyler cekirdek drawer ve discovery CTA'larindan dagitilmak yerine tek `/labs` hub altinda toplanir

Ana public / authenticated rotalar:

- `/splash`
- `/onboarding`
- `/discover`
- `/labs`
- `/feed`
- `/favorites`
- `/profile`
- `/inbox`
- `/menu/:menuId`
- `/b/:id`
- `/b/:id/menu/:menuId`
- `/b/:id/menu-item/:itemId`
- `/b/:id/reviews`
- `/b/:id/review`
- `/compare`
- `/group-requests`
- `/group-requests/new`
- `/group-requests/:id`
- `/suggest`
- `/my-suggestions`
- `/gourmets`
- `/following`
- `/taste-twin`
- `/heroes`
- `/top-businesses`
- `/my-suspended`
- `/legal`
- `/login`

Owner/admin rotalari mobilde acilmaz:

- `/owner`
- `/admin`

Bu rotalar `'/panel-web?from=...'` uzerinden panel handoff yuzeyine gider.

## Shell Yapisi

Shell dosyasi:

- `apps/mobile_flutter/lib/app/app_shell.dart`

Shell sorumluluklari:

- ust app bar
- konum secimi
- bildirim kutusu girisi
- alt navigation
- drawer
- push lifecycle watch
- runtime olarak acik deneysel yuzeyler icin tek `Labs` girisi

Not:
- Shell icinde halen token-disi hard-coded spacing/text style kullanimlari vardir.
- ilk cleanup adimi olarak app bar title ve location pill spacing `AppTokens`/theme tipografisine baglandi (`app/app_shell.dart`).
- 13.1 ayrimi sonrasi app bar ve drawer, deneysel modulleri dogrudan feed/group/taste/hero linkleri ile dagitmaz; tek `Labs` kapi rotasi kullanir.

## Auth ve Session

Auth servisi:

- `apps/mobile_flutter/lib/features/auth/data/auth_service.dart`

Session storage:

- `apps/mobile_flutter/lib/core/security/secure_local_storage.dart`

Davranis:

- Supabase auth session local olarak saklanir
- mobilde `flutter_secure_storage` kullanilir
- web fallback branch'i vardir, ama urun kapsaminda mobil one-cikar

## State Yonetimi

Temel state deseni:

- Riverpod `Provider`
- `FutureProvider`
- `NotifierProvider`
- `AsyncNotifierProvider`
- buyuk ekranlarda ek widget-level `StatefulWidget`

Bu melez yapi bugun calisiyor ama buyuk ekranlarda state parcalanmasi ihtiyaci doguruyor:

- `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`

## Data Katmani

Feature repository deseni belirgin:

- `features/*/data/*repository.dart`

Genel model:

1. UI provider repository'yi okur
2. Repository Supabase RPC veya tablo query'si yapar
3. Gerekirse memory TTL veya local prefs cache kullanir
4. UI `AsyncValue` ile sonucu render eder

Skor dili omurgasi:

- kullaniciya aciklanan puanlar artik ortak bir urun diliyle paketlenir
- ana ayrim iki katmandadir:
  - `kullanici guveni`: profildeki topluluk guveni
  - `veri guveni`: business/menu/item tarafindaki menu ve fiyat guveni
- reputation, silent quality, accuracy, freshness, consensus ve benzeri alanlar ana skor olarak degil, bu iki katmani besleyen destek sinyali veya bilgi skoru olarak aciklanir
- mobilde bu dil `CommunityScoreExplainerSheet` ve `CommunityScoreGuideCard` ile ortaklastirilmistir

Detay kontratlar:

- `docs/mobile_supabase_contracts.md`

## Offline ve Cache

Ana katmanlar:

- merkezi request cache scope'u: `apps/mobile_flutter/lib/core/cache/request_cache.dart`
- memory TTL cache: `apps/mobile_flutter/lib/core/cache/ttl_memory_cache.dart`
- disk cache: `apps/mobile_flutter/lib/core/storage/offline_cache_prefs.dart`
- verify/suggestion queue: `apps/mobile_flutter/lib/features/menus/data/offline_verify_queue.dart`
- report/review/business suggestion queue: `apps/mobile_flutter/lib/core/storage/offline_submission_queue.dart`
- ortak mutation queue store: `apps/mobile_flutter/lib/core/storage/offline_mutation_queue.dart`

Bugunku durum:

- discovery/search/menu repository'leri ortak `RequestCache` scope'u uzerinden invalidate edilebilir sekilde calisir
- deneysel V2 akislarinda da (`smart_feed`, `taste_twin`, `gourmets`, `group_requests`, `suspended_meals`, `budget_combos`) request cache + stale fallback rollout'u devrede
- read path'lerde parcali stale-while-revalidate benzeri davranis var
- cekirdek read path'lerde (`discovery`, `business detail`, `business menus`, `menu sections`, `menu items`) ortak local snapshot store'a write-through + fallback devrede
- write path'lerde menu verify disinda report/review/business suggestion draft queue mevcut
- devtools ekraninda verify/submission queue ozetleri, retry/bloklu durumlar, top error bucket'lari, suggested action ipuclari ve dikkat isteyen item listesi izlenebilir; manuel flush aksiyonlari tetiklenebilir
- app root seviyesinde `OfflineSyncService` ile verify/submission queue replay ve expired snapshot prune foreground/resume aninda tetiklenir
- `ConnectivityRestoreService` offline -> online gecisini probe ederek replay'i backoff disi zorlayabilir
- replay ve connectivity state gecisleri telemetry event'lerine raporlanir
- verify/submission wrapper'lari artik ayni `offlineMutationQueue` bucket'ina yazar; retry metadata bu kayitta tutulur
- replay hatalari `retry`, `resolve-conflict` ve `drop` olarak ayrilir
- action-bazli idempotency key standardi vardir; ayni logical payload yeniden queue'lanirsa mevcut item upsert edilir
- explicit server-side idempotency bugun `submit_review_v2`, `submit_report_v2`, `submit_business_suggestion_v2`, `submit_menu_item_price_suggestion_v5`, `submit_menu_item_suggestion_v2`, `create_price_alert_v2`, `submit_presence_v2`, `set_group_offer_vote_v2`, `set_favorite_v2`, `set_menu_item_price_vote_v2`, `set_follow_v2` ve `set_menu_item_photo_vote_v2` ile cekirdek ve kritik secondary write'larda vardir
- `create_price_alert_v1`, `submit_presence_v1`, `vote_group_offer_v1`, `toggle_favorite_v1`, `vote_menu_item_price_v1`, `toggle_follow_v1` ve `vote_menu_item_photo_v1` sadece legacy compatibility fallback olarak tutulur; kalan bosluk daha cok yeni/kenar interaction write'larin ayni standarda alinmasidir
- manual refresh akislarinda cache bypass icin explicit invalidation kullanimi var (`search_repository.clearCache`, `discovery_repository.invalidateBusiness`, `menu_repository.clearReadCache`)
- follow/group mutation'larinda ilgili cache scope'lari invalidation alir; feed/following ekranlari force-refresh ile yeniden yuklenir
- Android/iOS runtime local store'u `SqfliteLocalDbStore`, web/fallback katmani `SharedPrefsLocalDbStore` olarak calisir

Local DB P2/P2.1 durum:

- `apps/mobile_flutter/lib/core/storage/local_db/local_db_models.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/local_db_store.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/memory_local_db_store.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/shared_prefs_local_db_store.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/sqflite_local_db_store.dart`
- `apps/mobile_flutter/lib/core/storage/local_db/local_db_provider.dart`
- `apps/mobile_flutter/lib/core/storage/offline_mutation_queue.dart`
- `apps/mobile_flutter/lib/core/storage/offline_sync_service.dart`
- `apps/mobile_flutter/lib/core/network/connectivity_restore_service.dart`
- migration plani: `docs/mobile_local_db_offline_plan.md`

Devtools queue akisi:

- queue count kaynaklari:
  - `apps/mobile_flutter/lib/features/menus/data/offline_verify_queue.dart`
  - `apps/mobile_flutter/lib/core/storage/offline_submission_queue.dart`
- flush aksiyonlari:
  - verify queue: `menuRepository.flushOfflineVerifyQueue()`
  - submission queue: `flushOfflineSubmissionQueue(supabaseClient)`
- snapshot gozlemi:
  - local bucket count + prune: `DeveloperToolsPage`

## Telemetry, Analytics ve Error Handling

Analytics:

- `apps/mobile_flutter/lib/core/analytics/analytics_repository.dart`
- `apps/mobile_flutter/lib/core/analytics/analytics_client.dart`
- `analytics_repository` basarisiz `log_event_v1` cagrilarini in-memory queue'ya alir, retry/backoff ile batch flush yapar.

Telemetry:

- `apps/mobile_flutter/lib/core/monitoring/app_telemetry.dart`
- `apps/mobile_flutter/lib/core/perf/firebase_perf_trace.dart`
- discovery telemetry/dashboard kontrati: `docs/mobile_discovery_telemetry_contract.md`
- embed open telemetry: `perf_embed_open` + `embed_open_ms` eventleri `EmbedViewerPage` acilisinda olculur

Error mapping:

- `apps/mobile_flutter/lib/core/errors/app_error_mapper.dart`

Crash reporting:

- `apps/mobile_flutter/lib/main.dart`

## Push ve Inbox

Push service:

- `apps/mobile_flutter/lib/features/notifications/domain/push_notification_service.dart`

Inbox repository:

- `apps/mobile_flutter/lib/features/notifications/data/inbox_repository.dart`

Davranis:

- foreground push geldiginde inbox refresh tetiklenir
- push tap (`onMessageOpenedApp` / `getInitialMessage`) verisi `pushTapIntentProvider` uzerinden route intent'e cevrilir
- push lifecycle ve route intent listener'i app root seviyesinde calisir; shell-disi rotalarda da push yonlendirmesi kacirilmaz
- Android debug smoke icin `MainActivity` explicit debug intent payload'larini `EventChannel` ile Flutter'a aktarir; app root bu payload'lari ayni route intent akisina baglar
- device token RPC ile kaydedilir / silinir
- token kaydi yalnizca mobil platformlarda (android/ios) yapilir; mobil-disi platformlarda push register/unregister calismaz
- inbox yeni `notifications` tablosu ile legacy notification kaynaklarini birlestirir
- notification type/data -> route cozumleme tek helper'da toplanir: `apps/mobile_flutter/lib/features/notifications/domain/notification_target_path_resolver.dart`
- debug/manual smoke icin `DeveloperToolsPage` icinde push payload simulator vardir
- Android native bridge dosyalari:
  - `apps/mobile_flutter/android/app/src/main/kotlin/com/yeedoy/app/MainActivity.kt`
  - `apps/mobile_flutter/lib/features/notifications/domain/android_debug_push_bridge.dart`
  - `apps/mobile_flutter/tool/android_debug_push.ps1`

## Agir Moduller

En buyuk maliyet / bakim baskisi olusturan ekranlar:

- `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart`
- `apps/mobile_flutter/lib/features/business/ui/business_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart`
- `apps/mobile_flutter/lib/features/embed/ui/embed_viewer_page.dart`
- `apps/mobile_flutter/lib/features/menus/ui/menu_ocr_flow.dart`

Discovery ayristirma ilerlemesi:

- campaign tab surface: `apps/mobile_flutter/lib/features/discovery/ui/surfaces/discovery_campaigns_tab.dart`
- map surface: `apps/mobile_flutter/lib/features/discovery/ui/surfaces/discovery_map_surface.dart`
- insight/skeleton surface'leri: `apps/mobile_flutter/lib/features/discovery/ui/surfaces/discovery_insight_sections.dart`
- ana dosya satir sayisi ilk adimda `4527 -> 4049` seviyesine indi

Business ayristirma ilerlemesi:

- section bazli UI bloklari: `apps/mobile_flutter/lib/features/business/ui/sections/business_detail_sections.dart`
- ana dosya satir sayisi ilk adimda `2225 -> 1549` seviyesine indi
- token cleanup baslangici: `apps/mobile_flutter/lib/features/business/ui/business_page.dart` icinde secili spacing/radius/padding noktalarinda `AppTokens` kullanimina gecildi
- zincir sayfasi token cleanup adimi: `apps/mobile_flutter/lib/features/chains/ui/chain_page.dart` icinde spacing/typography noktalarinda `AppTokens` + theme extension kullanimina gecildi

Menu item ayristirma ilerlemesi:

- price/status/value/photos section bloklari: `apps/mobile_flutter/lib/features/menus/ui/sections/menu_item_detail_sections.dart`
- suggestion/catalog sheet bloklari: `apps/mobile_flutter/lib/features/menus/ui/sections/menu_item_suggestion_sections.dart`
- core body/cart/skeleton bloklari: `apps/mobile_flutter/lib/features/menus/ui/sections/menu_item_core_sections.dart`
- ana dosya satir sayisi bu asamada `2786 -> 250` seviyesine indi

Embed ayristirma ilerlemesi:

- ana karar/sayfa: `apps/mobile_flutter/lib/features/embed/ui/embed_viewer_page.dart`
- youtube provider surface: `apps/mobile_flutter/lib/features/embed/ui/providers/embed_provider_youtube.dart`
- instagram/facebook webview surface: `apps/mobile_flutter/lib/features/embed/ui/providers/embed_provider_webview.dart`
- youtube/webview controller lifecycle'lari sayfa icinden ayrilarak provider bazli widgetlara tasindi
- invalid URL fallback + youtube invalid-id fallback widget testleri eklendi:
  - `apps/mobile_flutter/test/features/embed/ui/embed_viewer_page_test.dart`
- invalid URL icin integration smoke eklendi:
  - `apps/mobile_flutter/integration_test/embed_smoke_integration_test.dart`
- release gate metrik setine `embed_open_p95_ms` eklendi:
  - `apps/mobile_flutter/lib/core/quality/release_gate.dart`
  - `apps/mobile_flutter/tool/release_gate_check.dart`

Image cache policy ilerlemesi:

- `apps/mobile_flutter/lib/core/media/app_image_cache_manager.dart` profile-bazli (`compact/balanced/aggressive`) cache policy destegi aldi
- policy override icin `IMAGE_CACHE_PROFILE` dart-define destegi eklendi

OCR akis ayristirma ilerlemesi:

- OCR parse/price extraction mantigi `apps/mobile_flutter/lib/features/menus/data/ocr_price_extractor.dart` dosyasina tasindi
- `menu_ocr_flow.dart` icindeki UI/state akisi OCR servisini tuketecek sekilde sadeleştirildi

Ads/sponsored ayristirma ilerlemesi:

- ad placement is kurali `apps/mobile_flutter/lib/features/discovery/domain/discovery_feed_composer.dart` dosyasina tasindi
- discovery feed icinde native ad slot karari bu composer uzerinden calisiyor
- sponsored discovery parametreleri `apps/mobile_flutter/lib/features/monetization/domain/sponsored_businesses_provider.dart` icindeki helper ile tek kaynaktan uretiliyor

## Panel ve Web Next ile Sinir

Mobil:

- QR scan eder
- public menu tuketir
- business share / public menu share akisini tuketir

Panel:

- owner/admin operasyonlarini yapar

Web Next:

- public QR menu render eder
- owner icin QR Studio barindirir

Teknik baglantilar:

- mobil deep link / QR parse resolver: `apps/mobile_flutter/lib/core/linking/yeedoy_route_resolver.dart`
- contribute entry entegrasyonu: `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart`
- deep-link/QR route smoke testi: `apps/mobile_flutter/integration_test/golden_paths_integration_test.dart`
- public menu share: `apps/mobile_flutter/lib/features/menus/ui/public_menu_share_page.dart`
- panel public URL uretimi: `apps/panel_flutter_web/lib/core/navigation/public_menu_url.dart`

## Mimari Kararlar

- Mobile consumer-first kalmali
- owner/admin operasyonlari mobile'a tasinmamali
- Supabase kontratlari dokumansiz genisletilmemeli
- agir ekranlar adim adim parcali hale getirilmeli
- offline "minimum viable" seviyeden tam veri senkronuna plansiz gecilmemeli
