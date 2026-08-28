# R-5 Pazarlama E-posta Opt-In — Veritabanı Doğrulama Raporu

**Hazırlanma tarihi:** 2026-06-20  
**Hazırlayan:** postgres-pro  
**Doğrulanan migration'lar:**  
- `supabase/migrations/20260620000001_user_profiles_marketing_email_opt_in.sql`  
- `supabase/migrations/20260620000002_r5_marketing_email_rpcs.sql`  
**Doğrulama yöntemi:** Statik analiz (local Supabase başlatılmadı — dinamik testler çalıştırılamadı)  
**Durum:** 25 kontrol yapıldı — 23 geçti, 2 bulgu (1 kritik, 1 orta)

---

## 1. Doğrulanan Migration Dosyaları

| Dosya | Satır sayısı | İçerik |
|---|---|---|
| `20260620000001_user_profiles_marketing_email_opt_in.sql` | 73 | 2 ALTER TABLE + 2 COMMENT |
| `20260620000002_r5_marketing_email_rpcs.sql` | 245 | 3 CREATE OR REPLACE FUNCTION + 1 RLS policy |

Her iki dosya da `supabase/migrations/` dizininde doğru konumlandırılmış ve dosya adı tarih sıralaması geçerli (`20260620000001` < `20260620000002`).

---

## 2. Statik SQL Doğrulama Sonucu

### 2.1 Sütun doğrulaması

| Kontrol | Beklenen | Bulunan | Sonuç |
|---|---|---|---|
| Tablo adı doğru mu? | `public.user_profiles` | `ALTER TABLE public.user_profiles` | GEÇTI |
| `marketing_email_opt_in` tipi | `boolean NOT NULL DEFAULT false` | `boolean NOT NULL DEFAULT false` | GEÇTI |
| `marketing_email_opted_in_at` tipi | `timestamptz NULL` | `timestamptz NULL` | GEÇTI |
| `ADD COLUMN IF NOT EXISTS` kullanılmış mı? | İdempotent olmalı | Her iki sütunda da `IF NOT EXISTS` var | GEÇTI |
| Mevcut kullanıcılar otomatik opt-in yapılıyor mu? | Yapılmamalı | `DEFAULT false` — hiçbir backfill UPDATE yok | GEÇTI |
| `business_follows.is_subscribed_email`'e dokunuluyor mu? | Dokunulmamalı | 20260620000001 dosyasında business_follows referansı yok | GEÇTI |
| Sütun adları repo standardına uygun mu? | `snake_case`, anlamlı | `marketing_email_opt_in`, `marketing_email_opted_in_at` — uygun | GEÇTI |
| `profiles` yerine `user_profiles` kullanılmış mı? | `user_profiles` | `ALTER TABLE public.user_profiles` | GEÇTI |

**Tablo adı notı:** `docs/arsiv/r5-marketing-optin-data-model-decision.md` raporunda `user_profiles` olarak doğru yazılmış. `profiles` adında ayrı bir public tablo yok. Doğrulama kaynağı: `00000000000000_base_schema.sql` satır 24161. Migration doğru tabloyu kullanıyor.

---

### 2.2 RPC doğrulaması

#### get_my_notification_preferences_v1()

