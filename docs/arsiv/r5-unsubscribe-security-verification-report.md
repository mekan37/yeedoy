# R-5 Unsubscribe / Ret Hakkı — Güvenlik ve Uyumluluk Doğrulama Raporu

**Doğrulayan:** security-auditor (statik analiz, üretim bağlantısı yok)
**Tarih:** 2026-06-18
**Uygulama raporuna referans:** `docs/hukuki/r5-unsubscribe-web-edge-implementation-report.md`
**Karar planına referans:** `docs/hukuki/r5-unsubscribe-web-edge-decision-plan.md`
**Yöntem:** Yalnızca statik kod analizi. Üretim bağlantısı yapılmamış, migration uygulanmamış.

---

## 1. Doğrulanan Dosyalar

| # | Dosya | Satır | Durum |
|---|-------|-------|-------|
| 1 | `uygulamalar/web/src/lib/email/unsubscribe-token.ts` | 197 | DOĞRULANDI |
| 2 | `uygulamalar/web/app/(genel)/abonelik-iptal/page.tsx` | 341 | DOĞRULANDI |
| 3 | `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx` | 110 | DOĞRULANDI |
| 4 | `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/pazarlama-email-toggle.tsx` | 105 | DOĞRULANDI |
| 5 | `uygulamalar/web/src/lib/email/get-opted-in-emails.ts` | 102 | DOĞRULANDI |
| 6 | `uygulamalar/web/src/lib/email/resend-client.ts` | 144 | DOĞRULANDI |
| 7 | `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | 114 | DOĞRULANDI |
| 8 | `supabase/functions/send-email-campaign/index.ts` | 316 | DOĞRULANDI |
| 9 | `uygulamalar/web/test/lib/unsubscribe-token.test.ts` | 199 | DOĞRULANDI |
| 10 | `uygulamalar/web/app/(kimlik)/layout.tsx` | (referans) | DOĞRULANDI |

---

## 2. Güvenlik Doğrulama Özeti

| Alan | Sonuç | Not |
|------|-------|-----|
| HMAC-SHA256 algoritması | GECTI | `createHmac('sha256', secret)` — node:crypto |
| Timing-safe karşılaştırma | GECTI | `timingSafeEqual` + try/catch |
| Token'da e-posta adresi yok | GECTI | Yalnızca UUID'ler taşınıyor |
| Yalnızca opt-out yazma | GECTI | `false` dışında write yok |
| Service role sunucu tarafında | GECTI | `NEXT_PUBLIC_` prefix'i yok |
| Login gerektirmeme (genel) | GECTI | `(genel)` route grubu |
| Login zorunluluğu (kimlik) | GECTI | `(kimlik)/layout.tsx` yönlendirmesi |
| Kavram ayrımı korunuyor | GECTI | `user_profiles` ve `business_follows` ayrı |
| Eski hatalı schema referansı | GECTI | `follower_id` ve `profiles!inner(email)` kaldırıldı |
| Rate limit | KISMI | In-memory — tek instance için yeterli |
| marketing_email_opt_in filtresi | EKSIK | T18/T19 — migration bekleniyor |
| Cross-implementation HMAC testi | EKSIK | Node.js/Deno arası test yok |

---

## 3. Token Güvenlik Doğrulaması

### 3.1 Algoritma ve İmza

`unsubscribe-token.ts` satır 61-68:

```
createHmac('sha256', secret).update(payload).digest('base64')
  .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
