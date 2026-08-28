# R-4 IP Metadata Migration — Doğrulama Raporu

**Hazırlanma tarihi:** 2026-06-19  
**Hazırlayan:** postgres-pro  
**Doğrulanan migration:** `supabase/migrations/20260619000001_remove_ip_metadata_from_policy_acceptances.sql`  
**Referans karar:** `docs/arsiv/r4-ip-metadata-decision-plan.md` — Seçenek B  
**Doğrulama yöntemi:** Statik SQL analizi (local Supabase Docker mevcut değil — dinamik test yapılamadı)  
**Durum:** Statik doğrulama TAMAM. Dinamik testler production öncesinde local ortamda çalıştırılmalıdır.

---

## 1. Doğrulanan Migration Dosyası

**Dosya:** `supabase/migrations/20260619000001_remove_ip_metadata_from_policy_acceptances.sql`  
**Boyut:** 176 satır  
**Oluşturulma tarihi:** 2026-06-19  
**Önceki migration:** `20260616000001_get_smart_recommendations_v1.sql`  
**Kronolojik sıra:** Doğru — Haziran 2026 serisi içinde son migration olarak yerleşiyor.

Migration üç yürütme bloğundan oluşmaktadır:

| Blok | Tür | Hedef | Açıklama |
|---|---|---|---|
| Bölüm 1 | DDL — `CREATE OR REPLACE FUNCTION` | `public.capture_request_metadata_v1()` | IP/UA doldurma bloğu çıkarıldı |
| Bölüm 2 | DML — `UPDATE` | `public.user_policy_acceptances` | Mevcut ip_address, user_agent → NULL |
| Bölüm 3 | DML — `UPDATE` | `public.business_policy_acceptances` | Mevcut ip_address, user_agent → NULL |

---

## 2. Statik SQL Doğrulama Sonucu

### 2.1 Fonksiyon İmzası Kontrolü

**Soru:** `CREATE OR REPLACE FUNCTION public.capture_request_metadata_v1()` fonksiyon imzasını koruyor mu?

**Kaynak (20260414000010 — mevcut):**
```sql
create or replace function public.capture_request_metadata_v1()
returns trigger
language plpgsql
set search_path to 'public'
```

**Migration (20260619000001 — yeni):**
```sql
CREATE OR REPLACE FUNCTION public.capture_request_metadata_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
```

**Fark analizi:**

| Özellik | Mevcut | Migration | Durum |
|---|---|---|---|
| Fonksiyon adı | `capture_request_metadata_v1` | `capture_request_metadata_v1` | Aynı |
| Parametre listesi | `()` (boş) | `()` (boş) | Aynı |
| Dönüş tipi | `trigger` | `trigger` | Aynı |
| Dil | `plpgsql` | `plpgsql` | Aynı |
| `SECURITY DEFINER` | Base schema'da VARDΙ; 20260414 dosyasında YOK | Var | Yeniden eklendi |
| `SET search_path` | `'public'` | `'public'` | Aynı |

**Kritik gözlem — SECURITY DEFINER:** `20260414000010_fix_capture_request_metadata_trigger.sql` dosyasındaki `CREATE OR REPLACE` satırında `SECURITY DEFINER` eksikti. Ancak `00000000000000_base_schema.sql` (remote schema snapshot) ve `_archive/20260326000001_legal_compliance_foundation.sql` (orijinal tanım) incelendiğinde fonksiyon her zaman `SECURITY DEFINER` olarak tanımlanmıştır. `20260414000010` dosyasının bu niteliği atlayan bir yazım hatası içerdiği anlaşılmaktadır — yeni migration `SECURITY DEFINER`'ı geri koyarak orijinal amaca uygun duruma getirir. Bu, bir düzeltmedir.

**Sonuç: Fonksiyon imzası tamamen korunuyor. Trigger bağlantısı bozulmaz.**

### 2.2 Trigger Uyumluluğu Kontrolü

PostgreSQL'de `CREATE OR REPLACE FUNCTION` ile trigger fonksiyonu güncellendiğinde:
- Fonksiyon adı ve dönüş tipi (`trigger`) değişmediği sürece tüm mevcut trigger tanımları otomatik olarak yeni gövdeyi kullanır.
- Trigger'ların yeniden oluşturulmasına gerek yoktur.
- Migration'da `DROP TRIGGER` veya `CREATE TRIGGER` ifadesi yok — doğru yaklaşım.

