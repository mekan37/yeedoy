# Email Delivery Integration Plan

> Status: 🟡 PARTIAL — Resend code deployed, GitHub Secrets ❌ MISSING, local .env.local ❌ missing RESEND_API_KEY (2026-06-06 verified).
> **Last updated:** 2026-06-06 (Runtime environment verified)

## Mevcut Aktivasyon Durması

| Ortam | RESEND_API_KEY | Email aktif mi? | Not |
|---|---|---|---|
| GitHub Secrets | ❌ MISSING | — | Repository secrets'ta tanımlı değil |
| Local dev (`.env.local`) | ❌ MISSING | Hayır — `provider_not_configured: true` | RESEND_API_KEY ve SUPABASE_SERVICE_ROLE_KEY eksik |
| Production runtime (Vercel veya deployment) | Hazırlanmadı | — | Deployment anında env var eklenince aktif |

**Kontrol Tarihi:** 2026-06-06 | `gh secret list --repo mekan37/yeedoy` ile doğrulandı

`resend-client.ts` su an:
```javascript
const apiKey = process.env.RESEND_API_KEY?.trim();

if (!apiKey) {
  return { success_count: 0, failure_count: 0, provider_not_configured: true };  // Fail-safe
}
```

Runtime env var yoksa otomatik olarak `provider_not_configured: true` donduruyor (fail-safe).

## Mevcut Altyapı

| Bileşen | Konum | Durum |
|---|---|---|
| `email_campaigns` tablosu | Supabase — `id, business_id, subject, html_body, target_segment, scheduled_at, sent_at, sent_count, opened_count, created_at` | Aktif |
| `business_follows.is_subscribed_email` | Supabase — consent kolonu (boolean) | Aktif |
| `business_claims` view | Supabase — RLS ile korunuyor | Aktif |
| `create_email_campaign_v1` RPC | Supabase | Aktif |
| `list_email_campaigns_v1` RPC | Supabase | Aktif |
| `estimate_email_segment_v1` RPC | Supabase | **BROKEN** — `follower_id` kolonu kullanıyor, tablo `user_id` — kullanilmayin |
| `get-opted-in-emails.ts` | `src/lib/email/get-opted-in-emails.ts` | Deployed |
| `resend-client.ts` | `src/lib/email/resend-client.ts` | Deployed |
| Owner email route | `app/sunucu/sahip/eposta-kampanya/route.ts` | Resend entegre edildi |
| Owner email page | `app/owner/marketing/email/page.tsx` | MVP |

## Broken RPC Notu

`estimate_email_segment_v1` RPC, `business_follows` tablosunu `bf.follower_id` ile sorgular.
Ancak tablo şeması `user_id` kolonunu kullanır — bu RPC hatalı sonuç verir veya hata atar.
Bu RPC'yi owner email sayfasında kullanmak yerine doğrudan `business_follows` sorgusu tercih edildi.
**Migration ile düzeltilmesi gerekiyor:** `follower_id` → `user_id`.

## Gerekli Env Var'lar

| Env Var | Zorunlu mu? | Açıklama |
|---|---|---|
| `RESEND_API_KEY` | Email gönderimi için gerekli | Resend dashboard'dan alınır |
| `RESEND_FROM_EMAIL` | Opsiyonel | Default: `noreply@yeedoy.com` |
| `SUPABASE_SERVICE_ROLE_KEY` | Opted-in listesi için gerekli | Supabase dashboard → Settings → API |

## Aktivasyon Adımları

### 1. Resend Hesabı Oluştur

