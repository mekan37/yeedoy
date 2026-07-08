# Yeedoy Hukuki Belgeler — Placeholder Envanteri ve Doldurma Planı

**Hazırlayan:** koordinatör (tam belge taraması)  
**Tarih:** 2026-06-19  
**Kapsam:** 6 ana hukuki belge — KVKK Aydınlatma Metni, Gizlilik Politikası, Çerez Politikası, Veri Silme Talebi, Kullanım Şartları, Telif Hakkı Politikası  
**Toplam benzersiz placeholder:** 41  
**Yayın öncesi zorunlu:** 39  
**Opsiyonel:** 2 (`[TICARI_UNVAN]`, `[CEREZ_POLITIKASI_BAGLANTISI]`)

---

> **Kullanım notu:** Aynı placeholder birden fazla belgede geçiyorsa tek satırda birleştirilmiştir. Bir değer belirlendikten sonra tüm belgeler aynı anda güncellenmelidir. `[HUKUKCU_KONTROLU]` etiketi taşıyan maddeler hukukçudan yazılı görüş alınmadan kesinleştirilemez.

---

## Kısaltmalar

| Kısaltma | Dosya |
|---|---|
| KVKK | `kvkk-aydinlatma-metni.md` |
| Gizlilik | `gizlilik-politikasi.md` |
| Çerez | `cerez-politikasi.md` |
| VSD | `veri-silme-talebi.md` |
| KŞ | `kullanim-sartlari.md` |
| TH | `telif-hakki-politikasi.md` |

---

## Grup 1 — Şirket ve Kimlik Bilgileri

