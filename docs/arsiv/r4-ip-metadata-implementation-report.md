# R-4 IP Metadata Kaldırma — Uygulama Raporu

**Hazırlanma tarihi:** 2026-06-19  
**Hazırlayan:** postgres-pro  
**Karar referansı:** `docs/arsiv/r4-ip-metadata-decision-plan.md` — Seçenek B  
**Durum:** Migration oluşturuldu. Production'a henüz uygulanmadı.

---

## 1. Yapılan Değişiklik Özeti

R-4 kararı doğrultusunda (`r4-ip-metadata-decision-plan.md` Bölüm 3 — Seçenek B):

- `capture_request_metadata_v1()` trigger fonksiyonunun IP/user-agent otomatik doldurma bloğu **kaldırıldı**. Kullanıcı kimliği ve zaman damgası doldurma mantığı korundu.
- `user_policy_acceptances` ve `business_policy_acceptances` tablolarındaki **mevcut kayıtlarda** `ip_address` ve `user_agent` sütunları NULL'a güncellendi.
- Sütunlar fiziksel olarak silinmedi (`DROP COLUMN` yapılmadı).
- `request_ip_v1()` ve `request_header_v1()` fonksiyonları silinmedi; `admin_audit_log` akışı bu fonksiyonları `capture_request_meta_v1()` üzerinden kullanmaya devam eder.

**Hukuki dayanak:** KVKK md. 4/2-ç (veri minimizasyonu) ve KVKK md. 10 (aydınlatma yükümlülüğü). IP adresi hiçbir RPC, view veya UI tarafından okunmayan "yazılıp hiç okunmayan" veri olarak doğrulandı.

---

## 2. Oluşturulan Migration Dosyası

**Dosya:** `supabase/migrations/20260619000001_remove_ip_metadata_from_policy_acceptances.sql`

### İçerik özeti

Migration üç bölümden oluşmaktadır:

**Bölüm 1 — Fonksiyon yeniden tanımı:**  
`capture_request_metadata_v1()` `CREATE OR REPLACE FUNCTION` ile yeniden yazıldı. Değişiklik:
- Kaldırılan blok: `user_agent` ve `ip_address` için `public.request_header_v1()` ve `public.request_ip_v1()` çağrıları
- Korunan bloklar: `user_id` doldurma (3 tablo), `accepted_at` doldurma (2 tablo), `submitted_at` doldurma (`privacy_requests`), `requested_at` doldurma (`account_deletion_requests`)

**Bölüm 2 — Geçmiş veri temizliği (user_policy_acceptances):**  
```sql
UPDATE public.user_policy_acceptances
SET ip_address = NULL, user_agent = NULL
WHERE ip_address IS NOT NULL OR user_agent IS NOT NULL;
```

**Bölüm 3 — Geçmiş veri temizliği (business_policy_acceptances):**  
```sql
UPDATE public.business_policy_acceptances
SET ip_address = NULL, user_agent = NULL
WHERE ip_address IS NOT NULL OR user_agent IS NOT NULL;
```

Migration sonunda rollback referansı yorum bloğu olarak korundu.

---

## 3. Değişen Tablolar

| Tablo | Değişiklik Türü | Detay |
|---|---|---|
| `user_policy_acceptances` | Veri güncellemesi | `ip_address`, `user_agent` → NULL |
| `business_policy_acceptances` | Veri güncellemesi | `ip_address`, `user_agent` → NULL |

Şema (DDL) değişikliği yoktur. Sütunlar, kısıtlar, index'ler ve RLS policy'ler olduğu gibi korunmaktadır.

---

## 4. Değişen Trigger / Fonksiyonlar

