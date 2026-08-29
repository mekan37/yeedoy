# Yeedoy — Veri Silme Talebi ve Başvuru Prosedürü

## 1. Belge Durumu ve Uyarı

**Durum:** TASLAK — Yayına hazır kesin metin değildir.

- Bu belge bir **taslak metindir**.
- Yayın öncesinde KVKK ve veri koruma alanında uzmanlaşmış bir **hukuk danışmanı tarafından kontrol edilmeli ve onaylanmalıdır**.
- Bu belge, **KVKK Aydınlatma Metni** (`kvkk-aydinlatma-metni.md`) ve **Gizlilik Politikası** (`gizlilik-politikasi.md`) ile **birlikte değerlendirilmelidir**; onların yerine geçmez.
- Belgedeki kesin **saklama süreleri ve yasal istisnalar**, hukukçu tarafından onaylanmadan yayına alınmamalıdır. `[PLACEHOLDER]` içeren tüm alanlar doldurulmadan metin yayınlanamaz.
- Bu belge bir açık rıza metni değildir.

**Tarih:** [YURURLUK_TARIHI]

---

## 2. Amaç ve Kapsam

Bu belge, Yeedoy kullanıcılarının kişisel verilerinin silinmesi, yok edilmesi veya anonim hale getirilmesi ile pazarlama izinlerinin geri çekilmesine ilişkin talep ve başvuru süreçlerini açıklar.

Kapsanan talep ve veri türleri:

- Hesap silme (hesap ve profil verileri)
- Belirli veri türlerinin silinmesi (yorum, puan, favori, check-in, konum verileri vb.)
- Pazarlama e-posta izninin geri çekilmesi (global platform izni)
- İşletme bazlı e-posta aboneliğinin kapatılması
- Destek talebi ve KVKK başvuru geçmişine ilişkin veriler
- İşletme sahipliği başvurusuyla ilişkili veriler
- Web / QR menü tarafında ve mobil uygulamada işlenen veriler

**Not:** Pazarlama izninin geri çekilmesi, veri silme talebinden farklı bir işlemdir (bkz. Bölüm 12).

---

## 3. Silme, Yok Etme ve Anonimleştirme Farkı

KVKK kapsamında kişisel verilerin "imha edilmesi" üç farklı yöntemle gerçekleşebilir. Kullanıcı açısından özetle:

- **Silme:** Verinin ilgili kullanıcılar için erişilemez ve tekrar kullanılamaz hale getirilmesi. Veri sistemden kaldırılır.
- **Yok etme:** Verinin hiçbir şekilde kurtarılamayacak, okunamayacak ve yeniden kullanılamayacak şekilde tamamen ortadan kaldırılması.
- **Anonimleştirme:** Verinin, hiçbir şekilde belirli veya belirlenebilir bir kişiyle ilişkilendirilemeyecek hale getirilmesi. Bu durumda veri artık kişisel veri sayılmaz; ancak kişiyle bağı koparılmış içerik (örneğin adı kaldırılmış bir yorum) platformda kalabilir.

Hangi veri için hangi yöntemin ne zaman uygulanacağı, veri türüne ve yasal yükümlülüğe göre değişir.

> **Teknik uygulama notu:** Yeedoy'da silme, yok etme ve anonimleştirme yöntemlerinin hangi tablo/işlem için kesin olarak uygulandığı henüz net değildir (örneğin hesap silindiğinde yorumların tamamen silinmesi mi yoksa anonim bırakılması mı). Bu nedenle her veri türü için uygulanan yöntem **teknik olarak ayrıca doğrulanmalıdır** (bkz. Bölüm 15-16).

---

## 4. Hangi Talepler Yapılabilir?

Kullanıcı aşağıdaki taleplerden birini veya birkaçını iletebilir:

- **Hesabımı sil** — Hesabımı ve ilişkili kişisel verilerimi sil.
- **Tüm kişisel verilerimi sil / yok et / anonimleştir** — KVKK kapsamında kişisel verilerimin imha edilmesini talep ediyorum.
- **Belirli yorumlarımı veya içeriklerimi sil** — Yalnızca seçtiğim içerikleri kaldır.
- **Favorilerimi / check-in kayıtlarımı sil.**
- **Konumla ilişkili verilerimi sil** — Şehir/ilçe tercihi, fiyat uyarısı konum kriterleri vb.
- **Destek talebi geçmişimi sil.**
- **İşletme sahipliği başvurumla ilişkili verileri sil.**
- **Pazarlama e-posta iznimi geri çek** — Yeedoy platform geneli kampanya e-postalarını almak istemiyorum.
- **İşletme bazlı e-posta aboneliğimi kapat** — Belirli bir işletmenin kampanya e-postalarını almak istemiyorum.

