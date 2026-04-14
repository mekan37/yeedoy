# Mobil Ozellik Matrisi

Bu belge `apps/mobile_flutter` urun kapsam matrisi icin tek kaynaktir.

Durum kolonlari:

- `Canli`: aktif ve urun akisinda var
- `Kismi`: kod var ama tam olgun degil
- `Deneysel`: v2/labs seviyesinde
- `Yok`: mobile kapsaminda bilincli olarak yok

Navigasyon karari:

- cekirdek mobil gezinme `discover`, `favorites`, `profile`, `inbox`, `menu`, `business`, `review` ve `suggest` etrafinda kalir
- deneysel yuzeyler cekirdek drawer/bottom-nav icinden dagitilmaz; runtime flag aciksa tek `Labs` hub altinda toplanir
- `enableLabs` ve `enablePhotoFeed` varsayilan olarak kapalidir; derin linkten gelen kapali deneysel rotalar `/discover`'a duser

## Cekirdek Tuketici Akislari

| Alan | Durum | Kanit | Not |
|---|---|---|---|
| Discovery | Canli | `apps/mobile_flutter/lib/features/discovery/ui/discovery_page.dart` | ana giris omurgasi |
| Business detail | Canli | `apps/mobile_flutter/lib/features/business/ui/business_page.dart` | trend, review, amenities dahil; veri guveni rehberi aktif |
| Menu | Canli | `apps/mobile_flutter/lib/features/menus/ui/menu_page.dart` | menu guncelligi ve veri guveni dili ayrildi |
| Menu item detail | Canli | `apps/mobile_flutter/lib/features/menus/ui/menu_item_page.dart` | fiyat, photo, history; price confidence veri guveni, value score bilgi skoru olarak aciklanir |
| Review create | Canli | `apps/mobile_flutter/lib/features/reviews/ui/review_create_page.dart` | |
| Review list/helpful | Canli | `apps/mobile_flutter/lib/features/reviews/ui/business_reviews_page.dart` | |
| Report | Canli | `apps/mobile_flutter/lib/features/business/data/report_repository.dart` | business/review/photo |
| Favorites | Canli | `apps/mobile_flutter/lib/features/favorites/ui/favorites_page.dart` | paylasim dahil |
| Profile | Canli | `apps/mobile_flutter/lib/features/profile/ui/profile_page.dart` | stats + progress + topluluk guveni / destek sinyali dili aktif |
| Inbox / notifications | Canli | `apps/mobile_flutter/lib/features/notifications/ui/inbox_page.dart` | push + legacy merge + push tap route intent |
| Suggest business | Canli | `apps/mobile_flutter/lib/features/suggestions/ui/suggest_business_page.dart` | |
| QR scan / deep link parse | Canli | `apps/mobile_flutter/lib/features/contribute/ui/contribute_entry.dart` | |
| Price verify / suggestion | Canli | `apps/mobile_flutter/lib/features/menus/data/menu_repository.dart` | offline queue parcali |

## Genisleme / V2 Akislari

| Alan | Durum | Kanit | Not |
|---|---|---|---|
| Smart feed | Deneysel | `apps/mobile_flutter/lib/features/smart_feed/ui/smart_feed_page.dart` | v1/v2 RPC fallback + request cache/force-refresh + runtime feature flag gate var |
| Taste Twin | Deneysel | `apps/mobile_flutter/lib/features/taste_twin/ui/taste_twin_page.dart` | graph/match akisi + read cache katmani var |
| Group requests | Deneysel | `apps/mobile_flutter/lib/features/group_requests/ui/*` | cok adimli community akis + mutation sonrasi cache invalidation var; core discovery CTA'si yerine `Labs` hub altina toplandi |
| Top businesses | Canli | `apps/mobile_flutter/lib/features/top_businesses/ui/top_businesses_page.dart` | |
| Gourmets/following/feed | Deneysel | `apps/mobile_flutter/lib/features/gourmets/ui/*` | sosyal akis + follow sonrası feed/following refresh baglandi; bottom-nav artik feed'e sapmaz, giris `Labs` hub altindadir |
| Heroes | Deneysel | `apps/mobile_flutter/lib/features/heroes/ui/heroes_page.dart` | cekirdek drawer/discovery uzerinden dogrudan dagitilmaz; `Labs` hub altindadir |
| Budget combos | Deneysel | `apps/mobile_flutter/lib/features/budget_combos/ui/budget_combo_results_page.dart` | RPC cevabi request cache ile korunuyor; cekirdek discovery kartlari yerine `Labs` hub altina cekildi |
| Price alerts | Canli | `apps/mobile_flutter/lib/features/price_alerts/data/price_alerts_repository.dart` | UI gomulu |
| Suspended meals | Deneysel | `apps/mobile_flutter/lib/features/suspended_meals/ui/my_suspended_claims_page.dart` | claims + badge icin read cache + force refresh var; account drawer yerine `Labs` hub altina tasindi |
| Embeds | Canli | `apps/mobile_flutter/lib/features/embed/ui/embed_viewer_page.dart` | provider ayristirma + widget/integration smoke + embed perf gate tamamlandi |
| Sponsored businesses | Canli | `apps/mobile_flutter/lib/features/monetization/domain/sponsored_businesses_provider.dart` | discovery icinde |
| Native ads | Canli | `apps/mobile_flutter/lib/features/ads/data/native_ad_controller.dart` | discovery feed ad placement kurali composer katmanina tasindi |
| Perks | Canli | `apps/mobile_flutter/lib/features/perks/domain/perk_providers.dart` | business icinde |

