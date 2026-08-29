# Kişisel Verilerin Korunması Kanunu Kapsamında Aydınlatma Metni

---

## Belge Durumu ve Uyarılar

**Durum:** TASLAK — Yayına hazır kesin metin değildir.

Bu belge teknik doğruluk amacıyla hazırlanmış bir taslaktır. Yayına alınmadan önce aşağıdaki koşulların tamamlanması zorunludur:

1. Tüm `[PLACEHOLDER]` alanları doldurulmalıdır. Placeholder tamamlanmadan yayına alınamaz.
2. Belge bir hukuk danışmanı veya KVKK alanında uzmanlaşmış hukuk bürosu tarafından gözden geçirilmeli ve onaylanmalıdır.
3. Aşağıda "hukukçuya kontrol ettirilmeli" olarak işaretlenen her madde yazılı görüş alınarak netleştirilmelidir.
4. Production öncesi teknik bloklayıcılar bölümündeki tüm maddeler kapatılmalıdır.

**Bu belge bir açık rıza metni değildir.** Pazarlama e-postası ve benzer isteğe bağlı işlemler için açık rıza ayrı bir belge ile ayrı bir kullanıcı aksiyonu aracılığıyla alınmaktadır. Aydınlatma metni ile açık rıza beyanı aynı belgede yer alamaz (6698 sayılı KVKK Kılavuzu uyarınca).

**Tarih:** [YURURLUK_TARIHI]

---

## İçindekiler

1. Veri Sorumlusu Kimliği
2. Aydınlatma Metninin Kapsamı
3. İşlenen Kişisel Veri Kategorileri
4. Kişisel Verilerin İşlenme Amaçları
5. Hukuki Sebepler
6. Kişisel Verilerin Aktarımı
7. Kişisel Veri Toplama Yöntemleri
8. Pazarlama E-postası ve Açık Rıza Ayrımı
9. Kişisel Veri Saklama Süreleri
10. İlgili Kişinin Hakları (KVKK Madde 11)
11. Başvuru Yöntemi ve Yanıt Süreci
12. Çocukların Verileri
13. Uygulama İçinde Gösterilecek Kısa Özet
14. Eksik Bilgiler ve Hukukçuya Sorulacaklar
15. Production Öncesi Teknik Bloklayıcılar

---

## 1. Veri Sorumlusu Kimliği

Kişisel verileriniz aşağıda bilgileri yer alan veri sorumlusu tarafından 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında işlenmektedir.

| Bilgi | Değer |
|---|---|
| Unvan | [VERI_SORUMLUSU_UNVANI] |
| Ticari Unvan (varsa) | [TICARI_UNVAN] |
| MERSİS Numarası | [MERSIS_NO] |
| Vergi Numarası | [VERGI_NO] |
| Kayıtlı Adres | [ADRES] |
| Genel Destek E-postası | [DESTEK_EPOSTA] |
| KVKK Başvuru E-postası | [KVKK_BASVURU_EPOSTA] |
| Telefon | [TELEFON] |
| Web Sitesi | [WEB_SITESI] |

---

## 2. Aydınlatma Metninin Kapsamı

Bu aydınlatma metni, Yeedoy markası altında sunulan aşağıdaki platformlar ve hizmetlerde gerçekleştirilen kişisel veri işleme faaliyetlerini kapsar:

- **Yeedoy Mobil Uygulaması** (Android ve iOS): Restoran ve kafe keşfi, konum bazlı arama, dijital menü görüntüleme, kullanıcı yorumları, puanlama, fiyat bilgisi, favoriler, check-in, kampanya takibi, işletme takibi, grup rezervasyon talebi, bildirim tercihleri, hesap ve profil yönetimi.
- **Yeedoy Web Sitesi ve QR Menü Sayfaları** (web.yeedoy.com): Kamuya açık dijital menü görüntüleme, QR kodu ile menü erişimi, işletme profili inceleme, web üzerinden bildirim ve pazarlama tercihleri yönetimi.
- **Yeedoy İşletme Paneli** (panel.yeedoy.com): İşletme sahipleri ve yetkili personele yönelik operasyon ekranları — menü yönetimi, analitik, kampanya gönderimi, ekip yönetimi, işletme sahipliği başvurusu.
- **Destek Talepleri ve KVKK Başvuruları**: [DESTEK_EPOSTA] ve [KVKK_BASVURU_EPOSTA] kanalları üzerinden iletilen her türlü destek, bilgi edinme, düzeltme, silme, itiraz ve benzeri başvurular.

Bu metin, yukarıdaki platformlarda hesap oluşturan, kullanıcı içeriği üreten, konum izni veren, bildirim tercihlerini yöneten, işletme sahipliği başvurusunda bulunan ve işletme panelini kullanan tüm gerçek kişilere uygulanır.

---

## 3. İşlenen Kişisel Veri Kategorileri

Aşağıdaki tablo Yeedoy'da işlenen kişisel veri kategorilerini özetlemektedir. Her kategorinin teknik dayanağı bu metnin sonundaki rapor referanslarında belgelenmiştir.

> **Not:** "Saklama Süresi" sütununda `[PLACEHOLDER]` içeren satırlar, hukuki veya teknik karar gerektiren açık maddelerdir. Bu placeholder'lar doldurulmadan ilgili metinler yayına alınamaz.

### 3.1 Kimlik ve Hesap Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| E-posta adresi | kullanici@ornek.com | Hesap oluşturma, oturum, şifre sıfırlama | Sözleşme ifası | Hesap silinene kadar | Supabase Auth (altyapı), Resend (transactional e-posta) |
| Şifre (hash) | (işlenmiş hash) | Kimlik doğrulama | Sözleşme ifası | Hesap silinene kadar | Supabase Auth (hash olarak) |
| Telefon numarası | +90 5xx xxx xx xx | SMS ile giriş doğrulama, işletme sahipliği başvurusu | Sözleşme ifası | Hesap silinene kadar; sahiplik başvurularında [SAKLAMA_SURESI_OWNER_CLAIMS] | Supabase Auth, [SMS_SAGLAYICI_ADI] |
| Görünen ad | "Ahmet Y." | Profil ve yorum gösterimi | Sözleşme ifası | Hesap silinene kadar | Kamuya açık profil ve yorum görünürlüğü |
| Profil fotoğrafı (URL) | CDN bağlantısı | Profil sayfası gösterimi | Sözleşme ifası | Hesap silinene kadar | Supabase Storage (CDN) |
| Google OAuth profil bilgisi | Ad, e-posta, profil resmi | Google ile giriş yapma | Açık rıza | Hesap silinene kadar | Google (OAuth akışı), Supabase Auth |
| Kullanıcı rolü | authenticated, owner, admin | Rol tabanlı erişim kontrolü | Meşru menfaat (güvenlik) | Hesap/rol silinene kadar | Yok |
| İşletme ekip daveti e-postası | davet@isletme.com | İşletme ekibine davet akışı | Sözleşme ifası (meşru menfaat) | Davet kabul/iptal edilene kadar | Resend (davet e-postası) |

