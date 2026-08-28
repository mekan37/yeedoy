# R-5 Unsubscribe / Ret Hakkı — Web Route ve Edge Function Karar Planı

**Hazırlanma tarihi:** 2026-06-18  
**Hazırlayan:** postgres-pro  
**Bağlı raporlar:**  
- `docs/arsiv/r5-marketing-optin-data-model-decision.md`  
- `docs/hukuki/r5-marketing-optin-db-implementation-report.md`  
- `docs/hukuki/r5-marketing-optin-db-verification-report.md`  
**Durum:** Karar ve uygulama planı — kod değişikliği yapılmadı, route oluşturulmadı, migration oluşturulmadı.

---

## 1. Mevcut E-posta Kampanyası Akışı

### 1.1 İki Paralel E-posta Gönderim Yolu

Sistemde aynı amaca hizmet eden ama birbirinden bağımsız iki e-posta gönderim yolu bulunmaktadır:

**Yol A — Supabase Edge Function (`supabase/functions/send-email-campaign/index.ts`)**

- POST `/functions/v1/send-email-campaign` endpoint'ini açık bırakır
- JWT token ile authenticated kontrolü yapar
- `email_campaigns` tablosundan kampanya bilgisini çeker
- `business_claims` kontrolüyle owner yetkisini doğrular
- Günde 1 kampanya rate limit uygular
- `business_follows` tablosuna `follower_id` + `profiles!inner(email)` ile sorgu atar — **ikisi de schema ile uyumsuz** (aşağıda açıklanıyor)
- Resend batch API ile 50'lik gruplar halinde gönderir
- Gönderilen her e-postaya statik bir unsubscribe footer ekler

**Yol B — Next.js Route Handler (`uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`)**

- POST `/sunucu/sahip/eposta-kampanya` endpoint'i
- Next.js Auth + Zod safeParse + rate limit (3/saat) içerir
- `getOptedInEmails()` helper'ını kullanır (`src/lib/email/get-opted-in-emails.ts`)
- `get-opted-in-emails.ts` doğru schema kullanır: `user_id` + `user_profiles:user_id(display_name)` + `auth.admin.listUsers()` ile e-posta adresi alır
- `sendEmailCampaign()` (Resend client wrapper) ile gönderim yapar
- Campaign kaydını `email_campaigns` tablosuna yazar

**Önemli:** Yol A (edge function) buggy — muhtemelen aktif kullanımda değil. Yol B (Next.js route) doğru schema kullanıyor ve aktif görünüyor. Ancak her ikisi de unsubscribe mekanizması içermiyor.

### 1.2 `get-opted-in-emails.ts` — Doğru Schema (Yol B)

```
business_follows → user_id, user_profiles:user_id(display_name)
                → is_subscribed_email = true filtresi
                → auth.admin.listUsers() ile e-posta adresi eşleştirme
```

Bu dosya doğru çalışmaktadır. `is_subscribed_email = true` filtresini uygulamaktadır. Ancak `marketing_email_opt_in` global izin kontrolü yoktur.

### 1.3 Global Opt-In Kontrol Eksikliği

Her iki gönderim yolunda da `user_profiles.marketing_email_opt_in` kontrolü yapılmamaktadır. Kullanıcı global pazarlama iznini geri çekse bile — R-5 DB katmanı devreye alındıktan sonra — e-posta gönderilmeye devam edebilir.

Bu bir katman eksikliği olup hem Yol A hem Yol B'de giderilmesi gerekir.

### 1.4 Unsubscribe Footer Durumu

Edge function (`index.ts` satır 119-125) sabit bir HTML footer ekler:

```html
<a href="https://yeedoy.com/settings/notifications">
  aboneliğinizi iptal edebilirsiniz
</a>
```

Next.js Yol B'de (`eposta-kampanya/route.ts`) `sendEmailCampaign()` çağrısına unsubscribe footer bilgisi iletilmemektedir. `resend-client.ts` bu dosyayı okumadan değerlendirilemez ancak footer'ın Yol B'de de eksik olduğu varsayılmalıdır.

---

## 2. Mevcut Unsubscribe / Ret Hakkı Durumu

### 2.1 Nereye Yönlendiriyor?

