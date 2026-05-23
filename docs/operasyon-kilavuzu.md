# Runbook

Bu belge release smoke, incident response ve hizli operasyon kontrol sirasi icindir.

## Release Smoke

### Mobile

```bash
cd uygulamalar/mobil
flutter pub get
flutter analyze
flutter test
flutter test integration_test/golden_paths_integration_test.dart
flutter build apk --release -t lib/mobil_giris.dart
```

Beklenenler:

- cold start onboarding veya kesif akisina iner
- auth gerektiren favori/profil/gelen-kutusu route'lari login'e duser
- discovery -> business -> menu -> item zinciri kirilmaz
- review/report/favorite write semantigi bozulmaz

### Web Next

```bash
npm --prefix uygulamalar/web run typecheck
npm --prefix uygulamalar/web run lint
npm --prefix uygulamalar/web run build
npm --prefix uygulamalar/web run test
```

Ek smoke:

- `/` public discovery anasayfasi acilir
- `/m/:publicSlugOrId` public menu acilir
- `/m/:publicSlugOrId/c/:categoryId` kategori route'u acilir
- `/m/:publicSlugOrId/i/:itemId` item detail sheet acilir
- `/karekod/:businessId` session ve business yetkisi ister
- `/owner/**` owner session ister
- `/admin/**` admin session ister
- `/sunucu/izleme` valid event kabul eder
- `robots.txt` ve `sitemap.xml` 200 doner

## Offline Queue Recovery

Belirti:

- mobile devtools offline queue kartinda retry/drop birikiyor

Kontrol:

1. Network hatasinda otomatik replay bekle.
2. Auth/401/403 hatasinda oturumu yenile.
3. 429 hatasinda retry penceresini bekle.
4. 5xx hatasinda backend sagligini kontrol et.
5. Kalici validation hatasinda payload/RPC kontratini incele.

## QR veya Branding Sorunu

Kontrol:

1. Kullanici authenticated mi?
2. `can_manage_business_v1(business_id)` true mu?
3. `business_menu_presentation_settings` satiri guncellendi mi?
4. `updated_at` degisti mi?
5. `/sunucu/yeniden-dogrulama` basarili mi?

## Upload 403

Kontrol:

1. Session var mi?
2. `can_manage_business_v1` true mu?
3. Request body icinde `businessId`, `type`, `file` var mi?
4. `SUPABASE_SERVICE_ROLE_KEY` server env'de var mi?
5. Mime ve 5MB siniri uygun mu?

Beklenen:

- no session -> `401`
- yetkisiz business -> `403`
- yanlis mime veya buyuk dosya -> `400`

## Perf Regression

Kontrol:

```bash
npm --prefix uygulamalar/web run build
npm --prefix uygulamalar/web run build:analyze
npm --prefix uygulamalar/web run lighthouse:mobile
```

Odak:

- yeni client component lazy split edildi mi?
- `qrcode`, upload UI veya agir validation ilk chunk'a girdi mi?
- `next/image` ve dynamic import sinirlari korundu mu?