**Etkilenen 4 trigger:**

| Trigger | Tablo | Önceki davranış | Yeni davranış |
|---|---|---|---|
| `trg_user_policy_acceptances_capture_request_metadata_v1` | `user_policy_acceptances` | `user_id` + `accepted_at` + `ip_address` + `user_agent` doldurur | `user_id` + `accepted_at` doldurur (IP/UA kaldırıldı) |
| `trg_business_policy_acceptances_capture_request_metadata_v1` | `business_policy_acceptances` | `accepted_at` + `ip_address` + `user_agent` doldurur | `accepted_at` doldurur (IP/UA kaldırıldı) |
| `trg_privacy_requests_capture_request_metadata_v1` | `privacy_requests` | `user_id` + `submitted_at` doldurur | Değişmez — IP/UA bu tabloda zaten yoktu |
| `trg_account_deletion_requests_capture_request_metadata_v1` | `account_deletion_requests` | `requested_at` doldurur | Değişmez — IP/UA bu tabloda zaten yoktu |

**Sonuç: Tüm trigger'lar kırılmadan çalışmaya devam eder.**

### 2.3 IP/UA Doldurma Kaldırıldı mı?

Eski fonksiyon gövdesinde (20260414000010) şu blok vardı:

```sql
if tg_table_name in ('user_policy_acceptances', 'business_policy_acceptances') then
  -- accepted_at ...
  if coalesce(to_jsonb(new)->>'user_agent', '') = '' then
    new := jsonb_populate_record(new,
      jsonb_build_object('user_agent', public.request_header_v1('user-agent')));
  end if;
  if coalesce(to_jsonb(new)->>'ip_address', '') = '' then
    new := jsonb_populate_record(new,
      jsonb_build_object('ip_address', public.request_ip_v1()));
  end if;
end if;
```

Yeni fonksiyon gövdesinde (20260619000001) bu tablolar için yalnızca şu kalıyor:

```sql
IF tg_table_name IN ('user_policy_acceptances', 'business_policy_acceptances') THEN
  IF coalesce(to_jsonb(NEW)->>'accepted_at', '') = '' THEN
    NEW := jsonb_populate_record(NEW, jsonb_build_object('accepted_at', now()));
  END IF;
END IF;
```

Migration metninde `request_header_v1`, `request_ip_v1`, `user_agent`, `ip_address` kelimelerinin hiçbiri **yürütülen SQL kodunda** geçmiyor (yalnızca yorum satırlarında ve ROLLBACK bloğunda geçiyor). Grep ile doğrulandı.

**Sonuç: IP/UA doldurma tamamen ve doğru biçimde kaldırıldı.**

### 2.4 Korunan Alanlar Kontrolü

**user_id doldurma:**

```sql
IF tg_table_name IN ('user_policy_acceptances', 'privacy_requests', 'account_deletion_requests')
   AND coalesce(to_jsonb(NEW)->>'user_id', '') = '' THEN
  NEW := jsonb_populate_record(NEW, jsonb_build_object('user_id', auth.uid()));
END IF;
```

Mevcut (20260414) ile aynı mantık — `business_policy_acceptances` bu listede değil. Bu doğrudur: `business_policy_acceptances`'ta `user_id` istemci tarafından sağlanmaktadır; trigger doldurmasına gerek yoktur ve base schema bunu teyit etmektedir (`user_id uuid NOT NULL` — default yok).

**accepted_at doldurma:** Her iki policy tablosu için korundu.

**submitted_at doldurma:** `privacy_requests` için korundu.

**requested_at doldurma:** `account_deletion_requests` için korundu.

**Sonuç: Tüm gerekli alanlar eksiksiz korunuyor.**

### 2.5 privacy_requests ve account_deletion_requests Etkileniyor mu?

Base schema (`00000000000000_base_schema.sql`) incelendi:

**privacy_requests sütunları:** `id`, `user_id`, `request_type`, `status`, `details`, `submitted_at`, `resolved_at`, `created_at` — `ip_address` ve `user_agent` yok.

**account_deletion_requests sütunları:** `id`, `user_id`, `reason`, `status`, `requested_at`, `completed_at`, `created_at` — `ip_address` ve `user_agent` yok.

Migration içinde bu iki tabloya ait herhangi bir `UPDATE` veya DDL ifadesi bulunmuyor.

