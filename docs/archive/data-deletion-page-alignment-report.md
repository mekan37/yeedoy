# Veri Silme Talebi Ekranı — Yasal Uyum Hizalama Raporu

Tarih: 2026-06-19  
Kapsam: `uygulamalar/mobil/lib/features/legal/ui/data_deletion_page.dart` Flutter UI metin düzeltmeleri  
Yöntem: Legal belgeler okundu, ekran analiz edildi, UI metinleri güncellendi, testler eklendi.  
Bu rapor hukuki metin değildir.

---

## 1. Yapılan Değişiklik Özeti

`data_deletion_page.dart` dosyasındaki beş ayrı yasal sorun düzeltildi:

1. "Hesabınız ve tüm verileriniz kalıcı olarak silinecektir." ifadesi kaldırıldı, yerine KVKK uyumlu metin eklendi.
2. "Bu işlem geri alınamaz." satırı tamamen kaldırıldı.
3. "30 gün içinde" kesin süre ifadesi SnackBar metninden kaldırıldı.
4. "Veri İndir" aktif metin/buton kaldırıldı (backend yok, işlevsiz).
5. Pazarlama e-postası kapatma seçeneği eklendi; seçildiğinde form gönderilmeyip `/notification-preferences` sayfasına yönlendirme yapılıyor.
6. Talep nedeni listesi KVKK uyumlu 7 kategoriye genişletildi.
7. 11 adet yasal metin uyum testi eklendi; tamamı geçiyor.

---

## 2. Güncellenen Flutter Dosyaları

| Dosya | Değişiklik türü |
|---|---|
| `uygulamalar/mobil/lib/features/legal/ui/data_deletion_page.dart` | Metin ve mantık düzeltmesi |
| `uygulamalar/mobil/test/features/legal/data_deletion_page_text_test.dart` | Yeni test dosyası (oluşturuldu) |

---

## 3. Değiştirilen Riskli İfadeler (Eski → Yeni)

### 3.1 _PreRequestCard — 1. satır

**Eski (riskli):**
> "Hesabınız ve tüm verileriniz kalıcı olarak silinecektir."

**Yeni:**
> "Hesabınıza ilişkin kişisel verilerinizin silinmesini, yok edilmesini veya anonim hale getirilmesini talep edebilirsiniz."

**Sorun:** Eski metin KVKK'da tanımlı silme/yok etme/anonimleştirme ayrımını yok sayıyor, her verinin silineceğini taahhüt ediyor, yasal saklama istisnalarını dışlıyor, `veri-silme-talebi.md` Bölüm 15 ve KVKK Aydınlatma Metni ile çelişiyordu.

### 3.2 _PreRequestCard — "Bu işlem geri alınamaz." satırı

**Eski (riskli):**
> "Bu işlem geri alınamaz."

**Yeni:** Bu satır kaldırıldı. Yerine "sınırlı süre saklanabilir" uyarısı ve "Talebinizin sonucu size bildirilecektir." bilgi satırı eklendi.

**Sorun:** "Geri alınamaz" ifadesi birden fazla veri türü için saklama istisnasının var olduğunu yok sayıyordu; ayrıca kullanıcı talep sürecinin bir talep/değerlendirme akışı olduğunu gizliyordu.

### 3.3 SnackBar metni — "30 gün"

**Eski (riskli):**
> "Talebiniz alındı. 30 gün içinde e-posta adresinize bildirilecektir."

**Yeni:**
> "Talebiniz alındı. Değerlendirme sonucu e-posta adresinize bildirilecektir."

**Sorun:** `veri-silme-talebi.md` Bölüm 10 ve KVKK Aydınlatma Metni Bölüm 11 açıkça "kesin yasal süre hukukçuya danışılmadan yazılmamalıdır" şeklinde not düşmüştür. "30 gün" ifadesi henüz hukukçu onayı olmayan bir taahhüttü.

### 3.4 _AfterSubmitCard metni — "30 gün" ve "kalıcı silinecektir"

**Eski (riskli):**
> "Talebiniz 30 gün içinde değerlendirilecek ve sonucu e-posta adresinize bildirilecektir. İşleminiz tamamlandığında hesabınız ve verileriniz kalıcı olarak silinecektir."

**Yeni:**
> "Talebiniz alınır ve değerlendirilir. Talebinizin sonucu size bildirilecektir. Bazı veriler yasal yükümlülükler nedeniyle sınırlı süre saklanabilir."

**Sorun:** Çifte sorun içeriyordu — hem kesin süre hem de tüm verilerin silineceği taahhüdü.

### 3.5 Talep nedeni listesi

**Eski:**
```
- Hesabımı kapatmak istiyorum
- Gizlilik endişelerim var
- Hizmeti kullanmak istemiyorum
- Diğer
```

