# Yeedoy Gizlilik Politikası

---

## Belge Durumu ve Zorunlu Uyarılar

**Durum:** TASLAK — Yayına hazır kesin metin değildir.

Bu metin, teknik veri envanteri ve gizlilik mühendislik raporlarına dayalı olarak hazırlanmış bir taslaktır. Yayına alınmadan önce aşağıdaki koşulların tamamlanması zorunludur:

1. Bu metin bir **taslaktır**. Yayın öncesinde KVKK alanında uzmanlaşmış bir hukuk danışmanı tarafından gözden geçirilmeli ve onaylanmalıdır.
2. **KVKK Aydınlatma Metni'nin yerini almaz**; onu tamamlayıcı niteliktedir. KVKK Aydınlatma Metni ayrı bir belge olarak `kvkk-aydinlatma-metni.md` dosyasında yer almaktadır.
3. Aşağıda `[PLACEHOLDER]` biçiminde işaretlenmiş tüm alanlar doldurulmadan bu metin yayına alınamaz.
4. "Production öncesi teknik bloklayıcılar" bölümündeki maddeler kapatılmadan e-posta kampanyaları ve ilgili sistemler canlıya alınamaz.

**Tarih:** [YURURLUK_TARIHI]

---

## İçindekiler

1. Veri Sorumlusu ve İletişim
2. Kapsam
3. Hangi Verileri Topluyoruz?
4. Verileri Nasıl Kullanıyoruz?
5. Konum Verisi
6. Pazarlama E-postaları ve Bildirimler
7. Verilerinizi Kimlerle Paylaşabiliriz?
8. Verilerinizi Nasıl Koruyoruz?
9. Veri Saklama ve Silme
10. Çerezler ve Benzeri Teknolojiler
11. Haklarınız ve Tercihleriniz
12. Çocukların Gizliliği
13. Politika Değişiklikleri
14. Uygulamada Gösterilecek Kısa Özet
15. Eksik Bilgiler ve Hukukçuya Sorulacaklar
16. Production Öncesi Teknik Bloklayıcılar

---

## 1. Veri Sorumlusu ve İletişim

Yeedoy uygulamasını ve hizmetlerini kullananların kişisel verileri, aşağıda bilgileri yer alan veri sorumlusu tarafından işlenmektedir.

| Bilgi | Değer |
|---|---|
| Unvan | [VERI_SORUMLUSU_UNVANI] |
| Ticari Unvan (varsa) | [TICARI_UNVAN] |
| Adres | [ADRES] |
| Genel Destek E-postası | [DESTEK_EPOSTA] |
| KVKK Başvuru E-postası | [KVKK_BASVURU_EPOSTA] |
| Telefon | [TELEFON] |
| Web Sitesi | [WEB_SITESI] |

Bu politikada "Yeedoy", "biz" veya "bizim" ifadeleri yukarıdaki veri sorumlusunu ifade etmektedir.

---

## 2. Kapsam

Bu Gizlilik Politikası, Yeedoy markası altında sunulan tüm platformları kapsar:

- **Yeedoy Mobil Uygulaması** (Android ve iOS): Restoran ve kafe keşfi, konum bazlı arama, dijital menü görüntüleme, kullanıcı yorumları, puanlama, fiyat bilgisi, favoriler, kampanya takibi, işletme takibi, grup rezervasyon talebi, bildirim tercihleri, hesap ve profil yönetimi.
- **Yeedoy Web Sitesi ve QR Menü Sayfaları**: Kamuya açık dijital menü görüntüleme, QR kodu ile menü erişimi, işletme profili inceleme, web üzerinden bildirim ve pazarlama tercihleri yönetimi.
- **Yeedoy İşletme Paneli**: İşletme sahipleri ve yetkili personele yönelik operasyon ekranları — menü yönetimi, analitik, kampanya gönderimi, ekip yönetimi, işletme sahipliği başvurusu.
- **Bildirim Ayarları ve Tercih Yönetimi**: Uygulama içi ve web üzerindeki bildirim ve pazarlama tercih ekranları.
- **Destek Talepleri**: [DESTEK_EPOSTA] ve [KVKK_BASVURU_EPOSTA] kanalları üzerinden iletilen tüm başvurular.
- **İşletme Sahipliği Başvuruları**: Sahiplik doğrulama süreci kapsamında yürütülen işlemler.
- **Kampanya ve E-posta İzin Sistemi**: Pazarlama e-postası opt-in ve abonelik iptal akışları.

Bu metin, yukarıdaki platformlarda hesap oluşturan, içerik üreten, konum izni veren, bildirim tercihlerini yöneten, işletme sahipliği başvurusunda bulunan ve işletme panelini kullanan tüm gerçek kişilere uygulanır.

---

## 3. Hangi Verileri Topluyoruz?

### 3.1 Hesap Bilgileri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| E-posta adresi | kullanici@ornek.com | Hesap oluşturma, giriş, şifre sıfırlama | Evet — hesap ayarlarından |
| Şifre (hash) | (işlenmiş hash, düz metin saklanmaz) | Kimlik doğrulama | Evet — şifre değiştirme |
| Telefon numarası | +90 5xx xxx xx xx | SMS ile giriş doğrulama, işletme sahipliği başvurusu | Evet — hesap ayarlarından |
| Görünen ad | "Ahmet Y." | Profil ve yorum gösterimi | Evet — profil düzenleme |
| Profil fotoğrafı | (CDN bağlantısı) | Profil sayfası gösterimi | Evet — profil düzenleme veya fotoğraf kaldırma |
| Google OAuth profil bilgisi | Ad, e-posta, profil resmi | Google ile giriş yapma | Evet — Google hesap ayarlarından |
| Kullanıcı rolü | authenticated, owner, admin | Rol tabanlı erişim kontrolü (güvenlik) | Hayır — sistem tarafından yönetilir |

### 3.2 İletişim ve Ekip Bilgileri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| İşletme ekip daveti e-postası | davet@isletme.com | İşletme ekibine davet göndermek | Evet — davet iptal edilebilir |