> Kullanıcı yorumları kamuya açık olarak görüntülenir ve görünen adla ilişkilendirilir. Yorum paylaşmak kullanıcının bilinçli aksiyonudur; bu konu Bölüm 7'de açıklanmaktadır.

### 3.2 Konum Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Kullanıcı şehir/ilçe tercihi | İstanbul, Kadıköy | Yakın işletme keşfi, fiyat uyarıları | Açık rıza | Kullanıcı güncelleyene veya sile kadar | Yok |
| Konum modu (otomatik/manuel) | Otomatik | Kullanıcı tercihi yönetimi | Açık rıza | Yukarıdaki ile aynı | Yok |
| Anlık GPS koordinatları | (40.99, 28.84) | Yakın işletme arama, mesafe hesaplama | Açık rıza | Yalnızca oturum süresince bellekte; kalıcı olarak saklanmaz | Yok |
| Fiyat uyarısı şehir/ilçe | Beyoğlu | Kullanıcı tanımlı fiyat alarmı filtresi | Açık rıza | Uyarı silinene kadar | Yok |

> GPS koordinatları sunuculara iletilmez; yalnızca cihaz belleğinde tutularak yakın işletme hesaplaması yapılır. Kalıcı konum kaydı yapılmamaktadır.

> Konum izninin nasıl geri alınacağı Bölüm 10'da anlatılmaktadır.

### 3.3 Kullanıcı Tarafından Üretilen İçerik

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Yorum metni ve puanı | "Yemekler harikaydı, 5/5" | İşletme değerlendirmesi; kamuya açık gösterim | Açık rıza | [SAKLAMA_SURESI_KULLANICI_ETKILESIM] | Kamuya açık API (ad ile birlikte) |
| Fiyat önerisi | 85 TL (önerilen) | Topluluk fiyat güncellemesi | Açık rıza | Onay/ret kararına kadar; kabul edilirse süresiz | Yok |
| Favoriler | Kayıtlı işletme listesi | Kişisel favori listesi | Sözleşme ifası | Kullanıcı silinceye veya sile kadar | Yok |
| İşletme takibi | Takip edilen işletme ID'si | Besleme akışı, e-posta bülteni onayı (ayrı onay ile) | Meşru menfaat (besleme); açık rıza (e-posta) | Takip bırakılana kadar | Owner özet sayısı; e-posta için Resend |
| Kullanıcı takibi | Takip edilen kullanıcı | Sosyal besleme akışı | Sözleşme ifası | Takip bırakılana kadar | Yok |
| İşbirlikçi liste | Ortak restoran listesi | Arkadaşlarla liste oluşturma | Sözleşme ifası | Silme işlemine kadar | Yok |
| Grup rezervasyon talebi | Kişi sayısı, bütçe, notlar | Toplu rezervasyon | Açık rıza | Talep kapanana kadar | İlgili işletme sahiplerine görünür (bkz. Bölüm 6) |
| Grup teklif mesajı | "Salonu da ayarlayabilir misiniz?" | Rezervasyon müzakeresi | Sözleşme ifası | Talep silinene kadar | İlgili işletme sahibine görünür |
| Başarım kaydı | Ödül rozet bilgisi | Gamifikasyon | Sözleşme ifası | Hesap silinene kadar | Yok |

> Grup rezervasyon taleplerinizde yazdığınız notlar ve işletmelerle olan teklif mesajlarınız, teklife dahil işletme sahipleri tarafından görülebilir. Bu paylaşım rezervasyon sürecinin teknik gereğidir.

### 3.4 Bildirim ve Tercih Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| FCM push token | (cihaz kimliği) | Push bildirim gönderimi | Açık rıza | 120 gün hareketsizlikte otomatik silinir | Firebase Cloud Messaging (Google) |
| Platform ve uygulama sürümü | Android 14, v2.1.0 | Bildirim uyumluluk yönetimi | Meşru menfaat | Push token ile aynı süre | Yok |
| Bildirim içeriği ve okundu bayrağı | "Yeni kampanya!" | Kullanıcı gelen kutusu gösterimi | Sözleşme ifası | [SAKLAMA_SURESI_BILDIRIMLER] | Yok |

### 3.5 Pazarlama İzin Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Global pazarlama e-posta izni | true/false | Yeedoy'un platform genelinde kampanya e-postası göndermesine izin | Açık rıza | [SAKLAMA_SURESI_MARKETING_CONSENT] | Yok (karar; e-posta gönderiminde Resend kullanılır) |
| Son opt-in zamanı | 2026-06-18T10:00:00Z | Rıza ispat yükümlülüğü | Yasal yükümlülük | Global izin ile aynı süre | Yok |
| İşletme bazlı e-posta aboneliği | is_subscribed_email: true/false | Belirli bir işletmeden kampanya e-postası almak | Açık rıza | Takip bırakılana kadar | Resend (gönderimde) |

> Global platform pazarlama izni ile belirli bir işletmeden e-posta aboneliği birbirinden farklı kavramlardır. Bu ayrım Bölüm 8'de ayrıntılı açıklanmaktadır.

