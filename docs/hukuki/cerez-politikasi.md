# Yeedoy Çerez Politikası

---

## Belge Durumu ve Zorunlu Uyarılar

**Durum:** TASLAK — Hukukçu kontrolünden geçmeden yayınlanmamalıdır.

Bu metin, Yeedoy kod tabanının teknik incelemesine (web `@supabase/ssr` cookie kullanımı, `yd_client_id` localStorage analitik tanımlayıcısı, mobil paket envanteri) dayalı olarak hazırlanmış bir taslaktır. Yayına alınmadan önce:

1. Tüm `[PLACEHOLDER]` / `[URL_EKLENECEK]` / `[EMAIL_EKLENECEK]` alanları doldurulmalıdır.
2. KVKK ve veri koruma alanında uzman bir hukuk danışmanı tarafından gözden geçirilmeli ve onaylanmalıdır.
3. `[KONTROL_EDILECEK]` ve `[HUKUKCU_KONTROLU]` ile işaretli her madde netleştirilmelidir.
4. Bölüm 9'daki production öncesi teknik kontrol listesi (özellikle consent banner) kapatılmalıdır.

**Bu belge yalnızca çerez ve benzeri istemci-tarafı izleme/depolama teknolojilerini düzenler.** KVKK Aydınlatma Metni (`kvkk-aydinlatma-metni.md`) ve Gizlilik Politikası (`gizlilik-politikasi.md`) ayrı belgelerdir; bu metin onların yerini almaz, onları tamamlar.

**Hazırlayan notu:** Teknik bulgular kod denetimi sonucu üretilmiştir; hukuki dayanak ve süre değerlendirmeleri hukukçu onayı gerektirir.

**Tarih:** [YURURLUK_TARIHI]

---

## 1. Kapsam ve Amaç

Bu Çerez Politikası, Yeedoy markası altında sunulan tarayıcı tabanlı platformlarda kullanılan çerezleri ve benzeri teknolojileri açıklar:

- **Yeedoy Web Sitesi ve QR Menü Sayfaları** (örn. `yeedoy.com`, `/m/...`, `/qr/...` ve işletmelere ait özel alan adları): Kamuya açık dijital menü görüntüleme, QR ile menü erişimi, işletme profili inceleme.
- **Yeedoy İşletme Paneli** (owner/admin panelleri, alt alan adı yönlendirmeli): İşletme sahibi ve yetkili personel ekranları.

Bu politika, **mobil uygulamada geleneksel tarayıcı çerezi kullanılmadığı için** mobil eşdeğer teknolojileri yalnızca bilgilendirme amacıyla Bölüm 3'te özetler; mobil uygulamanın asıl veri işleme açıklaması Gizlilik Politikası ve KVKK Aydınlatma Metni'ndedir.

**Hukuki çerçeve:** Bu politika 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve 6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun çerçevesinde hazırlanmıştır.

> **[HUKUKCU_KONTROLU]** Türk hukukunda çerezlerin (özellikle zorunlu olmayan/analitik çerezlerin) hangi mevzuat maddesine dayandırılacağı ve açık rıza/aydınlatma yükümlülüğünün kapsamı hukukçu tarafından netleştirilmelidir. AB'de ePrivacy Direktifi'ne karşılık gelen doğrudan bir Türk düzenlemesi olup olmadığı değerlendirilmelidir.

**İlişki:** Bu Çerez Politikası, Gizlilik Politikası'nın "Çerezler ve Benzeri Teknolojiler" bölümünün ayrıntılı karşılığıdır. Aydınlatma Metni'ndeki veri kategorileri ve aktarım açıklamaları için ilgili belgelere bakınız.

---

## 2. Çerez Nedir?

**Çerez (cookie)**, bir web sitesini ziyaret ettiğinizde tarayıcınız tarafından cihazınıza kaydedilen küçük metin dosyasıdır. Site, sonraki ziyaretlerde bu dosyayı okuyarak oturumunuzu sürdürebilir veya tercihlerinizi hatırlayabilir.

