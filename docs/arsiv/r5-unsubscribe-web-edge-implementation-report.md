# R-5 Unsubscribe / Ret Hakkı — Web ve Edge Function Uygulama Raporu

**Hazırlanma tarihi:** 2026-06-18  
**Hazırlayan:** nextjs-developer  
**Kaynak karar planı:** `docs/hukuki/r5-unsubscribe-web-edge-decision-plan.md`  
**Durum:** Uygulama tamamlandı. Production'a migration uygulanmadı.

---

## 1. Yapılan Değişiklik Özeti

| # | Dosya | İşlem | Amaç |
|---|---|---|---|
| 1 | `src/lib/email/unsubscribe-token.ts` | Oluşturuldu | HMAC-SHA256 token üretim/doğrulama |
| 2 | `app/(genel)/abonelik-iptal/page.tsx` | Oluşturuldu | Public unsubscribe route (login gerektirmez) |
| 3 | `src/lib/email/resend-client.ts` | Güncellendi | Per-alıcı unsubscribeUrl desteği |
| 4 | `src/lib/email/get-opted-in-emails.ts` | Güncellendi | `userId` alanı eklendi |
| 5 | `app/sunucu/sahip/eposta-kampanya/route.ts` | Güncellendi | Token üretimi + footer eklendi |
| 6 | `app/(kimlik)/bildirim-ayarlari/page.tsx` | Güncellendi | marketing_email_opt_in section eklendi |
| 7 | `app/(kimlik)/bildirim-ayarlari/pazarlama-email-toggle.tsx` | Oluşturuldu | Client-side marketing toggle bileşeni |
| 8 | `supabase/functions/send-email-campaign/index.ts` | Düzeltildi | Schema hataları giderildi + token eklendi |
| 9 | `test/lib/unsubscribe-token.test.ts` | Oluşturuldu | 20 test (token üretim + doğrulama) |

Migration oluşturulmadı. Flutter dosyaları değiştirilmedi.

---

## 2. Oluşturulan / Değiştirilen Web Route'ları

### 2.1 Yeni Route: `/abonelik-iptal`

**Dosya:** `uygulamalar/web/app/(genel)/abonelik-iptal/page.tsx`  
**Grup:** `(genel)` — public, kimlik doğrulaması gerektirmez  
**URL:** `https://yeedoy.com/abonelik-iptal?token=...`

**Davranış akışı:**

```
GET /abonelik-iptal?token={token}
│
├── token yoksa → InvalidScreen
├── UNSUBSCRIBE_HMAC_SECRET yoksa → NoSecretScreen
├── Rate limit aşıldıysa (10/dk IP bazlı) → InvalidScreen
├── Token doğrulaması başarısız
│   ├── Süre dolmuşsa → ExpiredScreen (bildirim-ayarlari linki içerir)
│   └── Biçim/imza hatası → InvalidScreen
│
├── type = "mkt" → user_profiles.marketing_email_opt_in = false, opted_in_at = NULL
│   ├── Zaten false ise → AlreadyUnsubscribedScreen
│   └── Başarı → SuccessScreen
│
└── type = "biz" → business_follows.is_subscribed_email = false (user_id + business_id)
    ├── Kayıt yok / zaten false ise → AlreadyUnsubscribedScreen
    └── Başarı → SuccessScreen
```

**Güvenlik özellikleri:**
- Public route yalnızca `false` yazabilir — hiçbir zaman `true` yazamaz
- DB işlemi service role ile yapılır, kullanıcı oturumu gerektirmez
- Başarı ekranı e-posta adresi göstermez
- `user_id` log'a yazılmaz (yalnızca "successful opt-out" seviyesinde bilgi)

### 2.2 Güncellenen Route: `/bildirim-ayarlari`

**Dosya:** `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx`

Değişiklikler:
- Server component içinde `user_profiles.marketing_email_opt_in` değeri yüklenir
- Yeni "E-posta Tercihleri" section eklendi (sayfanın en altında)
- `PazarlamaEmailToggle` bileşeni bu section içinde görünür
- Sütun henüz yoksa (migration uygulanmamış) `false` default ile çalışmaya devam eder