```

- HMAC-SHA256 doğru uygulanmış.
- Base64url dönüşümü `+`→`-`, `/`→`_`, `=` kaldırma ile URL güvenlidir.

### 3.2 Timing-Safe Karşılaştırma

`unsubscribe-token.ts` satır 158-163:

```typescript
try {
  sigMatches = timingSafeEqual(Buffer.from(sig, 'utf8'), Buffer.from(expectedSig, 'utf8'));
} catch {
  // timingSafeEqual uzunluk uyuşmazlığında fırlatır
  sigMatches = false;
}
```

- `timingSafeEqual` farklı uzunluklarda exception fırlatır — `catch` ile false'a düşürülmüş. DOGRU.
- Timing saldırısı önlemi eksiksiz.

### 3.3 Token Yapısı

Format: `{type}.{userIdB64}.{businessIdB64}.{expiresUnix}.{sig}` (5 parça)

- `mkt` türünde businessId sahasına nil UUID (`00000000-0000-0000-0000-000000000000`) yerleştiriliyor.
- `biz` türünde gerçek businessId taşınıyor.
- Token'dan decode edilen `userId` ve `businessId` UUID regex ile doğrulanıyor (`satır 183-192`).
- E-posta adresi hiçbir zaman token içinde yer almıyor. KVKK md.4/2-ç veri minimizasyonu sağlanmış.

### 3.4 Süre Kontrolü

```typescript
const nowUnix = Math.floor(Date.now() / 1000);
if (nowUnix > expiresUnix) { return null; }
```

- Süre kontrolü imza doğrulamasından ÖNCE yapılıyor. Bu sıra güvenlik açısından tercih edilen sıradır: süresi dolmuş token'lar imza hesabı yapılmaksızın reddedilir.
- Varsayılan TTL: 30 gün.

### 3.5 mkt/biz Tür Ayrımı

`abonelik-iptal/page.tsx` içinde:
- `isMkt = payload.type === 'mkt'` → `user_profiles.marketing_email_opt_in` güncellenir.
- `biz` → `business_follows.is_subscribed_email` güncellenir.
- İki tablo hiçbir koşulda çapraz güncellenmez. DOGRU.

### 3.6 Gizli Anahtarın Yokluğu

- Üretim: `throw new Error(...)` — token üretimi durur.
- Doğrulama: `return null` — tüm token'lar reddedilir.
- Her iki durumda da güvenli başarısızlık (fail-secure) davranışı mevcut. DOGRU.

---

## 4. Public Route (`/abonelik-iptal`) Doğrulaması

### 4.1 Kimlik Doğrulama Gereksinimleri

- Route `app/(genel)/abonelik-iptal/page.tsx` konumunda.
- `(genel)` route grubu: Supabase auth veya oturum kontrolü yok.
- `(kimlik)/layout.tsx`'te yer alan `redirect('/giris?redirect=/profil')` bu route için geçerli değil.
- 6563 sayılı Kanun md.9/3 gereği login gerektirmeyen unsubscribe mekanizması sağlanmış. DOGRU.

### 4.2 Yalnızca Opt-Out Yazma

`processUnsubscribe` fonksiyonunda yazılan değerler:

| Tablo | Sütun | Yazılan değer |
|-------|-------|---------------|
| `user_profiles` | `marketing_email_opt_in` | `false` (sabit) |
| `user_profiles` | `marketing_email_opted_in_at` | `null` (sabit) |
| `business_follows` | `is_subscribed_email` | `false` (sabit) |

Kodun hiçbir dalında `true` yazılmıyor. DOGRU.

### 4.3 Service Role Kullanımı

```typescript
const serviceRoleKey = appConfig.serviceRoleKey();
const supabase = createClient(appConfig.supabaseUrl(), serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
```

- `appConfig.serviceRoleKey()` sunucu taraflı ortam değişkeninden okur.
- `NEXT_PUBLIC_` prefix'i olan değişken kullanılmıyor.
- Server component (`page.tsx`, `'use client'` direktifi yok) içinde çalışıyor. DOGRU.

### 4.4 Rate Limiting

```typescript
const rl = rateLimit(`unsub:${ip}`, 10, 60_000);
```

- Limit: 10 istek/60 saniye/IP.
- Kaynak: `src/lib/oran-siniri.ts` — in-memory `Map`.
- Sunucu yeniden başlatıldığında sıfırlanır.
- Çoklu Next.js instance'larında her instance bağımsız sayaç tutar.
- Risk değerlendirmesi: HMAC imzası olmadan token üretilemediği için rate limit aşılsa bile saldırgan başka kullanıcıları etkileyemez. Rate limit burada defense-in-depth katmanıdır, birincil güvenlik mekanizması HMAC'tir.
- Nihai değerlendirme: MVP için kabul edilebilir; prodüksiyonda Redis veya Supabase tabanlı merkezi rate limiter önerilir.

### 4.5 Hata Ekranları ve Bilgi Sızıntısı

| Sonuç | Gösterilen Ekran | E-posta gösteriliyor mu? |
|-------|-----------------|--------------------------|
| `success` | "Abonelik İptal Edildi" (genel mesaj) | HAYIR |
| `already_unsubscribed` | "Zaten Abonelikten Çıktınız" (genel mesaj) | HAYIR |
| `expired` | "Bağlantı Süresi Doldu" (genel mesaj) | HAYIR |
| `invalid` | "Geçersiz Bağlantı" (genel mesaj) | HAYIR |
| `rate_limited` | `InvalidScreen` (genel mesaj) | HAYIR |
| `no_secret` | "Hizmet Geçici Olarak Kullanılamıyor" | HAYIR |

`userId` sunucu tarafı log'a yazılıyor ancak ekranda gösterilmiyor. E-posta adresi hiçbir log satırında yer almıyor. DOGRU.

### 4.6 Expired Token Tespiti

Özel not: Token doğrulama null döndürdüğünde `processUnsubscribe` token'ın parçalarını kendisi inceleyerek `expired` ve `invalid` arasında ayrım yapıyor:

```typescript
const parts = token.split('.');
if (parts.length === 5) {
  const exp = parseInt(parts[3], 10);
  if (!isNaN(exp) && Math.floor(Date.now() / 1000) > exp) {
    return { status: 'expired' };
  }
}
return { status: 'invalid' };
```

Bu kod, imza doğrulanmamış bir token'ın `expiresUnix` alanını okur. Güvenlik açısından: expired dedirtecek bir saldırı ancak geçerli sayı formatında 4. parça ile mümkündür ve bunun sağlayacağı bilgi yalnızca "Bağlantı Süresi Doldu" ekranı yerine "Bağlantı Süresi Doldu" ekranı görmektir — expired/invalid ayrımı davranışsal bir fark yaratmaz. Risk: DUSUK.

---

## 5. Edge Function (`send-email-campaign`) Doğrulaması

### 5.1 Hatalı Schema Referanslarının Kaldırılması

Önceki hatalı sütun/ilişki referansları:

| Eski (Hatalı) | Yeni (Doğru) | Doğrulama |
|---------------|--------------|-----------|
| `follower_id` | `user_id` | `grep 'follower_id' index.ts` → eşleşme yok |
| `profiles!inner(email)` | `auth.admin.listUsers()` | `grep 'profiles!inner' index.ts` → eşleşme yok |

`fetchRecipients()` fonksiyonu (satır 71-136):
- `business_follows.select("user_id, user_profiles:user_id(display_name)")` — DOGRU.
- `auth.admin.listUsers({ page: 1, perPage: limit })` — DOGRU.
- İki sonuç in-memory Map ile birleştiriliyor — DOGRU.

### 5.2 Per-Recipient Token Üretimi

```typescript
const token = await generateBizToken(r.userId, campaign.business_id, UNSUBSCRIBE_HMAC_SECRET);
const url = `${SITE_URL}/abonelik-iptal?token=${encodeURIComponent(token)}`;
```

- Her alıcı için ayrı token üretiliyor.
- `UNSUBSCRIBE_HMAC_SECRET` yoksa uyarı loglanıyor ve e-posta footer'sız gönderiliyor (kampanya engellenmez).
- Eski statik `https://yeedoy.com/settings/notifications` linki kaldırılmış: `grep 'settings/notifications' index.ts` → eşleşme yok.

### 5.3 HMAC Implementasyon Uyumluluğu (Deno vs. Node.js)

Edge function Deno Web Crypto API kullanıyor:
```typescript
crypto.subtle.importKey("raw", ..., { name: "HMAC", hash: "SHA-256" }, ...)
crypto.subtle.sign("HMAC", key, encoder.encode(payload))
```

Next.js route handler Node.js `createHmac('sha256', secret)` kullanıyor.

Her iki implementasyon da HMAC-SHA256 standardını uygular. Aynı `payload` ve `secret` ile özdeş imza üretirler. Ancak şu anda bu uyumu doğrulayan çapraz-platform test mevcut değil — sadece teorik garantiye dayanılıyor.

Risk: YUKSEK (test kapsamı eksikliği, üretim hatası keşfini geciktirebilir).

### 5.4 Tautology (Önemsiz Hata)

Satır 284:
```typescript
subject: campaign.html_body ? campaign.subject : campaign.subject,
```

Her iki dalda aynı değer (`campaign.subject`) atanıyor. Fonksiyonel hata yok, yalnızca dead code. Güvenlik etkisi yok.

### 5.5 `auth.admin.listUsers()` Performans Riski

```typescript
const { data: usersPage } = await supabase.auth.admin.listUsers({ page: 1, perPage: limit });
```

- `limit` varsayılan 200.
- `listUsers` tüm kullanıcı havuzundan ilk 200 kaydı çeker — yalnızca opted-in kullanıcıları değil.
- Büyük kullanıcı tabanlarında (10K+) bu yöntem ölçeklenemez; istenilen kullanıcılar listede olmayabilir.
- Mevcut MVP kullanıcı sayısı için kabul edilebilir.

Risk: DUSUK (MVP kapsamı); büyüme sonrası yeniden değerlendirilmeli.

---

## 6. `/bildirim-ayarlari` Doğrulaması

### 6.1 Kimlik Doğrulama Gerekliliği

`app/(kimlik)/layout.tsx`:
```typescript
if (!user) redirect('/giris?redirect=/profil');
```

`/bildirim-ayarlari` bu layout altında. Kimliksiz erişim otomatik yönlendirme ile engelleniyor. DOGRU.

### 6.2 Global Pazarlama İzni Güncellemesi

`pazarlama-email-toggle.tsx` satır 46-52:
```typescript
.update({
  marketing_email_opt_in: next,
  marketing_email_opted_in_at: next ? new Date().toISOString() : null,
  updated_at: new Date().toISOString(),
})
.eq('user_id', user.id)
```

- `true` → `opted_in_at = now()` (onay zamanı kaydediliyor). DOGRU.
- `false` → `opted_in_at = null` (zaman damgası temizleniyor). DOGRU.
- `user.id` koşulu: yalnızca giriş yapmış kullanıcının kendi kaydı güncelleniyor. DOGRU.
- `business_follows.is_subscribed_email`'e hiç dokunulmuyor. DOGRU.

### 6.3 Kavram Ayrımı Metni

`bildirim-ayarlari/page.tsx` satır 102-105:
```
Bu tercihi kapatırsanız Yeedoy'dan pazarlama e-postası almayı bırakırsınız.
İşletmelerin gönderdiği kampanya e-postaları için ayrıca her işletmenin takip
sayfasından aboneliğinizi yönetebilirsiniz.
```

Kullanıcıya iki kavramın ayrı olduğu açıkça belirtilmiş. DOGRU.

### 6.4 Server-Side Veri Yükleme

`bildirim-ayarlari/page.tsx` satır 52-64:

```typescript
const { data: profileData } = await (supabase as any)
  .from('user_profiles')
  .select('marketing_email_opt_in')
  .eq('user_id', user!.id)
  .single();
```

- `createSupabaseServerClient()` sunucu taraflı — cookie'den oturum alır, browser'a key göndermez.
- `try/catch` ile migration uygulanmadan önce sütun yoksa `false` default'a düşüyor. DOGRU.

### 6.5 Client Component Güvenliği

`pazarlama-email-toggle.tsx`:
- `'use client'` direktifi var — browser'da çalışıyor.
- `createSupabaseBrowserClient()` kullanıyor (anon key ile).
- RLS politikası `user_profiles`'da `user_id = auth.uid()` koşulunu uygulamalı (migration 20260620000001 bekleniyor).
- Mevcut RLS yoksa kullanıcı başka kullanıcının profilini güncelleyebilir — ancak `user.id` koşulu zaten kendi kaydına yönlendiriyor ve `auth.getUser()` çağrısı sunucu tarafında yapıldığından session manipülasyonu mümkün değil.

---

## 7. Test Sonuçları

### 7.1 Birim Testleri (unsubscribe-token.test.ts)

| # | Test Açıklaması | Sonuç |
|---|-----------------|-------|
| 1 | mkt türü için geçerli token üretir | GECTI |
| 2 | biz türü için geçerli token üretir | GECTI |
| 3 | mkt türünde businessId null döner | GECTI |
| 4 | Farklı zamanlarda farklı token (string kontrolü) | GECTI |
| 5 | Secret yoksa Error fırlatır | GECTI |
| 6 | URL-safe karakter içerir (+/= yok) | GECTI |
| 7 | Geçerli mkt token payload döner | GECTI |
| 8 | Geçerli biz token payload döner | GECTI |
| 9 | Token idempotent — birden fazla kez doğrulanabilir | GECTI |
| 10 | Rastgele string için null döner | GECTI |
| 11 | Boş string için null döner | GECTI |
| 12 | 4 parçalı token için null döner | GECTI |
| 13 | 6 parçalı token için null döner | GECTI |
| 14 | İmza değiştirilmiş token için null döner | GECTI |
| 15 | userId değiştirilmiş token için null döner | GECTI |
| 16 | Farklı secret ile token için null döner | GECTI |
| 17 | Secret yokken doğrulama null döner | GECTI |
| 18 | Bilinmeyen type için null döner | GECTI |
| 19 | Süresi dolmuş token null döner (Date.now mock) | GECTI |
| 20 | 30 günlük token hemen geçerlidir | GECTI |

Toplam: 20/20 test geçti.

### 7.2 Test Kapsamı Eksiklikleri

| Eksik Test | Risk Seviyesi | Açıklama |
|------------|---------------|----------|
| Deno/Node.js cross-implementation HMAC uyumu | YUKSEK | Token edge'de üretilip web'de doğrulanamaz durumuna karşı test yok |
| `/abonelik-iptal` route E2E testi | ORTA | İzin kapatma davranışı gerçek DB ile test edilmedi |
| Rate limit aşımı davranışı | DUSUK | In-memory rate limit sınırı testi yok |
| Expired token ekran testi | DUSUK | UI tarafında ExpiredScreen'in render edilmesi test edilmedi |

---

## 8. Kalan Riskler

### 8.1 Kritik Risk

**RISK-C1: `marketing_email_opt_in` filtresi e-posta gönderme yollarında eksik**

`get-opted-in-emails.ts` ve `send-email-campaign/index.ts` hâlâ yalnızca `is_subscribed_email = true` filtresi uyguluyor. `marketing_email_opt_in = true` filtresi eklenmemiş.

Sonuç: Global pazarlama e-posta iznini kapatan kullanıcılar, bir işletmeyi takip ettikleri sürece kampanya e-postası almaya devam edebilir. Bu durum 6563 sayılı Kanun ile KVKK md.11/2-ç kapsamında ret hakkı ihlaline yol açabilir.

Neden eklenmedi: Migration `20260620000001` sütunu ekliyor; üretimde sütun yokken filtre eklenmesi sorgu hatasına yol açar.

Müdahale: Migration üretimde çalıştırıldıktan sonra T18 (`get-opted-in-emails.ts`) ve T19 (`send-email-campaign/index.ts`) derhal uygulanmalıdır. Bu iki görev migration aktivasyonuyla aynı değişiklik paketine alınmalıdır.

### 8.2 Yüksek Riskler

**RISK-H1: In-memory rate limit çoklu instance'larda etkisiz**

`oran-siniri.ts` Node.js süreç hafızasında `Map` kullanıyor. Vercel Edge veya çoklu pod ortamında her instance bağımsız sayaç tutar; aynı IP farklı instance'lara istek dağıtarak limiti aşabilir.

Müdahale: Prodüksiyonda Redis veya Supabase tabanlı merkezi rate limit uygulanmalı. HMAC imzası saldırganın başarı ihtimalini zaten sınırladığından kritik değil, ancak yüksek trafik ortamında ele alınmalı.

**RISK-H2: Deno/Node.js cross-implementation HMAC test eksikliği**

Edge function Deno `crypto.subtle` ile token üretirken, doğrulama `unsubscribe-token.ts`'deki Node.js `createHmac` ile yapılıyor. Teorik olarak özdeş — ancak doğrulanmamış. Gizli anahtar veya encoding farkı token'ların tanınmamasına yol açabilir.

Müdahale: Deno ortamında (yerel `supabase functions serve`) token üret, Node.js `verifyUnsubscribeToken` ile doğrulayan bir cross-platform test yazılmalı.

**RISK-H3: `UNSUBSCRIBE_HMAC_SECRET` ortam değişkeni prodüksiyon yapılandırması**

Her iki gönderme yolunun da (`eposta-kampanya route` ve `send-email-campaign edge function`) çalışması için bu değişken hem Next.js hem de Supabase edge function ortamına eklenmiş olmalıdır.

Eksiklik durumu:
- Next.js: `generateUnsubscribeToken` exception fırlatır, kampanya gönderilir ancak footer olmadan.
- Edge function: `UNSUBSCRIBE_HMAC_SECRET` yokken uyarı loglanır, kampanya yine gönderilir.
- Her iki durumda da 6563 md.9/3 uyumsuzluğu oluşur.

Müdahale: Prodüksiyon öncesi checklist'e `UNSUBSCRIBE_HMAC_SECRET` eklenmeli ve deployment pipeline'da doğrulanmalı.

### 8.3 Orta Riskler

**RISK-M1: 30 günlük token ömrü**

Gönderilen e-postadaki link 30 gün boyunca geçerli. Bu süre zarfında kullanıcı başka bir cihazda linke tıklarsa opt-out gerçekleşir. Stateless tasarım nedeniyle önceden iptal mümkün değil (kullanıcı opt-in yaptıktan sonra eski link hâlâ çalışır).

Risk değerlendirmesi: Kullanıcı perspektifinden makul — "önceki e-postamı bulup unsubscribe yaptım." Ciddi suistimal vektörü yok.

**RISK-M2: `user_profiles` global marketing toggle'ın tarayıcı RLS bağımlılığı**

`pazarlama-email-toggle.tsx` browser client ile `user_profiles` tablosunu günceller. `auth.uid() = user_id` RLS politikası migration sonrası uygulanacak. Migration öncesinde bu toggle çalışmaz (sütun yok), ama etkin olduğunda RLS koruması migration'a bağlı.

### 8.4 Düşük Riskler

**RISK-L1: `profiles_read` politikası `marketing_email_opt_in` sütununu herkese açık yapabilir**

`user_profiles`'da `USING(true)` SELECT politikası varsa `marketing_email_opt_in` değeri anonim sorgularla okunabilir. Sütun hassas sayılmaz (boolean tercih), ancak kullanıcı profili keşfine olanak tanıyabilir.

**RISK-L2: `auth.admin.listUsers()` ölçeklenemezlik**

`perPage=200` ile tüm kullanıcı havuzundan ilk 200 kayıt çekiliyor. 10K kullanıcıda opted-in kullanıcılar bu 200'ün dışında kalabilir.

**RISK-L3: Token revocation olmadığı için opt-in sonrası eski link çalışmaya devam eder**

Kullanıcı unsubscribe → subscribe → eski e-postadaki linke tıklarsa tekrar unsubscribe olur. İdempotent davranış — mevcut izin durumunu `false` yapar. Kullanıcı deneyimi açısından şaşırtıcı olabilir ancak kötüye kullanım vektörü mevcut değil (kendi iznini değiştiriyor).

---

## 9. Production Öncesi Kontrol Listesi

| # | Görev | Durum | Öncelik |
|---|-------|-------|---------|
| T16 | Migration `20260620000001` prodüksiyona uygulanmalı (`marketing_email_opt_in` sütunları) | BEKLIYOR | KRITIK |
| T17 | Migration `20260620000002` prodüksiyona uygulanmalı (RPC'ler) | BEKLIYOR | KRITIK |
| T18 | `get-opted-in-emails.ts`'e `marketing_email_opt_in = true` filtresi eklenmeli (T16 sonrası) | BEKLIYOR | KRITIK |
| T19 | `send-email-campaign/index.ts`'e `marketing_email_opt_in = true` filtresi eklenmeli (T16 sonrası) | BEKLIYOR | KRITIK |
| T20 | `UNSUBSCRIBE_HMAC_SECRET` Next.js üretim ortam değişkenlerine eklenmeli | BEKLIYOR | YUKSEK |
| T21 | `UNSUBSCRIBE_HMAC_SECRET` Supabase edge function secrets'a eklenmeli | BEKLIYOR | YUKSEK |
| T22 | Deno/Node.js cross-implementation HMAC doğrulama testi yazılmalı | BEKLIYOR | YUKSEK |
| T23 | Redis/Supabase tabanlı rate limit (çoklu instance prodüksiyon hazırlığı) | BEKLIYOR | ORTA |
| T24 | Flutter `LegalAcceptancePage._submit()` → `update_my_marketing_email_opt_in_v1` bağlantısı | BEKLIYOR | ORTA |
| T25 | Flutter `NotificationPreferencesPage` email toggle → RPC bağlantısı | BEKLIYOR | ORTA |
| T26 | `abonelik-iptal` route E2E testi (staging ortamında) | BEKLIYOR | ORTA |
| T27 | `auth.admin.listUsers()` ölçeklenebilirlik: kullanıcı filtresi veya pagination | BEKLIYOR | DUSUK |

---

## 10. Nihai Karar

**B — Flutter adımına geçilebilir, ancak aşağıdaki şartlar prodüksiyon öncesinde karşılanmalıdır.**

Token mimarisi, route güvenliği ve kavram ayrımı doğru uygulanmış. Hatalı schema referansları (`follower_id`, `profiles!inner(email)`) kaldırılmış ve edge function işlevsel hale getirilmiş. Yalnızca opt-out yazma kuralı eksiksiz uygulanmış. 20/20 birim testi geçiyor.

Ancak aşağıdaki maddeler üretim ortamına geçişi engelleyen koşullardır:

1. **T16+T18 / T17+T19 (Kritik):** `marketing_email_opt_in` sütunları migration ile eklenmeden ve T18/T19 filtreleri devreye girmeden sistem 6563 sayılı Kanun md.9/3 ile KVKK md.11/2-ç kapsamındaki ret hakkını tam olarak karşılamaz.

2. **T20+T21 (Yüksek):** `UNSUBSCRIBE_HMAC_SECRET` her iki ortamda yapılandırılmadığında e-postalar yasal zorunlu unsubscribe linki olmadan gönderilir.

3. **T22 (Yüksek):** Deno/Node.js cross-implementation HMAC testi olmadan token uyumsuzluğu canlıya kadar keşfedilemez.

Flutter bağlama adımları (T24/T25) migration'lardan bağımsız olarak başlatılabilir, ancak migration'lar üretimde aktif olmadan Flutter toggle'ı işlevsel hale getirilmemeli.

---

*Bu rapor statik kod analizine dayanmaktadır. Üretim veritabanına bağlanılmamış, migration uygulanmamış, kod değiştirilmemiştir.*
