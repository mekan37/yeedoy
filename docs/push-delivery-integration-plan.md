# Push Delivery Integration Plan

> Status: ✅ HAZIR — FCM code deployed, GitHub Secrets ✅ var, local .env.local ✅ configured (2026-06-06 verified).
> **Last updated:** 2026-06-06 (Runtime environment verified)

## Mevcut Aktivasyon Durumu

| Ortam | Firebase env var | FCM aktif mi? | Not |
|---|---|---|---|
| GitHub Actions (CI) | ✅ Secret kayıtlı | Workflow yok | CI workflow'lara atanmadı |
| Local dev (`.env.local`) | ✅ Eklendi (2026-06-05) | ✅ Aktif | FIREBASE_PROJECT_ID / CLIENT_EMAIL / PRIVATE_KEY set |
| Production runtime | ❌ Deployment yok | — | Deployment anında env var eklenince aktif |

### Private Key Format Kontrolü
- `FIREBASE_PRIVATE_KEY`: escaped `\n` formatı → `fcm-client.ts` `replace(/\\n/g, '\n')` ile işliyor → **FORMAT OK**

### FCM Token Durumu (DB)
- `user_devices` tablosunda **1 Android token** kayıtlı (son görülme: 2026-05-12)
- Token stale (>20 gün) — gerçek test için aktif bir mobil oturumu gerekiyor
- iOS token: 0

### Test Adımları (admin UI üzerinden)
1. `npm run dev` ile local server başlat (port 3000)
2. Admin hesabıyla `/yonetici/push-kampanyalari` sayfasına git
3. Bir işletme ve "new_30d" gibi küçük segment seç
4. Kampanya gönder — `providerNotConfigured: false` ve `sentCount` görmeli
5. `push_campaigns` tablosunda `sent_count` güncellendi mi kontrol et