Çerez türleri:

- **Oturum çerezi (session cookie):** Tarayıcı kapatıldığında silinir.
- **Kalıcı çerez (persistent cookie):** Belirli bir süre veya silinene kadar cihazda kalır.
- **Birinci taraf (first-party) çerez:** Doğrudan ziyaret ettiğiniz site tarafından oluşturulur.
- **Üçüncü taraf (third-party) çerez:** Başka bir alan adı (örn. reklam/analitik ağı) tarafından oluşturulur.

**Benzeri teknolojiler:** Çerez dışında, aynı amaçlarla kullanılan istemci-tarafı teknolojiler de bu politika kapsamındadır:

- **localStorage / sessionStorage:** Tarayıcının yerel depolama alanı. Yeedoy web tarafında tema tercihi, panel arayüz durumu ve analitik tanımlayıcı için kullanılır.
- **IndexedDB:** Bazı kütüphanelerin (örn. Firebase) dahili olarak kullanabildiği tarayıcı veritabanı.
- **Parmak izi (fingerprint):** Cihaz/tarayıcı özelliklerinden kimlik çıkarımı. **Yeedoy bilinçli olarak parmak izi tabanlı izleme kullanmamaktadır.**

---

## 3. Mobil Uygulama ile Web Arasındaki Fark

Yeedoy mobil uygulamasında (Android/iOS) **geleneksel tarayıcı çerezi kullanılmaz.** Mobil uygulama, tarayıcı çerezi yerine işletim sistemi düzeyindeki depolama ve cihaz tanımlayıcılarını kullanır. Mobil eşdeğer teknolojiler (kod envanterinden doğrulanmıştır):

| Teknoloji | Mobil paket | Amaç |
|---|---|---|
| SharedPreferences | `shared_preferences` | Basit kullanıcı tercihleri (tema, ayarlar) |
| Güvenli depolama | `flutter_secure_storage` | Hassas veriler (token vb.) için şifreli depolama |
| Yerel veritabanı | `sqflite` | Çevrimdışı önbellek / kuyruk |
| Push token | `firebase_messaging` (FCM) | Bildirim gönderimi için cihaz tokeni |
| Çökme/analitik SDK | `firebase_analytics`, `firebase_crashlytics`, `firebase_performance` | Kullanım analitiği, çökme ve performans izleme |
| Reklam SDK | `google_mobile_ads` | Uygulama içi reklam gösterimi |

> **[HUKUKCU_KONTROLU]** Mobil uygulamanın çökme/analitik/performans izleme sağlayıcısı **Firebase Crashlytics, Firebase Analytics ve Firebase Performance**'tır (`pubspec.yaml` ile doğrulanmıştır). Önceki taslaklardaki **Sentry referansları KVKK Aydınlatma Metni ve Gizlilik Politikası'ndan kaldırılmış**; tüm hukuki belgeler bu gerçek SDK listesiyle hizalanmıştır (2026-06-19, `legal-sdk-provider-alignment-report.md`). Firebase Analytics/Performance veri toplama beyanlarının App Store ve Google Play gizlilik formlarıyla tutarlı olması doğrulanmalıdır.

**Bu belgede "çerez" terimi yalnızca web/tarayıcı ortamını kapsar.** Mobil uygulamanın depolama ve SDK kullanımına ilişkin kapsamlı açıklama Gizlilik Politikası ve KVKK Aydınlatma Metni'nde yer alır.

---

## 4. Kullanılan Çerezler ve Benzer Teknolojiler

Aşağıdaki tablo, kod denetimi sonucu Yeedoy web platformunda tespit edilen çerezleri ve benzeri istemci-tarafı teknolojileri listeler.

> **Not:** "Çerez adı" sütunundaki Supabase auth çerezi adları sürüm ve yapılandırmaya göre değişebilir (`sb-<proje-ref>-auth-token` biçimi). Kesin ad ve süreler production yapılandırmasından teyit edilmelidir.

