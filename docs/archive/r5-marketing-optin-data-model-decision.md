# R-5 Pazarlama E-posta Opt-In — Veri Modeli Karar Raporu

**Hazırlanma tarihi:** 2026-06-19  
**Hazırlayan:** postgres-pro  
**Kaynak raporlar:** `docs/legal/critical-privacy-gaps-report.md`, `docs/legal/legal-preflight-report.md`  
**Durum:** Analiz tamamlandı. Kod değişikliği yapılmadı, migration oluşturulmadı.

---

## 1. Mevcut Pazarlama / E-posta İzin Akışı

### 1.1 _marketingOptIn nerede gösteriliyor?

`uygulamalar/mobil/lib/features/legal/ui/legal_acceptance_page.dart` içinde, "İsteğe bağlı tercihler" başlıklı bir kartın içinde `SwitchListTile` olarak gösteriliyor. Başlığı "Kampanya ve bildirim izinleri". İkinci bir toggle, "Ürün analitiği iyileştirme izni" olarak `_analyticsOptIn` değişkenine bağlı.

### 1.2 Kullanıcı hangi ekranda bu izni veriyor?

`LegalAcceptancePage` — uygulamaya giriş akışında, zorunlu politika kabul ekranının hemen altında. Bu ekran, politika versiyonları güncellendiğinde yeniden gösteriliyor. Kullanıcı uygulamayı açtığında kabul bekleyen versiyon varsa bu ekrana yönlendiriliyor.

### 1.3 Bu değer şu anda nereye yazılıyor?

Hiçbir yere. `_submit()` metodunun tamamı şu:

```dart
await ref.read(legalRepositoryProvider).acceptPolicyVersions(versions);
ref.invalidate(legalAcceptanceSnapshotProvider);
context.go(widget.fromPath ?? '/discover');
```

`_marketingOptIn` ve `_analyticsOptIn` değerleri `_submit()` içinde kullanılmıyor. Switch görsel olarak çalışıyor, değer widget state'inde tutuluyor, ancak herhangi bir repository çağrısına bağlanmıyor.

### 1.4 notification_preferences_page.dart hangi değerleri gösteriyor?

`NotificationPreferencesPage` üç kanal toggle'ı gösteriyor:
- `_appNotifs` — Uygulama İçi Bildirimler
- `_emailNotifs` — E-posta Bildirimleri
- `_smsNotifs` — SMS Bildirimleri

Ve altı kategori toggle'ı (Duyurular, Kampanyalar, Başarılar, Etkinlikler, Sosyal, Hatırlatmalar).

Tüm bu değerler widget state'inde (`StatefulWidget._State`) tutuluyor. Hiçbir Supabase yazma çağrısı yok, Riverpod provider yok, SharedPreferences kayıt yok. Sayfa Riverpod dışında `StatefulWidget` olarak tanımlanmış — bu, bu sayfanın kasıtlı olarak local state özelinde bırakılmış olduğunu gösteriyor. Oturum sonrasında tüm tercihler sıfırlanıyor.

### 1.5 E-posta bildirimi toggle'ı global mi, işletme bazlı mı?

`_emailNotifs` toggle'ı bu sayfada bir kanal olarak tanımlanmış ve tanımı şu: "E-posta adresinize bildirim gönderilsin". Bu genel bir açıklama; herhangi bir işletmeye bağlı değil. Ancak bu toggle hiçbir yere yazılmıyor. Mevcut kod, bu toggle'ın neyi temsil ettiğini belirleyen bir backing store içermiyor.

### 1.6 business_follows.is_subscribed_email ne amaçla tasarlanmış?

`20260424000009_email_campaigns.sql` migration'ı şu sütunu ekliyor:

```sql
alter table public.business_follows
  add column if not exists is_subscribed_email boolean not null default false;
```

Bu sütun açıkça bir kullanıcının **belirli bir işletmeden** e-posta kampanyası almak isteyip istemediğini temsil ediyor. `send-email-campaign/index.ts` edge function'ı şu sorguyu çalıştırıyor:

```typescript
.from("business_follows")
.eq("business_id", campaign.business_id)
.eq("is_subscribed_email", true)
```

`estimate_email_segment_v1()` RPC'si de aynı şekilde `business_id + is_subscribed_email = true` kombinasyonunu kullanıyor. `get-opted-in-emails.ts` de bu alanı filtreli olarak okuyor.