| Nesne | Değişiklik | Detay |
|---|---|---|
| `public.capture_request_metadata_v1()` | `CREATE OR REPLACE` ile yeniden tanımlandı | IP/UA doldurma bloğu çıkarıldı; diğer mantık korundu |
| `trg_user_policy_acceptances_capture_request_metadata_v1` | Değişmedi | Aynı fonksiyonu çağırmaya devam eder |
| `trg_business_policy_acceptances_capture_request_metadata_v1` | Değişmedi | Aynı fonksiyonu çağırmaya devam eder |
| `trg_privacy_requests_capture_request_metadata_v1` | Değişmedi | Zaten IP yazmıyordu; etkilenmez |
| `trg_account_deletion_requests_capture_request_metadata_v1` | Değişmedi | Zaten IP yazmıyordu; etkilenmez |

---

## 5. Dokunulmayan Tablolar

| Tablo | Gerekçe |
|---|---|
| `privacy_requests` | `ip_address` / `user_agent` sütunu hiç bulunmuyordu; doğrulandı |
| `account_deletion_requests` | `ip_address` / `user_agent` sütunu hiç bulunmuyordu; doğrulandı |
| `admin_audit_log` | `capture_request_meta_v1()` fonksiyonu üzerinden IP kaydeder; bu akış R-4 kapsamı dışında ve doğru şekilde çalışmaktadır |
| Diğer tüm tablolar | IP/UA sütunu bulunmuyor |

Silinen fonksiyon: Yok.  
Değiştirilen RLS: Yok.  
Değiştirilen Flutter kodu: Yok.

---

## 6. Eski Kayıtlar İçin Yapılan Veri Temizliği

Migration içindeki iki `UPDATE` ifadesi çalıştırıldığında:

- `user_policy_acceptances` tablosunda `ip_address IS NOT NULL OR user_agent IS NOT NULL` koşulunu sağlayan tüm satırlarda bu alanlar NULL'a çekilir.
- `business_policy_acceptances` tablosunda aynı işlem uygulanır.
- Temizlik **geri dönüşümsüzdür**: NULL'lanan IP verileri yeniden kurtarılamaz. Bu, kararın beklenen sonucudur.
- `WHERE` koşulu (`IS NOT NULL`) sayesinde boş satırlarda gereksiz UPDATE yapılmaz; performans etkisi minimumdur.

---

## 7. Riskler

| Risk | Açıklama | Değerlendirme |
|---|---|---|
| Fonksiyon gövdesi değişikliği | `CREATE OR REPLACE` idempotent değildir; migration iki kez çalıştırılırsa sonuç aynıdır | Düşük — PostgreSQL `CREATE OR REPLACE` güvenlidir |
| `accepted_at` doldurma hatası | IP/UA bloğu kaldırılırken `accepted_at` bloğu yanlışlıkla çıkarılmış olabilir | Migration tam incelendi; `accepted_at` bloğu korunmaktadır |
| `user_id` doldurma kırılması | `business_policy_acceptances` için `user_id` doldurma kontrolündeki tablo listesi | `business_policy_acceptances` bu listede değildi ve zaten orada `user_id` istemci tarafından gönderilir; mevcut davranış korundu |
| NULL güncelleme çakışması | Paralel transaction'larda MVCC çakışması teorik olarak mümkün | Düşük; policy acceptances nadiren eş zamanlı güncellenir; UPDATE koşulu güvenlidir |
| `admin_audit_log` kırılması | `request_ip_v1()` / `request_header_v1()` silinmemiş; `capture_request_meta_v1()` akışı bozulmamış | Sıfır risk — bu fonksiyonlara dokunulmadı |

---

## 8. Rollback Planı

Migration fiziksel şema değişikliği içermediğinden rollback iki adımdan oluşur:

**Adım 1 — Fonksiyonu eski haline döndür:**  
Yeni bir migration dosyası oluşturulur (örn. `20260619000002_rollback_capture_request_metadata.sql`). Migration içinde `r4-ip-metadata-decision-plan.md` Bölüm 4'teki veya bu dosyanın ROLLBACK REFERANSI yorum bloğundaki `CREATE OR REPLACE FUNCTION` kodu çalıştırılır.

**Adım 2 — Eski IP verilerini geri yükleme:**  
NULL'lanan IP/UA verileri geri kazanılamaz. Rollback kararı verilmeden önce bu geri dönüşsüzlük kabul edilmelidir. Yeni INSERT'lar rollback sonrasında tekrar IP toplamaya başlar.