### 4.1 Zorunlu Çerezler ve Teknolojiler (rıza gerekmez)

Bu teknolojiler olmadan oturum açma, panel erişimi ve temel güvenlik çalışmaz.

| Ad / grup | Tür | Amaç | Sağlayıcı | Süre | Yasal dayanak |
|---|---|---|---|---|---|
| `sb-...-auth-token` (Supabase oturum çerezi) | Çerez (first-party) | Oturum yönetimi, kimlik doğrulama; owner/admin panel erişim koruması | Supabase (`@supabase/ssr`) | Oturum / token yenileme süresi | Hizmetin sunulması için zorunlu — [HUKUKCU_KONTROLU] |
| `panel-store` | localStorage | Panel kenar çubuğu açık/kapalı durumu (arayüz tercihi) | Yeedoy (first-party, `zustand persist`) | Kullanıcı silene kadar | Zorunlu/fonksiyonel — [HUKUKCU_KONTROLU] |
| `yd-theme` | localStorage | Açık/karanlık tema tercihi | Yeedoy (first-party) | Kullanıcı silene kadar | Zorunlu/fonksiyonel — [HUKUKCU_KONTROLU] |

> **Teknik dayanak:** Supabase oturum çerezi `uygulamalar/web/middleware.ts` ve `uygulamalar/web/src/lib/supabase/server.ts` içinde `@supabase/ssr` ile yönetilmektedir. `yd-theme` ve `panel-store` ilgili istemci bileşenlerinde localStorage üzerinden tutulur.

> **[HUKUKCU_KONTROLU]** Tema ve panel arayüz tercihinin "kesinlikle zorunlu" mu yoksa "fonksiyonel/tercih" çerezi mi sayılacağı ve bunların açık rıza gerektirip gerektirmediği değerlendirilmelidir.

### 4.2 Performans / Analitik Teknolojileri

| Ad / grup | Tür | Amaç | Sağlayıcı | Süre | Yasal dayanak |
|---|---|---|---|---|---|
| `yd_client_id` | localStorage | Birinci-taraf analitik: anonim ziyaretçi tanımlayıcısı; menü görüntüleme, QR tarama, öğe tıklama olaylarını Yeedoy'un kendi `/api/track` uç noktasına iletmek | Yeedoy (first-party) | Kullanıcı silene kadar | Meşru menfaat — [HUKUKCU_KONTROLU] |

> **Teknik dayanak:** `yd_client_id` değeri `uygulamalar/web/src/ui/sections/public-menu-client.tsx` içinde üretilir (`web_<uuid>` biçiminde) ve olaylar **kendi sunucumuzdaki** `/api/track` uç noktasına gönderilir. **Üçüncü taraf bir analitik ağına aktarım yoktur.**

> **[HUKUKCU_KONTROLU]** `yd_client_id`'nin çerez/eşdeğer araç sayılıp sayılmayacağı; analitik için açık rıza mı yoksa meşru menfaat mi gerektiği; consent banner zorunlu ise bu tanımlayıcının rıza öncesinde yazılmaması gerekip gerekmediği değerlendirilmelidir.

**Üçüncü taraf analitik durumu:** Kod incelemesinde Google Analytics (gtag), Google Tag Manager, Plausible, Hotjar, Microsoft Clarity, Meta (Facebook) Pixel, Vercel Analytics, Segment, Mixpanel, Amplitude veya benzeri **hiçbir üçüncü taraf analitik/izleme betiği tespit edilmemiştir.** Web tarafındaki tek Firebase kullanımı push bildirim (FCM) gönderimine yöneliktir (Bölüm 5).

### 4.3 Pazarlama / Reklam Çerezleri

**Yeedoy web sitesinde ve QR menü sayfalarında şu an reklam veya pazarlama amaçlı çerez kullanılmamaktadır.** Web tarafında herhangi bir reklam ağı veya yeniden hedefleme (retargeting) pikseli tespit edilmemiştir.