Tasarım niyeti: **işletme bazlı** e-posta pazarlama aboneliği. `DEFAULT false` — kullanıcı açıkça opt-in etmeden false başlıyor. Bu doğru bir yaklaşım.

### 1.7 profiles veya başka bir tabloda global pazarlama izni alanı var mı?

`user_profiles` tablosu (`00000000000000_base_schema.sql` satır 24161): `user_id`, `display_name`, `avatar_url`, `bio`, `is_gourmet`, `created_at`, `updated_at`, `shadow_banned`, `social_links`. **Global pazarlama izni alanı yok.**

`ConsentState` (`consent_state.dart`) bir `marketing` alanı içeriyor (`ConsentStatus` enum: unknown/granted/denied). Ancak bu yalnızca `SharedPreferences`'e yazılıyor (`kvkk_consent_marketing` anahtarıyla) — Supabase'e yazılmıyor. Sunucu tarafında görünmüyor, email gönderim sistemleri bu değeri okumuyor.

Hiçbir migration'da `marketing_email_opt_in`, `global_marketing_consent`, `email_consent` veya benzeri global bir sütun bulunmuyor.

---

## 2. Global İzin ile İşletme Bazlı İzin Ayrımı

Bu iki kavram birbirinden köklü biçimde farklı ve karıştırılmaması gerekiyor.

### Kavram A: Global Pazarlama / E-posta İzni

**Tanım:** Kullanıcının Yeedoy platformundan gelen her türlü ticari elektronik iletiyi almayı kabul etmesi. Hangi işletmeden olduğundan bağımsız, platform düzeyinde bir izin.

**Mevcut durum:** Yalnızca `SharedPreferences`'te (device-local) tutuluyor. Supabase'de bu kavramı karşılayan tablo veya sütun yok.

**Hangi tabloda tutulmalı:** `user_profiles` tablosuna `marketing_email_opt_in boolean not null default false` sütunu (ya da ayrı bir tablo — bkz. Bölüm 4). Sunucu taraflı olmalı; çünkü ispat yükümlülüğü var.

**Hangi UI ekranında yönetilmeli:** İki nokta:
- `LegalAcceptancePage` içindeki "Kampanya ve bildirim izinleri" toggle'ı — ilk kez izin alınacak yer
- `NotificationPreferencesPage` içindeki "E-posta Bildirimleri" toggle'ı — daha sonra değiştirebilecek yer

**Kullanıcı izni nasıl geri çekmeli:** Bildirim tercihleri sayfasından toggle'ı kapatarak. Ayrıca e-posta footer'ındaki unsubscribe linkiyle (bu yalnızca `business_follows.is_subscribed_email` için çalışıyor — global opt-in için ayrı bir endpoint gerekiyor).

**KVKK/açık rıza açısından ayrı metin gerekir mi:** Evet. Zorunlu sözleşme kabul metni ile pazarlama e-postası rızası aynı metinde olamaz (KVKK Rehberi). Toggle ayrı ve opt-in mantığında olmalı, zorunlu checkbox ile aynı onay hareketinde birleştirilmemeli.

### Kavram B: İşletme Bazlı Takip E-posta Aboneliği

**Tanım:** Kullanıcının takip ettiği belirli bir işletmeden kampanya / özel teklif e-postası almayı kabul etmesi.

**Mevcut durum:** `business_follows.is_subscribed_email` alanı olarak doğru modellenmiş. `DEFAULT false`. Ancak mobil uygulamada bu alanı `true` yapan bir kod yolu yok.

**Hangi tabloda tutulmalı:** Zaten doğru tabloda — `business_follows.is_subscribed_email`. Değişiklik gerekmez.

**Hangi UI ekranında yönetilmeli:** İşletme takip akışında (takip butonu yanında veya sonrasında) ya da işletme profil sayfasında ayrı bir toggle olarak.

**Kullanıcı izni nasıl geri çekmeli:** İşletme profil sayfasındaki toggle'ı kapatarak. E-posta footer'ındaki unsubscribe linki `/settings/notifications` adresine yönlendiriyor — bu adres `business_follows.is_subscribed_email` güncellemesi yapan bir API ile desteklenmiş olmalı.