**Önemli:** Rollback kararı hukuk danışmanı ile birlikte alınmalıdır; teknik rollback fonksiyon gövdesini eski haline getirir ancak veri minimizasyonu ihlali yeniden başlar.

---

## 9. Çalıştırılan Testler / Çalıştırılamayan Testler

### Statik doğrulama (çalıştırıldı)

Migration dosyası elle incelendi:

- `capture_request_metadata_v1()` yeni gövdesi: IP/UA bloğu yok, `user_id`/`accepted_at`/`submitted_at`/`requested_at` doldurma var — doğrulandı.
- `UPDATE WHERE ip_address IS NOT NULL OR user_agent IS NOT NULL` koşulu: `inet null` ve `text null` sütunlarda geçerli SQL — doğrulandı.
- `request_ip_v1()` ve `request_header_v1()` fonksiyonlarına dokunulmadığı: migration içinde bu isimlere referans yok — doğrulandı.
- `privacy_requests` ve `account_deletion_requests` tablolarına referans yok — doğrulandı.
- RLS policy değişikliği yok — doğrulandı.
- DROP COLUMN yok — doğrulandı.

### Dinamik testler (local Supabase çalışmadığı için çalıştırılamadı)

Aşağıdaki testler production'a uygulanmadan önce local Supabase ortamında (`supabase start` + `supabase db reset`) doğrulanmalıdır:

1. INSERT sonrası `ip_address IS NULL` ve `user_agent IS NULL` doğrulaması
2. INSERT sonrası `user_id` ve `accepted_at` hâlâ dolduğunun doğrulaması
3. Mevcut kayıtlarda NULL temizliğinin tamamlandığının doğrulaması
4. `admin_audit_log` akışının bozulmadığının doğrulaması

Doğrulama SQL'leri Bölüm 10'da yer almaktadır.

---

## 10. Production'a Uygulamadan Önce Kontrol Listesi

### Zorunlu (blokerlayıcı)

- [ ] Hukuk danışmanı Seçenek B kararını onayladı ("IP'siz kabul ispatı KVKK kapsamında yeterli mi?")
- [ ] Local Supabase ortamında `supabase start` + `supabase db reset` ile migration test edildi
- [ ] INSERT doğrulama SQL'leri (Bölüm 11) local'de çalıştırıldı ve beklenen sonuçlar alındı
- [ ] `admin_audit_log` insert testi yapıldı — IP hâlâ kaydediliyor (bu tabloya dokunulmadı, beklenen davranış korunmalı)
- [ ] Production'daki `user_policy_acceptances` ve `business_policy_acceptances` satır sayısı not edildi (güncelleme öncesi baseline)

### Tavsiye edilen

- [ ] `supabase migration list` ile migration sırası ve tarih uyumu doğrulandı
- [ ] Personel / panel tarafındaki `business_policy_acceptances` INSERT akışı test edildi (Karar B kapsamında IP gönderilmediğinden etkilenmemesi beklenir)
- [ ] `legal-data-inventory.md` Bölüm 6 satır 6.6 güncellendi ("IP kaldırıldı — R-4 Seçenek B uygulandı")
- [ ] `legal-data-inventory.md` Bölüm 7 satır 7.3 güncellendi ("capture_request_metadata_v1 artık policy tablolarına IP yazmıyor")

---

## 11. Doğrulama SQL'leri (Production'da veya Local'de Elle Çalıştırılacak)

Aşağıdaki sorgular production'da veya local'de **salt okunur** biçimde çalıştırılır. Hiçbir DDL veya DML içermez.

### Test 1 — INSERT sonrası IP/user_agent dolmuyor mu?

