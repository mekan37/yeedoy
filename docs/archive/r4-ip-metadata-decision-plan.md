# R-4 — IP Metadata Sessiz Kaydı: Karar Planı ve Etki Analizi

**Hazırlayan:** Güvenlik Denetçisi  
**Tarih:** 2026-06-18  
**Kapsam:** `capture_request_metadata_v1()` trigger akışı ile IP/user-agent sessiz kaydı  
**Durum:** Kod tabanı doğrulamasına dayalı kesin bulgular. Kod değiştirilmedi, migration üretilmedi.

---

## 1. Mevcut IP Metadata Akışı

### Hangi tablolar IP adresi kaydediyor?

Şema doğrulamasıyla (`00000000000000_base_schema.sql`) yalnızca **iki tabloda** fiziksel `ip_address inet` ve `user_agent text` sütunu vardır:

| Tablo | `ip_address` sütunu | `user_agent` sütunu | Trigger IP/UA dolduruyor mu? |
|---|---|---|---|
| `user_policy_acceptances` | Var | Var | **Evet** |
| `business_policy_acceptances` | Var | Var | **Evet** |
| `privacy_requests` | **Yok** | **Yok** | Hayır (yalnızca `user_id` + `submitted_at`) |
| `account_deletion_requests` | **Yok** | **Yok** | Hayır (yalnızca `user_id` + `requested_at`) |

> **Düzeltme (önceki R-4 raporuna göre):** `privacy_requests` ve `account_deletion_requests` tablolarında IP/UA sütunu **bulunmamaktadır**. `critical-privacy-gaps-report.md` Bölüm 4.2'de bu iki tablonun "aynı işlevle IP kaydettiği" izlenimi doğru değildir. Trigger bu tablolar için yalnızca `user_id` ve zaman damgası doldurur — IP/UA bloğu sadece `('user_policy_acceptances','business_policy_acceptances')` koşulunda çalışır.

### Hangi trigger/fonksiyon ile kaydediliyor?

- **Fonksiyon:** `public.capture_request_metadata_v1()` — `BEFORE INSERT` trigger fonksiyonu, `SECURITY DEFINER`, `set search_path = public`
- **Mantık özeti** (`20260414000010_fix_capture_request_metadata_trigger.sql`):
  - `user_id` boşsa → `auth.uid()`
  - `accepted_at` boşsa → `now()` (yalnızca iki policy tablosu)
  - `user_agent` boşsa → `public.request_header_v1('user-agent')` (yalnızca iki policy tablosu)
  - `ip_address` boşsa → `public.request_ip_v1()` (yalnızca iki policy tablosu)
- **`request_ip_v1()`:** `x-forwarded-for` → yoksa `x-real-ip` HTTP başlığını okur, virgülle ayrılmış listenin ilk değerini `inet`'e cast eder, hata olursa `null` döner
- **`request_header_v1(p_name)`:** `current_setting('request.headers')` JSONB'sinden başlığı okur
- **Bağlanan trigger'lar** (4 adet, hepsi `BEFORE INSERT ... FOR EACH ROW`): Hepsi aynı fonksiyonu çağırır; ancak IP/UA yan etkisi sadece ilk iki tabloda gerçekleşir

### Hangi kullanıcı aksiyonunda tetikleniyor?

- `user_policy_acceptances`: `LegalAcceptancePage` → "Kabul Et ve Devam Et" → `LegalRepository.acceptPolicyVersions()` → upsert. İstemci `ip_address` göndermez; trigger doldurur (**sessiz**)
- `business_policy_acceptances`: Personel/panel tarafında işletme politika kabul akışı. Flutter mobil bu tabloya yazmaz

### IP dışında user_agent / request_id tutuluyor mu?

