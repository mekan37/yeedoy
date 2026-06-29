# Flutter RPC Hizalama Raporu — Veri Silme Talebi

Tarih: 2026-06-19
Kapsam: data_deletion_page.dart _submit() akışı ve legal_repository.dart RPC bağlantısı
Yöntem: Önceki legal raporlar + Flutter kaynak kodu statik analiz. Production'a bağlanılmadı.
Bu rapor hukuki metin değildir.

---

## 1. Yapılan Değişiklik Özeti

| # | Değişiklik | Dosya |
|---|---|---|
| 1 | `_submit()` metoduna neden bazlı dallanma eklendi | `data_deletion_page.dart` |
| 2 | `_reasonToRequestType()` yardımcı metodu eklendi | `data_deletion_page.dart` |
| 3 | SnackBar metni güncellendi: "Talebiniz alınmıştır. Değerlendirme sonucu size bildirilecektir." | `data_deletion_page.dart` |
| 4 | `submitPrivacyRequest()` doğrudan tablo INSERT yerine `submit_privacy_request_v1` RPC'ye bağlandı | `legal_repository.dart` |
| 5 | `submitAccountDeletionRequest()` doğrudan tablo INSERT yerine `submit_account_deletion_request_v1` RPC'ye bağlandı | `legal_repository.dart` |
| 6 | `_ensureNoOpenRequest()` private metodu kaldırıldı (RPC kendi içinde yönetiyor) | `legal_repository.dart` |
| 7 | `submitPrivacyRequest` imzası: `details` artık `String?` (isteğe bağlı) | `legal_repository.dart` |
| 8 | `submitAccountDeletionRequest` imzası: `reason` artık `String?` (isteğe bağlı) | `legal_repository.dart` |
| 9 | Test dosyası 11 metin testinden 24 teste genişletildi (13 yeni RPC dallanma testi) | `data_deletion_page_text_test.dart` |
| 10 | `legal_acceptance_marketing_test.dart` fake sınıf imzaları güncellendi | `legal_acceptance_marketing_test.dart` |

---

## 2. Güncellenen Flutter Dosyaları

| Dosya | Değişiklik türü |
|---|---|
| `uygulamalar/mobil/lib/features/legal/ui/data_deletion_page.dart` | `_submit()` neden dallanması + `_reasonToRequestType()` + SnackBar metni |
| `uygulamalar/mobil/lib/features/legal/legal_repository.dart` | `submitPrivacyRequest` ve `submitAccountDeletionRequest` RPC'ye bağlandı, `_ensureNoOpenRequest` kaldırıldı |
| `uygulamalar/mobil/test/features/legal/data_deletion_page_text_test.dart` | 11 metin testinden 24 teste genişletildi |
| `uygulamalar/mobil/test/features/legal/legal_acceptance_marketing_test.dart` | Fake sınıf imzaları `String?` ile hizalandı |

---

## 3. Eklenen/Güncellenen Repository Metotları

### 3.1 submitPrivacyRequest (güncellendi)

```dart
Future<void> submitPrivacyRequest({
  required String requestType,
  String? details,           // String? — isteğe bağlı
}) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) throw StateError('auth_required');

  await _supabase.rpc(
    'submit_privacy_request_v1',
    params: <String, dynamic>{
      'p_request_type': requestType,
      if (details != null && details.trim().isNotEmpty)
        'p_details': details.trim(),
    },
  );
}
```

Eski davranış: `_supabase.from('privacy_requests').insert(...)` — doğrudan tablo INSERT.
Yeni davranış: `submit_privacy_request_v1` RPC çağrısı. RPC auth kontrolü ve duplicate koruması yapıyor.

### 3.2 submitAccountDeletionRequest (güncellendi)

```dart
Future<void> submitAccountDeletionRequest({String? reason}) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) throw StateError('auth_required');

  await _supabase.rpc(
    'submit_account_deletion_request_v1',
    params: <String, dynamic>{
      if (reason != null && reason.trim().isNotEmpty)
        'p_reason': reason.trim(),
    },
  );
}
```

Eski davranış: `_supabase.from('account_deletion_requests').insert(...)` — doğrudan tablo INSERT.
Yeni davranış: `submit_account_deletion_request_v1` RPC çağrısı.

---

## 4. UI Seçeneği → RPC → request_type Eşleştirmesi