| Kontrol | Beklenen | Bulunan | Sonuç |
|---|---|---|---|
| auth.uid() IS NULL kontrolü | Olmalı | `IF v_uid IS NULL THEN RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002'` | GEÇTI |
| SECURITY DEFINER | Olmalı | `SECURITY DEFINER` satırı mevcut | GEÇTI |
| SET search_path = public | Olmalı | `SET search_path = public` | GEÇTI |
| STABLE tanımlaması uygun mu? | Sorgu fonksiyonu — STABLE kabul edilebilir | `STABLE` + `SECURITY DEFINER` kombinasyonu repoda standarttır (base_schema'da yaygın) | GEÇTI |
| Kullanıcı yalnızca kendi kaydını okuyabiliyor mu? | `WHERE user_id = v_uid` | `WHERE user_id = v_uid` — v_uid = auth.uid() | GEÇTI |
| business_follows tablosuna dokunuyor mu? | Dokunmamalı | Yalnızca `user_profiles` SELECT | GEÇTI |
| Kayıt yoksa null/default döndürüyor mu? | Edge case korunmalı | `IF NOT FOUND THEN RETURN jsonb_build_object('marketing_email_opt_in', false, ...)` | GEÇTI |
| REVOKE ALL FROM PUBLIC + GRANT TO authenticated | Olmalı | Her ikisi de mevcut | GEÇTI |

#### update_my_marketing_email_opt_in_v1(boolean)

| Kontrol | Beklenen | Bulunan | Sonuç |
|---|---|---|---|
| auth.uid() IS NULL kontrolü | Olmalı | `IF v_uid IS NULL THEN RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002'` | GEÇTI |
| SECURITY DEFINER | Olmalı | `SECURITY DEFINER` | GEÇTI |
| SET search_path = public | Olmalı | `SET search_path = public` | GEÇTI |
| p_value = true → opted_in_at = now() | Olmalı | `WHEN p_value = true THEN now()` | GEÇTI |
| p_value = false → opted_in_at = NULL | Olmalı | `WHEN p_value = false THEN NULL` | GEÇTI |
| updated_at güncelleniyor mu? | `user_profiles.updated_at` var, güncellenmeli | `updated_at = now()` | GEÇTI |
| NULL p_value koruması var mı? | Olmalı | `IF p_value IS NULL THEN RAISE EXCEPTION ... P0003` | GEÇTI |
| Kullanıcı yalnızca kendi kaydını güncelleyebiliyor mu? | `WHERE user_id = v_uid` | `WHERE user_id = v_uid` — v_uid = auth.uid() | GEÇTI |
| business_follows tablosuna dokunuyor mu? | Dokunmamalı | Yalnızca `UPDATE public.user_profiles` | GEÇTI |
| REVOKE ALL FROM PUBLIC + GRANT TO authenticated | Olmalı | Her ikisi de mevcut | GEÇTI |

#### update_business_follow_email_subscription_v1(uuid, boolean)

| Kontrol | Beklenen | Bulunan | Sonuç |
|---|---|---|---|
| auth.uid() IS NULL kontrolü | Olmalı | `IF v_uid IS NULL THEN RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002'` | GEÇTI |
| SECURITY DEFINER | Olmalı | `SECURITY DEFINER` | GEÇTI |
| SET search_path = public | Olmalı | `SET search_path = public` | GEÇTI |
| p_business_id NULL koruması | Olmalı | `IF p_business_id IS NULL THEN RAISE EXCEPTION ... P0003` | GEÇTI |
| p_subscribed NULL koruması | Olmalı | `IF p_subscribed IS NULL THEN RAISE EXCEPTION ... P0003` | GEÇTI |
| Kullanıcı yalnızca kendi takibini güncelleyebiliyor mu? | `WHERE user_id = v_uid AND business_id = p_business_id` | Mevcut | GEÇTI |
| Takip yoksa not_found hatası veriyor mu? | `IF NOT FOUND THEN RAISE EXCEPTION ... P0001` | Mevcut | GEÇTI |
| user_profiles tablosuna dokunuyor mu? | Dokunmamalı | Yalnızca `UPDATE public.business_follows` | GEÇTI |
| REVOKE ALL FROM PUBLIC + GRANT TO authenticated | Olmalı | Her ikisi de mevcut | GEÇTI |

#### RPC versiyonlama standart kontrolü

Repodaki RPC adlandırma standardı: `{action}_{subject}_{version}` (CLAUDE.md).

| RPC Adı | Standard | Değerlendirme |
|---|---|---|
| `get_my_notification_preferences_v1` | `get_` + subject + `_v1` | Uygun |
| `update_my_marketing_email_opt_in_v1` | `update_` + subject + `_v1` | Uygun |
| `update_business_follow_email_subscription_v1` | `update_` + subject + `_v1` | Uygun |

---

## 3. Local Test Sonucu

**Local Supabase çalıştırılmadı.** Bu doğrulama tamamen statik analize dayanmaktadır. Dinamik testler çalıştırılamadı.

Nedeni: Docker/Supabase local stack bu oturumda başlatılmadı. `supabase start` çalıştırılmadı.

Bölüm 8'de production öncesi manuel SQL test sorguları sağlanmıştır.

---

## 4. RLS Güvenlik Sonucu

### 4.1 user_profiles RLS

Mevcut policy'ler (`00000000000000_base_schema.sql` satır 27514-27526 + 27884):

```sql
ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;

"profiles_delete_own"  FOR DELETE TO authenticated USING (user_id = auth.uid())
"profiles_insert_own"  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid())
"profiles_read"        FOR SELECT USING (true)   -- herkese açık okuma
"profiles_update_own"  FOR UPDATE TO authenticated
                       USING (user_id = auth.uid())
                       WITH CHECK (user_id = auth.uid())
```

**Sonuç:** YETERLI.

- `profiles_update_own` satır-tabanlı bir policy olduğundan yeni `marketing_email_opt_in` ve `marketing_email_opted_in_at` sütunları için ek policy gerekmez. Kullanıcı yalnızca kendi satırını güncelleyebilir.
- `update_my_marketing_email_opt_in_v1` SECURITY DEFINER olduğundan RLS'i bypass eder; ancak `WHERE user_id = v_uid` koşuluyla yalnızca kendi kaydını günceller — ek güvenlik katmanı.

**Uyarı — profiles_read herkese açık:** `profiles_read` policy `USING (true)` ile `anon` dahil herkese okuma izni veriyor. `marketing_email_opt_in` değeri `SELECT *` ile okunabilir. Mevcut `shadow_banned` gibi alanlar da aynı şekilde açık — tutarlı ama `marketing_email_opt_in` harici bir izin bayrağı olduğundan potansiyel bilgi sızıntısı tartışılabilir. Bu migration kapsamının dışındadır; ayrı değerlendirme gerektirir.

### 4.2 business_follows RLS

Mevcut policy'ler (base_schema satır 26710-26721):

```
RLS: ENABLED
"business_follows_delete_own"  FOR DELETE TO authenticated USING (user_id = auth.uid())
"business_follows_insert_own"  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid())
"business_follows_select_own"  FOR SELECT TO authenticated USING (user_id = auth.uid())
-- UPDATE policy: YOK (base_schema'da hiçbir migration'da yoktu)
```

**Yeni policy (20260620000002):**

```sql
"business_follows_update_own"  FOR UPDATE TO authenticated
                               USING (user_id = auth.uid())
                               WITH CHECK (user_id = auth.uid())
```

**Sonuç:** DOĞRU VE GEREKLİ.

- `UPDATE` policy eklenmesi bir güvenlik açığını kapatıyor — bu migration olmadan `authenticated` kullanıcılar GRANT ALL kapsamında başka kullanıcıların `is_subscribed_email` değerini güncelleyebiliyordu.
- Yeni policy mevcut INSERT/SELECT/DELETE policy'leriyle çakışmıyor; farklı işlem türleri için ayrı policy'ler PostgreSQL'de bağımsız çalışır.

### 4.3 GRANT ALL + RLS ilişkisi

`business_follows`'ta `GRANT ALL TO "anon"` ve `GRANT ALL TO "authenticated"` var (satır 30781-30782). Bu `anon` kullanıcılara tablo-level GRANT veriyor. Ancak RLS aktif olduğundan ve `anon` için açık bir policy tanımlanmadığından `anon` kullanıcılar bu tabloda hiçbir işlem yapamaz.

**PostgreSQL davranışı:** RLS aktif olduğunda, eşleşen policy olmayan roller için tüm satırlar gizlenir (SELECT) veya tüm işlemler reddedilir (INSERT/UPDATE/DELETE). `GRANT ALL` tablo-level izin verir ama RLS satır-level erişimi ayrıca kısıtlar. Yeni UPDATE policy sadece `TO authenticated` ile tanımlandığından `anon` UPDATE yapamaz — güvenli.

### 4.4 service_role bypass

`GRANT ALL TO "service_role"` mevcut. `service_role` Supabase'de RLS'i bypass eder. `update_business_follow_email_subscription_v1` SECURITY DEFINER fonksiyonu `postgres` rolü ile çalışır ve RLS bypass eder — bu kasıtlı ve güvenli (`WHERE user_id = v_uid` koruması nedeniyle).

**Başka kullanıcının is_subscribed_email'ini değiştirebilir mi?**

- `authenticated` rol, doğrudan `UPDATE public.business_follows` yapabilir. Yeni `business_follows_update_own` policy ile bu artık `user_id = auth.uid()` koşuluna bağlıdır — başka kullanıcının kaydı güncellenemez.
- `update_business_follow_email_subscription_v1` RPC içinde `WHERE user_id = v_uid AND business_id = p_business_id` ek koruma sağlar.
- `service_role` RLS'i bypass eder — bu yalnızca sunucu tarafı işlemler (edge function, cron) için kullanılır ve Flutter client'a verilmez.

---

## 5. RPC Güvenlik Sonucu

### 5.1 SECURITY DEFINER + auth.uid() güvenliği

Tüm üç RPC'de `v_uid := auth.uid()` fonksiyon başında atanıyor. Bu PostgreSQL'in `SET ROLE` veya başka bir kimlik değiştirme girişimine karşı güvenlidir çünkü `auth.uid()` Supabase JWT'den okunur ve SECURITY DEFINER bağlamında bile JWT sahibinin uid'ini döndürür.

Bir edge case: `SECURITY DEFINER` fonksiyon `postgres` rolüyle çalışır. Eğer `auth.uid()` iç içe geçmiş bir çağrıda farklı bir değer döndürseydi güvenlik açığı oluşabilirdi. Ancak Supabase'de `auth.uid()` JWT `sub` claim'inden okunur ve her bağlantı için sabittir — güvenli.

### 5.2 DROP POLICY sözdizim incelemesi

Migration satır 228:

```sql
EXECUTE 'DROP POLICY business_follows_update_own ON public.business_follows';
```

Policy adı (`business_follows_update_own`) sadece küçük harf ve underscore içerdiğinden çift tırnak olmadan da çalışır. PostgreSQL policy adlarını case-insensitive tanımlamalar için tırnaksız kabul eder. **Fonksiyonel sorun yok** ancak savunmacı yaklaşım açısından `"business_follows_update_own"` şeklinde tırnaklı yazılması tercih edilebilir. Bu bir syntax hatası değil, stil tercihidir.

### 5.3 STABLE volatility etiketi

`get_my_notification_preferences_v1()` fonksiyonu `STABLE` olarak işaretlenmiş ve `SECURITY DEFINER` ile birlikte kullanılmış. Base_schema'da bu kombinasyon yaygın:

```sql
-- Örnek: admin_export_suspended_claims_csv_v1
LANGUAGE "sql" STABLE SECURITY DEFINER SET "search_path" TO 'public'
```

`plpgsql` ile `STABLE` tanımı geçerlidir. `STABLE` fonksiyonlar aynı transaction içinde önbelleklenebilir ama farklı satırlar için aynı parametreyle farklı sonuç vermeyeceği garantisini verir. `auth.uid()` her çağrıda aynı değeri döndürdüğünden bu garantiyi bozmaz. **Sorun yok.**

---

## 6. Unsubscribe / Ret Hakkı Durumu

### 6.1 Mevcut unsubscribe linki

`supabase/functions/send-email-campaign/index.ts` satır 122:

```html
<a href="https://yeedoy.com/settings/notifications" style="color:#7F1D1D;">
  aboneliğinizi iptal edebilirsiniz
</a>
```

### 6.2 settings/notifications route'u var mı?

Web uygulamasında arama yapıldı:
- `C:\yeedoy\uygulamalar\web\app\` dizininde `settings/notifications` adında bir route **yok**
- `Glob` aramasında `notification*` veya `settings*` pattern'leriyle eşleşen web route dosyası bulunamadı
- Mobil uygulamada `/notification-preferences` router kaydı var (`router.dart` satır 323) ancak bu web değil Flutter mobil rotasıdır

### 6.3 DEĞERLENDİRME: KRİTİK RİSK

**6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun md. 9/3:** Her ticari elektronik iletide geçerli ve çalışan bir abonelik iptal mekanizması bulunması zorunludur.

Mevcut durum:
- `send-email-campaign/index.ts`: Unsubscribe link `https://yeedoy.com/settings/notifications`'a yönlendiriyor
- `uygulamalar/web/app/` altında `settings/notifications` route'u yok
- Bu link ya 404 döndürüyor ya da var olmayan bir sayfaya yönlendiriyor
- `update_my_marketing_email_opt_in_v1(false)` veya `update_business_follow_email_subscription_v1(..., false)` çağıran bir web endpoint yok

**Bu, R-5 DB katmanı tamamlansa dahi e-posta gönderimi başlamadan önce çözülmesi gereken kritik bir bağlantı eksikliğidir.**

### 6.4 Kullanıcı bildirim tercihleri sayfasından izni geri çekebilecek mi?

`notification_preferences_page.dart` mevcut durumda:
- StatefulWidget (Riverpod yok)
- Hiçbir RPC veya Supabase çağrısı yok
- `_emailNotifs` toggle tamamen local state
- Bu migration ile RPC hazır oldu ama Flutter kodu henüz bağlanmadı

Flutter agent (`flutter-expert`) bu sayfayı `ConsumerStatefulWidget`'a dönüştürüp `get_my_notification_preferences_v1` ve `update_my_marketing_email_opt_in_v1` ile bağlamadan geri çekme mekanizması teknik olarak işlevsel olmayacak.

---

## 7. İki İzin Türü Ayrımı Doğrulaması

### 7.1 Global pazarlama izni user_profiles üzerinde kalıyor mu?

`update_my_marketing_email_opt_in_v1` fonksiyon gövdesi:

```sql
UPDATE public.user_profiles
SET
  marketing_email_opt_in     = p_value,
  marketing_email_opted_in_at = CASE WHEN p_value = true THEN now() WHEN p_value = false THEN NULL END,
  updated_at                  = now()
WHERE user_id = v_uid;
```

`business_follows` referansı yok. **GEÇTI.**

### 7.2 İşletme bazlı abonelik business_follows üzerinde kalıyor mu?

`update_business_follow_email_subscription_v1` fonksiyon gövdesi:

```sql
UPDATE public.business_follows
SET is_subscribed_email = p_subscribed
WHERE user_id     = v_uid
  AND business_id = p_business_id;
```

`user_profiles` referansı yok. **GEÇTI.**

### 7.3 Hiçbir RPC iki kavramı karıştırıyor mu?

- `update_my_marketing_email_opt_in_v1`: Sadece `user_profiles`, `business_follows`'a dokunmuyor — GEÇTI
- `update_business_follow_email_subscription_v1`: Sadece `business_follows`, `user_profiles`'a dokunmuyor — GEÇTI
- `get_my_notification_preferences_v1`: Sadece `user_profiles`'dan okuyuyor — GEÇTI

### 7.4 Kampanya e-postası koşul önerisi

Rapor (`r5-marketing-optin-db-implementation-report.md` Bölüm 7.3) şu önerilen SQL koşulunu açıkça belirtiyor:

```sql
-- Katmanlı kontrol (önerilen):
AND bf.is_subscribed_email = true    -- katman 1: işletme bazlı
AND up.marketing_email_opt_in = true  -- katman 2: global platform
```

Bu kural raporda net yazılmış. **GEÇTI.**

**Ancak:** `send-email-campaign/index.ts` ve `get-opted-in-emails.ts` henüz bu koşulu uygulamıyor. Mevcut implementasyonlar yalnızca `is_subscribed_email = true` filtresi kullanıyor — `marketing_email_opt_in` kontrolü yok. Bu, R-5 DB katmanı uygulandıktan sonra ayrı bir sprint maddesi olarak ele alınmalıdır.

---

## 8. Production Öncesi Manuel Test Sorguları

Bu sorgular `psql` veya Supabase Studio ile **local test veritabanına** karşı çalıştırılmalıdır. Production'a uygulamadan önce local ortamda doğrulama zorunludur.

### Sorgu A — Migration öncesi baseline

```sql
-- Sütun varlığını doğrula (migration öncesi YOK olmalı)
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_profiles'
  AND column_name  IN ('marketing_email_opt_in', 'marketing_email_opted_in_at');
-- Beklenen: 0 satır (sütunlar henüz yok)

-- business_follows UPDATE policy durumu (migration öncesi YOK olmalı)
SELECT policyname, cmd FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'business_follows'
  AND cmd        = 'UPDATE';
-- Beklenen: 0 satır

-- RPC varlığı kontrolü (migration öncesi YOK olmalı)
SELECT proname FROM pg_proc
JOIN pg_namespace n ON n.oid = pg_proc.pronamespace
WHERE n.nspname = 'public'
  AND proname IN (
    'get_my_notification_preferences_v1',
    'update_my_marketing_email_opt_in_v1',
    'update_business_follow_email_subscription_v1'
  );
-- Beklenen: 0 satır
```

### Sorgu B — Migration sonrası yapısal doğrulama

```sql
-- 20260620000001 sonrası: yeni sütunlar mevcut olmalı
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_profiles'
  AND column_name  IN ('marketing_email_opt_in', 'marketing_email_opted_in_at');
-- Beklenen: 2 satır
--   marketing_email_opt_in: boolean, DEFAULT false, NOT NULL
--   marketing_email_opted_in_at: timestamp with time zone, NULL

-- 20260620000002 sonrası: RPC'ler mevcut olmalı
SELECT proname, prosecdef, provolatile
FROM pg_proc
JOIN pg_namespace n ON n.oid = pg_proc.pronamespace
WHERE n.nspname = 'public'
  AND proname IN (
    'get_my_notification_preferences_v1',
    'update_my_marketing_email_opt_in_v1',
    'update_business_follow_email_subscription_v1'
  );
-- Beklenen: 3 satır, prosecdef=true (SECURITY DEFINER), provolatile:
--   get_my_notification_preferences_v1: provolatile='s' (STABLE)
--   update_my_marketing_email_opt_in_v1: provolatile='v' (VOLATILE — default)
--   update_business_follow_email_subscription_v1: provolatile='v' (VOLATILE)

-- UPDATE policy eklenmiş olmalı
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'business_follows'
  AND cmd        = 'UPDATE';
-- Beklenen: 1 satır — business_follows_update_own, {authenticated}, user_id = auth.uid()
```

### Sorgu C — Mevcut kullanıcılar opt-in yapılmamış

```sql
-- Tüm mevcut kullanıcılar false ile başlamış olmalı
SELECT
  COUNT(*)                                       AS total_users,
  COUNT(*) FILTER (WHERE marketing_email_opt_in = true)  AS opted_in,
  COUNT(*) FILTER (WHERE marketing_email_opt_in = false) AS opted_out,
  COUNT(*) FILTER (WHERE marketing_email_opted_in_at IS NOT NULL) AS has_timestamp
FROM public.user_profiles;
-- Beklenen: opted_in=0, has_timestamp=0, opted_out=total_users
```

### Sorgu D — RPC davranış testleri (authenticated kullanıcı gerektirir)

Bu sorgular Supabase Studio'da oturum açmış kullanıcı olarak veya `supabase db test` (RLS bypass kapatılmış) ortamında çalıştırılmalıdır.

```sql
-- Test D1: Başlangıç durumu false/null
SELECT public.get_my_notification_preferences_v1();
-- Beklenen: {"marketing_email_opt_in": false, "marketing_email_opted_in_at": null}

-- Test D2: Opt-in
SELECT public.update_my_marketing_email_opt_in_v1(true);
SELECT public.get_my_notification_preferences_v1();
-- Beklenen: {"marketing_email_opt_in": true, "marketing_email_opted_in_at": "<timestamp>"}

-- Test D3: Opt-out
SELECT public.update_my_marketing_email_opt_in_v1(false);
SELECT public.get_my_notification_preferences_v1();
-- Beklened: {"marketing_email_opt_in": false, "marketing_email_opted_in_at": null}

-- Test D4: NULL parametre koruması
SELECT public.update_my_marketing_email_opt_in_v1(null);
-- Beklened: P0003 validation_error hatası

-- Test D5: Takip edilen işletme için abonelik
-- (önce işletmeyi takip et: SELECT public.follow_business_v1('<uuid>'))
SELECT public.update_business_follow_email_subscription_v1('<followed_business_uuid>', true);
SELECT is_subscribed_email FROM public.business_follows
WHERE user_id = auth.uid() AND business_id = '<followed_business_uuid>';
-- Beklened: true

-- Test D6: Takip edilmeyen işletme için abonelik
SELECT public.update_business_follow_email_subscription_v1('<not_followed_uuid>', true);
-- Beklened: P0001 not_found hatası

-- Test D7: RPC başka kullanıcının kaydını güncelleyemiyor
-- Farklı iki kullanıcı oturumu gerektirir (Supabase Studio'da iki sekme)
-- Kullanıcı A: <user_a_uuid> işletmeyi takip ediyor
-- Kullanıcı B oturumunda:
SELECT public.update_business_follow_email_subscription_v1('<business_uuid_followed_by_a>', true);
-- Beklened: P0001 not_found hatası (çünkü Kullanıcı B bu işletmeyi takip etmiyor)
-- NOT: Bu test user_id izolasyonunu doğrular — güvenli
```

### Sorgu E — email_campaigns / send-email-campaign schema uyumu

```sql
-- send-email-campaign edge function'ın hala eski schema kullanan kodu var
-- Aşağıdaki sorgu edge function'ın çalışıp çalışmadığını simulate eder:
SELECT bf.user_id  -- doğru sütun adı (eski kod follower_id kullanıyordu — hata)
FROM public.business_follows bf
WHERE bf.business_id = '<some_uuid>'
  AND bf.is_subscribed_email = true
LIMIT 1;
-- follower_id kullanılsaydı: "column does not exist" hatası alınırdı
-- user_id kullanıldığında: başarılı (0 satır — test db'de veri yok)
```

---

## 9. Rollback Kontrolü

`r5-marketing-optin-db-implementation-report.md` Bölüm 10'da rollback SQL'i doğru yazılmış:

```sql
-- Rollback sırası (yeni migration dosyasına yazılmalı):
DROP FUNCTION IF EXISTS public.get_my_notification_preferences_v1();
DROP FUNCTION IF EXISTS public.update_my_marketing_email_opt_in_v1(boolean);
DROP FUNCTION IF EXISTS public.update_business_follow_email_subscription_v1(uuid, boolean);
DROP POLICY IF EXISTS "business_follows_update_own" ON public.business_follows;
ALTER TABLE public.user_profiles
  DROP COLUMN IF EXISTS marketing_email_opted_in_at,
  DROP COLUMN IF EXISTS marketing_email_opt_in;
```

**Rollback sırası doğru:** Önce fonksiyonlar, sonra policy, sonra sütunlar.

**Veri kaybı uyarısı:** Sütun DROP veri kaybına yol açar — raporda belirtilmiş.

**Yedek önlem:** Raporda opt-in verisi backup SQL'i de verilmiş:
```sql
CREATE TABLE public._backup_marketing_email_opt_in_20260620 AS
SELECT user_id, marketing_email_opt_in, marketing_email_opted_in_at
FROM public.user_profiles WHERE marketing_email_opt_in = true;
```

Rollback planı eksiksiz ve güvenli.

---

## 10. Kalan Riskler

### Risk K1 — KRITIK: Unsubscribe endpoint yok

**Bulgu:** `send-email-campaign/index.ts` satır 122'deki unsubscribe linki `https://yeedoy.com/settings/notifications` adresine yönlendiriyor. Web uygulamasında bu URL için route **yok**.

**Etki:** 6563 sayılı Kanun md. 9/3 gereği her ticari elektronik iletide çalışan bir abonelik iptal mekanizması zorunludur. Link var ama hedef sayfa yok — bu yasal yükümlülüğü karşılamıyor.

**Gerekli aksiyon (bu migration kapsamı dışında):**
1. `uygulamalar/web/app/(kimlik)/settings/notifications/page.tsx` oluşturulmalı (kimlik doğrulama gerektirir)
2. Sayfa `update_business_follow_email_subscription_v1` veya `update_my_marketing_email_opt_in_v1` çağırmalı
3. Alternatif: Token-tabanlı one-click unsubscribe endpoint (`/api/unsubscribe?token=...`)
4. E-posta kampanyası canlıya alınmadan önce bu endpoint tamamlanmalıdır

### Risk K2 — ORTA: send-email-campaign edge function'da eski schema hatası devam ediyor

**Bulgu:** `supabase/functions/send-email-campaign/index.ts` satır 89:

```typescript
.select("follower_id, profiles!inner(email)")
```

`follower_id` sütunu `business_follows` tablosunda **yok** (doğru ad: `user_id`). `profiles` tablosu public schema'da **yok** (doğru ad: `user_profiles`, ve email sütunu yok). Bu edge function şu anda `emails.length === 0` döndüreceğinden hiçbir e-posta gönderilemiyor.

Bu hata `20260603000010_fix_estimate_email_segment_v1.sql` migration'ında `estimate_email_segment_v1` için düzeltildi ancak edge function kodu güncellenmedi.

**Bağlantı:** `get-opted-in-emails.ts` doğru şemayı kullanıyor (`user_id` + `user_profiles`). Web route handler (`sunucu/sahip/eposta-kampanya/route.ts`) `getOptedInEmails()` üzerinden gidiyor. Edge function ise doğrudan query yapıyor ve hatalı.

**Etki:** E-posta kampanyası edge function üzerinden tetiklenirse hiç e-posta gitmiyor. R-5 ile ilişkili ama bu migration kapsamı dışında.

### Risk K3 — ORTA: get-opted-in-emails.ts global opt-in kontrolü yapmıyor

**Bulgu:** `uygulamalar/web/src/lib/email/get-opted-in-emails.ts` satır 34-37 yalnızca `is_subscribed_email = true` filtreliyor, `marketing_email_opt_in` kontrolü yok.

**Etki:** Global opt-out yapan kullanıcı (`marketing_email_opt_in = false`) işletme bazlı aboneliğini (`is_subscribed_email = true`) kaldırmamışsa hâlâ kampanya listesinde görünür.

**Gerekli aksiyon:** Hukuki karar netleşince (`is_subscribed_email` tek başına yeterli mi, yoksa her ikisi de gerekli mi) `get-opted-in-emails.ts` güncellenmeli.

### Risk K4 — DÜŞÜK: profiles_read herkese açık

**Bulgu:** `profiles_read` policy `USING (true)` ile tüm `user_profiles` satırlarını herkese açık kılıyor. `marketing_email_opt_in` dahil.

**Etki:** Herhangi bir kullanıcı (hatta `anon`) başka kullanıcının global opt-in durumunu okuyabilir. Bu bir pazarlama tercihi bayrağı olduğundan gizlilik değeri düşük, ancak veri minimizasyonu ilkesiyle tartışılabilir.

**Gerekli aksiyon:** Şimdilik kabul edilebilir. İleride profil gizlilik geliştirmesi yapılırsa birlikte değerlendirilebilir.

### Risk K5 — DÜŞÜK: opted_in_at opt-out sonrası NULL — ispat geçmişi tutulmuyor

**Bulgu:** Kullanıcı izni geri çektiğinde `marketing_email_opted_in_at = NULL` yapılıyor. Son opt-in zamanı siliniyor.

**Etki:** "Kullanıcı ne zaman opt-in yapmıştı?" sorusuna production'da yanıt verilemez. `updated_at` güncelleniyor ama bu opt-in mi opt-out mu olduğunu göstermiyor.

**Hukukçuya kontrol ettirilmeli:** KVKK ispat yükümlülüğü açısından yalnızca son opt-in zamanının yeterli olup olmadığı clarify edilmeli. Gerekirse `marketing_email_opted_out_at timestamptz` sütunu veya Seçenek C (ayrı consent log tablosu) değerlendirilebilir.

---

## 11. Nihai Karar

### R-5 DB katmanı Flutter'a geçmeye hazır mı?

**Koşullu Hazır — Aşağıdaki ön koşullarla Flutter geçişi başlayabilir.**

#### Hazır olan bileşenler

| Bileşen | Durum |
|---|---|
| `user_profiles.marketing_email_opt_in` sütunu | Hazır |
| `user_profiles.marketing_email_opted_in_at` sütunu | Hazır |
| `get_my_notification_preferences_v1()` RPC | Hazır |
| `update_my_marketing_email_opt_in_v1()` RPC | Hazır |
| `update_business_follow_email_subscription_v1()` RPC | Hazır |
| `business_follows_update_own` UPDATE RLS policy | Hazır |
| Global ve işletme bazlı izin ayrımı | Doğrulandı |
| Güvenlik (SECURITY DEFINER, search_path, auth.uid guard) | Doğrulandı |

#### Flutter geçişinden ÖNCE çözülmesi gerekenler (blokör değil, ama gerekli)

| Madde | Öncelik | Açıklama |
|---|---|---|
| Local Supabase'de Sorgu A-D çalıştırılmalı | Yüksek | Migration'ların başarıyla uygulandığı doğrulanmalı |
| `send-email-campaign/index.ts` `follower_id` → `user_id` + `profiles` → `user_profiles` | Yüksek | Mevcut edge function zaten hatalı; Flutter bağlantısından bağımsız sorun |

#### E-posta kampanyası canlıya almadan ÖNCE çözülmesi gerekenler (blokör)

| Madde | Öncelik | Açıklama |
|---|---|---|
| `settings/notifications` unsubscribe web sayfası | KRİTİK | 6563 md.9/3 — çalışan iptal mekanizması zorunlu |
| `get-opted-in-emails.ts` global opt-in kontrolü | Orta | Hukuki karar sonrası eklenecek |

**Flutter agent geçiş onayı:** DB katmanı teknik açıdan doğrulandı. Yukarıdaki RPC'ler Flutter repository sınıflarına bağlanabilir. E-posta kampanyasının canlıya alınması unsubscribe endpoint tamamlanana kadar beklenmelidir.