## Kismi / Duzeltilmeli Alanlar

| Alan | Durum | Kanit | Neden |
|---|---|---|---|
| Nearby campaigns | Canli | `apps/mobile_flutter/lib/features/discovery/data/discovery_repository.dart` | `get_nearby_campaign_stories_v1` ile okunuyor |
| Integration smoke | Kismi | `apps/mobile_flutter/integration_test/golden_paths_integration_test.dart` | gercek router smoke + runtime feature-flag + deep-link/QR route smoke + devtools push payload simulator smoke var; Android native debug push bridge mevcut, true FCM transport/iOS e2e hala eksik |
| Offline mode | Kismi | `apps/mobile_flutter/lib/core/storage/local_db/local_db_provider.dart` | SQLite-backed snapshot store + unified mutation queue + foreground/connectivity replay + client-side idempotency var; cekirdek katkı write'lariyla birlikte `favorite`, `price vote`, `follow`, `photo vote`, `price alert create`, `group offer vote` ve `presence submit` icin de explicit server-side idempotency aktif, devtools queue diagnostics + admin observability outcome ekranı + health summary threshold'lari + conflict policy + suggested action operator gorunurlugu sagliyor; kalan risk artik daha cok gelecekte eklenecek write yuzeylerinin ayni standardi korumasidir |
| Deneysel read-cache hardening | Tamam | `apps/mobile_flutter/lib/features/{smart_feed,taste_twin,gourmets,group_requests,suspended_meals,budget_combos}/data/*` | request cache + invalidation rollout tamamlandi |
| Runtime feature-flag gates | Tamam | `apps/mobile_flutter/lib/{app/router.dart,app/app_shell.dart,features/shared/ui/components/*}` | feed/labs rollout kapilari runtime provider ile yonetiliyor; `Labs` hub route'u eklendi, cekirdek alt-nav `/discover`'a sabitlendi |
| Embed hardening | Tamam | `apps/mobile_flutter/{lib/features/embed/*,integration_test/embed_smoke_integration_test.dart,test/features/embed/ui/embed_viewer_page_test.dart}` | fallback akisi + coverage + release gate metrik baglantisi tamamlandi |
| Upload naming | Tamam | `apps/mobile_flutter/lib/core/media/media_upload_repository.dart` | aktif call site'lar `media upload` katmanina tasindi; eski `wp_upload*` dosyalari kaldirildi |

## Mobilde Olmamali

| Alan | Durum | Kanit | Neden |
|---|---|---|---|
| Admin queue | Yok | `apps/panel_flutter_web/lib/features/admin/ui/admin_queue_page.dart` | operasyon panel isi |
| Admin audit | Yok | `apps/panel_flutter_web/lib/features/admin/ui/admin_audit_page.dart` | operasyon panel isi |
| Admin impersonation | Yok | `apps/panel_flutter_web/lib/features/admin/ui/admin_user_access_page.dart` | support/admin isi |
| Owner businesses CRUD | Yok | `apps/panel_flutter_web/lib/features/owner_businesses/ui/*` | panel isi |
| Owner menu editor | Yok | `apps/panel_flutter_web/lib/features/owner_menu_management/ui/*` | panel isi |
| Owner team / RBAC | Yok | `apps/panel_flutter_web/lib/features/owner_team/ui/owner_team_page.dart` | panel isi |
| Owner trash / versions | Yok | `apps/panel_flutter_web/lib/features/owner_menu_management/ui/owner_menu_trash_page.dart` | panel isi |
| QR Studio / presentation settings | Yok | `apps/web_next/app/qr/[businessId]/page.tsx` | web/panel bagli akis |

## MVP Siniri

Kisa tanimla MVP:

- discovery
- business detail
- menu/item
- review/report
- favorites
- profile
- QR scan
- price verify

MVP disinda kalan her sey:

- sosyal graph
- smart feed
- group requests
- taste twin
- suspended meals
- sponsorlu surfaces

Bu alanlar kodda olsa da release kararinda ayri degerlendirilmelidir.