### 3.3 Konum Bilgileri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Kullanıcı şehir/ilçe tercihi | İstanbul, Kadıköy | Yakın işletme keşfi, fiyat uyarıları | Evet — uygulama konum ayarlarından |
| Konum modu (otomatik/manuel) | Otomatik | Kullanıcı tercihi yönetimi | Evet — uygulama ayarlarından |
| Anlık GPS koordinatları | (40.99, 28.84) | Yakın işletme arama, mesafe hesaplama | Evet — cihaz izinleri (Bölüm 5) |
| Fiyat uyarısı şehir/ilçe | Beyoğlu | Kullanıcı tanımlı fiyat alarmı filtresi | Evet — uyarı silinerek |

> GPS koordinatları sunuculara kalıcı olarak iletilmez. Yalnızca cihaz belleğinde tutularak yakın işletme hesaplaması yapılır ve oturum sonunda silinir.

### 3.4 Favoriler, Yorumlar, Puanlar ve Kullanıcı Etkileşimleri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Yorum metni ve puanı | "Yemekler harikaydı, 5/5" | İşletme değerlendirmesi; kamuya açık gösterim | Evet — yorum silme; ancak silme/anonimleştirme kararı hukukçuya sorulacak (bkz. Bölüm 15) |
| Fiyat önerisi | 85 TL (önerilen) | Topluluk fiyat güncellemesi | Evet — onay öncesi geri çekilebilir |
| Favoriler | Kayıtlı işletme listesi | Kişisel favori listesi | Evet — favori kaldırılabilir |
| İşletme takibi | Takip edilen işletme | Besleme akışı | Evet — takibi bırakmak |
| Kullanıcı takibi | Takip edilen diğer kullanıcılar | Sosyal besleme akışı | Evet — takibi bırakmak |
| İşbirlikçi liste | Ortak restoran listesi | Arkadaşlarla liste oluşturma | Evet — listeden ayrılma |
| Grup rezervasyon talebi | Kişi sayısı, bütçe, notlar | Toplu rezervasyon | Evet — talep kapatılabilir |
| Grup teklif mesajı | Mesaj içeriği | Rezervasyon müzakeresi | Talep kapatıldığında |
| Başarım kaydı | Rozet bilgisi | Gamifikasyon | Hayır — sistem tarafından yönetilir |

> Yorumlarınız görünen adınızla birlikte kamuya açık olarak görüntülenir. Yorum paylaşmak bilinçli bir kullanıcı aksiyonudur. Grup rezervasyon talepleriniz ve teklif mesajlarınız, teklife dahil işletme sahipleri tarafından görülebilir; bu paylaşım rezervasyon sürecinin teknik gereğidir.

### 3.5 İşletme Sahipliği Başvuru Bilgileri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Ad soyad | Ayşe Kaya | İşletme sahibi doğrulaması | Karar öncesi iptal |
| Telefon numarası | +90 5xx xxx xx xx | Sahiplik doğrulama iletişimi | Karar öncesi iptal |
| Kanıt belge URL'si | (belge bağlantısı) | Sahipliğin belgelenmesi | Karar öncesi iptal |

### 3.6 Destek Mesajları

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Destek talebi içeriği | Sorun açıklaması | Destek sağlamak | KVKK başvurusu ile |
| KVKK başvurusu | Başvuru türü, talep | Yasal yükümlülük | Yasal sürece göre |
| Hesap silme talebi | Talep nedeni, durum | Silme sürecini yönetmek | Talebi geri çekme |

### 3.7 Bildirim ve Pazarlama Tercihleri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| FCM push token | (cihaz kimliği) | Push bildirim gönderimi | Evet — cihaz bildirim izni |
| Global pazarlama e-posta izni | true/false | Yeedoy kampanya e-postaları | Evet — bildirim ayarlarından veya e-postadaki iptal linki |
| İzin verme zamanı | 2026-06-18T10:00:00Z | Rıza ispat yükümlülüğü | Rıza geri çekilebilir |
| İşletme bazlı e-posta aboneliği | Abone/değil | Belirli işletmeden kampanya | Evet — e-postadaki iptal linki veya işletme profili |

> Global platform pazarlama izni ile belirli bir işletmeye e-posta aboneliği farklı kavramlardır. Bu ayrım Bölüm 6'da ayrıntılı açıklanmaktadır.

### 3.8 Teknik Loglar ve Hata Kayıtları

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Politika kabul kaydı | Kabul edilen sürüm, zaman, kaynak uygulama | KVKK ispat yükümlülüğü | KVKK başvurusu ile |
| Firebase Crashlytics çökme logu | Anonim hata izi, cihaz tipi | Uygulama çökmelerini düzeltmek | Hayır — teknik operasyon |
| Sunucu tarafı log | JSON hata kaydı | Hata ayıklama, güvenlik | Hayır — teknik operasyon |
| Rate-limit sayacı | İşlem sayısı | Spam ve kötüye kullanım önleme | Hayır — teknik operasyon |

> Politika kabul kayıtlarında IP adresi ve tarayıcı/uygulama kimliği (user-agent) otomatik olarak tutulmamaktadır. Bu veriler, veri minimizasyonu ilkesi doğrultusunda teknik bir karar ile kaldırılmıştır. Kabul kaydı; kullanıcı kimliği, kabul edilen politika sürümü, kabul zamanı ve kaynak uygulama bilgisinden oluşmaktadır.

### 3.9 Analitik ve Verimlilik Verileri

| Veri Türü | Örnekler | Neden Kullanıyoruz? | Kullanıcı Yönetebilir mi? |
|---|---|---|---|
| Menü ve QR olay logu | Menü görüntüleme, kalem tıklama, QR tarama | İşletme analitiği, platform büyümesini ölçmek | Hayır — teknik operasyon |
| Web analitik olayları (birinci taraf) | Sayfa görüntüleme — yalnızca kendi sunucumuza (`/api/track`) | Platform kalitesini artırmak | Hayır — teknik operasyon |
| Firebase Analytics olayları (mobil) | Ekran görüntüleme, etkileşim | Uygulama kullanımını ölçmek | Hayır — teknik operasyon |
| Firebase Performance izleri (mobil) | Açılış/ağ performans izi | Performansı izlemek | Hayır — teknik operasyon |
| AdMob reklam verisi (mobil) | Reklam tanımlayıcısı, gösterim/tıklama | Uygulama içi reklam | iOS'ta ATT izni; cihaz reklam ayarlarından sıfırlanabilir |