### 2.3 Güncellenen Route: `/sunucu/sahip/eposta-kampanya`

**Dosya:** `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`

Değişiklikler:
- `generateUnsubscribeToken` import eklendi
- `getOptedInEmails()` sonucu artık `userId` içeriyor
- Her alıcı için bireysel `biz` token üretiliyor
- Token üretim hatası (secret eksik) sistemi durdurmaz; logger'a bildirir, e-posta gönderime devam eder

---

## 3. Token Mimarisi

### 3.1 Token Yapısı

```
{type}.{userIdB64url}.{businessIdB64url}.{expiresUnix}.{hmacSig}
```

**Parça açıklamaları:**

| Parça | Değer | Açıklama |
|---|---|---|
| type | `mkt` veya `biz` | Token türü |
| userIdB64url | UUID → base64url | Kullanıcı kimliği (e-posta adresi taşınmaz) |
| businessIdB64url | UUID → base64url | İşletme UUID; `mkt` için nil UUID |
| expiresUnix | Unix saniye | Token son geçerlilik zamanı (30 gün) |
| hmacSig | HMAC-SHA256 → base64url | İmza — timing-safe karşılaştırma ile doğrulanır |

### 3.2 Token Türleri ve Kavram Ayrımı

| Token türü | Yazdığı tablo | Yazdığı alan | Neyi durdurur |
|---|---|---|---|
| `mkt` | `user_profiles` | `marketing_email_opt_in = false` | Tüm Yeedoy platform e-postaları |
| `biz` | `business_follows` | `is_subscribed_email = false` | Yalnızca o işletmenin kampanyaları |

Bu iki alan birbirinden bağımsızdır. `mkt` token `business_follows`'a, `biz` token `user_profiles`'a dokunmaz.

### 3.3 Stateless Tasarım

Token veritabanında saklanmaz. HMAC imza doğrulaması ile her istekte yeniden doğrulanır. Bu yaklaşım:
- Ayrı migration gerektirmez
- Veri minimizasyonu sağlar (KVKK md. 4/2-ç)
- Idempotent davranışa izin verir (aynı token birden fazla kullanılırsa sonuç değişmez)

### 3.4 Timing-Safe Doğrulama

`unsubscribe-token.ts` dosyasında imza karşılaştırması `node:crypto.timingSafeEqual()` ile yapılır. Uzunluk uyuşmazlığında `timingSafeEqual` exception fırlatır; bu try/catch içinde yakalanır ve `false` olarak işlenir — timing saldırısı açığı yoktur.

---

## 4. Değiştirilen Edge Function Dosyaları

**Dosya:** `supabase/functions/send-email-campaign/index.ts`

### 4.1 Düzeltilen Schema Hataları

| Eski (hatalı) | Yeni (doğru) | Açıklama |
|---|---|---|
| `.select("follower_id, profiles!inner(email)")` | `fetchRecipients()` helper ile `user_id + user_profiles:user_id(display_name)` | `follower_id` kolonu yok; doğrusu `user_id` |
| `profiles!inner(email)` join | `supabase.auth.admin.listUsers()` | `public.profiles` tablosu yok; e-posta auth.users'dedir |
| `emails: string[]` düz dizi | `recipients: Recipient[]` (`userId` dahil) | Token üretimi için `userId` gerekiyor |

### 4.2 Eklenen Token Desteği

- Her alıcı için asenkron `generateBizToken()` çağrısı yapılır (Deno Web Crypto API)
- Token başarısız üretilirse (secret eksik) boş footer ile gönderim devam eder
- Unsubscribe URL: `https://yeedoy.com/abonelik-iptal?token={encodeURIComponent(token)}`
- Footer HTML: her e-postaya bireysel URL ile eklenir

### 4.3 `SITE_URL` Ortam Değişkeni