1. [resend.com](https://resend.com) → hesap olustur veya giris yap
2. API Keys → "Create API Key" → "Sending access" → anahtari kopyala
3. Domains → domain dogrulama yap (DNS kaydi) — yoksa `onboarding@resend.dev` test adresi kullanilir

### 2. Lokal Test Icin (.env.local — ASLA commit etme)

`.env.local` dosyasına (`.gitignore` icinde) ekle:

```bash
# .env.local (LOCAL DEV ONLY — never commit)
RESEND_API_KEY=re_your_api_key_here
RESEND_FROM_EMAIL=noreply@yourdomain.com
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Dogrulama: `npm run dev` ile local server baslat → owner email kampanya sayfasina git →
test kampanyasi gonder → API yanitinda `provider_not_configured: false` gormelisin.

### 3. Production Deployment (Vercel / diger platform)

Deployment platform dashboard'unda (Production + Preview icin):

| Degisken | Deger |
|---|---|
| `RESEND_API_KEY` | Resend API key |
| `RESEND_FROM_EMAIL` | `noreply@yeedoy.com` (domain dogrulansa) |

Deploy tetikle → email kampanya sayfasindan test et.

## KVKK / Consent Filtresi

`getOptedInEmails()` fonksiyonu yalnizca `is_subscribed_email = true` olan kullanicilari
getirir. Bu filtre consent olmadan hic email gonderilmemesini garanti eder.

```typescript
.eq('is_subscribed_email', true)  // KVKK consent — zorunlu
```

Consent alunmamis kullanici → otomatik olarak listeden cikarilir, hata donmez.

## Guvenlik Notlari

### Logging / PII
- Recipient email adresleri **asla** loglanmaz — yalnizca `count` loglanir
- `RESEND_API_KEY` env var **asla** loglanmaz
- Ham Resend API hata detaylari UI'a **donmez** — sadece count-based yanit

### Access Control
- Owner email route **owner-only korumalidır** (`hasOwnerBusiness()` guard aktif)
- Rate limit: `3 kampanya/saat/kullanici`
- `getOptedInEmails` — service role key yoksa `[]` dondurur (kampanya DB'ye kaydedilir, email gitmez)

### Env Var Guvenligi
- `.env.local` **ASLA commit etme** → `.gitignore` icinde
- Deployment platform secrets UI uzerinden gir — version control'de sakla

## API Yanit Senaryolari

### Senaryo 1: RESEND_API_KEY Eksikse

```json
{
  "ok": true,
  "sent_to": 0,
  "provider_not_configured": true,
  "truncated": false
}
```

UI'da: "E-posta servisi henuz yapilandirilmamis" banner gosterilir.

### Senaryo 2: Basarili Gonderim

```json
{
  "ok": true,
  "sent_to": 45,
  "provider_not_configured": false,
  "truncated": false
}
```

UI'da: "Kampanya gonderildi. 45 kisiye ulasti." mesaji gosterilir.

### Senaryo 3: Opted-in Takipci Yok

```json
{
  "ok": true,
  "sent_to": 0,
  "provider_not_configured": false,
  "truncated": false
}
```

UI'da: "E-posta izni veren takipci bulunamadi." mesaji gosterilir.

## Test Plani (Env Var Eklendikten Sonra)

### 1. Lokal Test

```bash
# .env.local'e RESEND_API_KEY ekle
npm run dev
# /owner/marketing/email adresine git
# Test kampanyasi olustur ve gonder
```

**Beklenen yanit:**
```json
{
  "ok": true,
  "sent_to": 3,
  "provider_not_configured": false
}
```

**Server log beklentisi:**
```
resend: campaign send complete { success_count: 3, failure_count: 0 }
```

### 2. Dogrulama Kontrol Listesi

- [ ] `provider_not_configured: false` yanit alindi
- [ ] `email_campaigns` tablosunda `sent_count > 0` kaydi var
- [ ] Server log'da email adresleri **yoktur** (yalnizca count gozukuyor)
- [ ] `.env.local` gitignore'da ve commit edilmedi
- [ ] KVKK: yalnizca `is_subscribed_email = true` olan kullanicilar hedeflendi

### 3. Troubleshooting

| Sorun | Beklenen hata | Cozum |
|---|---|---|
| API key yanlis | `resend: send auth failed { status: 401 }` | Resend dashboard'dan key'i yenile |
| Domain dogrulanmamis | `resend: send rejected { status: 422 }` | Resend Domains'de DNS kaydi ekle |
| Service role key eksik | `get-opted-in-emails: service role key not configured` | `.env.local`'e `SUPABASE_SERVICE_ROLE_KEY` ekle |
| Env var eksik | `sent_to: 0, provider_not_configured: true` | Runtime env var'larini ekle |
