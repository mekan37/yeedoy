# Yeedoy Hukuki Belge Seti — Final Tutarlılık Denetimi

**Hazırlayan:** koordinatör (kod tarama + belge analizi)  
**Denetim tarihi:** 2026-06-19  
**Durum:** TAMAMLANDI — Production öncesi eylem gerektiren maddeler listelenmiştir.

---

## 1. Yönetici Özeti

| Kategori | Durum |
|---|---|
| Belgeler arası SDK/servis tutarlılığı | ✅ Altı ana belgede tutarlı |
| Sentry kalıntı taraması (6 ana belge) | ✅ Temiz |
| `legal-data-inventory.md` Sentry kalıntısı | ⚠️ 4 satırda hâlâ Sentry var (destekleyici belge) |
| `kullanim-sartlari.md` T-10 notu | ⚠️ Bayatlamış — veri-silme-talebi zaten düzeltildi |
| Saklama süresi placeholder'ları | 🔴 10 ayrı kategori için süre belirlenmemiş |
| DPA/yurt dışı aktarım placeholder'ları | 🔴 8 placeholder doldurulmamış |
| Kimlik/iletişim placeholder'ları | 🔴 19 placeholder doldurulmamış |
| Production teknik bloklayıcı | 🔴 10 madde |
| Eksik belge (zorunlu) | 🟡 Çocukların Gizliliği (yaş sınırı belirsiz) |
| Eksik belge (önerilen) | 🟡 Erişilebilirlik Beyanı |

---

## 2. Denetim Kapsamı

### Denetlenen 6 ana belge

| # | Dosya | Durum |
|---|---|---|
| 1 | `kvkk-aydinlatma-metni.md` | ✅ |
| 2 | `gizlilik-politikasi.md` | ✅ |
| 3 | `cerez-politikasi.md` | ✅ |
| 4 | `veri-silme-talebi.md` | ✅ |
| 5 | `kullanim-sartlari.md` | ✅ (T-10 bayat notu hariç) |
| 6 | `telif-hakki-politikasi.md` | ✅ |

### Destekleyici belgeler (referans amaçlı incelendi)

- `legal-data-inventory.md` — Sentry kalıntısı bulundu (bkz. Bölüm 4)
- `legal-sdk-provider-alignment-report.md` — hizalama geçmişi
- `legal-preflight-report.md` — pre-alignment raporu (tarihsel, güncel değil)
- `r4-r5-end-to-end-qa-report.md` — pre-alignment QA raporu (tarihsel)

---

## 3. Belgeler Arası Çelişki Analizi

### ÇELİŞKİ-1 (Orta) — `kullanim-sartlari.md` T-10 notu bayatlamış

**Sorun:** `kullanim-sartlari.md` Bölüm 19 hukukçu soruları tablosundaki T-10 notu şunu söyler:

> "`veri-silme-talebi.md` Bölüm 13'te Sentry referansı kalmaktadır (alignment raporunda kaldırıldığı belirtilmesine karşın bu belge güncellenmemiş görünmektedir)."

**Gerçek durum:** `veri-silme-talebi.md` Bölüm 13 2026-06-19 tarihinde güncellendi; Sentry satırı kaldırıldı, Firebase/AdMob satırları eklendi. T-10 notu artık yanlış bilgi veriyor.

**Öneri:** `kullanim-sartlari.md` Bölüm 19 T-10 satırını "KAPATILDI (2026-06-19)" olarak işaretleyin.

---

### ÇELİŞKİ-2 (Düşük) — `legal-data-inventory.md` SDK listesi güncel değil

**Sorun:** `legal-data-inventory.md` satır 7.4, 8.5, 159 ve 176'da hâlâ Sentry listeleniyor. Bu dosya 6 ana belge kapsamında değil ancak aynı `docs/legal/` dizininde duruyor ve yanıltıcı.

**Sorunlu satırlar:**