### 3.6 İşlem Güvenliği ve Teknik Log Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Politika kabul kaydı | Kabul edilen sürüm ID, zaman, kaynak uygulama | KVKK ispat yükümlülüğü | Yasal yükümlülük | [SAKLAMA_SURESI_POLICY_ACCEPTANCE] | Yok |
| KVKK başvurusu | Başvuru türü, durum, tarih | KVKK md.11 başvurusu yönetimi | Yasal yükümlülük | [SAKLAMA_SURESI_DESTEK] | Yok |
| Hesap silme talebi | Talep nedeni, durum | Hesap silme süreç takibi | Yasal yükümlülük | Tamamlandıktan sonra [SAKLAMA_SURESI_DESTEK] | Yok |
| Politika sürüm kataloğu | Sürüm kodu, yayın tarihi | Hangi metnin ne zaman geçerli olduğunun kanıtı | Yasal yükümlülük | Süresiz (değiştirilemez kayıt) | Yok |
| Rate-limit sayacı | İşlem sayısı (kullanıcı ID'si ile) | Spam koruması | Meşru menfaat | Günlük; eski veriler temizlenir | Yok |
| Sunucu tarafı log | JSON log (hata ayıklama) | Hata ayıklama, güvenlik | Meşru menfaat | [SAKLAMA_SURESI_LOGS] | Yok |

> Politika kabul kayıtlarında IP adresi ve tarayıcı/uygulama kimliği (user-agent) otomatik olarak toplanmamaktadır. Bu veriler, veri minimizasyonu ilkesi (KVKK md.4/2-ç) doğrultusunda 2026 yılında yapılan teknik değişiklikle kaldırılmıştır. Kabul kaydı; kullanıcı kimliği, kabul edilen politika sürümü, kabul zamanı ve kaynak uygulama bilgisinden oluşmaktadır.

> **Hukukçuya kontrol ettirilmeli:** IP adresi içermeyen politika kabul kaydının KVKK ispat yükümlülüğü kapsamında yeterli kanıt sayılıp sayılmayacağı.

### 3.7 İşletme Sahipliği Başvurusu Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Ad soyad | Ayşe Kaya | İşletme sahibi doğrulaması | Sözleşme ifası | [SAKLAMA_SURESI_OWNER_CLAIMS] | Yok |
| Telefon numarası | +90 5xx xxx xx xx | Sahiplik doğrulama iletişimi | Sözleşme ifası | [SAKLAMA_SURESI_OWNER_CLAIMS] | Yok |
| Kanıt belge URL'si | (belge bağlantısı) | Sahipliğin belgelenmesi | Sözleşme ifası | [SAKLAMA_SURESI_OWNER_CLAIMS] | Yok |

> **Hukukçuya kontrol ettirilmeli:** Reddedilen işletme sahipliği başvurularında ticaret hukuku veya vergi mevzuatı kapsamında zorunlu saklama süresi bulunup bulunmadığı.

### 3.8 Reklam, Analitik ve Performans Verileri

| Veri | Örnek | İşleme Amacı | Hukuki Sebep | Saklama Notu | Aktarım |
|---|---|---|---|---|---|
| Menü ve QR olay logu | Menü görüntüleme, kalem tıklama, QR tarama olayı | İşletme analitiği, platform büyüme ölçümü | Meşru menfaat | [SAKLAMA_SURESI_ANALYTICS] | Yok |
| Çökme ve hata logu | Anonim hata izi, cihaz tipi | Çökme ve hata izleme | Meşru menfaat | Firebase politikasına göre (varsayılan ~90 gün) | Firebase Crashlytics (Google LLC) — bkz. Bölüm 6 |
| Kullanım analitiği olayları | Ekran görüntüleme, uygulama açılışı, etkileşim olayları | Uygulama kullanımını ölçme, ürün iyileştirme | Meşru menfaat [HUKUKCU_KONTROLU] | Firebase politikasına göre | Firebase Analytics (Google LLC) — bkz. Bölüm 6 |
| Performans izleri | Açılış süresi, ağ isteği süresi, ekran render süresi | Uygulama performansını izleme | Meşru menfaat | Firebase politikasına göre | Firebase Performance (Google LLC) — bkz. Bölüm 6 |
| Reklam gösterim verisi | Reklam tanımlayıcısı (Android Advertising ID / iOS IDFA), gösterim/tıklama | Uygulama içi reklam gösterimi | Açık rıza (iOS ATT) / Meşru menfaat [HUKUKCU_KONTROLU] | Google AdMob politikasına göre | Google AdMob (Google LLC) — bkz. Bölüm 6 |

> Yeedoy mobil uygulamasında uygulama içi reklam gösterimi için Google AdMob kullanılmaktadır. iOS'ta App Tracking Transparency (ATT) çerçevesi kapsamında izleme izni kullanıcıdan alınır; izin verilmezse kişiselleştirilmemiş reklam gösterilir. Google Play Data Safety ve App Store gizlilik beyanları bu kullanımı yansıtacak şekilde güncellenmelidir. [HUKUKCU_KONTROLU]

### 3.9 Üçüncü Taraf Servis Verileri

Ayrıntılar Bölüm 6'da yer almaktadır. Üçüncü tarafların kendi platformlarında işlediği veriler o şirketlerin gizlilik politikalarına tabidir.

---

## 4. Kişisel Verilerin İşlenme Amaçları

Yeedoy, topladığı kişisel verileri yalnızca aşağıdaki belirli ve meşru amaçlarla işler. Amaç kapsamı dışında işleme yapılmaz.

**Temel hizmet amaçları:**

1. Hesap oluşturma, kimlik doğrulama ve oturum yönetimi
2. Restoran ve kafe keşif deneyimi sunma; kişiselleştirilmiş önerilerde bulunma
3. Konuma göre arama, filtreleme ve mesafe hesaplama
4. Kullanıcı yorumları, puanlar, fiyat önerileri, favoriler ve check-in işlemlerini kaydetme ve gösterme
5. Dijital menü içerikleri ve işletme bilgilerini görüntüleme (kamuya açık ve kimlik doğrulamalı)
6. İşletme sahipliği ve doğrulama başvurularını yönetme
7. Destek taleplerini ve KVKK kapsamındaki yasal başvuruları yanıtlama
8. Kullanıcının push bildirim tercihlerini yönetme ve tercihine uygun bildirimler gönderme

**İzne bağlı amaçlar (yalnızca kullanıcı onayı varsa):**

9. Yeedoy'un platform genelinde kampanya, yenilik ve fırsat içerikli e-postalar göndermesi (global pazarlama e-posta izni)
10. Belirli işletmelerin kullanıcıya kampanya içerikli e-postalar göndermesi (işletme bazlı abonelik)

**Güvenlik ve yasal uyum amaçları:**

11. Platform güvenliği, kötüye kullanım tespiti ve önlenmesi, içerik moderasyonu
12. Çökme ve hata izleme; hizmet kalitesini artırma
13. 6698 sayılı KVKK, 6563 sayılı Elektronik Ticaret Kanunu ve ilgili diğer mevzuat kapsamındaki yasal yükümlülükleri yerine getirme
14. Yetkili kamu kurumlarının taleplerini karşılama

---

## 5. Hukuki Sebepler

KVKK'da kişisel verilerin işlenmesi belirli hukuki şartlara dayanmak zorundadır. Aşağıda her işleme faaliyeti için kullanılan temel hukuki sebep belirtilmiştir.

> **Uyarı:** Bu sınıflandırma teknik analiz temelinde hazırlanmıştır. Hukukçuya kontrol ettirilmesi gereken maddeler ayrıca işaretlenmiştir. Mevzuat atıflarını yanlış kullanmamak adına genel kategoriler tercih edilmiştir; kesin madde numaraları hukukçu tarafından teyit edilmelidir.

| İşleme Faaliyeti | Hukuki Sebep | Hukukçu Notu |
|---|---|---|
| Hesap oluşturma ve oturum yönetimi | Sözleşme ifası (KVKK md.5/2-c) | — |
| Konum bazlı arama | Açık rıza (KVKK md.5/1) | Konum izni; kullanıcı cihaz izni verir |
| Kullanıcı yorumları ve içerik | Açık rıza (KVKK md.5/1) | Kullanıcı bilinçli içerik üretir |
| İşletme sahipliği başvurusu | Sözleşme ifası (KVKK md.5/2-c) | Hukukçuya kontrol ettirilmeli |
| KVKK başvurusu ve hesap silme talebi | Yasal yükümlülük (KVKK md.5/2-a) | — |
| Politika kabul kaydı | Yasal yükümlülük (KVKK md.5/2-a) | Hukukçuya kontrol ettirilmeli: ispat yükümlülüğünün tam kapsamı |
| Push bildirim tokeni | Açık rıza (KVKK md.5/1) | Kullanıcı bildirim izni verir |
| Platform güvenliği ve hata izleme | Meşru menfaat (KVKK md.5/2-f) | Hukukçuya kontrol ettirilmeli: meşru menfaat dengesinin yazılı olarak belgelenmesi önerilir |
| Analitik ve büyüme ölçümü | Meşru menfaat (KVKK md.5/2-f) | Hukukçuya kontrol ettirilmeli: Kullanıcı ID içeren event loglarının meşru menfaat kapsamında değerlendirilip değerlendirilemeyeceği; anonimleştirme gereği |
| Pazarlama e-postası gönderimi | Açık rıza (KVKK md.5/1) + 6563 sayılı Kanun | Hukukçuya kontrol ettirilmeli: ayrıca 6563 sayılı Kanun md.6 kapsamındaki ticari elektronik ileti onayı; bu iki onayın ayrı alınması veya birleştirilip birleştirilemeyeceği |
| İşletme bazlı e-posta kampanyası | Açık rıza (KVKK md.5/1) + 6563 sayılı Kanun | Hukukçuya kontrol ettirilmeli: işletme bazlı açık rızanın yeterlilik koşulları; "her hizmet sağlayıcı için ayrı onay" prensibi |
| Yetkili kamu kurumlarına bilgi verme | Yasal yükümlülük (KVKK md.5/2-a) | — |

---

## 6. Kişisel Verilerin Aktarımı

### 6.1 Yurt İçi Aktarım

Yeedoy, kişisel verileri yetkili kamu kurumlarının yasal talepleri kapsamında ilgili kurumlara aktarabilir.

### 6.2 Yurt Dışı Aktarım — Hizmet Sağlayıcılar

Yeedoy, aşağıdaki yurt dışı hizmet sağlayıcılarla çalışmaktadır. Bu aktarımlar KVKK md.9 kapsamında değerlendirilmeli ve yeterli güvence mekanizmaları tesis edilmelidir.

> **Hukukçuya kontrol ettirilmeli:** Her satır için DPA (Veri İşleme Anlaşması) ve KVKK Kurulu kararı veya muafiyet durumu netleştirilmelidir. Placeholder'lar doldurulmadan bu bölüm yayına alınamaz.

#### Supabase (Altyapı, Veritabanı, Kimlik Doğrulama, Dosya Depolama)

| Bilgi | Değer |
|---|---|
| Şirket | Supabase, Inc. |
| Sunucu konumu | Frankfurt, Almanya (AB bölgesi) |
| Aktarılan veriler | Hesap verileri, profil bilgileri, kullanıcı içerikleri, politika kabul kayıtları, bildirim verileri, işletme verileri — veritabanına yazılan tüm veriler |
| Aktarım amacı | Veritabanı, kimlik doğrulama, dosya depolama (CDN) altyapısı sağlamak |
| DPA durumu | [SUPABASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |
| Hukukçu notu | AB sunucuları GDPR kapsamındadır; Türkiye-AB arası aktarım için KVKK Kurulunun mevcut tutumu değerlendirilmelidir |

#### Firebase / Google (Push Bildirim)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | FCM push token, bildirim içeriği (başlık, metin) |
| Aktarım amacı | Push bildirim iletimi |
| DPA durumu | [FIREBASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |
| Hukukçu notu | Google Cloud DPA ve SCCs varlığı teyit edilmelidir |

#### Google (OAuth/Sign-In)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | Google hesap e-postası, adı, profil resmi (yalnızca Google ile giriş yapıldığında) |
| Aktarım amacı | Sosyal giriş (OAuth 2.0 PKCE) |
| DPA durumu | [FIREBASE_DPA_DURUMU] |
| Hukukçu notu | Google Kimlik Hizmetleri Gizlilik Politikası geçerlidir; Kullanıcı Google hesabıyla giriş yaparken Google'ın izin ekranını açıkça onaylar |

#### Resend (E-posta Gönderim Servisi)

| Bilgi | Değer |
|---|---|
| Şirket | Resend (ABD) |
| Aktarılan veriler | E-posta adresi, görünen ad (transactional ve kampanya e-postaları için) |
| Aktarım amacı | Transactional e-posta (şifre sıfırlama, bilgilendirme) ve pazarlama e-postası gönderimi |
| DPA durumu | [RESEND_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |
| Hukukçu notu | Kampanya e-postalarında yalnızca her iki iznin de sağlandığı kullanıcılar alıcı listesine dahil edilir (global pazarlama izni + işletme bazlı abonelik); ayrıntılar Bölüm 8'de |

#### Firebase Crashlytics / Analytics / Performance (Çökme İzleme, Analitik, Performans)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | Anonim hata/çökme izleri ve cihaz tipi (Crashlytics); ekran ve etkileşim olayları, cihaz/uygulama bilgisi (Analytics); açılış ve ağ performans izleri (Performance) |
| Aktarım amacı | Uygulama çökmelerini ve hatalarını izlemek, kullanım analitiği üretmek, performans ölçümü yapmak |
| DPA durumu | [FIREBASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |
| Hukukçu notu | Crashlytics hata izlerinde istem dışı kişisel veri bulunabileceği riski değerlendirilmelidir; Firebase Analytics kullanıcı bazlı olay toplaması için meşru menfaat/açık rıza tercihi ve Google Cloud DPA/SCCs varlığı teyit edilmelidir |

#### Google AdMob (Uygulama İçi Reklam)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | Reklam tanımlayıcısı (Android Advertising ID / iOS IDFA), reklam gösterim/tıklama olayları, yaklaşık cihaz bilgisi |
| Aktarım amacı | Uygulama içi reklam gösterimi ve ölçümü |
| DPA durumu | [ADMOB_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |
| Hukukçu notu | iOS ATT izni ve Google Play Data Safety beyanı yapılandırılmalıdır; kişiselleştirilmiş reklam için ayrı açık rıza gerekip gerekmediği değerlendirilmelidir [HUKUKCU_KONTROLU] |

#### [SMS_SAGLAYICI_ADI] (SMS / OTP Hizmeti)

| Bilgi | Değer |
|---|---|
| Şirket | [SMS_SAGLAYICI_ADI] |
| Aktarılan veriler | Telefon numarası |
| Aktarım amacı | SMS ile tek kullanımlık giriş kodu (OTP) gönderimi |
| DPA durumu | [SMS_SAGLAYICI_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

### 6.3 Grup Rezervasyon Taleplerinde Üçüncü Taraf Görünürlüğü

Kullanıcının oluşturduğu grup rezervasyon talepleri (kişi sayısı, bütçe, notlar, teklif mesajları) teklife dahil işletme sahipleri tarafından görülebilir. Bu paylaşım, talep sürecinin teknik gereğidir ve kullanıcı talebi oluştururken buna peşinen onay vermiş sayılır.

---

## 7. Kişisel Veri Toplama Yöntemleri

Kişisel verileriniz aşağıdaki yollarla toplanmaktadır:

**Kullanıcının doğrudan girdiği veriler:**
- Kayıt formu, profil düzenleme ekranları, yorum yazma, fiyat önerisi gönderme, grup talebi oluşturma, destek talebi açma, işletme sahipliği başvurusu doldurma, tercih ve izin ekranlarındaki seçimler.

**Supabase Auth / Kimlik Doğrulama:**
- E-posta/şifre ile kayıt veya Google OAuth ile giriş sırasında kimlik bilgileri Supabase Auth altyapısı üzerinden alınır.

**Cihaz İzinleri:**
- Konum izni (konum bazlı arama için isteğe bağlı, uygulama ilk kullanımda ister).
- Bildirim izni (push bildirim için isteğe bağlı, uygulama ilk kullanımda ister).
- Bu izinler cihaz işletim sistemi ayarlarından her zaman geri alınabilir.

**Kullanıcı Etkileşimleri:**
- Menü görüntüleme, kalem tıklama, QR tarama gibi davranışsal olaylar analitik amaçla kaydedilir. Bu olaylar kullanıcı kimliğiyle ilişkilendirilebilir.

**Destek ve Başvuru Kanalları:**
- [DESTEK_EPOSTA] ve [KVKK_BASVURU_EPOSTA] adreslerine gönderilen e-postalar ile uygulama içi destek formundan iletilen veriler.

**İşletme Başvuruları:**
- Sahiplik doğrulama formunda kullanıcının girdiği ad, telefon ve belge bilgileri.

**Web Tarafı — Çerez ve Benzeri Teknolojiler:**
- Yeedoy web sitesinde oturum yönetimi için teknik çerezler ve yerel depolama kullanılmaktadır. Detaylı çerez envanteri için [CEREZ_POLITIKASI_BAGLANTISI] adresindeki Çerez Politikamıza bakınız.

> **Hukukçuya kontrol ettirilmeli:** Web çerez banner gerekliliği ve analitik client_id'nin çerez/eşdeğer araç sayılıp sayılmayacağı değerlendirilmelidir.

**iOS Siri / Google Assistant Kısayolları:**
- Yeedoy mobil uygulaması, iOS'ta Siri Kısayolları ve Android'de Uygulama Kısayolları özelliği aracılığıyla "Yakın yer keşfet" gibi akışları başlatmak için `NSUserActivity` kaydı yapar. Bu kaydın amacı kullanıcıya hızlı erişim kolaylığı sağlamaktır; bilgiler yalnızca cihaz üzerinde işlenir ve Yeedoy sunucularına gönderilmez.

---

## 8. Pazarlama E-postası ve Açık Rıza Ayrımı

### 8.1 Aydınlatma Metni ile Açık Rıza Ayrımı

Bu belge bir aydınlatma metnidir ve tek başına bir rıza beyanı içermez. Pazarlama e-postaları için açık rıza ayrı bir kullanıcı aksiyonu (isteğe bağlı opt-in) ile alınmaktadır. KVKK Kılavuzu uyarınca aydınlatma ve rıza belgelerinin karıştırılmaması gerekmektedir.

> **Hukukçuya kontrol ettirilmeli:** Pazarlama e-postası için KVKK md.5/1 kapsamındaki açık rıza ile 6563 sayılı Kanun md.6 kapsamındaki ticari elektronik ileti onayının ayrı mı alınması gerektiği yoksa tek aksiyonda birleştirilebilir mi olduğu. Ayrı açık rıza metni gerekliyse bu dokümanın yanı sıra ayrı bir metin hazırlanmalıdır.

### 8.2 Global Platform Pazarlama İzni

Yeedoy, yeni özellikler, kampanyalar ve fırsatlar hakkında genel bilgilendirme e-postaları göndermek için kullanıcının ayrı ve isteğe bağlı onayını almaktadır.

- Bu izin yasal kabul ekranında zorunlu onaydan bağımsız olarak ayrı bir toggle ile sunulur.
- Kullanıcı bu izni vermek zorunda değildir; uygulama bu onay olmadan da kullanılabilir.
- Kullanıcı, uygulamanın "Bildirim Ayarları" ekranından veya aldığı e-postalardaki abonelik iptal bağlantısından bu izni dilediği zaman geri çekebilir.
- İzin geri çekildiğinde Yeedoy bu kategorideki e-postaları artık göndermez.
- İzin durumu sunucu tarafında kayıt altında tutulur; tüm cihazlarda geçerlidir.

### 8.3 İşletme Bazlı E-posta Aboneliği

Kullanıcının takip ettiği belirli bir işletmeden kampanya ve özel teklif e-postası alması için ayrıca ve yalnızca o işletmeye özgü bir abonelik onayı gerekmektedir. Bu, global platform izninden bağımsızdır.

- Kullanıcı her işletme için ayrı ayrı abonelik tercihini belirleyebilir.
- İşletme bazlı abonelik işletme profil sayfasından yönetilebilir.
- E-postalardaki abonelik iptal bağlantısı (`/abonelik-iptal?token=...`) yalnızca o işletmeye yönelik aboneliği sonlandırır; global platform iznini etkilemez.

### 8.4 Çift Filtre Kuralı

Bir kullanıcıya kampanya e-postası gönderilebilmesi için her iki iznin de aynı anda sağlanmış olması zorunludur:

1. Global platform pazarlama e-posta izni (user_profiles.marketing_email_opt_in = true)
2. İlgili işletme için e-posta aboneliği (business_follows.is_subscribed_email = true)

Bu koşulların herhangi biri sağlanmamışsa kullanıcı alıcı listesine dahil edilmez.

> **Hukukçuya kontrol ettirilmeli:** Global `marketing_email_opt_in` ve işletme bazlı `is_subscribed_email` çift filtresinin hukuki metinde nasıl açıklanacağı; işletme bazlı kampanyalarda ayrıca işletme bazlı yazılı rıza veya denetim kaydı gerekip gerekmediği.

### 8.5 Abonelik İptal Mekanizması (6563 sayılı Kanun md.9/3)

Her kampanya e-postasında çalışan bir abonelik iptal bağlantısı yer almaktadır. Bu bağlantı `/abonelik-iptal?token=...` adresine yönlendirir ve sunucu tarafında doğrulama yapılarak ilgili abonelik sonlandırılır. Token HMAC-SHA256 ile imzalanmıştır ve süre sınırına tabidir. Bağlantının güvenlik özellikleri teknik doğrulama raporunda belgelenmiştir.

---

## 9. Kişisel Veri Saklama Süreleri

Kişisel veriler, işleme amacının gerektirdiği süre boyunca saklanır; amacın sona ermesiyle birlikte silinir, anonimleştirilir veya ilgili yasal yükümlülük kapsamında arşivlenir.

Aşağıdaki tabloda her veri kategorisi için saklama süresi yer almaktadır. `[PLACEHOLDER]` içeren satırlar için henüz kesin karar verilmemiştir; yayın öncesinde tamamlanmalıdır.

> **Uyarı:** Saklama süreleri kesin rakamlara dayandırılmalıdır. Tahmini süreler yayına alınamaz. Hukukçu her kategori için yasal gereksinim değerlendirmesi yapmalıdır.

| Veri Kategorisi | Saklama Süresi | Notlar |
|---|---|---|
| Hesap ve kimlik verileri | Hesap silinene kadar | Kullanıcı hesabını sildiğinde CASCADE ile ilgili veriler de silinir |
| Profil verileri (görünen ad, avatar) | Hesap silinene kadar | — |
| Konum tercihleri (şehir/ilçe) | Kullanıcı güncelleyene veya hesap silinene kadar | Kullanıcı ayarlardan silebilir |
| Kullanıcı yorumları ve puanları | [SAKLAMA_SURESI_KULLANICI_ETKILESIM] | Hukukçuya kontrol ettirilmeli: hesap silindiğinde yorum anonim mi kalabilir yoksa silinmeli mi |
| Favoriler | Hesap silinene kadar | — |
| FCM push token | 120 gün hareketsizlik sonrası otomatik silinir | Oturum kapatmada da silinir |
| Bildirimler | [SAKLAMA_SURESI_BILDIRIMLER] | — |
| Politika kabul kayıtları | [SAKLAMA_SURESI_POLICY_ACCEPTANCE] | KVKK ispat yükümlülüğü için hukukçu karar vermeli |
| KVKK başvuruları ve hesap silme talepleri | [SAKLAMA_SURESI_DESTEK] | İdari işlem kaydı; en az 3-5 yıl önerisi (hukukçuya kontrol ettirilmeli) |
| İşletme sahipliği başvuruları | [SAKLAMA_SURESI_OWNER_CLAIMS] | Karar tarihinden itibaren süre belirlenmeli |
| Analitik olay logu | [SAKLAMA_SURESI_ANALYTICS] | Kullanıcı ID içeriyor; saklama süresi veya anonimleştirme kararı verilmeli |
| Pazarlama izin durumu ve opt-in zamanı | [SAKLAMA_SURESI_MARKETING_CONSENT] | KVKK ispat yükümlülüğü kapsamında; opt-out geçmişi ayrıca tutulacak mı hukukçuya sorulmalı |
| Hata/log kayıtları | [SAKLAMA_SURESI_LOGS] | Sunucu log politikası belirlenmeli (öneri: 30 gün) |
| Politika sürüm kataloğu | Süresiz | Değiştirilemez yasal kayıt |

---

## 10. İlgili Kişinin Hakları (KVKK Madde 11)

6698 sayılı Kişisel Verilerin Korunması Kanunu'nun 11. maddesi uyarınca her kullanıcı aşağıdaki haklara sahiptir:

**a) Kişisel verilerinin işlenip işlenmediğini öğrenme**
Hangi kişisel verilerinizin Yeedoy tarafından tutulduğunu sormak için başvuruda bulunabilirsiniz.

**b) Kişisel verilerinin işlenmiş olması halinde buna ilişkin bilgi talep etme**
Verilerinizin hangi amaçla, hangi yöntemle ve kimlere aktarıldığını öğrenebilirsiniz.

**c) Kişisel verilerin işlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme**
Verilerinizin belirtilen amaçlar dışında kullanılıp kullanılmadığını sorgulayabilirsiniz.

**d) Yurt içinde veya yurt dışında kişisel verilerin aktarıldığı üçüncü kişileri bilme**
Verilerinizin hangi kuruluşlara aktarıldığını öğrenme hakkına sahipsiniz.

**e) Kişisel verilerin eksik veya yanlış işlenmiş olması halinde bunların düzeltilmesini isteme**
Yanlış veya eksik bilgilerinizin düzeltilmesini talep edebilirsiniz.

**f) İlgili mevzuatta öngörülen şartlar çerçevesinde kişisel verilerin silinmesini veya yok edilmesini isteme**
Hesabınızı silme veya belirli verilerinizin kaldırılmasını talep edebilirsiniz. Bu talep uygulama içi "Hesabımı Sil" akışı veya [KVKK_BASVURU_EPOSTA] adresi üzerinden iletilebilir.

**g) (e) ve (f) bentleri uyarınca yapılan işlemlerin kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme**
Düzeltme veya silme işlemlerinin aktarım yapılan üçüncü taraflara da bildirilmesini talep edebilirsiniz.