**KVKK/açık rıza açısından ayrı metin gerekir mi:** Evet. Her işletme için ayrı onay alınması ideal. Toplu onay ("tüm takip ettiğim işletmelere izin ver") de KVKK açısından tartışmalı olabilir — hukukçuya kontrol ettirilmeli.

### Aynı alanla tutulmaları doğru mu?

Hayır, bunlar iki farklı kavramdır ve ayrı tutulmalıdır:

| Özellik | Global opt-in | İşletme bazlı abonelik |
|---|---|---|
| Kapsam | Platform geneli | Tek bir işletme |
| Rıza granülaritesi | Bir kez, tüm ticari iletiler | Her işletme için ayrı |
| Geri çekme | Bir toggle ile tümü kapanır | İşletme bazında kapatılır |
| Tablo | `user_profiles` (önerilir) veya ayrı tablo | `business_follows.is_subscribed_email` |
| Mevcut durum | Yok (sadece device-local) | Var ama hiç true yapılmıyor |

---

## 3. Veri Modeli Seçenekleri

### Seçenek A: Yalnızca business_follows.is_subscribed_email kullanmak

Bu seçenek `_marketingOptIn` toggle'ını işletme bazlı olarak yorumlar. Toggle'ı kullanıcının "takip ettiğim tüm işletmelerden e-posta almak istiyorum" anlamında kullanır.

**Artıları:**
- Yeni tablo/sütun gerektirmez.
- Mevcut email kampanya altyapısı bu alanı zaten kullanıyor.
- Geri çekme granüler — işletme bazında kontrol.

**Eksileri:**
- `LegalAcceptancePage`'deki toggle işletme bağlamından bağımsız; hangi işletmenin `is_subscribed_email`'i güncellenecek belli değil.
- Kullanıcının henüz takip etmediği işletmeler için bu toggle anlamsız kalır.
- "Kabul et ekranında tüm mevcut takiplere toplu opt-in" mantığı KVKK açısından riskli — granüler rıza prensibiyle çelişebilir.
- Yeni bir takipte default false kalıyor; kullanıcı her işletme için ayrıca opt-in etmek zorunda — bu UX açısından karmaşık.

**KVKK riski:** Orta. Toplu opt-in granüler rıza ilkesiyle çelişebilir. Hukukçuya kontrol ettirilmeli.

**Teknik karmaşıklık:** Düşük-orta. Tablo değişikliği yok; ancak "tüm takiplere toplu güncelleme" mantığı RPC ile yazılmalı.

**Geri çekme kolaylığı:** Her işletme için ayrı ayrı; kullanıcı için zahmetli. Toplu geri çekme için ek RPC gerekir.

**Audit gereksinimi:** Orta — `business_follows` değişikliği timestamp ile iz bırakmıyor; ne zaman opt-in yapıldığı belli olmaz.

**Tavsiye edilir mi:** Tek başına hayır. İşletme bazlı abonelik için kullanılabilir, ama global opt-in için yeterli değil.

---

### Seçenek B: user_profiles tablosuna global marketing_email_opt_in eklemek

`user_profiles` tablosuna `marketing_email_opt_in boolean not null default false` ve `marketing_email_opted_in_at timestamptz null` sütunları eklenir.

**Artıları:**
- Temiz, tek bir global bayrak — kullanıcı başına bir değer.
- `LegalAcceptancePage` toggle'ı doğal olarak bu alana yazabilir.
- `NotificationPreferencesPage` e-posta toggle'ı bu alanı okuyup güncelleyebilir.
- Supabase üzerinde sunucu taraflı — ispat için timestamp ile tutulabilir.
- Unsubscribe linki global opt-out için bu alanı false yapan tek bir API çağrısı yapabilir.
- Mevcut RLS `user_profiles` için zaten var (`user_id = auth.uid()`).

**Eksileri:**
- `user_profiles` tablosu büyümeye devam ediyor — içine her tercihin eklenmesi tablo şişmesine yol açar.
- Global opt-in ile işletme bazlı aboneliği birbirinden ayırt etmek için ek logic gerekiyor: `marketing_email_opt_in = true AND is_subscribed_email = true` gibi kompozit bir koşul.
- E-posta gönderim sistemleri (`send-email-campaign`, `estimate_email_segment_v1`) `business_follows.is_subscribed_email` kullanıyor — global opt-in kontrolü için bu sistemler güncellenmeli.