| Satır | İçerik |
|---|---|
| 7.4 | `Sentry hata logu \| Sentry Flutter SDK (mobil)` |
| 8.5 | `Sentry \| Anonim hata trace'leri, cihaz bilgisi (PII scrub etkin)` |
| 159 | `Sentry log \| 90 gün \| Sentry politikasına bırakılmış` |
| 176 (R-6) | `Sentry PII scrub etkin ancak stack trace'lerde kullanıcı verisi sızabilir` |

**Öneri:** `legal-data-inventory.md` bu satırları Firebase Crashlytics ile güncelleyin.

---

### ÇELİŞKİ-3 (Bilgi) — Saklama sürelerinin tutarsız olmadığı, sadece doldurulmadığı

Tüm belgelerde saklama süreleri `[SAKLAMA_SURESI_*]` placeholder ile gösterilmiş. Belgeler birbirini çelişmiyor; sürelerin hiçbiri hukuki kararla belirlenmemiş. Bu bir çelişki değil, bir eksiktir (bkz. Bölüm 7).

---

## 4. Sentry Artık Tarama Sonuçları

### 6 Ana belge

| Belge | Durum | Son güncelleme |
|---|---|---|
| `kvkk-aydinlatma-metni.md` | ✅ Temiz | 2026-06-19 |
| `gizlilik-politikasi.md` | ✅ Temiz | 2026-06-19 |
| `cerez-politikasi.md` | ✅ Temiz (tarihsel atıf notu içeriyor) | 2026-06-19 |
| `veri-silme-talebi.md` | ✅ Temiz | 2026-06-19 |
| `kullanim-sartlari.md` | ✅ Temiz (T-10 bayat notu hariç — Sentry metin yok) | 2026-06-19 |
| `telif-hakki-politikasi.md` | ✅ Temiz | 2026-06-19 |

### Destekleyici belgeler

| Belge | Durum | Not |
|---|---|---|
| `legal-data-inventory.md` | ⚠️ 4 satırda Sentry | Güncellenmesi gerekiyor |
| `legal-preflight-report.md` | ℹ️ Sentry var | Pre-alignment tarihsel belge |
| `r4-r5-end-to-end-qa-report.md` | ℹ️ Sentry var | Pre-alignment QA raporu |
| `legal-sdk-provider-alignment-report.md` | ℹ️ Sentry var | Tarihsel bağlam, referans olarak bırakılabilir |

---

## 5. SDK/Servis Tutarlılık Matrisi

| Servis | KVKK | Gizlilik | Çerez | Veri Silme | Kullanım Şartları | Telif |
|---|---|---|---|---|---|---|
| **Firebase Crashlytics** | ✅ B3.8, B6 | ✅ B3.8, B7 | ✅ B3 | ✅ B13 | — | — |
| **Firebase Analytics** | ✅ B3.8, B6 | ✅ B3.9, B7 | ✅ B3 | ✅ B13 | — | — |
| **Firebase Performance** | ✅ B3.8, B6 | ✅ B3.9, B7 | ✅ B3 | ✅ B13 | — | — |
| **Firebase FCM** | ✅ B3.4 | ✅ B3.7 | ✅ B4 | ✅ B13 | ✅ B5 | — |
| **Google AdMob** | ✅ B3.8, B6 | ✅ B3.9, B7 | ✅ B4.3 | ✅ B13 | ✅ B11.2 | — |
| **Supabase (DB/Storage/Auth)** | ✅ B6 | ✅ B7 | ✅ B4.1 | ✅ B12 | ✅ | — |
| **Resend (e-posta)** | ✅ B3.5 | ✅ B7 | — | ✅ B12 | ✅ B12 | — |
| **Twilio/MessageBird (SMS)** | ✅ `[SMS_SAGLAYICI_ADI]` | ✅ | — | — | ✅ | — |

**Web analitik notu:** Web tarafında GA/GTM/Hotjar/Meta Pixel/`@vercel/analytics` olmadığı kod taramasıyla doğrulandı. Gizlilik Politikası Bölüm 3.9'da açıkça belirtilmiştir.

