# Yeedoy Hukuki Belgeler — Kurucu Giriş Formu

**Hazırlayan:** koordinatör  
**Tarih:** 2026-06-19  
**Amaç:** Hukuki belgelerdeki kurucu/operasyon sorumluluğundaki tüm placeholder'ları tek formda toplar.

---

> **Nasıl kullanılır:**
> 1. Bu formdaki her alanı "Değeriniz" sütununa doldurun.
> 2. Doldurulmuş formu geliştirici veya içerik editörüne verin; 6 belge tek seferde güncellensin.
> 3. `[YURURLUK_TARIHI]` en son belirlenmeli — diğer tüm alanlar ve hukukçu görüşleri tamamlandıktan sonra set edin.
> 4. Bu formdaki alanlar tamamlanmadan hukukçudan görüş alınan alanlar bile yayına alınamaz.

---

> **Bu formda YER ALMAYAN alanlar** (hukukçu kararı gerekiyor):
> DPA / yurt dışı aktarım, saklama süreleri ve hukukçu kararı gereken placeholder'lar bu forma dahil edilmemiştir.
> Bunların listesi bu belgenin sonundaki **Ek A — Hukukçuya Kalacak Alanlar** bölümündedir.

---

## Bölüm 1 — Şirket ve Kimlik Bilgileri

*Kaynak: Türk Ticaret Sicili, Gelir İdaresi Başkanlığı, MERSİS portali.*

---

### F-01 — Şirket Unvanı

| Alan | Değer |
|---|---|
| **Placeholder** | `[SIRKET_UNVANI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Örnek Teknoloji Anonim Şirketi` |
| **Açıklama** | Ticaret siciline tescil edilmiş tam yasal unvan. MERSİS veya ticaret sicil gazetesinden alınır. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Kullanım Şartları, Telif Hakkı Politikası |

---

### F-02 — Veri Sorumlusu Unvanı

| Alan | Değer |
|---|---|
| **Placeholder** | `[VERI_SORUMLUSU_UNVANI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Örnek Teknoloji Anonim Şirketi` |
| **Açıklama** | KVKK kapsamında VERBİS'e kayıtlı veri sorumlusu unvanı. Çoğunlukla `[SIRKET_UNVANI]` ile aynıdır; farklıysa ayrı yazın. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Çerez Politikası |

---

### F-03 — Ticari Unvan / Marka Adı

| Alan | Değer |
|---|---|
| **Placeholder** | `[TICARI_UNVAN]` |
| **Değeriniz** | ________________________________________ (yoksa boş bırakın) |
| **Örnek format** | `Yeedoy` |
| **Açıklama** | Yasal unvandan farklı kullanılan marka/ticari adı. Ayrı tescilli ticari unvan yoksa bu alanı boş bırakın; ilgili tablo satırı belgeden silinebilir. |
| **Zorunlu** | Hayır (opsiyonel) |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası |

---

### F-04 — Vergi Kimlik Numarası