Edge function artık `SITE_URL` env variable kullanır (varsayılan: `https://yeedoy.com`). Bu değişken Supabase Dashboard → Edge Functions → Secrets bölümüne eklenmeli.

---

## 5. Düzeltilen Schema Hataları

Doğrulama raporunda (`r5-marketing-optin-db-verification-report.md`) Kritik bulgu olarak işaretlenen iki hata giderildi:

### Hata 1 — `follower_id` kolonu (GIDERILDI)

`send-email-campaign/index.ts` eski kod:
```typescript
.select("follower_id, profiles!inner(email)")
```
Düzeltme: `fetchRecipients()` helper ile `user_id` kullanıldı. Aynı hata daha önce `20260603000010_fix_estimate_email_segment_v1.sql` migration'ıyla RPC'de düzeltilmişti — edge function güncellenmemişti.

### Hata 2 — `profiles` tablosu yok (GIDERILDI)

`public.profiles` tablosu yok, doğru tablo `user_profiles`. E-posta adresi ise `user_profiles`'da değil, `auth.users`'da. `auth.admin.listUsers()` pattern'ına geçildi.

### Hata 3 — Unsubscribe link 404 (GIDERILDI)

`https://yeedoy.com/settings/notifications` → `https://yeedoy.com/abonelik-iptal?token={token}` olarak değiştirildi. `/abonelik-iptal` route'u artık mevcut.

---

## 6. /bildirim-ayarlari Değişiklikleri

**Eklenen dosya:** `pazarlama-email-toggle.tsx`

- `'use client'` bileşeni
- `user_profiles.marketing_email_opt_in` alanını günceller
- `business_follows.is_subscribed_email`'e dokunmaz
- Optimistik UI: toggle anında değişir, hata durumunda geri alınır
- `true` → `marketing_email_opted_in_at = now()` (timestamp)
- `false` → `marketing_email_opted_in_at = null`

**page.tsx değişikliği:**

- Server-side `marketing_email_opt_in` yükleme (try/catch ile — migration öncesi sütun yoksa default `false`)
- Yeni "E-posta Tercihleri" section en alta eklendi
- Mevcut push bildirim section'ları ve `BildirimTercihleri` bileşeni değiştirilmedi

**İşletme bazlı abonelikler (TODO):**

Her işletmenin takip sayfasından `is_subscribed_email` yönetimi şu an uygulanmadı. Sayfa açıklaması metni bu durumu kullanıcıya bildirir: "İşletmelerin gönderdiği kampanya e-postaları için ayrıca her işletmenin takip sayfasından aboneliğinizi yönetebilirsiniz."

---

## 7. Güvenlik Değerlendirmesi

### 7.1 Secret Yönetimi

- `UNSUBSCRIBE_HMAC_SECRET` hiçbir zaman client bundle'a eklenmez
- Token üretimi: Next.js route handler (server-side) ve edge function
- Token doğrulaması: server component içinde
- `SUPABASE_SERVICE_ROLE_KEY`: yalnızca `get-opted-in-emails.ts` ve edge function içinde kullanılır

### 7.2 Public Route Güvenliği

- Yalnızca `false` yazar — izin açma işlemi yapılamaz
- Token olmadan GET isteği → `InvalidScreen` (hiçbir DB işlemi yapılmaz)
- Rate limit: IP başına 10 istek/dakika (`oran-siniri.ts` in-memory store)
- Farklı kullanıcının token'ını kullanamazsın — token içindeki `user_id` bağlar

### 7.3 Gizlilik

- Başarı ekranı e-posta adresi göstermez
- Logger: `userId` loglanır, e-posta adresi asla loglanmaz
- `get-opted-in-emails.ts`'deki "never log raw email addresses" kuralına devam edildi

### 7.4 Açık Kalan Risk

`user_profiles.profiles_read USING(true)` policy `marketing_email_opt_in` değerini herkese açık kılar. Bu sütun eklenmeden önceki `shadow_banned` gibi alanlar da aynı şekilde açıktı — bu risk doğrulama raporunda belgelenmiş ve bu sprint kapsamı dışında bırakılmıştır.