**h) İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle kişinin kendisi aleyhine bir sonucun ortaya çıkmasına itiraz etme**
Otomatik karar alma süreçlerine itiraz etme hakkına sahipsiniz.

**i) Kişisel verilerin kanuna aykırı olarak işlenmesi sebebiyle zarara uğraması halinde zararın giderilmesini talep etme**
Kanuna aykırı işleme nedeniyle uğradığınız zararın tazminini talep edebilirsiniz.

**Konum rızasını geri çekme:**
Cihazınızın uygulama izin ayarlarından "Konum" iznini kaldırabilirsiniz. Ayrıca uygulamanın Bildirim Ayarları ekranından konum modunu "Manuel" olarak değiştirebilirsiniz.

**Pazarlama e-postası iznini geri çekme:**
Uygulamanın "Bildirim Ayarları" ekranındaki "Pazarlama E-postaları" toggleı ile veya aldığınız e-postalardaki abonelik iptal bağlantısı ile dilediğiniz zaman geri çekebilirsiniz. İzin geri çekildikten sonra bu kategorideki e-postalar artık gönderilmez.

**KVK Kurumu'na şikayet hakkı:**
Başvurunuzun yetersiz karşılandığını düşünüyorsanız Kişisel Verileri Koruma Kurumu'na (www.kvkk.gov.tr) şikayette bulunma hakkınız saklıdır.

