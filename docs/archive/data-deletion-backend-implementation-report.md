# Veri Silme Backend Uygulama Raporu

Tarih: 2026-06-19
Kapsam: privacy_requests.request_type CHECK constraint genişletmesi, submit_privacy_request_v1 ve submit_account_deletion_request_v1 RPC oluşturulması
Yöntem: Migration dosyaları ve Flutter kaynak kodu statik analiz ile incelendi; production'a bağlanılmadı.
Bu rapor hukuki metin değildir.

---

## 1. Yapılan Değişiklik Özeti

| # | Değişiklik | Dosya |
|---|---|---|
| 1 | privacy_requests.request_type CHECK constraint genişletildi (5 yeni değer eklendi) | `20260620000003_fix_privacy_request_type_and_rpcs.sql` |
| 2 | `submit_privacy_request_v1(p_request_type, p_details)` RPC oluşturuldu | aynı migration |
| 3 | `submit_account_deletion_request_v1(p_reason)` RPC oluşturuldu | aynı migration |
| 4 | RLS policy analizi yapıldı — ek policy gerekmedi, mevcut yeterli | belgeleme |

Hiçbir Flutter dosyasına, Web/Next.js dosyasına, Edge Function'a, pazarlama RPC'sine veya `ip_address`/`user_agent` alanlarına dokunulmadı.

---

## 2. Oluşturulan Migration Dosyası

`C:\yeedoy\supabase\migrations\20260620000003_fix_privacy_request_type_and_rpcs.sql`

Mevcut son migration `20260620000002_r5_marketing_email_rpcs.sql` olduğundan sıradaki geçerli timestamp `20260620000003` seçildi.

---

## 3. privacy_requests Tablo Analizi

### Kolon yapısı (base schema)

| Kolon | Tip | Kısıt |
|---|---|---|
| id | uuid | PK, DEFAULT gen_random_uuid() |
| user_id | uuid | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| request_type | text | NOT NULL, CHECK constraint |
| status | text | NOT NULL, DEFAULT 'submitted', CHECK constraint |
| details | text | NOT NULL, DEFAULT '' |
| submitted_at | timestamptz | NOT NULL, DEFAULT now() |
| resolved_at | timestamptz | NULL |
| created_at | timestamptz | NOT NULL, DEFAULT now() |

### ip_address / user_agent sütunu var mı?

**YOK.** `privacy_requests` tablosunda `ip_address` veya `user_agent` sütunu mevcut değil. Base schema ve tüm migration dosyaları incelendi. R-4 kararı doğru: bu tablo bu alanları hiçbir zaman içermedi.

### Mevcut request_type CHECK constraint (base schema)

```
'data_export', 'privacy_application', 'access', 'rectification',
'erasure', 'restriction', 'objection', 'portability'
```

### Tespit edilen sorun

Flutter `data_deletion_page.dart` satır 73:
```dart
await ref.read(legalRepositoryProvider).submitPrivacyRequest(
  requestType: 'delete_data',
  details: details,
);
```

`'delete_data'` değeri CHECK constraint listesinde YOK. Bu değer gönderildiğinde PostgreSQL `check_violation` hatası (SQLSTATE 23514) verir. Tüm veri silme talepleri runtime'da başarısız olmaktadır.

### status CHECK constraint değerleri

```
'submitted', 'in_review', 'resolved', 'rejected', 'cancelled'
```

Bu değerler sorunsuz; değiştirilmedi.

### Mevcut index'ler

- `privacy_requests_one_open_per_user_idx` — UNIQUE ON (user_id) WHERE status IN ('submitted','in_review')
- `privacy_requests_user_id_status_idx` — ON (user_id, status, submitted_at DESC)

Her iki index de korundu; yeni migration index değiştirmiyor.

---

## 4. account_deletion_requests Tablo Analizi

### Kolon yapısı (base schema)

| Kolon | Tip | Kısıt |
|---|---|---|
| id | uuid | PK, DEFAULT gen_random_uuid() |
| user_id | uuid | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| reason | text | NOT NULL, DEFAULT '' |
| status | text | NOT NULL, DEFAULT 'requested', CHECK constraint |
| requested_at | timestamptz | NOT NULL, DEFAULT now() |
| completed_at | timestamptz | NULL |
| created_at | timestamptz | NOT NULL, DEFAULT now() |