**Sonuç: Bu iki tablo migration kapsamı dışında. Akışları değişmiyor.**

### 2.6 request_ip_v1() ve request_header_v1() Silinmemesi Doğru mu?

`insert_audit_log_v1()` fonksiyonu (`00000000000000_base_schema.sql` satır 11786) şu akışı izliyor:

```sql
select o_ip, o_user_agent
  into v_ip, v_user_agent
from public.capture_request_meta_v1();   -- farklı fonksiyon: capture_request_META_v1
```

`capture_request_meta_v1()` (meta, metadata değil) — ayrı bir fonksiyon, admin audit log için kullanılıyor. Bu fonksiyon doğrudan `current_setting('request.headers')` JSONB'sini okuyor ve `request_header_v1()` / `request_ip_v1()` kullanmıyor.

Bununla birlikte `request_ip_v1()` ve `request_header_v1()` şu bağımlılıkları taşımaktadır:
- `20260520000005_set_function_search_paths.sql` bu iki fonksiyon için `search_path` ayarlıyor (satır 27-28). Silinseydi bu migration hata verirdi.
- Potansiyel olarak başka edge function veya henüz incelenmemiş migration'larda referans alınıyor olabilirler.
- Sütunlar `DROP COLUMN` yapılmadığından `ip_address inet` tipi hâlâ tabloda var; gelecekte başka bir karar alınırsa bu fonksiyonlara ihtiyaç duyulabilir.

**Sonuç: Bu fonksiyonların korunması hem teknik olarak doğru hem de savunmacı bir kararır. Silinmemeleri onaylanmıştır.**

### 2.7 RLS Policy, Index, View, RPC Değişmedi mi?

Migration içinde şu anahtar kelimeler arandı — hiçbiri yok:

- `CREATE POLICY` / `DROP POLICY` / `ALTER POLICY` — Yok
- `CREATE INDEX` / `DROP INDEX` — Yok
- `CREATE VIEW` / `DROP VIEW` — Yok
- `CREATE OR REPLACE FUNCTION` — Yalnızca `capture_request_metadata_v1()` için, beklenen
- `DROP FUNCTION` — Yok
- `DROP COLUMN` / `ALTER TABLE` / `ADD COLUMN` — Yok
- `GRANT` / `REVOKE` — Yok

**Sonuç: RLS policy, index, view ve RPC'ler tamamen dokunulmamış durumda.**

### 2.8 UPDATE Koşullarının Doğruluğu

```sql
UPDATE public.user_policy_acceptances
SET ip_address = NULL, user_agent = NULL
WHERE ip_address IS NOT NULL OR user_agent IS NOT NULL;
```

- `ip_address inet null` ve `user_agent text null` olduğu base schema'da doğrulandı.
- `WHERE` koşulu `OR` operatörü ile her iki sütunun herhangi birinde değer olan satırları hedefliyor. Bu doğrudur: birinde NULL, diğerinde değer olan edge case'i de kapsıyor.
- `NOT NULL` kısıtı olmadığından UPDATE başarısız olmaz.
- `WHERE` koşulu sayesinde zaten NULL olan satırlarda gereksiz IO yapılmıyor.

**Sonuç: UPDATE ifadeleri hem semantik hem de performans açısından doğru.**

### 2.9 Syntax Geçerlilik Kontrolü

Migration PostgreSQL plpgsql standardına uygunluk açısından satır satır incelendi:

| Kontrol | Sonuç |
|---|---|
| `$$` dollar-quote açılış/kapanış eşleşmesi | Eşleşiyor (satır 63 açılış, satır 96 kapanış) |
| `BEGIN...END` blok yapısı | Tam ve doğru |
| `IF...END IF` blok yapısı | Her IF bloğu kapatılmış |
| `RETURN NEW` ifadesi | Var (satır 94) — trigger fonksiyonu için zorunlu |
| `COMMENT ON FUNCTION` söz dizimi | Geçerli — fonksiyon imzası `()` ile eşleşiyor |
| `UPDATE...SET...WHERE` söz dizimi | Geçerli standart SQL |
| Noktalı virgül sonlandırmaları | Her ifade düzgün sonlandırılmış |
| Yorum bloğu (rollback referansı) | `--` ile başlayan satırlar, SQL parser tarafından yok sayılır |

