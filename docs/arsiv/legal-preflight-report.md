# Yeedoy — Hukuki Ön Kontrol Raporu

**Hazırlanma tarihi:** 2026-06-18  
**Hazırlayan:** Hukuki Ön Analiz (legal-advisor)  
**Kaynak:** `docs/hukuki/legal-data-inventory.md`  
**Kapsam:** Final hukuki metinler yazılmadan önce eksik bilgi, risk ve yapılacaklar haritası  
**Önemli uyarı:** Bu rapor hukuki danışmanlık yerine geçmez. Kritik ve Yüksek risk maddelerinin tamamı yayına çıkmadan önce bir avukata onaylatılmalıdır.

---

## Içindekiler

1. [Hukuki Belge Haritası](#1-hukuki-belge-haritası)
2. [Zorunlu Eksik Bilgiler ve Placeholder Listesi](#2-zorunlu-eksik-bilgiler-ve-placeholder-listesi)
3. [Risklerin Hukuki Sınıflandırması](#3-risklerin-hukuki-sınıflandırması)
4. [Riske Göre Yapılacak İşlem Tablosu](#4-riske-göre-yapılacak-i̇şlem-tablosu)
5. [Saklama Süresi Karar Tablosu](#5-saklama-süresi-karar-tablosu)
6. [Mesafeli Satış Sözleşmesi Gerekliliği Değerlendirmesi](#6-mesafeli-satış-sözleşmesi-gerekliliği-değerlendirmesi)
7. [Final Metinlerde Kullanılacak Placeholder Listesi](#7-final-metinlerde-kullanılacak-placeholder-listesi)
8. [Sonraki Adım Önerisi — Yazım Sırası](#8-sonraki-adım-önerisi--yazım-sırası)

---

## 1. Hukuki Belge Haritası

### 1.1 Kullanım Şartları — Kapsam Gereksinimleri

Yeedoy'un Kullanım Şartları asgari olarak şu konuları kapsamalıdır:

| # | Konu | Neden gerekli? |
|---|------|---------------|
| US-1 | Platformun tanımı ve sunulan hizmetler (keşif, dijital menü, yorum, fiyat bilgisi, kampanya, QR erişim) | Kullanıcının ne satın aldığını / ne kullandığını net tanımlamak |
| US-2 | Kullanıcı hesabı oluşturma, kapatma, askıya alma koşulları | Hesap sonlandırma yetkisinin hukuki dayanağı |
| US-3 | Kabul edilebilir kullanım — yasak davranışlar (spam, sahte yorum, yanlış işletme sahipliği iddiası, ticari kazıma) | Platform güvenliği, sorumluluğun sınırlandırılması |
| US-4 | Kullanıcı tarafından yüklenen içeriğin (yorum, fotoğraf, fiyat önerisi) lisansı | Yeedoy'un bu içeriği işleyebilmesi ve gösterebilmesi için lisans dayanağı gerekir |
| US-5 | İşletme sahipliği talep süreci ve başvurucu beyan yükümlülükleri | owner_claims sürecinin hukuki çerçevesi |
| US-6 | Fiyat bilgisinin doğruluğu ve sorumluluk reddi | Kullanıcı sunduğu fiyat bilgisine dayanarak zarara uğrarsa sorumluluk |
| US-7 | Grup rezervasyon talebi ve tekliflerin hukuki niteliği | group_requests ön teklif mi, bağlayıcı sözleşme mi? Hukukçuya sorulmalı |
| US-8 | Fikri mülkiyet (logo, marka, menü fotoğrafları, içerik) | Yeedoy'un ve üçüncü tarafların haklarının korunması |
| US-9 | Hizmetin değiştirilmesi veya sonlandırılması hakkı | Ürün değişikliği esnekliği |
| US-10 | Uygulanacak hukuk ve yetki mahkemesi | Türkiye hukuku, uyuşmazlık çözümü |
| US-11 | Yaş sınırı (18 yaş altı kullanım koşulları) | KVKK'da çocukların verisi özel kategori sayılmasa da ihtiyatlı yaklaşım gerekir; hukukçuya sorulmalı |
| US-12 | İşletme sahipleri için ek koşullar (menü doğruluğu, kampanya içeriği, ekip erişimi) | Sahip-platform ilişkisinin ayrı çerçevesi |
| US-13 | Sponsorluk / reklam paketi koşulları (mevcut altyapı var) | sponsorship_leads tablosu aktif; ödeme henüz canlı değilse pasif madde olarak yazılabilir |
| US-14 | Hesap silme ve veri silme hakkının süreci | Teknik süreçle uyum zorunlu |

### 1.2 Gizlilik Politikası — Kapsam Gereksinimleri

| # | Konu | Envanterdeki Kaynak |
|---|------|-------------------|
| GP-1 | Veri sorumlusunun kimliği ve iletişim bilgileri | Placeholder gerekiyor |
| GP-2 | Toplanan kişisel veri kategorileri | Envanter Bölüm 1-7 |
| GP-3 | Veri toplama yöntemleri (doğrudan giriş, OAuth, cihaz sensörü, çerez/client_id) | Envanter 1.6, 2.3, 7.1-7.2 |
| GP-4 | Her kategorinin işleme amacı ve hukuki dayanağı | Envanter hukuki dayanak sütunları |
| GP-5 | Üçüncü taraflarla paylaşım — Supabase, Google/Firebase, Resend, Sentry, Twilio | Envanter Bölüm 8 |
| GP-6 | Yurt dışı veri aktarımı (Supabase Frankfurt/EU, Google ABD, Sentry ABD, Resend ABD) | R-6 riski ile ilişkili; hukukçuya sorulmalı |
| GP-7 | Veri saklama süreleri | Saklama süresi karar tablosu (Bölüm 5) kararlar bekleniyor |
| GP-8 | Kullanıcı hakları (erişim, düzeltme, silme, itiraz, portabilite, şikayet) | privacy_requests tablosu altyapısı var |
| GP-9 | Konum verisinin işlenmesi (GPS, şehir/ilçe tercihi) | Envanter 2.1-2.4 |
| GP-10 | Push bildirim ve FCM token | Envanter 5.1-5.2 |
| GP-11 | IP adresi kaydı (politika kabulünde) | R-4 riski |
| GP-12 | Pazarlama e-postası ve opt-out mekanizması | R-5 riski |
| GP-13 | Profil ve içerik görünürlüğü (yorumlar kamuya açık, adla birlikte) | Envanter 3.1 |
| GP-14 | Grup talebi ve mesajların işletme sahibine görünürlüğü | R-7 riski |
| GP-15 | Siri/Google Assistant kısayolu ve cihaz önbelleği | R-10 riski |
| GP-16 | Çocukların verisi — platforma erişim yaş koşulu | Hukukçuya sorulmalı |
| GP-17 | Politika değişikliği bildirimi usulü | policy_versions tablosu ile teknik altyapı var |

### 1.3 Çerez Politikası — Kapsam Gereksinimleri

| # | Konu | Notlar |
|---|------|--------|
| CP-1 | Kullanılan çerez / yerel depolama türleri | Next.js web tarafında Supabase oturum token'ı localStorage/cookie olarak saklanıyor; mobilde SharedPreferences/SecureStorage. Tam çerez envanteri teknik ekipten alınmalı |
| CP-2 | Zorunlu (işlevsel) çerezler vs. analitik/pazarlama çerezleri ayrımı | analytics_events tablosuna client_id yazılıyor; bu bir tanımlayıcı; hukukçuya sorulmalı |
| CP-3 | Çerez onay banner'ı gerekliliği | Web tarafı için 7 Nisan 2016 tarihli BTK tebliği ve e-Gizlilik direktifi açısından değerlendirme gerekir; hukukçuya sorulmalı |
| CP-4 | Üçüncü taraf çerezleri (Google Analytics varsa) | Envanterde Google Analytics görünmüyor; doğrulama gerekiyor |
| CP-5 | Çerez yönetim mekanizması | Mevcut bir consent manager var mı? Yoksa tanımlanmalı |

### 1.4 Telif Hakkı Politikası — Kapsam Gereksinimleri

| # | Konu | Notlar |
|---|------|--------|
| TH-1 | Platform içeriğinin telif durumu (menü fotoğrafları, işletme logoları) | Yüklenen içeriğin orijinal sahibi kim? |
| TH-2 | DMCA benzeri ihbar ve kaldırma prosedürü | policy_versions'da `dmca` ve `copyright` türleri var; içeriği doldurmak gerekiyor |
| TH-3 | Kullanıcı içeriklerine verilen lisansın kapsamı | Yeedoy'un fotoğrafları CDN'de servis edebilmesi, önerilerde kullanabilmesi için |
| TH-4 | DSA (Dijital Hizmetler Yasası) uyumu | AB kullanıcılarına hizmet veriliyorsa geçerli; policy_versions'da `dsa` türü var, içerik boş |
| TH-5 | Yapay zeka içerik politikası | policy_versions'da `ai` türü var; içerik oluşturulmalı |

### 1.5 KVKK Aydınlatma Metni — Kapsam Gereksinimleri

KVKK Madde 10 uyarınca aydınlatma metni aşağıdaki veri kategorilerini ayrı ayrı ele almalıdır. Açık rıza metninden AYRI bir belge olmalıdır.

| # | Veri Kategorisi | Envanter Referansı |
|---|----------------|--------------------|
| AM-1 | Kimlik verisi (ad, soyad) | 1.4, 4.1 |
| AM-2 | İletişim verisi (e-posta, telefon) | 1.1, 1.3 |
| AM-3 | Konum verisi (GPS, şehir/ilçe) | 2.1-2.4 |
| AM-4 | Kullanım ve davranış verisi (analitik olaylar, client_id) | 7.1-7.2 |
| AM-5 | Cihaz verisi (FCM token, platform, uygulama sürümü) | 5.1-5.2 |
| AM-6 | Görsel veri (avatar, yüklenen fotoğraflar) | 1.5, 3.2 |
| AM-7 | İşlem verisi (yorum, puan, fiyat önerisi, favori) | 3.1-3.12 |
| AM-8 | Kimlik doğrulama verisi (şifre hash, IP, user-agent) | 1.2, 6.6 |
| AM-9 | Üçüncü taraf OAuth verisi (Google profil bilgisi) | 1.6 |
| AM-10 | İşletme sahipliği başvuru verisi (ad soyad, telefon, kanıt) | 4.1 |
| AM-11 | Veri işleyenler listesi (Supabase, Google, Resend, Sentry, Twilio) | Bölüm 8 |
| AM-12 | Yurt dışı veri aktarımı ve aktarım güvenceleri | R-6 riski; hukukçuya sorulmalı |
| AM-13 | Veri sahibinin hakları (KVKK md. 11) ve başvuru usulü | privacy_requests teknik altyapısı var |
| AM-14 | Veri sahibinin başvurabileceği KVKK başvuru kanalı | Placeholder gerekiyor |

**Not:** Aydınlatma metni ile açık rıza beyanı aynı belgede olamaz (KVKK Rehberi). user_policy_acceptances tablosu her ikisi için tek tıklama kullanıyorsa bu teknik ayrımın yapılması gerekir; hukukçuya sorulmalı.

### 1.6 Veri Silme Talebi — Teknik ve Hukuki Süreç Gereksinimleri

| # | Gereksinim | Mevcut Durum |
|---|-----------|--------------|
| VS-1 | Kullanıcının silme talebini iletebileceği kanal (uygulama içi form) | account_deletion_requests tablosu ve UI flow var |
| VS-2 | Talebin alındığına dair otomatik bildirim (e-posta/bildirim) | Teknik altyapı belirsiz; kontrol edilmeli |
| VS-3 | KVKK'nın öngördüğü 30 günlük cevap süresi | Süreç tanımlı değil; SLA oluşturulmalı |
| VS-4 | Hangi verilerin silineceği, hangilerinin yasal zorunluluk nedeniyle tutulacağı | Politika kabul kayıtları yasal yükümlülük nedeniyle tutulabilir; kullanıcıya bildirilmeli |
| VS-5 | Silme sonrası kullanıcıya bilgilendirme | Süreç tanımlı değil |
| VS-6 | Bağlı verilerin durumu (yorumlar, fiyat önerileri, fotoğraflar — anonim mi kalıyor yoksa siliniyor mu?) | Kritik karar; hukukçuya sorulmalı |

### 1.7 Yasal Destek Metni — İletişim ve Başvuru Kanalları

| # | Kanal | Gereklilik |
|---|-------|-----------|
| YD-1 | Genel destek e-postası | Zorunlu |
| YD-2 | KVKK başvuru e-postası veya yazılı başvuru adresi | KVKK md. 11 zorunlu kılıyor |
| YD-3 | Telefon hattı (isteğe bağlı) | Zorunlu değil ama tavsiye edilir |
| YD-4 | Posta adresi | Tüzel kişi için zorunlu |
| YD-5 | Yanıt süresi taahhüdü | 30 gün içinde yanıt KVKK zorunluluğu |
| YD-6 | KVK Kurumu'na şikayet hakkı bilgisi | KVKK md. 14 gereği aydınlatma metninde yer almalı |

---

## 2. Zorunlu Eksik Bilgiler ve Placeholder Listesi

Aşağıdaki bilgiler mevcut değildir. Final metinler yazılmadan önce bu bilgiler temin edilmeli; temin edilemezse placeholder ile geçici metin oluşturulabilir, ancak yayına çıkmadan önce mutlaka doldurulmalıdır.

| # | Eksik Bilgi | Hangi Belgede Gerekli | Placeholder | Kritiklik |
|---|------------|----------------------|-------------|-----------|
| E-1 | Veri sorumlusunun gerçek / tüzel kişi adı | Tüm belgeler | `[VERI_SORUMLUSU_UNVANI]` | Kritik |
| E-2 | Ticari unvan (varsa şirket adı) | Tüm belgeler | `[TICARI_UNVAN]` | Kritik |
| E-3 | Vergi numarası / MERSİS numarası | Kullanım Şartları, KVKK Aydınlatma | `[VERGI_NO]` / `[MERSIS_NO]` | Yüksek |
| E-4 | Kayıtlı iş adresi | Tüm belgeler | `[ADRES]` | Kritik |
| E-5 | Genel destek e-posta adresi | Tüm belgeler, Yasal Destek | `[DESTEK_EPOSTA]` | Kritik |
| E-6 | KVKK başvuru e-posta adresi | KVKK Aydınlatma, Gizlilik Politikası | `[KVKK_BASVURU_EPOSTA]` | Kritik |
| E-7 | Telefon numarası (isteğe bağlı) | Yasal Destek, KVKK Aydınlatma | `[TELEFON]` | Orta |
| E-8 | Supabase ile imzalı Veri İşleme Anlaşması (DPA) var mı? | Gizlilik Politikası, KVKK Aydınlatma | `[SUPABASE_DPA_DURUMU]` | Kritik |
| E-9 | Google / Firebase ile DPA imzalı mı? | Gizlilik Politikası, KVKK Aydınlatma | `[GOOGLE_DPA_DURUMU]` | Kritik |
| E-10 | Resend ile DPA imzalı mı? | Gizlilik Politikası | `[RESEND_DPA_DURUMU]` | Yüksek |
| E-11 | Sentry ile DPA / SCCs imzalı mı? | Gizlilik Politikası | `[SENTRY_DPA_DURUMU]` | Yüksek |
| E-12 | Twilio/MessageBird ile DPA imzalı mı? | Gizlilik Politikası | `[SMS_SAGLAYICI_DPA_DURUMU]` | Yüksek |
| E-13 | Yurt dışına veri aktarımı için KVKK Kurulu kararı veya muafiyet var mı? | KVKK Aydınlatma, Gizlilik Politikası | `[YURT_DISI_AKTARIM_DURUMU]` | Kritik |
| E-14 | Pazarlama e-postası opt-in için ayrı onay kutusu UI akışı teyit edildi mi? | Gizlilik Politikası, Kullanım Şartları | `[PAZARLAMA_OPTIN_AKIS_DURUMU]` | Kritik |
| E-15 | Web tarafı için çerez / consent banner var mı? | Çerez Politikası | `[CEREZ_BANNER_DURUMU]` | Yüksek |
| E-16 | Ödeme / abonelik sistemi aktif mi? Hangi sağlayıcı? | Kullanım Şartları, Mesafeli Satış | `[ODEME_SISTEMI_DURUMU]` | Orta |
| E-17 | Reklam paketi satışı (sponsorships) aktif ve paralı mı? | Kullanım Şartları, Mesafeli Satış | `[REKLAM_PAKETI_DURUMU]` | Orta |
| E-18 | Uygulamanın yayına çıkış tarihi / politika yürürlük tarihi | Tüm belgeler | `[YURURLUK_TARIHI]` | Orta |
| E-19 | SMS OTP için hangi sağlayıcı kullanılıyor: Twilio mu, MessageBird mi, diğer mi? | Gizlilik Politikası | `[SMS_SAGLAYICI_ADI]` | Orta |
| E-20 | Çocuklara yönelik hizmet mi? Yaş sınırı kararı | Kullanım Şartları, KVKK Aydınlatma | `[YAS_SINIRI]` | Yüksek |

---

## 3. Risklerin Hukuki Sınıflandırması

Envanterdeki 10 risk maddesi aşağıdaki gibi derecelendirilmiştir:

| Risk | Bulgu Özeti | Sınıf | Gerekçe |
|------|------------|-------|---------|
| R-1 | analytics_events saklama süresi tanımsız | Yüksek | KVKK md. 7/f.2 — işleme amacı ortadan kalktığında silme zorunlu; ölçülebilir süre belirlenmeli |
| R-2 | business_activity_log sınır yok | Orta | Doğrudan kişisel veri içermiyor; log user_id içerip içermediği tekrar kontrol edilmeli; içeriyorsa Yüksek'e çıkar |
| R-3 | menu_snapshots saklama belirsiz | Orta | snapshot_json içinde fiyat öneren kullanıcı ID'si created_by olarak saklanıyor; dolaylı kişisel veri riski |
| R-4 | IP adresi kaydı aydınlatılmamış | Kritik | KVKK md. 10 — veri işleme başlamadan önce aydınlatma zorunlu; IP kişisel veri sayılır |
| R-5 | Pazarlama opt-in akışı doğrulanmamış | Kritik | 6563 sayılı Ticari İletişim ve Ticari Elektronik İleti Kanunu md. 6 — açık onay olmadan ticari elektronik ileti göndermek idari para cezasına tabidir |
| R-6 | Sentry yurt dışı aktarım güvencesi belirsiz | Yüksek | KVKK md. 9 — yurt dışına aktarımda Kurul izni veya muafiyet gerekir; Sentry ABD menşeli |
| R-7 | group_requests işletme sahibine görünüyor | Orta | Kullanıcı verilerinin üçüncü tarafa aktarılması; aydınlatma metninde belirtilmeli |
| R-8 | notifications silme politikası yok | Orta | Süresiz kişisel veri birikimi; temizleme trigger'ı eklenmeli |
| R-9 | owner_claims saklama belirsiz | Yüksek | Ad, telefon, kanıt belgesi içeriyor; KVKK md. 7 saklama süresi zorunlu |
| R-10 | Siri/Google Assistant cihaz önbelleği | Düşük | Cihaz düzeyinde; Apple ve Google'ın kendi politikaları öncelikli; AppStore/PlayStore mağaza listesinde belirtilmeli |

---

## 4. Riske Göre Yapılacak İşlem Tablosu

| Risk | Hangi Hukuki Belge | Hangi Teknik Sistem | Yayın Öncesi Zorunlu mu? | Placeholder ile Geçici Yazılabilir mi? | Hukukçuya Sorulsun mu? |
|------|-------------------|---------------------|--------------------------|----------------------------------------|------------------------|
| R-1 | Gizlilik Politikası, KVKK Aydınlatma | analytics_events tablosu, TTL job | Evet | Hayır — TTL değeri karara bağlanmadan metin yazılamaz | Hukukçuya sorulmalı (süre belirleme) |
| R-2 | Gizlilik Politikası | business_activity_log tablosu | Hayır — orta risk; yayın sonrası düzeltilebilir | Evet | Teknik ekip önce user_id içerip içermediğini doğrulamalı |
| R-3 | Gizlilik Politikası | menu_snapshots tablosu | Hayır — orta risk | Evet (`[SAKLAMA_SURESI_SNAPSHOTS]`) | Hayır — teknik karar yeterli |
| R-4 | KVKK Aydınlatma Metni, Gizlilik Politikası | user_policy_acceptances, capture_request_metadata_v1 | Evet — yayına çıkmadan IP kaydı aydınlatmada belirtilmeli | Hayır | Hukukçuya sorulmalı (KVKK md. 10 uyum) |
| R-5 | Gizlilik Politikası, Kullanım Şartları | business_follows.is_subscribed_email, UI opt-in akışı | Evet — 6563 sayılı Kanun gereği | Hayır — akış doğrulanmadan metin yazılamaz | Kritik; hukukçuya sorulmalı |
| R-6 | Gizlilik Politikası, KVKK Aydınlatma | Sentry SDK, Supabase, Firebase, Resend | Evet — KVKK md. 9 aktarım güvencesi gerekli | Hayır — güvence türü belirlenmeden yazılamaz | Hukukçuya sorulmalı (Kurul izni vs. muafiyet) |
| R-7 | Gizlilik Politikası, Kullanım Şartları | group_requests, offer_messages tabloları | Evet — aydınlatmada üçüncü taraf paylaşımı açıklanmalı | Evet (açıklayıcı bir cümle ile) | Hayır — teknik gerçek doğru aktarılırsa yeterli |
| R-8 | Gizlilik Politikası | notifications tablosu | Hayır — orta risk | Evet (`[SAKLAMA_SURESI_BILDIRIMLER]`) | Hayır |
| R-9 | KVKK Aydınlatma, Gizlilik Politikası | owner_claims tablosu | Evet — kişisel veri içeriyor, süre belirlenmeli | Hayır — süre kararlaştırılmadan yazılamaz | Hukukçuya sorulmalı |
| R-10 | Gizlilik Politikası (iOS bölümü) | iOS plist, AssistantShortcutsPlugin | Hayır — düşük risk | Evet (kısa bilgi notu) | Hayır |

---

## 5. Saklama Süresi Karar Tablosu

Bu tablo öneri değil, karar gerektiren işlem kalemidir. Her satır için "Saklama süresi kararı gerekli mi?" sütunundaki Evet'ler yayına çıkmadan çözülmeli veya placeholder ile işaretlenmelidir.

| Veri Türü | Hangi Belgede Açıklanmalı | Olası Hukuki Dayanak | Saklama Süresi Kararı Gerekli mi? | Silme / Anonimleştirme / Yasal Saklama Notu | Hukukçuya Sorulacak Soru |
|-----------|--------------------------|---------------------|-----------------------------------|----------------------------------------------|--------------------------|
| analytics_events | Gizlilik Politikası, KVKK Aydınlatma | Meşru menfaat (platform analitik) | Evet | Kullanıcı ID içerdiği için kişisel veri; anonimleştirme veya 24 ay TTL seçenekleri | "analytics_events içindeki user_id anonimleştirilerek saklanabilir mi veya TTL yeterli mi?" |
| business_activity_log | Gizlilik Politikası | Meşru menfaat | Evet — user_id içerip içermediği tekrar doğrulanmalı | user_id yoksa kişisel veri değil; varsa 12 ay TTL önerisi | "Log created_by veya user_id içeriyor mu? İçeriyorsa ne kadar süre gerekli?" |
| menu_snapshots | Gizlilik Politikası | Meşru menfaat (sürüm yönetimi) | Evet | created_by UUID içeriyor; 90 gün TTL veya işletme silme ile kademeli silme | "Snapshot'lar geri yükleme dışında başka amaçla kullanılıyor mu?" |
| user_policy_acceptances | KVKK Aydınlatma, Gizlilik Politikası | Yasal yükümlülük (ispat) | Evet — KVKK ispat için ne kadar tutulmalı? | Hesap silinmesi + en az 3 yıl arşiv önerisi; IP adresi daha kısa tutulabilir | "KVKK ispat yükümlülüğü kapsamında kabul kaydının saklanması için alt sınır var mı?" |
| Destek mesajları / gizlilik başvuruları (privacy_requests) | KVKK Aydınlatma, Gizlilik Politikası | Yasal yükümlülük | Evet | KVKK md. 11 başvuruları idari işlem; 5 yıl arşiv ihtiyatla önerilir | "İdari başvuru kayıtları için zorunlu saklama süresi var mı?" |
| Kullanıcı yorumları (reviews) | Gizlilik Politikası, Kullanım Şartları | Açık rıza / sözleşme ifası | Evet — kullanıcı silme talebi işlendiğinde ne olur? | Seçenek 1: Tamamen sil. Seçenek 2: Yorumu anonim bırak (puan kalsın). Hukukçuya sorulmalı | "Kullanıcı verisi silindiğinde yorumlar anonim mi kalabilir yoksa tamamen silinmeli mi?" |
| Favoriler | Gizlilik Politikası | Sözleşme ifası | Hayır — hesap silinince silmek yeterli | CASCADE sil yeterli; hukuki risk düşük | — |
| Konum verisi (şehir/ilçe tercihi) | KVKK Aydınlatma, Gizlilik Politikası | Açık rıza | Evet — kullanıcı rıza geri alırsa ne olur? | Kullanıcı ayarlardan silebilmeli; mevcut CRUD fonksiyonu var | "Konum rızası geri alındığında sistem otomatik siliyor mu?" |
| Cihaz / push token (user_devices) | Gizlilik Politikası, KVKK Aydınlatma | Açık rıza | Hayır — 120 gün TTL mevcut; uygun | 120 gün hareketsizlikte otomatik silme uygulanmış; kabul edilebilir | — |
| İşletme sahipliği başvuruları (owner_claims) | KVKK Aydınlatma, Gizlilik Politikası | Sözleşme ifası / yasal yükümlülük | Evet — red kararı sonrası ne kadar saklanmalı? | Ad, telefon, kanıt belgesi içeriyor; 1 yıl sonra silme önerisi ama hukuki zorunluluk belirsiz | "Reddedilen sahiplik başvurularında saklama zorunluluğu var mı (ticaret hukuku, vergi)?" |

---

## 6. Mesafeli Satış Sözleşmesi Gerekliliği Değerlendirmesi

**Mevcut durum:** Envanter incelemesinde `sponsorship_packages`, `sponsorships` ve `business_premium` tabloları mevcut; ancak ödeme akışının canlıya alınıp alınmadığı belirsizdir.

| Senaryo | Mesafeli Satış Sözleşmesi Gerekli mi? |
|---------|---------------------------------------|
| Uygulamada yalnızca ücretsiz kullanıcı özellikleri aktif | Hayır |
| Sponsorluk lead formu aktif ama ödeme UI'ı yok | Hayır — ancak kullanım şartlarında sponsorluk başvurusunun ön teklif niteliğinde olduğu belirtilmeli |
| Sponsorluk paketleri fiyatlandırılmış ve ödeme akışı canlı | Evet — 6502 sayılı Tüketicinin Korunması Hakkında Kanun ve Mesafeli Sözleşmeler Yönetmeliği kapsamında; cayma hakkı, ön bilgilendirme formu zorunlu |
| İşletme sahipleri için ücretli premium/abonelik aktif | Evet — aynı yasal çerçeve |

**Sonuç:** Ödeme ve abonelik sistemi aktif değilse Mesafeli Satış Sözleşmesi şu an hazırlanmak zorunda değildir. Ancak sponsorluk paketi veya premium özellik satışa açılmadan en az 2 hafta önce hazırlanmış olmalıdır.

**Hukukçuya sorulacak:** "B2B işletme sahiplerine satılan reklam paketleri tüketici mi sayılır yoksa ticari müşteri mi? Bu ayrım cayma hakkını etkiler."

---

## 7. Final Metinlerde Kullanılacak Placeholder Listesi

Aşağıdaki placeholder'lar tüm belgelerde tutarlı şekilde kullanılmalı ve yayın öncesinde doldurulmalıdır.

### Kimlik Bilgileri

```
[VERI_SORUMLUSU_UNVANI]         — Gerçek veya tüzel kişi adı
[TICARI_UNVAN]                  — Varsa şirket ticari unvanı
[ADRES]                         — Kayıtlı iş adresi (sokak, şehir, posta kodu)
[VERGI_NO]                      — Vergi numarası
[MERSIS_NO]                     — MERSİS numarası (şirket varsa)
[DESTEK_EPOSTA]                 — Genel destek e-posta adresi
[KVKK_BASVURU_EPOSTA]           — KVKK başvuruları için özel e-posta
[TELEFON]                       — İletişim telefon numarası (isteğe bağlı)
[YURURLUK_TARIHI]               — Politikaların yürürlüğe girdiği tarih
```

### Üçüncü Taraf Durumları

```
[SUPABASE_DPA_DURUMU]           — "DPA imzalanmıştır" / "DPA sürecindedir" / "Supabase standart DPA geçerlidir"
[GOOGLE_DPA_DURUMU]             — Google Cloud/Firebase DPA durumu
[RESEND_DPA_DURUMU]             — Resend veri işleme sözleşme durumu
[SENTRY_DPA_DURUMU]             — Sentry DPA / SCCs durumu
[SMS_SAGLAYICI_ADI]             — Twilio / MessageBird / diğer
[SMS_SAGLAYICI_DPA_DURUMU]      — SMS sağlayıcı DPA durumu
[YURT_DISI_AKTARIM_DURUMU]      — KVKK Kurulu kararı / muafiyet / SCCs durumu
```

### Saklama Süreleri

```
[SAKLAMA_SURESI_ANALYTICS]      — analytics_events için karar verilen süre (örn. "24 ay")
[SAKLAMA_SURESI_ACTIVITY_LOG]   — business_activity_log için karar verilen süre
[SAKLAMA_SURESI_SNAPSHOTS]      — menu_snapshots için karar verilen süre
[SAKLAMA_SURESI_BILDIRIMLER]    — notifications için karar verilen süre
[SAKLAMA_SURESI_OWNER_CLAIMS]   — owner_claims için karar verilen süre
[SAKLAMA_SURESI_DESTEK]         — privacy_requests için karar verilen süre
[SAKLAMA_SURESI_YORUMLAR]       — reviews için silme / anonimleştirme kararı
[SAKLAMA_SURESI_KABUL_KAYDI]    — user_policy_acceptances için arşiv süresi
```

### Sistem ve Akış Durumları

```
[PAZARLAMA_OPTIN_AKIS_DURUMU]   — Opt-in akışı teyit edildi mi?
[CEREZ_BANNER_DURUMU]           — Web çerez banner var mı / planlanıyor mu?
[ODEME_SISTEMI_DURUMU]          — Ödeme sistemi aktif mi, hangi sağlayıcı?
[REKLAM_PAKETI_DURUMU]          — Sponsorluk paketi satışa açık mı?
[YAS_SINIRI]                    — Minimum kullanım yaşı (örn. "13" veya "18")
```

---

## 8. Sonraki Adım Önerisi — Yazım Sırası

Final hukuki metinler aşağıdaki sırayla yazılmalıdır. Bu sıra bağımlılık ilişkisine ve hukuki öneme göre belirlenmiştir.

| Sıra | Belge | Neden Bu Sırada? | Ön Koşul |
|------|-------|-----------------|----------|
| 1 | KVKK Aydınlatma Metni | Tüm diğer belgelerin temelini oluşturuyor; hangi verilerin toplandığı burada netleşince diğer belgeler tutarlı yazılabiliyor | E-1 ila E-6 placeholder'ları doldurulmalı; R-4, R-6 riskleri hukukçuya danışılmalı |
| 2 | Gizlilik Politikası | Aydınlatma metninden türetiliyor; üçüncü taraf DPA durumları ve yurt dışı aktarım kararları belli olduktan sonra yazılmalı | E-8 ila E-13 placeholder'ları doldurulmalı; R-1, R-5, R-6 çözülmeli |
| 3 | Kullanım Şartları | Hizmet kapsamı ve kullanıcı yükümlülükleri tanımlı olmalı; içerik lisansı kararı verilmeli | Gizlilik Politikası taslağı hazır olmalı; R-5, R-7 aydınlatılmalı |
| 4 | Veri Silme Talebi | Teknik süreç (account_deletion_requests akışı) netleşmeli; aydınlatma metni tamamlanmış olmalı | VS-2 ila VS-6 teknik kararları verilmeli |
| 5 | Çerez Politikası | Web tarafının çerez envanteri teknik ekipten alınmalı; banner kararı verilmeli | E-15 doldurulmalı; çerez envanteri çıkarılmalı |
| 6 | Telif Hakkı Politikası | Kullanım Şartları'ndaki içerik lisansı maddesi tamamlandıktan sonra yazılmalı | policy_versions'daki `dmca`, `copyright`, `ai`, `dsa` türleri için içerik kararları |
| 7 | Mesafeli Satış Sözleşmesi | Yalnızca ödeme / abonelik / reklam paketi satışa açılacağında yazılmalı | E-16, E-17 doldurulmalı; hukukçu B2B/B2C ayrımını netleştirmeli |
| 8 | Yasal Destek Metni | Diğer belgeler tamamlandıktan sonra başvuru kanallarını ve SLA taahhütlerini özetleyen son belge | Tüm iletişim placeholder'ları doldurulmalı |

---

**Son not:** Bu rapor Yeedoy projesinin legal-data-inventory.md dosyasındaki teknik tespitlere dayanılarak hazırlanmıştır. Kritik ve Yüksek risk sınıfındaki maddelerin tamamı (R-1, R-4, R-5, R-6, R-9 ve E-1 ila E-6, E-8 ila E-14) yayına çıkmadan önce Türkiye'de lisanslı bir avukat veya KVKK danışmanlığı yapan bir hukuk bürosu tarafından onaylanmalıdır. Bu belge hukuki görüş niteliği taşımaz.