| UI seçeneği | Çağrılan repository metodu | RPC | request_type / parametre |
|---|---|---|---|
| Hesabımı silme talebi | `submitAccountDeletionRequest` | `submit_account_deletion_request_v1` | `p_reason: details` |
| Kişisel verilerimin silinmesi / yok edilmesi / anonimleştirilmesi talebi | `submitPrivacyRequest` | `submit_privacy_request_v1` | `p_request_type: 'delete_data'` |
| Yorum, favori veya check-in verilerimle ilgili talep | `submitPrivacyRequest` | `submit_privacy_request_v1` | `p_request_type: 'delete_interactions'` |
| Destek talebi geçmişimle ilgili talep | `submitPrivacyRequest` | `submit_privacy_request_v1` | `p_request_type: 'delete_support'` |
| İşletme sahipliği başvurumla ilgili talep | `submitPrivacyRequest` | `submit_privacy_request_v1` | `p_request_type: 'delete_owner_claims'` |
| Pazarlama e-postası iznini kapatmak istiyorum | Hiçbir RPC çağrılmaz | — | `context.push('/notification-preferences')` ile yönlendirilir |
| Diğer | `submitPrivacyRequest` | `submit_privacy_request_v1` | `p_request_type: 'other'` |

`_reasonToRequestType()` metodu `data_deletion_page.dart` içinde `static` olarak tanımlandı. Switch expression ile neden dizesini request_type değerine dönüştürüyor; bilinmeyen değerlerde `'other'` döndürüyor.

---

## 5. Hesap Silme ve Veri Silme Ayrımı

Önceki agent bu ayrımı tespit etmişti; bu görevde kod yoluyla uygulandı.

**"Hesabımı silme talebi"** seçeneği:
- `submitAccountDeletionRequest()` çağrılır
- `submit_account_deletion_request_v1` RPC çağrılır
- `account_deletion_requests` tablosuna yazılır
- `status: 'requested'` ile başlar

**Diğer gizlilik/veri talepleri:**
- `submitPrivacyRequest()` çağrılır
- `submit_privacy_request_v1` RPC çağrılır
- `privacy_requests` tablosuna yazılır
- `status: 'submitted'` ile başlar

Bu ayrım `veri-silme-talebi.md` Bölüm 4 ve `data-deletion-backend-implementation-report.md` Bölüm 8 ile hizalıdır.

---

## 6. Pazarlama İzni Ayrımı

`_marketingReason = 'Pazarlama e-postası iznini kapatmak istiyorum'` seçildiğinde:

1. `_isMarketingSelected` getter `true` döner
2. `_submit()` içinde ilk dallanmada yakalanır
3. `context.push('/notification-preferences')` ile yönlendirme yapılır
4. Hiçbir RPC çağrılmaz — ne `submit_privacy_request_v1` ne de `submit_account_deletion_request_v1`
5. E-posta alanı gösterilmez (`showEmailField: !_isMarketingSelected`)
6. Ekranda `_MarketingRedirectNote` widget'ı gösterilir: "Pazarlama e-postasını kapatmak, veri silme talebinden farklı bir işlemdir..."

Bu davranış `veri-silme-talebi.md` Bölüm 12 ("Pazarlama e-posta izni geri çekilmesi, veri silme talebinden farklı bir işlemdir") ile hizalıdır.

---

## 7. Çalıştırılan Testler ve Sonuçları

### 7.1 flutter analyze

```
flutter analyze lib/features/legal/ lib/features/profile/ui/account_info_page.dart lib/features/profile/ui/profile_settings_page.dart lib/features/auth/ui/account_security_page.dart
```

**Sonuç: No issues found.**

### 7.2 flutter test test/features/legal/

```
flutter test test/features/legal/ --reporter=expanded
```

**Sonuç: 49/49 GEÇTI**

| Test dosyası | Test sayısı | Sonuç |
|---|---|---|
| `consent_smoke_test.dart` | 17 | GEÇTI |
| `data_deletion_page_text_test.dart` | 24 | GEÇTI |
| `legal_acceptance_marketing_test.dart` | 8 | GEÇTI |
| **TOPLAM** | **49** | **GEÇTI** |

### 7.3 Yeni RPC dallanma testleri (T12–T24)

| Test | Açıklama | Sonuç |
|---|---|---|
| T12 | "Hesabımı silme talebi" → submitAccountDeletionRequest çağrıldı | GEÇTI |
| T13 | "Hesabımı silme talebi" → submitPrivacyRequest çağrılmadı | GEÇTI |
| T14 | "Kişisel verilerimin silinmesi" → submitPrivacyRequest(delete_data) | GEÇTI |
| T15 | "Yorum, favori veya check-in" → delete_interactions | GEÇTI |
| T16 | "Destek talebi geçmişimle ilgili talep" → delete_support | GEÇTI |
| T17 | "İşletme sahipliği başvurumla ilgili talep" → delete_owner_claims | GEÇTI |
| T18 | "Diğer" → submitPrivacyRequest(other) | GEÇTI |
| T19 | Pazarlama seçeneği → hiçbir veri silme RPC çağrılmadı | GEÇTI |
| T20 | Pazarlama seçeneği → yönlendirme yapıldı | GEÇTI |
| T21 | RPC hata verince UI çökmeden hata mesajı gösteriyor | GEÇTI |
| T22 | Ekranda "kalıcı olarak silinecektir" ifadesi yok | GEÇTI |
| T23 | Ekranda "30 gün" ifadesi yok | GEÇTI |
| T24 | _reasonToRequestType tüm eşleştirmeleri doğru | GEÇTI |