| Alan | Değer |
|---|---|
| **Placeholder** | `[VERGI_NO]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `1234567890` (10 hane, rakam) |
| **Açıklama** | Gelir İdaresi Başkanlığı'ndan alınan 10 haneli kurumlar vergisi numarası. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Kullanım Şartları, Telif Hakkı Politikası |

---

### F-05 — MERSİS Numarası

| Alan | Değer |
|---|---|
| **Placeholder** | `[MERSIS_NO]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `0123456789012345` (16 hane, mersis.gtb.gov.tr'den) |
| **Açıklama** | Merkezi Sicil Kayıt Sistemi numarası. mersis.gtb.gov.tr adresinden sorgulanır. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Kullanım Şartları |

---

### F-06 — Kayıtlı Adres

| Alan | Değer |
|---|---|
| **Placeholder** | `[ADRES]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Örnek Mahallesi, Örnek Sokak No:1 Kat:2 Daire:3, Beşiktaş / İstanbul 34349` |
| **Açıklama** | Ticaret siciline kayıtlı tam yazışma adresi. Posta kodu dahil. Kullanıcıların KVKK başvurusunu elden veya posta ile iletebileceği adres olmalı. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları, Telif Hakkı Politikası, Veri Silme Talebi |

---

### F-07 — Yürürlük Tarihi

| Alan | Değer |
|---|---|
| **Placeholder** | `[YURURLUK_TARIHI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `01.07.2026` (GG.AA.YYYY) |
| **Açıklama** | Belgelerin canlıya alındığı tarih. **En son doldurulmalı** — diğer tüm alanlar ve hukukçu görüşleri tamamlandıktan sonra belirleyin. Tüm 6 belgede aynı değer kullanılır. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | **Tüm 6 belge** |

---

## Bölüm 2 — İletişim Kanalları

*E-posta adreslerini yayına geçmeden önce test edin; gelen e-postaları düzenli izleyin.*

---

### F-08 — Genel Destek E-postası

| Alan | Değer |
|---|---|
| **Placeholder** | `[DESTEK_EPOSTA]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `destek@yeedoy.com` |
| **Açıklama** | Kullanıcı destek talepleri, hesap sorunları ve genel sorular için birincil e-posta adresi. Belgede KVKK başvuruları dışındaki tüm kullanıcı iletişimi için bu adres gösterilir. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları, Telif Hakkı Politikası, Veri Silme Talebi, Çerez Politikası |

---

### F-09 — KVKK Başvuru E-postası

| Alan | Değer |
|---|---|
| **Placeholder** | `[KVKK_BASVURU_EPOSTA]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `kvkk@yeedoy.com` |
| **Açıklama** | Yalnızca KVKK md. 11 kapsamındaki başvurular (erişim, düzeltme, silme, itiraz) için ayrılan e-posta. `[DESTEK_EPOSTA]`'dan farklı bir adres olması önerilir; KVKK Kurul'u ayrı bir kanalın varlığını olumlu değerlendiriyor. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları, Veri Silme Talebi, Çerez Politikası |

---

### F-10 — Telefon Numarası

| Alan | Değer |
|---|---|
| **Placeholder** | `[TELEFON]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `+90 (212) 000 00 00` veya `+90 530 000 00 00` |
| **Açıklama** | Şirket iletişim telefonu. KVKK Aydınlatma Metni ve Gizlilik Politikası'ndaki veri sorumlusu bilgi tablosunda gösterilir. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları |

---

### F-11 — Web Sitesi Adresi

| Alan | Değer |
|---|---|
| **Placeholder** | `[WEB_SITESI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `https://yeedoy.com` |
| **Açıklama** | Protokol dahil tam alan adı. Bu değer tüm belgelerdeki yasal sayfaların URL'ini oluşturmak için kullanılır (`[WEB_SITESI]/gizlilik-politikasi` vb.). Sonda `/` olmadan yazın. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | **Tüm 6 belge** |

---

### F-12 — Telif Hakkı Bildirim E-postası

| Alan | Değer |
|---|---|
| **Placeholder** | `[TELIF_BILDIRIM_EPOSTA]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `telif@yeedoy.com` veya `copyright@yeedoy.com` |
| **Açıklama** | 5846 sayılı FSEK kapsamındaki telif hakkı ihlal bildirimlerine ayrılmış e-posta. `[DESTEK_EPOSTA]`'dan bağımsız bir adres oluşturun; gelen bildirimleri düzenli izleyecek bir kişi atayın. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Telif Hakkı Politikası |

---

### F-13 — Yetkili Birim Adı

| Alan | Değer |
|---|---|
| **Placeholder** | `[YETKILI_BIRIM]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Hukuk ve Uyum Birimi` veya `İçerik Moderasyon Ekibi` veya kişi adı |
| **Açıklama** | Telif hakkı ve içerik şikâyetlerini inceleyen iç birim veya sorumlunun unvanı. Henüz ayrı bir birim yoksa kurucu adı veya genel bir unvan kullanılabilir. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Telif Hakkı Politikası |

---

### F-14 — Çerez Politikası İletişim E-postaları

| Alan | Değer |
|---|---|
| **Placeholder** | `[EMAIL_EKLENECEK]` (Çerez Politikası'nda 2 adet) |
| **Değeriniz — 1. kullanım (genel iletişim)** | ________________________________________ |
| **Değeriniz — 2. kullanım (KVKK başvuru)** | ________________________________________ |
| **Örnek format** | 1. kullanım: `[DESTEK_EPOSTA]` değeriyle aynı · 2. kullanım: `[KVKK_BASVURU_EPOSTA]` değeriyle aynı |
| **Açıklama** | Çerez Politikası Bölüm 7 ve 8'deki iletişim e-postası alanları. F-08 ve F-09'da belirlenen değerlerin burada tekrarlanması yeterlidir. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Çerez Politikası |

---

### F-15 — Tarayıcı Çerez Ayarları Bağlantıları

| Alan | Değer |
|---|---|
| **Placeholder** | `[URL_EKLENECEK]` (Çerez Politikası'nda 3 adet) |
| **Değeriniz — Chrome** | ________________________________________ |
| **Değeriniz — Firefox** | ________________________________________ |
| **Değeriniz — Safari** | ________________________________________ |
| **Örnek format** | Tarayıcı üreticisinin güncel yardım sayfası URL'i. Örnek yapı: `https://support.google.com/chrome/...` |
| **Açıklama** | Çerez Politikası Bölüm 5'te kullanıcılara tarayıcı çerez ayarlarına nasıl erişeceği gösterilir. Her üç büyük tarayıcı için güncel destek sayfası linkini girin. Linkleri yayın öncesinde çalışır durumda test edin. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Çerez Politikası |

---

### F-16 — Çerez Politikası Bağlantısı

| Alan | Değer |
|---|---|
| **Placeholder** | `[CEREZ_POLITIKASI_BAGLANTISI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `https://yeedoy.com/cerez-politikasi` |
| **Açıklama** | KVKK Aydınlatma Metni Bölüm 3.9'da geçen çerez politikası linki. F-11'deki `[WEB_SITESI]` değerinden otomatik türetilebilir: `[WEB_SITESI]/cerez-politikasi`. Ayrıca doldurmak zorunda değilsiniz; geliştirici F-11 üzerinden bunu oluşturabilir. |
| **Zorunlu** | Hayır (F-11 üzerinden türetilir) |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni |

---

## Bölüm 3 — Servis Sağlayıcı Bilgileri

*Teknik ekiple birlikte doldurun — hangi sağlayıcının kullanıldığını geliştirici onaylamalı.*

---

### F-17 — SMS / OTP Sağlayıcısı Adı

| Alan | Değer |
|---|---|
| **Placeholder** | `[SMS_SAGLAYICI_ADI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Twilio Inc.` veya `MessageBird B.V.` veya `Netgsm` |
| **Açıklama** | Supabase Auth üzerinden OTP SMS göndermek için kullanılan sağlayıcının tam ticari adı. Geliştirici hangi sağlayıcının entegre edildiğini doğrulamalı. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | KVKK Aydınlatma Metni, Gizlilik Politikası, Kullanım Şartları |

---

### F-18 — SMS Sağlayıcısı Ülke / Konum

| Alan | Değer |
|---|---|
| **Placeholder** | `[SMS_SAGLAYICI_KONUM]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `ABD (San Francisco, CA)` veya `AB / Hollanda (Amsterdam)` |
| **Açıklama** | SMS sağlayıcısının şirket merkezi veya veri merkezi ülkesi. Yurt dışı ise DPA / yurt dışı aktarım güvencesi hukukçu tarafından değerlendirilmeli (bkz. Ek A → A-05). |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Kullanım Şartları |

---

### F-19 — Hosting / CDN Sağlayıcısı

| Alan | Değer |
|---|---|
| **Placeholder** | `[HOSTING_SAGLAYICI]` |
| **Değeriniz** | ________________________________________ |
| **Örnek format** | `Vercel Inc. (ABD)` veya `Amazon Web Services — Frankfurt (AB)` |
| **Açıklama** | Web / API altyapısını barındıran sağlayıcının adı ve merkez/veri merkezi ülkesi. Yurt dışı ise DPA güvencesi gerekebilir (bkz. Ek A → A-06). CDN sağlayıcısı ayrıysa onu da ekleyin. |
| **Zorunlu** | Evet |
| **Geçtiği belgeler** | Gizlilik Politikası |

---

## Form Tamamlama Özeti

| Alan | Placeholder | Durum |
|---|---|---|
| F-01 | `[SIRKET_UNVANI]` | ☐ Dolduruldu |
| F-02 | `[VERI_SORUMLUSU_UNVANI]` | ☐ Dolduruldu |
| F-03 | `[TICARI_UNVAN]` | ☐ Dolduruldu / ☐ Uygulanmıyor |
| F-04 | `[VERGI_NO]` | ☐ Dolduruldu |
| F-05 | `[MERSIS_NO]` | ☐ Dolduruldu |
| F-06 | `[ADRES]` | ☐ Dolduruldu |
| F-07 | `[YURURLUK_TARIHI]` | ☐ Dolduruldu (en son) |
| F-08 | `[DESTEK_EPOSTA]` | ☐ Dolduruldu |
| F-09 | `[KVKK_BASVURU_EPOSTA]` | ☐ Dolduruldu |
| F-10 | `[TELEFON]` | ☐ Dolduruldu |
| F-11 | `[WEB_SITESI]` | ☐ Dolduruldu |
| F-12 | `[TELIF_BILDIRIM_EPOSTA]` | ☐ Dolduruldu |
| F-13 | `[YETKILI_BIRIM]` | ☐ Dolduruldu |
| F-14 | `[EMAIL_EKLENECEK]` (2 adet) | ☐ Dolduruldu |
| F-15 | `[URL_EKLENECEK]` (Chrome/Firefox/Safari) | ☐ Dolduruldu |
| F-16 | `[CEREZ_POLITIKASI_BAGLANTISI]` | ☐ Dolduruldu / ☐ F-11'den türetildi |
| F-17 | `[SMS_SAGLAYICI_ADI]` | ☐ Dolduruldu |
| F-18 | `[SMS_SAGLAYICI_KONUM]` | ☐ Dolduruldu |
| F-19 | `[HOSTING_SAGLAYICI]` | ☐ Dolduruldu |

**Zorunlu tamamlanma:** 18/19 alan (F-03 ve F-16 opsiyonel)

---

## Ek A — Hukukçuya Kalacak Alanlar

Aşağıdaki placeholder'lar **bu forma dahil edilmemiştir**. Hukukçudan yazılı görüş alınmadan belirlenemez. Doldurma planı için `legal-placeholder-inventory.md` Grup 3, 4 ve 6'ya bakın.

### A.1 DPA ve Yurt Dışı Aktarım

| Placeholder | Geçtiği belgeler | Açıklama |
|---|---|---|
| `[SUPABASE_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Supabase DPA / SCCs durumu |
| `[FIREBASE_DPA_DURUMU]` | KVKK (×3), Gizlilik, VSD | Firebase/Google Cloud DPA durumu |
| `[ADMOB_DPA_DURUMU]` | KVKK, Gizlilik, VSD | AdMob + iOS ATT DPA durumu |
| `[RESEND_DPA_DURUMU]` | KVKK, Gizlilik, VSD | Resend DPA durumu |
| `[SMS_SAGLAYICI_DPA_DURUMU]` | KVKK, Gizlilik | SMS sağlayıcısı DPA durumu |
| `[YURT_DISI_AKTARIM_DURUMU]` | KVKK (×5), Gizlilik (×5), VSD | KVKK md. 9 güvencesi — her sağlayıcı için |

### A.2 Saklama Süreleri

| Placeholder | Geçtiği belgeler | Teknik öneri |
|---|---|---|
| `[SAKLAMA_SURESI_HESAP]` | VSD | Hesap silme sonrası |
| `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | KVKK, Gizlilik, VSD | Silme veya anonimleştirme kararı gerekiyor |
| `[SAKLAMA_SURESI_KONUM]` | VSD | Hesap silme ile birlikte |
| `[SAKLAMA_SURESI_DESTEK]` | KVKK, Gizlilik, VSD | Min. 3–5 yıl önerisi |
| `[SAKLAMA_SURESI_POLICY_ACCEPTANCE]` | KVKK, Gizlilik, VSD | Hesap + 3 yıl önerisi |
| `[SAKLAMA_SURESI_OWNER_CLAIMS]` | KVKK, Gizlilik, VSD | Karar tarihi + 1 yıl önerisi |
| `[SAKLAMA_SURESI_MARKETING_CONSENT]` | KVKK, Gizlilik, VSD | 6563 kapsamı, min. 3 yıl önerisi |
| `[SAKLAMA_SURESI_LOGS]` | KVKK, Gizlilik, VSD | 30 gün önerisi |
| `[SAKLAMA_SURESI_ANALYTICS]` | KVKK, Gizlilik, VSD | 24 ay + anonimleştirme önerisi |
| `[SAKLAMA_SURESI_BILDIRIMLER]` | KVKK, Gizlilik, VSD | Okundu + 30 gün önerisi |
| `[SAKLAMA_SURESI_YASAL_AUDIT]` | VSD | Süresiz arşiv önerisi |

### A.3 Hukukçu Kararı Gerekenler

| Placeholder | Geçtiği belgeler | Açıklama |
|---|---|---|
| `[YAS_SINIRI]` | KVKK, Gizlilik, KŞ | Minimum kullanım yaşı — 18 mi, daha az mı? |
| `[HAREKETSIZLIK_SURESI]` | KŞ | Hesap kapatma için pasiflik süresi |
| `[UYUSMAZLIK_YETKILI_MAHKEME]` | KŞ | Yetkili mahkeme yeri — tüketici kısıtı var mı? |
| `[BILDIRIM_YANIT_SURESI]` | TH | Telif bildirimine yanıt süresi (iş günü) |
| `[ICERIK_SIKAYET_MEKANIZMASI]` | KŞ | İçerik şikâyet kanalı — 5651 kapsamı |

---

> **Bu form doldurulmadan legal belgeler yayına alınmamalıdır.**