> Web tarafında üçüncü taraf web analitiği (Google Analytics, Tag Manager vb.) kullanılmamaktadır; analitik tanımlayıcı yalnızca Yeedoy'un kendi sunucusuna gönderilir.

### 3.10 Çerez ve Benzeri Web Teknolojileri

Web sitemizde ve QR menü sayfalarında oturum yönetimi ve teknik işleyiş için çerezler ve benzeri teknolojiler kullanılabilir. Detaylı bilgi için ayrı Çerez Politikamıza bakınız. Bu bölüm Çerez Politikası'nın yerini tutmaz. Mobil uygulamada çerez yerine cihaz izinleri, push token veya SDK verileri kullanılmaktadır.

---

## 4. Verileri Nasıl Kullanıyoruz?

Yeedoy, topladığı kişisel verileri yalnızca aşağıdaki belirli ve meşru amaçlarla işler.

**Hesap ve güvenlik:**
- Hesap oluşturmak, kimliğinizi doğrulamak ve oturumunuzu güvenli şekilde yönetmek
- Rol tabanlı erişim kontrolü ile yetkisiz erişimi engellemek

**Keşif ve içerik:**
- Yakındaki restoran ve kafeleri göstermek; konuma göre arama ve filtreleme yapmak
- Dijital menüleri, fiyatları ve işletme bilgilerini görüntülemek
- Kullanıcı yorumları, favoriler, puanlamalar ve fiyat önerilerini çalıştırmak

**Platform özellikleri:**
- Grup rezervasyon taleplerini işletmelerle eşleştirmek
- İşletme sahipliği ve doğrulama başvurularını değerlendirmek ve yönetmek
- Destek taleplerini yanıtlamak

**Bildirim ve tercih yönetimi:**
- Kullanıcının push bildirim tercihlerine göre bildirim göndermek
- Bildirim ve e-posta tercihlerini kayıt altında tutmak

**İzne bağlı kullanım (yalnızca kullanıcı onayı varsa):**
- Yeedoy'un platform genelinde kampanya, yenilik ve fırsat içerikli e-postalar göndermesi
- Belirli işletmelerin, yalnızca abonelik vermiş takipçilerine kampanya e-postaları göndermesi

**Güvenlik ve yasal uyum:**
- Platform güvenliği, kötüye kullanım tespiti, içerik moderasyonu ve spam koruması
- Uygulama hatalarını ve çökmeleri tespit ederek hizmet kalitesini artırmak
- 6698 sayılı KVKK, 6563 sayılı Elektronik Ticaret Kanunu ve ilgili mevzuat kapsamındaki yasal yükümlülükleri yerine getirmek
- Yetkili kamu kurumlarının yasal taleplerini karşılamak

---

## 5. Konum Verisi

Konum özelliği, uygulamada size yakın mekanları göstermek ve arama sonuçlarını iyileştirmek için kullanılmaktadır.

- **İzin sizden alınır:** Konum izni, uygulamayı ilk kullandığınızda işletim sisteminizin standart izin ekranı aracılığıyla sorulur. Bu izin zorunlu değildir; uygulamanın diğer bölümleri konum izni olmadan da kullanılabilir.
- **GPS koordinatları:** Yakın işletme arama yapıldığında anlık GPS koordinatlarınız yalnızca cihaz belleğinde işlenir ve sunuculara kalıcı olarak gönderilmez.
- **Şehir/ilçe tercihi:** Konum modunu "Manuel" olarak ayarlamanız durumunda yalnızca seçtiğiniz şehir ve ilçe bilgisi sunucularımızda saklanır.
- **İzni kapatmak:** Cihazınızın uygulama izin ayarlarından "Konum" iznini istediğiniz zaman kaldırabilirsiniz. Ayrıca uygulama içi konum ayarlarından modu manuel olarak değiştirebilirsiniz.

> **Teknik doğrulama notu:** Sürekli arka plan konum takibi yapılıp yapılmadığı kesin olarak doğrulanmalıdır. Doğrulama tamamlanmadan bu konuda kesin bir beyanda bulunulmamaktadır.

---

## 6. Pazarlama E-postaları ve Bildirimler

Bu bölüm, KVKK Aydınlatma Metni ile tutarlı şekilde yazılmıştır. Pazarlama e-postası işlemleri teknik olarak doğrulanmış bir opt-in altyapısına dayanmaktadır.

### Global Platform Pazarlama İzni

Yeedoy, yeni özellikler, kampanyalar ve fırsatlar hakkında e-postalar göndermek için kullanıcının ayrı ve isteğe bağlı onayını almaktadır.

- Kullanıcı bu izni vermek zorunda değildir; uygulama bu onay olmadan da eksiksiz kullanılabilir.
- Kullanıcı, yasal kabul ekranında zorunlu onaydan bağımsız olarak ayrı bir tercih alanı ile bu izni verebilir veya reddedebilir.
- Kullanıcılar otomatik olarak pazarlama e-postalarına dahil edilmez. Varsayılan durum izin verilmemiş (opt-out) olarak başlar.
- İzin durumu sunucu tarafında kayıt altında tutulur; tüm cihazlarda geçerlidir.
- Bu izni uygulamanın "Bildirim Ayarları" ekranındaki "Pazarlama E-postaları" tercihinden dilediğiniz zaman geri çekebilirsiniz.
- Aldığınız e-postalardaki `/abonelik-iptal?token=...` bağlantısı ile de global platform iznini sonlandırabilirsiniz (6563 sayılı Kanun md. 9/3 uyumu).
- İzin geri çekildiğinde Yeedoy bu kategorideki e-postaları artık göndermez.