> **[KONTROL_EDILECEK]** **Mobil uygulamada** `google_mobile_ads` (Google AdMob) reklam SDK'sı bulunmaktadır. Bu SDK web çerezi kullanmaz; ancak mobil reklam tanımlayıcısı (Android Advertising ID / iOS IDFA) gibi cihaz düzeyinde tanımlayıcılar kullanabilir. Bu durumun mobil reklam kişiselleştirme/izleme açısından Gizlilik Politikası ve KVKK Aydınlatma Metni'nde ayrıca ele alınması; iOS App Tracking Transparency (ATT) ve Google Data Safety beyanlarının buna göre yapılandırılması gerekir. **Bu reklam SDK'sı bir web çerezi olmadığından bu Çerez Politikası'nın doğrudan konusu değildir, ancak burada şeffaflık adına belirtilmiştir.**

---

## 5. Üçüncü Taraf Hizmetler

Web platformunda istemci tarafında veya çerez/yerel depolama davranışını etkileyebilecek üçüncü taraf hizmetler aşağıdadır. Her hizmetin işlediği veriler kendi gizlilik politikasına tabidir. Veri aktarımı ve yurt dışı aktarım güvencesi ayrıntıları için Gizlilik Politikası ve KVKK Aydınlatma Metni'nin ilgili bölümlerine bakınız.

### Supabase (Kimlik Doğrulama, Veritabanı, Depolama)

- **Amaç:** Oturum yönetimi (auth çerezi), veritabanı, dosya depolama.
- **Çerez/depolama etkisi:** `@supabase/ssr` aracılığıyla oturum çerezi yazar.
- **Sunucu konumu:** Frankfurt, Almanya (AB bölgesi).
- **Gizlilik politikası:** `[URL_EKLENECEK]`

### Firebase Cloud Messaging — FCM (Web Push Bildirim) — PASİF

> **Doğrulandı (2026-08-29):** Web tarafında push bildirim akışı **aktif değildir**. İlgili kod (`src/lib/push/fcm-client.ts`) ve backend dispatch edge function'ları (`push-dispatch`, `send-push-campaign`) kaldırılmıştır; owner push kampanya route'u kill-switch ile kapatılmıştır (MVP kapsamı dışı). Firebase JS SDK web tarafında push amacıyla çalıştırılmamaktadır, dolayısıyla bu amaçla çerez/yerel depolama yazmaz. Bu bölüm, özellik yeniden etkinleştirilirse güncellenmelidir.

### Hosting / CDN (Barındırma)

- **Amaç:** Next.js uygulamasının barındırılması ve içerik dağıtımı.
- **Çerez/depolama etkisi:** Hosting/CDN sağlayıcısı yük dengeleme veya güvenlik amaçlı teknik çerez ekleyebilir.
- **Sağlayıcı:** `[KONTROL_EDILECEK — production hosting sağlayıcısı teyit edilmeli (ör. Vercel)]`
- **Gizlilik politikası:** `[URL_EKLENECEK]`

> **[KONTROL_EDILECEK]** Production hosting sağlayıcısının (ör. Vercel) otomatik olarak çerez ekleyip eklemediği ve `@vercel/analytics` benzeri bir paketin dahil olup olmadığı production dağıtımında teyit edilmelidir. Kod denetiminde böyle bir paket bulunmamıştır.

### Resend (Transactional / Kampanya E-postası)

- **Amaç:** E-posta gönderimi. **Çerez/yerel depolama davranışı yoktur** (sunucu tarafı e-posta servisi); burada yalnızca bütünlük adına listelenmiştir.
- **Sağlayıcı:** Resend (ABD).
- **Gizlilik politikası:** `[URL_EKLENECEK]`