**Yeni:**
```
- Hesabımı silme talebi
- Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi
- Yorum, favori veya check-in verilerimle ilgili talep
- Destek talebi geçmişimle ilgili talep
- İşletme sahipliği başvurumla ilgili talep
- Pazarlama e-postası iznini kapatmak istiyorum
- Diğer
```

**Sorun:** Eski liste KVKK madde 11 kapsamındaki veri tipleri ayrımını yansıtmıyor, `veri-silme-talebi.md` Bölüm 4 ve Bölüm 7'deki önerilen yapıyla uyumsuzdu.

---

## 4. Veri İndir Eylemi — Karar ve Gerekçe

**Karar: Kaldırıldı.**

**Gerekçe:**
- `veri-silme-talebi.md` Bölüm 15 şöyle belirtmektedir: "Ekrandaki 'Veri İndir' eylemi işlevsiz görünmektedir; ya işlevsel hale getirilmeli ya da kaldırılmalıdır."
- Backend'de veri export için herhangi bir RPC, Supabase Edge Function veya repository metodu yoktur.
- `legal_repository.dart` dosyasında `submitPrivacyRequest` ve `submitAccountDeletionRequest` mevcuttur; veri export metodu yoktur.
- İşlevsiz bir "Veri İndir" butonu/linki kullanıcıyı yanıltır ve KVKK madde 11/d kapsamındaki veri taşınabilirliği hakkının uygulandığı izlenimini yaratır.
- Backend uygulaması hazır olduğunda ayrı bir görevde aktif hale getirilebilir.

---

## 5. Hesap Silme / Veri Silme / Pazarlama İzni Ayrımı Analizi

### Mevcut uygulama:

| İşlem | Flutter kodu | Hedef tablo/RPC |
|---|---|---|
| Veri silme talebi (genel) | `submitPrivacyRequest(requestType: 'delete_data', ...)` | `privacy_requests` |
| Hesap silme talebi | `submitAccountDeletionRequest(reason: ...)` | `account_deletion_requests` |
| Global pazarlama izni kapatma | `updateMyMarketingEmailOptIn(enabled: false)` | `update_my_marketing_email_opt_in_v1` RPC |
| İşletme bazlı abonelik | `updateBusinessFollowEmailSubscription(...)` | `business_follows.is_subscribed_email` |

### Sorunlar (backend değişikliği gerektiriyor — bu görevde yapılmadı):

1. Ekrandaki "Hesabımı silme talebi" seçeneği `submitPrivacyRequest(requestType: 'delete_data')` ile `privacy_requests` tablosuna yazılıyor. Oysa hesap silme talebi `submitAccountDeletionRequest` ile `account_deletion_requests` tablosuna yazılmalı. UI'da ayrım var, kod yolunda henüz yok.

2. `privacy_requests` tablosunun `request_type` CHECK constraint'i şu değerleri kabul ediyor: `'data_export', 'privacy_application', 'access', 'rectification', 'erasure', 'restriction', 'objection', 'portability'`. Kodun gönderdiği `'delete_data'` bu listede YOK. Bu bir runtime hatası yaratır. **Bu görevde backend değişikliği yapılmadı; backend ekibine raporlanmalıdır.**

---

## 6. account_deletion_requests ve privacy_requests Analiz Sonucu

### account_deletion_requests tablosu:
- `status` değerleri: `requested, in_review, completed, rejected, cancelled`
- RLS: `insert_own` (authenticated kullanıcı kendi kaydını ekleyebilir), `select_own` (authenticated veya admin okuyabilir)
- Flutter: `submitAccountDeletionRequest()` metodu doğru şekilde bu tabloya yazıyor

### privacy_requests tablosu:
- `request_type` CHECK: `data_export, privacy_application, access, rectification, erasure, restriction, objection, portability`
- `status` değerleri: `submitted, in_review, resolved, rejected, cancelled`
- Flutter: `submitPrivacyRequest(requestType: 'delete_data')` çağrısı CHECK constraint ile çakışıyor — `'delete_data'` geçersiz değer

### Sonuç:
- Hesap silme talebi: yanlış tabloya yazılıyor (privacy_requests yerine account_deletion_requests olmalı)
- Genel veri silme talebi: `request_type: 'delete_data'` geçersiz — DB CHECK constraint hatasına yol açar

---

## 7. Backend Değişikliği Gerekiyor mu?

**Evet, iki backend düzeltmesi gerekiyor (bu görevde yapılmadı):**

1. "Hesabımı silme talebi" neden seçildiğinde `submitPrivacyRequest` yerine `submitAccountDeletionRequest` çağrılmalıdır. Bu kod yolu değişikliği gerektirir.

2. `privacy_requests.request_type` CHECK constraint'ine `'delete_data'` değeri eklenmeli VEYA Flutter tarafı mevcut geçerli tiplerden birini (`'erasure'`) kullanacak şekilde güncellenmeli. Migration gerektirir.

Bu iki değişiklik bu görevi aşıyor; belgelenmiş ve beklemede.

---