### İşletme Bazlı E-posta Aboneliği

Takip ettiğiniz belirli bir işletmeden kampanya ve özel teklif e-postası alabilmek için ayrıca o işletmeye özgü bir abonelik onayı gerekmektedir. Bu onay global platform izninden tamamen bağımsızdır.

- Her işletme için abonelik tercihi ayrı ayrı yönetilebilir.
- İşletme bazlı abonelik, işletme profil sayfasında veya takip akışında ilgili tercih alanı aracılığıyla yönetilebilir.
- E-postalardaki abonelik iptal bağlantısı (`/abonelik-iptal?token=...`) yalnızca ilgili işletmeye ait aboneliği sonlandırır; global platform iznini etkilemez.

### Çift Filtre Kuralı

Bir kullanıcıya kampanya e-postası gönderilebilmesi için iki iznin de aynı anda sağlanmış olması zorunludur:

1. Global platform pazarlama e-posta izni (açık rıza ile alınmış)
2. İlgili işletme için e-posta aboneliği (işletme bazlı onay ile alınmış)

Bu koşullardan biri sağlanmamışsa kullanıcı alıcı listesine dahil edilmez. Bu kuralın güvenli çalışması için `UNSUBSCRIBE_HMAC_SECRET` ortam değişkeninin production ortamında tanımlı olması zorunludur; aksi hâlde e-posta kampanyaları teknik olarak durdurulur (fail-closed davranış).

### Abonelik İptal Mekanizması

Her kampanya e-postasında çalışan bir abonelik iptal bağlantısı yer almaktadır. Bu bağlantı HMAC-SHA256 ile imzalanmış ve süre sınırına tabi bir token içerir; sunucu tarafında doğrulama yapılarak ilgili abonelik sonlandırılır. Geçersiz veya süresi dolmuş tokenler herhangi bir veritabanı değişikliğine yol açmaz.

> **Hukukçuya not:** Pazarlama e-postası için KVKK md.5/1 kapsamındaki açık rıza ile 6563 sayılı Kanun md.6 kapsamındaki ticari elektronik ileti onayının birleştirilebilir olup olmadığı veya ayrı alınması gerekip gerekmediği değerlendirilmelidir. Açık rıza metni ayrıca hazırlanması gerekiyorsa bu bölüm ona atıfta bulunacak şekilde güncellenmelidir.

---

## 7. Verilerinizi Kimlerle Paylaşabiliriz?

Kişisel verilerinizi üçüncü taraflarla satmıyoruz. Veriler yalnızca aşağıda belirtilen amaçlarla ve belirtilen taraflarla paylaşılmaktadır.

### Supabase (Veritabanı, Kimlik Doğrulama, Dosya Depolama)