**KVKK riski:** Düşük. Tek bir timestamp ile opt-in anı ispatlanabilir. Granüler işletme rızası için `business_follows.is_subscribed_email` ile kombinasyon gerekiyor.

**Teknik karmaşıklık:** Düşük. Migration basit. RPC `update_marketing_email_opt_in_v1(p_value bool)` yazımı kolay. Email sistemlerinde global check eklenmeli.

**Geri çekme kolaylığı:** Çok iyi. Tek RPC çağrısı yeterli.

**Audit gereksinimi:** Düşük-orta. `opted_in_at` timestamp yeterli temel ispat için.

**Tavsiye edilir mi:** Global pazarlama izni için evet — önerilir.

---

### Seçenek C: Ayrı user_marketing_consents tablosu oluşturmak

```sql
create table public.user_marketing_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_type text not null, -- 'platform_marketing_email', 'platform_marketing_push', ...
  granted boolean not null,
  source text not null, -- 'legal_acceptance_page', 'notification_settings', 'unsubscribe_link'
  granted_at timestamptz not null default now(),
  revoked_at timestamptz null,
  created_at timestamptz not null default now()
);
```

**Artıları:**
- En güçlü audit trail — ne zaman, hangi ekrandan, hangi tür onay alındığı tam olarak kayıt altında.
- Zaman içinde izin geçmişi sorgulanabilir ("kullanıcı 3 kez opt-in, 2 kez opt-out yapmış").
- Farklı consent türlerini (email, push, SMS, analytics) aynı tabloda yönetebilir.
- KVKK ispat yükümlülüğü için en sağlam seçenek.
- Platform pazarlama ile işletme bazlı aboneliği net olarak ayırıyor.

**Eksileri:**
- En yüksek teknik karmaşıklık — yeni tablo, yeni RLS, yeni RPC'ler, yeni repository sınıfı.
- Basit bir boolean flag için aşırı mühendislik olabilir (özellikle başlangıç aşamasında).
- "Güncel izin durumu nedir" sorgusu için ek logic gerekiyor (en son revoked_at null olan satır).
- E-posta gönderim sistemleri bu tabloya JOIN eklemeli.

**KVKK riski:** Çok düşük — tam denetim izi.

**Teknik karmaşıklık:** Yüksek. Projenin mevcut aşamasına göre aşırı olabilir.

**Geri çekme kolaylığı:** İyi — yeni bir `revoked_at` satırı eklenir, soft delete mantığı.

**Audit gereksinimi:** Tam karşılıyor.

**Tavsiye edilir mi:** İleri aşamada veya ciddi KVKK denetim gereksinimleri varsa evet. Mevcut Sprint kapsamı için erken.

---

### Seçenek D: Mevcut policy acceptance tablolarına marketing consent eklemek

`user_policy_acceptances` tablosuna `marketing_email_consent boolean null`, `analytics_consent boolean null` sütunları eklenir. Kabul kaydı oluşturulurken bu değerler de yazılır.

**Artıları:**
- Tek INSERT ile hem politika kabulü hem consent kaydı.
- Kabul zamanı ve consent zamanı eşleşiyor.
- Mevcut tablo zaten `user_id`, `accepted_at`, `source_app` bilgisini içeriyor.

**Eksileri:**
- Kavramsal olarak yanlış: `user_policy_acceptances` politika metni kabulünü temsil ediyor, pazarlama tercihini değil. Karıştırılmamalı.
- Kullanıcı daha sonra pazarlama iznini geri çektiğinde yeni bir satır mı oluşturulacak? Tablonun semantiği buna uygun değil.
- `privacy_requests` ve `account_deletion_requests` ile olan ayırım prensibini bozuyor.
- Policy acceptance güncellenemez (upsert ignoreDuplicates ile çalışıyor) — izni değiştirmek istediğinde ne olacak belirsiz.
- Tablonun amacı değişiyor; mevcut dokümantasyon ve RLS'e uyumsuz.

**KVKK riski:** Yüksek — kavramsal karışıklık, geri çekme mekanizması belirsiz.

**Teknik karmaşıklık:** Düşük başlangıç, uzun vadede yüksek bakım.