## 8. Çalıştırılan Testler ve Sonuçları

```
flutter test test/features/legal/data_deletion_page_text_test.dart --reporter=expanded
```

**Sonuç: 11/11 GEÇTI**

| Test | Açıklama | Sonuç |
|---|---|---|
| T1 | _PreRequestCard "kalıcı olarak silinecektir" içermiyor | GEÇTI |
| T2 | Yasaklı ifadeler hiçbir ekran metninde yok | GEÇTI |
| T3 | SnackBar kesin süre (30 gün vb.) içermiyor | GEÇTI |
| T4 | _AfterSubmitCard "sınırlı süre saklanabilir" içeriyor | GEÇTI |
| T5 | _AfterSubmitCard "Talebiniz alınır ve değerlendirilir" içeriyor | GEÇTI |
| T6 | Pazarlama seçeneği neden listesinde mevcut | GEÇTI |
| T7 | Pazarlama seçilince submitPrivacyRequest çağrılmıyor | GEÇTI |
| T8 | Pazarlama notu "veri silme talebinden farklı" içeriyor | GEÇTI |
| T9 | Pazarlama notu "Bildirim Ayarları" yönlendirmesini içeriyor | GEÇTI |
| T10 | "Veri İndir" aktif metin olarak ekranda yok | GEÇTI |
| T11 | Neden listesi 7 seçenek içeriyor | GEÇTI |

```
flutter analyze
```

**Sonuç: 8 issue — tamamı pre-existing (bu görevden önce mevcut)**

| Dosya | Issue | Bu görevle ilgisi |
|---|---|---|
| `search_filter_sheet.dart` | info: use_null_aware_elements | Önceden mevcut |
| `login_page_test.dart` | error: initialSignup param undefined | Önceden mevcut |
| `gelen_kutusu_sayfasi_test.dart` | error: recentBusinessesProvider undefined (x2) | Önceden mevcut |
| `giris_sayfasi_test.dart` | error: initialSignup param undefined | Önceden mevcut |
| `notification_preferences_test.dart` | info: unnecessary_import | Önceden mevcut |
| `inbox_page_test.dart` | error: undefined identifiers (x2) | Önceden mevcut |

`data_deletion_page.dart` ve `data_deletion_page_text_test.dart` için flutter analyze sıfır hata/uyarı döndürdü.

---

## 9. Çalıştırılamayan Testler

Yok. Tüm planlanan testler yazıldı ve çalıştırıldı.

---

## 10. Kalan Riskler

| Risk | Öncelik | Açıklama |
|---|---|---|
| `privacy_requests.request_type = 'delete_data'` DB constraint hatası | Kritik | Runtime'da INSERT başarısız olur; backend düzeltmesi bekliyor |
| "Hesabımı silme talebi" yanlış tabloya yazılıyor | Yüksek | `submitPrivacyRequest` yerine `submitAccountDeletionRequest` çağrılmalı |
| `request_type: 'delete_data'` CHECK constraint dışında | Kritik | Migration veya Flutter tarafı düzeltmesi gerekiyor |
| Onay metni ("Bu talebin bazı özelliklere erişimimi etkileyebileceğini anlıyorum.") henüz eklenmedi | Orta | `veri-silme-talebi.md` Bölüm 7'de öneriliyor; bir sonraki görevde eklenebilir |
| Talep durumu kullanıcıya gösterilmiyor | Orta | `veri-silme-talebi.md` Bölüm 15: "statüs kullanıcıya gösterilmeli" |
| Hukuki metin placeholder'ları dolu değil | Yüksek | Tüm legal docs [PLACEHOLDER] içeriyor; hukukçu onayı bekleniyor |

---

## 11. Sonraki Adım Önerisi

1. **Acil (backend):** `privacy_requests.request_type` CHECK constraint'ine `'delete_data'` eklenebilir veya Flutter tarafı `'erasure'` kullanacak şekilde güncellenebilir. Migration gerektirir.

2. **Acil (backend):** "Hesabımı silme talebi" seçildiğinde `submitAccountDeletionRequest` çağrılacak şekilde `_submit()` içine neden bazlı dallanma eklenmeli.

3. **Orta öncelik (UI):** KVKK Aydınlatma Metni Bölüm 7'de önerilen "Bu talebin bazı özelliklere erişimimi etkileyebileceğini anlıyorum." onay checkbox'ı eklenebilir.

4. **Orta öncelik (UI):** Talep durumu (submitted / in_review / resolved) kullanıcıya gösterilecek bir banner veya bilgi satırı ile ekrana yansıtılabilir.

5. **Hukuki:** Tüm legal belgelerdeki `[PLACEHOLDER]` alanları hukukçu onayıyla doldurulmalı; saklama süreleri kesinleştirilmeli.

---

*Bu rapor hukuki metin değildir. KVKK/Gizlilik/Veri Silme legal belgelerinin final metni hukukçu onayına bağlıdır.*