`send-email-campaign/index.ts` satır 122:
```
https://yeedoy.com/settings/notifications
```

### 2.2 Bu Route Var mı?

`uygulamalar/web/app/` dizininin tamamı incelendi. Eşleşen route bulunmadı:

| Arama | Sonuç |
|---|---|
| `settings/` klasörü altında herhangi bir route | YOK |
| `notifications/` adlı route | YOK |
| `notification-preferences/` adlı route | YOK |

Web uygulamasında bildirim tercihleri sayfası **farklı bir URL'de** var: `/bildirim-ayarlari` (`uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx`). Bu sayfa:
- Push notification türlerini yönetir (yorum yanıtları, fiyat alarmları, yeni işletmeler)
- `notification_preferences` tablosuna yazar
- **`marketing_email_opt_in` veya `is_subscribed_email` alanlarını yönetmez**
- Kimlik doğrulama gerektirir (auth group içinde)

### 2.3 Mobil Uygulama Yeterli mi?

Flutter mobil uygulamada `/notification-preferences` rotası var (`router.dart` satır 323). Bu rota:
- Uygulama içi bildirim tercihlerini yönetir
- Web'deki `send-email-campaign` e-postalarından erişilemez (mobil link, web e-postasında açılmaz)
- `marketing_email_opt_in` toggle'ı `LegalAcceptancePage`'de var ama henüz Supabase'e bağlı değil

Mobil uygulama, web e-posta kampanyaları için unsubscribe mekanizması olarak yetersizdir.

### 2.4 Hukuki Durum

**6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun md. 9/3:** Her ticari elektronik iletide alıcının ret hakkını kullanabileceği geçerli ve işlevsel bir mekanizma bulunması zorunludur.

Mevcut durum bu zorunluluğu karşılamamaktadır:
- Gönderilen linklerin hedef URL'si mevcut değildir
- Alternatif erişim yolu (mobil uygulama) e-posta bağlamında ulaşılamaz durumdadır
- `marketing_email_opt_in` false olsa bile e-posta gönderimi durdurulamaz

**Sonuç:** E-posta kampanyaları DB katmanı hazır olsa bile bu sorun çözülmeden canlıya alınamaz.

---

## 3. Mimari Seçenekler

### Seçenek A — Login Gerektiren Ayarlar Sayfası

**Tanım:** `/bildirim-ayarlari` sayfasına `marketing_email_opt_in` ve `is_subscribed_email` toggle'ları eklenir. E-postalardaki link bu sayfaya yönlendirir. Kullanıcının giriş yapması gerekir.

**Artıları:**
- Kimlik doğrulanmış işlem — güvenli
- Mevcut sayfa yapısına entegrasyon (az yeni kod)
- Token yönetimi gerekmez
- Kullanıcı tüm bildirim tercihlerini tek yerden yönetir

**Eksileri:**
- E-posta gönderim zamanında kullanıcı oturumu olmayabilir
- Kullanıcı oturumunu unutmuş, şifresini değiştirmiş olabilir
- Login sayfasına yönlendirme ve geri dönüş akışı UX karmaşıklığı
- 6563 md. 9/3 "tek tıkla ret" beklentisini karşılamaz — çok adımlı
- Pasif kullanıcılar (uygulamayı kullanmayan) unsubscribe yapamayabilir

**Güvenlik:** Yüksek — authenticated işlem.

**Hukuki:** Kısmi uyum — ret mekanizması teknik olarak var ama "tek tıkla" pratiği karşılanmıyor. BTIK denetimleri tek adım bekler.

**UX:** Kötü — e-posta alıcısının ne yaptığını anlayabilmesi için ek adım gerekir.

**Teknik maliyet:** Düşük-orta — mevcut sayfa değiştirilir, yeni migration gerekmez (RPC mevcut).

**Tavsiye:** Tek başına yetersiz. Seçenek B ile kombinlenmeli.

---

### Seçenek B — Token Tabanlı Public Unsubscribe Route

**Tanım:** E-postalara imzalı, tek kullanımlık veya süreli token içeren bir link eklenir. Kullanıcı bu linki tıklayınca login gerekmeden `is_subscribed_email` veya `marketing_email_opt_in` false'a çevrilir. Token geçerlilik süresi dolunca işlevsiz olur.