---

## 11. Başvuru Yöntemi ve Yanıt Süreci

### Başvuru Kanalları

KVKK kapsamındaki haklarınızı kullanmak için aşağıdaki kanallardan başvuruda bulunabilirsiniz:

| Kanal | Adres | Açıklama |
|---|---|---|
| E-posta | [KVKK_BASVURU_EPOSTA] | KVKK başvuruları için tercih edilen kanal |
| Yazılı başvuru (posta/elden) | [ADRES] | Kimlik belgesi ile birlikte |
| Genel destek | [DESTEK_EPOSTA] | Hesap ve teknik sorular için |

### Başvuruda Bulunması Gereken Bilgiler

Başvurunuzda şu bilgilerin yer alması süreci hızlandıracaktır: Ad soyad, iletişim bilgisi (e-posta veya telefon), talep türü (erişim / düzeltme / silme / itiraz / diğer), talep edilen verinin açıklaması, varsa ilgili hesap bilgisi.

### Yanıt Süreci

Başvurular en kısa sürede ve her halükarda yasal süre içinde yanıtlanır. Yanıt süresi ve usulü hakkında kesin yasal çerçeve için hukukçuya danışılmalıdır.

> **Hukukçuya kontrol ettirilmeli:** KVKK kapsamındaki başvurulara yanıt süresinin kesin hukuki çerçevesi ve uygulanacak usul (noter kanalı, KEP adresi vb. gereksinimler).