**Sonuç: Migration söz dizimi geçerli. PostgreSQL 14+ uyumlu.**

---

## 3. Local Test Sonucu

**Local Supabase durumu:** ÇALIŞMIYOR

Docker engine bağlantısı başarısız oldu:

```
failed to inspect container health: error during connect: in the default daemon
configuration on Windows, the docker client must be run with elevated privileges to connect
```

Docker servisi bu makinede çalışmıyor ya da yüklü değil. Local Supabase ortamı (`supabase start`) çalıştırılamadı.

**Dinamik testlerin tamamı çalıştırılamadı.** Bölüm 4'te çalıştırılamayan testler listelenmekte; Bölüm 6'da production öncesi elle çalıştırılacak kontrol sorguları bulunmaktadır.

---

## 4. Çalıştırılamayan Testler

Aşağıdaki testler local Supabase ortamı gerektirdiği için bu aşamada çalıştırılamadı:

| Test | Neden gerekli | Nasıl çalıştırılır |
|---|---|---|
| T1 — INSERT sonrası trigger davranışı | ip_address ve user_agent gerçekten NULL kalıyor mu doğrulamak için | `supabase start` → Bölüm 6 Test 1 |
| T2 — user_id ve accepted_at doldurma | Korunan alanların çalıştığını doğrulamak için | `supabase start` → Bölüm 6 Test 4 |
| T3 — business_policy_acceptances INSERT | B2B kabul akışının çalıştığını doğrulamak için | `supabase start` → Bölüm 6 Test 1 (business_policy_acceptances için) |
| T4 — privacy_requests INSERT | submitted_at ve user_id hâlâ dolduruluyor mu | `supabase start` → Bölüm 6 Test 5 |
| T5 — account_deletion_requests INSERT | requested_at hâlâ dolduruluyor mu | `supabase start` → Bölüm 6 Test 5 |
| T6 — Geçmiş veri temizliği | UPDATE'lerin uygulandığını sayısal olarak doğrulamak için | `supabase start` → Bölüm 6 Test 2 |
| T7 — admin_audit_log akışı | insert_audit_log_v1 → capture_request_meta_v1 zinciri çalışıyor mu | Admin işlemi tetikleyerek admin_audit_log kontrol et |
| T8 — SECURITY DEFINER onayı | Fonksiyonun pg_proc'da security_type = 'definer' olduğunu doğrulamak için | `supabase start` → pg_proc sorgusu |

---

## 5. Riskler

### Risk 1 — SECURITY DEFINER Tutarsızlığı (Düşük — Düzeltici)

**Bulgu:** `20260414000010_fix_capture_request_metadata_trigger.sql` (şu anda geçerli migration) `SECURITY DEFINER` niteliğini içermiyor. Orijinal tanım (`20260326000001`) ve base schema snapshot (`00000000000000`) ise `SECURITY DEFINER` içeriyor.

**Durum:** `20260414000010` dosyası `CREATE OR REPLACE` ile fonksiyonu güncelledi ve `SECURITY DEFINER`'ı yanlışlıkla düşürdüyse, production'daki mevcut fonksiyon şu anda `SECURITY INVOKER` (varsayılan) olarak çalışıyor olabilir. Bu durumda `auth.uid()` çağrısı `authenticated` rolünün yetki sınırlarına göre işliyor demektir.

**Yeni migration:** `SECURITY DEFINER`'ı yeniden ekliyor. Eğer production'da zaten `SECURITY DEFINER` çalışıyorsa değişiklik yok. Eğer `SECURITY INVOKER` çalışıyorsa güvenlik karakteristiklerini orijinal tasarıma geri döndürüyor.

**Değerlendirme:** Her iki durumda da yeni migration'ın etkisi doğru yönde. Risk düşük.

**Önerilen kontrol:** Production öncesi `SELECT proname, prosecdef FROM pg_proc WHERE proname = 'capture_request_metadata_v1'` sorgusu ile mevcut `prosecdef` değerini not alın.

### Risk 2 — UPDATE Geri Dönüşsüzlüğü (Beklenen — Kabul Edilebilir)

**Bulgu:** `UPDATE ... SET ip_address = NULL, user_agent = NULL` geri alınamaz. Migration uygulandıktan sonra NULL'lanan değerler kurtarılamaz.