**Artıları:**
- "Tek tıkla" ret hakkı — 6563 md. 9/3 uyumu
- Login gerektirmez — pasif kullanıcılar da kullanabilir
- E-posta istemcilerinden direkt çalışır
- List-Unsubscribe header ile e-posta provider'ları (Gmail, Outlook) unsubscribe düğmesi gösterebilir
- Modern e-posta pazarlama standardı

**Eksileri:**
- Token üretimi, saklama ve doğrulama altyapısı gerektirir
- Token yeniden kullanımı / replay saldırısı önlemi gerektirir
- Token süresi dolmuşsa kullanıcı yeniden login yapmalı
- E-posta forward edilirse başka biri unsubscribe yapabilir (düşük risk — kasıtlı istenirse logout mantığına benzer)

**Güvenlik:** Orta — token'ın HMAC-SHA256 ile imzalanması ve süreli olması saldırı yüzeyini minimize eder.

**Hukuki:** Tam uyum — 6563 md. 9/3 ve GDPR Art. 21 (AB/KVKK benchmark) gereksinimlerini karşılar.

**UX:** İyi — tek tıkla çalışır, kullanıcı onay sayfası görür.

**Teknik maliyet:** Orta — token üretimi, new API route veya edge function, yeni migration veya token sütunu.

**Tavsiye:** Temel çözüm. Seçenek A ile kombinlenmeli.

---

### Seçenek C — Her İkisi Birden (A + B)

**Tanım:** E-postalarda token tabanlı tek tıkla unsubscribe linki bulunur (Seçenek B). `/bildirim-ayarlari` sayfasına marketing_email_opt_in ve is_subscribed_email toggle'ları da eklenir (Seçenek A). İki yol birbirini tamamlar.

**Artıları:**
- En kapsamlı çözüm
- E-postadan direkt unsubscribe + uygulama içi tercih yönetimi
- Kullanıcı her iki kanaldan da opt-out yapabilir
- Projenin genel kalitesini yükseltir

**Eksileri:**
- En yüksek geliştirme maliyeti
- Tutarlılık gerektir: token route ve settings sayfası aynı RPC'yi kullanmalı

**Güvenlik:** Yüksek — iki katmanlı.

**Hukuki:** Tam uyum ve iyi uygulama örneği.

**UX:** Mükemmel.

**Teknik maliyet:** Orta-yüksek — iki bileşen geliştirme gerektirir.

**Tavsiye:** Önerilen karar. Sprint zamanı kısıtlıysa Seçenek B önce yapılır, Seçenek A ikinci iterasyonda.

---

### Seçenek D — Mobil Uygulama Tek Kanal

**Tanım:** Unsubscribe yalnızca Flutter mobil uygulaması üzerinden sağlanır. E-postalardaki link App Store/Play Store'a yönlendirir veya uygulamanın deep link'ini açar.

**Artıları:**
- Ek web altyapısı gerekmez
- Mevcut mobil notification preferences sayfası kullanılır

**Eksileri:**
- E-posta alıcısı uygulamayı yüklü olmayabilir
- Web e-postasından uygulama açılması kötü UX
- 6563 md. 9/3 uyumunu sağlamaz — pratik erişilebilirlik koşulu
- Pasif kullanıcılar (kampanyalar nedeniyle uygulama silmiş) unsubscribe yapamaz
- Hukuki açıdan savunulamaz

**Tavsiye:** Kabul edilemez. Bu seçenek uygulanamaz.

---

## 4. Önerilen Karar

**Seçenek C: Token tabanlı public unsubscribe route (Seçenek B) + bildirim ayarları sayfası güncellemesi (Seçenek A)**

Sprint kısıtı varsa **önce Seçenek B** (hukuki zorunluluk), ardından **Seçenek A** (UX tamamlama).

### 4.1 Token Tasarımı

**Token türü:** HMAC-SHA256 imzalı, URL-safe Base64 encoded, süreli yapılandırılmış string.

**Yapı:**
```
{type}.{user_id_base64url}.{business_id_base64url}.{expires_unix}.{hmac_signature}
```

