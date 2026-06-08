# Delivery Integration Status — Push / Email / SMS

> **Audit Tarihi:** 2026-06-06 | **Denetleyen:** Deployment Engineer
> **Kapsam:** Push (FCM), Email (Resend), SMS (Netgsm/İleti Merkezi TBD)
> **Yöntem:** Kod incelemesi, GitHub secrets kontrolü, `.env.local` incelemesi, TS/lint doğrulama

Bu belge, üç delivery kanalı için ayrı ayrı tutulan plan dosyalarının (`runtime-delivery-env-status.md`, `push-delivery-integration-plan.md`, `email-delivery-integration-plan.md`, `sms-delivery-integration-plan.md`) birleştirilmiş kanonik halidir; dördü de bu dosyaya taşındı ve silindi.

---

## Özet

| Kanal | Kod Durumu | GitHub Secrets | Local Env | Runtime Durumu | Risk |
|---|---|---|---|---|---|
| **Push (FCM)** | ✅ Deployed | ✅ Tamam | ✅ Yapılandırıldı | ✅ HAZIR | DÜŞÜK |
| **Email (Resend)** | ✅ Deployed | ❌ Eksik | ❌ Eksik | 🟡 PARTIAL | ORTA |
| **SMS** | ✅ Sadece route | ❌ Eksik | ❌ Eksik | 🔴 BLOCKER | YÜKSEK |

---

## 1. Push Notification (FCM) — ✅ HAZIR

### Kod ve Altyapı

| Bileşen | Konum | Durum |
|---|---|---|
| Admin push route | `uygulamalar/web/app/sunucu/yonetici/push-kampanyalari/route.ts` | ✅ Deployed, FCM entegre |
| FCM client | `uygulamalar/web/src/lib/push/fcm-client.ts` (180 satır) | ✅ Deployed |
| Token fetch | `uygulamalar/web/src/lib/push/get-segment-tokens.ts` | ✅ Deployed |
| `user_devices`, `push_campaigns` | Supabase tabloları | ✅ Şema mevcut |
| `estimate_campaign_segment_v1`, `create_push_campaign_v1` | RPC | ✅ Mevcut |
| `business_follows` | Supabase tablosu (`business_id, user_id`) | ✅ Aktif |

**Fail-safe pattern:** Env var eksikse `provider_not_configured: true` döner — asla throw etmez. FCM token / private key değerleri asla loglanmaz, yalnızca `success_count`/`failure_count` sayıları loglanır.

### Ortam Durumu

