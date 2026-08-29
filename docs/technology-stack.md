# Yeedoy Technology Stack

## 1. Genel Mimari

| Alan | Teknoloji | Repoda Nerede | Kanıt Dosya |
|---|---|---|---|
| Monorepo | npm workspaces | `uygulamalar/web`, `uygulamalar/mobil`, `packages/*` workspace olarak tanımlı | `package.json`, `package-lock.json` |
| Mobil uygulama | Flutter / Dart | Son kullanıcı mobil uygulaması | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/main.dart` |
| Web uygulaması | Next.js App Router / React / TypeScript | Public menu, owner ve admin yüzeyleri | `uygulamalar/web/package.json`, `uygulamalar/web/app`, `uygulamalar/web/tsconfig.json` |
| Backend | Supabase | Auth, Postgres, Storage, Edge Functions, local Supabase stack | `supabase/config.toml`, `supabase/functions/README.md`, `supabase/migrations` |
| Database | PostgreSQL 17 | Supabase DB major version ve SQL migrations | `supabase/config.toml`, `supabase/migrations/00000000000000_base_schema.sql` |
| Serverless runtime | Supabase Edge Functions / Deno / TypeScript | Edge function `index.ts` girişleri | `supabase/functions/*/index.ts`, `.github/workflows/edge_function_smoke.yml` |
| Ortak Flutter paketleri | Local Dart packages | Shared models ve shared UI components | `packages/shared_models/pubspec.yaml`, `packages/shared_ui_components/pubspec.yaml` |

## 2. Mobil Uygulama Teknolojileri

| Teknoloji | Kullanım Amacı | Paket / Config | Kanıt Dosya |
|---|---|---|---|
| Flutter | Android/iOS mobil UI ve uygulama runtime | `flutter`, `uses-material-design` | `uygulamalar/mobil/pubspec.yaml` |
| Dart SDK 3.10.7 | Mobil uygulama dili/runtime hedefi | `environment.sdk: ^3.10.7` | `uygulamalar/mobil/pubspec.yaml` |
| Riverpod | State yönetimi | `flutter_riverpod` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/app/app.dart` |
| GoRouter | Navigasyon | `go_router` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/app/router.dart` |
| Supabase Flutter | Auth, RPC, database ve storage erişimi | `supabase_flutter` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/network/supabase_provider.dart` |
| Firebase Core / Messaging / Analytics / Crashlytics / Performance | Push, analitik, crash ve performans izleme | `firebase_core`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/main.dart`, `firebase.json` |
| Google Sign-In | Google ile giriş | `google_sign_in` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/auth/data/auth_service.dart` |
| Google Mobile Ads / AdMob | Reklam gösterimi | `google_mobile_ads` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/ads/ui/native_ad_card.dart`, `uygulamalar/mobil/ios/Runner/Info.plist` |
| Local Auth / Secure Storage | Biyometrik giriş ve güvenli yerel saklama | `local_auth`, `flutter_secure_storage` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/security/secure_local_storage.dart` |
| Shared Preferences | Yerel tercih/cache saklama | `shared_preferences` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/storage/theme_prefs.dart` |
| sqflite | Yerel SQLite tabanlı offline store | `sqflite` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/storage/local_db/sqflite_local_db_store.dart` |
| Google ML Kit | OCR ve barkod/QR algılama | `google_ml_kit`, `google_mlkit_barcode_scanning` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/menus/data/ocr_price_extractor.dart` |
| QR Flutter | QR üretimi | `qr_flutter` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/yerlestir/ui/yerlestir_sayfasi.dart` |
| Geolocator / Geocoding | Konum ve ters/ileri geocoding | `geolocator`, `geocoding` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/location/user_location_controller.dart` |
| flutter_map / latlong2 | Harita gösterimi | `flutter_map`, `latlong2` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/discovery/ui/discovery_page.dart` |
| Image/Web media | Görsel seçme, cache, webview, YouTube embed | `image_picker`, `cached_network_image`, `flutter_cache_manager`, `webview_flutter`, `youtube_player_iframe` | `uygulamalar/mobil/pubspec.yaml` |
| Home Widget | Platform widget entegrasyonu | `home_widget` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/core/services/home_widget_service.dart` |
| Android Gradle / Kotlin / Java 17 | Android build ve native plugin altyapısı | Android Gradle Plugin, Kotlin Android, Java 17 | `uygulamalar/mobil/android/app/build.gradle.kts`, `uygulamalar/mobil/android/settings.gradle.kts` |
| iOS CocoaPods | iOS dependency entegrasyonu | `Podfile`, static frameworks | `uygulamalar/mobil/ios/Podfile` |

## 3. Web Uygulama Teknolojileri

| Teknoloji | Kullanım Amacı | Paket / Config | Kanıt Dosya |
|---|---|---|---|
| Next.js 15 | Public web, owner/admin route ve route handler runtime | `next` | `uygulamalar/web/package.json`, `uygulamalar/web/next.config.mjs` |
| React 19 | Web UI componentleri | `react`, `react-dom` | `uygulamalar/web/package.json`, `uygulamalar/web/app`, `uygulamalar/web/src/ui` |
| TypeScript | Web statik tip kontrolü | `typescript`, strict `tsconfig` | `uygulamalar/web/package.json`, `uygulamalar/web/tsconfig.json` |
| Tailwind CSS | Web styling ve design token kullanımı | `tailwindcss`, semantic token config | `uygulamalar/web/package.json`, `uygulamalar/web/tailwind.config.js` |
| PostCSS / Autoprefixer | CSS işlem hattı | `postcss`, `autoprefixer` | `uygulamalar/web/postcss.config.js`, `uygulamalar/web/package.json` |
| Supabase JS / SSR | Browser, server ve service-role Supabase erişimi | `@supabase/supabase-js`, `@supabase/ssr` | `uygulamalar/web/package.json`, `uygulamalar/web/src/lib/supabase/server.ts`, `uygulamalar/web/src/lib/supabase/client.ts` |
| Zod | Route handler ve form validasyonu | `zod` | `uygulamalar/web/package.json`, `uygulamalar/web/app/api/owner/menus/route.ts` |
| TanStack React Query | Client state/query provider | `@tanstack/react-query` | `uygulamalar/web/package.json`, `uygulamalar/web/src/lib/providers.tsx` |
| Zustand | Client state store | `zustand` | `uygulamalar/web/package.json` |
| Radix UI | Headless UI primitive componentleri | `@radix-ui/react-*` | `uygulamalar/web/package.json` |
| Leaflet / React Leaflet | Web harita UI | `leaflet`, `react-leaflet` | `uygulamalar/web/package.json`, `uygulamalar/web/app/(genel)/kesif/harita` |
| qrcode | QR Studio / QR üretimi | `qrcode` | `uygulamalar/web/package.json`, `uygulamalar/web/src/ui/sections/qr-generator.tsx` |
| Firebase Web SDK | Web push izin ve FCM token akışı | `firebase` | `uygulamalar/web/package.json`, `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/push-izin-butonu.tsx`, `uygulamalar/web/public/firebase-messaging-sw.js` |
| Replicate SDK | Makbuz OCR / DeepSeek OCR route'u | `replicate` | `uygulamalar/web/package.json`, `uygulamalar/web/app/sunucu/makbuz-ocr/route.ts` |
| Lighthouse | Mobil performans smoke scriptleri | `lighthouse`, `chrome-launcher` | `uygulamalar/web/package.json`, `uygulamalar/web/scripts/lighthouse-mobile.mjs` |
| Next Bundle Analyzer | Bundle analiz build modu | `@next/bundle-analyzer` | `uygulamalar/web/package.json`, `uygulamalar/web/next.config.mjs` |

## 4. Admin Panel Teknolojileri

| Teknoloji | Kullanım Amacı | Paket / Config | Kanıt Dosya |
|---|---|---|---|
| Next.js Admin/Owner panel | Admin ve owner CRUD/operasyon ekranları | `app/yonetici`, `app/admin`, `app/sahip`, `app/owner` route yapısı | `uygulamalar/web/package.json`, `uygulamalar/web/app/yonetici`, `uygulamalar/web/app/sahip` |
| Next.js Route Handlers | Owner/admin mutation ve server API uçları | `app/api/**/route.ts`, `app/sunucu/**/route.ts` | `uygulamalar/web/app/api/owner/menus/route.ts`, `uygulamalar/web/app/sunucu/masa-siparisi/route.ts` |
| Zod | Admin/owner input validasyonu | `zod` | `uygulamalar/web/app/api/owner/businesses/route.ts`, `uygulamalar/web/package.json` |
| Supabase SSR | Panel auth/session yönetimi | `@supabase/ssr` | `uygulamalar/web/src/lib/supabase/server.ts`, `uygulamalar/web/app/auth/callback/route.ts` |

Not (2026-06-24): `uygulamalar/personel` (Flutter owner/garson operasyon uygulaması) ürün kapsamından tamamen kaldırıldı; owner/admin operasyonları artık tamamen `uygulamalar/web` üzerinden yürütülüyor. Bu bölümdeki Flutter-tabanlı satırlar (Riverpod/GoRouter, Supabase Flutter, QR Scanner, Firebase) bu nedenle silindi.

## 5. Backend Teknolojileri

| Teknoloji | Kullanım Amacı | Repoda Nerede | Kanıt Dosya |
|---|---|---|---|
| Supabase Edge Functions | Admin API, AI analiz, upload, push, email ve guard endpointleri | `supabase/functions/*/index.ts` | `supabase/functions/README.md`, `supabase/config.toml` |
| Deno 2.x | Edge function type check ve runtime hedefi | CI Deno check | `.github/workflows/edge_function_smoke.yml` |
| TypeScript | Edge function kaynak dili | `index.ts` dosyaları | `supabase/functions/write-gatekeeper/index.ts`, `supabase/functions/ai-menu-analyze/index.ts` |
| Supabase JS | Edge function içinde DB/Auth/Storage client | esm.sh import | `supabase/functions/media-upload-user/index.ts`, `supabase/functions/_shared/rate-limit.ts` |
| Next.js Route Handlers | Web backend API katmanı | `uygulamalar/web/app/api`, `uygulamalar/web/app/sunucu` | `uygulamalar/web/app/sunucu/masa-siparisi/route.ts` |
| Rate limit / write guard | Hassas yazma akışları ve spam koruması | Edge function ve shared rate-limit | `supabase/functions/_shared/rate-limit.ts`, `supabase/functions/write-gatekeeper/index.ts`, `supabase/functions/anti-spam-guard/index.ts` |
| Media upload | Mobil/user-scoped upload, Supabase Storage | `media-upload-user` | `supabase/functions/media-upload-user/index.ts` |
| Email dispatch | Resend API ile kampanya e-postası (Next.js route handler'dan, edge function değil) | web resend client | `uygulamalar/web/src/lib/email/resend-client.ts`, `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` |

## 6. Database Teknolojileri

| Teknoloji | Kullanım Amacı | Repoda Nerede | Kanıt Dosya |
|---|---|---|---|
| PostgreSQL 17 | Ana ilişkisel veritabanı | Supabase local DB config | `supabase/config.toml` |
| SQL migrations | Şema, RPC, RLS ve veri modeli değişiklikleri | `supabase/migrations`, `supabase/migrations/_archive` | `supabase/migrations/00000000000000_base_schema.sql`, `supabase/migrations/20260615000005_top_businesses_redesign_rpc.sql` |
| PL/pgSQL RPC | Clientların çağırdığı RPC fonksiyonları | Migration dosyaları | `supabase/migrations/20260615000002_search_menu_items_v2.sql`, `supabase/migrations/20260615000005_top_businesses_redesign_rpc.sql` |
| Row Level Security | Tablo erişim politikaları | SQL policy ve RLS ifadeleri | `supabase/remote_schema_latest.sql`, `supabase/migrations/20260526000003_rls_hardening.sql` |
| Supabase Storage | Media bucket ve storage policies | Storage bucket migrations | `supabase/migrations/20260609000005_fix_storage_policies.sql`, `supabase/config.toml` |
| Supabase Auth | JWT, email auth ve redirect ayarları | `[auth]` config ve client auth akışları | `supabase/config.toml`, `uygulamalar/web/app/auth/callback/route.ts`, `uygulamalar/mobil/lib/features/auth/data/auth_service.dart` |
| Supabase Realtime | Bildirim / realtime menu alanları | Realtime migration ve client refresh | `supabase/migrations/_archive/20260321000011_push_notifications_and_realtime.sql`, `supabase/migrations/20260414000006_realtime_menu_items.sql` |
| PostGIS | Yakın arama ve konum indeksleri | PostGIS migration | `supabase/migrations/20260526000001_postgis_business_location_index.sql`, `supabase/migrations/20260515000002_postgis_yakin_arama.sql` |
| pgcrypto | Token/hash/crypto destekli SQL işlemleri | Extension create | `supabase/remote_schema_latest.sql`, `supabase/migrations/_archive/20260321000008_collection_shares.sql` |
| GraphQL public schema | Supabase local API schema listesinde açık | `graphql_public` schema | `supabase/config.toml` |

## 7. DevOps / CI-CD Teknolojileri

| Teknoloji | Kullanım Amacı | Workflow / Config | Kanıt Dosya |
|---|---|---|---|
| GitHub Actions | CI, kalite ve release workflowları | `.github/workflows/*.yml` | `.github/workflows/web_quality.yml`, `.github/workflows/mobile_quality.yml` |
| actions/checkout | Repo checkout | Tüm aktif workflowlar | `.github/workflows/web_quality.yml`, `.github/workflows/mobile_release.yml` |
| actions/setup-node | Web Node 20 kurulumu | Web kalite ve release smoke | `.github/workflows/web_quality.yml`, `.github/workflows/web_release_smoke.yml` |
| subosito/flutter-action | Flutter SDK kurulumu | Mobil ve package kalite | `.github/workflows/mobile_quality.yml`, `.github/workflows/packages_quality.yml` |
| actions/setup-java | Java 17 kurulumu | Flutter Android build/analyze | `.github/workflows/mobile_quality.yml` |
| denoland/setup-deno | Edge Functions Deno check | Edge function smoke | `.github/workflows/edge_function_smoke.yml` |
| dorny/paths-filter | PR path filtreleme | Web, mobil kalite | `.github/workflows/web_quality.yml`, `.github/workflows/mobile_quality.yml` |
| actions/upload-artifact | Release ve Playwright rapor artifactleri | Android/iOS artifact ve smoke raporu | `.github/workflows/mobile_release.yml`, `.github/workflows/mobile_readiness.yml`, `.github/workflows/web_release_smoke.yml` |
| npm ci / npm audit | Web dependency kurulumu ve güvenlik audit | Web CI | `.github/workflows/web_quality.yml` |
| Flutter analyze/test | Mobil kalite kapısı | Mobile CI | `.github/workflows/mobile_quality.yml` |
| Android AAB/APK release | Mobil release build | `flutter build appbundle`, `flutter build apk` | `.github/workflows/mobile_release.yml`, `.github/workflows/mobile_readiness.yml` |
| iOS IPA release dry run | iOS signing ve IPA dry run | macOS runner, `flutter build ipa` | `.github/workflows/mobile_readiness.yml` |
| Vercel | Web deployment/runtime ortamı olarak dokümante edilmiş | Env ve dashboard referansları | `docs/bildirim-teslimati/delivery-integration-status.md`, `uygulamalar/web/app/admin/dev-tools/page.tsx`, `uygulamalar/web/next.config.mjs` |

## 8. Test Teknolojileri

| Teknoloji | Kullanım Amacı | Test Dosyaları | Kanıt Dosya |
|---|---|---|---|
| Vitest | Web unit testleri | `uygulamalar/web/test/**/*.test.ts(x)` | `uygulamalar/web/package.json`, `uygulamalar/web/vitest.config.ts` |
| React Testing Library | React component testleri | `two-factor-banner.test.tsx` | `uygulamalar/web/package.json`, `uygulamalar/web/test/ui/two-factor-banner.test.tsx` |
| jsdom | Web test DOM ortamı | Vitest environment | `uygulamalar/web/vitest.config.ts`, `uygulamalar/web/package.json` |
| Playwright | Web E2E ve smoke testleri | `uygulamalar/web/e2e/*.spec.ts` | `uygulamalar/web/package.json`, `uygulamalar/web/playwright.config.ts` |
| Flutter Test | Mobil unit ve widget testleri | `uygulamalar/mobil/test` | `uygulamalar/mobil/pubspec.yaml` |
| Flutter Integration Test | Mobil integration smoke testleri | `uygulamalar/mobil/integration_test` | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/integration_test/offline_queue_smoke_test.dart` |
| Golden tests | Mobil UI snapshot/golden kalite | `test/ui/golden`, `test/ui/altin` | `.github/workflows/mobile_quality.yml`, `uygulamalar/mobil/test/ui/golden/basic_surfaces_golden_test.dart` |
| Mocktail | Dart mocking | Flutter test dev dependency | `uygulamalar/mobil/pubspec.yaml` |
| Deno check | Edge Function type check | `deno check supabase/functions/**/index.ts` | `.github/workflows/edge_function_smoke.yml` |
| Lighthouse | Web performance smoke/audit | Lighthouse scripts ve raporlar | `uygulamalar/web/package.json`, `uygulamalar/web/reports/lighthouse` |

## 9. Güvenlik / Auth Teknolojileri

| Teknoloji | Kullanım Amacı | Repoda Nerede | Kanıt Dosya |
|---|---|---|---|
| Supabase Auth | Kullanıcı oturumu, callback ve mobile auth | Web auth routes, Flutter auth service | `supabase/config.toml`, `uygulamalar/web/app/auth/callback/route.ts`, `uygulamalar/mobil/lib/features/auth/data/auth_service.dart` |
| Supabase SSR Cookies | Server-side session cookie yönetimi | `createServerClient` | `uygulamalar/web/src/lib/supabase/server.ts`, `uygulamalar/web/app/sunucu/kimlik/giris/route.ts` |
| RLS policies | Database erişim güvenliği | SQL migrations ve remote schema | `supabase/remote_schema_latest.sql`, `supabase/migrations/20260526000003_rls_hardening.sql` |
| JWT doğrulama | Edge function auth enforcement | `verify_jwt` config ve auth headers | `supabase/config.toml`, `.github/workflows/edge_function_smoke.yml` |
| CSP / HSTS / security headers | Web güvenlik headerları | Next headers config | `uygulamalar/web/next.config.mjs` |
| Zod validation | API input doğrulama | Route handlers | `uygulamalar/web/app/api/owner/menus/route.ts`, `uygulamalar/web/app/sunucu/masa-siparisi/route.ts` |
| Rate limiting | Edge ve write path rate limit | Supabase function shared module | `supabase/functions/_shared/rate-limit.ts`, `supabase/migrations/20260427000005_rate_limit_buckets.sql` |
| Flutter Secure Storage | Mobil secure local secret/session storage | Mobil app | `uygulamalar/mobil/lib/core/security/secure_local_storage.dart` |
| Local Auth / Face ID | Biyometrik doğrulama | Mobil ayar ve login | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/ios/Runner/Info.plist` |
| Google Sign-In | Federated login | Mobil auth service | `uygulamalar/mobil/pubspec.yaml`, `uygulamalar/mobil/lib/features/auth/data/auth_service.dart` |
| Firebase Cloud Messaging tokenları | Mobil device token kaydı (push dispatch/kampanya akışı MVP kapsamı dışına alınıp kill-switch edildi, fcm-client.ts ve push-dispatch/send-push-campaign edge function'ları kaldırıldı) | Mobil | `uygulamalar/mobil/pubspec.yaml` |

## 10. Dış Servisler

| Servis | Kullanım Amacı | Repoda Kanıt | Durum |
|---|---|---|---|
| Supabase | Postgres, Auth, Storage, Edge Functions | `supabase/config.toml`, `@supabase/*` bağımlılıkları | Aktif |
| Firebase | Analytics, crash, performance (mobil) | `firebase.json`, `uygulamalar/mobil/pubspec.yaml` | Aktif |
| Firebase Cloud Messaging (web push) | Push bildirim gönderimi | — | Kaldırıldı (kill-switch, 2026-08-29) |
| Google AdMob | Mobil reklam | `google_mobile_ads`, `GADApplicationIdentifier` | Aktif |
| Google Sign-In | Mobil federated login | `google_sign_in`, `auth_service.dart` | Aktif |
| OpenRouter | AI menü/gıda analizi | `OPENROUTER_API_KEY`, `openrouter.ai/api/v1/chat/completions` | Aktif, secret gerekli |
| Replicate / DeepSeek OCR | Menü ve makbuz OCR | `REPLICATE_API_TOKEN`, `replicate` SDK, DeepSeek OCR model sabiti | Aktif, secret gerekli |
| Resend | E-posta kampanyaları | `RESEND_API_KEY`, `api.resend.com` | Kısmi; kod hazır, runtime secret durumuna bağlı |
| WordPress Media API | Legacy medya upload uyumu | `WP_BASE_URL`, `/wp-json/wp/v2/media` | Legacy uyumluluk |
| TCMB | Kur verisi çekme | `https://www.tcmb.gov.tr/kurlar/today.xml` | Aktif function |
| Foursquare Places API | İlçe bazlı mekan import aracı | `tools/foursquare-ilce-ice-aktar.mjs`, `FOURSQUARE_API_KEY` | Tooling/import |
| OpenStreetMap / Overpass API | POI ve idari sınır importu | `tools/overpass-ilce-canli-ice-aktar.mjs`, OSM import scripts | Tooling/import |
| osmium-tool | OSM PBF işleme | `tools/osm-pbf-isle.mjs` | Tooling/import; sistem aracı gerekli |
| Vercel | Web production env/deployment referansı | `docs/bildirim-teslimati/delivery-integration-status.md`, CSP `vercel-scripts` | Dokümante edilmiş |
| pnpm | Workspace/package manager | Kanıt bulunamadı; `pnpm-workspace.yaml` yok | Kullanım kanıtı yok |
| Flutter web panel | Eski panel yüzeyi | Aktif kanıt bulunamadı; workflow arşivli | Kullanılmıyor/arşiv |

## 11. Öğrenme Önceliği

| Öncelik | Teknoloji | Neden Öğrenmeliyim? | Projede Nerede Kullanılıyor? |
|---|---|---|---|
| P0 | Flutter / Dart | Mobil uygulamanın ana geliştirme yüzeyi | `uygulamalar/mobil`, `packages/shared_*` |
| P0 | Riverpod | Mobil state orchestration standardı | `uygulamalar/mobil/lib/**/domain` |
| P0 | Supabase | Auth, DB, Storage, RPC ve Edge Functions tüm ürünün backend temeli | `supabase`, Flutter/web Supabase clientları |
| P0 | PostgreSQL / SQL / RLS | Veri modeli, RPC ve güvenlik politikalarını anlamak için gerekli | `supabase/migrations`, `supabase/remote_schema_latest.sql` |
| P0 | Next.js App Router | Public menu, owner ve admin web yüzeyinin ana frameworkü | `uygulamalar/web/app` |
| P0 | TypeScript / React | Web UI ve route handler geliştirme için temel | `uygulamalar/web/src`, `uygulamalar/web/app` |
| P0 | Zod | Web mutation route güvenliği ve input doğrulama için gerekli | `uygulamalar/web/app/api`, `uygulamalar/web/app/sunucu` |
| P1 | Tailwind CSS ve web token sistemi | Web UI standardını bozmadan geliştirme yapmak için gerekli | `uygulamalar/web/tailwind.config.js`, `uygulamalar/web/src/styles/tokens.css` |
| P1 | Supabase Edge Functions / Deno | AI, upload, email, push ve guard backendlerini değiştirmek için gerekli | `supabase/functions` |
| P1 | Firebase / Crashlytics | Analytics ve crash akışlarını yönetmek için gerekli (FCM push dispatch kill-switch edildi) | `uygulamalar/mobil` |
| P1 | GitHub Actions | Kalite kapıları ve release akışlarını yönetmek için gerekli | `.github/workflows` |
| P1 | Playwright / Vitest / Flutter Test | Değişiklikleri doğru yüzeyde doğrulamak için gerekli | `uygulamalar/web/test`, `uygulamalar/web/e2e`, `uygulamalar/mobil/test` |
| P1 | Android Gradle / iOS CocoaPods signing | Mobil release, Firebase ve native izinleri anlamak için gerekli | `uygulamalar/mobil/android`, `uygulamalar/mobil/ios` |
| P2 | Replicate / OpenRouter | AI menü analizi ve OCR özellikleriyle çalışırken gerekli | `supabase/functions/ai-*`, `uygulamalar/web/app/sunucu/makbuz-ocr/route.ts` |
| P2 | Resend | Owner e-posta kampanyaları üzerinde çalışırken gerekli | `uygulamalar/web/src/lib/email/resend-client.ts`, `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` |
| P2 | Leaflet / flutter_map | Harita ve yakın arama UI'larında gerekli | `uygulamalar/web`, `uygulamalar/mobil/lib/features/discovery` |
| P2 | OSM / Overpass import tooling (idari sınır) | İdari sınır/lokasyon veri zenginleştirme işlerinde gerekli — işletme POI import pipeline'ı (Foursquare dahil) 2026-08-29'da kaldırıldı | `tools/*osm*`, `tools/*overpass*` |

## Kısa Özet

En kritik 10 teknoloji: Flutter, Dart, Riverpod, Supabase, PostgreSQL/RLS, Next.js, React, TypeScript, Zod, GitHub Actions.

Yeni başlayan biri için ilk öğrenme sırası: Flutter/Dart + Riverpod, Supabase/PostgreSQL/RLS, Next.js/React/TypeScript, sonra Zod ve proje test araçları.

Gereksiz veya kullanılmıyor gibi görünenler: `pnpm` için kanıt bulunamadı; repo npm workspaces ve `package-lock.json` kullanıyor. `packages/api_client`, `packages/shared_config`, `packages/shared_types` hiçbir app tarafından import edilmediği doğrulanıp 2026-07-25'te silindi (bkz. CLAUDE.md'nin eski "yeni iş taşınmasın" uyarısı).