---

## 12. Çocukların Verileri

Yeedoy, çocuklara özel olarak tasarlanmamış bir platformdur. Platformun kullanımı için minimum yaş [YAS_SINIRI] olarak belirlenmiştir.

> **Hukukçuya kontrol ettirilmeli:**
> - Minimum kullanım yaşının ([YAS_SINIRI]) hukuki dayanağı ve uygulanabilirliği
> - Yaş sınırı altındaki kullanıcıların verilerinin tespit edilmesi ve silinmesi için gerekli teknik ve idari tedbirler
> - KVKK kapsamında ebeveyn/vasi rızası gereksinimleri

---

## 13. Uygulama İçinde Gösterilecek Kısa Özet

Aşağıdaki özet, yasal işlemler ekranında veya KVKK bilgi kartında gösterilmek üzere hazırlanmıştır. Tam metin için bu belgenin tamamı bağlantılanmalıdır.

---

**Kişisel Verileriniz Hakkında Kısa Bilgi**

1. Hesap oluşturma, konum arama, yorumlar ve bildirimler için gerekli kişisel verileriniz [VERI_SORUMLUSU_UNVANI] tarafından işlenmektedir.
2. GPS koordinatlarınız sunuculara iletilmez; yalnızca cihazınızda yakın işletme hesaplaması için kullanılır ve kalıcı olarak saklanmaz.
3. Yorumlarınız adınızla birlikte kamuya açık olarak görüntülenir.
4. Pazarlama e-postaları yalnızca ayrıca onayladığınızda gönderilir; Bildirim Ayarları ekranından veya e-postadaki bağlantıdan dilediğiniz zaman durdurunuz.
5. Verileriniz; Supabase (altyapı), Google/Firebase (giriş, bildirim, çökme izleme, analitik, performans, reklam) ve Resend (e-posta) hizmet sağlayıcılarına aktarılabilir.
6. Erişim, düzeltme, silme ve itiraz haklarınız için [KVKK_BASVURU_EPOSTA] adresine başvurabilirsiniz.
7. Tam Aydınlatma Metni için: [WEB_SITESI]/kvkk-aydinlatma-metni