### ip_address / user_agent sütunu var mı?

**YOK.** `account_deletion_requests` tablosunda da bu sütunlar mevcut değil. R-4 QA raporu doğrulandı.

### status CHECK constraint değerleri

```
'requested', 'in_review', 'completed', 'rejected', 'cancelled'
```

Değiştirilmedi.

### Mevcut index'ler

- `account_deletion_requests_one_open_per_user_idx` — UNIQUE ON (user_id) WHERE status IN ('requested','in_review')
- `account_deletion_requests_user_id_status_idx` — ON (user_id, status, requested_at DESC)

`one_open_per_user_idx` unique index zaten duplicate koruması sağlıyor. RPC içinde önceden kontrol yapılarak daha açıklayıcı hata mesajı üretiliyor; unique constraint son savunma katmanı olarak kalmaya devam ediyor.

---

## 5. request_type CHECK Constraint Değişikliği (Eski → Yeni)

### Eski değerler (8 adet)

```
data_export, privacy_application, access, rectification,
erasure, restriction, objection, portability
```

### Yeni değerler (13 adet — 8 eski + 5 yeni)

```
data_export, privacy_application, access, rectification,
erasure, restriction, objection, portability,
delete_data, delete_interactions, delete_support,
delete_owner_claims, other
```

### Eklenen değerlerin gerekçesi

| Değer | Gerekçe |
|---|---|
| `delete_data` | Flutter UI mevcut kullanımı; `data_deletion_page.dart` satır 73. Tüm veri silme talepleri bu değerle gönderiliyor. |
| `delete_interactions` | `veri-silme-talebi.md` Bölüm 4/7: "Yorum, favori veya check-in verilerimle ilgili talep" |
| `delete_support` | `veri-silme-talebi.md` Bölüm 4/7: "Destek talebi geçmişimle ilgili talep" |
| `delete_owner_claims` | `veri-silme-talebi.md` Bölüm 4/7: "İşletme sahipliği başvurumla ilgili talep" |
| `other` | `veri-silme-talebi.md` Bölüm 4/7: "Diğer" |

### Uygulama yöntemi

```sql
ALTER TABLE public.privacy_requests
  DROP CONSTRAINT IF EXISTS privacy_requests_request_type_check;

ALTER TABLE public.privacy_requests
  ADD CONSTRAINT privacy_requests_request_type_check
  CHECK (request_type = ANY (ARRAY[...]));
```

`DROP CONSTRAINT IF EXISTS` kullanıldı: constraint yoksa hata vermez. Mevcut kayıtlar (constraint hatası nedeniyle hiç yazılamadığından pratik olarak boş) korunur.

---

## 6. Oluşturulan RPC'ler

### 6.1 submit_privacy_request_v1

**İmza:**
```sql
CREATE OR REPLACE FUNCTION public.submit_privacy_request_v1(
  p_request_type text,
  p_details      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Mantık:**
1. `auth.uid() IS NULL` → `RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002'`
2. `p_request_type` izin verilen listede değilse → `RAISE EXCEPTION 'validation_error' USING ERRCODE = 'P0003'`
3. Açık (submitted/in_review) talep varsa → `RAISE EXCEPTION 'validation_error' USING ERRCODE = 'P0003'`
4. `privacy_requests`'e INSERT: `user_id=auth.uid()`, `status='submitted'`, `submitted_at=now()`

**GRANT:**
```sql
REVOKE ALL ON FUNCTION public.submit_privacy_request_v1(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_privacy_request_v1(text, text) TO authenticated;
```

### 6.2 submit_account_deletion_request_v1

**İmza:**
```sql
CREATE OR REPLACE FUNCTION public.submit_account_deletion_request_v1(
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Mantık:**
1. `auth.uid() IS NULL` → `RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002'`
2. Açık (requested/in_review) talep varsa → `RAISE EXCEPTION 'validation_error' USING ERRCODE = 'P0003'`
3. `account_deletion_requests`'e INSERT: `user_id=auth.uid()`, `status='requested'`, `requested_at=now()`

**GRANT:**
```sql
REVOKE ALL ON FUNCTION public.submit_account_deletion_request_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_account_deletion_request_v1(text) TO authenticated;
```

---

## 7. RLS ve Güvenlik Değerlendirmesi

### privacy_requests