- **`user_agent`:** Evet, iki policy tablosunda. Flutter istemcisi `acceptPolicyVersions()` içinde sentetik user-agent (`yeedoy-mobile/<platform>`) açıkça gönderiyor (`legal_repository.dart` satır 87). Bu durumda trigger'ın `user_agent is null` koşulu mobil için tetiklenmez; gerçek HTTP user-agent yalnızca istemci hiç göndermezse (panel/web) yazılır
- **`request_id`:** Yok
- Ayrı `admin_audit_log` tablosu IP/UA tutar (`insert_audit_log_v1` + `capture_request_meta_v1`), ancak bu admin işlemleri içindir; R-4 kapsamı dışındadır

### Bu alanlar nullable mı?

**Evet.** Her iki tabloda da `ip_address inet null` ve `user_agent text null`. NOT NULL kısıtı yok; trigger kaldırılsa veya IP null bırakılsa şema bozulmaz, INSERT başarısız olmaz.

### Bu alanlara bağlı test, RPC, view veya UI var mı?

- **RPC/View:** Hayır. `ip_address` sütununu policy tablolarından SELECT eden hiçbir RPC, view veya fonksiyon bulunamadı
- **UI:** Hayır. Flutter `legal_repository.dart` IP'yi ne okur ne yazar
- **Test:** Doğrudan IP'ye bağlı test yok
- **Web `ip_address` referansları** (`audit.ts`, `denetim.ts`) → tümü `admin_audit_log` içindir, policy tabloları değil

**Sonuç:** IP/UA alanları teknik olarak "yazılıp hiç okunmayan" ölü-ağırlık veridir. Hiçbir özellik bunlara bağımlı değildir → teknik kırılma riski minimumdur.

---

## 2. Tablo Bazlı Karar Analizi

### a) `user_policy_acceptances`