---

## 14. Eksik Bilgiler ve Hukukçuya Sorulacaklar

Aşağıdaki maddeler teknik çalışmadan gelen açık sorulardır. Her biri yayın öncesinde yanıtlanmalıdır.

| # | Soru | Kaynak | Öncelik |
|---|---|---|---|
| S-1 | IP adresi içermeyen politika kabul kaydı (yalnızca user_id + sürüm + zaman) KVKK ispat yükümlülüğü için yeterli midir? | r4-ip-metadata-decision-plan.md | Kritik |
| S-2 | `user_policy_acceptances` ve `business_policy_acceptances` tablolarındaki `ip_address` / `user_agent` sütunları fiziksel olarak DROP edilmeli mi yoksa NULL bırakılması yeterli midir? | r4-ip-metadata-decision-plan.md | Yüksek |
| S-3 | `marketing_email_opted_in_at` alanı opt-out sonrasında NULL'a çekilmektedir. Kullanıcının izni geri çektiğine dair ispat için bu yeterli midir, yoksa opt-out geçmişi de ayrıca kayıt altına alınmalı mıdır? | r5-marketing-optin-data-model-decision.md | Kritik |
| S-4 | Opt-out geçmişi (izin verme ve geri alma tarihleri) ayrı bir tabloda tutulmalı mıdır? | r5-marketing-optin-data-model-decision.md | Yüksek |
| S-5 | Global `marketing_email_opt_in` ve işletme bazlı `business_follows.is_subscribed_email` çift filtresi hukuki metinde nasıl tanımlanmalıdır? | r5-email-filter-token-hardening-report.md | Yüksek |
| S-6 | İşletme bazlı kampanya e-postalarında ayrıca işletme bazlı yazılı rıza veya denetim kaydı zorunlu mudur? | r5-marketing-optin-data-model-decision.md | Kritik |
| S-7 | Supabase (Frankfurt/AB), Resend (ABD), Google/Firebase — Crashlytics/Analytics/Performance/AdMob (ABD) için yurt dışı aktarım güvencesi KVKK md.9 kapsamında yeterince karşılanmış mıdır? Her biri için DPA veya SCCs imzalanmalı mıdır? | legal-preflight-report.md | Kritik |
| S-16 | Firebase Analytics ve Performance için meşru menfaat yeterli midir, yoksa açık rıza mı gereklidir? AdMob için iOS ATT izni ve Google Play Data Safety beyanı yapılandırıldı mı; kişiselleştirilmiş reklam için ayrı açık rıza gerekir mi? | cerez-politikasi.md | Kritik |
| S-8 | HMAC-SHA256 imzalı stateless unsubscribe token süresinin [Token geçerlilik süresi Supabase konfigürasyonuna bağlı] olarak belirlenmesi yeterli midir; yoksa daha kısa bir süre gerekli midir? | r5-unsubscribe-security-verification-report.md | Orta |
| S-9 | Web `/bildirim-ayarlari` sayfasının doğrudan tablo güncellemesi yerine RPC standardına geçirilmesi gerekiyor mu? Mevcut durum hukuki açıdan risk taşır mı? | r5-unsubscribe-security-verification-report.md | Orta |
| S-10 | Kullanıcı yorumu anonimleştirilmeden silinebilir mi yoksa yorum anonim olarak (ad olmadan, içerik kalabilir) bırakılabilir mi? | legal-preflight-report.md | Yüksek |
| S-11 | İşletme sahipliği başvurularında ticaret hukuku veya vergi mevzuatı kapsamında zorunlu saklama süresi var mı? | legal-preflight-report.md | Yüksek |
| S-12 | `analytics_events` tablosunda user_id içeren olay loglarının meşru menfaat kapsamında işlenmesi kabul edilebilir mi, yoksa anonimleştirme zorunlu mudur? | legal-data-inventory.md | Yüksek |
| S-13 | Siri/Google Assistant kısayolu için iOS Privacy Manifest veya App Store gizlilik bildirimi güncellenmesi gerekiyor mu? | legal-preflight-report.md | Düşük |
| S-14 | Kullanıcının konum iznini geri çekmesi durumunda sistem otomatik olarak konum tercihini siliyor mu, yoksa manuel müdahale mi gerekiyor? | legal-preflight-report.md | Orta |
| S-15 | KVKK başvurularına yanıt için kesin yasal süre ve usul (noter kanalı, KEP adresi vb.) nedir? | legal-preflight-report.md | Yüksek |