| Policy | Tip | Durum |
|---|---|---|
| RLS ENABLE | — | Aktif |
| `privacy_requests_insert_own` | INSERT | `WITH CHECK (user_id = auth.uid())` — yeterli |
| `privacy_requests_select_own` | SELECT | `USING (is_admin() OR user_id = auth.uid())` — yeterli |

UPDATE ve DELETE policy mevcut değil — bu kasıtlı. Kullanıcı kendi talebini güncelleyemiyor veya silemez; yalnızca admin güncelleyebilir.

### account_deletion_requests

| Policy | Tip | Durum |
|---|---|---|
| RLS ENABLE | — | Aktif |
| `account_deletion_requests_insert_own` | INSERT | `WITH CHECK (user_id = auth.uid())` — yeterli |
| `account_deletion_requests_select_own` | SELECT | `USING (is_admin() OR user_id = auth.uid())` — yeterli |

### Çift koruma katmanı

RPC'ler `SECURITY DEFINER` olduğundan çalışırken RLS bypass edilir. Ancak:
- RPC içinde `auth.uid()` manuel kontrolü her iki RPC'de zorunlu tutulmuş.
- Kullanıcı RPC kullanmadan doğrudan `privacy_requests` INSERT yaparsa RLS devreye girer.
- `one_open_per_user_idx` unique index son mekanik bariyer olarak çalışır.

### Ek policy gereksinimi

Yok. Mevcut RLS yapısı bu migration'ın kapsamı için yeterli.

---

## 8. UI Seçeneği → Tablo / RPC / request_type Karar Tablosu

| UI seçeneği | Tablo | Çağrılacak RPC | Gönderilecek parametre |
|---|---|---|---|
| Hesabımı silme talebi | `account_deletion_requests` | `submit_account_deletion_request_v1` | `reason: description` |
| Tüm kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi | `privacy_requests` | `submit_privacy_request_v1` | `request_type: 'erasure', details: description` |
| Yorum, favori veya check-in verilerimle ilgili talep | `privacy_requests` | `submit_privacy_request_v1` | `request_type: 'delete_interactions', details: description` |
| Destek talebi geçmişimle ilgili talep | `privacy_requests` | `submit_privacy_request_v1` | `request_type: 'delete_support', details: description` |
| İşletme sahipliği başvurumla ilgili talep | `privacy_requests` | `submit_privacy_request_v1` | `request_type: 'delete_owner_claims', details: description` |
| Pazarlama e-postası iznini kapatmak istiyorum | Tablo yok | `update_my_marketing_email_opt_in_v1(false)` | — (yönlendirme: /notification-preferences) |
| Diğer | `privacy_requests` | `submit_privacy_request_v1` | `request_type: 'other', details: description` |

**Not:** "Hesabımı silme talebi" seçeneği mevcut kodda `submitPrivacyRequest(requestType: 'delete_data')` ile privacy_requests tablosuna yazılıyor. Bu değer artık constraint'ten geçecek; ancak doğru tablo `account_deletion_requests`'tir. Flutter tarafında `_submit()` metoduna neden bazlı dallanma eklenmesi gerekmektedir (Flutter sonraki adım bölümüne bakın).

---

## 9. Flutter Sonraki Adım Talimatı

Bu migration uygulandıktan sonra Flutter `data_deletion_page.dart` dosyasındaki `_submit()` metodu aşağıdaki şemaya göre güncellenmelidir.

### Mevcut durum (sorunlu)

```dart
// Her seçenek için aynı RPC çağrısı — yanlış
await ref.read(legalRepositoryProvider).submitPrivacyRequest(
  requestType: 'delete_data',  // tek sabit değer — yanlış
  details: details,
);
```

### Hedef durum (neden bazlı dallanma)

```dart
Future<void> _submit() async {
  // ... doğrulama ...

  // Pazarlama: form gönderilmez, yönlendirilir (mevcut — dokunma)
  if (_isMarketingSelected) {
    context.push('/notification-preferences');
    return;
  }

  // Hesap silme: ayrı tablo ve RPC
  if (_reason == 'Hesabımı silme talebi') {
    await ref.read(legalRepositoryProvider).submitAccountDeletionRequest(
      reason: details,
    );
    return;
  }

  // Diğer seçenekler: privacy_requests tablosu
  final requestType = _reasonToRequestType(_reason);
  await ref.read(legalRepositoryProvider).submitPrivacyRequest(
    requestType: requestType,
    details: details,
  );
}

String _reasonToRequestType(String? reason) {
  return switch (reason) {
    'Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi'
        => 'erasure',
    'Yorum, favori veya check-in verilerimle ilgili talep'
        => 'delete_interactions',
    'Destek talebi geçmişimle ilgili talep'
        => 'delete_support',
    'İşletme sahipliği başvurumla ilgili talep'
        => 'delete_owner_claims',
    _ => 'other',
  };
}
```

