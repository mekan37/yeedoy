# Release Gate

Bu klasörde panel web sürümü için iki zorunlu kapı scripti bulunur.

## 1) Güvenlik kapısı

Script:

```bash
dart run tool/security_review_check.dart
```

Katı mod (bulgu varsa hata kodu ile çık):

```bash
dart run tool/security_review_check.dart --strict
```

Kontrol ettiği başlıklar:
- Doğrudan kritik DB yazımı (`insert/update/upsert/delete`) kullanımı
- Kritik RPC adları (`submit_*`, `owner_*`, `admin_*`, vb.)
- Yalnızca izinli katmanlarda (`core/security/*`, `features/admin/*`) kritik yazma akışı

## 2) API versiyon kapısı

Script:

```bash
dart run tool/api_version_gate_check.dart
```

Kural:
- `rpc('...')` çağrılarında isim sonu sürüm içermelidir (`_v1`, `_v2` vb.).
- Kural ihlalinde script `BLOCK` döndürür ve hatalı dosya/satırları listeler.

## 3) CI önerisi

Release pipeline sırası:

1. `flutter analyze`
2. `flutter test`
3. `flutter test test/web/security/route_sanitizer_test.dart`
4. `flutter test test/web/security/admin_permissions_test.dart`
5. `dart run tool/security_review_check.dart --strict`
6. `dart run tool/api_version_gate_check.dart`

Bu adımlar geçmeden release alınmamalıdır.