| Ortam | Firebase env var | FCM aktif mi? |
|---|---|---|
| GitHub Actions (CI) | ✅ Secret kayıtlı (2026-06-05 güncellendi: `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) | Workflow yok — CI'da kullanılmıyor |
| Local dev (`.env.local`) | ✅ Eklendi (2026-06-05) | ✅ Aktif |
| Production runtime | ❌ Henüz deploy edilmedi | Deployment anında env var eklenince aktif olur |

**Kritik ayrım:** GitHub repository secret'ları yalnızca GitHub Actions workflow'larında `${{ secrets.X }}` ile erişilebilir. Next.js server runtime'ı (`.env.local` veya production deployment env var'ları) tamamen ayrı bir katmandır — secrets eklemek deployment'ı otomatik aktive etmez.

**FCM Token Durumu (DB):** `user_devices` tablosunda 1 Android token (son görülme: 2026-05-12, >24 gün stale). iOS token: 0. Anlamlı test için aktif bir mobil oturum gerekir.

### `FIREBASE_PRIVATE_KEY` Newline Formatı (kritik detay)

Firebase Console'dan indirilen `serviceAccountKey.json` içindeki `private_key` alanı **literal `\n`** karakterleri içerir (gerçek newline değil):

```json
"private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBA...\n-----END RSA PRIVATE KEY-----\n"
```

- **`.env.local` (lokal):** Değeri tırnak içinde `\n`'ler ile aynen kopyala — `fcm-client.ts` `.replace(/\\n/g, '\n')` ile otomatik gerçek newline'a çevirir.
- **Vercel / deployment platformu:** UI'dan girerken tırnakları çıkarıp gerçek satır sonlarıyla yapıştır; platform string'e otomatik `\n` ekler.
- Sonuç: `fcm-client.ts` her iki formatı da doğru işler — **format sorunu değil, env var'ın var olup olmaması önemli**.

```javascript
const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').trim();

if (!projectId || !clientEmail || !privateKey) {
  return { success_count: 0, failure_count: 0, provider_not_configured: true };  // Fail-safe
}
```

### Aktivasyon Adımları

1. **Firebase Service Account Key oluştur:** Firebase Console → Project Settings → Service Accounts → "Generate new private key" → JSON indir → `project_id`/`client_email`/`private_key` değerlerini al
2. **Lokal test (`.env.local` — asla commit etme):**
   ```bash
   FIREBASE_PROJECT_ID=yeedoy-498507
   FIREBASE_CLIENT_EMAIL=yeedoy@yeedoy-498507.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
   ```
3. **Production (Vercel / deployment platformu):** Environment Variables → 3 değişkeni ekle (Production + Preview) → deploy tetikle → push kampanyaları otomatik aktive olur
4. **GitHub Secrets:** Web deployment için gerekli değil; yalnızca CI workflow'ları Firebase'e erişecekse eklenir (şu an hiçbir workflow kullanmıyor)

### `providerNotConfigured` Senaryoları

| Senaryo | Yanıt | Server log | Aksiyon |
|---|---|---|---|
| Env var eksik | `{ sentCount: 0, providerNotConfigured: true }` | `fcm: provider not configured` | Runtime env var ekle, redeploy |
| Başarılı gönderim | `{ sentCount: 150, providerNotConfigured: false }` | `fcm: batch send complete { success_count: 150, failure_count: 12 }` | — |
| Auth hatası | `{ sentCount: 0, providerNotConfigured: false }` | `fcm: send auth failed { status: 401 }` | Private key / client email doğrula |

### Segment Davranışı

| Segment | Kural |
|---|---|
| `all_followers` | İşletmenin tüm takipçileri |
| `new_30d` | Son 30 günde takip edenler |
| `loyal_top20`, `inactive_30d` vd. | MVP kapsamında `all_followers` ile aynı davranır |
| Pasif token filtresi | `last_seen_at > 90 gün` olanlar dahil edilmez |
| Limit | Maks 500 token (MVP) |

### Test / Doğrulama

```bash
cd uygulamalar/web && npm run dev
# /yonetici/push-kampanyalari → küçük segment (örn. "new_30d") ile test kampanyası gönder
# Beklenen: { ok: true, sentCount: N, providerNotConfigured: false }
```

- [ ] `providerNotConfigured: false` yanıtı alındı
- [ ] `push_campaigns.sent_count > 0`
- [ ] Server log'da token değeri yok (yalnızca count)
- [ ] `.env.local` gitignore'da, commit edilmedi

**Troubleshooting:** Yanlış private key → `oauth token exchange returned no access_token`; yanlış client email → `send auth failed { status: 401 }`; token yok → `sentCount: 0, providerNotConfigured: false` (mobil FCM token kaydını kontrol et).

### Production Aktivasyon Checklist

- [ ] `FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY` GitHub secrets'ta ✅ (zaten var)
- [ ] Aynı 3 değişkeni Vercel → Environment Variables'a ekle (Production + Preview)
- [ ] Yeni deployment tetikle
- [ ] Test: admin push kampanyası → `providerNotConfigured: false` bekle

---

## 2. Email (Resend) — 🟡 PARTIAL

### Kod ve Altyapı

| Bileşen | Konum | Durum |
|---|---|---|
| Owner email route | `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | ✅ Deployed, Resend entegre |
| Resend client | `uygulamalar/web/src/lib/email/resend-client.ts` (127 satır) | ✅ Deployed |
| Opted-in fetch | `uygulamalar/web/src/lib/email/get-opted-in-emails.ts` | ✅ Deployed |
| Edge function | `supabase/functions/send-email-campaign/index.ts` (193 satır) | ✅ Deployed |
| `email_campaigns` tablosu | Supabase | ✅ Şema mevcut |
| `create_email_campaign_v1`, `list_email_campaigns_v1` | RPC | ✅ Mevcut |
| `estimate_email_segment_v1` | RPC | ✅ **Düzeltildi** — bkz. not aşağıda |
| Owner email sayfası | `app/owner/marketing/email/page.tsx` | MVP |

> **Düzeltilen iddia — `estimate_email_segment_v1` artık BROKEN değil:** Bu RPC'nin `business_follows.follower_id` (var olmayan kolon) kullandığı ve hatalı sonuç verdiği iddiası, migration `supabase/migrations/20260603000010_fix_estimate_email_segment_v1.sql` ile **2026-06-05'te düzeltildi** — RPC artık `bf.business_id` / `is_subscribed_email` filtresi + `is_admin()`/`is_owner_of_business()` yetki kontrolü + `SET search_path = public` ile çalışıyor (PR #55). Bu, eski plan dosyalarında (`email-delivery-integration-plan.md`, `eksik-listesi.md`) hâlâ "BROKEN" olarak görünen ama artık güncel olmayan bir bilgiydi — denetim sırasında migration kodunun tamamı okunarak doğrulandı.

**Fail-safe pattern:**
```javascript
const apiKey = process.env.RESEND_API_KEY?.trim();
if (!apiKey) {
  return { success_count: 0, failure_count: 0, provider_not_configured: true };
}
```

### Ortam Durumu

| Ortam | `RESEND_API_KEY` | Email aktif mi? |
|---|---|---|
| GitHub Secrets | ❌ Eksik (`gh secret list` ile doğrulandı, 2026-06-06) | — |
| Local dev (`.env.local`) | ❌ Eksik | Hayır — `provider_not_configured: true` |
| Production runtime | Hazırlanmadı | Deployment anında env var eklenince aktif |

### Gerekli Env Var'lar

| Env Var | Zorunlu mu? | Açıklama |
|---|---|---|
| `RESEND_API_KEY` | Evet | resend.com Dashboard → API Keys |
| `RESEND_FROM_EMAIL` | Opsiyonel | Default: `noreply@yeedoy.com` |
| `SUPABASE_SERVICE_ROLE_KEY` | Evet (opted-in listesi için) | Supabase Dashboard → Settings → API |

### Aktivasyon Adımları

1. **Resend hesabı:** resend.com → API Keys → "Create API Key" ("Sending access") → `re_...` formatında anahtarı kopyala; Domains'te DNS doğrulaması yap (yoksa `onboarding@resend.dev` test adresi kullanılır)
2. **Lokal test (`.env.local`):**
   ```bash
   RESEND_API_KEY=re_your_api_key_here
   RESEND_FROM_EMAIL=noreply@yourdomain.com
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```
3. **Production (Vercel):** `RESEND_API_KEY` + `RESEND_FROM_EMAIL` ekle (Production + Preview) → redeploy
4. **GitHub Secrets:** Yalnızca CI için isteğe bağlı

### KVKK / Consent Filtresi

`getOptedInEmails()` yalnızca `is_subscribed_email = true` olan kullanıcıları getirir:
```typescript
.eq('is_subscribed_email', true)  // KVKK consent — zorunlu
```
Consent vermemiş kullanıcı listeden otomatik çıkarılır, hata dönmez.

### API Yanıt Senaryoları

| Senaryo | Yanıt | UI mesajı |
|---|---|---|
| `RESEND_API_KEY` eksik | `{ sent_to: 0, provider_not_configured: true }` | "E-posta servisi henüz yapılandırılmamış" |
| Başarılı gönderim | `{ sent_to: 45, provider_not_configured: false }` | "Kampanya gönderildi. 45 kişiye ulaştı." |
| Opted-in takipçi yok | `{ sent_to: 0, provider_not_configured: false }` | "E-posta izni veren takipçi bulunamadı." |

### Test / Doğrulama

```bash
cd uygulamalar/web && npm run dev
# /owner/marketing/email → test kampanyası oluştur ve gönder
# Beklenen: { ok: true, sent_to: N, provider_not_configured: false }
```

- [ ] `provider_not_configured: false` alındı
- [ ] `email_campaigns.sent_count > 0`
- [ ] Server log'da email adresi yok (yalnızca count)
- [ ] Yalnızca `is_subscribed_email = true` kullanıcılar hedeflendi (KVKK)

**Troubleshooting:** Yanlış API key → `send auth failed { status: 401 }`; doğrulanmamış domain → `send rejected { status: 422 }`; service role key eksik → `service role key not configured`.

### Güvenlik

- Alıcı email adresleri ve `RESEND_API_KEY` asla loglanmaz — yalnızca count
- Owner-only route guard (`hasOwnerBusiness()`), rate limit 3 kampanya/saat/kullanıcı
- Ham Resend API hata detayları UI'a dönmez

### Risk Değerlendirmesi

- **Mevcut:** Dev/preview kampanyaları sessizce başarısız oluyor (DB'ye `sent_count=0` ile kaydediliyor)
- **Önem derecesi:** ORTA — özellik çalışıyormuş gibi görünüyor ama teslim etmiyor
- **Düzeltme süresi:** API key alındıktan sonra <5 dakika

---

## 3. SMS (Netgsm / İleti Merkezi — TBD) — 🔴 BLOCKER

### Mevcut Durum

| Bileşen | Konum | Durum |
|---|---|---|
| SMS kampanya route | `app/sunucu/sahip/sms-kampanya/route.ts` | ✅ Deployed (route only) |
| Ownership guard (`hasOwnerBusiness()`) | route içinde | ✅ Aktif |
| Rate limit (3/saat/kullanıcı) | route içinde | ✅ Aktif |
| Zod input validation | `schema.safeParse()` | ✅ Aktif |
| Gerçek SMS gönderimi | — | ❌ `// TODO: integrate with Netgsm/Twilio` |
| `sms_campaigns` tablosu | Supabase migration | ❌ Yok — route `as any` ile bypass ediyor |
| `is_subscribed_sms` opt-in | `business_follows`/`user_profiles` | ❌ Yok |
| `user_profiles.phone` | migration | ❌ Yok |
| Opt-out (STOP) handler | endpoint | ❌ Yok |
| KVKK rıza kaydı | `consented_at`/`consent_source` | ❌ Yok |

Mevcut route davranışı: `business_follows`/`loyalty_cards`'dan abone sayısını kabaca tahmin ediyor, `sms_campaigns`'a kayıt atıyor (migration yok), `is_subscribed_sms` filtresi yapmıyor, gerçek gönderim yapmıyor — `sentCount` yalnızca tahmin.

### KVKK / Ticari Elektronik İleti Mevzuatı (Türkiye)

**6563 Sayılı Kanun:**
- Alıcının açık rızası olmadan ticari SMS gönderilemez; rıza önceden, gönüllü ve spesifik olmalı
- Opt-out istekleri en geç 3 iş günü içinde işlenmeli
- Gönderici kimliği açıkça belirtilmeli

**IYS — İleti Yönetim Sistemi:**
- Türkiye'de B2C ticari elektronik ileti göndericileri için zorunlu kayıt sistemi
- Tüm izinler ve opt-out'lar IYS'e yansıtılmalı
- Netgsm ve İleti Merkezi gibi yerel sağlayıcılar IYS entegrasyonunu otomatik sağlar

**Tutulması gereken consent kaydı:** `consented_at` (opt-in tarihi), `consent_source` (`loyalty_signup`/`follow_form`/`checkout`), opsiyonel IP (KVKK'ya dikkatle).

### Provider Seçenekleri

| Provider | Kapsam | IYS Entegrasyonu | Not |
|---|---|---|---|
| **Netgsm** | Türkiye | Mevcut (direkt) | Yerel, yaygın, Türkiye numara kaynağı |
| **İleti Merkezi** | Türkiye | Mevcut (direkt) | Yerel, IYS uyumlu API |
| Verimor | Türkiye | Mevcut | Yerel, API tabanlı |
| Twilio | Global | Manuel | IYS entegrasyonu geliştirici tarafından yapılmalı |

**Öneri:** Netgsm veya İleti Merkezi (yerel IYS uyumluluğu).

### Gerekli Env Var İsimleri (değer değil)

```
SMS_PROVIDER=netgsm|ileti-merkezi|twilio
SMS_API_KEY=
SMS_API_SECRET=
SMS_SENDER_ID=
```
`.env.example`'da bu değişkenler henüz tanımlı değil.

### Teknik Tasarım — MVP Adımları

1. **Migration `user_profiles.phone`:**
   ```sql
   ALTER TABLE user_profiles ADD COLUMN phone text;
   ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_phone_format
     CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{7,14}$');
   ```
2. **Migration `business_follows.is_subscribed_sms` + consent kolonları:**
   ```sql
   ALTER TABLE business_follows ADD COLUMN is_subscribed_sms boolean NOT NULL DEFAULT false;
   ALTER TABLE business_follows ADD COLUMN sms_consented_at timestamptz;
   ALTER TABLE business_follows ADD COLUMN sms_consent_source text;
   ```
3. **Migration `sms_campaigns` tablosu** — `id, business_id, message, segment, sent_count, status, scheduled_at, sent_at, created_by, created_at` + RLS politikaları (`business_claims` üzerinden owner erişimi — bkz. eski plan dosyasında tam SQL)
4. **Provider helper `src/lib/sms/sms-client.ts`** — push/email ile aynı fail-safe pattern:
   ```typescript
   export async function sendSmsToRecipients(phoneNumbers: string[], message: string, senderId: string) {
     const apiKey = process.env.SMS_API_KEY?.trim();
     const provider = process.env.SMS_PROVIDER?.trim();
     if (!apiKey || !provider) {
       return { success_count: 0, failure_count: 0, provider_not_configured: true };
     }
     // Provider-specific implementation
   }
   ```
5. **Route güncelleme:** `is_subscribed_sms = true` filtresi + `user_profiles.phone` join + `sms-client.ts` çağrısı + `sent_count`/`sent_at` güncelleme
6. **Opt-out endpoint** `POST /api/sms/unsubscribe`: STOP komutu webhook handler, `is_subscribed_sms = false` güncelleme, IYS bildirimi, maks 3 iş günü SLA

### Blokerler ve Efor Tahmini

| # | Kalem | Efor |
|---|---|---|
| 1 | SMS sağlayıcı kararı (Netgsm / İleti Merkezi / Twilio) | 1 saat (karar) |
| 2 | `user_profiles.phone` migration | 30 dk |
| 3 | `business_follows.is_subscribed_sms` migration | 30 dk |
| 4 | `sms_campaigns` tablo migration | 1 saat |
| 5 | `src/lib/sms/sms-client.ts` adapter | 2-4 saat (sağlayıcıya bağlı) |
| 6 | Route güncelleme — consent filtresi + phone join | 1 saat |
| 7 | Opt-out endpoint + IYS webhook handler | 3-4 saat |
| 8 | KVKK + IYS kaydı | 2-8 saat (hukuki/uyumluluk) |

**Toplam tahmini efor:** 12-20 saat

### Rollout Planı

1. Migrasyonlar uygulanmalı + provider seçilmeli + env var'lar hazırlanmalı
2. Alpha: admin test segmentiyle dry-run (kendi numaranıza SMS)
3. Owner beta: 1 işletme sahibiyle kontrollü test kampanyası
4. Rate limit doğrulaması: günlük maks ~1000 SMS / kampanya önerisi (burst koruması)
5. Production rollout: yalnızca IYS kaydı tamamlandıktan sonra

### Risk Değerlendirmesi

- **Mevcut:** Route istek kabul ediyor ama hiçbir şey göndermiyor; DB kayıtları `sent_count=0` gösteriyor
- **Önem derecesi:** YÜKSEK — özellik çalışıyormuş gibi görünüyor ama veri toplama + consent altyapısı yok
- **Uyumluluk riski:** Orta-Yüksek (consent altyapısı olmadan etkinleştirilirse KVKK/IYS ihlali)

> **HOLD — SMS kampanyalarını şunlar tamamlanmadan etkinleştirme:** migrasyonlar deploy edilmeli, telefon toplama aktif olmalı, consent altyapısı kurulmalı, provider seçilip kimlik bilgileri alınmalı, KVKK+IYS kaydı tamamlanmalı, opt-out handler test edilmeli.

---

## Build & Doğrulama Özeti (2026-06-06 14:22 UTC)

```bash
cd uygulamalar/web
npm run typecheck  # ✅ Hata yok
npm run lint       # ✅ Uyarı yok (ESLint)
```

**Güvenlik kontrolleri:**
- ✅ Kodda hardcoded API key/token yok
- ✅ Tüm kanallarda fail-safe pattern (`provider_not_configured`)
- ✅ PII/credential'lar loglanmıyor (yalnızca count-bazlı metrikler)
- ✅ Tüm route'larda rate limiting aktif
- ✅ Owner/admin yetki guard'ları yerinde
- ✅ `.env.local` `.gitignore`'da (commit edilmemiş)

---

## Öneriler

**Hemen (sıradaki sprint):**
1. `RESEND_API_KEY`'i production'a ekle — düşük efor, owner email'i açar (risk: düşük, fail-safe zaten yerinde, <5 dk konfigürasyon)
2. Production'da FCM delivery'yi izle — başarı oranları, token listesi doğruluğu, hata kalıpları

**Takip (yol haritası):**
1. SMS altyapısı — sıradaki sprint için planla (12-20 saat tahmini); provider kararı, migrasyonlar + consent akışları, KVKK/IYS uyumluluğu
2. Email analitiği — faz 2 (open/click tracking, dashboard metrikleri)
3. Push bildirim analitiği — faz 2 (delivery raporlama, kullanıcı etkileşimi)

---

## Denetim Notları

- **Kod kalitesi:** Tüm delivery kodu aynı fail-safe pattern'i izliyor — tutarlılık iyi
- **Güvenlik duruşu:** PII/credential'lar düzgün korunuyor; loglama güvenli
- **Uyumluluk:** Email consent filtrelenmiş ✅; SMS consent eksik ❌; Push consent gerekmiyor (cihaz seviyesinde)
- **Test:** Lokal `.env.local` manuel test için etkin; delivery kanalları için otomatik entegrasyon testi yok

**Sonraki inceleme önerisi:** Production email + FCM aktivasyonundan sonra (önerilen tarih: 2026-06-10)

---

## İlgili Belgeler

- `docs/security/account-security.md` — SMS 2FA neden tercih edilmedi bağlamı
- `docs/kalan-isler.md` — SMS altyapı kurulumu açık iş kalemi
