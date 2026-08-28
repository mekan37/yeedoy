# R-5 Pazarlama E-posta Opt-In — Veritabanı Uygulama Raporu

**Hazırlanma tarihi:** 2026-06-20  
**Hazırlayan:** postgres-pro  
**Önceki rapor:** `docs/arsiv/r5-marketing-optin-data-model-decision.md`  
**Durum:** Migration dosyaları oluşturuldu. Production'a uygulanmadı.

---

## 1. Yapılan Değişiklik Özeti

R-5 kararı uyarınca iki migration dosyası oluşturuldu:

| Dosya | İçerik |
|---|---|
| `supabase/migrations/20260620000001_user_profiles_marketing_email_opt_in.sql` | `user_profiles` tablosuna iki yeni sütun |
| `supabase/migrations/20260620000002_r5_marketing_email_rpcs.sql` | 3 yeni RPC + `business_follows` UPDATE policy |

Kod değişikliği yapılmadı. Flutter dosyaları değiştirilmedi.

---

## 2. Gerçek Profil Tablo Adı

**Tablo adı: `public.user_profiles`**

`docs/arsiv/r5-marketing-optin-data-model-decision.md` raporunda `user_profiles` olarak doğru belirtilmiş. Farklılık yok.

Doğrulama kaynağı: `supabase/migrations/00000000000000_base_schema.sql` satır 24161:
```sql
CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "user_id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    ...
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "shadow_banned" boolean DEFAULT false NOT NULL
);
```

`profiles` adında ayrı bir public tablo yoktur. `supabase/migrations/20260424000009_email_campaigns.sql` içinde eski kod `profiles.email` ve `follower_id` referansı yapıyordu — bu schema uyumsuzluğu zaten `20260603000010_fix_estimate_email_segment_v1.sql` migration'ı ile düzeltilmiştir.

---

## 3. Eklenen Sütunlar

Migration: `20260620000001_user_profiles_marketing_email_opt_in.sql`

### 3.1 marketing_email_opt_in

```sql
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS marketing_email_opt_in boolean NOT NULL DEFAULT false;
```

| Özellik | Değer |
|---|---|
| Tür | `boolean NOT NULL` |
| Default | `false` |
| Null | İzin verilmiyor |
| Semantik | Platform geneli pazarlama e-posta izni |
| Etkilenen kullanıcılar | Mevcut tüm kullanıcılar `false` ile başlar (otomatik opt-in yapılmaz) |

### 3.2 marketing_email_opted_in_at

```sql
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS marketing_email_opted_in_at timestamptz NULL;
```

| Özellik | Değer |
|---|---|
| Tür | `timestamptz NULL` |
| Default | `NULL` |
| Semantik | Son opt-in zamanı. Opt-out durumunda NULL yapılır. |
| KVKK amacı | İspat yükümlülüğü — ne zaman izin verildiği kayıt altında |

### 3.3 Güncel user_profiles sütun listesi (tüm migration'lar sonrası)

```
user_id                       uuid NOT NULL (PK)
display_name                  text NOT NULL
avatar_url                    text
bio                           text
is_gourmet                    boolean NOT NULL DEFAULT false
created_at                    timestamptz NOT NULL DEFAULT now()
updated_at                    timestamptz NOT NULL DEFAULT now()
shadow_banned                 boolean NOT NULL DEFAULT false
social_links                  jsonb NULL  -- 20260603000011 ile eklendi
marketing_email_opt_in        boolean NOT NULL DEFAULT false  -- YENİ (bu migration)
marketing_email_opted_in_at   timestamptz NULL                -- YENİ (bu migration)
```

---

## 4. Oluşturulan ve Güncellenen RPC'ler

Migration: `20260620000002_r5_marketing_email_rpcs.sql`

### 4.1 get_my_notification_preferences_v1

**İmza:**
```sql
CREATE OR REPLACE FUNCTION public.get_my_notification_preferences_v1()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
```

**Döndürülen JSON:**
```json
{
  "marketing_email_opt_in": false,
  "marketing_email_opted_in_at": null
}
```