### LegalRepository — RPC uyumu

`LegalRepository.submitPrivacyRequest()` ve `submitAccountDeletionRequest()` mevcut metodları doğrudan tabloya INSERT yapıyor. Bu metodlar opsiyonel olarak RPC çağrısına güncellenebilir; ancak RLS ve constraint düzeltmesinden sonra mevcut doğrudan INSERT da çalışacaktır. RPC katmanının tutarlılığı için tercihen RPC çağrısına geçiş önerilir:

```dart
// Tercih edilen: RPC üzerinden
await _supabase.rpc('submit_privacy_request_v1', params: {
  'p_request_type': requestType,
  'p_details': details.trim(),
});

await _supabase.rpc('submit_account_deletion_request_v1', params: {
  'p_reason': reason.trim(),
});
```

---

## 10. Doğrulama SQL'leri

Aşağıdaki sorgular local veya staging veritabanında elle çalıştırılarak migration sonrası doğrulama yapılabilir. Production'da çalıştırılmamalıdır.

### 1. privacy_requests.request_type CHECK constraint güncel değerleri

```sql
SELECT
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
  JOIN pg_class rel ON rel.oid = con.conrelid
  JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'public'
  AND rel.relname = 'privacy_requests'
  AND con.contype = 'c'
  AND con.conname = 'privacy_requests_request_type_check';
```

Beklenen sonuç: ARRAY listesinde 13 değer — orijinal 8 + delete_data, delete_interactions, delete_support, delete_owner_claims, other.

### 2. submit_privacy_request_v1 ile 'erasure' türünde talep oluşturuluyor mu?

```sql
-- authenticated kullanıcı bağlamında çalıştırın
SELECT public.submit_privacy_request_v1('erasure', 'Test talebi — doğrulama');

-- Sonucu kontrol et
SELECT id, user_id, request_type, status, submitted_at
FROM public.privacy_requests
WHERE request_type = 'erasure'
ORDER BY submitted_at DESC
LIMIT 1;
```

Beklenen: satır INSERT edilmiş, status = 'submitted'.

### 3. submit_privacy_request_v1 geçersiz request_type reddediyor mu?

```sql
-- Bu çağrı P0003 validation_error döndürmeli
SELECT public.submit_privacy_request_v1('gecersiz_tur', 'test');
-- HATA: validation_error: Geçersiz talep türü: gecersiz_tur bekleniyor
```

### 4. submit_account_deletion_request_v1 account_deletion_requests'e yazıyor mu?

```sql
-- authenticated kullanıcı bağlamında çalıştırın
SELECT public.submit_account_deletion_request_v1('Test hesap silme talebi');

SELECT id, user_id, reason, status, requested_at
FROM public.account_deletion_requests
ORDER BY requested_at DESC
LIMIT 1;
```

Beklenen: satır INSERT edilmiş, status = 'requested'.

### 5. privacy_requests'te ip_address sütunu yok mu?

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'privacy_requests'
  AND column_name IN ('ip_address', 'user_agent');
```

Beklenen: 0 satır.

### 6. account_deletion_requests'te ip_address sütunu yok mu?

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'account_deletion_requests'
  AND column_name IN ('ip_address', 'user_agent');
```

Beklenen: 0 satır.

### 7. RLS: kullanıcı başka kullanıcının talebini göremez mi?

```sql
-- Kullanıcı A bağlamında giriş yapın (set_config ile auth context simüle et):
SELECT set_config('request.jwt.claims',
  '{"sub":"USER_A_UUID","role":"authenticated"}', true);

-- Kullanıcı A yalnızca kendi kayıtlarını görmeli
SELECT COUNT(*) FROM public.privacy_requests;  -- Yalnızca A'nın kayıtları

-- Kullanıcı B'nin talebini doğrudan INSERT etmeye çalış (RLS'in reddetmesi bekleniyor)
INSERT INTO public.privacy_requests (user_id, request_type, details)
VALUES ('USER_B_UUID'::uuid, 'other', 'test');
-- HATA: new row violates row-level security policy bekleniyor
```