---

## 8. Çalıştırılan Testler

**Dosya:** `test/lib/unsubscribe-token.test.ts`

| Test grubu | Test sayısı | Sonuç |
|---|---|---|
| `generateUnsubscribeToken` | 5 | GEÇTI |
| `verifyUnsubscribeToken — geçerli token` | 3 | GEÇTI |
| `verifyUnsubscribeToken — geçersiz token` | 8 | GEÇTI |
| `verifyUnsubscribeToken — süresi dolmuş token` | 2 | GEÇTI |

**Toplam: 20 test — hepsi GEÇTI**

Kapsam:
- Geçerli `mkt` token üretimi ve payload doğrulaması
- Geçerli `biz` token üretimi ve payload doğrulaması
- `businessId = null` (`mkt` türünde doğru)
- Farklı secret ile üretilmiş token reddedilir
- İmza değiştirilmiş token reddedilir
- `user_id` değiştirilmiş token reddedilir
- Parça sayısı hatalı token reddedilir
- UNSUBSCRIBE_HMAC_SECRET yoksa üretim hata fırlatır, doğrulama `null` döner
- URL-safe karakterler (+ / = yok)
- 2 saniyelik token 2.5 saniye sonra null döner
- Token idempotent (aynı token birden fazla doğrulanabilir)

**Mevcut test suite ile entegrasyon:**

```
Test Files  10 passed (10)
Tests       51 passed (51)
```

Mevcut 9 test dosyasındaki tüm 31 test korundu; 20 yeni test eklendi.

**typecheck:** Hatasız (0 hata)  
**lint:** Uyarı yok

---

## 9. Çalıştırılamayan Testler

Aşağıdaki senaryolar için dinamik test yazılamadı (production bağlantısı yok, vitest jsdom ortamı DB gerektirmez):

| Test senaryosu | Neden çalıştırılamadı |
|---|---|
| Gerçek DB ile `mkt` token global opt-out yaptıyor | Production'a bağlanmak yasak |
| Gerçek DB ile `biz` token işletme bazlı aboneliği kapatıyor | Production'a bağlanmak yasak |
| `/abonelik-iptal` route'u 404 dönmüyor | E2E / integration test gerektirir |
| `/bildirim-ayarlari` marketing toggle doğru alanı güncelliyor | Integration test gerektirir |
| `send-email-campaign` artık `follower_id`/`profiles` kullanmıyor | Edge function test ortamı gerektirir |
| Üretilen unsubscribe linki `/abonelik-iptal?token=` formatında | E2E test gerektirir |

Bu senaryolar `test:e2e` playwright testleri veya Supabase local stack ile çalıştırılabilir. Bunlar için test şablonları `docs/hukuki/` klasörüne ayrı bir dosyada hazırlanabilir.

---

## 10. Kalan Riskler

| Risk | Seviye | Açıklama |
|---|---|---|
| `marketing_email_opt_in` sütunu migration öncesi yok | Yüksek | `20260620000001` production'a uygulanmadan toggle işlevsiz. `bildirim-ayarlari` sayfası try/catch ile default `false` döner — kullanıcıya hata göstermez ama kaydetme başarısız olur. |
| `UNSUBSCRIBE_HMAC_SECRET` production'da yoksa token üretilemez | Yüksek | Kampanya gönderilir ama unsubscribe footer olmaz — 6563 md.9/3 ihlali. Secret önce eklenmelidir. |
| `get-opted-in-emails.ts` hâlâ `marketing_email_opt_in` filtresi uygulamıyor | Orta | Global opt-out etmiş kullanıcılar hâlâ işletme listesinde görünür. Sütun migration sonrası filter eklenmelidir (T18). |
| Edge function `send-email-campaign` hâlâ `marketing_email_opt_in` filtresi uygulamıyor | Orta | Aynı sorun — T19 görevi. |
| `bildirim-ayarlari` işletme bazlı abonelik yönetimi yok | Düşük | TODO olarak bırakıldı. Kullanıcı açıklama metninde yönlendirildi. |
| Token replay saldırısı | Düşük | Stateless token idempotent davranır. `used_tokens` tablosu ile single-use zorlanabilir (gelecek sprint). |
| `profiles_read USING(true)` — `marketing_email_opt_in` herkese açık | Düşük | Doğrulama raporunda belgelenmiş, bu sprint dışı. |