> **Yurt dışı aktarım notu:** Supabase (AB), Google/Firebase (ABD) ve Resend (ABD) yurt dışında yerleşiktir. Bu aktarımların KVKK md. 9 kapsamındaki güvence durumu (DPA/SCCs) Gizlilik Politikası ve KVKK Aydınlatma Metni'nde takip edilmektedir; ilgili `[PLACEHOLDER]`'lar oralarda doldurulmalıdır.

---

## 6. Kullanıcı Tercihleri ve Çerez Yönetimi

### Tarayıcı Ayarlarından Yönetim

Çoğu tarayıcı, çerezleri görüntülemenize, silmenize veya engellemenize olanak tanır. İlgili ayarlar tarayıcıların "Gizlilik" / "Çerezler ve Site Verileri" bölümünde yer alır (Chrome, Firefox, Safari, Edge). localStorage verileri de tarayıcının "Site verilerini temizle" seçeneğiyle silinebilir.

> **Uyarı:** Zorunlu çerezleri (Supabase oturum çerezi) engellerseniz oturum açamaz ve panel/hesap özelliklerini kullanamazsınız.

### Zorunlu Olmayan Teknolojiler için Rıza

- **Analitik tanımlayıcı (`yd_client_id`):** Tarayıcının site verilerini temizleyerek bu tanımlayıcıyı silebilirsiniz; bir sonraki ziyarette yeni anonim bir tanımlayıcı oluşturulur.

> **[KONTROL_EDILECEK — consent banner uygulaması production öncesi yapılmalıdır]** Yeedoy web platformunda **şu anda bir çerez onay (consent) bannerı veya onay yönetim platformu (CMP) bulunmamaktadır.** Zorunlu olmayan çerezler/analitik tanımlayıcılar için önceden rıza (opt-in) gerekiyorsa, production öncesinde bir consent banner uygulanmalı ve `yd_client_id` gibi analitik tanımlayıcılar rıza verilene kadar yazılmamalıdır. Bu zorunluluk hukukçu tarafından teyit edilmelidir.

### Opt-out Bağlantıları

Web tarafında üçüncü taraf reklam/analitik ağı kullanılmadığından harici bir opt-out bağlantısı (örn. Google Analytics opt-out) gerekmemektedir. Üçüncü taraf bir analitik/reklam ağı eklenirse bu bölüme ilgili opt-out bağlantısı eklenmelidir.

### Push Bildirim Tercihi

Web/mobil push bildirimlerini tarayıcı veya cihaz bildirim ayarlarından kapatabilirsiniz.

---

## 7. Çerez Politikası Güncellemeleri

Bu Çerez Politikası, kullanılan teknolojiler değiştikçe (örn. yeni bir analitik aracı veya consent banner eklenmesi) güncellenebilir. Önemli değişikliklerde web sitesi üzerinden ve/veya uygulama içi bildirimle bilgilendirme yapılabilir. Güncel sürüm her zaman `[URL_EKLENECEK — örn. https://yeedoy.com/legal/cookies]` adresinde yayımlanır.

**Yürürlük tarihi:** [YURURLUK_TARIHI]

---

## 8. İletişim

Çerez ve veri işleme uygulamalarımıza ilişkin sorularınız için:

- **Veri sorumlusu:** `[VERI_SORUMLUSU_UNVANI]`
- **Genel destek:** `[EMAIL_EKLENECEK]`
- **KVKK başvuru:** `[EMAIL_EKLENECEK]`

KVKK md. 11 kapsamındaki haklarınız ve başvuru usulü için KVKK Aydınlatma Metni'ne bakınız.

---

## 9. Eksikler ve Hukukçuya Sorulacaklar