### 8. Duplicate açık talep engeli çalışıyor mu?

```sql
-- İkinci kez aynı kullanıcıdan çağır (ilk talep submitted/in_review durumundayken)
SELECT public.submit_privacy_request_v1('other', 'ikinci talep');
-- HATA: validation_error: Bu kullanıcı için zaten açık bir gizlilik talebi mevcut bekleniyor
```

---

## 11. Kalan Riskler

| Risk | Öncelik | Açıklama |
|---|---|---|
| Flutter `_submit()` neden dallanması eksik | Kritik | "Hesabımı silme talebi" hâlâ `submitPrivacyRequest('delete_data')` çağrıyor; `submitAccountDeletionRequest` çağrılmıyor. Migration sonrası constraint hata vermez ama yanlış tabloya yazılır. Flutter değişikliği gerekiyor. |
| LegalRepository doğrudan INSERT yapıyor | Yüksek | RPC yerine tablo INSERT yapılıyor. Constraint düzelmesiyle çalışır; RPC'ye geçiş mimari tutarlılık için önerilir. |
| `one_open_per_user_idx` unique conflict | Orta | Flutter `_ensureNoOpenRequest()` ile önceden kontrol yapıyor; RPC içinde de kontrol var; index son bariyer. Eş zamanlı çift INSERT edge case'i DB'de hata verir — Flutter bunu `exception` olarak yakalar, sorun değil. |
| `privacy_requests_one_open_per_user_idx` tek tip talep kısıtı | Orta | Bu index TÜM request_type değerleri için tek açık talep kabul ediyor. Farklı kategorilerde aynı anda talep açılamaz. Bu davranış mevcut şemada kasıtlı görünüyor; değiştirilmedi. |
| Hukuki metin placeholder'ları | Yüksek | Tüm legal belgeler `[PLACEHOLDER]` içeriyor; hukukçu onayı bekliyor. Backend bu raporu engellemez. |
| Talep durumu kullanıcıya gösterilmiyor | Orta | `veri-silme-talebi.md` Bölüm 15: statüs UI'a yansıtılmalı. Bu rapor kapsamı dışında. |

---

## 12. Production Öncesi Kontrol Listesi

- [ ] `20260620000003_fix_privacy_request_type_and_rpcs.sql` local/staging'de test edilmeli.
- [ ] Doğrulama SQL'leri (Bölüm 10) staging'de el ile çalıştırılmalı; tüm beklenen sonuçlar doğrulanmalı.
- [ ] Flutter `_submit()` neden dallanması eklenmeli (Bölüm 9 şemasına göre).
- [ ] `flutter analyze` sıfır yeni hata ile geçmeli.
- [ ] Migration 1, 2 ve 3 birlikte `supabase db reset` ile lokal test edilmeli (20260619000001 → 20260620000001 → 20260620000002 → 20260620000003 sırası).
- [ ] Authenticated kullanıcıyla `submit_privacy_request_v1('erasure', ...)` çağrısı DB'de doğrulanmalı.
- [ ] Authenticated kullanıcıyla `submit_account_deletion_request_v1(...)` çağrısı DB'de doğrulanmalı.
- [ ] Geçersiz `request_type` ile çağrı P0003 döndürdüğü doğrulanmalı.
- [ ] Duplicate talep girişimi P0003 döndürdüğü doğrulanmalı.
- [ ] RLS: farklı kullanıcı taleplerinin SELECT/INSERT sızıntısı olmadığı iki kullanıcıyla test edilmeli.
- [ ] Production'a geçiş için önceki migration bloklayıcıları (`20260619000001`, `20260620000001`, `20260620000002`) uygulanmış ve test edilmiş olmalı.
- [ ] `UNSUBSCRIBE_HMAC_SECRET` ve `SITE_URL` production'da tanımlı olmalı (R-5 bağımlılığı).
- [ ] Hukuki metin placeholder'ları kapatılmadan veri silme talep ekranı canlıya alınmamalı.

---

*Bu rapor hukuki metin değildir. Tüm legal belgeler hukukçu onayına tabidir.*