> **Önemli ayrım:** "Pazarlama e-posta izninin geri çekilmesi" ve "işletme bazlı e-posta aboneliğinin kapatılması" birer **veri silme talebi değildir**. Bu işlemler, halihazırda işlenen verinin silinmesini sağlamaz; yalnızca gelecekte ticari e-posta gönderilmemesini sağlar. Detaylar Bölüm 12'dedir.

---

## 5. Hangi Veriler Hemen Silinebilir, Hangileri Sınırlı Saklanabilir?

> Aşağıdaki tablo bir taslaktır. Silme/yok etme/anonimleştirme yöntemi ve saklama süreleri hukukçu onayı ve teknik doğrulama olmadan kesinleştirilemez. `[PLACEHOLDER]` saklama süreleri doldurulmadan yayınlanamaz.

| Veri türü | Talep halinde işlem | Silme / yok etme / anonimleştirme ihtimali | Yasal saklama istisnası olabilir mi? | Placeholder saklama süresi | Hukukçu kontrolü notu |
|---|---|---|---|---|---|
| Hesap ve profil (e-posta, görünen ad, avatar, telefon) | Hesap silme akışında kaldırılır | Silme; ilişkili kayıtlar büyük ölçüde silinebilir | Sınırlı (yasal ispat kayıtları hariç) | `[SAKLAMA_SURESI_HESAP]` | Hesap silme sonrası hangi kalemlerin tamamen silineceği netleştirilmeli |
| Yorumlar / puanlar | Talebe göre silinir veya anonimleştirilir | Silme **veya** anonimleştirme (karar bekliyor) | Düşük; içerik kamuya açık | `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | Kamuya açık yorumların silinmesi mi anonimleştirilmesi mi gerektiği hukukçuya sorulacak |
| Favoriler / check-in | Silinir | Silme | Yok | `[SAKLAMA_SURESI_KULLANICI_ETKILESIM]` | Düşük risk |
| Konum verileri (şehir/ilçe tercihi, fiyat uyarısı konumu) | Silinir | Silme | Yok | `[SAKLAMA_SURESI_KONUM]` | GPS koordinatı kalıcı saklanmaz; tercih verisi silinebilir |
| Destek talepleri / KVKK başvuruları | Süreç sonrası saklanabilir | Silme veya arşiv | **Evet** — idari işlem kaydı | `[SAKLAMA_SURESI_DESTEK]` | İdari başvuru kayıtları için zorunlu saklama süresi hukukçuya sorulacak |
| Politika kabul kayıtları | Yasal ispat için saklanır | Arşiv (silme sınırlı) | **Evet** — KVKK ispat yükümlülüğü | `[SAKLAMA_SURESI_POLICY_ACCEPTANCE]` | IP/UA içermez; ispat için yeterlilik hukukçuya sorulacak |
| İşletme sahipliği başvuruları (ad, telefon, kanıt belge) | Karar sonrası saklanabilir | Silme veya arşiv | Olası (ticaret/vergi) | `[SAKLAMA_SURESI_OWNER_CLAIMS]` | Reddedilen başvurularda zorunlu saklama süresi hukukçuya sorulacak |
| Pazarlama izin kayıtları (global opt-in + opt-in zamanı) | İzin geri çekilir; kayıt ispat için tutulabilir | Arşiv / güncelleme | **Evet** — 6563 sayılı Kanun ispat | `[SAKLAMA_SURESI_MARKETING_CONSENT]` | Opt-out geçmişinin ayrıca tutulması gerekip gerekmediği hukukçuya sorulacak |
| E-posta gönderim / abonelikten çıkma kayıtları | Süreç kayıtları sınırlı tutulur | Arşiv | Olası — ileti gönderim ispatı | `[SAKLAMA_SURESI_MARKETING_CONSENT]` | Gönderim/iptal loglarının saklanma gerekliliği hukukçuya sorulacak |
| Teknik loglar ve güvenlik kayıtları | Süre sonunda otomatik silinir | Silme | Sınırlı — güvenlik | `[SAKLAMA_SURESI_LOGS]` | Sunucu log saklama süresi belirlenmeli |
| Analitik olaylar | Süre/anonimleştirme kararına bağlı | Silme veya anonimleştirme | Düşük — meşru menfaat | `[SAKLAMA_SURESI_ANALYTICS]` | Kullanıcı kimliği içeren olay loglarının anonimleştirilmesi hukukçuya sorulacak |
| Yasal / audit kayıtları (politika sürüm kataloğu vb.) | Saklanır | Arşiv (değiştirilemez) | **Evet** — yasal kayıt | `[SAKLAMA_SURESI_YASAL_AUDIT]` | Değiştirilemez kayıtların saklama süresi hukukçuya sorulacak |

---

## 6. Hesap Silme Akışı

1. Talep, uygulama içindeki ilgili ekrandan veya Bölüm 8'deki başvuru kanallarından iletilebilir.
2. Kötüye kullanımı önlemek ve başkasının hesabını etkilemesini engellemek için **kimlik doğrulama gerekebilir**.
3. Hesap silme işlemi tamamlandığında hesap ve profil verileri ile bunlara doğrudan bağlı kişisel veriler silinir veya anonimleştirilir. Hangi kalemlerin tamamen silineceği, hangilerinin anonimleştirileceği teknik olarak netleştirilmelidir (bkz. Bölüm 15-16).
4. **Kamuya açık yorum ve puanlar** için işlem; yorumun tamamen silinmesi veya kullanıcı kimliğinden koparılarak anonim bırakılması seçeneklerinden biri olarak ele alınır. Bu karar hukukçu onayına tabidir (bkz. Bölüm 16).
5. Kullanıcının açık bir **işletme sahipliği başvurusu** varsa, bu başvuru ayrıca değerlendirilebilir ve yasal/ticari saklama yükümlülükleri çerçevesinde işlem görür.
6. **Yasal saklama gerektiren kayıtlar** (politika kabul kayıtları, KVKK başvuru kayıtları, gerekli audit kayıtları) ilgili sürelerle sınırlı olarak saklanabilir.
7. Talep sonuçlandığında kullanıcıya **bilgi verilir**.

> Hesap silme işleminde her verinin anında ve eksiksiz silineceği taahhüt edilmemektedir. Bazı veriler yasal yükümlülükler nedeniyle sınırlı süre saklanabilir; bazı kamuya açık içerikler anonimleştirilebilir.

---

## 7. Uygulama İçi Veri Silme Talebi Ekranı için Metin

Aşağıdaki kısa metinler, Flutter uygulamasındaki Veri Silme Talebi ekranında (`lib/features/legal/ui/data_deletion_page.dart`) kullanılmak üzere önerilmiştir. Hukukçu onayından sonra kullanılmalıdır.

**Başlık:**
> Veri Silme Talebi

**Açıklama:**
> Yeedoy hesabınızla ilişkili kişisel verilerin silinmesini, yok edilmesini veya anonim hale getirilmesini talep edebilirsiniz.

**Uyarı:**
> Bazı veriler yasal yükümlülükler, güvenlik veya uyuşmazlıkların çözümü için sınırlı süre saklanabilir.

**Talep türleri:**
- Hesabımı sil
- Yorum / favori / check-in verilerimi sil
- Destek talebi verilerimi sil
- İşletme sahipliği başvuru verilerimi sil
- Pazarlama e-posta iznimi kapat
- Diğer

**Onay metni:**
> Bu talebin bazı özelliklere erişimimi etkileyebileceğini anlıyorum.

> **Geliştirici notu:** Mevcut ekran "Hesabınız ve tüm verileriniz kalıcı olarak silinecektir", "Bu işlem geri alınamaz" ve "30 gün içinde" gibi kesin ifadeler içermektedir. Bu ifadeler bu belge ile çelişmektedir ve düzeltilmelidir (bkz. Bölüm 15).

---

## 8. Başvuru Kanalları

| Kanal | Adres / Yöntem |
|---|---|
| Uygulama içi talep formu | Yeedoy mobil uygulaması → Veri Silme Talebi ekranı |
| KVKK başvuru e-postası | `[KVKK_BASVURU_EPOSTA]` |
| Genel destek e-postası | `[DESTEK_EPOSTA]` |
| Yazılı başvuru (posta/elden) | `[ADRES]` |
| Telefon | `[TELEFON]` |
| Web sitesi | `[WEB_SITESI]` |

---

## 9. Başvuruda İstenebilecek Bilgiler

Kimlik doğrulama ve talebin doğru işlenmesi için aşağıdaki asgari bilgiler istenebilir:

- Ad soyad veya kullanıcı hesabı bilgisi
- İletişim e-postası (talep sonucunun iletileceği adres)
- Talep türü (hesap silme / belirli veri silme / izin geri çekme / diğer)
- Talebin kısa açıklaması
- Gerektiğinde kimlik doğrulama bilgileri
- Temsilci aracılığıyla başvuruda yetki/vekâlet belgesi

> **Veri minimizasyonu:** Başvuru sürecinde yalnızca talebin doğrulanması ve işlenmesi için gerekli asgari bilgiler istenir. Gereğinden fazla kişisel veri talep edilmez ve bu bilgiler yalnızca başvurunun değerlendirilmesi amacıyla kullanılır.

---

## 10. Yanıt Süreci

- Başvurular alındıktan sonra değerlendirilir ve yasal süre içinde sonuçlandırılır.
- Talep alındığında ve sonuçlandığında kullanıcıya bilgi verilmesi hedeflenir.
- Yanıt usulü, gerekli kimlik doğrulama ve varsa ücretlendirme koşulları yürürlükteki mevzuata göre uygulanır.

> **Hukukçu kontrolü notu:** KVKK kapsamındaki başvurulara yanıt için **kesin yasal süre** ve uygulanacak usul (örneğin yazılı başvuru, KEP adresi gereksinimi, ücretlendirme koşulları) hukukçu tarafından netleştirilmeden bu bölüme kesin süre yazılmamalıdır. Mevcut uygulama içi metinde geçen "30 gün" ifadesi hukukçu onayı ile teyit edilmelidir.

---

## 11. Talebin Reddedilebileceği veya Sınırlanabileceği Durumlar

Aşağıdaki durumlarda talep tamamen veya kısmen reddedilebilir ya da sınırlanabilir:

- Yürürlükteki mevzuat gereği **yasal saklama yükümlülüğü** bulunması
- Devam eden bir **uyuşmazlık, güvenlik incelemesi veya kötüye kullanım** araştırması
- Talebin yerine getirilmesinin **başka kişilere ait verileri** olumsuz etkilemesi
- Kamuya açık **meşru içeriğin** korunması ile silme talebi arasındaki dengenin gözetilmesi gerekmesi
- Başvuranın **kimliğinin doğrulanamaması**
- Talebin **aşırı, genel veya belirsiz** olması nedeniyle işlenememesi

> **Hukukçu kontrolü notu:** Ret ve sınırlama gerekçelerinin yasal dayanakları ve hangi hallerde uygulanabileceği hukukçu tarafından gözden geçirilmelidir.

---

## 12. Pazarlama İzni ve Abonelik İptali (Ayrı Bölüm)

Bu bölüm **bir açık rıza metni değildir**; yalnızca pazarlama izni yönetimini açıklar.

- **Pazarlama e-postasını kapatmak, veri silme talebiyle aynı şey değildir.** Pazarlama iznini geri çekmek, halihazırda işlenmiş verilerin silinmesini sağlamaz; yalnızca gelecekte ticari e-posta gönderilmemesini sağlar.
- Kullanıcı, uygulamanın **Bildirim Ayarları** ekranındaki "Pazarlama E-postaları" tercihinden **global pazarlama iznini** kapatabilir. Bu izin sunucu tarafında kayıtlıdır ve tüm cihazlarda geçerlidir.
- Kullanıcı, aldığı e-postalardaki **`/abonelik-iptal?token=...`** bağlantısıyla abonelikten çıkabilir.
- **İşletme bazlı e-posta aboneliği** ayrıca kapatılabilir; bu, global izinden bağımsızdır ve ilgili işletmeye özgüdür.
- Pazarlama izni kapatılsa bile **zorunlu hesap, güvenlik ve yasal bildirimler** (örneğin şifre sıfırlama, hesap güvenliği, yasal bilgilendirme) gönderilmeye devam edebilir.

> Bir kullanıcıya kampanya e-postası gönderilebilmesi için hem global pazarlama izni hem de ilgili işletme aboneliği aynı anda aktif olmalıdır (çift filtre kuralı). Detaylar KVKK Aydınlatma Metni Bölüm 8 ve Gizlilik Politikası Bölüm 6'dadır.

---

## 13. Üçüncü Taraf Servisler

Yeedoy'un kullandığı üçüncü taraf hizmet sağlayıcıları, silme/erişim taleplerinin işlenmesini etkileyebilir. Aşağıdaki durumlar yayın öncesinde netleştirilmelidir.

| Servis | Rol | Silme/erişim talebine etkisi | DPA / aktarım durumu | Kontrol notu |
|---|---|---|---|---|
| Supabase | Veritabanı, kimlik doğrulama, dosya depolama | Silme işlemi büyük ölçüde bu altyapıda gerçekleşir | `[SUPABASE_DPA_DURUMU]` | Hukukçu + teknik kontrol |
| Firebase / Google (Crashlytics, Analytics, Performance, FCM) | Çökme izleme, kullanım analitiği, performans izleme, push bildirim, sosyal giriş | Push token, giriş verisi ve çökme/analitik verileri bu servislerde işlenir; silme talebi Firebase veri saklama politikasına tabidir | `[FIREBASE_DPA_DURUMU]` | Hukukçu + teknik kontrol |
| Google AdMob | Uygulama içi reklam gösterimi (yalnızca mobil) | Reklam tanımlayıcısı (Android Advertising ID / iOS IDFA) Google'ın kendi saklama politikasına tabidir; iOS ATT kapsamında kullanıcı sıfırlayabilir | `[ADMOB_DPA_DURUMU]` | Hukukçu + teknik kontrol |
| Resend | E-posta gönderim | Gönderim logları sağlayıcı politikasına tabidir | `[RESEND_DPA_DURUMU]` | Hukukçu + teknik kontrol |
| Hosting / CDN | Sunum altyapısı | Teknik log/önbellek etkilenebilir | `[YURT_DISI_AKTARIM_DURUMU]` | Hukukçu + teknik kontrol |
| Genel yurt dışı aktarım | Tüm yurt dışı sağlayıcılar | KVKK md. 9 kapsamı | `[YURT_DISI_AKTARIM_DURUMU]` | Hukukçu kontrolü |

> Üçüncü tarafların kendi sistemlerinde işlediği veriler, o şirketlerin gizlilik politikalarına ve saklama sürelerine tabidir. Silme taleplerinin bu servislere de iletilmesi gereken durumlar teknik olarak doğrulanmalıdır.

---

## 14. Teknik İş Akışı Önerisi (Kod İçermez)

1. Talep alınır (uygulama içi form veya başvuru kanalı)
2. Kullanıcının kimliği doğrulanır
3. Talebin kapsadığı ilgili veri kategorileri belirlenir
4. Her kategori için silme, yok etme veya anonimleştirme kararı verilir
5. Yasal saklama istisnası bulunup bulunmadığı kontrol edilir
6. Uygun işlem (silme / anonimleştirme / arşivleme) gerçekleştirilir
7. Sonuç kullanıcıya bildirilir
8. İşlem, yasal ispat amacıyla sınırlı ve veri minimizasyonu ilkesine uygun bir audit kaydı olarak tutulur

---

## 15. Eksik Teknik Noktalar / Geliştirici Görevleri

- `account_deletion_requests` ve `privacy_requests` akışları **uçtan uca test edilmelidir**.
- Mevcut Veri Silme Talebi ekranı (`data_deletion_page.dart`), `delete_data` türünde talebi **`privacy_requests`** tablosuna yazmaktadır; ayrı bir `account_deletion_requests` akışı (`submitAccountDeletionRequest`) repository'de mevcuttur. Hesap silme ile genel veri silme talebinin **hangi tabloya gideceği netleştirilmelidir**.
- Ekrandaki "Hesabınız ve tüm verileriniz kalıcı olarak silinecektir", "Bu işlem geri alınamaz" ve "30 gün içinde" ifadeleri bu belge ve KVKK metinleriyle **çelişmektedir**; yasal saklama istisnalarını yansıtacak şekilde güncellenmelidir.
- Ekrandaki "Veri İndir" eylemi işlevsiz görünmektedir; ya işlevsel hale getirilmeli ya da kaldırılmalıdır.
- `acceptPolicyVersions` içinde hâlâ sentetik `user_agent` gönderilmektedir; R-4 kararı doğrultusunda bu gönderimin tutulup tutulmayacağı netleştirilmelidir.
- Talep **statüsleri kullanıcıya gösterilmelidir** (alındı / inceleniyor / tamamlandı).
- **Fiziksel silme vs. anonimleştirme** kararı migration/RPC seviyesinde netleştirilmelidir.
- Silme sonrası **yorum/puan/işletme istatistik etkisi** belirlenmelidir.
- **Opt-out geçmişinin** audit olarak tutulup tutulmayacağı karara bağlanmalıdır.
- **TTL / temizleme job'ları** (analitik, log, bildirim, snapshot) planlanmalıdır.
- Web ve Flutter ekranları **aynı statü modelini** kullanmalıdır.

---

## 16. Eksik Bilgiler / Hukukçuya Sorulacaklar

- Hesap silme sonrası hangi veriler tamamen silinmeli, hangileri anonim kalabilir?
- Kamuya açık yorum/puan içerikleri silinmeli mi yoksa anonimleştirilmeli mi?
- İşletme sahipliği başvurusunda (red dahil) yasal saklama süresi nedir?
- IP içermeyen politika kabul kayıtları ne kadar süreyle saklanmalı?
- Pazarlama opt-in/opt-out geçmişi ayrı tutulmalı mı?
- Analitik ve log verileri için azami saklama süresi nedir?
- Üçüncü taraf servislerde silme talepleri nasıl işletilmeli (DPA/aktarım)?
- KVKK başvurularına yanıt süresi, usulü ve ücretlendirme detayları nedir?

---

## 17. Production Öncesi Teknik Bloklayıcılar

- `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` migration uygulanmalı
- `20260620000001_user_profiles_marketing_email_opt_in.sql` migration uygulanmalı
- `20260620000002_r5_marketing_email_rpcs.sql` migration uygulanmalı
- `UNSUBSCRIBE_HMAC_SECRET` Next.js production ortamına eklenmeli
- `UNSUBSCRIBE_HMAC_SECRET` Supabase Edge Function secrets içine (aynı değer) eklenmeli
- `SITE_URL` doğru production URL olmalı
- Web `typecheck` ve `lint` çalıştırılmalı
- Local/staging veritabanı testleri yapılmalı
- `account_deletion_requests` ve `privacy_requests` uçtan uca test edilmeli
- E-posta kampanyası bu maddeler kapanmadan canlıya alınmamalı

---

## 18. Uygulama İçinde Gösterilecek Kısa Özet

1. Hesabınızı ve kişisel verilerinizi silme/anonimleştirme talebinde bulunabilirsiniz.
2. Bazı veriler yasal yükümlülükler nedeniyle sınırlı süre saklanabilir; her şey anında silinmez.
3. Kamuya açık yorumlarınız silinebilir veya anonim hale getirilebilir.
4. Pazarlama e-postasını kapatmak, veri silme talebinden farklıdır.
5. Talebiniz alındığında kimlik doğrulaması istenebilir.
6. Talebiniz değerlendirilir ve sonucu size bildirilir.
7. KVKK haklarınız için `[KVKK_BASVURU_EPOSTA]` adresine başvurabilirsiniz.

---

## Referans Belgeler

| Belge | Konu |
|---|---|
| `docs/hukuki/legal-data-inventory.md` | Kişisel veri envanteri |
| `docs/hukuki/kvkk-aydinlatma-metni.md` | KVKK Aydınlatma Metni taslağı |
| `docs/hukuki/gizlilik-politikasi.md` | Gizlilik Politikası taslağı |

---

*Bu belge yayına hazır kesin hukuki metin değildir. Hukuki geçerlilik için tüm placeholder'ların doldurulması ve bir hukuk danışmanı tarafından onaylanması zorunludur. KVKK Aydınlatma Metni ve Gizlilik Politikası ile birlikte değerlendirilmelidir.*