| Bilgi | Değer |
|---|---|
| Şirket | Supabase, Inc. |
| Sunucu konumu | Frankfurt, Almanya (AB bölgesi) |
| Aktarılan veriler | Hesap verileri, profil, kullanıcı içerikleri, bildirim verileri, işletme verileri — veritabanına yazılan tüm veriler |
| Amaç | Veritabanı, kimlik doğrulama, dosya depolama (CDN) altyapısı |
| Aktarım türü | Yurt dışı aktarım |
| DPA durumu | [SUPABASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

### Firebase / Google (Push Bildirim ve Sosyal Giriş)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | FCM push token, bildirim içeriği; Google ile giriş yapıldığında Google hesap e-postası, adı, profil resmi |
| Amaç | Push bildirim iletimi; Google ile sosyal giriş (OAuth 2.0 PKCE) |
| Aktarım türü | Yurt dışı aktarım |
| DPA durumu | [FIREBASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

### Resend (E-posta Gönderim Servisi)

| Bilgi | Değer |
|---|---|
| Şirket | Resend (ABD) |
| Aktarılan veriler | E-posta adresi, görünen ad |
| Amaç | Transactional e-posta (şifre sıfırlama, bilgilendirme) ve kullanıcı izni varsa kampanya e-postaları |
| Aktarım türü | Yurt dışı aktarım |
| DPA durumu | [RESEND_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

> Kampanya e-postalarında yalnızca hem global platform iznini hem de işletme bazlı aboneliği aynı anda sağlamış kullanıcılar alıcı listesine dahil edilir (Bölüm 6'daki çift filtre kuralı).

### Firebase Crashlytics / Analytics / Performance (Çökme İzleme, Analitik, Performans)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | Anonim hata/çökme izleri, cihaz tipi (Crashlytics); kullanım olayları, cihaz/uygulama bilgisi (Analytics); performans izleri (Performance) |
| Amaç | Uygulama çökmelerini izlemek, kullanım analitiği ve performans ölçümü |
| Aktarım türü | Yurt dışı aktarım |
| DPA durumu | [FIREBASE_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

> Crashlytics hata izlerinde istem dışı kişisel veri bulunabileceği riski değerlendirilmelidir.

### Google AdMob (Uygulama İçi Reklam — Yalnızca Mobil)

| Bilgi | Değer |
|---|---|
| Şirket | Google LLC (ABD) |
| Aktarılan veriler | Reklam tanımlayıcısı (Android Advertising ID / iOS IDFA), reklam gösterim/tıklama |
| Amaç | Uygulama içi reklam gösterimi ve ölçümü |
| Aktarım türü | Yurt dışı aktarım |
| DPA durumu | [ADMOB_DPA_DURUMU] |
| Yurt dışı aktarım güvencesi | [YURT_DISI_AKTARIM_DURUMU] |

> iOS'ta App Tracking Transparency (ATT) çerçevesi kapsamında izleme izni alınır; Google Play Data Safety ve App Store gizlilik beyanları bu kullanımı yansıtacak şekilde yapılandırılmalıdır. [HUKUKCU_KONTROLU]

### SMS Hizmet Sağlayıcısı

| Bilgi | Değer |
|---|---|
| Şirket | [SMS_SAGLAYICI_ADI] |
| Aktarılan veriler | Telefon numarası |
| Amaç | SMS ile tek kullanımlık giriş kodu (OTP) gönderimi |
| Aktarım türü | [YURT_DISI_AKTARIM_DURUMU] |
| DPA durumu | [SMS_SAGLAYICI_DPA_DURUMU] |

### Hosting ve CDN Sağlayıcıları

Platformun sunulabilmesi için kullanılan hosting ve içerik dağıtım ağı (CDN) sağlayıcıları ile teknik altyapı kapsamında sınırlı veriler paylaşılabilir. Bu sağlayıcılar [HOSTING_SAGLAYICI] şirketi tarafından işletilmektedir.

### Yetkili Kamu Kurumları

Yürürlükteki mevzuat kapsamında yetkili kamu kurumlarının yasal talepleri doğrultusunda kişisel veriler ilgili kurumlara aktarılabilir.

### Yurt Dışı Aktarım Genel Durumu

Supabase, Google/Firebase (Crashlytics, Analytics, Performance, AdMob) ve Resend yurt dışında yerleşik şirketlerdir. Bu aktarımlar KVKK'nın 9. maddesi kapsamında değerlendirilmektedir. Her bir sağlayıcı için DPA (Veri İşleme Anlaşması) ve yurt dışı aktarım güvencesi durumu yukarıdaki tablolarda `[PLACEHOLDER]` olarak işaretlenmiştir; yayın öncesinde doldurulması zorunludur.

---

## 8. Verilerinizi Nasıl Koruyoruz?

Kişisel verilerinizin güvenliği için çeşitli teknik ve idari tedbirler uygulamaktayız.

**Erişim kontrolü ve yetkilendirme:**
- Veritabanında Satır Düzeyinde Güvenlik (RLS) politikaları ile her kullanıcı yalnızca kendi verilerine erişebilir.
- Rol tabanlı erişim kontrolü (RBAC) ile admin, işletme sahibi ve kullanıcı rolleri ayrıştırılmıştır.
- Tüm Supabase işlemleri için SECURITY DEFINER fonksiyonlar kullanılmakta; UI katmanından doğrudan veritabanı erişimi engellenmektedir.

**Güvenli oturum yönetimi:**
- Oturum tokenleri JWT standardıyla oluşturulmakta ve sunucu tarafında doğrulanmaktadır.
- Şifreler düz metin olarak saklanmaz; yalnızca güvenli hash formatında tutulur.

**Veri minimizasyonu:**
- Politika kabul kayıtlarında IP adresi ve tarayıcı kimliği (user-agent) otomatik olarak toplanmamaktadır. Bu karar, veri minimizasyonu ilkesi doğrultusunda alınmıştır.
- FCM push token'lar 120 gün hareketsizlik sonrasında otomatik olarak silinmektedir.

**Hata izleme ve PII koruma:**
- Firebase Crashlytics çökme izleme aracında yalnızca anonim hata izleri ve cihaz tipi toplanır; kişisel veri minimize edilir.

> **Teknik doğrulama notu:** Crashlytics hata izlerinde istem dışı kişisel veri sızmaması için yapılandırmanın periyodik denetlenmesi gerekmektedir. Bu denetim üretim öncesinde gerçekleştirilmelidir.

**İletişim güvenliği:**
- Tüm veri iletişimi TLS (HTTPS) üzerinden şifrelenerek gerçekleşmektedir.
- Servis anahtarları (service role) istemci tarafına taşınmamaktadır.

**Kötüye kullanım önleme:**
- Rate-limit mekanizması ile spam ve kötüye kullanım girişimleri engellenmektedir.
- İçerik moderasyonu ve gölge-ban sistemi platform güvenliğini desteklemektedir.

Alınan tüm teknik önlemlere karşın hiçbir sistem mutlak güvenlik sağlayamamaktadır. Bir güvenlik ihlali tespit etmeniz hâlinde lütfen [DESTEK_EPOSTA] adresine bildirin.

---

## 9. Veri Saklama ve Silme

Kişisel verileriniz, işleme amacının gerektirdiği süre boyunca saklanır; amacın sona ermesiyle birlikte silinir, anonimleştirilir veya ilgili yasal yükümlülük kapsamında arşivlenir.

> **Uyarı:** Aşağıdaki tabloda `[PLACEHOLDER]` içeren saklama süreleri, henüz kesin karar verilmemiş açık maddelerdir. Bu placeholder'lar doldurulmadan ilgili veriler için doğru bir saklama politikası uygulanamaz ve metin yayına alınamaz. Saklama süreleri için kesin rakamların hukukçu tarafından belirlenmesi zorunludur.

| Veri Kategorisi | Saklama Süresi | Açıklama |
|---|---|---|
| Hesap ve kimlik verileri | Hesap silinene kadar | Kullanıcı hesabını sildiğinde ilgili veriler de kaldırılır |
| Profil verileri (görünen ad, avatar) | Hesap silinene kadar | — |
| Konum tercihleri (şehir/ilçe) | Kullanıcı değiştirinceye veya hesap silinene kadar | Kullanıcı ayarlardan silebilir |
| Kullanıcı yorumları ve puanları | [SAKLAMA_SURESI_KULLANICI_ETKILESIM] | Hesap silindiğinde yorum anonim mi kalabilir yoksa silinmeli mi kararı hukukçuya sorulacak |
| Favoriler | Hesap silinene kadar | — |
| FCM push token | 120 gün hareketsizlik sonrası otomatik silinir | Oturum kapatmada da silinir |
| Bildirim içerikleri | [SAKLAMA_SURESI_BILDIRIMLER] | — |
| Politika kabul kayıtları | [SAKLAMA_SURESI_POLICY_ACCEPTANCE] | KVKK ispat yükümlülüğü için hukukçu tarafından belirlenecek |
| KVKK başvuruları ve hesap silme talepleri | [SAKLAMA_SURESI_DESTEK] | İdari işlem kaydı; önerimiz en az 3-5 yıl; hukukçuya sorulacak |
| İşletme sahipliği başvuruları | [SAKLAMA_SURESI_OWNER_CLAIMS] | Ad, telefon, kanıt belgesi içeriyor; karar tarihinden itibaren süre belirlenecek |
| Analitik olay logu | [SAKLAMA_SURESI_ANALYTICS] | Kullanıcı ID içermekte; saklama süresi veya anonimleştirme kararı gerekiyor |
| Pazarlama izin durumu ve opt-in zamanı | [SAKLAMA_SURESI_MARKETING_CONSENT] | KVKK ispat yükümlülüğü kapsamında belirlenecek |
| Sunucu log kayıtları | [SAKLAMA_SURESI_LOGS] | Teknik operasyon; önerimiz 30 gün |
| Politika sürüm kataloğu | Süresiz | Değiştirilemez yasal kayıt |

### Hesabınızı Silebilirsiniz

Uygulamanın "Hesap Ayarları" bölümündeki "Hesabımı Sil" seçeneği veya [KVKK_BASVURU_EPOSTA] adresine iletilen yazılı talep ile hesabınızın silinmesini isteyebilirsiniz. Hesap silinmesine ilişkin teknik süreç ve hangi verilerin yasal yükümlülükler nedeniyle belirli bir süre daha saklanabileceği konusundaki detaylar ayrı bir "Veri Silme Talebi" belgesi ile açıklanacaktır.

Bazı veriler (politika kabul kayıtları, KVKK başvuruları gibi) yasal yükümlülükler çerçevesinde hesap silinmesinden sonra belirli bir süre arşivlenebilir. Bu veriler yalnızca yasal zorunlulukların gerektirdiği kapsamda ve sürede tutulur.

---

## 10. Çerezler ve Benzeri Teknolojiler

Web sitemizde ve QR menü sayfalarımızda oturum yönetimi ve teknik işleyiş için çerezler ile yerel depolama teknolojileri kullanılabilir.

- Web tarafında Supabase oturum tokeni çerez veya yerel depolama aracılığıyla saklanmaktadır.
- Analitik amaçlı kullanılan tanımlayıcılar (client_id gibi) hakkında detaylı bilgi ayrı Çerez Politikası'nda yer almaktadır.
- Bu bölüm Çerez Politikası'nın yerini tutmaz. Çerez envanteri, zorunlu/analitik çerez ayrımı ve kullanıcı onay mekanizması ayrı bir Çerez Politikası belgesi ile düzenlenecektir.

**Mobil uygulama:** Mobil uygulamada tarayıcı çerezi kullanılmamaktadır. Bunun yerine cihaz izinleri, push token ve uygulama depolama alanı kullanılmaktadır.

**iOS Siri / Google Assistant Kısayolları:** Yeedoy mobil uygulaması, iOS'ta Siri Kısayolları ve Android'de Uygulama Kısayolları özelliği aracılığıyla "Yakın yer keşfet" gibi akışları başlatmak için cihaz düzeyinde aktivite kaydı yapar. Bu bilgiler yalnızca cihaz üzerinde işlenir ve Yeedoy sunucularına gönderilmez.

---

## 11. Haklarınız ve Tercihleriniz

6698 sayılı KVKK'nın 11. maddesi uyarınca aşağıdaki hakları kullanabilirsiniz:

**Erişim hakkı:** Yeedoy'un hangi kişisel verilerinizi işlediğini öğrenebilirsiniz.

**Düzeltme hakkı:** Yanlış veya eksik kişisel verilerinizin düzeltilmesini talep edebilirsiniz. Profil bilgilerinizi uygulamanın "Profil Düzenleme" ekranından doğrudan güncelleyebilirsiniz.

**Silme veya yok etme hakkı:** Kişisel verilerinizin silinmesini veya yok edilmesini talep edebilirsiniz. Bu talebi uygulama içi "Hesabımı Sil" akışı veya [KVKK_BASVURU_EPOSTA] adresi üzerinden iletebilirsiniz.

**İşlemeyi kısıtlama hakkı:** Belirli koşullarda kişisel verilerinizin işlenmesinin kısıtlanmasını isteyebilirsiniz.

**İtiraz hakkı:** Meşru menfaate dayalı işleme faaliyetlerine itiraz edebilirsiniz.

**Zarar giderme hakkı:** Kanuna aykırı veri işleme nedeniyle uğradığınız zararın giderilmesini talep edebilirsiniz.

### Pazarlama E-postasını Kapatmak

Uygulamanın "Bildirim Ayarları" ekranındaki "Pazarlama E-postaları" seçeneğini kapatarak global platform pazarlama iznini dilediğiniz zaman geri çekebilirsiniz. Aldığınız e-postalardaki abonelik iptal bağlantısını kullanmak da bir seçenektir. İzin geri çekildiğinde Yeedoy bu kategorideki e-postaları artık göndermez.

### Konum İznini Kapatmak

Cihazınızın uygulama izin ayarlarından "Konum" iznini kaldırabilirsiniz. Ayrıca uygulama ayarlarından konum modunu "Manuel" olarak değiştirebilirsiniz.

### Push Bildirimleri Kapatmak

Cihazınızın bildirim ayarlarından Yeedoy için bildirimleri kapatabilirsiniz.

### Başvuru Kanalları

| Kanal | Adres | Açıklama |
|---|---|---|
| E-posta | [KVKK_BASVURU_EPOSTA] | KVKK başvuruları için tercih edilen kanal |
| Yazılı başvuru | [ADRES] | Kimlik belgesi ile birlikte |
| Genel destek | [DESTEK_EPOSTA] | Hesap ve teknik sorular için |

Başvurunuzda ad soyadınızı, iletişim bilginizi, talep türünü ve ilgili hesap bilgisini belirtmeniz süreci hızlandıracaktır. Başvurular yasal süre içinde yanıtlanır.

### KVK Kurumu'na Şikayet

Başvurunuzun yetersiz karşılandığını düşünüyorsanız Kişisel Verileri Koruma Kurumu'na (kvkk.gov.tr) şikayette bulunma hakkınız saklıdır.

---

## 12. Çocukların Gizliliği

Yeedoy, çocuklara özel olarak tasarlanmamış bir platformdur. Platformun kullanımı için minimum yaş sınırı [YAS_SINIRI] olarak belirlenmiştir.

[YAS_SINIRI] yaşın altındaki kişilerin kişisel verilerini bilerek toplamıyoruz. Bu yaş sınırını aşmayan bir kullanıcının kaydı tespit edilmesi durumunda ilgili veriler silinir.

> **Hukukçuya kontrol ettirilmeli:** Minimum yaş sınırının ([YAS_SINIRI]) hukuki dayanağı, uygulanabilirliği ve çocuğun velisi/vasisi için rıza gereksinimleri değerlendirilmelidir. Yaş doğrulama mekanizmasının teknik olarak uygulanıp uygulanmayacağı da hukukçuyla kararlaştırılmalıdır.

---

## 13. Politika Değişiklikleri

Bu Gizlilik Politikası zaman zaman güncellenebilir. Önemli değişiklikler yapılması durumunda kullanıcılar uygulama içi bildirim veya e-posta yoluyla bilgilendirilebilir. Politikanın güncel versiyonu her zaman [WEB_SITESI]/gizlilik-politikasi adresinde yayımlanır.

Politika kabulleriniz; kullanıcı kimliği, kabul edilen politika sürümü, kabul zamanı ve kaynak uygulama bilgisiyle kayıt altına alınır. Politika kabul kayıtlarında IP adresi veya tarayıcı/uygulama kimliği (user-agent) otomatik olarak saklanmamaktadır; bu karar veri minimizasyonu ilkesi doğrultusunda teknik olarak uygulanmıştır.

---

## 14. Uygulamada Gösterilecek Kısa Özet

Aşağıdaki özet, uygulama içi gizlilik bilgi kartında veya yasal işlemler ekranında gösterilmek üzere hazırlanmıştır. Tam metin için bu sayfanın bütünü bağlantılanmalıdır.

---

**Gizliliğiniz Hakkında Kısa Bilgi**

1. Hesap, konum arama, yorumlar ve bildirimler için gerekli kişisel verileriniz [VERI_SORUMLUSU_UNVANI] tarafından işlenmektedir.
2. GPS koordinatlarınız sunuculara kalıcı olarak iletilmez; yalnızca cihazınızda yakın işletme hesaplaması için kullanılır.
3. Yorumlarınız görünen adınızla birlikte kamuya açık olarak gösterilir.
4. Pazarlama e-postaları yalnızca ayrıca verdiğiniz onay doğrultusunda gönderilir. Bildirim Ayarları ekranından veya e-postadaki bağlantıdan dilediğiniz zaman durdurabilirsiniz.
5. Verileriniz; Supabase (altyapı), Google/Firebase (giriş, bildirim, çökme izleme, analitik, performans, reklam) ve Resend (e-posta) hizmet sağlayıcılarıyla paylaşılabilir.
6. Erişim, düzeltme, silme ve itiraz haklarınız için [KVKK_BASVURU_EPOSTA] adresine başvurabilirsiniz.
7. Tam Gizlilik Politikası için: [WEB_SITESI]/gizlilik-politikasi

---

## 15. Eksik Bilgiler ve Hukukçuya Sorulacaklar

Aşağıdaki maddeler yayın öncesinde yanıtlanmalıdır. Bazıları teknik karar, bazıları hukuki görüş gerektirmektedir.

| # | Soru | Kaynak | Öncelik |
|---|---|---|---|
| S-1 | Veri sorumlusu bilgileri (unvan, adres, iletişim) tamamlandı mı? Placeholder'lar dolduruldu mu? | Tüm belgeler | Kritik |
| S-2 | Supabase, Google/Firebase (Crashlytics/Analytics/Performance/AdMob), Resend ile DPA imzalandı mı? Yurt dışı aktarım güvencesi (KVKK md.9) karşılandı mı? | legal-preflight-report.md | Kritik |
| S-16 | Firebase Analytics/Performance için meşru menfaat yeterli midir? AdMob için iOS ATT ve Google Play Data Safety beyanı yapılandırıldı mı; kişiselleştirilmiş reklam için ayrı açık rıza gerekir mi? | cerez-politikasi.md — Ç-3 | Kritik |
| S-3 | Saklama süreleri ([PLACEHOLDER]) için hukukçu kararı verildi mi? | legal-preflight-report.md | Kritik |
| S-4 | IP adresi içermeyen politika kabul kaydı (kullanıcı kimliği + sürüm + zaman) KVKK ispat yükümlülüğü için yeterli midir? | r4-r5-end-to-end-qa-report.md | Kritik |
| S-5 | Global `marketing_email_opt_in` ve işletme bazlı `business_follows.is_subscribed_email` çift filtresi hukuki metinde yeterince açıklanmış mı? İşletme bazlı kampanyalarda ayrıca işletme bazlı yazılı rıza veya denetim kaydı gerekir mi? | r5-marketing-optin-data-model-decision.md | Kritik |
| S-6 | Pazarlama e-postası için KVKK md.5/1 kapsamındaki açık rıza ile 6563 sayılı Kanun md.6 kapsamındaki ticari elektronik ileti onayı ayrı alınmalı mıdır? Ayrı bir açık rıza metni hazırlanması gerekiyor mu? | kvkk-aydinlatma-metni.md | Kritik |
| S-7 | Kullanıcı hesabı silindiğinde yorumlar tamamen silinmeli mi, yoksa anonim kalabilir mi? (İçerik saklanır, ad kaldırılır seçeneği) | legal-preflight-report.md | Yüksek |
| S-8 | Çocukların gizliliği: Minimum kullanım yaşı ([YAS_SINIRI]) hukuki dayanağı ve yaş doğrulama mekanizması gerekli mi? | legal-preflight-report.md | Yüksek |
| S-9 | `marketing_email_opted_in_at` alanı opt-out sırasında NULL yapılmaktadır. Opt-out geçmişi ayrı bir tabloda tutulmalı mı? Bu mevcut yapı KVKK ispat yükümlülüğü için yeterli mi? | r5-marketing-optin-data-model-decision.md | Yüksek |
| S-10 | İşletme sahipliği başvuruları (ad, telefon, kanıt belgesi): Reddedilen başvurular için ticaret hukuku veya vergi mevzuatı kapsamında zorunlu saklama süresi var mı? | legal-preflight-report.md | Yüksek |
| S-11 | Web `/bildirim-ayarlari` sayfasında global pazarlama izni RPC yerine doğrudan tablo güncellemesiyle yönetilmektedir. Bu mimari sapma hukuki açıdan risk taşır mı; RLS'e dayanması yeterli midir? | r4-r5-end-to-end-qa-report.md | Orta |
| S-12 | Çerez Politikası ayrı hazırlanmalı mı? Web tarafındaki çerez envanteri (Supabase session token, analitik client_id) tamamlanmış mı? Çerez onay banner gerekliliği değerlendirildi mi? | legal-preflight-report.md | Orta |
| S-13 | `analytics_events` tablosunda kullanıcı kimliği içeren olay loglarının meşru menfaat kapsamında işlenmesi KVKK açısından kabul edilebilir mi? Yoksa anonimleştirme zorunlu mu? | legal-data-inventory.md | Orta |
| S-14 | Konum izni geri çekildiğinde sistem otomatik olarak kullanıcının konum tercihini siliyor mu, yoksa manuel müdahale mi gerekiyor? | legal-preflight-report.md | Orta |
| S-15 | SMS OTP sağlayıcısı ([SMS_SAGLAYICI_ADI]) teyit edildi mi? DPA imzalandı mı? | legal-preflight-report.md | Orta |

---

## 16. Production Öncesi Teknik Bloklayıcılar

Aşağıdaki teknik maddeler kapatılmadan e-posta kampanyası sistemi ve bu politikanın taahhüt ettiği teknik altyapı production ortamında tam olarak çalışmıyor demektir. Bu maddelerden herhangi biri eksikse e-posta kampanyası canlıya alınamaz.

### Veritabanı Migration'ları (Production'a Uygulanmamış)

| Migration Dosyası | İçerik | Durum |
|---|---|---|
| `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` | IP adresi ve user-agent otomatik toplama bloğunu kaldırır; mevcut kayıtlardaki verileri NULL'a çeker | Oluşturuldu — production'a uygulanmadı |
| `20260620000001_user_profiles_marketing_email_opt_in.sql` | `user_profiles` tablosuna `marketing_email_opt_in` (DEFAULT false) ve `marketing_email_opted_in_at` sütunlarını ekler | Oluşturuldu — production'a uygulanmadı |
| `20260620000002_r5_marketing_email_rpcs.sql` | `get_my_notification_preferences_v1`, `update_my_marketing_email_opt_in_v1`, `update_business_email_subscription_v1` RPC'lerini oluşturur; `business_follows` UPDATE RLS policy'si ekler | Oluşturuldu — production'a uygulanmadı |

### Ortam Değişkenleri ve Secrets

| Değişken | Nerede | Durum |
|---|---|---|
| `UNSUBSCRIBE_HMAC_SECRET` | Next.js production `.env` | Eklenmeli — eksikse kampanya fail-closed durur |
| `UNSUBSCRIBE_HMAC_SECRET` | Supabase Edge Function secrets | Aynı değer ile eklenmeli (Next.js ile eşleşmeli) |
| `SITE_URL` | Next.js production `.env` | Doğru production URL olmalı |

### Doğrulama Testleri

| Test | Açıklama |
|---|---|
| Web typecheck ve lint | `npm run typecheck` ve `npm run lint` temiz çalışmalı |
| Web birim testleri | `npm run test:unit` — 27 unsubscribe-token testi geçmeli |
| Local/staging veritabanı testleri | Migration'lar `supabase start` + `supabase db reset` ortamında test edilmeli; IP NULL kontrolü ve RPC davranışları doğrulanmalı |
| Flutter analyze | 0 hata/uyarı (mevcut durumda temiz) |
| Flutter birim testleri | 27/27 R-5 testi geçmeli (mevcut durumda geçiyor) |
| E-posta kampanyası uçtan uca testi | Staging ortamında: opt-in kullanıcıya gönderim başarılı, opt-out kullanıcıya gönderilmiyor, unsubscribe linki çalışıyor doğrulanmalı |

> E-posta kampanyası, yukarıdaki tüm maddeler kapatılmadan production ortamında canlıya alınamaz.

---

## Referans Belgeler

Bu Gizlilik Politikası aşağıdaki teknik ve analiz belgelerine dayanılarak hazırlanmıştır:

| Belge | Konu |
|---|---|
| `docs/legal/legal-data-inventory.md` | Kişisel veri envanteri |
| `docs/legal/legal-preflight-report.md` | Hukuki ön kontrol raporu ve placeholder listesi |
| `docs/legal/critical-privacy-gaps-report.md` | R-4 ve R-5 kritik gizlilik eksikleri |
| `docs/legal/r4-ip-metadata-decision-plan.md` | IP metadata kaldırma karar planı |
| `docs/legal/r5-marketing-optin-data-model-decision.md` | Pazarlama opt-in veri modeli karar raporu |
| `docs/legal/r5-email-filter-token-hardening-report.md` | E-posta filtresi ve token sertleştirme raporu |
| `docs/legal/r5-flutter-marketing-optin-implementation-report.md` | Flutter pazarlama opt-in uygulama raporu |
| `docs/legal/r4-r5-end-to-end-qa-report.md` | Uçtan uca QA doğrulama raporu |
| `docs/legal/kvkk-aydinlatma-metni.md` | KVKK Aydınlatma Metni taslağı |

---

*Bu belge yayına hazır kesin hukuki metin değildir. Hukuki geçerlilik için tüm placeholder'ların doldurulması ve bir hukuk danışmanı tarafından onaylanması zorunludur. Bu metin KVKK Aydınlatma Metni'nin yerine geçmez; ona ek bir belgedir.*