**Hosting/CDN notu:** `[HOSTING_SAGLAYICI]` placeholder'ı Gizlilik Politikası Bölüm 3.10'da doldurulmamış. Sunucu sağlayıcısı belirlenerek eklenmeli.

**Sonuç:** 6 ana belgede SDK/servis listesi tutarlıdır. Çelişki yok.

---

## 6. Tam Placeholder Envanteri

### 6.1 Kimlik ve İletişim Bilgileri (production öncesi mutlaka doldur)

| Placeholder | Geçtiği belgeler | Açıklama |
|---|---|---|
| `[SIRKET_UNVANI]` | KŞ, TH | Şirket ticaret unvanı |
| `[VERI_SORUMLUSU_UNVANI]` | KVKK, Gizlilik, Çerez | KVKK veri sorumlusu adı |
| `[ADRES]` / `[VERI_SORUMLUSU_ADRES]` | KVKK, Gizlilik | Tescilli iş adresi |
| `[KVKK_BASVURU_EPOSTA]` | KVKK, Gizlilik, VSD, Çerez | KVKK başvuru e-postası |
| `[DESTEK_EPOSTA]` | Gizlilik, VSD, KŞ, Çerez | Genel destek e-postası |
| `[TELIF_BILDIRIM_EPOSTA]` | TH | Telif ihlal bildirimleri |
| `[TELEFON]` | Gizlilik | Kurum telefon numarası |
| `[WEB_SITESI]` | KVKK, Gizlilik, KŞ | Alan adı (ör. yeedoy.com) |
| `[YURURLUK_TARIHI]` | Tüm 6 belge | Yayın tarihi |
| `[VERGI_NO]` | KŞ, TH | Vergi kimlik numarası |
| `[MERSIS_NO]` | KŞ | MERSİS kayıt numarası |
| `[YAS_SINIRI]` | KVKK, Gizlilik, KŞ | Minimum kullanım yaşı |
| `[HAREKETSIZLIK_SURESI]` | KŞ | Hesap kapatma için pasiflik süresi |
| `[UYUSMAZLIK_YETKILI_MAHKEME]` | KŞ | Yetkili mahkeme/tahkim yeri |
| `[BILDIRIM_YANIT_SURESI]` | TH | Telif bildirim yanıt süresi |
| `[YETKILI_BIRIM]` | TH, KŞ | İç telif/şikayet birimi adı |
| `[ICERIK_SIKAYET_MEKANIZMASI]` | KŞ | 5651 kapsamı içerik şikâyet yöntemi |
| `[URL_EKLENECEK]` (3 adet) | Çerez | Tarayıcı ayar yardım linkleri |
| `[EMAIL_EKLENECEK]` (2 adet) | Çerez | İletişim e-posta adresleri |

*Kısaltmalar: KVKK = kvkk-aydinlatma-metni, Gizlilik = gizlilik-politikasi, Çerez = cerez-politikasi, VSD = veri-silme-talebi, KŞ = kullanim-sartlari, TH = telif-hakki-politikasi*

---

### 6.2 DPA ve Yurt Dışı Aktarım (hukuki onay gerekli)