- `type`: `mkt` (marketing global opt-out) veya `biz` (business-specific unsubscribe)
- `user_id_base64url`: kullanıcı UUID'si base64url encode edilmiş
- `business_id_base64url`: işletme UUID'si base64url encode edilmiş (`mkt` türü için sabit `00000000-0000-0000-0000-000000000000`)
- `expires_unix`: Unix timestamp (saniye), 30 gün geçerlilik (2592000 saniye)
- `hmac_signature`: HMAC-SHA256(payload, `UNSUBSCRIBE_SECRET`), hex veya base64url

**Ayrı sütun yerine stateless tasarım:** Token veritabanında saklanmaz. HMAC doğrulaması ile her istek için geçerliliği kontrol edilir. Süresi dolmuş tokenlar reddedilir. Bu yaklaşım veri minimizasyonunu sağlar (KVKK md. 4/2-ç) ve ayrı migration gerektirmez.

**UNSUBSCRIBE_SECRET:** Supabase ortam değişkenlerinde `UNSUBSCRIBE_HMAC_SECRET` olarak tutulur. Edge function veya Next.js `process.env.UNSUBSCRIBE_HMAC_SECRET` ile okur. Sızdırılırsa tüm tokenlar geçersizleşir — secret rotation planı gerektirir.

**Token süresi:** 30 gün. Süresi dolan tokeni tıklayan kullanıcıya açıklayıcı hata mesajı gösterilir ve `/bildirim-ayarlari` sayfasına yönlendirme yapılır.

**Tek kullanımlık mı?** Stateless imzalı token yaklaşımında teknik olarak `mkt` token'ı birden fazla kez kullanılabilir ancak sonuç değişmez (marketing_email_opt_in zaten false olur). Bu idempotent davranış kabul edilebilir. Gerekirse `used_tokens` tablosu eklenerek single-use zorlanabilir ama bu sprint kapsamı dışındadır.

### 4.2 İki Kavram İçin İki Token Türü

**Global pazarlama opt-out (`mkt` token):**
- `update_my_marketing_email_opt_in_v1(false)` RPC'yi çağırır
- `user_profiles.marketing_email_opt_in` = false yapar
- Tüm Yeedoy e-postalarını durdurur
- Bu token edge function e-postalarında kullanılmalı (Yol A veya platform genel kampanyaları)

**İşletme bazlı unsubscribe (`biz` token):**
- `update_business_follow_email_subscription_v1(business_id, false)` RPC'yi çağırır
- `business_follows.is_subscribed_email` = false yapar
- Yalnızca o işletmenin kampanyalarını durdurur
- Bu token owner e-posta kampanyalarında kullanılmalı (Yol B)

Her e-posta türünde hangi token kullanılacağı net olmalı. Karıştırılmamalı.

### 4.3 Public Unsubscribe Route URL Tasarımı

**Önerilen URL:** `/abonelik-iptal?token={token}`  

(Türkçe URL kalıbına uyan ve mevcut route adlandırma standardıyla uyumlu)

Bu route:
- Kimlik doğrulaması gerektirmez (public group altında)
- GET isteğinde token doğrular ve onay sayfası gösterir
- POST isteğinde (veya GET ile onay parametresiyle) RPC'yi çağırır ve sonuç sayfası gösterir
- Token geçersizse/süresi dolmuşsa açıklayıcı mesaj gösterir

Alternatif URL seçenekleri: `/vazgec?token=`, `/bildirim-iptal?token=`, `/unsubscribe?token=` (global en anlaşılır).

### 4.4 Hangi RPC Hangi Amaç İçin

| Token türü | RPC | Tablo | Etki |
|---|---|---|---|
| `mkt` | `update_my_marketing_email_opt_in_v1(false)` | `user_profiles` | Tüm platform pazarlama e-postaları durur |
| `biz` | `update_business_follow_email_subscription_v1(business_id, false)` | `business_follows` | Yalnızca bu işletmenin e-postaları durur |

Her iki RPC de `SECURITY DEFINER` ve `WHERE user_id = v_uid` korumalı — token'dan çıkarılan `user_id` ile doğrudan çağrılabilir.