*Tüzel kişilik tescil bilgileri. Ticaret Sicili ve Türkiye Cumhuriyeti kayıtlarından alınır. **Kurucu / işletme sorumlusu doldurur.***

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 1 | `[SIRKET_UNVANI]` | KŞ, TH | Şirkete ait resmi ticaret sicil unvanı | Kullanıcı | 🔴 Kritik | Evet |
| 2 | `[VERI_SORUMLUSU_UNVANI]` | KVKK, Gizlilik, Çerez | KVKK kapsamında kayıt edilmiş veri sorumlusu unvanı (genellikle şirket unvanıyla aynı) | Kullanıcı | 🔴 Kritik | Evet |
| 3 | `[TICARI_UNVAN]` | KVKK, Gizlilik | Varsa ayrı ticari unvan (marka adı). Yoksa sütun boş bırakılabilir veya silinebilir. | Kullanıcı | 🟡 Orta | Hayır (opsiyonel) |
| 4 | `[VERGI_NO]` | KVKK, KŞ, TH | 10 haneli vergi kimlik numarası | Kullanıcı | 🔴 Kritik | Evet |
| 5 | `[MERSIS_NO]` | KVKK, KŞ | MERSİS kayıt numarası (mersis.gtb.gov.tr'den) | Kullanıcı | 🔴 Kritik | Evet |
| 6 | `[ADRES]` | KVKK, Gizlilik, KŞ, TH, VSD | Ticaret siciline kayıtlı tam yazışma adresi | Kullanıcı | 🔴 Kritik | Evet |
| 7 | `[YURURLUK_TARIHI]` | **Tüm 6 belge** | Belgelerin yayına alındığı tarih (GG.AA.YYYY) | Kullanıcı | 🔴 Kritik | Evet |

---

## Grup 2 — İletişim Bilgileri

*Kullanıcıya yönelik iletişim kanalları. Posta kutuları veya mevcut adresler belirlenerek doldurulur. **Kurucu / operasyon ekibi doldurur.***

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 8 | `[DESTEK_EPOSTA]` | KVKK, Gizlilik, KŞ, TH, VSD, Çerez | Genel kullanıcı destek e-posta adresi (ör. destek@yeedoy.com) | Kullanıcı | 🔴 Kritik | Evet |
| 9 | `[KVKK_BASVURU_EPOSTA]` | KVKK, Gizlilik, KŞ, VSD, Çerez | KVKK başvuruları için ayrılmış e-posta adresi (ör. kvkk@yeedoy.com) | Kullanıcı | 🔴 Kritik | Evet |
| 10 | `[TELEFON]` | KVKK, Gizlilik, KŞ | İletişim telefon numarası | Kullanıcı | 🟠 Yüksek | Evet |
| 11 | `[WEB_SITESI]` | **Tüm 6 belge** | Platformun tam alan adı (ör. https://yeedoy.com) | Kullanıcı | 🔴 Kritik | Evet |
| 12 | `[TELIF_BILDIRIM_EPOSTA]` | TH | Telif hakkı ihlal bildirimleri için özel e-posta adresi (ör. telif@yeedoy.com). Genel destek adresinden ayrı tutulması önerilir. | Kullanıcı | 🟠 Yüksek | Evet |
| 13 | `[YETKILI_BIRIM]` | TH | Telif hakkı ve içerik şikâyetlerinden sorumlu iç birim veya kişi unvanı (ör. "Hukuk ve Uyum Birimi") | Kullanıcı | 🟡 Orta | Evet |
| 14 | `[EMAIL_EKLENECEK]` (2 adet) | Çerez | Çerez Politikası Bölüm 7 ve 8'deki iletişim e-posta alanları. `[DESTEK_EPOSTA]` veya `[KVKK_BASVURU_EPOSTA]` ile doldurulabilir. | Kullanıcı | 🟠 Yüksek | Evet |
| 15 | `[URL_EKLENECEK]` (3 adet) | Çerez | Çerez Politikası Bölüm 5'teki tarayıcı çerez ayarları yardım sayfaları (Chrome, Firefox, Safari linkleri). Tarayıcı üreticilerin güncel destek sayfaları kullanılabilir. | Kullanıcı | 🟡 Orta | Evet |
| 16 | `[CEREZ_POLITIKASI_BAGLANTISI]` | KVKK | KVKK Aydınlatma Metni Bölüm 3.9'daki çerez politikası linki. `[WEB_SITESI]/cerez-politikasi` olarak türetilebilir. | Kullanıcı | 🟡 Orta | Hayır (`[WEB_SITESI]` doldurulunca otomatik türer) |

---

## Grup 3 — DPA ve Yurt Dışı Aktarım

*KVKK md. 9 kapsamında üçüncü ülkelere yapılan veri aktarımlarının hukuki güvencesi. Her sağlayıcının DPA (Veri İşleme Anlaşması) ve SCCs (Standart Sözleşme Maddeleri) durumu hukukçu tarafından doğrulanmalıdır. **Hukukçu + kullanıcı birlikte doldurur.***

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 17 | `[SUPABASE_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Supabase Inc. ile DPA imzalandı mı? Supabase AB bölgesinde çalışıyor; SCCs / KVKK muadili güvence var mı? | Hukukçu + Kullanıcı | 🔴 Kritik | Evet |
| 18 | `[FIREBASE_DPA_DURUMU]` | KVKK (×3), Gizlilik, VSD | Google Cloud / Firebase DPA imzalandı mı? Crashlytics, Analytics ve Performance için ABD aktarım güvencesi (SCCs) doğrulandı mı? KVKK kapsamında geçerli mi? | Hukukçu + Kullanıcı | 🔴 Kritik | Evet |
| 19 | `[ADMOB_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Google AdMob DPA durumu; iOS ATT izin akışı aktif mi; Android Advertising ID / IDFA aktarımı için KVKK güvencesi var mı? | Hukukçu + Kullanıcı | 🔴 Kritik | Evet |
| 20 | `[RESEND_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Resend Inc. ile DPA imzalandı mı? ABD merkezli; e-posta adresi aktarımı için SCCs var mı? | Hukukçu + Kullanıcı | 🔴 Kritik | Evet |
| 21 | `[SMS_SAGLAYICI_DPA_DURUMU]` | KVKK, Gizlilik | SMS OTP sağlayıcısı (Twilio / MessageBird) ile DPA var mı? Telefon numarası aktarımı için güvence | Hukukçu + Kullanıcı | 🔴 Kritik | Evet |
| 22 | `[YURT_DISI_AKTARIM_DURUMU]` | KVKK (×5), Gizlilik (×5), VSD | Her sağlayıcı için KVKK md. 9 güvencesinin özeti: "SCCs imzalandı", "Kurul kararı kapsamında", "muafiyet" veya "imzalanmadı [HUKUKCU_KONTROLU]". Her sağlayıcı için ayrı satır doldurulacak. | Hukukçu | 🔴 Kritik | Evet |

---

## Grup 4 — Saklama Süreleri

*KVKK md. 4/2-e uyarınca her veri kategorisi için belirli saklama süreleri zorunludur. **Hukukçu karar verir; geliştirici teknik uygulamayı doğrular.***

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 23 | `[SAKLAMA_SURESI_HESAP]` | VSD | Hesap verileri (profil, e-posta, telefon) için hesap silinmesinin ardından saklanma süresi | Hukukçu | 🔴 Kritik | Evet |
| 24 | `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | KVKK, Gizlilik, VSD | Yorumlar, favoriler, check-in; hesap silindiğinde anonim mi kalacak yoksa silinecek mi kararı + süre | Hukukçu | 🔴 Kritik | Evet |
| 25 | `[SAKLAMA_SURESI_KONUM]` | VSD | Şehir/ilçe tercihi ve fiyat uyarısı konum bilgisi | Hukukçu | 🟠 Yüksek | Evet |
| 26 | `[SAKLAMA_SURESI_DESTEK]` | KVKK, Gizlilik, VSD | Destek talepleri ve KVKK başvuruları için idari kayıt saklama süresi (hukuki önerimiz: min. 3–5 yıl) | Hukukçu | 🔴 Kritik | Evet |
| 27 | `[SAKLAMA_SURESI_POLICY_ACCEPTANCE]` | KVKK, Gizlilik, VSD | Politika kabul kayıtları — KVKK ispat yükümlülüğü kapsamında; hesap silinmesinden sonra ne kadar saklanacak? | Hukukçu | 🔴 Kritik | Evet |
| 28 | `[SAKLAMA_SURESI_OWNER_CLAIMS]` | KVKK, Gizlilik, VSD | İşletme sahipliği başvuruları (ad, telefon, kanıt belge) — karar tarihinden itibaren süre | Hukukçu | 🟠 Yüksek | Evet |
| 29 | `[SAKLAMA_SURESI_MARKETING_CONSENT]` | KVKK, Gizlilik, VSD | Pazarlama izin kayıtları (opt-in zamanı, opt-out geçmişi) — 6563 sayılı Kanun ispat yükümlülüğü kapsamında | Hukukçu | 🔴 Kritik | Evet |
| 30 | `[SAKLAMA_SURESI_LOGS]` | KVKK, Gizlilik, VSD | Sunucu ve güvenlik logları (teknik önerimiz: 30 gün; yasal sınır hukukçuya sorulacak) | Hukukçu | 🟠 Yüksek | Evet |
| 31 | `[SAKLAMA_SURESI_ANALYTICS]` | KVKK, Gizlilik, VSD | Analitik olay logu (`analytics_events`) — user_id içerdiğinden anonimleştirme veya silme kararı + süre (teknik önerimiz: 24 ay) | Hukukçu | 🔴 Kritik | Evet |
| 32 | `[SAKLAMA_SURESI_BILDIRIMLER]` | KVKK, Gizlilik, VSD | Bildirim içeriği (`notifications` tablosu) — okunan bildirimler için saklama süresi (teknik önerimiz: okundu + 30 gün) | Hukukçu | 🟠 Yüksek | Evet |
| 33 | `[SAKLAMA_SURESI_YASAL_AUDIT]` | VSD | Politika sürüm kataloğu ve değiştirilemez audit kayıtları — önerimiz süresiz arşiv; hukukçu onaylamalı | Hukukçu | 🟡 Orta | Evet |

---

## Grup 5 — Servis Sağlayıcı Bilgileri

*Üçüncü taraf entegrasyon kimlik bilgileri. Teknik ekip veya kurucudan alınır.*

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 34 | `[SMS_SAGLAYICI_ADI]` | KVKK, Gizlilik, KŞ | OTP/SMS gönderimleri için kullanılan sağlayıcının ticari adı (Twilio / MessageBird / Netgsm / başka?) | Kullanıcı | 🔴 Kritik | Evet |
| 35 | `[SMS_SAGLAYICI_KONUM]` | KŞ | SMS sağlayıcısının şirket merkezi / veri merkezi ülkesi (ör. "ABD", "AB/Almanya") | Kullanıcı | 🟠 Yüksek | Evet |
| 36 | `[HOSTING_SAGLAYICI]` | Gizlilik | Web / API deployment altyapısı sağlayıcısının adı (Vercel? AWS? Supabase Edge? Başka?) — CDN dahil | Kullanıcı + Geliştirici | 🟠 Yüksek | Evet |

---

## Grup 6 — Hukukçu Kararı Gerekenler

*Bu değerler tahmin edilemez; bir hukuk danışmanından yazılı görüş alınmadan kesinleştirilemez. **Hukukçu doldurur.***

| # | Placeholder | Geçtiği belgeler | Ne bilgi gerekiyor? | Kim doldurur? | Öncelik | Yayın öncesi zorunlu? |
|---|---|---|---|---|---|---|
| 37 | `[YAS_SINIRI]` | KVKK, Gizlilik, KŞ | Platformun minimum kullanım yaşı. 18 olarak belirlenirse Çocukların Gizliliği belgesi gerekmez; daha düşükse ebeveyn rızası mekanizması tasarlanmalı. | Hukukçu | 🔴 Kritik | Evet |
| 38 | `[HAREKETSIZLIK_SURESI]` | KŞ | Hesap kapama gerekçesi olarak kullanılacak pasiflik süresi (ör. "24 ay"). Yasal bir üst sınır var mı hukukçuya sorulmalı. | Hukukçu | 🟡 Orta | Evet |
| 39 | `[UYUSMAZLIK_YETKILI_MAHKEME]` | KŞ | Uyuşmazlık çözümünde yetkili mahkeme yeri (ör. "İstanbul"). Tüketici işlemleri için satıcı merkezli yetki kaydının geçerli olup olmadığı 6502 md. 73 kapsamında değerlendirilmeli. | Hukukçu | 🟠 Yüksek | Evet |
| 40 | `[BILDIRIM_YANIT_SURESI]` | TH | Telif hakkı bildirimlerine yanıt süresi (iş günü olarak — ör. "5 iş günü"). FSEK'teki yasal üst sınır hukukçu tarafından belirlenmeli. | Hukukçu | 🟠 Yüksek | Evet |
| 41 | `[ICERIK_SIKAYET_MEKANIZMASI]` | KŞ | Kullanıcıların kurallara aykırı içerikleri bildireceği mekanizma: uygulama içi "Bildir" butonu mu, e-posta formu mu? 5651 sayılı Kanun kapsamı netleştirilmeli. | Hukukçu + Geliştirici | 🟠 Yüksek | Evet |

---

## Doldurma Planı ve Sıralama

### Adım 1 — Kurucunun tek oturumda doldurduğu değerler (Grup 1 + 2)

Aşağıdakileri belirleyip tüm belgelere aynı anda uygulanabilir:

```
[SIRKET_UNVANI]           = ?
[VERI_SORUMLUSU_UNVANI]   = ?        (çoğunlukla aynı)
[TICARI_UNVAN]            = ?        (yoksa silinebilir)
[VERGI_NO]                = ?
[MERSIS_NO]               = ?
[ADRES]                   = ?
[YURURLUK_TARIHI]         = __.__.20__
[DESTEK_EPOSTA]           = ?
[KVKK_BASVURU_EPOSTA]     = ?
[TELEFON]                 = ?
[WEB_SITESI]              = https://___________
[TELIF_BILDIRIM_EPOSTA]   = ?
[YETKILI_BIRIM]           = ?
[SMS_SAGLAYICI_ADI]       = ?        (Twilio / MessageBird / Netgsm / ?)
[SMS_SAGLAYICI_KONUM]     = ?
[HOSTING_SAGLAYICI]       = ?        (Vercel / AWS / ?)
[EMAIL_EKLENECEK] (Çerez) = [DESTEK_EPOSTA] veya [KVKK_BASVURU_EPOSTA]
[URL_EKLENECEK] (3 adet)  = Chrome, Firefox, Safari çerez ayarları linkleri
[CEREZ_POLITIKASI_BAGLANTISI] = [WEB_SITESI]/cerez-politikasi  (türetilebilir)
```

---

### Adım 2 — Hukukçuya öncelikli sorular (Grup 3 + 6)

Hukukçudan yazılı görüş alınacak maddeler, önem sırasına göre:

1. **DPA imzalama kararı** — Supabase, Firebase/Google, AdMob, Resend, SMS sağlayıcısı için DPA + SCCs durumu (`[*_DPA_DURUMU]` ve `[YURT_DISI_AKTARIM_DURUMU]`)
2. **`[YAS_SINIRI]`** — 18 altı kabul edilecek mi; yaş doğrulama mekanizması zorunlu mu?
3. **`[UYUSMAZLIK_YETKILI_MAHKEME]`** — Tüketici işlemlerinde yetki kaydı geçerli mi?
4. **`[BILDIRIM_YANIT_SURESI]`** — FSEK kapsamında azami yanıt süresi
5. **`[ICERIK_SIKAYET_MEKANIZMASI]`** — 5651 kapsamı ve teknik yükümlülük
6. **`[HAREKETSIZLIK_SURESI]`** — Yasal üst sınır var mı?

---

### Adım 3 — Saklama süreleri (Grup 4)

Hukukçu aşağıdaki kararları verdikten sonra belgelere yansıtılır:

| Placeholder | Teknik Öneri | Hukukçu Kararı |
|---|---|---|
| `[SAKLAMA_SURESI_HESAP]` | Hesap silinene kadar | ? |
| `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | Silme veya anonimleştirme | ? |
| `[SAKLAMA_SURESI_KONUM]` | Hesap silme ile birlikte | ? |
| `[SAKLAMA_SURESI_DESTEK]` | Min. 3–5 yıl | ? |
| `[SAKLAMA_SURESI_POLICY_ACCEPTANCE]` | Hesap + 3 yıl | ? |
| `[SAKLAMA_SURESI_OWNER_CLAIMS]` | Karar tarihi + 1 yıl | ? |
| `[SAKLAMA_SURESI_MARKETING_CONSENT]` | 6563 kapsamı (min. 3 yıl önerisi) | ? |
| `[SAKLAMA_SURESI_LOGS]` | 30 gün | ? |
| `[SAKLAMA_SURESI_ANALYTICS]` | 24 ay (+ anonimleştirme) | ? |
| `[SAKLAMA_SURESI_BILDIRIMLER]` | Okundu + 30 gün | ? |
| `[SAKLAMA_SURESI_YASAL_AUDIT]` | Süresiz arşiv | ? |

---

## Placeholder Sayısal Özet

| Grup | Placeholder sayısı | Sorumlu |
|---|---|---|
| 1 — Şirket/Kimlik | 7 | Kullanıcı |
| 2 — İletişim | 9 | Kullanıcı |
| 3 — DPA/Aktarım | 6 | Hukukçu + Kullanıcı |
| 4 — Saklama Süreleri | 11 | Hukukçu |
| 5 — Servis Sağlayıcı | 3 | Kullanıcı + Geliştirici |
| 6 — Hukukçu Kararı | 5 | Hukukçu |
| **Toplam** | **41** | |

---

## Belge Başına Geçen Placeholder Sayısı

| Belge | Benzersiz placeholder sayısı |
|---|---|
| KVKK Aydınlatma Metni | 28 |
| Gizlilik Politikası | 27 |
| Kullanım Şartları | 17 |
| Veri Silme Talebi | 22 |
| Çerez Politikası | 9 |
| Telif Hakkı Politikası | 11 |

*Not: Aynı placeholder birden fazla belgede geçtiğinden belge başına sayılar toplamı 41'i aşar.*

---

*Bu envanter yalnızca doldurma planı niteliğindedir. Placeholder değerleri belirlenmeden hukuki belgelerin yayınlanması yasak veya yanıltıcı metin içermesine yol açar. Değerler belirlendikten sonra tüm belgeler aynı anda güncellenmeli ve `[YURURLUK_TARIHI]` set edilmelidir.*