**Değerlendirme:** Bu, R-4 Seçenek B kararının öngörülen ve istenen sonucudur. Backup alınmış bir ortamda rollback senaryosu ancak veri yedekleme (pg_dump) üzerinden mümkün olur.

**Önlem:** Migration uygulanmadan önce production'da şu baseline ölçümü alınmalıdır:

```sql
SELECT
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_dolu,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_dolu,
  count(*) AS toplam
FROM public.user_policy_acceptances;

SELECT
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_dolu,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_dolu,
  count(*) AS toplam
FROM public.business_policy_acceptances;
```

### Risk 3 — capture_request_metadata_v1 ile capture_request_meta_v1 Karışıklığı (Düşük — Belgelenmiş)

**Bulgu:** Projede benzer isimli iki fonksiyon var: `capture_request_metadata_v1()` (trigger, bu migration ile değiştirilen) ve `capture_request_meta_v1()` (admin audit log için, OUT parametreli farklı bir fonksiyon). Migration yalnızca `_metadata_v1` fonksiyonunu değiştiriyor.

**Değerlendirme:** Migration doğru fonksiyonu hedefliyor. `insert_audit_log_v1` → `capture_request_meta_v1()` zinciri etkilenmiyor.

### Risk 4 — Parallel INSERT Yarış Koşulu (Çok Düşük)

**Bulgu:** Migration'daki UPDATE işlemi çalışırken eş zamanlı bir INSERT gerçekleşirse, INSERT henüz yeni fonksiyon gövdesini görmüyor olabilir — bu PostgreSQL transaction izolasyon düzeyine göre farklılık gösterir.

**Değerlendirme:** `CREATE OR REPLACE FUNCTION` transaction içinde atomiktir. Migration transaction tamamlandıktan sonra tüm yeni INSERT'lar yeni gövdeyi kullanır. Policy acceptances tabloları yoğun concurrent yazma senaryosu değil; pratik risk minimumdur.

---

## 6. Production Öncesi Manuel Kontrol Sorguları

Bu sorgular migration **uygulanmadan önce** (baseline) ve **uygulandıktan sonra** (doğrulama) çalıştırılmalıdır. Tümü salt okunurdur; DDL veya DML içermez.

### Sorgu A — Migration öncesi baseline (uygulamadan önce çalıştırın)

```sql
-- Migration uygulanmadan önce mevcut IP/UA durumunu kaydedin.
-- Bu sayılar daha sonra temizleme başarısını doğrulamak için kullanılır.

SELECT
  'user_policy_acceptances' AS tablo,
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_dolu_kayit,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_dolu_kayit,
  count(*) AS toplam_kayit
FROM public.user_policy_acceptances
UNION ALL
SELECT
  'business_policy_acceptances',
  count(*) FILTER (WHERE ip_address IS NOT NULL),
  count(*) FILTER (WHERE user_agent IS NOT NULL),
  count(*)
FROM public.business_policy_acceptances;
```

### Sorgu B — Mevcut fonksiyon güvenlik türü (uygulamadan önce not alın)

```sql
-- SECURITY DEFINER mi INVOKER mi olduğunu kaydedin.
-- prosecdef = true → SECURITY DEFINER

SELECT
  proname,
  prosecdef AS security_definer,
  prosrc LIKE '%request_ip_v1%' AS ip_kodu_var,
  prosrc LIKE '%request_header_v1%' AS ua_kodu_var
FROM pg_proc
WHERE proname = 'capture_request_metadata_v1'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
```

### Sorgu C — Tablo sütun varlık kontrolü

```sql
-- ip_address ve user_agent sütunlarının hâlâ var olduğunu ve
-- nullable olduğunu doğrulayın (DROP COLUMN yapılmadı).

SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE
  table_schema = 'public'
  AND table_name IN ('user_policy_acceptances', 'business_policy_acceptances')
  AND column_name IN ('ip_address', 'user_agent', 'user_id', 'accepted_at')
ORDER BY table_name, column_name;

-- Beklenen: ip_address (inet, YES), user_agent (text, YES),
--           user_id (uuid, NO), accepted_at (timestamptz, NO) — her iki tablo için
```

### Sorgu D — privacy_requests ve account_deletion_requests sütun yokluğu

