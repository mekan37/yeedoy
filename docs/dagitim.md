# Dagitim Notlari

Bu belge aktif iki uygulamanin dagitim, env ve kalite kapilarini ozetler.

## Aktif Uygulamalar

- `uygulamalar/mobil`
- `uygulamalar/web`

Eski Flutter panel kaldirilmistir; owner/admin operasyonu `uygulamalar/web` altindadir.

## Web Next

Zorunlu env:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_SITE_URL`

Opsiyonel/server env:

- `SUPABASE_SERVICE_ROLE_KEY`
- `REVALIDATE_SECRET`
- `NEXT_PUBLIC_GMAPS_KEY`

Komutlar:

```bash
npm --prefix uygulamalar/web run typecheck
npm --prefix uygulamalar/web run lint
npm --prefix uygulamalar/web run build
npm --prefix uygulamalar/web run test
```

Hosting:

- Root directory: repo root veya `uygulamalar/web`
- Build command: `npm --prefix uygulamalar/web run build`
- Start command: `npm --prefix uygulamalar/web run start`

## Mobile Flutter

Lokal:

```bash
cd uygulamalar/mobil
flutter pub get
flutter run -t lib/mobil_giris.dart
```

Release:

```bash
flutter build apk --release -t lib/mobil_giris.dart
```

Signing env:

- `ANDROID_RELEASE_STORE_FILE`
- `ANDROID_RELEASE_STORE_PASSWORD`
- `ANDROID_RELEASE_KEY_ALIAS`
- `ANDROID_RELEASE_KEY_PASSWORD`

iOS release asset ve readiness ayrintisi icin `docs/mobil-ci-ios-hazirlik.md` kullanilir.

## Cache Invalidation

`POST /sunucu/yeniden-dogrulama` Next cache temizler.

Tek slug temizle:

```bash
curl -X POST "$NEXT_PUBLIC_SITE_URL/sunucu/yeniden-dogrulama" \
  -H "Content-Type: application/json" \
  -d '{"secret":"$REVALIDATE_SECRET","slug":"kafe-yeedoy"}'
```

Business ID ile temizle:

```bash
curl -X POST "$NEXT_PUBLIC_SITE_URL/sunucu/yeniden-dogrulama" \
  -H "Content-Type: application/json" \
  -d '{"secret":"$REVALIDATE_SECRET","businessId":"<uuid>"}'
```

## Secret Hijyeni

Ornek env dosyalari gercek secret tasimaz.

Hizli kontrol:

```bash
rg -n "eyJhbGci|SUPABASE_SERVICE_ROLE_KEY=.*[A-Za-z0-9_-]{20,}" uygulamalar/**/.env.example
```

Beklenen sonuc: eslesme olmamasi.