```sql
-- Test amaçlı sahte kabul kaydı insert ederek trigger davranışını kontrol et.
-- Bu sorguyu yalnızca local/test ortamında çalıştırın.
-- Beklenen: ip_address IS NULL, user_agent IS NULL

WITH inserted AS (
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
  ip_address IS NULL AS ip_is_null,
  user_agent IS NULL AS ua_is_null,
  accepted_at IS NOT NULL AS accepted_at_filled,
  user_id IS NOT NULL AS user_id_filled
FROM inserted;

-- Beklenen sonuç: ip_is_null = true, ua_is_null = true,
--                 accepted_at_filled = true, user_id_filled = true
```

### Test 2 — Mevcut kayıtlarda ip_address ve user_agent NULL mu?

```sql
-- Her iki tabloda da NULL olmayan değer kalmamalı

SELECT
  'user_policy_acceptances' AS tablo,
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_dolu_sayi,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_dolu_sayi,
  count(*) AS toplam_satir
FROM public.user_policy_acceptances

UNION ALL

SELECT
  'business_policy_acceptances' AS tablo,
  count(*) FILTER (WHERE ip_address IS NOT NULL) AS ip_dolu_sayi,
  count(*) FILTER (WHERE user_agent IS NOT NULL) AS ua_dolu_sayi,
  count(*) AS toplam_satir
FROM public.business_policy_acceptances;

-- Beklenen: ip_dolu_sayi = 0, ua_dolu_sayi = 0 (her iki satırda)
```

### Test 3 — privacy_requests ve account_deletion_requests etkilenmedi mi?

```sql
-- Bu tablolarda ip_address / user_agent sütunu hiç yoktu;
-- Migration sonrası da yokluğu korunuyor.

SELECT column_name, data_type
FROM information_schema.columns
WHERE
  table_schema = 'public'
  AND table_name IN ('privacy_requests', 'account_deletion_requests')
  AND column_name IN ('ip_address', 'user_agent')
ORDER BY table_name, column_name;

-- Beklenen: 0 satır döner (bu sütunlar bu tablolarda hiç yoktu)
```

### Test 4 — user_id ve accepted_at hâlâ doğru dolduruluyor mu?

```sql
-- Son 10 policy kabul kaydını kontrol et: user_id ve accepted_at dolu olmalı

SELECT
  id,
  user_id IS NOT NULL AS has_user_id,
  accepted_at IS NOT NULL AS has_accepted_at,
  ip_address IS NULL AS ip_null,
  user_agent IS NULL AS ua_null,
  accepted_at
FROM public.user_policy_acceptances
ORDER BY created_at DESC
LIMIT 10;

-- Beklenen: has_user_id = true, has_accepted_at = true,
--           ip_null = true, ua_null = true
```

### Test 5 — admin_audit_log triggeri hâlâ çalışıyor mu?

```sql
-- admin_audit_log tablosundaki son kayıtları kontrol et.
-- capture_request_meta_v1() bu tabloya ip / user_agent yazar;
-- bu akış bu migration tarafından etkilenmemiş olmalı.

SELECT
  id,
  action,
  target_table,
  ip IS NOT NULL AS ip_var,
  user_agent IS NOT NULL AS ua_var,
  created_at
FROM public.admin_audit_log
ORDER BY created_at DESC
LIMIT 5;

-- Beklenen: admin işlemleri için ip ve user_agent hâlâ dolu olabilir
-- (capture_request_meta_v1() akışı dokunulmadı; yalnızca capture_request_metadata_v1 değişti)
```

### Test 6 — capture_request_metadata_v1 gövdesi doğru mu?

```sql
-- Fonksiyon gövdesinde ip_address ve user_agent referansı kalmamalı

SELECT
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE
  routine_schema = 'public'
  AND routine_name = 'capture_request_metadata_v1';

-- Beklenen: routine_definition içinde 'ip_address' veya 'request_ip_v1'
--           veya 'user_agent' veya 'request_header_v1' geçmemeli
```

---

*Bu rapor `docs/arsiv/r4-ip-metadata-decision-plan.md` ve `docs/arsiv/critical-privacy-gaps-report.md` ile birlikte okunmalıdır. Migration production'a uygulanmadan önce hukuk danışmanı onayı alınmalıdır.*