**Kritik ayrım:** GitHub repository secret'ları yalnızca GitHub Actions workflow'larında `${{ secrets.FIREBASE_PROJECT_ID }}` syntax'ıyla erişilebilir. Next.js server runtime'ı (lokal `.env.local` dosyası veya production deployment env var'ları) tamamen ayrı bir yapılandırma katmanıdır.

`fcm-client.ts` şu an:
```javascript
const projectId = process.env.FIREBASE_PROJECT_ID?.trim();  // Runtime'dan oku
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').trim();

if (!projectId || !clientEmail || !privateKey) {
  return { success_count: 0, failure_count: 0, provider_not_configured: true };  // Fail-safe
}
```

Runtime env var'ları yoksa otomatik olarak `provider_not_configured: true` döndürüyor (fail-safe).

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

## Aktivasyon için Gerekli — Runtime env Yapılandırması

Runtime ortamlarında (lokal, production) 3 Firebase env var gerekiyor:

| Env Var | Değer | Nereden alınır |
|---|---|---|
| `FIREBASE_PROJECT_ID` | ör. `yeedoy-498507` | Firebase Console → Project Settings |
| `FIREBASE_CLIENT_EMAIL` | ör. `yeedoy@yeedoy-498507.iam.gserviceaccount.com` | Service account e-postası |
| `FIREBASE_PRIVATE_KEY` | `-----BEGIN RSA PRIVATE KEY-----\n...\n-----END...` | Service account private key (escaped newlines) |

**Not:** Bu değerleri GitHub repository secret'larına koymak deploy yapılandırmasını etkilemez. Deployment zaman'ında deployment platform'unun (Vercel, Railway, Fly.io vb.) environment variables panel'inde ayrı olarak eklenmeleri gerekir. |

## FIREBASE_PRIVATE_KEY Newline Detayı

Firebase Console'dan indirilen `serviceAccountKey.json` örneği:

```json
{
  "type": "service_account",
  "project_id": "yeedoy-498507",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBA...\n-----END RSA PRIVATE KEY-----\n",
  "client_email": "yeedoy@yeedoy-498507.iam.gserviceaccount.com",
  ...
}
```

**Kritik:** `private_key` alanı literal `\n` karakterlerini (escaped backslash-n) içerir — gerçek newline değil.

Bu değeri env var olarak kullandığında:

#### `.env.local` (lokal dev)
```bash
FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIEpAI...\n-----END RSA PRIVATE KEY-----\n"
```
Tırnak içinde değeri `\n`'ler olarak kopyala. `fcm-client.ts` otomatik işleyecek.

#### Vercel / diğer deployment
UI copy-paste yapıyorsan, tırnaklarını çıkarıp değeri öyle ekle:
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBA...
-----END RSA PRIVATE KEY-----
```
Deployment platform otomatik olarak env var string'ine `\n` karakterlerini koyacak.

**Sonuç:** `fcm-client.ts` satır 22'de `.replace(/\\n/g, '\n')` her durumda işleri düzeltir.

## Aktivasyon Adımları

### 1. Firebase Service Account Key Oluştur

1. [Firebase Console](https://console.firebase.google.com) → proje seç veya oluştur
2. Project Settings → Service Accounts tab → "Generate new private key" → JSON indir
3. JSON dosyasından 3 değeri al:
   - `project_id` → `FIREBASE_PROJECT_ID`
   - `client_email` → `FIREBASE_CLIENT_EMAIL`
   - `private_key` → `FIREBASE_PRIVATE_KEY` (tırnak içindeki tüm içeriği, `-----BEGIN...-----END` dahil)

### 2. Lokal Test için (.env.local — ASLA commit etme)

`.env.local` dosyasını (`.gitignore` içinde) oluştur:

```bash
# .env.local (LOCAL DEV ONLY — never commit)
FIREBASE_PROJECT_ID=yeedoy-498507
FIREBASE_CLIENT_EMAIL=yeedoy@yeedoy-498507.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA...\n-----END RSA PRIVATE KEY-----\n"
```

**Not:** `FIREBASE_PRIVATE_KEY` literal `\n` karakterlerini (escaped newline) içermeli. `fcm-client.ts` bunu `.replace(/\\n/g, '\n')` ile gerçek newline'a dönüştürüyor.

Doğrulaştırma: `npm run dev` ile local server başlat, admin push kampanya sayfasından test kampanyası gönder → API yanıtında `providerNotConfigured: false` ve `sentCount > 0` görmelisin.

### 3. Production Deployment (Vercel / diğer platform)

Kullandığın deployment platform'unun (Vercel, Railway, Fly.io vb.) dashboard'unda:

1. Environment Variables → Add 3 variables (Production + Preview):
   - Name: `FIREBASE_PROJECT_ID` → Value: `yeedoy-498507`
   - Name: `FIREBASE_CLIENT_EMAIL` → Value: `yeedoy@yeedoy-498507.iam.gserviceaccount.com`
   - Name: `FIREBASE_PRIVATE_KEY` → Value: JSON'dan kopyalanan `private_key` alanı (tırnak başında \n'lerle başlar, end'de \n'lerle biter)
2. Deploy tetikle
3. Deployment tamamlandıktan sonra push kampanya API otomatik olarak aktif hale gelir

### 4. GitHub Secrets (İsteğe bağlı — CI workflow'ları için)

GitHub Actions workflow'ları Firebase services'ine erişmesi gerekiyorsa, aynı 3 secret'ı ` GitHub → Repository Settings → Secrets` altına ekle. Ancak web deployment için gerekli değildir.

**Uyarı:** Şu an CI workflow'larında hiçbiri Firebase secrets'ları kullanmıyor.

## providerNotConfigured Nasıl Anlaşılır?

Admin push kampanya API endpoint: `POST /api/sunucu/yonetici/push-kampanyalari`

### Senaryo 1: Env Var Eksikse (Deployment öncesi veya lokal yardım yapılandırılmadıysa)

```json
{
  "ok": true,
  "sentCount": 0,
  "providerNotConfigured": true
}
```

Bu durumda:
- FCM hiç çalışmamış
- Server log: `fcm: provider not configured — FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY missing`
- Kampanya DB'ye kaydedildi (`sent_count = 0`, `sent_at = now`)
- **Aksiyon:** Runtime env var'larını ekle ve deployment yenile

### Senaryo 2: Env Var Mevcut, FCM Başarılıysa

```json
{
  "ok": true,
  "sentCount": 150,
  "providerNotConfigured": false
}
```

Bu durumda:
- FCM 150 token'a başarıyla göndermiş
- Server log: `fcm: batch send complete { success_count: 150, failure_count: 12 }`
- Kampanya DB'ye kaydedildi (`sent_count = 150`, `sent_at = now`)
- **Status:** Aktif ve çalışıyor

### Senaryo 3: Env Var Mevcut, FCM Başarısızsa (ör. auth error)

```json
{
  "ok": true,
  "sentCount": 0,
  "providerNotConfigured": false
}
```

Bu durumda:
- FCM bağlantı hatasıyla başarısız
- Server log: `fcm: send auth failed { status: 401 }` veya `fcm: failed to obtain access token`
- Kampanya DB'ye kaydedildi ama `sent_count = 0`
- **Aksiyon:** Private key, client email doğrulaması yap

## Güvenlik Notları

### Logging / PII
- FCM token değerleri **asla** loglanmaz — yalnızca `success_count` / `failure_count` loglanır
- `FIREBASE_PRIVATE_KEY` env var **asla** loglanmaz
- OAuth2 access token **asla** loglanmaz veya kullanıcıya döndürülmez
- Ham Firebase API hata detayları UI'a **dönmez** — sadece `{ error: 'internal_error' }` veya count-based yanıt

### Access Control
- Admin push kampanya route **admin-only korumalıdır** (`is_admin()` RPC guard)
- `getSegmentTokens` RPC — service role key yoksa `[]` döndürür (kampanya o iş) ve sadece warn log yazar

### Env Var Güvenliği
- `.env.local` **ASLA commit etme** → `.gitignore` içinde
- Deployment platform secrets (Vercel, Railway vb.) **UI üzerinden gir** — version control'de sakla değil
- Private key yalnızca lokal test ve deployment platform tarafından erişilebilir olmalı

## Segment Davranışı

| Segment | Kural |
|---|---|
| `all_followers` | İşletmenin tüm takipçileri |
| `new_30d` | Son 30 günde takip edenler |
| `loyal_top20`, `inactive_30d` ve diğerleri | `all_followers` ile aynı davranır (MVP scope) |
| Pasif token filtresi | `last_seen_at > 90 gün` olanlar dahil edilmez |
| Limit | Max 500 token (MVP scope) |

## Test Planı (Env Var Eklendikten Sonra)

### 1. Lokal Test

```bash
# .env.local'e Firebase 3 env var'ını ekle
npm run dev
# Admin push kampanya sayfasına git: /sunucu/yonetici/push-kampanyalari
# Test kampanyası oluştur ve gönder
```

**Beklenen yanıt:**
```json
{
  "ok": true,
  "sentCount": 50,  // veya sıfır token varsa 0
  "providerNotConfigured": false
}
```

**Server log beklentisi:**
```
fcm: batch send complete { success_count: 50, failure_count: 2 }
```

### 2. Doğrulama

- [ ] Admin push sayfasında kampanya formu çıkışı
- [ ] `providerNotConfigured: false` yanıt aldın
- [ ] `push_campaigns` tablosunda `sent_count > 0` kaydı (kontrol: `supabase > push_campaigns` tablo)
- [ ] Server log'da FCM token değerleri **yoktur** (yalnızca count görünüyor)
- [ ] `.env.local` gitignore'da ve commit edilmedi

### 3. Troubleshooting

| Sorun | Beklenen hata | Çözüm |
|---|---|---|
| Private key yanlış | `fcm: oauth token exchange returned no access_token` | Firebase Console'dan private key'i tekrar kopyala |
| Client email yanlış | `fcm: send auth failed { status: 401 }` | Service account email doğru mu kontrol et |
| Hiç token yok | `sentCount: 0, providerNotConfigured: false` | Mobil uygulamadan FCM token gönderildi mi kontrol et (user_devices) |
| Env var eksik | `sentCount: 0, providerNotConfigured: true` | Runtime env var'ları (.env.local / deployment) ekle |

### 4. Production Dağıtım

1. Deployment platform (Vercel, Railway vb.) → Environment Variables → 3 Firebase var ekle
2. Yeni deploy tetikle
3. Admin push kampanya sayfasından production'da test yap
4. `sentCount > 0` ve `providerNotConfigured: false` gözlemle