```sql
-- Bu tablolarda ip_address / user_agent hiç olmamalı.
-- Migration sonrası da olmamalı — bu teyit sorgusudur.

SELECT
  table_name,
  column_name
FROM information_schema.columns
WHERE
  table_schema = 'public'
  AND table_name IN ('privacy_requests', 'account_deletion_requests')
  AND column_name IN ('ip_address', 'user_agent');

-- Beklenen: 0 satır (bu sütunlar bu tablolarda hiç yoktu)
```

### Sorgu E — Migration sonrası geçmiş veri temizliği teyidi

```sql
-- Migration uygulandıktan sonra: dolu değer kalmamalı.
-- Sorgu A'daki ip_dolu_kayit ve ua_dolu_kayit değerleri artık 0 olmalı.

SELECT
  'user_policy_acceptances' AS tablo,
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_hala_dolu,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_hala_dolu,
  count(*) AS toplam_kayit
FROM public.user_policy_acceptances
UNION ALL
SELECT
  'business_policy_acceptances',
  count(*) FILTER (WHERE ip_address IS NOT NULL),
  count(*) FILTER (WHERE user_agent IS NOT NULL),
  count(*)
FROM public.business_policy_acceptances;

-- Beklenen: ip_hala_dolu = 0, ua_hala_dolu = 0 (her iki satırda)
```

### Sorgu F — Migration sonrası fonksiyon gövdesi doğrulama

```sql
-- Fonksiyon gövdesinde IP/UA kodu kalmamalı.

SELECT
  proname,
  prosecdef AS security_definer,
  prosrc LIKE '%request_ip_v1%' AS ip_kodu_var,
  prosrc LIKE '%request_header_v1%' AS ua_kodu_var,
  prosrc LIKE '%user_id%' AS userid_kodu_var,
  prosrc LIKE '%accepted_at%' AS acceptedat_kodu_var
FROM pg_proc
WHERE proname = 'capture_request_metadata_v1'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Beklenen: ip_kodu_var = false, ua_kodu_var = false,
--           userid_kodu_var = true, acceptedat_kodu_var = true,
--           security_definer = true
```

### Sorgu G — Trigger bağlantı sağlığı

```sql
-- 4 trigger hâlâ doğru fonksiyona bağlı olmalı.

SELECT
  t.tgname AS trigger_adi,
  c.relname AS tablo_adi,
  p.proname AS fonksiyon_adi,
  CASE t.tgtype & 2 WHEN 2 THEN 'BEFORE' ELSE 'AFTER' END AS zamanlama,
  CASE t.tgtype & 4 WHEN 4 THEN 'INSERT' ELSE 'OTHER' END AS olay
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_proc p ON p.oid = t.tgfoid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND p.proname = 'capture_request_metadata_v1'
ORDER BY c.relname;

-- Beklenen: 4 satır:
-- trg_account_deletion_requests_capture_request_metadata_v1 | account_deletion_requests | BEFORE INSERT
-- trg_business_policy_acceptances_capture_request_metadata_v1 | business_policy_acceptances | BEFORE INSERT
-- trg_privacy_requests_capture_request_metadata_v1 | privacy_requests | BEFORE INSERT
-- trg_user_policy_acceptances_capture_request_metadata_v1 | user_policy_acceptances | BEFORE INSERT
```

### Sorgu H — admin_audit_log akışı etkilenmedi mi?

```sql
-- insert_audit_log_v1 → capture_request_meta_v1() zinciri bağımsız çalışıyor.
-- Son 5 audit kaydında ip alanı dolu olmalı (admin işlemleri gerçekleştiyse).

SELECT
  action,
  target_table,
  ip IS NOT NULL AS ip_var,
  user_agent IS NOT NULL AS ua_var,
  created_at
FROM public.admin_audit_log
ORDER BY created_at DESC
LIMIT 5;

-- Beklenen: admin işlemi gerçekleştiyse ip_var = true
-- (capture_request_meta_v1 akışı bu migration ile değişmedi)
```

### Sorgu I — Local test: INSERT davranışı (yalnızca local/test ortamında)