**Tavsiye edilir mi:** Hayır. Bu seçenek R-4 ile çözmeye çalıştığımız sorunları tekrar ediyor.

---

## 4. Önerilen Karar

### 4.1 Global pazarlama izni nerede tutulmalı?

**Seçenek B — `user_profiles` tablosuna iki sütun eklenmeli:**

```sql
alter table public.user_profiles
  add column if not exists marketing_email_opt_in boolean not null default false;

alter table public.user_profiles
  add column if not exists marketing_email_opted_in_at timestamptz null;
```

`marketing_email_opted_in_at` timestamp, izni geri çekince NULL'a döner değil, son opt-in zamanını tutar. Revoke zamanı için ayrıca `marketing_email_opted_out_at timestamptz null` veya `marketing_email_opt_in = false + updated_at` kombinasyonu kullanılabilir.

Gerekçe:
- `user_profiles` tek satır per user, RLS zaten doğru, mevcut update RPC'lerine parametre eklenmesi yeterli.
- Global bayrak basit sorgularla okunabilir.
- `marketing_email_opt_in = false DEFAULT` sayesinde mevcut kullanıcılar opt-out durumunda başlıyor — doğru ve güvenli.
- KVKK md. 4/2-ç (veri minimizasyonu) açısından Seçenek C'ye göre daha az veri birikimi.

Hukukçuya kontrol ettirilmeli: "user_profiles.marketing_email_opt_in + opted_in_at timestamp KVKK ispat yükümlülüğü için yeterli mi, yoksa revoke geçmişi de kayıt altına alınmalı mı?"

### 4.2 İşletme bazlı e-posta aboneliği nerede tutulmalı?

`business_follows.is_subscribed_email` — mevcut konum doğru. Değişiklik gerekmez. Sadece mobil uygulamada bu alanı true/false yapan kod yazılması gerekiyor.

### 4.3 _marketingOptIn hangi tabloya yazılmalı?

`user_profiles.marketing_email_opt_in` — global platform pazarlama izni olarak.

`LegalAcceptancePage`'deki toggle adı ve açıklaması "platform genelinde kampanya e-postası" anlamına hizalanmalı; işletme bazlı abonelik buraya karıştırılmamalı.

### 4.4 notification_preferences_page.dart hangi kaynaktan okumalı?

`user_profiles.marketing_email_opt_in` — Supabase'den. Mevcut SharedPreferences-only `ConsentState` yapısına ek olarak, `_emailNotifs` toggle'ı bu alanı Riverpod provider aracılığıyla okumalı ve değişince yazmalı.

### 4.5 business_follows.is_subscribed_email hangi durumda kullanılmalı?

Kullanıcı bir işletmeyi takip ettiği ekranda — takip akışı veya işletme profil sayfası. "Bu işletmeden kampanya e-postası al" toggle'ı olarak. `LegalAcceptancePage`'deki global toggle ile karıştırılmamalı.

---

## 5. Gerekli Teknik Değişiklik Planı

### 5.1 Gerekli Migration Dosyaları

**Migration 1 — user_profiles pazarlama opt-in sütunları:**
```
supabase/migrations/20260620000001_user_profiles_marketing_email_opt_in.sql
```
İçerik:
- `user_profiles.marketing_email_opt_in boolean not null default false`
- `user_profiles.marketing_email_opted_in_at timestamptz null`
- Comment on column (KVKK R-5 Seçenek B)

**Migration 2 — update_marketing_email_opt_in_v1 RPC:**
```
supabase/migrations/20260620000002_update_marketing_email_opt_in_rpc.sql
```

**Migration 3 — business_follows abonelik RPC:**
```
supabase/migrations/20260620000003_update_business_email_subscription_v1.sql
```

### 5.2 Gerekli RPC'ler

**RPC 1: Kullanıcı global pazarlama opt-in güncelleme**

```sql
-- supabase/migrations/20260620000002_update_marketing_email_opt_in_rpc.sql
CREATE OR REPLACE FUNCTION public.update_marketing_email_opt_in_v1(
  p_value boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.user_profiles
  SET
    marketing_email_opt_in     = p_value,
    marketing_email_opted_in_at = CASE WHEN p_value THEN now() ELSE marketing_email_opted_in_at END,
    updated_at                  = now()
  WHERE user_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.update_marketing_email_opt_in_v1(boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_marketing_email_opt_in_v1(boolean) TO authenticated;
COMMENT ON FUNCTION public.update_marketing_email_opt_in_v1 IS
  'Kullanıcının global platform pazarlama e-posta iznini günceller. '
  'R-5 Seçenek B. Çağıranlar: legal_acceptance_page.dart, notification_preferences_page.dart.';
```