**Çağıranlar:** `notification_preferences_page.dart`, `legal_acceptance_page.dart`  
**GRANT:** `authenticated`  
**Edge case:** `user_profiles` kaydı yoksa `NOT FOUND` fırlatmak yerine `false/null` döner — Flutter tarafında profil oluşturma akışı henüz tamamlanmamış olabilir.

### 4.2 update_my_marketing_email_opt_in_v1

**İmza:**
```sql
CREATE OR REPLACE FUNCTION public.update_my_marketing_email_opt_in_v1(
  p_value boolean
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

**Davranış:**
- `p_value = true` → `marketing_email_opt_in = true`, `marketing_email_opted_in_at = now()`, `updated_at = now()`
- `p_value = false` → `marketing_email_opt_in = false`, `marketing_email_opted_in_at = NULL`, `updated_at = now()`
- `p_value = NULL` → `P0003 validation_error` hatası
- `user_profiles` kaydı bulunamazsa → RAISE WARNING (sessiz başarı, kayıt yok)

**business_follows tablosuna DOKUNMAZ.**

**Çağıranlar:** `legal_acceptance_page.dart` (_submit()), `notification_preferences_page.dart` (e-posta toggle)  
**GRANT:** `authenticated`

### 4.3 update_business_follow_email_subscription_v1

**İmza:**
```sql
CREATE OR REPLACE FUNCTION public.update_business_follow_email_subscription_v1(
  p_business_id uuid,
  p_subscribed  boolean
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

**Davranış:**
- `business_follows.is_subscribed_email` alanını günceller
- Yalnızca `auth.uid()` kullanıcısının, `p_business_id` işletmesine ait takip kaydını etkiler
- Takip ilişkisi yoksa `P0001 not_found` hatası
- Null parametreler için `P0003 validation_error` hatası

**user_profiles tablosuna DOKUNMAZ — global opt-in değiştirmez.**

**Çağıranlar:** `business_profile_repository.dart` (yeni — Flutter katmanı), web unsubscribe endpoint  
**GRANT:** `authenticated`

### 4.4 RPC Önceden Var Olanlar (değiştirilmedi)

Mevcut kodda aynı adda RPC yoktu:
- `get_my_notification_preferences_v1` — daha önce yoktu, yeni oluşturuldu
- `update_my_marketing_email_opt_in_v1` — daha önce yoktu, yeni oluşturuldu
- `update_business_follow_email_subscription_v1` — daha önce yoktu, yeni oluşturuldu

Var olan ve korunan RPC'ler:
- `follow_business_v1` — dokunulmadı
- `unfollow_business_v1` — dokunulmadı
- `estimate_email_segment_v1` — dokunulmadı (bkz. Bölüm 6)
- `list_email_campaigns_v1` — dokunulmadı
- `create_email_campaign_v1` — dokunulmadı

---

## 5. RLS ve Güvenlik Değerlendirmesi

### 5.1 user_profiles RLS analizi

**Mevcut policy'ler (base_schema, satır 27514-27526):**

```sql
CREATE POLICY "profiles_delete_own" ON "public"."user_profiles"
  FOR DELETE TO "authenticated" USING (user_id = auth.uid());

CREATE POLICY "profiles_insert_own" ON "public"."user_profiles"
  FOR INSERT TO "authenticated" WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_read" ON "public"."user_profiles"
  FOR SELECT USING (true);

CREATE POLICY "profiles_update_own" ON "public"."user_profiles"
  FOR UPDATE TO "authenticated"
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
```

**Sonuç:** `profiles_update_own` policy tablo sütunlarına göre değil, satıra göre çalışır. Yeni `marketing_email_opt_in` ve `marketing_email_opted_in_at` sütunları `profiles_update_own` kapsamına otomatik girer. Ek policy gerekmez.

**Güvenlik notu:** `profiles_read` USING(true) ile herkese açık okuma sağlıyor. `marketing_email_opt_in` değeri de `SELECT *` ile okunabilir. Bu mevcut `shadow_banned` gibi alanlarla tutarlı; gizlilik değeri düşük bir boolean. Sütun seviyesinde okuma kısıtlaması gerekiyorsa ayrı bir column-level security değerlendirmesi yapılmalı (bu migration kapsamı dışında).

### 5.2 business_follows RLS analizi

**Mevcut policy'ler (base_schema, satır 26713-26721):**

```sql
-- SELECT, INSERT, DELETE policy'leri var
-- UPDATE policy YOK
```

`business_follows`'ta UPDATE policy olmadığı tespit edildi. Tablo GRANT'ı `authenticated`'e ALL veriyor (satır 30781-30783), bu da row-level UPDATE guard olmadan herhangi bir authenticated kullanıcının herhangi bir satırı güncelleyebileceği anlamına gelir.

**Bu migration'da yapılan düzeltme:**

`20260620000002` migration'ı şu policy'yi ekliyor:

```sql
CREATE POLICY "business_follows_update_own"
  ON public.business_follows
  FOR UPDATE TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

Bu policy ile:
- Kullanıcı yalnızca kendi `user_id`'sine ait satırları güncelleyebilir
- `update_business_follow_email_subscription_v1` SECURITY DEFINER RPC, RLS'i bypass eder ve zaten `WHERE user_id = v_uid` koşulunu içerir — ek güvenlik katmanı
- Doğrudan tablo UPDATE'i yapan mevcut Flutter kodu varsa da RLS guard sayesinde başka kullanıcının kaydı değiştirilemez

### 5.3 SECURITY DEFINER search_path güvenliği

Tüm yeni RPC'ler `SET search_path = public` kullanıyor. Bu, search_path injection saldırılarına karşı koruma sağlar ve repodaki diğer SECURITY DEFINER fonksiyonlarla tutarlıdır (örn. `follow_business_v1`, `fix_estimate_email_segment_v1`).

---

## 6. business_follows ile Global İzin Ayrımı

Bu migration iki kavramın net olarak ayrı tutulmasını sağlar:

| Alan | Tablo | Kapsam | Semantik |
|---|---|---|---|
| `marketing_email_opt_in` | `user_profiles` | Platform geneli | "Yeedoy'dan pazarlama e-postası almak istiyorum" |
| `is_subscribed_email` | `business_follows` | Belirli bir işletme | "Bu işletmeden kampanya e-postası almak istiyorum" |

**Birbirini etkilemedikleri garanti altına alınmıştır:**
- `update_my_marketing_email_opt_in_v1` → yalnızca `user_profiles` günceller, `business_follows`'a dokunmaz
- `update_business_follow_email_subscription_v1` → yalnızca `business_follows` günceller, `user_profiles`'a dokunmaz
- `get_my_notification_preferences_v1` → yalnızca `user_profiles` okur

---

## 7. E-posta Gönderiminde Kontrol Edilmesi Gereken SQL Koşulları

Bu migration kod değişikliği içermez. Aşağıdaki koşullar öneri niteliğindedir ve e-posta gönderim sistemleri güncelleneceğinde uygulanmalıdır.

### 7.1 İşletme kampanya e-postası gönderirken (send-email-campaign edge function)

Mevcut filtre:
```typescript
.eq("is_subscribed_email", true)
```

Önerilen ek koşul (global opt-in kontrolü eklenirse):
```sql
-- Hem işletme bazlı hem global izni olan kullanıcılar
SELECT bf.user_id
FROM public.business_follows bf
JOIN public.user_profiles up ON up.user_id = bf.user_id
WHERE bf.business_id = p_business_id
  AND bf.is_subscribed_email = true
  AND up.marketing_email_opt_in = true;
```

Hukukçuya kontrol ettirilmeli: "İşletme bazlı abonelik tek başına yeterli mi, yoksa global opt-in da zorunlu mu?" Karar netleşene kadar mevcut filtre (`is_subscribed_email = true`) değiştirilmemeli.

### 7.2 estimate_email_segment_v1 için önerilen güncelleme

Mevcut `20260603000010_fix_estimate_email_segment_v1.sql` yalnızca `is_subscribed_email = true` filtreliyor. Global opt-in koşulu eklenecekse:

```sql
SELECT count(*)::int
FROM public.business_follows bf
JOIN public.user_profiles up ON up.user_id = bf.user_id
WHERE bf.business_id = p_business_id
  AND bf.is_subscribed_email = true
  AND up.marketing_email_opt_in = true  -- global izin kontrolü
  AND (is_admin() OR is_owner_of_business(p_business_id))
  AND (
    p_segment = 'all_followers'
    OR (p_segment = 'new_30d'      AND bf.created_at >= now() - interval '30 days')
    OR (p_segment = 'inactive_30d' AND bf.created_at <  now() - interval '30 days')
  );
```

Bu güncelleme ayrı bir migration (örn. `20260621000001_estimate_email_segment_v2.sql`) olarak uygulanmalı; hukuki karar geldikten sonra.

### 7.3 Global opt-out durumunda e-posta engelleme (katmanlı kontrol önerisi)

```sql
-- E-posta gönderilecek kullanıcı listesini belirleyen güvenli sorgu:
-- KATMAN 1: İşletme bazlı abonelik
-- KATMAN 2: Global platform pazarlama izni
SELECT
  bf.user_id,
  up.marketing_email_opt_in,
  bf.is_subscribed_email
FROM public.business_follows bf
JOIN public.user_profiles up ON up.user_id = bf.user_id
WHERE bf.business_id = :business_id
  AND bf.is_subscribed_email = true    -- katman 1: işletme bazlı
  AND up.marketing_email_opt_in = true  -- katman 2: global platform
```

Bu sorgu iki koşulun AND kombinasyonunu kullanır: kullanıcı hem işletmeyi takip edip o işletmeden e-posta almak istediğini belirtmiş, hem de platform genelinde pazarlama e-postasına izin vermiş olmalıdır.

---

## 8. Çalıştırılan Testler / Çalıştırılamayan Testler

### 8.1 Statik analiz (çalıştırıldı)

Migration dosyaları şu açılardan manuel olarak doğrulandı:

| Kontrol | Sonuç |
|---|---|
| `user_profiles` tablo adı doğru mu? | Geçti — base_schema ile eşleşiyor |
| `updated_at` sütunu `user_profiles`'ta var mı? | Geçti — satır 24168'de doğrulandı |
| `profiles_update_own` policy yeni sütunları kapsıyor mu? | Geçti — row-based policy, sütunları otomatik kapsar |
| `business_follows` UPDATE policy var mıydı? | Geçti — yoktu, bu migration ile eklendi |
| `is_subscribed_email` sütunu `business_follows`'ta var mı? | Geçti — 20260424000009 ile eklendi |
| RPC'ler `auth.uid() IS NULL` kontrolü yapıyor mu? | Geçti — 3 RPC'de de mevcut |
| RPC'ler `SECURITY DEFINER SET search_path = public` kullanıyor mu? | Geçti — 3 RPC'de de mevcut |
| `update_my_marketing_email_opt_in_v1` business_follows'a dokunuyor mu? | Geçti — hayır, yalnızca user_profiles |
| `update_business_follow_email_subscription_v1` user_profiles'a dokunuyor mu? | Geçti — hayır, yalnızca business_follows |
| `ADD COLUMN IF NOT EXISTS` güvenli mi? | Geçti — idempotent, ikinci çalışmada hata vermez |
| REVOKE + GRANT pattern doğru mu? | Geçti — authenticated'e GRANT, PUBLIC'ten REVOKE |
| Yeni sütunlarda NOT NULL DEFAULT false — mevcut kullanıcılar etkileniyor mu? | Geçti — DEFAULT false, kimse otomatik opt-in yapılmıyor |

### 8.2 Local Supabase testi (çalıştırılamadı)

Local Supabase stack bu oturumda çalıştırılmadı. Migration'lar static analiz ile doğrulandı.

### 8.3 Production öncesi manuel doğrulama sorguları

Production'a uygulamadan önce aşağıdaki sorgular çalıştırılmalıdır:

**A — Migration öncesi baseline:**
```sql
-- user_profiles mevcut sütunları kontrol
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_profiles'
ORDER BY ordinal_position;

-- business_follows RLS policy durumu
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'business_follows';

-- Mevcut RPC kontrolü (varsa versiyon çakışması olabilir)
SELECT proname, prosecdef
FROM pg_proc
JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE nspname = 'public'
  AND proname IN (
    'get_my_notification_preferences_v1',
    'update_my_marketing_email_opt_in_v1',
    'update_business_follow_email_subscription_v1'
  );
```

**B — Migration sonrası doğrulama:**
```sql
-- Yeni sütunların eklendiğini doğrula
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_profiles'
  AND column_name IN ('marketing_email_opt_in', 'marketing_email_opted_in_at');

-- Yeni RPC'lerin oluşturulduğunu doğrula
SELECT proname, prosecdef, proconfig
FROM pg_proc
JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE nspname = 'public'
  AND proname IN (
    'get_my_notification_preferences_v1',
    'update_my_marketing_email_opt_in_v1',
    'update_business_follow_email_subscription_v1'
  );

-- business_follows UPDATE policy eklendiğini doğrula
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'business_follows'
  AND policyname = 'business_follows_update_own';

-- Mevcut kullanıcıların marketing_email_opt_in değerini doğrula
-- (hepsi false olmalı)
SELECT
  COUNT(*) FILTER (WHERE marketing_email_opt_in = true)  AS opted_in_count,
  COUNT(*) FILTER (WHERE marketing_email_opt_in = false) AS opted_out_count,
  COUNT(*) FILTER (WHERE marketing_email_opted_in_at IS NOT NULL) AS has_opt_in_date
FROM public.user_profiles;
-- Beklenen: opted_in_count=0, opted_out_count=toplam_kullanici, has_opt_in_date=0
```

**C — RPC fonksiyon testi (authenticated kullanıcı olarak):**
```sql
-- Test 1: get_my_notification_preferences_v1 (yeni kullanıcı)
SELECT public.get_my_notification_preferences_v1();
-- Beklenen: {"marketing_email_opt_in": false, "marketing_email_opted_in_at": null}

-- Test 2: opt-in
SELECT public.update_my_marketing_email_opt_in_v1(true);
SELECT public.get_my_notification_preferences_v1();
-- Beklenen: {"marketing_email_opt_in": true, "marketing_email_opted_in_at": "<timestamp>"}

-- Test 3: opt-out
SELECT public.update_my_marketing_email_opt_in_v1(false);
SELECT public.get_my_notification_preferences_v1();
-- Beklenen: {"marketing_email_opt_in": false, "marketing_email_opted_in_at": null}

-- Test 4: işletme bazlı abonelik
-- (önce işletmeyi takip edilmeli)
SELECT public.update_business_follow_email_subscription_v1('<business_id>', true);
-- Beklenen: void (hata yok)
SELECT is_subscribed_email FROM public.business_follows
WHERE user_id = auth.uid() AND business_id = '<business_id>';
-- Beklened: true

-- Test 5: takip edilmeyen işletme için abonelik (not_found testi)
SELECT public.update_business_follow_email_subscription_v1('<takip_edilmeyen_business_id>', true);
-- Beklenen: P0001 not_found hatası
```

---

## 9. Riskler

### Risk 1 — profiles_read USING(true) ile marketing_email_opt_in herkese okunabilir

Mevcut `profiles_read` policy `USING(true)` ile herkese açık. `marketing_email_opt_in` bu kapsamda okunabilir. Gizlilik değeri düşük (boolean), ancak pazarlama amacıyla kötüye kullanılabilir. Eğer bu bilginin gizli tutulması gerekiyorsa `profiles_read` policy'nin kısıtlanması veya column-level security eklenmesi değerlendirilmeli.

**Öneri:** Şimdilik kabul edilebilir. `shadow_banned` gibi alanlar da aynı policy kapsamında. İleride bir audit yapılırsa birlikte değerlendirilebilir.

### Risk 2 — estimate_email_segment_v1 global opt-in kontrol etmiyor

Mevcut `estimate_email_segment_v1` yalnızca `is_subscribed_email = true` filtreliyor. Global `marketing_email_opt_in = false` olan kullanıcılar da sayıma dahil olabilir. Bu, bir kullanıcının global opt-out yapmasına rağmen kampanya tahmin sayısında görünmesi anlamına gelir. Gerçek gönderimde kullanılan `send-email-campaign` edge function da aynı durumda.

**Öneri:** Hukuki karar netleşince `estimate_email_segment_v1` ve `send-email-campaign` için global opt-in koşulu eklenecek yeni bir migration açılmalı. Bu migration o karardan bağımsız olarak uygulanabilir.

### Risk 3 — update_my_marketing_email_opt_in_v1 user_profiles kaydı yoksa uyarı verir

Edge case: kullanıcının auth kaydı var ama `user_profiles` kaydı henüz oluşturulmamış. RPC `RAISE WARNING` ile sessizce geçer. Flutter tarafında bu durumu `NOT FOUND` yerine başarı olarak görür.

**Değerlendirme:** `user_profiles` kaydı Flutter'da `auth.onAuthStateChange` ile login'de upsert ediliyor. Bu edge case pratikte nadirdir ve yıkıcı değildir. Kullanıcı daha sonra tekrar çağırabilir.

### Risk 4 — business_follows UPDATE policy eklenmesi mevcut doğrudan UPDATE akışlarını kırabilir

`business_follows_update_own` policy, kullanıcıların yalnızca kendi satırlarını doğrudan UPDATE yapabilmesine izin veriyor. `follow_business_v1` INSERT kullandığından etkilenmez. `unfollow_business_v1` DELETE kullandığından etkilenmez. Doğrudan `business_follows` UPDATE yapan başka Flutter/web kodu varsa `user_id = auth.uid()` koşulu zaten sağlanıyorsa çalışır.

**Değerlendirme:** Düşük risk. Policy mevcut doğru kullanımı kırmaz; yalnızca `user_id != auth.uid()` ile UPDATE yapmaya çalışan kodu engeller (ki bu zaten olmamalıydı).

### Risk 5 — opted_in_at opt-out sonrası NULL yapılıyor — ispat sorunu

`marketing_email_opted_in_at` opt-out yapıldığında NULL'a çekiliyor. Bu, kullanıcının ne zaman opt-out yaptığının kaydını tutmuyor. Yalnızca son opt-in zamanı biliniyor.

**Hukukçuya kontrol ettirilmeli:** KVKK ispat yükümlülüğü açısından yalnızca son opt-in zamanının yeterli olup olmadığı veya revoke geçmişinin de kayıt altına alınması gerekip gerekmediği clarify edilmeli. Eğer geçmiş gerekiyorsa Seçenek C (ayrı `user_marketing_consents` tablosu) değerlendirilebilir.

**Mevcut hafifletici:** `updated_at` sütunu her güncellemede `now()` ile güncelleniyor — en son değişiklik zamanı korunuyor. Bu zaman, opt-in mi opt-out mu olduğunu tek başına kanıtlamıyor.

---

## 10. Rollback Planı

Production'a uygulandıktan sonra geri alınması gerekirse:

```sql
-- Rollback migration (yeni bir dosya olarak oluşturulmalı):
-- supabase/migrations/20260620000099_rollback_r5_marketing_email.sql

-- 1. RPC'leri kaldır
DROP FUNCTION IF EXISTS public.get_my_notification_preferences_v1();
DROP FUNCTION IF EXISTS public.update_my_marketing_email_opt_in_v1(boolean);
DROP FUNCTION IF EXISTS public.update_business_follow_email_subscription_v1(uuid, boolean);

-- 2. business_follows UPDATE policy'yi kaldır
DROP POLICY IF EXISTS "business_follows_update_own" ON public.business_follows;

-- 3. user_profiles sütunlarını kaldır
-- UYARI: Bu adım veri kaybına yol açar (opt-in kayıtları silinir)
ALTER TABLE public.user_profiles
  DROP COLUMN IF EXISTS marketing_email_opted_in_at,
  DROP COLUMN IF EXISTS marketing_email_opt_in;
```

**Önemli:** Sütun drop öncesinde opt-in verisi yedeklenebilir:
```sql
-- Yedek (rollback öncesi çalıştır):
CREATE TABLE public._backup_marketing_email_opt_in_20260620 AS
SELECT user_id, marketing_email_opt_in, marketing_email_opted_in_at
FROM public.user_profiles
WHERE marketing_email_opt_in = true;
```

---

## 11. Production Öncesi Kontrol Listesi

- [ ] Migration'ların test ortamında (`supabase start` + `supabase db reset`) başarıyla çalıştığı doğrulanmalı
- [ ] Sorgu A — baseline (Bölüm 8.3) production'a bağlanmadan önce çalıştırılmalı
- [ ] 20260620000001 uygulanmalı; sonra Sorgu B ile sütunların eklendiği doğrulanmalı
- [ ] 20260620000002 uygulanmalı; sonra Sorgu B + C ile RPC'ler ve policy doğrulanmalı
- [ ] Flutter tarafı (legal_acceptance_page.dart, notification_preferences_page.dart) kendi migration'larıyla birlikte test edilmeli
- [ ] `update_my_marketing_email_opt_in_v1(true)` → `get_my_notification_preferences_v1()` döngüsü uçtan uca test edilmeli
- [ ] `update_business_follow_email_subscription_v1` takip edilmiş bir işletme için test edilmeli
- [ ] Hukuki karar: opted_in_at rollback davranışı hukukçuya onaylatılmalı
- [ ] Hukuki karar: global opt-in + işletme bazlı abonelik katmanlı kontrol kararı alınmalı

---

## 12. Sonraki Flutter Uygulama Adımı İçin Dosya Listesi

Flutter agent (`voltagent-lang:flutter-expert`) aşağıdaki dosyaları değiştirmelidir:

| Dosya | Değişiklik |
|---|---|
| `uygulamalar/mobil/lib/features/legal/legal_repository.dart` | `updateMarketingEmailOptIn(bool)` ve `loadMarketingEmailOptIn()` metotları eklenmeli. RPC: `update_my_marketing_email_opt_in_v1`, `get_my_notification_preferences_v1`. |
| `uygulamalar/mobil/lib/features/legal/ui/legal_acceptance_page.dart` | `_submit()` içinde `_marketingOptIn` değeri `updateMarketingEmailOptIn(bool)` ile kaydedilmeli. `Future.wait([policyAccept, marketingOptIn])` paralel çalıştırılabilir. Opt-in başarısız olsa da politika kabulü başarılı sayılmalı. |
| `uygulamalar/mobil/lib/features/notifications/ui/notification_preferences_page.dart` | `StatefulWidget` → `ConsumerStatefulWidget`. `initState`'te `get_my_notification_preferences_v1` okunmalı. Toggle değişince `update_my_marketing_email_opt_in_v1` çağrılmalı. |
| `uygulamalar/mobil/lib/features/business/data/business_profile_repository.dart` (yeni veya mevcut) | `updateBusinessEmailSubscription(businessId, subscribed)` metodu. RPC: `update_business_follow_email_subscription_v1`. |

**RPC çağrı örnekleri:**

```dart
// Global opt-in kaydet (legal_repository.dart)
await _supabase.rpc(
  'update_my_marketing_email_opt_in_v1',
  params: {'p_value': value},
);

// Global opt-in oku (legal_repository.dart)
final result = await _supabase.rpc(
  'get_my_notification_preferences_v1',
);
final marketingOptIn = (result as Map?)['marketing_email_opt_in'] as bool? ?? false;

// İşletme bazlı abonelik güncelle (business_profile_repository.dart)
await _supabase.rpc(
  'update_business_follow_email_subscription_v1',
  params: {
    'p_business_id': businessId,
    'p_subscribed': subscribed,
  },
);
```

---

*Bu rapor yalnızca database/RPC katmanı değişikliklerini kapsar. Flutter UI değişiklikleri bu raporun kapsamı dışındadır. Hukukçuya onaylatılması gereken maddeler Bölüm 9 ve Bölüm 11'de açıkça belirtilmiştir.*