| Placeholder | Geçtiği belgeler | Açıklama |
|---|---|---|
| `[SUPABASE_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Supabase DPA / SCCs durumu |
| `[FIREBASE_DPA_DURUMU]` | KVKK (×3), Gizlilik, VSD | Firebase/Google Cloud DPA durumu |
| `[ADMOB_DPA_DURUMU]` | KVKK, Gizlilik, VSD | AdMob DPA / iOS ATT durumu |
| `[RESEND_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Resend DPA durumu |
| `[SMS_SAGLAYICI_DPA_DURUMU]` | KVKK, Gizlilik | SMS sağlayıcısı DPA durumu |
| `[SMS_SAGLAYICI_ADI]` | KVKK, Gizlilik, KŞ | SMS sağlayıcı ticari adı |
| `[YURT_DISI_AKTARIM_DURUMU]` | Tüm 6 belge | Yurt dışı aktarım güvencesi (SCC/Kurul kararı/muafiyet) |
| `[HOSTING_SAGLAYICI]` | Gizlilik | Hosting/CDN sağlayıcı adı |

---

## 7. Saklama Süresi Placeholder Listesi

Aşağıdaki 10 veri kategorisi için hukuki olarak belirlenmiş saklama süresi bulunmamaktadır. Her birinin belirlenmesi KVKK md. 4/2-e (gerekli süreyle sınırlı saklama) yükümlülüğü için zorunludur.

| # | Placeholder | Kapsam | Geçtiği belgeler |
|---|---|---|---|
| S-1 | `[SAKLAMA_SURESI_HESAP]` | Hesap verileri (profil, oturum) | VSD |
| S-2 | `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | Yorumlar, etkileşimler, koleksiyon | KVKK, Gizlilik, VSD |
| S-3 | `[SAKLAMA_SURESI_KONUM]` | Konum verileri | VSD |
| S-4 | `[SAKLAMA_SURESI_DESTEK]` | Destek talepleri | KVKK, Gizlilik, VSD |
| S-5 | `[SAKLAMA_SURESI_POLICY_ACCEPTANCE]` | Politika kabul kayıtları | KVKK, Gizlilik, VSD |
| S-6 | `[SAKLAMA_SURESI_OWNER_CLAIMS]` | İşletme sahiplik talepleri | KVKK, Gizlilik, VSD |
| S-7 | `[SAKLAMA_SURESI_MARKETING_CONSENT]` | Pazarlama izin kayıtları | KVKK, Gizlilik, VSD |
| S-8 | `[SAKLAMA_SURESI_LOGS]` | Sistem/güvenlik logları | KVKK, Gizlilik, VSD |
| S-9 | `[SAKLAMA_SURESI_ANALYTICS]` | Analitik olaylar | KVKK, Gizlilik, VSD |
| S-10 | `[SAKLAMA_SURESI_BILDIRIMLER]` | Bildirim geçmişi | KVKK, Gizlilik, VSD |

**Not:** `legal-preflight-report.md` içinde `[SAKLAMA_SURESI_SNAPSHOTS]`, `[SAKLAMA_SURESI_ACTIVITY_LOG]`, `[SAKLAMA_SURESI_YORUMLAR]`, `[SAKLAMA_SURESI_KABUL_KAYDI]` de bulunmaktadır; bu dosya destekleyici nitelikte olup 6 ana belge kapsamı dışındadır.

---

## 8. Production Öncesi Teknik Bloklayıcılar

| # | Bloklayıcı | Sorumlu | Öncelik |
|---|---|---|---|
| **B-1** | Tüm `[PLACEHOLDER]` değerleri doldurulmadan hiçbir hukuki sayfa yayınlanamaz. `[YURURLUK_TARIHI]` dahil 27+ placeholder açık. | İşletme / Hukuk | 🔴 Kritik |
| **B-2** | Supabase migrations production'a uygulanmamış: `20260619000001_remove_ip_metadata_from_policy_acceptances.sql`, `20260620000001_user_profiles_marketing_email_opt_in.sql`, `20260620000002_r5_marketing_email_rpcs.sql`, `20260620000003_fix_privacy_request_type_and_rpcs.sql` | Backend | 🔴 Kritik |
| **B-3** | iOS `Info.plist`'te `NSUserTrackingUsageDescription` ve `GADApplicationIdentifier` doğrulanmalı; ATT izin akışı `native_ad_controller.dart`'ta tetikleniyor mu kontrol edilmeli. | iOS dev | 🔴 Kritik |
| **B-4** | Google Play Console Data Safety formu ve App Store Privacy Label Firebase Crashlytics / Analytics / Performance / AdMob veri toplama beyanlarıyla güncellenmeli. | Mobile ops | 🔴 Kritik |
| **B-5** | `UNSUBSCRIBE_HMAC_SECRET` env değişkeni production'da tanımlanmalı; e-posta abonelik iptal token doğrulaması bu anahtara bağlı. | Infra | 🔴 Kritik |
| **B-6** | Firebase Analytics / Crashlytics için kullanıcı opt-out mekanizması (collection enabled toggle) ürün içinde mevcut mu doğrulanmalı. KVKK itiraz hakkı (md. 11/e) teknik olarak karşılanamadığı sürece belge boş vaat içerir. | Mobile dev | 🔴 Kritik |
| **B-7** | Consent banner kararı verilmeli: web'de Supabase oturum çerezi zorunlu; analitik `yd_client_id` için consent banner gerekip gerekmediği hukukçuyla netleştirilmeli; karar Çerez Politikası Bölüm 7'ye eklenmeli. | Hukuk + Frontend | 🟠 Yüksek |
| **B-8** | `[HOSTING_SAGLAYICI]` belirsiz. Web deployment altyapısı (Vercel? AWS? Supabase Edge?) belirlenerek Gizlilik Politikası Bölüm 3.10 ve ilgili KVKK bloğu güncellenmeli. | Infra + Hukuk | 🟠 Yüksek |
| **B-9** | `/legal/` web rotasında yayınlanan metinler bu belgelerle eşitlenmeli; özellikle çerez politikası ve KVKK aydınlatma metni web'de güncel olmalı. | Frontend | 🟠 Yüksek |
| **B-10** | `legal-data-inventory.md` Sentry satırları (7.4, 8.5, 159, 176) Firebase Crashlytics ile güncellenmeli; `kullanim-sartlari.md` T-10 "KAPATILDI" olarak işaretlenmeli. | Hukuk | 🟡 Orta |

---

## 9. Hukukçuya Sorular (Önem Sırasına Göre)

| # | Soru | Öncelik |
|---|---|---|
| **H-1** | AdMob için iOS ATT izni zorunlu mu; kişiselleştirilmiş reklam gösterimi için ayrı açık rıza (KVKK md. 5/1) şart mı, yoksa meşru menfaat (md. 5/2-f) yeterli mi? | 🔴 Kritik |
| **H-2** | Firebase Crashlytics/Analytics/Performance ve Google AdMob için Google Cloud DPA imzalanmalı mı; SCCs/standart sözleşme maddeleri Türkiye-ABD aktarımı için KVKK Kurul kararı olmadan yeterli midir? | 🔴 Kritik |
| **H-3** | Supabase (AB bölgesi) için aktarım güvencesi: Supabase'in AB sunucularında tutulması KVKK md. 9/2 kapsamında yeterince gerekçelendirilebilir mi, yoksa ayrıca Kurul kararı mı gerekir? | 🔴 Kritik |
| **H-4** | Firebase Analytics'in user_id içeren olay logları meşru menfaate dayandırılabilir mi; kullanıcıya ayrı açık rıza sorusu sorulmalı mı? | 🟠 Yüksek |
| **H-5** | Kullanım Şartları Bölüm 12'deki çift filtre pazarlama modeli (global opt-in + işletme aboneliği) 6563 sayılı Kanun md. 6 kapsamında ticari elektronik ileti izni için yeterli mi? İki iznin birbirinden bağımsız ve ayrı onay kutusuna dayandırılması gerekiyor mu? | 🟠 Yüksek |
| **H-6** | Minimum kullanım yaşı `[YAS_SINIRI]` olarak belirlendi. 13 yaş altı kullanıcılar için KVKK kapsamında ebeveyn rızası gerekli mi; Çocukların Gizliliği Politikası ayrı bir belge olarak hazırlanmalı mı? | 🟠 Yüksek |
| **H-7** | `[SAKLAMA_SURESI_*]` kategorilerinin her birinde yasal asgari/azami süre var mı; hukuki zorunluluk bulunmayan kategoriler için makul süre nasıl belirlenmelidir (iş ihtiyacı analizi)? | 🟠 Yüksek |
| **H-8** | Kullanım Şartları Bölüm 14.1 hareketsizlik nedeniyle hesap kapatma: `[HAREKETSIZLIK_SURESI]` için yasal sınır var mı; önceden bildirim yapılması zorunlu mu? | 🟡 Orta |
| **H-9** | Telif Hakkı Politikası Bölüm 6: Yeedoy'un 5846 sayılı FSEK kapsamında "aracı hizmet sağlayıcı" niteliği taşıyıp taşımadığı ve 5651 sayılı Kanun md. 8A kapsamı; içerik kaldırma süresi yükümlülüğü var mı? | 🟡 Orta |
| **H-10** | Web'deki `yd_client_id` için "açıklayıcı banner" zorunluluğu: yalnızca birinci taraf analitik için GDPR/Türkiye uyum çerçevesinde çerez onay banner'ı şart mı? | 🟡 Orta |
| **H-11** | Kullanım Şartları Bölüm 7.5 içerik şikâyet mekanizması `[ICERIK_SIKAYET_MEKANIZMASI]`: 5651 md. 9 "erişim engeli" ve md. 9A "hak ihlali bildirimi" kapsamında Yeedoy'un sorumluluğu; yanıt süresi yükümlülüğü var mı? | 🟡 Orta |
| **H-12** | `[UYUSMAZLIK_YETKILI_MAHKEME]`: Türkiye'de tüketici uyuşmazlıkları için mahkeme seçimi kısıtlaması var mı (TKHK md. 73); tahkim maddesi yazılabilir mi? | 🟡 Orta |

---

## 10. Eksik Belge Değerlendirmesi

### 10.1 Mesafeli Satış Sözleşmesi — GEREKMİYOR

**Gerekçe:** Platform şu an ücretsizdir. Kullanım Şartları Bölüm 16 ("Ücretli Hizmetler — Henüz Aktif Değil") mesafeli satış hükümlerini doğru biçimde ileriye dönük işaretlemiştir. Ücretli hizmetler devreye girdiğinde 6502 sayılı Kanun ve Mesafeli Sözleşmeler Yönetmeliği kapsamında ayrı bir belge hazırlanmalıdır.

### 10.2 Çocukların Gizliliği Politikası — KOŞULLU GEREKLİ

**Durum:** `[YAS_SINIRI]` tüm belgelerde doldurulmamış. KVKK Bölüm 5, Gizlilik Politikası Bölüm 5 ve Kullanım Şartları Bölüm 4.2 platformun "18 yaş altına yönelik olmadığını" belirtmektedir; ancak minimum yaş sayısal olarak belirsiz.

**Öneri:**
- Yaş sınırı **18** olarak belirlenirse: Çocukların Gizliliği belgesi gerekmez; `[YAS_SINIRI]` = 18 ile tüm belgeleri güncellemeniz yeterlidir.
- Yaş sınırı **13–17** olarak belirlenirse: KVKK kapsamında ebeveyn rızası mekanizması tasarlanmalı ve ayrı bir Çocukların Gizliliği Politikası hazırlanmalıdır.
- Karar için hukukçu görüşü alınmalı (bkz. H-6).

### 10.3 Erişilebilirlik Beyanı — ÖNERİLİR

**Durum:** Yeedoy tasarım sistemi WCAG erişilebilirlik önlemlerini (min 44px tıklama hedefi, renk kontrast iyileştirmeleri, semantik yapı) uygulayarak güncellendi; ancak kamuya açık bir Erişilebilirlik Beyanı yoktur.

**Öneri:** Kısa bir Erişilebilirlik Beyanı (`erisebilirlik-beyani.md`) zorunlu değil ama rakiplerden farklılaştırıcıdır. WCAG 2.1 AA uyum hedefi, bildirilen eksikler ve iletişim kanalı belgelenebilir.

### 10.4 Yasal Destek / Legal Support Sayfası — GEREKMİYOR

**Gerekçe:** KVKK Bölüm 13 ve Gizlilik Politikası Bölüm 15 zaten veri koruma iletişim kanallarını tanımlamaktadır. Hukuki destek için ayrı belge gerekmez; `[KVKK_BASVURU_EPOSTA]` ve `[DESTEK_EPOSTA]` doldurulduğunda yeterlidir.

---

## 11. Eylem Planı

### Acil (yayın öncesi zorunlu)

1. Hukukçu H-1 → H-3 sorularını yanıtlar → DPA durumları belirlenir → tüm `[*_DPA_DURUMU]` doldurulur.
2. `[YAS_SINIRI]` kararı alınır → Çocukların Gizliliği ihtiyacı netleşir.
3. `[SAKLAMA_SURESI_*]` kategorileri için saklama süreleri belirlenir.
4. Şirket kimlik/iletişim bilgileri (`[SIRKET_UNVANI]`, `[VERI_SORUMLUSU_UNVANI]`, `[ADRES]`, e-postalar, vergi no, MERSİS no) doldurulur.
5. `[YURURLUK_TARIHI]` belirlenir ve tüm belgelere eklenir.
6. B-2 migrations production'a uygulanır.
7. B-3 iOS ATT + AdMob configuration doğrulanır.
8. B-4 App Store / Google Play Data Safety güncellenir.
9. B-5 `UNSUBSCRIBE_HMAC_SECRET` production'da set edilir.
10. B-6 Firebase opt-out mekanizması test edilir veya eklenir.

### Orta vade (yayın sonrası 30 gün)

11. `legal-data-inventory.md` Sentry satırları güncellenir (B-10).
12. `kullanim-sartlari.md` T-10 notu "KAPATILDI" işaretlenir (B-10).
13. Consent banner kararı uygulanır (B-7).
14. `[HOSTING_SAGLAYICI]` belirlenerek belgelere eklenir (B-8).
15. Erişilebilirlik Beyanı hazırlanır (opsiyonel).

---

## 12. Rapor Sonu

Bu rapor yalnızca denetim bulgusu niteliğindedir. Hukuki metin değişikliği, migration uygulaması veya production ortamına dokunulmamıştır.

**İmzalayan:** Koordinatör — Yeedoy Hukuki Belge Denetimi  
**Tarih:** 2026-06-19  
**Sonraki adım:** Hukukçuya H-1–H-12 sorularını iletin; DPA ve saklama süresi kararları sonrası tüm placeholder'ları tek oturumda doldurun.

---

## 13. Placeholder Envanteri

Tüm placeholder'lar `docs/legal/legal-placeholder-inventory.md` dosyasında tek tabloda toplanmıştır (2026-06-19).

- **41 benzersiz placeholder** tespit edildi
- **39'u yayın öncesi zorunlu**, 2'si opsiyonel (`[TICARI_UNVAN]`, `[CEREZ_POLITIKASI_BAGLANTISI]`)
- Sorumluluk dağılımı: 16 → Kullanıcı/Kurucu · 17 → Hukukçu · 5 → Hukukçu + Kullanıcı · 3 → Kullanıcı + Geliştirici
- 3 adımlı doldurma planı ve saklama süreleri için teknik öneri tablosu envanter belgesinde yer alıyor

---

## 14. Denetim Sonrası Düzeltme Kaydı

**2026-06-19 — Küçük tutarsızlıklar giderildi**

| Dosya | Değişiklik |
|---|---|
| `legal-data-inventory.md` satır 7.4 | Sentry → Firebase Crashlytics SDK |
| `legal-data-inventory.md` satır 8.5 | Sentry → Firebase Crashlytics / Analytics / Performance |
| `legal-data-inventory.md` saklama tablosu | "Sentry log" satırı → "Firebase Crashlytics logu" |
| `legal-data-inventory.md` R-6 | Sentry risk notu → Firebase Crashlytics + Google DPA notu |
| `kullanim-sartlari.md` T-10 | Bayat "Sentry referansı kalmaktadır" notu → KAPATILDI; migration B-2 notu eklendi |

Bu dosyada Bölüm 4 (ÇELİŞKİ-1 ve ÇELİŞKİ-2) ve Bölüm 8 (B-10) kapsamında tanımlanan tutarsızlıklar giderilmiştir. `legal-preflight-report.md` ve `r4-r5-end-to-end-qa-report.md` tarihsel belgelerdir; güncelleme yapılmamıştır.