**RPC 2: İşletme bazlı e-posta abonelik güncelleme**

```sql
-- supabase/migrations/20260620000003_update_business_email_subscription_v1.sql
CREATE OR REPLACE FUNCTION public.update_business_email_subscription_v1(
  p_business_id uuid,
  p_subscribed  boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  -- Sadece mevcut takip ilişkisi varsa güncelle
  UPDATE public.business_follows
  SET is_subscribed_email = p_subscribed
  WHERE user_id    = auth.uid()
    AND business_id = p_business_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Takip ilişkisi bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_business_email_subscription_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_business_email_subscription_v1(uuid, boolean) TO authenticated;
COMMENT ON FUNCTION public.update_business_email_subscription_v1 IS
  'İşletme bazlı e-posta abonelik durumunu günceller. '
  'Yalnızca mevcut takip ilişkisi olan kullanıcı çağırabilir. '
  'R-5 Seçenek B. Çağıranlar: business_profile_repository.dart (yeni).';
```

### 5.3 Gerekli RLS Policy Kontrolleri

- `user_profiles` üzerindeki mevcut `profiles_update_own` policy (veya eşdeğeri) `user_id = auth.uid()` koşulunu kullanıyorsa yeni sütunlar otomatik olarak kapsama girer — ek policy gerekmez.
- `business_follows` üzerindeki mevcut RLS `update_business_email_subscription_v1` SECURITY DEFINER RPC ile çalıştığından tablo-level RLS'e dokunmak gerekmez.
- Email gönderim sistemi (`send-email-campaign`, `estimate_email_segment_v1`) — bu sistemlere global opt-in koşulu eklenmeli mi sorgulanmalı:

Hukukçuya kontrol ettirilmeli: "İşletme bazlı abonelik (`is_subscribed_email = true`) kendi başına yeterli bir rıza delili mi, yoksa global `marketing_email_opt_in = true` da aranmalı mı? (iki katmanlı kontrol)"

### 5.4 Gerekli Flutter Repository Değişiklikleri

**1. Yeni MarketingConsentRepository (veya mevcut LegalRepository genişletme):**

`lib/features/legal/legal_repository.dart` içine iki metot eklenmeli:

```dart
Future<void> updateMarketingEmailOptIn(bool value) async {
  await _supabase.rpc('update_marketing_email_opt_in_v1', params: {'p_value': value});
}

Future<bool> loadMarketingEmailOptIn() async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return false;
  final row = await _supabase
      .from('user_profiles')
      .select('marketing_email_opt_in')
      .eq('user_id', uid)
      .maybeSingle();
  return (row?['marketing_email_opt_in'] as bool?) ?? false;
}
```

**2. Yeni BusinessFollowSubscriptionRepository (veya business follow repository genişletme):**

```dart
Future<void> updateBusinessEmailSubscription(String businessId, bool subscribed) async {
  await _supabase.rpc('update_business_email_subscription_v1', params: {
    'p_business_id': businessId,
    'p_subscribed': subscribed,
  });
}
```

### 5.5 Gerekli UI Değişiklikleri

**1. legal_acceptance_page.dart — _submit() güncellemesi:**
- `_marketingOptIn` değeri `updateMarketingEmailOptIn()` ile kaydedilmeli.
- `_analyticsOptIn` değeri `ConsentNotifier.update(analytics: ...)` ile kaydedilmeli (mevcut consent sistemi bu için var).
- İki işlem paralel çalıştırılabilir (Future.wait).
- Hata durumunda politika kabulü başarılı olmuş olsa bile opt-in kayıt başarısız olabilir — bu durum yıkıcı değil; kullanıcı daha sonra ayarlardan güncelleyebilir.

**2. notification_preferences_page.dart — e-posta toggle kalıcılaştırma:**
- Sayfa `ConsumerStatefulWidget`'a dönüştürülmeli.
- `_emailNotifs` başlangıç değeri `user_profiles.marketing_email_opt_in`'den yüklenmeli.
- Toggle değişince `updateMarketingEmailOptIn()` çağrılmalı.
- Loading/saving state yönetimi eklenmeli.