| Soru | Yanıt |
|---|---|
| IP gerçekten gerekli mi? | Hayır. `user_id` + `policy_version_id` + `accepted_at` + `source_app` ispat için yeterli |
| Sadece audit amaçlı tutulabilir mi? | Teorik evet, ama hiç okunmuyor; audit iddiası için bile saklama süresi + aydınlatma gerekir |
| Tutulacaksa hangi ekranda bildirilmeli? | `LegalAcceptancePage` (zorunlu onay kartının `helperText`'i) + Gizlilik Politikası |
| Tutulmayacaksa trigger nasıl etkilenir? | Fonksiyonun IP/UA bloğu çıkarılır; `user_id`/`accepted_at` doldurma korunur |
| Mevcut eski kayıtlar için migration? | Evet — `UPDATE ... SET ip_address = NULL, user_agent = NULL` |
| Hukukçu kontrolü? | **Evet** |

> ⚠️ Hukukçuya kontrol ettirilmeli: "Politika kabul ispatı için IP zorunlu bir delil unsuru mudur, yoksa user_id + sürüm + zaman damgası yeterli mi?"

### b) `business_policy_acceptances`

| Soru | Yanıt |
|---|---|
| IP gerçekten gerekli mi? | Hayır (`user_policy_acceptances` ile aynı gerekçe) |
| Sadece audit amaçlı tutulabilir mi? | Kullanılmıyor; aynı değerlendirme |
| Tutulacaksa hangi ekranda bildirilmeli? | Personel/panel işletme politika kabul akışı (bu görevde UI okunamadı) |
| Trigger etkisi / eski kayıt / migration | (a) ile aynı; ortak fonksiyon, tek migration yeterli |
| Hukukçu kontrolü? | **Evet** (B2B temsilci verisi nüansı) |

> ⚠️ Hukukçuya kontrol ettirilmeli: Personel/panel tarafındaki kabul ekranının disclosure durumu ayrıca doğrulanmalı.

### c) `privacy_requests`

| Soru | Yanıt |
|---|---|
| IP tutuluyor mu? | **Hayır** — sütun yok |
| Trigger IP/UA yazıyor mu? | Hayır (IP/UA bloğu bu tabloyu kapsamıyor) |
| Aksiyon gerekiyor mu? | **Yok** — mevcut durum temiz |
| Hukukçu kontrolü? | Hayır (saklama süresi kararı R-4'ten bağımsız) |

### d) `account_deletion_requests`

| Soru | Yanıt |
|---|---|
| IP tutuluyor mu? | **Hayır** — sütun yok |
| Trigger IP/UA yazıyor mu? | Hayır |
| Aksiyon gerekiyor mu? | **Yok** |
| Hukukçu kontrolü? | Hayır |

---

## 3. Önerilen Karar

### **Seçenek B** ✅

> Politika kabul kayıtlarından (`user_policy_acceptances`, `business_policy_acceptances`) IP/user-agent otomatik yakalaması tamamen kaldırılmalı. `privacy_requests` ve `account_deletion_requests` zaten IP tutmuyor — dokunulmayacak.

Bu projede B'nin pratik karşılığı A'ya çok yakındır (IP sadece 2 tabloda olduğundan).

**Gerekçe:**

1. **Veri minimizasyonu (KVKK md. 4/2-ç):** IP hiçbir özellik, RPC veya UI tarafından okunmuyor → işleme amacı yok. Amaçsız kişisel veri toplamak ihlaldir
2. **Aydınlatma açığını ortadan kaldırır (KVKK md. 10):** Veri toplanmazsa aydınlatma da gerekmez — en temiz uyum yolu
3. **Teknik risk düşük:** Sütunlar nullable, hiçbir bağımlılık yok → kaldırma kırılma yaratmaz
4. **Hukuki ispat kaybı minimal:** `user_id` + `policy_version_id` + `accepted_at` + `source_app` ispat için yeterli

**Reddedilen seçenekler:**

- **C (koru + bilgilendir):** Okunmayan veriyi korumak için UI + politika metni + saklama süresi yükü doğurur. Minimizasyon ilkesine aykırı
- **D (ek bilgi gerek):** Gerekmiyor; teknik gerçeklik tam doğrulandı

> ⚠️ Hukukçuya kontrol ettirilmeli: Karar B/A onayı ve "IP'siz kabul ispatı yeterli mi" teyidi yayın öncesi alınmalı.

---

## 4. Minimum Güvenli Teknik Çözüm (Karar B)

### Gerekli SQL migration listesi

**`20260619000001_remove_ip_metadata_from_policy_acceptances.sql`**

İçeriği (sadece liste — kod yazılmadı):
- `capture_request_metadata_v1()` fonksiyonunu **yeniden tanımla**: IP/UA doldurma bloğunu çıkar; `user_id`, `accepted_at`, `submitted_at`, `requested_at` doldurma mantığını **koru**
- Geçmiş veri temizliği: `user_policy_acceptances` ve `business_policy_acceptances` tablolarında `ip_address = NULL, user_agent = NULL` UPDATE
- Sütunlar fiziksel olarak **DROP edilmez** (rollback için NULL bırakmak yeterli)
- `request_ip_v1` / `request_header_v1` fonksiyonları **silinmez** (`admin_audit_log` yolu kullanır)

> ⚠️ Hukukçuya kontrol ettirilmeli: Sütunların fiziksel DROP'u mu yoksa NULL'a çekilmesi mi tercih edilmeli.

### Gerekli Flutter UI değişiklikleri

**Karar B'de UI değişikliği gerekmez.** IP toplanmadığı için aydınlatma metni eklenmez.

Opsiyonel (hukuk kararına bağlı):
- `legal_repository.dart` → `acceptPolicyVersions()` içindeki sentetik `user_agent` gönderimi gözden geçirilir

> ⚠️ Hukukçuya kontrol ettirilmeli: Sentetik `yeedoy-mobile/<platform>` user-agent kaydı tutulsun mu (kanal/sürüm teşhisi) yoksa o da kaldırılsın mı.

### Gerekli repository/model değişiklikleri

**Yok.** `legal_repository.dart` IP'yi zaten göndermiyor/okumuyor.

### Gerekli testler

- SQL davranış testi (migration sonrası): `user_policy_acceptances`'a INSERT → `ip_address IS NULL` doğrula; `user_id`/`accepted_at` hâlâ doğru dolduğunu doğrula
- Flutter: mevcut `consent_smoke_test.dart` etkilenmez. `acceptPolicyVersions` için repo testi varsa IP içermediğini teyit eden assertion (opsiyonel)

### Geri dönüş / rollback planı

Migration yalnızca fonksiyon gövdesi + UPDATE içerdiğinden geri alınabilir:
- Önceki `capture_request_metadata_v1()` sürümünü yeniden tanımlayan ters migration yazılır
- Sütun DROP edilmediği için geri dönüş tam mümkündür
- NULL'lanan eski IP verisi geri gelmez — bu kabul edilebilir (amaçsız veri)

---

## 5. Risk Matrisi

| Risk | A — Tamamen kaldır | B — Sadece kabul kayıtlarından kaldır ✅ | C — Koru + bilgilendir | D — Karar verilemiyor |
|---|---|---|---|---|
| KVKK veri minimizasyon riski | Düşük | **Düşük** | Yüksek | Orta |
| Hukuki ispat/audit kaybı riski | Orta | **Düşük** | Düşük | Orta |
| Kullanıcı şeffaflığı riski | Düşük | **Düşük** | Orta (metin tam yazılmazsa Yüksek) | Yüksek |
| Teknik kırılma riski | Düşük | **Düşük** | Düşük | Düşük |
| Uygulama yayına çıkış riski | Düşük | **Düşük** | Orta (politika + UI bağımlılığı) | Yüksek (karar verilmeden yayın engellenir) |

---

## 6. Net Uygulama Talimatı

### SQL / Supabase değişiklikleri
- **Agent:** `voltagent-data-ai:postgres-pro` veya `mcp__supabase__apply_migration`
- **Dosyalar:**
  - `supabase/migrations/20260619000001_remove_ip_metadata_from_policy_acceptances.sql` (YENİ)
    - `capture_request_metadata_v1()` yeniden tanımı (IP/UA bloğu çıkarılır, user_id/zaman damgaları korunur)
    - `user_policy_acceptances` + `business_policy_acceptances`: ip_address/user_agent NULL'a UPDATE
    - `request_ip_v1` / `request_header_v1` **silinmez**

### Flutter UI değişiklikleri
- **Agent:** `voltagent-lang:flutter-expert`
- **Dosyalar:** Karar B'de değişiklik YOK
- Opsiyonel: `uygulamalar/mobil/lib/features/legal/legal_repository.dart` (user_agent gönderimi — hukuk kararına bağlı)

### Test
- **Agent:** `voltagent-qa-sec:qa-expert`
- **Dosyalar:**
  - Migration sonrası SQL INSERT davranış doğrulaması
  - `uygulamalar/mobil/test/features/legal/` (gerekirse `acceptPolicyVersions` assertion)

### Legal metin güncellemesi
- **Agent:** `voltagent-biz:legal-advisor`
- **Dosyalar:**
  - `docs/legal/legal-data-inventory.md` (R-4 satırı güncellenir: "kaldırıldı")
  - Gizlilik Politikası / KVKK Aydınlatma taslakları (IP kaydı maddesi B kararına göre revize)
  - Personel/panel `business_policy_acceptances` kabul ekranı disclosure teyidi (ayrı doğrulama)

---

## Önemli Düzeltme Notu

Önceki `critical-privacy-gaps-report.md` Bölüm 4.2'deki "`privacy_requests` ve `account_deletion_requests` IP kaydediyor olabilir" varsayımı **doğrulanmadı**: bu tablolarda IP/UA sütunu yoktur; trigger oralarda IP yazmaz. **R-4'ün gerçek kapsamı yalnızca 2 tablodur.**

---

## Hukukçu Kontrol Listesi

- [ ] Karar B/A onayı: "IP'siz kabul ispatı KVKK kapsamında yeterli mi?"
- [ ] Sütun fiziksel DROP mu yoksa NULL'a çekilme mi?
- [ ] Sentetik `yeedoy-mobile/<platform>` user-agent kaydı tutulsun mu?
- [ ] Personel/panel `business_policy_acceptances` kabul ekranı disclosure durumu doğrulaması