```sql
-- UYARI: Bu sorguyu YALNIZCA local veya test ortamında çalıştırın.
-- Production'da çalıştırmayın — gerçek kullanıcı olarak kayıt oluşturur.

BEGIN;

WITH test_insert AS (
  INSERT INTO public.user_policy_acceptances
    (user_id, policy_version_id, accepted_at, source_app)
  SELECT
    auth.uid(),
    pv.id,
    now(),
    'mobile_flutter'
  FROM public.policy_versions pv
  WHERE pv.is_active = true
  LIMIT 1
  RETURNING id, ip_address, user_agent, accepted_at, user_id
)
SELECT
  id,
  ip_address IS NULL                  AS ip_null_beklenen_true,
  user_agent IS NULL                  AS ua_null_beklenen_true,
  accepted_at IS NOT NULL             AS accepted_at_dolu_beklenen_true,
  user_id IS NOT NULL                 AS user_id_dolu_beklenen_true
FROM test_insert;

ROLLBACK; -- Test kaydını geri al
```

---

## 7. Rollback Kontrolü

### Rollback mümkün mü?

Evet — sütunlar `DROP COLUMN` yapılmadığı için tam teknik rollback mümkündür.

### Rollback adımları

**Adım 1 — Fonksiyon gövdesini eski haline döndür:**  
Migration içindeki yorum bloğundaki `CREATE OR REPLACE FUNCTION` kodunu yeni bir migration dosyasına kopyalayarak çalıştırın. Fonksiyon imzası değişmediğinden trigger bağlantıları korunur.

**Adım 2 — Veri geri yükleme:**  
NULL'lanan IP/UA verileri geri kazanılamaz. Ancak yeni INSERT'lar rollback migration'ı çalıştırdıktan sonra tekrar IP/UA toplamaya başlar.

### Rollback kısıtları

- Migration uygulanmadan önce pg_dump ile backup alınmışsa geçmiş IP verisi geri yüklenebilir. Aksi durumda geri dönüş kısmi olur.
- Rollback kararı hukuki gerekçe ile alınmalıdır; teknik adım basittir.

### Rollback migration şablonu

Rollback gerekirse şu isimle yeni migration oluşturulur:  
`supabase/migrations/20260619000002_rollback_capture_request_metadata.sql`

İçeriği: Migration'ın ROLLBACK REFERANSI yorum bloğundaki `CREATE OR REPLACE FUNCTION` kodu.

---

## 8. Nihai Karar: R-4 Kapatılabilir mi?

### Statik doğrulama sonucu: ONAYLANDI

Tüm statik kontrol noktaları geçti:

| Kontrol | Sonuç |
|---|---|
| Fonksiyon imzası korunuyor | ONAYLANDI |
| Trigger bağlantıları bozulmuyor | ONAYLANDI |
| IP/UA doldurma kaldırıldı | ONAYLANDI |
| user_id, accepted_at korunuyor | ONAYLANDI |
| submitted_at, requested_at korunuyor | ONAYLANDI |
| privacy_requests etkilenmiyor | ONAYLANDI |
| account_deletion_requests etkilenmiyor | ONAYLANDI |
| request_ip_v1 / request_header_v1 korunuyor | ONAYLANDI |
| RLS policy değişmedi | ONAYLANDI |
| DROP COLUMN yok | ONAYLANDI |
| SQL syntax geçerli | ONAYLANDI |
| UPDATE koşulları doğru | ONAYLANDI |
| Kronolojik migration sırası doğru | ONAYLANDI |

### Nihai karar

**R-4 teknik açıdan kapatılabilir — aşağıdaki koşullar sağlandıktan sonra.**

Kalan adımlar (bloklayıcı):

1. Hukuk danışmanı "IP'siz kabul ispatı KVKK kapsamında yeterli mi?" sorusuna yazılı onay verdi.
2. Sorgu A (migration öncesi baseline) production'da çalıştırıldı ve sonuçlar kaydedildi.
3. Migration production'a uygulandı (`supabase db push` — bu göreve dahil değil, ayrıca onaylanacak).
4. Sorgu E ve F (migration sonrası doğrulama) production'da çalıştırıldı ve beklenen sonuçlar alındı.

Kalan adımlar (önerilen ama blokerlayıcı değil):

5. `docs/hukuki/legal-data-inventory.md` Bölüm 6 satır 6.6 güncellendi.
6. `docs/hukuki/legal-data-inventory.md` Bölüm 7 satır 7.3 güncellendi.
7. KVKK Aydınlatma Metni ve Gizlilik Politikası taslakları IP kaydının kaldırıldığını yansıtır biçimde güncellendi.

---

*Bu rapor `docs/arsiv/r4-ip-metadata-implementation-report.md` ve `docs/arsiv/r4-ip-metadata-decision-plan.md` ile birlikte okunmalıdır.*