| # | Konu | Durum / Soru |
|---|---|---|
| Ç-1 | Çerezlerin kesinliği | Supabase oturum çerezi, `yd-theme`, `panel-store`, `yd_client_id` kod denetiminde **kesin** tespit edilmiştir. Hosting/CDN'in (Vercel) otomatik eklediği çerezler ve Firebase JS SDK'nın push akışında oluşturduğu depolama anahtarları **production'da doğrulanmalıdır**. |
| Ç-2 | Consent banner zorunluluğu | Türk mevzuatında (KVKK + 6563) zorunlu olmayan/analitik çerezler için önceden açık rıza (opt-in banner) gerekip gerekmediği; gerekiyorsa `yd_client_id`'nin rıza öncesi yazılmaması gerektiği netleştirilmelidir. **Şu an CMP yoktur.** [HUKUKCU_KONTROLU] |
| Ç-3 | Reklam ağı entegrasyon planı | Web'de reklam çerezi yoktur. Mobilde `google_mobile_ads` (AdMob) vardır. İleride web'e Meta Pixel/Google Ads gibi bir ağ eklenirse: ayrı bir "pazarlama çerezleri" rıza kategorisi, opt-out bağlantıları ve bu politikada güncelleme zorunlu olur. |
| Ç-4 | Üçüncü ülke veri aktarımı | Supabase (AB), Google/Firebase (ABD), Resend (ABD) için KVKK md. 9 güvenceleri (DPA / SCCs / Kurul kararı) Gizlilik Politikası ve KVKK Aydınlatma Metni'nde `[PLACEHOLDER]` olarak işaretlidir; doldurulmalıdır. [HUKUKCU_KONTROLU] |
| Ç-5 | Mobil reklam/analitik SDK tutarsızlığı | **KAPATILDI (2026-06-19).** Üç hukuki belgedeki Sentry referansları kaldırıldı; gerçek SDK envanteri olan **Firebase Crashlytics, Firebase Analytics, Firebase Performance** ve **Google AdMob** KVKK Aydınlatma Metni (Bölüm 3.8 + 6) ve Gizlilik Politikası'na (Bölüm 3.9 + 7) eklendi. Çerez Politikası Bölüm 3/4.3 zaten doğru listeliyordu. AdMob için iOS ATT ve Google Data Safety notları her iki ana belgeye `[HUKUKCU_KONTROLU]` ile işlendi. Kaynak: `legal-sdk-provider-alignment-report.md`. |
| Ç-6 | Production öncesi teknik kontrol listesi | (a) Consent banner kararı verilip uygulanmalı; (b) production çerez envanteri tarayıcı denetimiyle (DevTools → Application → Cookies/Storage) doğrulanmalı; (c) hosting/CDN çerezleri listelenmeli; (d) Firebase push depolama anahtarları doğrulanmalı; (e) tüm `[URL_EKLENECEK]` / `[EMAIL_EKLENECEK]` doldurulmalı; (f) `/legal/cookies` rotasındaki yayın metni bu belgeyle eşitlenmeli. |

---

## 10. Uygulama İçi Kısa Özet (Banner / Modal Metni)

Aşağıdaki kısa metin, ileride uygulanacak çerez bilgilendirme bannerında kullanılabilir.

**Türkçe:**

> Yeedoy, oturumunuzu sürdürmek için zorunlu çerezler ve site deneyimini iyileştirmek için anonim birinci-taraf analitik tanımlayıcısı kullanır. Reklam veya üçüncü taraf izleme çerezi kullanmıyoruz. Tarayıcı ayarlarınızdan çerezleri yönetebilirsiniz. Ayrıntılar için Çerez Politikamıza bakın.

**English:**

> Yeedoy uses strictly necessary cookies to keep you signed in and a first-party anonymous analytics identifier to improve your experience. We do not use advertising or third-party tracking cookies. You can manage cookies in your browser settings. See our Cookie Policy for details.

---

*Bu belge yayına hazır kesin hukuki metin değildir. Hukuki geçerlilik için tüm placeholder'ların doldurulması, `[KONTROL_EDILECEK]` ve `[HUKUKCU_KONTROLU]` maddelerinin netleştirilmesi ve bir hukuk danışmanı tarafından onaylanması zorunludur. Bu metin KVKK Aydınlatma Metni veya Gizlilik Politikası'nın yerine geçmez.*