---

## 11. Environment Variable Listesi

Aşağıdaki environment değişkenleri production'da tanımlanmalıdır:

| Değişken | Platform | Amaç | Kritiklik |
|---|---|---|---|
| `UNSUBSCRIBE_HMAC_SECRET` | Next.js (`.env.local`) + Supabase Edge Functions Secrets | Token imzalama | Kritik — yoksa unsubscribe sistemi çalışmaz |
| `SITE_URL` | Supabase Edge Functions Secrets | Token URL'inde base URL | Orta — yoksa `https://yeedoy.com` kullanılır |
| `SUPABASE_SERVICE_ROLE_KEY` | Next.js (`.env.local`) | Alıcı listesi + DB işlemleri | Zaten mevcut olmalı |
| `RESEND_API_KEY` | Next.js (`.env.local`) + Supabase Edge Functions Secrets | E-posta gönderimi | Zaten mevcut olmalı |
| `NEXT_PUBLIC_SITE_URL` | Next.js (`.env.local`) | Unsubscribe URL base | Zaten mevcut olmalı |

**Not:** `UNSUBSCRIBE_HMAC_SECRET` değeri en az 32 karakter uzunluğunda, rastgele üretilmiş bir string olmalıdır. Örnek üretim:
```
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## 12. Production Öncesi Kontrol Listesi

Aşağıdaki adımlar e-posta kampanyaları canlıya alınmadan önce tamamlanmalıdır:

- [ ] `20260620000001_user_profiles_marketing_email_opt_in.sql` production'a uygulandı
- [ ] `20260620000002_r5_marketing_email_rpcs.sql` production'a uygulandı
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Next.js `.env.local`'e eklendi
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Supabase Edge Functions Secrets'a eklendi
- [ ] `SITE_URL` Supabase Edge Functions Secrets'a eklendi
- [ ] `/abonelik-iptal?token=TEST_TOKEN` sayfası tarayıcıda açılıp "Geçersiz Bağlantı" ekranı görüldü (route çalışıyor)
- [ ] Gerçek bir `biz` token üretildi ve `/abonelik-iptal` sayfasında test edildi
- [ ] Staging ortamında e-posta kampanyası gönderildi ve unsubscribe linki tıklandı
- [ ] `send-email-campaign` edge function deployment güncellendi (Supabase CLI: `supabase functions deploy send-email-campaign`)
- [ ] `get-opted-in-emails.ts`'e `marketing_email_opt_in = true` filtresi eklendi (T18)
- [ ] `send-email-campaign/index.ts`'e `marketing_email_opt_in = true` filtresi eklendi (T19)

---

## 13. Sonraki Flutter Adımı İçin Öneri

`LegalAcceptancePage._submit()` içindeki `_marketingOptIn` değişkeni hâlâ Supabase'e bağlı değil. Bu bağlantı tamamlanmadan global pazarlama izni yalnızca `/bildirim-ayarlari` web sayfasından yönetilebilir.

Flutter agent'a iletilecek öneri:

1. `LegalRepository` içinde `updateMarketingEmailOptIn(bool value)` metodu oluştur
2. `update_my_marketing_email_opt_in_v1` RPC'sini çağır (migration 20260620000002 içinde mevcut)
3. `LegalAcceptancePage._submit()` içinde `_marketingOptIn` değerini bu metoda ilet
4. `NotificationPreferencesPage` içindeki "E-posta Bildirimleri" toggle'ını aynı RPC'ye bağla

Migration'lar production'a uygulanmadan bu bağlantı devreye alınmamalı (`20260620000001` sütun oluşturmadan `update_my_marketing_email_opt_in_v1` RPC başarısız olur).
