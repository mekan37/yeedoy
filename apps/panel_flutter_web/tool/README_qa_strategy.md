# QA / Test Strategy (Az ama Altin)

## 1) Golden path integration testleri

- Dosya: `integration_test/golden_paths_integration_test.dart`
- Kapsam:
  - `Home -> Business -> Menu -> Verify Price`
  - `Login -> Review submit`
- Calistirma:
  - `flutter test integration_test/golden_paths_integration_test.dart`

## 2) Snapshot / Golden UI testleri

- Dosya: `test/ui/golden/basic_surfaces_golden_test.dart`
- Not: Golden testler default kapali.
- Calistirma:
  - `flutter test --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart`
- Golden guncelleme:
  - `flutter test --update-goldens --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart`

## 3) API contract testleri

- Dosya: `test/core/contracts/discovery_api_contract_test.dart`
- Kapsam:
  - `home_feed_v1` payload parse kontrati
  - `search_businesses_v1` item kontrati
- Calistirma:
  - `flutter test test/core/contracts/discovery_api_contract_test.dart`

## 4) Load test (home_feed, search, business)

- Dosya: `tool/load/k6_home_search_business.js`
- Arac: `k6`
- Calistirma:
  - `k6 run tool/load/k6_home_search_business.js -e BASE_URL=https://<your-edge-base-url> -e AUTH_HEADER=\"Bearer <token>\" -e BUSINESS_ID=<uuid>`
- Hedefler:
  - Home p95 < 1200ms
  - Search p95 < 800ms
  - Business p95 < 800ms

## 5) Release gate entegrasyonu

- Dosya: `tool/release_gate_check.dart`
- Gating:
  - Crash-free
  - Jank rate
  - Latency SLO
  - Security checklist
  - Rollout health (canary) + auto rollback