---

## 15. Production Öncesi Teknik Bloklayıcılar

Aşağıdaki teknik maddeler kapatılmadan bu aydınlatma metninin geçerli kılacağı sistemler production ortamında çalışmıyor olacaktır. Metin yayına alınmadan önce teknik ekip tarafından tüm maddelerin kapatıldığı doğrulanmalıdır.

> **Önemli:** Bu maddelerin herhangi biri eksikse e-posta kampanyası canlıya alınamaz. Kısmi uygulama 6563 sayılı Kanun ihlali riski taşır.

### Veritabanı Migration'ları (Üretimde Uygulanmamış)

| Migration | İçerik | Durum |
|---|---|---|
| `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` | `capture_request_metadata_v1()` fonksiyonundan IP/user-agent bloğunu kaldırır; mevcut kayıtlardaki IP/UA verilerini NULL'a çeker | Oluşturuldu — production'a uygulanmadı |
| `20260620000001_user_profiles_marketing_email_opt_in.sql` | `user_profiles` tablosuna `marketing_email_opt_in` ve `marketing_email_opted_in_at` sütunları ekler | Oluşturuldu — production'a uygulanmadı |
| `20260620000002_r5_marketing_email_rpcs.sql` | `get_my_notification_preferences_v1`, `update_my_marketing_email_opt_in_v1`, `update_business_email_subscription_v1` RPC'lerini oluşturur; `business_follows` UPDATE RLS policy'si ekler | Oluşturuldu — production'a uygulanmadı |

### Ortam Değişkenleri / Secrets

| Değişken | Nerede | Açıklama |
|---|---|---|
| `UNSUBSCRIBE_HMAC_SECRET` | Next.js production `.env` | HMAC-SHA256 unsubscribe token imzalama gizli anahtarı — eksikse kampanya gönderimi durdurulur (fail-closed) |
| `UNSUBSCRIBE_HMAC_SECRET` | Supabase Edge Function secrets | Aynı değer edge function tarafında da gereklidir |
| `SITE_URL` | Next.js production `.env` | Unsubscribe link'inde kullanılan domain — doğru production URL olmalıdır |

### Doğrulama Testleri

| Test | Açıklama |
|---|---|
| Web typecheck ve lint | `npm run typecheck && npm run lint` temiz çalışmalı |
| Unsubscribe token birim testleri | `npm run test:unit` — 27 test geçmeli |
| Local/staging veritabanı testleri | Migration'lar local `supabase start` + `supabase db reset` ortamında test edilmeli; IP NULL kontrolü, RPC davranışları doğrulanmalı |
| Flutter analyze | 0 hata/uyarı |
| Flutter birim testleri | 27/27 R-5 testi geçmeli |
| E-posta kampanyası uçtan uca testi | Staging ortamında: opt-in kullanıcıya gönderim başarılı, opt-out kullanıcıya gönderilmiyor, unsubscribe linki çalışıyor doğrulanmalı |

---

## Referans Belgeler

Bu aydınlatma metni aşağıdaki teknik ve analiz belgelerine dayanılarak hazırlanmıştır:

| Belge | Konu |
|---|---|
| `docs/hukuki/legal-data-inventory.md` | Kişisel veri envanteri |

---

*Bu belge yayına hazır kesin hukuki metin değildir. Hukuki geçerlilik için tüm placeholder'ların doldurulması ve bir hukuk danışmanı tarafından onaylanması zorunludur.*