**Not:** Public route SECURITY DEFINER RPC'yi service role ile çağırır — kullanıcı oturumu yoktur. Bu yüzden token içindeki `user_id` parametresi RPC içinde `v_uid` yerine kullanılmalıdır. Bu durumda RPC'nin token doğrulamalı bir wrapper versiyonu veya Next.js route handler'ında doğrudan `supabase_admin.rpc()` çağrısı tercih edilebilir. Mimari karar: **Next.js route handler + service role client + doğrudan UPDATE** en temiz yaklaşımdır (ayrı "unsubscribe_by_token_v1" RPC gereksizdir).

---

## 5. Edge Function Şema Düzeltme Planı

`supabase/functions/send-email-campaign/index.ts` dosyasında iki kritik hata tespit edilmiştir. Bu hatalar fonksiyonun mevcut haliyle hiç e-posta gönderememesine neden olmaktadır.

### 5.1 Mevcut Hatalı Sorgu (Satır 87-91)

```typescript
let followersQuery = supabase
  .from("business_follows")
  .select("follower_id, profiles!inner(email)")
  .eq("business_id", campaign.business_id)
  .eq("is_subscribed_email", true);
```

### 5.2 İki Hata

**Hata 1 — `follower_id` kolonu yok:**  
`business_follows` tablosu `user_id` ve `business_id` içerir. `follower_id` adında bir kolon base_schema'da veya hiçbir migration'da tanımlanmamıştır. Aynı hata `estimate_email_segment_v1` RPC'sinde de vardı ve `20260603000010_fix_estimate_email_segment_v1.sql` migration'ıyla düzeltildi — ancak edge function güncellenmedi.

**Hata 2 — `profiles` tablosu yok:**  
`public` schema'da `profiles` adında tablo yoktur. Doğru tablo adı `user_profiles`'dır. Ancak `user_profiles` tablosu auth `email` alanını içermez. E-posta adresleri `auth.users` tablosundadır ve `auth.admin.listUsers()` ile alınır.

### 5.3 Düzeltme Yaklaşımı

`get-opted-in-emails.ts` (Next.js Yol B) doğru yaklaşımı göstermektedir:

1. `business_follows` → `user_id` sütunu, `user_profiles:user_id(display_name)` join, `is_subscribed_email = true` filtresi
2. `auth.admin.listUsers()` ile tüm kullanıcıların e-posta adresleri alınır
3. `user_id` üzerinden eşleştirme yapılır

Edge function'da düzeltme planı:
- `select("follower_id, profiles!inner(email)")` → `select("user_id, user_profiles:user_id(display_name)")` olarak değiştirilecek
- `emails` array'i artık sorgudan değil `auth.admin.listUsers()` çağrısından üretilecek
- `f["profiles"]["email"]` referansı kaldırılacak, email map Deno'nun Supabase admin client'ı ile oluşturulacak
- Deno'da `supabase.auth.admin.listUsers()` service role client ile çalışır — mevcut `supabase` değişkeni zaten service role kullanıyor

### 5.4 Unsubscribe Link Değişikliği

Edge function satır 122'deki statik URL:
```
https://yeedoy.com/settings/notifications
```

Bu değiştirilecek ve dinamik token içerecek:
```
https://yeedoy.com/abonelik-iptal?token={generated_token}
```

Token, `user_id` ve `business_id` içerecek ve her alıcı için ayrı üretilecektir. Batch gönderimde her mesaj kendi token'ını alır.

### 5.5 marketing_email_opt_in Kontrolü Eklenmesi

Edge function ve `get-opted-in-emails.ts` her ikisi de şu anda yalnızca `is_subscribed_email = true` filtresi uygulamaktadır. `marketing_email_opt_in` global izin kontrolü eklenmesi gerekmektedir. Ancak `user_profiles.marketing_email_opt_in` sütunu henüz production'da yoktur (`20260620000001` migration'ı uygulanmamış). Bu sütun migration uygulandıktan sonra filtreye eklenmelidir.

Planlanan filtre (migration sonrası):
```
business_follows.is_subscribed_email = true
AND user_profiles.marketing_email_opt_in = true
```

