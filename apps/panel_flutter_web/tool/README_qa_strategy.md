# Panel Web QA Stratejisi

Bu belge `apps/panel_flutter_web` için mevcut test ve kontrol akışını özetler.

## 1) Birim ve web-guvenlik testleri

- Önbellek davranışı:
  - `flutter test test/core/cache/ttl_memory_cache_test.dart`
- Mikro kopya kural seti:
  - `flutter test test/core/content/microcopy_style_guide_test.dart`
- Tasarım sistemi kalite kapısı:
  - `flutter test test/ui/design_system_quality_gates_test.dart`
- Web rota/sanitizasyon kuralları:
  - `flutter test test/web/security/route_sanitizer_test.dart`
- Admin rol yetki matrisi:
  - `flutter test test/web/security/admin_permissions_test.dart`

Tüm testleri toplu çalıştırmak için:

```bash
flutter test
```

## 2) Golden testleri (opsiyonel)

- Dosya: `test/ui/golden/basic_surfaces_golden_test.dart`
- Varsayılan olarak kapalıdır.

Çalıştırma:

```bash
flutter test --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart
```

Golden güncelleme:

```bash
flutter test --update-goldens --dart-define=RUN_GOLDENS=true test/ui/golden/basic_surfaces_golden_test.dart
```

## 3) Statik analiz

```bash
flutter analyze
```

## 4) Güvenlik ve sürüm kapıları

- Güvenlik kontrolü:
  - `dart run tool/security_review_check.dart`
  - Katı mod: `dart run tool/security_review_check.dart --strict`
- RPC versiyon kuralı:
  - `dart run tool/api_version_gate_check.dart`

## 5) Yük testi (k6)

- Dosya: `tool/load/k6_home_search_business.js`
- Örnek:

```bash
k6 run tool/load/k6_home_search_business.js -e BASE_URL=https://<edge-base-url> -e AUTH_HEADER="Bearer <token>" -e BUSINESS_ID=<uuid>
```

Hedefler (script içinde):
- `home_feed` p95 < 1200ms
- `search` p95 < 800ms
- `business` p95 < 800ms