**3. İşletme profil sayfası veya takip akışı:**
- "Bu işletmeden e-posta kampanyası al" toggle'ı eklenmeli.
- `updateBusinessEmailSubscription()` çağrısı bağlanmalı.
- Bu toggle yalnızca kullanıcı ilgili işletmeyi takip ediyorken gösterilmeli.

### 5.6 Gerekli Testler

```
test/features/legal/marketing_opt_in_save_test.dart
  - _submit() sonrası user_profiles.marketing_email_opt_in güncellendi mi?
  - _marketingOptIn = false ile submit → opt_in = false kaydedildi mi?
  - Opt-in başarısız olsa bile politika kabulü başarılı sayılıyor mu?

test/features/notifications/notification_preferences_persistence_test.dart
  - Sayfa açılışında Supabase'den marketing_email_opt_in yükleniyor mu?
  - Toggle değişince updateMarketingEmailOptIn çağrılıyor mu?

test/features/business/business_email_subscription_test.dart
  - Takip edilen işletme için abonelik toggle'ı is_subscribed_email güncellüyor mu?
  - Takip edilmeyen işletme için toggle gösterilmiyor mu?
```

---

## 6. Kullanıcıya Gösterilecek Mikro Metinler

Bu metinler öneri niteliğindedir; final hukuki metin hukuk danışmanı tarafından onaylanmalıdır.

### Pazarlama e-postası checkbox/toggle metni (legal_acceptance_page.dart)

Toggle başlığı:
> "Yeedoy'dan kampanya ve fırsat e-postaları almak istiyorum"

Toggle altyazısı:
> "Bu tercih isteğe bağlıdır ve daha sonra profil ayarlarından değiştirilebilir. Takip ettiğiniz işletmelerin kampanyaları için ayrı onay gerekir."

### İzni geri çekme açıklaması (notification_preferences_page.dart)

E-posta Bildirimleri kanalı altyazısı:
> "Yeedoy'dan kampanya ve güncelleme e-postası almak için açık. Takip ettiğiniz işletmelerin e-postaları için işletme profilinden ayrıca yönetebilirsiniz."

Footer notu:
> "Bildirim tercihleriniz anlık olarak kaydedilir ve istediğiniz zaman değiştirilebilir."

### Bildirim tercihleri sayfasındaki uyarı (mevcut _InfoBanner yerine veya ek olarak)

> "E-posta tercihleriniz tüm cihazlarınızda geçerlidir. Belirli bir işletmeden e-posta almayı durdurmak için o işletmenin profilini ziyaret edin."

### İşletme bazlı e-posta aboneliği (işletme profil sayfası)

Toggle başlığı:
> "[İşletme Adı]'ndan kampanya e-postası al"

Toggle altyazısı:
> "Bu işletme yeni kampanya duyurduğunda e-posta alırsınız. İstediğiniz zaman kapatabilirsiniz."

---

## 7. Riskler

### Risk 1 — Global izin ile işletme bazlı izin karışırsa ne olur?

`_marketingOptIn` toggle'ı "işletme bazlı abone ol" olarak yorumlanırsa ve buna göre tüm `business_follows`'u toplu güncelleyen bir RPC yazılırsa:
- Kullanıcı henüz takip etmediği işletmeler için izin veremez — güncelleme anlamsız olur.
- Kullanıcı daha sonra yeni bir işletme takip ederse toggle durumu uyumsuz kalır.
- Hangi işletmeler için opt-in yapıldığı kullanıcıya belirsizleşir.
- 6563 sayılı Kanun açısından "her hizmet sağlayıcı için ayrı onay" prensibiyle çelişebilir (hukukçuya kontrol ettirilmeli).

### Risk 2 — Kullanıcı izni vermeden e-posta gönderilirse ne olur?

`business_follows.is_subscribed_email = false` olan kullanıcıya gönderim yapılırsa:
- 6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun md. 6 ihlali.
- İdari para cezası riski (BTK tarafından her mesaj için ayrı ceza kesilebilir).
- Resend/e-posta sağlayıcısı hesabı spam şikayeti nedeniyle askıya alınabilir.
- Kullanıcı güven kaybı.