Bu iki katmanlı filtre global ret hakkının teknik olarak uygulanmasını sağlar.

---

## 6. Gerekli Teknik İşler Listesi

### Öncelik 1 — Hukuki Zorunluluk (E-posta Canlıya Alma Bloker)

| # | İş | Dosya / Konum | Sorumlu Agent |
|---|---|---|---|
| T1 | `UNSUBSCRIBE_HMAC_SECRET` ortam değişkeni Supabase Dashboard'a ve `.env.local`'e eklenmesi | Supabase Dashboard → Edge Functions → Secrets | DevOps |
| T2 | Token üretim yardımcısı yazılması (`generateUnsubscribeToken(userId, businessId, type)`) | `uygulamalar/web/src/lib/email/unsubscribe-token.ts` (yeni) | nextjs-developer |
| T3 | Token doğrulama yardımcısı yazılması (`verifyUnsubscribeToken(token)`) | Aynı dosya veya ayrı `verify-unsubscribe-token.ts` | nextjs-developer |
| T4 | Public unsubscribe route oluşturulması | `uygulamalar/web/app/(genel)/abonelik-iptal/page.tsx` ve `route.ts` (yeni) | nextjs-developer |
| T5 | Unsubscribe route — token doğrulama + onay sayfası UI | Aynı dosya | nextjs-developer |
| T6 | Unsubscribe route — RPC çağrısı (service role ile `update_my_marketing_email_opt_in_v1` veya `update_business_follow_email_subscription_v1`) | Route handler POST action | nextjs-developer |
| T7 | `eposta-kampanya/route.ts` — `sendEmailCampaign()` çağrısına unsubscribe token eklenmesi | `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | nextjs-developer |
| T8 | `resend-client.ts` veya email template — her alıcı için benzersiz token içeren footer oluşturulması | `uygulamalar/web/src/lib/email/resend-client.ts` | nextjs-developer |
| T9 | `send-email-campaign/index.ts` — `follower_id` → `user_id` düzeltmesi | `supabase/functions/send-email-campaign/index.ts` satır 89 | nextjs-developer veya backend-developer |
| T10 | `send-email-campaign/index.ts` — `profiles!inner(email)` → `auth.admin.listUsers()` pattern'ına geçiş | Aynı satır ve sonraki email map kodu | nextjs-developer veya backend-developer |
| T11 | `send-email-campaign/index.ts` — statik unsubscribe URL → dinamik token URL değişimi | Satır 122 | nextjs-developer |

### Öncelik 2 — Kullanıcı Deneyimi Tamamlama

| # | İş | Dosya / Konum | Sorumlu Agent |
|---|---|---|---|
| T12 | `/bildirim-ayarlari` sayfasına `marketing_email_opt_in` toggle'ı eklenmesi | `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx` ve `bildirim-tercihleri.tsx` | nextjs-developer |
| T13 | `/bildirim-ayarlari` sayfasına işletme bazlı e-posta abonelik yönetimi eklenmesi (takip edilen işletmeler listesi + is_subscribed_email toggle'ları) | Yeni bileşen `eposta-abonelikleri.tsx` | nextjs-developer |
| T14 | `/bildirim-ayarlari` sayfası — `get_my_notification_preferences_v1()` RPC çağrısı ile marketing_email_opt_in değerinin server-side yüklenmesi | `page.tsx` server component | nextjs-developer |
| T15 | `/bildirim-ayarlari` sayfası — `update_my_marketing_email_opt_in_v1()` RPC çağrısı client-side bağlanması | `bildirim-tercihleri.tsx` veya yeni action | nextjs-developer |

### Öncelik 3 — DB Katmanı Aktivasyonu

| # | İş | Koşul |
|---|---|---|
| T16 | `20260620000001` migration production'a uygulanması | Legal onayı bekliyor |
| T17 | `20260620000002` migration production'a uygulanması | T16 sonrası |
| T18 | `get-opted-in-emails.ts` — `marketing_email_opt_in = true` filtresi eklenmesi | T16/T17 sonrası |
| T19 | `send-email-campaign/index.ts` — `marketing_email_opt_in = true` filtresi eklenmesi | T16/T17 sonrası |

### Öncelik 4 — Flutter Mobil Bağlantısı

| # | İş | Koşul |
|---|---|---|
| T20 | `LegalAcceptancePage._submit()` içinde `_marketingOptIn` değerinin `update_my_marketing_email_opt_in_v1()` RPC'sine bağlanması | T16/T17 + Flutter agent |
| T21 | `NotificationPreferencesPage` — e-posta toggle'ının `marketing_email_opt_in` ile bağlanması | T20 sonrası |

---

## 7. Güvenlik ve Kötüye Kullanım Önlemleri

### 7.1 Token Güvenliği

| Risk | Önlem |
|---|---|
| Token tahmin edilebilir mi? | HMAC-SHA256 + 256-bit secret → tahmini imkansız |
| Token süresi dolmadan kullanılabilir mi? | `expires_unix` kontrolü — 30 günlük pencere |
| Token başkasına forward edilirse? | `user_id` token'a gömülü — başka kullanıcı yararlanamaz (kendi unsubscribe'ı olur) |
| Secret sızdırılırsa? | Rotation ile tüm eski tokenlar geçersiz, yeni secret + yeni gönderim gerekir |
| Brute force? | HMAC-SHA256 256-bit → pratik olarak kırılamaz |

### 7.2 Unsubscribe Endpoint Güvenliği

- Rate limit uygulanmalı (örn. IP başına 10 istek/dakika)
- Token olmadan GET/POST → 400 Bad Request
- Geçersiz token → açıklayıcı hata, kullanıcı login'e yönlendirilir
- Başarılı unsubscribe → idempotent (defalarca çalıştırılabilir, sonuç değişmez)
- Endpoint'in açık (public) olması güvenlik riski değil — token olmadan hiçbir şey yapmaz

### 7.3 Gizlilik

- Unsubscribe sayfası işlem sonrası e-posta adresi göstermemeli (kısmi maskeleme maksimum: `k***@gmail.com`)
- Başarılı işlem logu: yalnızca sayım (`unsubscribed user_id=...`) — e-posta adresi log'a yazılmaz
- Hata logu: aynı şekilde e-posta adresi yazılmaz

### 7.4 İşletme Kampanyaları — Liste Yönetimi

İşletme sahibi, `is_subscribed_email` listesine yönelik kötüye kullanım yapabilir (eski kullanıcıları listeden çıkmış olsa da tekrar dahil etme). RPC `update_business_follow_email_subscription_v1` yalnızca `user_id = auth.uid()` ile çalışır — owner başka kullanıcının aboneliğini geri açamaz. Bu mimari olarak güvenlidir.

---

## 8. Sonraki Uygulama Promptu

Aşağıdaki prompt `nextjs-developer` agent'ına iletilmek üzere hazırlanmıştır:

---

**Prompt — nextjs-developer:**

Yeedoy R-5 pazarlama opt-in çalışmasında unsubscribe mekanizması uygulanacak.

**Karar (postgres-pro tarafından verildi):**  
Seçenek C: Token tabanlı public unsubscribe route + bildirim ayarları sayfası güncellemesi.

**Kısıtlar:**
- Migration oluşturma (DB katmanı hazır: `20260620000001` ve `20260620000002`)
- Flutter dosyası değiştirme
- Final KVKK/Gizlilik metni yazma
- `user_profiles.marketing_email_opt_in` ile `business_follows.is_subscribed_email` kavramlarını karıştırma

**Yapılacak işler (öncelik sırasıyla):**

1. `uygulamalar/web/src/lib/email/unsubscribe-token.ts` dosyası oluştur:
   - `generateUnsubscribeToken(userId: string, businessId: string | null, type: 'mkt' | 'biz', expiresInSec?: number): string`
   - `verifyUnsubscribeToken(token: string): { userId: string; businessId: string | null; type: 'mkt' | 'biz' } | null`
   - HMAC-SHA256 (`crypto.subtle` Node.js Web Crypto API), URL-safe base64
   - Secret: `process.env.UNSUBSCRIBE_HMAC_SECRET`
   - 30 gün varsayılan süre

2. `uygulamalar/web/app/(genel)/abonelik-iptal/` route'u oluştur:
   - `page.tsx` — GET: token doğrula, geçerliyse onay sayfası göster, geçersizse hata + `/bildirim-ayarlari` yönlendirme
   - API handler (server action veya route.ts) — POST: token doğrula, service role ile RPC çağır, başarı sayfası göster
   - `mkt` type → `update_my_marketing_email_opt_in_v1(false)` (user_id parametresi token'dan)
   - `biz` type → `update_business_follow_email_subscription_v1(business_id, false)` (token'dan her ikisi)
   - Rate limit: IP başına 10/dakika

3. `eposta-kampanya/route.ts` — `getOptedInEmails()` sonucunu alırken her alıcı için `biz` token üret, `sendEmailCampaign()` çağrısına unsubscribe footer bilgisi ilet.

4. `resend-client.ts` — `sendEmailCampaign()` fonksiyonu `unsubscribeUrl?: string` parametresi alacak şekilde güncellenir. Bu URL e-posta footer'ına eklenir.

5. `/bildirim-ayarlari` sayfası güncelleme:
   - `page.tsx` — `get_my_notification_preferences_v1()` RPC çağrısı eklenir, `marketing_email_opt_in` değeri yüklenir
   - `bildirim-tercihleri.tsx` — pazarlama e-posta toggle'ı eklenir, `update_my_marketing_email_opt_in_v1()` RPC'sine bağlanır

6. `send-email-campaign/index.ts` (edge function) şema düzeltmesi:
   - Satır 89: `follower_id` → `user_id`, `profiles!inner(email)` kaldırılır
   - `auth.admin.listUsers()` ile email alınması (`get-opted-in-emails.ts` pattern'ını takip et)
   - Satır 122: statik URL → dinamik token URL (`/abonelik-iptal?token={biz_token}`)

**Her fonksiyon için test yaz. `npm run typecheck` ve `npm run lint` geçmeli.**

**Kaynak dosyalar:**
- `docs/hukuki/r5-unsubscribe-web-edge-decision-plan.md` (bu dosya)
- `supabase/functions/send-email-campaign/index.ts`
- `uygulamalar/web/src/lib/email/get-opted-in-emails.ts`
- `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`
- `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx`

---

## 9. Özet Değerlendirme

### Hangi Dosyalarda Sorun Var?

| Dosya | Sorun | Kritiklik |
|---|---|---|
| `supabase/functions/send-email-campaign/index.ts` | `follower_id` kolon yok, `profiles` tablo yok, unsubscribe link 404 | Kritik — fonksiyon çalışmıyor |
| `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | Unsubscribe token gönderilmiyor, footer yok | Kritik — 6563 md.9/3 ihlali |
| `uygulamalar/web/src/lib/email/get-opted-in-emails.ts` | `marketing_email_opt_in` kontrolü yok | Orta — migration sonrası gerekli |
| `/bildirim-ayarlari` sayfası | `marketing_email_opt_in` toggle'ı yok | Orta — UX tamamlama |

### Canlıya Alma Koşulları (Engeller)

E-posta kampanyaları şu koşullar sağlanmadan canlıya alınmamalıdır:

1. `20260620000001` ve `20260620000002` migration'larının production'a uygulanması
2. Çalışan bir unsubscribe endpoint'inin (`/abonelik-iptal?token=`) mevcut olması
3. Her e-postada geçerli ve işlevsel unsubscribe link gönderilmesi
4. `send-email-campaign/index.ts` şema hatalarının düzeltilmesi

### İki Kavramın Net Ayrımı

Bu planda aşağıdaki ayrım korunmuştur:

| Kavram | Tablo | RPC | Token türü |
|---|---|---|---|
| Global platform pazarlama izni | `user_profiles.marketing_email_opt_in` | `update_my_marketing_email_opt_in_v1` | `mkt` |
| İşletme bazlı e-posta aboneliği | `business_follows.is_subscribed_email` | `update_business_follow_email_subscription_v1` | `biz` |

Bu iki kavram birbirinden bağımsızdır. Kullanıcı global izni geri çektiğinde işletme bazlı abonelikler değişmez; kullanıcı global izni verdiğinde işletme aboneliklerinden ayrı olarak değerlendirilir.
