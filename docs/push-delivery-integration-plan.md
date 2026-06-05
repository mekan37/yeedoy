# Push Delivery Integration Plan

> Status: Fail-safe implementation deployed. Activation blocked on Firebase secrets.

## Mevcut Altyapı

| Bileşen | Konum | Durum |
|---|---|---|
| `user_devices` tablosu | Supabase — `id, user_id, fcm_token, platform, last_seen_at` | Aktif |
| `push_campaigns` tablosu | Supabase — `id, business_id, title, body, target_segment, sent_count, sent_at` | Aktif |
| `estimate_campaign_segment_v1` RPC | Supabase | Aktif |
| `create_push_campaign_v1` RPC | Supabase | Aktif |
| `business_follows` tablosu | Supabase — `business_id, user_id` | Aktif |
| `get-segment-tokens.ts` | `src/lib/push/get-segment-tokens.ts` | Deployed |
| `fcm-client.ts` | `src/lib/push/fcm-client.ts` | Deployed |
| Admin push route | `app/sunucu/yonetici/push-kampanyalari/route.ts` | FCM entegre edildi |

## Eksikler — Aktivasyon için Gerekli

| Gereksinim | Nerede alınır |
|---|---|
| Firebase projesi | Firebase Console → yeni proje veya mevcut proje |
| Service account key (JSON) | Firebase Console → Project Settings → Service Accounts → Generate new private key |
| GitHub/Vercel secret tanımları | Aşağıdaki secret isimlerini ekle |

## Gerekli Secret İsimleri

```
FIREBASE_PROJECT_ID        # Firebase proje ID'si (ör. yeedoy-prod)
FIREBASE_CLIENT_EMAIL      # Service account e-postası (ör. firebase-adminsdk-xyz@yeedoy-prod.iam.gserviceaccount.com)
FIREBASE_PRIVATE_KEY       # Service account private key (-----BEGIN RSA PRIVATE KEY----- satırıyla başlar)
```

### FIREBASE_PRIVATE_KEY Newline Notu

Firebase Console'dan indirilen JSON dosyasındaki `private_key` alanı literal `\n` karakterleri içerir.
Bu değeri environment variable olarak kaydederken **olduğu gibi** kaydet — `fcm-client.ts` içinde
`.replace(/\\n/g, '\n')` ile gerçek newline'a dönüştürülmektedir.

Vercel'de eklerken: değeri tırnak içinde yaz, `\n` karakterlerini olduğu gibi bırak.

## Aktivasyon Adımları

1. [Firebase Console](https://console.firebase.google.com) → projeyi seç veya oluştur
2. Project Settings → Service Accounts → "Generate new private key" → JSON indir
3. JSON dosyasından 3 alan al:
   - `project_id` → `FIREBASE_PROJECT_ID`
   - `client_email` → `FIREBASE_CLIENT_EMAIL`
   - `private_key` → `FIREBASE_PRIVATE_KEY`
4. Vercel dashboard → Settings → Environment Variables → 3 değeri ekle (Production + Preview)
5. GitHub → Repository Secrets → aynı 3 değeri ekle (CI build için)
6. Vercel'de yeni deploy tetikle → `fcm-client.ts` secrets'ı okuyacak ve gerçek gönderime geçecek

## Mevcut Fail-Safe Davranışı

Secrets eksikse route şunu döndürür:

```json
{
  "ok": true,
  "sentCount": <estimate_campaign_segment_v1 tahmini>,
  "providerNotConfigured": true
}
```

Secrets mevcut ve FCM başarılıysa:

```json
{
  "ok": true,
  "sentCount": <gerçek başarılı gönderim sayısı>,
  "providerNotConfigured": false
}
```

## Güvenlik Notları

- FCM token değerleri asla loglanmaz — yalnızca count loglanır
- `FIREBASE_PRIVATE_KEY` asla loglanmaz
- OAuth2 access token asla loglanmaz
- Ham Firebase API hata detayları UI'a dönmez — sadece `{ error: 'internal_error' }` veya genel `failure_count`
- Route admin-only korumalıdır (`is_admin()` RPC guard)
- `getSegmentTokens` service role key yoksa `[]` döndürür ve sadece warn log yazar

## Segment Davranışı

| Segment | Kural |
|---|---|
| `all_followers` | İşletmenin tüm takipçileri |
| `new_30d` | Son 30 günde takip edenler |
| `loyal_top20`, `inactive_30d` ve diğerleri | `all_followers` ile aynı davranır (MVP scope) |
| Pasif token filtresi | `last_seen_at > 90 gün` olanlar dahil edilmez |
| Limit | Max 500 token (MVP scope) |