Mevcut durumda `send-email-campaign` edge function `is_subscribed_email = true` filtresi uyguluyor — bu doğru. Ancak mobil uygulama üzerinden `is_subscribed_email`'i true yapan bir yol olmadığı sürece hiç kimse bu e-postaları almıyor — bu sorun değil ama ürün değer sunmuyor.

### Risk 3 — Kullanıcı izni geri çekince hangi sistemler etkilenir?

`marketing_email_opt_in = false` yapıldığında:
- `estimate_email_segment_v1` ve `send-email-campaign` bu alanı kontrol etmiyor (yalnızca `is_subscribed_email` kontrol ediyor) — email sistemleri güncellenmeli.
- `user_profiles.marketing_email_opt_in = false` + `business_follows.is_subscribed_email = true` çelişkisi oluşabilir — hangisi öncelikli olacağı mimari olarak kararlaştırılmalı.

Öneri: `marketing_email_opt_in = false` olan kullanıcı için `is_subscribed_email` değerine bakılmaksızın email gönderilmemeli. Katmanlı kontrol: `global AND işletme-bazlı`.

Hukukçuya kontrol ettirilmeli: "Global opt-out işletme bazlı aboneliği geçersiz kılar mı?"

### Risk 4 — Unsubscribe linki /settings/notifications'a yönlendiriyor ama backend bağlantısı yok

`send-email-campaign/index.ts` unsubscribe footer'ında şu var:
```html
<a href="https://yeedoy.com/settings/notifications">aboneliğinizi iptal edebilirsiniz</a>
```

Bu link `/settings/notifications` adresine yönlendiriyor. Bu adresin `is_subscribed_email = false` yapan bir API endpoint veya UI flow ile desteklenmesi gerekiyor. Şu anda mobil uygulamada `NotificationPreferencesPage` var ama web'de `/settings/notifications` route'u henüz incelenmedi.

6563 sayılı Kanun: Her ticari elektronik iletide çalışan bir iptal mekanizması zorunlu. Link var ama fonksiyon yok ise bu ihlal oluşturur.

---

## 8. Sonraki Uygulama Promptu İçin Öneri

### SQL / Supabase migration için
**Agent:** `voltagent-data-ai:postgres-pro`

Görev: `20260620000001_user_profiles_marketing_email_opt_in.sql`, `20260620000002_update_marketing_email_opt_in_rpc.sql`, `20260620000003_update_business_email_subscription_v1.sql` migration'larını oluştur. `estimate_email_segment_v1` ve `send-email-campaign` için global opt-in koşulu nasıl ekleneceğini değerlendir.

### Flutter repository / UI için
**Agent:** `voltagent-lang:flutter-expert`

Görev: `legal_acceptance_page.dart` içinde `_submit()` metodunu güncelle — `_marketingOptIn` değerini `update_marketing_email_opt_in_v1` RPC'sine yaz. `notification_preferences_page.dart`'ı `ConsumerStatefulWidget`'a dönüştür ve `marketing_email_opt_in` alanını Supabase'den yükle/kaydet. İşletme profil sayfasına abonelik toggle'ı ekle.

### Test için
**Agent:** `voltagent-qa-sec:qa-expert`

Görev: Bölüm 5.6'daki test senaryolarını implement et. Özellikle "opt-in başarısız olsa bile politika kabulü başarılı sayılmalı" edge case'ini test et.

### Legal metin güncellemesi için
**Agent:** `voltagent-biz:legal-advisor`

Görev: `legal-data-inventory.md` Bölüm 3 satır 3.6 güncellenmeli (`is_subscribed_email` artık nasıl set ediliyor). `legal-preflight-report.md` R-5 satırı güncellenmeli (teknik değişiklik tamamlandı, hukuki onay bekleniyor). KVKK Aydınlatma Metni taslağı için pazarlama e-postası bölümü — global opt-in ve işletme bazlı abonelik ayrımı açıklanmalı.

---

*Bu rapor kod değişikliği içermez. Migration, RPC veya Flutter kodu oluşturulmamıştır. Tüm değişiklikler yukarıda listelenen sonraki adımlarda ayrı promptlar aracılığıyla uygulanacaktır. Hukukçuya kontrol ettirilmesi gereken maddeler metin içinde açıkça işaretlenmiştir.*