---

## 8. Çalıştırılamayan Testler

Yok. Tüm planlanan testler yazıldı ve başarıyla geçti.

---

## 9. Kalan Riskler

| Risk | Öncelik | Açıklama |
|---|---|---|
| `20260620000003_fix_privacy_request_type_and_rpcs.sql` migration production'a uygulanmamış | Kritik | Migration uygulanmadan `submit_privacy_request_v1` ve `submit_account_deletion_request_v1` RPC'leri production'da mevcut değil. Çağrı "function does not exist" hatası verir. |
| Önceki migration'lar da uygulanmamış | Kritik | `20260619000001`, `20260620000001`, `20260620000002` de uygulanmamış durumda. Migration sırası korunmalı. |
| Hukuki metin placeholder'ları kapatılmamış | Yüksek | Tüm legal belgeler `[PLACEHOLDER]` içeriyor; hukukçu onayı bekliyor. |
| Talep durumu kullanıcıya gösterilmiyor | Orta | `veri-silme-talebi.md` Bölüm 15: submitted/in_review/resolved durumları UI'a yansıtılmalı. |
| `privacy_requests_one_open_per_user_idx` tek açık talep kısıtı | Orta | Farklı kategorilerde aynı anda talep açılamıyor. Kullanıcı "Destek talebi" açıkken "Yorum talebi" açamaz. RPC P0003 döndürür; Flutter bunu AppErrorMapper ile yakalar. |
| `account_info_page.dart` ve `account_security_page.dart` SnackBar metni | Düşük | Bu sayfalardaki SnackBar hâlâ "Silme talebiniz iletildi." diyor; `data_deletion_page.dart`'taki güncellenen metinle tutarsız. Sonraki görevde hizalanabilir. |

---

## 10. Production Öncesi Kontrol Listesi

- [ ] `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` production'a uygulanmalı
- [ ] `20260620000001_user_profiles_marketing_email_opt_in.sql` production'a uygulanmalı
- [ ] `20260620000002_r5_marketing_email_rpcs.sql` production'a uygulanmalı
- [ ] `20260620000003_fix_privacy_request_type_and_rpcs.sql` production'a uygulanmalı
- [ ] `submit_privacy_request_v1` ve `submit_account_deletion_request_v1` RPC'lerinin production'da var olduğu doğrulanmalı
- [ ] Authenticated kullanıcıyla `submit_privacy_request_v1('delete_data', ...)` staging'de test edilmeli
- [ ] Authenticated kullanıcıyla `submit_account_deletion_request_v1(...)` staging'de test edilmeli
- [ ] Geçersiz request_type ile çağrı P0003 döndürdüğü doğrulanmalı
- [ ] Duplicate açık talep girişimi P0003 döndürdüğü doğrulanmalı
- [ ] `flutter analyze` sıfır hata ile geçmeli (şu an temiz)
- [ ] `flutter test test/features/legal/` tüm testler geçmeli (şu an 49/49)
- [ ] Hukuki metin placeholder'ları kapatılmadan ekran canlıya alınmamalı
- [ ] `UNSUBSCRIBE_HMAC_SECRET` ve `SITE_URL` production'da tanımlı olmalı

---

## 11. Sonraki QA Adımı Önerisi

1. **Acil — Staging testi:** Migration `20260620000003` local/staging'de çalıştırılarak Flutter `submit_privacy_request_v1` ve `submit_account_deletion_request_v1` RPC çağrıları authenticated kullanıcıyla doğrulanmalı.

2. **Orta öncelik:** "Hesabımı silme talebi" seçilince `account_deletion_requests` tablosuna yazıldığı, diğer seçeneklerde `privacy_requests` tablosuna yazıldığı DB seviyesinde doğrulanmalı.

3. **Orta öncelik:** `privacy_requests_one_open_per_user_idx` kısıtının kullanıcı davranışını nasıl etkilediği test edilmeli — açık talep varken yeni talep gönderildiğinde UI'da "Bekleyen bir gizlilik başvurunuz zaten var." mesajı gösterilmeli.

4. **Düşük öncelik:** Talep durumu (submitted/in_review/resolved) kullanıcıya gösterilecek bir banner veya bilgi satırı `data_deletion_page.dart`'a eklenebilir (`legalRequestOverviewProvider` zaten bu veriyi sunuyor).

5. **Düşük öncelik:** `account_info_page.dart` ve `account_security_page.dart`'taki "Silme talebiniz iletildi." SnackBar metni yasal belgelerle hizalanmalı.

---

*Bu rapor hukuki metin değildir. KVKK/Gizlilik/Veri Silme legal belgelerinin final metni hukukçu onayına bağlıdır.*
