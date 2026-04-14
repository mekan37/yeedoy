# Yeedoy Sistem Dokumantasyonu

Tarih: 2026-03-10  
Kapsam: Monorepo genel davranis dokumani  
Kaynak: Mevcut uygulama kodu, Supabase schema/migration izleri, operasyon dokumanlari ve aktif ekran akislari

## Belgenin Amaci

Bu belge, Yeedoy sisteminin kod tabanindan cikarilan gercek urun davranisini tek bir yerde toplar. Amaç, teknik sinif veya fonksiyon listesi vermek degil; sistemin gercekte hangi kullanicilar icin ne yaptigini, verinin nasil aktigini, hangi sureclerin hangi kontrol noktalarindan gectigini ve bugunku urun sinirlarinin ne oldugunu aciklamaktir.

Bu dokuman su kisiler icin yazilmistir:

- urun sahibi
- proje yoneticisi
- yeni geliştirici
- operasyon ve moderasyon ekipleri
- icerik editorleri
- yatirimci veya stratejik paydaslar

## Okuma Kurali

Bu belgede uc isaret kullanilir:

- `Tespit`: Kodda veya aktif dokumanlarda dogrudan gorulen davranis.
- `Yorum`: Birden fazla akis birlestirilerek cikarilan, kuvvetli fakat dolayli sonuc.
- `Bosluk`: Kod yuzeyi gorunen ama tam kapanmamis, kismi veya deneysel kalan alan.

## Incelenen Yuzeyler

Analiz, repo icindeki su ana alanlari kapsar:

- `apps/mobile_flutter`: son kullanici mobil uygulamasi ve legal acceptance yuzeyi
- `apps/panel_flutter_web`: owner/admin paneli ile ana web landing ve legal merkezi
- `apps/web_next`: public menu, QR dagitim ve minimum legal cikis katmani
- `packages/*`: paylasilan tur, konfig ve yardimci paketler
- `supabase/migrations`: veri modeli, RLS, RPC ve is kurallari
- `supabase/functions`: yazma korumalari, anti spam, push ve admin servisleri
- `docs/*`: mevcut urun, mimari, veri ve operasyon kaynaklari
- `tools/*`: build, seed, import ve kalite yardimcilari

## Kisa Yonetici Ozeti

Yeedoy, restoran ve yiyecek odakli bir bilgi ve dagitim sistemi olarak konumlanmis durumda. Sistemin cekirdegi uc seyi ayni anda yapmaya calisiyor:

1. Son kullaniciya canli menu ve fiyat seffafligi saglamak.
2. Toplulugu fiyat dogrulama, raporlama ve icerik katkisi icine almak.
3. Isletmelere public menu, QR dagitimi ve operasyon paneli vermek.

Bugunku mimari, bu hedefi uc istemciye bolerek uyguluyor:

- Mobil uygulama: kesif, menu, fiyat dogrulama, yorum, favori, bildirim, topluluk ve versionli legal acceptance akislarinin tuketici yuzeyi.
- Panel uygulamasi: owner/admin operasyonu ile birlikte ana web landing ve legal merkezin ana kontrol merkezi.
- Next.js uygulamasi: yalnizca public menu, QR olusturma, branding, web tracking ve minimum legal cikis katmani.

Backend omurgasi Supabase uzerindedir. Veri modeli, sadece basit CRUD iliskileri degil; ayni zamanda moderasyon, guven skoru, kalite skoru, anomali takibi, rate limit, role based access control, audit log ve push bildirim akislari da barindirir.

Sistem artik yalnizca bir "menu listeleme uygulamasi" degildir. Kod tabani, sunlari destekleyen daha genis bir operasyon modeli tasir:

- isletme sahipligi talebi
- yeni isletme onerme ve onaylama
- menu ve fiyat guncelleme
- receipt/OCR tabanli dogrulama
- topluluk katkilarinin puanlanmasi
- moderasyon itirazlari
- sponsorlu alan ve sponsorship yonetimi
- audit ve impersonation
- public SEO menuleri ve QR kisa link dagitimi
- versionli policy acceptance, privacy request ve account deletion is akislari

Bugunku yonetici seviyesi karar cumlesi sunudur:

- Urun cekirdegi artik yalnizca MVP degil; veri guveni, owner operasyonu ve public dagitim omurgasi production'a yakin bir seviyeye cikmis durumdadir.
- Gelir, guven ve operasyon ekseninde en kritik moduller artik birbirine bagli calisir: mobil kesif, panel governance, public QR menu, audit, moderation, sponsorship ve owner growth.
- Son sprintlerde kritik altyapi bosluklari daralmistir: canonical public slug modeli, unified offline queue/idempotency, admin observability, owner growth ayrimi ve receipt review workbench artik gercek urun davranisina donusmustur.
- Legal/compliance omurgasi artik daha net ayrismistir: ana landing ve legal merkezi panelde, policy acceptance ve kullanici talep akislari mobilde, minimum legal cikis ise public QR web katmaninda tutulur.
- Buna karsin urunun her parcasi ayni olgunlukta degildir. Sosyal graph, taste twin, group requests, suspended meals ve bazi deneysel labs yuzeyleri halen kontrollu alan olarak ele alinmalidir.
- Bugunku ana yonetim riski yeni ozellik gelistirmekten cok, mevcut guclu cekirdegin test, CI, iOS readiness ve rollout disiplini ile korunmasidir.

Yonetici icin kisa durum tablosu:

- Guclu alanlar: discovery, business detail, menu, public QR menu, owner operasyonu, admin governance, moderation, audit, sponsorship katalogu, B2B export sinifi.
- Kapanan stratejik bosluklar: public slug route, mobile offline replay/idempotency, admin decision support, owner operasyon/growth ayrimi, receipt/OCR operator workbench.
- Halen dikkat isteyen alanlar: true push transport e2e, signed iOS release + gercek cihaz matrisi, owner tarafindaki editor/trash/restore gibi daha derin write/modal aksiyonlarinin browser smoke'a genislemesi, deneysel sosyal yuzeylerin cekirdekten ayrimi.
- Urun yorumu: Yeedoy daginik bir fikir seti degil; farkli olgunluk seviyelerinde olsa da ayni veri guveni omurgasina baglanmis, cok istemcili bir urun platformudur.

## 1) Uygulamanin Genel Amaci

### 1.1 Hangi problemi cozer

Yeedoy, yemek mekanlari ile ilgili en zor alanlardan birine odaklaniyor: guncel ve guvenilir menu bilgisi.

Gercek hayatta kullanicilarin karsilastigi temel problemler sunlardir:

- Bir isletmenin menusu internette eksik veya cok eskidir.
- Fiyatlar hizli degisir, kullanici gittiginde surprizle karsilasir.
- Ayni markanin farkli subelerinde farkli fiyat veya bulunurluk olabilir.
- Isletmelerin kendi dijital menu dagitimi daginiktir.
- Topluluktan gelen bilgi vardir ama bunu duzenli onaylayan ve yoneten bir omurga yoktur.
- Yorum, rapor ve gorsel katkilarin guvenilirligi degiskendir.

Yeedoy bu problemi tek bir mekanizma ile degil, birden fazla katmanin birlikte calismasiyla cozmeye calisir:

- canli public menu dagitimi
- crowd sourced fiyat dogrulama
- owner kontrollu menu yonetimi
- admin moderasyonu
- kalite ve guven puanlari
- QR ile fiziksel mekandan dijitale gecis

### 1.2 Uygulamanin temel deger onerisi

Kod tabanindan cikan urun vaadi su sekilde ozetlenebilir:

- Kullanici, yakinindaki isletmelerin menulerini ve fiyatlarini daha seffaf gorebilir.
- Fiyatin ne kadar yeni ve ne kadar guvenilir oldugunu anlayabilir.
- QR okutunca dogru menuye veya ilgili is akimina yonlenir.
- Isletme, public menu ve QR dagitimini daha profesyonel yonetebilir.
- Admin ekibi, bu icerik akisini merkezi olarak denetleyebilir.

### 1.3 Ana kullanici tipleri

Sistemde fiilen gorunen kullanici segmentleri sunlardir:

- Misafir veya anonim ziyaretci
- Kayitli son kullanici
- Katki yapan topluluk kullanicisi
- Isletme sahibi
- Isletme ekibi uyesi
- Admin
- Community moderator veya sinirli admin rolundeki operator

### 1.4 Urun kapsaminda on plana cikan vaadler

Kod ve metinlerden tekrarlayan ana temalar:

- live menus
- verified prices
- smart discovery
- transparency
- community contribution
- owner operations
- public QR menu

Bu tekrarlar, urunun yalnizca icerik gosteren bir katalog degil; guven, guncellik ve operasyon uzerine kuruldugunu gosteriyor.

## 2) Sistem Mimarisi

### 2.1 Yapisal bakis

Yeedoy monorepo yapisi icinde calisan, tek backend uzerinde toplanmis coklu istemci mimarisidir.

Ana istemciler:

| Katman | Ana amac | Birincil kullanici |
|---|---|---|
| Mobil uygulama | Kesif, menu tuketimi, katkı, bildirim, legal acceptance | son kullanici |
| Flutter web panel | owner/admin operasyonu, ana web landing, legal merkezi | isletme, admin, genel ziyaretci |
| Next.js web | public menu, QR, branding, tracking, minimum legal cikis | isletme ve genel ziyaretci |
| Supabase | veri, auth, policy, RPC, storage | tum istemciler |

### 2.2 Mobil uygulamanin rolu

Mobil uygulama, sistemin tuketiciye donuk omurgasidir. Kullanici burada:

- kesif yapar
- yakin isletmeleri gorur
- menu gezer
- urun detayina iner
- yorum birakir
- fiyat dogrular
- fiyat degisikligi onerebilir
- rapor gonderebilir
- favori biriktirir
- bildirim alir
- profil ve katki ilerlemesini gorur
- kayit sirasinda zorunlu policy acceptance verir
- login sonrasinda aktif policy versiyonlarini kontrol eder
- profil ayarlarindan legal link, privacy request ve account deletion akislarini yonetir

Tespit: Mobil uygulama owner veya admin CRUD yeri olarak tasarlanmamis. `/owner*` ve `/admin*` gibi akislar panel tarafina handoff edilir.

### 2.3 Panel uygulamasinin rolu

Flutter web panel, iki farkli operasyon yuzeyini ayni urun omurgasinda birlestirir:

- owner operasyonu
- admin operasyonu
- ana web landing
- legal merkezi

Public web ve legal tarafta panel su konular icin kullanilir:

- `yeedoy.com` landing page'ini yayinlamak
- `/legal` ve tum alt legal dokumanlarini barindirmak
- footer legal linklerini tek bir route sisteminden sunmak
- isletme akislarindaki business terms kabulunu ana legal merkeze baglamak

Owner tarafinda panel su konular icin kullanilir:

- isletme olusturma veya sahiplik akisini tamamlama
- birden fazla isletme secme ve yonetme
- menu duzenleme
- menu yayinlama ve versiyon/taslak geri donusleri
- fiyat onerilerini inceleme
- ekip yetkilendirmesi
- audit ve aktivite goruntuleme
- analytics ve QR/public menuye gecis

Admin tarafinda panel su konular icin kullanilir:

- tum moderasyon kuyrugu
- raporlar
- claimler
- business submissions
- suggestions
- price suggestions
- receipt submissions
- sponsorship ve verified yonetimi
- incidents, observability, temp uploads, audit
- user access ve impersonation

### 2.4 Next.js katmaninin rolu

Next.js uygulamasi, urunun "public web" gorevini ustlenir. Bu katmanin mevcut gercek gorevi kod tabaninda netlesmistir:

- isletmenin public menu sayfasini yayinlamak
- QR Studio saglamak
- kisa link yonlendirmesi yapmak
- branding ve presentation settings saklamak
- public menu event tracking uretmek
- metadata, JSON-LD, sitemap ve SEO davranisi sunmak
- public QR deneyiminde Terms/Privacy/Cookies gibi minimum legal link cikisi vermek

Tespit: Next.js katmani bugunku durumda owner/admin CRUD merkezi degildir. Ana landing page veya ana legal merkezi burada degil; isletme yonetimi ve hukuki merkez halen panel uygulamasindadir.

### 2.5 Supabase backend omurgasi

Supabase, sadece bir veritabani degil; is kurallarinin buyuk bolumunun tasindigi kontrol katmanidir.

Burada su alanlar birlikte bulunur:

- auth ve session
- role based access control
- row level security policyleri
- RPC tabanli okunur ve yazilir is akislari
- storage ve medya dosyalari
- audit log
- notifications
- analytics event kayitlari
- anti spam, write guard ve rate limit mekanizmalari
- policy version ve acceptance kayitlari
- privacy request ve account deletion request lifecycle'i

Legal/compliance tarafinda son durumda su tablo aileleri acikca gorunur:

- `policy_versions`
- `user_policy_acceptances`
- `business_policy_acceptances`
- `privacy_requests`
- `account_deletion_requests`

### 2.6 Ortak veri akisi modeli

Sistemin yuksek seviyeli veri akisi genelde su modeli izler:

1. Kullanici veya operator bir ekranda bir aksiyon baslatir.
2. Uygulama dogrudan tablo yazmak yerine buyuk oranda RPC veya kontrollu write hattina gider.
3. RLS ve rol kontrolleri kullanicinin bunu yapip yapamayacagini belirler.
4. Icerik turune gore kalite, anomali, guven, SLA veya moderasyon sinyalleri uretilir.
5. Sonuc ilgili hedefe yansir:
   - public menu
   - admin kuyrugu
   - owner paneli
   - inbox/push bildirimleri
   - analytics/audit tablolari

### 2.7 Edge function ve koruma katmanlari

Supabase function katmani, yuksek riskli veya sistem genelindeki bazi islemleri application code disina cikarir.

Tespit edilen ana fonksiyon aileleri:

- `write-gatekeeper`: bazi hassas yazma aksiyonlarini kontrollu ve rate limited sekilde calistirir.
- `anti-spam-guard`: review, price verify, photo upload ve report gibi akislar icin limit ve davranis kontrolu uygular.
- `push-dispatch`: notification kayitlarini FCM cihazlarina dagitir.
- `admin-api`: admin yazma RPC'lerini allowlist mantigiyla daha kontrollu bir kanaldan gecirir.
- `purge-temp-uploads`: gecici medya ve silme kuyrugu temizligi yapar.
- `media-upload`: panel/admin tarafinda medya upload uyumluluk katmani gorevi gorur.
- `media-upload-user`: mobile ve user-scoped medya upload akislarini Supabase Storage uzerinden calistirir.
- `import_places_json`: veri aktarim veya seed yardimcisi olarak kullanilir.

### 2.8 Paylasilan paketler

Monorepo icindeki paylasilan paketler, istemciler arasinda ortaklik saglar.

- `api_client`: ortak API veya Supabase islem kaliplari
- `shared_config`: ortam ve ayar sozlesmeleri
- `shared_types`: paylasilan veri yapilari
- `l10n_assets`: lokalizasyon varliklari
- `ui_tokens`: tasarim tokenlari veya tema referanslari

Yorum: Kod gerceginde her istemci bu paketleri ayni yogunlukta kullanmiyor olabilir; fakat repo organizasyonu, urunu tek bir platform ailesi olarak yurutme niyetini gosteriyor.

## 3) Kullanici Tipleri

### 3.1 Misafir veya anonim ziyaretci

Bu rol ozellikle public web tarafinda onemlidir.

Ne gorebilir:

- public menu sayfalari
- kategori ve urun detaylari
- marka/kapak gorselleri
- calisma saatleri veya benzeri public isletme bilgileri
- SEO kaynakli acilan landing yuzeyleri

Ne yapabilir:

- QR veya kisa link ile menu acabilir
- menu icerigini tarayabilir
- kategoriye ve urun detaya inebilir
- event tracking uretir ama kimliksiz olabilir

Sinirlar:

- QR Studio ayarlarini degistiremez
- owner/admin panellerine giremez
- coklu katkilar veya guven gerektiren islemleri yapamaz

### 3.2 Kayitli son kullanici

Bu, mobil urunun temel hedef kitlesidir.

Ne gorebilir:

- discovery akislari
- business detail
- menu ve urun detaylari
- yorumlar
- favoriler
- profil ve katkı istatistikleri
- inbox/bildirimler

Ne yapabilir:

- yorum ekleyebilir
- faydali oy kullanabilir
- fiyat dogrulayabilir
- fiyat onerisi gonderebilir
- business, review veya photo reportlayabilir
- favori listesi olusturabilir
- grup istegi, sosyal akislari veya deneysel yuzeyleri kullanabilir

Kritik kural:

Tespit: Bazi kullanici icerigi yazimlarinda verified contact zorunlulugu bulunur. Reviews, price suggestions, photos ve bazi business media yazimlari dogrulanmis iletisim veya benzeri bir kimlik guveni olmadan reddedilebilir.

### 3.3 Katki yapan topluluk kullanicisi

Bu rol, kayitli kullanicinin daha aktif halidir. Ayrica sistemde guven ve itibar biriktiren bir profile donusebilir.

Tipik aksiyonlar:

- receipt/fis veya menu fotografi yukleme
- OCR ile fiyat cikarimi
- QR parse edip menuye gitme
- fiyat degisikligi bildirme
- yorumlar icin helpful vote kullanma
- business fee veya benzeri crowd verification alanlarinda oy verme

Sistem bu kullanicilari pasif tuketiciden ayiran metrikler tutuyor gibi gorunur:

- trust score
- reputation score
- approved/rejected contribution sayilari
- verified streak veya basari izleri
- achievement benzeri oduller

### 3.4 Isletme sahibi

Owner, sistemin ticari yuzunun temel aktorudur.

Ne gorebilir:

- kendi isletmeleri veya erisimli oldugu business listesi
- owner dashboard KPI'lari
- menu kalite ve guven sinyalleri
- analytics verileri
- ekip erisimleri
- price suggestion akisi
- trash/version gecmisi

Ne yapabilir:

- yeni isletme olusturabilir veya business submission gonderebilir
- sahiplik talebi baslatabilir
- menu ve bolumleri duzenleyebilir
- item, kategori, foto ve varyant yapisini yonetebilir
- menu yayinlayabilir
- QR/public menu akisini acabilir
- ekip uyelerini davet edip rol verebilir
- kendi kapsamindaki audit kayitlarini gorebilir

### 3.5 Isletme ekibi uyesi

Sistem owner hesabini tek kisilik dusunmuyor. Isletme ekibi ve rol bazli yetki matrisine dair net altyapi var.

Rol tipleri:

- owner
- manager
- editor
- staff
- viewer

Izin siniflari:

- `business_read`
- `analytics_view`
- `media_upload`
- `qr_manage`
- `menu_write`
- `business_write`
- `team_manage`

Yorum: Her rol, tum ekranlara esit erisim almiyor. Sistem, owner panelini bir ekip operasyon araci olarak tasarlamis.

### 3.6 Admin

Admin, platformun merkezi operasyon roludur.

Ne gorebilir:

- tum business kayitlari
- tum moderasyon kuyruklari
- claims, reports, suggestions, submissions
- sponsorship, verified ve growth yuzeyleri
- audit ve observability verileri
- incidents ve temp uploads
- b2b exportlar
- kullanici erisim kayitlari

Ne yapabilir:

- onay/red/assign/islem alma
- business merge ve duzeltme
- verified durumu verme veya kaldirma
- sponsorship paket ve campaign yonetimi
- impersonation
- policy/guardrail goruntuleme veya degistirme
- appeal kararlarini sonuclandirma

### 3.7 Community moderator veya sinirli admin operatoru

Tespit: Admin izin matrisi, tam admin ile community mod benzeri kisitli operator rollerini ayirir.

Bu rol genelde:

- tum admin katmanina degil
- kendisine izin verilen belirli queue veya moderasyon rotalarina
- daha sinirli write yetkileri ile erisir

Bu, sistemin buyudukce tam admin erisimini parcalara bolme niyetini gosterir.

### 3.8 Rol matrisi ozet tablo

| Rol | Public menu | Mobil tuketici akislar | Owner panel | Admin panel | Moderasyon karari | QR yonetimi |
|---|---|---|---|---|---|---|
| Misafir | Evet | Sinirli/yok | Hayir | Hayir | Hayir | Hayir |
| Kayitli kullanici | Kismen | Evet | Hayir | Hayir | Kendi katkisini gonderir | Hayir |
| Katki yapan kullanici | Kismen | Evet | Hayir | Hayir | Dolayli katkı uretir | QR okutabilir |
| Owner | Evet | Kismen | Evet | Hayir | Kendi kapsami icinde bazi kararlar | Evet |
| Owner ekip uyesi | Evet | Kismen | Rolune bagli | Hayir | Rolune bagli | Rolune bagli |
| Admin | Evet | Kismen | Gerektiginde | Evet | Evet | Evet |
| Community mod | Evet | Kismen | Hayir | Sinirli | Sinirli | Hayir |

## 4) Uygulamanin Ana Modulleri

Bu bolum, sistemin ana urun modullerini kullanici davranisi acisindan aciklar. Her modulde amac, kullanici, calisma mantigi ve veri kullanim bicimi ozetlenir.

### 4.1 Discovery ve kesif modulu

Amaci:

- Kullaniciya yakinindaki veya ilgisini cekebilecek isletmeleri gostermek
- Fiyat ve guven sinyallerini kesifin bir parcasi haline getirmek
- Kategori, trend ve sponsorlu yuzeyleri ayni omurgada toplamak

Kim kullanir:

- son kullanici
- kayitli mobil kullanici
- kismen sponsorlu gorunurluk satin alan isletmeler

Nasil calisir:

- Uygulama acildiginda discovery ana giris omurgasi olarak kullanilir.
- Konum veya secili bolge bilgisiyle yakin isletmeler, ozel koleksiyonlar, trend listeleri ve tematik bloklar yuklenir.
- Siralama tek bir kritere dayanmaz; mesafe, fiyat dogrulugu, etkileşim ve kalite skoru birlikte kullanilir.
- Sponsorlu alanlar organik siralamadan ayrik olarak etiketli bicimde yuzeye eklenir.

Kullandigi veri turleri:

- business temel bilgileri
- sehir/ilce/konum ekseni
- trend ve populerlik sinyalleri
- kalite/trust puanlari
- sponsorlu placement kayitlari
- nearby campaign stories benzeri tanitim bloklari

Tespit:

- Ranking formulu kullanici metinlerine kadar yansitilmis durumda; seffaf siralama iddiasi var.
- Sponsorlu icerik icin acik label/disclosure mantigi bulunuyor.

### 4.2 Business detail modulu

Amaci:

- Bir isletmenin kullaniciya tek sayfada anlamli gorunmesini saglamak
- Menu, yorum, fiyat guveni, imkanlar ve benzeri baglamsal bilgileri birlestirmek

Kim kullanir:

- son kullanici
- owner dolayli olarak kendi business gorunurlugunu kontrol etmek icin

Nasil calisir:

- Discovery veya paylasilan bir linkten business detail sayfasina girilir.
- Kullanici burada isletme ozeti, menuye gecis, review listesi, rapor aksiyonlari, favori islemleri ve bazen ek ticari/yardimci modulleri gorur.
- Zincir mantigi olan yapilarda business sayfasi, gerekirse zincir veya sube baglamina baglanir.

Kullandigi veri turleri:

- business kaydi
- business_media
- business_hours
- reviews
- menu ozetleri
- verified / trust sinyalleri
- amenities veya ek ozellikler

### 4.3 Menu ve katalog modulu

Amaci:

- Isletmenin mevcut menu yapisini dijital olarak gostermek
- Kategori, item, varyant, foto ve ceviri bilgilerini birlikte sunmak

Kim kullanir:

- son kullanici
- owner
- admin, duzeltme ve inceleme baglaminda
- public web ziyaretcisi

Nasil calisir:

- Kullanici business icinden menuye girer veya dogrudan public menu linki acar.
- Sistem aktif/published menu surumunu getirir.
- Menu yapisi section, category, item, variant ve photo katmanlariyla kurulur.
- Public web tarafinda kategori ve item bazli derin linkler vardir.

Kullandigi veri turleri:

- menus
- menu_sections
- menu_categories
- menu_items
- menu_item_variants
- menu_item_photos
- menu_translations

### 4.4 Menu item detail ve fiyat seffafligi modulu

Amaci:

- Tek bir urun icin sadece isim ve fiyat gostermek degil; fiyatin guvenilirligini ve tarihsel baglamini da gostermek

Kim kullanir:

- son kullanici
- katkı yapan kullanici
- owner ve admin dolayli olarak

Nasil calisir:

- Item detay sayfasinda urunun mevcut fiyati, onceki fiyat hareketleri, foto, varyant ve dogrulama sinyalleri gorunur.
- Kullanici ayni ekranda fiyat dogrulama veya fiyat degisikligi onerme aksiyonuna yonlendirilebilir.
- Bazi akislarda fee/cover/service/water gibi ek ucret alanlari icin crowd verified sinyaller bulunur.

Kullandigi veri turleri:

- menu item mevcut fiyat ve guncelleme metadata'si
- price history
- confidence score
- source type: owner/admin/suggestion/verified gibi kayitlar
- vote tablolari
- evidence veya receipt baglantilari

### 4.5 Review ve topluluk geri bildirim modulu

Amaci:

- Kullanici deneyimini yazi ve oylama ile toplamak
- Review kalitesini helpful vote mekanizmasiyla ayrismak

Kim kullanir:

- kayitli son kullanici
- admin ve moderator
- owner dolayli olarak izleme baglaminda

Nasil calisir:

- Kullanici business icin yorum olusturur.
- Diger kullanicilar bu yorumu faydali/faydali degil gibi sinyallerle degerlendirebilir.
- Review icerigi raporlanabilir.
- Moderasyon ve write guard mekanizmasi, review vote ve review olusturmayi korur.

Kullandigi veri turleri:

- reviews
- review_votes
- reports
- moderation ve audit kayitlari

### 4.6 Report ve moderasyon tetik modulu

Amaci:

- Toplulugun problemli icerigi veya hatali kayitlari platforma bildirmesini saglamak

Kim kullanir:

- son kullanici
- katkı yapan kullanici
- admin/moderator

Nasil calisir:

- Kullanici business, review, photo veya ilgili icerik turlerinde rapor aksiyonu baslatir.
- Rapor, anti spam ve verified contact kontrollerinden gecer.
- Sonra admin queue veya ilgili uzman sayfaya duser.
- Sonuc, audit ve bazen notification mekanizmasina yansir.

### 4.7 Fiyat dogrulama ve suggestion modulu

Amaci:

- Fiyat bilgisini topluluk ve owner sinyalleriyle gunceI tutmak

Kim kullanir:

- kayitli son kullanici
- aktif katkı kullanicisi
- owner
- admin

Nasil calisir:

- Kullanici "bu fiyat dogru" benzeri hizli bir verify aksiyonu kullanabilir.
- Alternatif olarak yeni fiyat onerebilir.
- Bu oneri dogrudan public degeri degistirmez; kalite, anomali, reputasyon ve gerekirse moderasyon zincirine girer.
- Owner tarafi kendi panelinden gelen suggestion akisini gorur ve bazi kararlar verebilir.
- Admin tarafi merkezi suggestion ve queue ekranlarindan ayni akis uzerinde karar verir.

Kullandigi veri turleri:

- menu_item_price_suggestions
- menu_item_price_votes
- price history / confidence metadata
- user reputation score
- anomaly/quality signal alanlari

### 4.8 OCR ve receipt destekli menu guncelleme modulu

Amaci:

- Elle tek tek fiyat girmek yerine, fis veya menu fotografi uzerinden yarı otomatik veri toplamak

Kim kullanir:

- katkı yapan kullanici
- potansiyel olarak owner veya saha ekibi
- admin/moderator dolayli olarak

Nasil calisir:

- Kullanici fotograf ceker veya galeriden secim yapar.
- Sistem OCR ile fiyat satirlarini cikarmaya calisir.
- Cikan satirlar mevcut menu item'lariyla esitlenmeye calisilir.
- Kullanici eslesmeleri duzeltir veya onaylar.
- Sonrasinda bunlar fiyat suggestion veya receipt submission olarak sisteme gonderilir.

Bu modulin urun degeri:

- veri girisini hizlandirir
- sahadaki katkıyı kolaylastirir
- topluluk katkisinin hacmini arttirabilir
- receipt'i kanit katmani olarak kullanir

### 4.9 QR ve deep link modulu

Amaci:

- Fiziksel mekandaki QR ile dijital menu veya ilgili uygulama ekranini bulusturmak

Kim kullanir:

- son kullanici
- isletme sahibi
- public menu ziyaretcisi

Nasil calisir:

- Mobil uygulama QR okur.
- Tanimli Yeedoy route'u ise dogrudan ilgili sayfaya gider.
- Tanimli olmayan ama anlamli payload ise cozumlendirilir veya inceleme icin yuklenir.
- Web tarafinda `/q/{code}` kisa linki public menuye yonlendirir ve `qr_scanned` tracking uretir.
- Owner, panelden handoff ile QR Studio acip menu linki, tasarim ve branding ayarlarini yonetir.

### 4.10 Public menu ve SEO modulu

Amaci:

- Isletmeler icin paylasilabilir, arama motoruna uygun ve marka gorseli tasiyan public menu yuzeyi saglamak

Kim kullanir:

- anonim ziyaretci
- son kullanici
- isletme sahibi

Nasil calisir:

- Isletme için canonical public menu URL uretilir.
- Theme, language ve source parametreleri normalize edilir.
- Restaurant/Menu JSON-LD uretilir.
- Kategori ve item bazli derin linkler desteklenir.
- Track event'leri menu acilma, kategori goruntuleme, item tiklama gibi davranislari kaydeder.

Kritik not:

Tespit: Public menu route modeli canonical olarak `public_slug` merkezlidir; `slug`, sonra `businessId` fallback olarak korunur.

### 4.11 Favoriler, koleksiyon ve tekrar ziyaret modulu

Amaci:

- Kullaniciya ilgilendigi isletmeleri tekrar bulma kolayligi vermek
- Price alert ve tekrar erisim gibi akislar icin kullanici niyeti sinyali uretmek

Kim kullanir:

- son kullanici

Nasil calisir:

- Kullanici business veya ilgili nesneyi favoriye ekler.
- Favori listesi mobilde ayrik yuzey olarak gorulur.
- Share ve canli write smoke izleri, bu alanin yalnizca lokal UI degil gercek veri yazdığını gosterir.
- Fiyat alarm tetiklerinde favori iliskileri anlamli bir baglam sinyali olabilir.

### 4.12 Profil, itibar ve basari modulu

Amaci:

- Kullanicinin topluluk icindeki yerini ve katkilarinin etkisini gostermek

Kim kullanir:

- son kullanici
- aktif katkı kullanicisi

Nasil calisir:

- Profilde temel istatistikler, trust score ve katkı ilerlemesi gorunur.
- Yardimci oylar, onaylanan katkilar, streak benzeri metrikler dolayli olarak bir puan modeline beslenir.
- Achievement altyapisi, kullanicinin belirli esikleri gecince odul veya unvan almasina imkan tanir.

### 4.13 Bildirim ve inbox modulu

Amaci:

- Kullaniciya sistemdeki degisiklikleri geri donus noktasina cevirmek

Kim kullanir:

- son kullanici
- dolayli olarak admin/owner karar mekanizmalari

Nasil calisir:

- Inbox, legacy notification ve push sinyallerini birlestiren bir kutu mantiginda calisir.
- Fiyat onerisi sonucu, claim, report sonuclari veya review reply gibi olaylar bildirim uretebilir.
- Push tap acildiginda uygulama, hedef route'u cozup ilgili ekrana gider.
- Android debug bridge ve simulator katmanlari, bu akis icin testlenebilirlik ekler.

### 4.14 Suggest business ve business acquisition modulu

Amaci:

- Kullanici veya owner kaynakli yeni isletme edinimini sisteme almak

Kim kullanir:

- son kullanici
- owner
- admin

Nasil calisir:

- Mobil kullanici yeni bir mekan onerebilir.
- Owner yeni business yaratma veya submission akisini panelden baslatabilir.
- Admin business submissions ekranindan bunlari inceler, onaylar veya reddeder.
- Onaylanan kayitlar ana business envanterine dahil olur.

### 4.15 Owner business management modulu

Amaci:

- Isletme tarafina kendi kayitlarini ve operasyon alanini yonetme imkani vermek

Kim kullanir:

- owner
- manager/editor gibi owner ekip rolleri

Nasil calisir:

- Kullanici owner paneline girer.
- Erisimli business listesi yuklenir.
- Business context bar ile aktif business secilir.
- Bu secim menu, analytics, team ve diger owner ekranlarina baglam tasir.

Bu modulun onemi:

- sistem bir kullanicinin birden fazla business yonetebilecegini kabul eder
- business secimi ekranlar arasi ortak state'tir
- owner panelindeki bircok islem business secimi olmadan anlamli calismaz

### 4.16 Owner menu editor ve lifecycle modulu

Amaci:

- Menu yapisini owner tarafindan olusturmak, duzenlemek, yayinlamak ve geri almak

Kim kullanir:

- owner
- menu write yetkisi olan ekip uyeleri
- admin, restore veya denetim baglaminda

Nasil calisir:

- Menuler liste halinde gorulur.
- Editor ile section/category/item seviyesinde degisiklik yapilir.
- Foto ve varyantlar duzenlenir.
- Publish oncesi veya publish aninda snapshot olusturulur.
- Silme davranisi fiziksel yok etme yerine soft delete mantigina dayanir.
- Trash ve version/restore akislarindan geri donus saglanir.

### 4.17 Owner team ve RBAC modulu

Amaci:

- Tek sahipli hesap modelinden cikarak ekip operasyonu saglamak

Kim kullanir:

- owner
- team manage yetkisi olan yoneticiler
- admin destek ve denetim amacli

Nasil calisir:

- Takim uyeleri davet edilir.
- Roller atanir.
- Yetkiler role gore hesaplanir.
- Admin, kullanici bazli access preview ve gerekirse impersonation yapabilir.

### 4.18 Owner analytics ve growth modulu

Amaci:

- Isletmeye sadece menu duzenleme degil, performans gorunurlugu de vermek

Kim kullanir:

- owner
- analytics_view yetkisi olan ekip uyeleri
- admin dolayli olarak

Nasil calisir:

- QR scans, menu opens, category views, item clicks, conversions benzeri KPI'lar sunulur.
- Source ayrimi yapilir: normal acilis, QR short link vb.
- `/owner/growth` ekrani talep, gorunurluk, fiyat pozisyonu ve sponsorship lead akisini toplar.
- `/owner/analytics` route'u ayni baglamin detay analitik inceleme ekranidir.
- Quality score, trust, menu freshness, price accuracy ve contribution trust gibi koruyucu metrikler artik operasyon merkezinde `/owner` altinda tutulur.

### 4.19 Admin moderation queue modulu

Amaci:

- Platform uzerindeki farkli riskli veya onay bekleyen icerikleri tek bir operasyon panelinde toplamak

Kim kullanir:

- admin
- community moderator

Nasil calisir:

- Queue, farkli kaynak tiplerini tek liste mantiginda birlestirir:
  - report
  - claim
  - price suggestion
  - business submission
  - media flag
- Liste filtrelenir, assign edilir, bulk islem alir ve detay drawer ile incelenir.
- Ozel sayfalar queue'ya dogru derin link veya filtre ile baglanir.

### 4.20 Admin business governance modulu

Amaci:

- Platformdaki business envanterinin kurumsal kalitesini korumak

Kim kullanir:

- admin

Nasil calisir:

- Admin business listesi arama, filtre, tarih, siralama, pagination ve bulk aksiyonlar sunar.
- Business kaydi duzenlenebilir, status degistirilebilir, verified yapilabilir veya merge edilebilir.
- Digital menu, QR ve public menu linkleri buradan acilabilir.

### 4.21 Claim ve appeal modulu

Amaci:

- Bir isletmenin kime ait oldugunu, hatali kararlarin nasil duzeltilecegini ve itirazin nasil yonetilecegini kurallastirmak

Kim kullanir:

- owner adayi
- admin
- moderator

Nasil calisir:

- Kullanici bir business uzerinde sahiplik talebi olusturur.
- Admin belge ve detay incelemesi yapar.
- Onay veya red karari verilir.
- Reddedilen kararlar icin moderation appeal akisi bulunur.
- Notification template ve audit izi ile surec kapanir.

### 4.22 Sponsorship, verified ve monetization modulu

Amaci:

- Ticari gorunurlugu urun mantigina zarar vermeden yonetmek

Kim kullanir:

- admin
- dolayli olarak owner

Nasil calisir:

- Sponsorship package tanimlari yapilir.
- Sponsorship olusturulur ve status yonetilir.
- Sponsorship leads owner tarafindan veya formlar uzerinden gelebilir.
- Verified business statusu ayrica yonetilir.
- Guardrails sponsorlu icerigin etiketi, min trust veya rating esigi gibi urun kurallarini korur.

### 4.23 Audit, observability ve incident modulu

Amaci:

- Sistem degisikliklerini gorulebilir, izlenebilir ve gerektiğinde soruşturulabilir kilmak

Kim kullanir:

- admin
- owner kendi kapsami icinde
- operasyon ve destek ekipleri

Nasil calisir:

- Audit timeline hem admin hem owner yuzeyinde vardir; owner yalnizca kendi erisimli business kayitlarini gorur.
- Incident center, belirli olay anahtarlarina gore aciklama ve durum guncellemeleri saklar.
- Observability sayfasi, operasyon ve saglik sinyallerini toplar.
- Temp upload ve deletion queue gibi yuzeyler de operasyonel hijyenin parcasidir.

### 4.24 Legal ve compliance modulu

Amaci:

- hukuki metinleri, policy acceptance kaydini ve kullanici veri taleplerini tek bir sistem davranisina donusturmek

Kim kullanir:

- son kullanici
- isletme sahibi
- genel web ziyaretcisi
- admin ve operasyon ekipleri

Nasil calisir:

- Ana legal merkez panel uygulamasi icindeki `/legal` route ailesinde yayimlanir.
- Legal dokumanlar slug, baslik, aciklama, versiyon, son guncelleme ve icerik bolumleriyle registry mantiginda tutulur.
- Mobil uygulama kayit ve login sonrasinda aktif `terms` ve `privacy` policy versiyonlarini kontrol eder.
- Kabul kayitlari `user_policy_acceptances` ve business kabul kayitlari `business_policy_acceptances` uzerine yazilir.
- Privacy request ve account deletion request akislarinda acik talep varsa yeni talep uretilmez; lifecycle status bazli takip edilir.
- Next.js yalnizca public QR yuzeyinde minimum legal link cikar ve ana hukuki merkezi tasimaz.

## 5) Kullanici Akislari

Bu bolum, sistemin gercekte nasil deneyimlendigi uzerine kuruludur. Koddaki route ve moduller, burada davranissal akislara cevrilmistir.

### 5.1 Son kullanicinin ilk acilis akisi

1. Kullanici uygulamayi acar.
2. Splash ve onboarding zinciri calisir.
3. Uygulama kullanicinin auth ve onboarding durumunu kontrol eder.
4. Ana varis noktasi cogu durumda discovery ekranidir.
5. Discovery, secili konuma veya son bilinen baglama gore isletme ve tema bloklarini yukler.

Bu akis, urunun kendini "arama kutusundan once kesif" olarak konumladigini gosterir.

### 5.2 Kesiften business detail'e gecis

1. Kullanici discovery kartlari, trend bloklari veya kategori yuzeylerinden bir isletmeye tiklar.
2. Business detail sayfasi acilir.
3. Kullanici burada:
   - menuye gidebilir
   - yorumlari gorebilir
   - rapor verebilir
   - favoriye ekleyebilir
   - bazen zincir veya benzer baglamlara gecis yapabilir
4. Eger isletme sponsorluysa bu durum etiketle belirtilir.

### 5.3 Business detail'den menu ve urun detayina gecis

1. Kullanici menuye girer.
2. Kategoriler arasinda gezinir.
3. Item listesinde fiyat, bulunurluk, foto veya ek nitelikler gorur.
4. Bir item secince item detail sayfasi acilir.
5. Burada fiyatin guncelligi, guven skoru, tarihcesi ve varsa ek kanitlar gorunur.

Bu akis, menuyu sadece "liste" olmaktan cikarip "karar verme ekrani" haline getirir.

### 5.4 Hizli fiyat dogrulama akisi

1. Kullanici bir item'da gordugu fiyatin dogru oldugunu dusunur.
2. Verify aksiyonunu kullanir.
3. Sistem bu eylemi rate limit ve guven kontrollerinden gecirir.
4. Sonuc kullanicinin katkı puanina ve ilgili item'in confidence modeline etki eder.
5. Yeterli sinyal birikirse item daha guvenilir gorunur veya ilgili alerts/analytics tetiklenebilir.

### 5.5 Yeni fiyat onerme akisi

1. Kullanici mevcut fiyatin hatali oldugunu gorur.
2. Yeni fiyat onerir.
3. Sistem bu oneriye:
   - kullanici reputasyonu
   - zaman bilgisi
   - evidence varligi
   - benzer suggestionlarla uyum
   - anomali skoru
   gibi parametreler atar.
4. Onay gerektiren durumlarda suggestion queue'ya duser.
5. Owner veya admin karari ile onaylandiginda canli fiyat modeline yansir.

### 5.6 OCR veya receipt ile fiyat guncelleme akisi

1. Kullanici katkı ekranina girer.
2. Fotograf veya fis secimi yapar.
3. Sistem OCR ile fiyatlari ayiklar.
4. Ekran, bulunan satirlari mevcut menu item'lariyla eslestirmeye calisir.
5. Kullanici eksik/yanlis eslesmeleri duzeltir.
6. Gonderim sonrasi:
   - receipt submission kaydi olusabilir
   - ayni anda bir veya daha fazla price suggestion olusabilir
7. Bunlar moderasyon/kalite hattina girer.

Bu akis, manuel veri girisini azaltirken operator maliyetini de dusurmeyi hedefler.

### 5.7 QR okutma akisi

1. Kullanici restorandaki QR kodu taratir.
2. Sistem icerigi parse eder.
3. Eger link Yeedoy tarafindan taniniyorsa uygun route'a gider:
   - business
   - menu item
   - public menu
   - panel handoff baglami
4. Eger taninmiyorsa ama kayda deger bir veri varsa inceleme veya upload akisi tetiklenebilir.
5. Web kisa linkse public menu acilir ve scan event'i kaydedilir.

### 5.8 Review ve report akisi

1. Kullanici business detail uzerinden yorum birakir.
2. Diger kullanicilar bu yoruma helpful vote verebilir.
3. Problemli yorum veya icerik raporlanabilir.
4. Report admin queue'ya duser.
5. Admin veya moderator inceleyip aksiyon alir.
6. Sonuc audit ve bazen notification tarafina yansir.

### 5.9 Favori ve geri donus akisi

1. Kullanici ilgisini ceken bir business'i favoriler.
2. Bu kayit kullanicinin favorites sayfasinda birikir.
3. Sistem bunu price alert veya tekrar ziyaret niyeti gibi ikincil sinyallerde kullanabilir.
4. Kullanici daha sonra bu sayfadan dogrudan business/menu akislara geri doner.

### 5.10 Bildirim ve push acilis akisi

1. Sistem bir olay uretir:
   - fiyat degisti
   - yorum cevabi geldi
   - suggestion/claim/report sonuclandi
   - achievement acildi
2. Notification kaydi olusur.
3. Gerekirse push-dispatch FCM cihazlarina dagitim yapar.
4. Kullanici bildirime tiklayinca hedef route cozulur.
5. Uygulama dogrudan ilgili business/item/inbox sayfasina gider.

### 5.11 Yeni business onerme akisi

1. Son kullanici veya owner yeni bir isletme kaydi baslatir.
2. Gerekli temel bilgiler girilir.
3. Kayit suggestion veya submission olarak sisteme duser.
4. Admin business submissions ekraninda bunu inceler.
5. Onay durumunda ana business envanterine dahil edilir.

### 5.12 Owner onboarding akisi

1. Kullanici business login veya register akisindan girer.
2. Owner rolune uygun yonlendirme alir.
3. Eger henuz yonettigi business yoksa onboarding veya business creation ekranlari gorunur.
4. Business olusturulur veya claim sureci baslatilir.
5. Sonrasinda owner shell ve business context bar aktif hale gelir.

### 5.13 Owner menu kurulum akisi

1. Owner aktif business'i secer.
2. Menus ekranindan yeni menu veya mevcut menu duzenleme secilir.
3. Section, category, item ve photo duzenlemeleri yapilir.
4. Gerekiyorsa medyalar upload edilir.
5. Publish islemi ile canli public menu surumu guncellenir.
6. Snapshot alindigi icin geri alma veya restore olasidir.

### 5.14 Owner QR/public menu dagitim akisi

1. Owner panelden QR veya public menu aksiyonunu secer.
2. Sistem panel session'ini Next uygulamasina handoff eder.
3. Owner QR Studio ekraninda isletmenin public menu linkini gorur.
4. Theme, language, logo, cover ve background gibi ayarlari yapar.
5. PNG/SVG QR ciktisi alir veya link kopyalar.
6. Kisa link uzerinden tarama olaylari analytics'e yansir.

### 5.15 Owner team yonetim akisi

1. Owner team ekranina girer.
2. Yeni ekip uyesi davet eder.
3. Rol ve kapsam belirler.
4. Yetkiler business bazli uygulanir.
5. Uye artik menuyu, analitigi veya business ayarlarini rolune gore kullanir.

### 5.16 Admin queue operasyon akisi

1. Admin queue ekranini acar.
2. Farkli kaynaklardan gelen bekleyen isler tek listede gorunur.
3. Tip, durum, atama ve SLA filtreleri kullanilir.
4. Admin bir kaydi kendine atar veya ekipten birine yonlendirir.
5. Detay drawer uzerinden karar verir.
6. Sonuc audit log'a ve ilgili hedef nesneye yansir.

### 5.17 Claim inceleme akisi

1. Bir owner adayi mevcut bir business icin sahiplik talebi gonderir.
2. Claim admin tarafinda queue veya ozel claims ekranina duser.
3. Belgeler ve detaylar incelenir.
4. Onay verilirse kullanici owner yetkileri kazanir veya ilgili business ile iliskilenir.
5. Red verilirse user'a sonuc bildirilir.
6. Gerekirse moderation appeal acilabilir.

### 5.18 Moderation appeal akisi

1. Kullanici bir report veya claim sonucuna itiraz eder.
2. Appeal kaydi olusur.
3. Admin appeals ekraninda yeniden incelenir.
4. Ilk karar guncellenebilir veya korunabilir.
5. Sonuc notification ve audit katmanlarina islenir.

### 5.19 Sponsorship lead akisi

1. Owner growth hub icinde pro/growth ilgisini bildiren formu doldurur.
2. Lead admin monetization ekranlarina duser.
3. Sponsorship package veya kampanya teklifine donusturulebilir.
4. Onayli sponsorship canli sponsorlu placement alanlarina yansitilabilir.

### 5.20 Admin business governance akisi

1. Admin business listesinde arama veya filtreleme yapar.
2. Problemli, kopya veya eksik kayitlari belirler.
3. Tekil veya bulk aksiyon alir:
   - approve/reject
   - status degistirme
   - assign/unassign
   - verified yapma
   - merge
4. Sonuc public ve owner deneyimini dogrudan etkiler.

### 5.21 Son kullanici legal acceptance akisi

1. Kullanici kayit ekraninda e-posta ve sifreyi girer.
2. "Kullanim Sartlari" ve "Gizlilik Politikasi" kabul edilmeden kayit tamamlanamaz.
3. Kayit veya login sonrasi sistem aktif policy versiyonlarini okur.
4. Kullanici eksik veya yeni policy versiyonu varsa `/legal/acceptance` ekranina yonlendirilir.
5. Kabul kaydi `user_policy_acceptances` tablosuna kaynak uygulama bilgisiyle yazilir.
6. Kabul tamamlanmadan ana mobil icerik akislarina gecilmez.

### 5.22 Privacy request ve account deletion akisi

1. Kullanici profil ayarlarindaki legal ve gizlilik bolumune girer.
2. Legal linkleri `yeedoy.com/legal/...` uzerinden ana web merkezine acar.
3. "Verilerimi disa aktar" veya "Gizlilik basvurusu" secilirse request dialog'u acilir.
4. Acik bir privacy request varsa yeni talep olusturulmaz; mevcut durum ekranda gorunur.
5. "Hesabimi sil" secilirse guclu uyari ve `SIL` dogrulamasi ile talep alinir.
6. Bu talepler `privacy_requests` ve `account_deletion_requests` tablolarinda status bazli izlenir.

## 6) Menu Sistemi

Menu sistemi, Yeedoy'un urun cekirdegi sayilir. Cunku discovery, QR, public web, owner panel, OCR ve fiyat seffafligi bu modul etrafinda birlesir.

### 6.1 Menu sisteminin amaci

Menu sistemi yalnizca urun isimlerinin listelenmesi icin degil, su hedefler icin kurulmus gorunuyor:

- isletmenin dijital vitrini olmak
- fiyatin guncelligini gostermek
- kategorik gezinmeyi kolaylastirmak
- public web ve QR dagitiminin kaynagi olmak
- topluluk ve owner verisini ayni katalog yapisinda birlestirmek

### 6.2 Veri modeli mantigi

Menu sisteminin cekirdek katmanlari sunlardir:

- `menus`: menunun ust kaydi
- `menu_sections`: genel bolumleme
- `menu_categories`: kategori yapisi
- `menu_items`: asil urunler
- `menu_item_variants`: boyut, porsiyon veya alternatif varyantlar
- `menu_item_photos`: urune bagli gorseller
- `menu_translations`: dil bazli metin alanlari

Yorum: Bu yapi, menuyu basit bir liste degil, zenginlestirilebilir bir icerik agaci olarak kurguluyor.

### 6.3 Menu nasil olusturulur

Owner akislarindan cikan davranis su sekildedir:

1. Owner, isletmesini secer.
2. Menus ekranina girer.
3. Yeni menu olusturur veya mevcut menuyu duzenler.
4. Section ve category'ler kurulur.
5. Item'lar eklenir.
6. Gerekirse varyant, gorsel ve ceviri alanlari tamamlanir.
7. Menu publish edilir.

Bu akisin onemi:

- public menu sayfasi owner tarafinda yayinlanan son gecerli surume dayanir
- mobil uygulama da dogrudan veya dolayli olarak ayni menu yapisini tuketir

### 6.4 Menu yayinlama mantigi

Tespit: Menu publish akisi, snapshot ve version metadata ile birlikte dusunulmus.

Bu da sunu gosterir:

- owner duzenleme yaparken menu taslak benzeri bir surec yasiyor
- yayinlanan surum public yuzey icin anlamli referans oluyor
- geri alma gerekiyorsa, destructively overwrite etmek yerine restore/copy mantigi tercih ediliyor

Bu tercih urun acisindan su avantajlari saglar:

- hatali menu guncellemesinde geri donus kolaylasir
- audit edilebilirlik artar
- operasyonel risk azalir

### 6.5 Menu versiyonlama ve geri donus

Data safety kaynaklarindan cikan davranis:

- menu silme dogrudan fiziksel silme degil, daha cok archived/soft delete mantigi ile ele alinir
- item seviyesinde bulunurluk veya gorunurluk alanlari kullanilabilir
- menu snapshot'lari yayin aninda alinabilir
- restore islemi mevcut kaydin uzerine yazmak yerine geri yuklenmis yeni bir surum olusturabilir

Yorum: Bu sistem, owner panelinin profesyonel bir operasyon araci gibi tasarlandigini gosterir.

### 6.6 Kategoriler nasil calisir

Menu category sistemi sadece owner editor tarafinda degil, public tuketim tarafinda da birincil gezinme eksenidir.

Davranis olarak:

- kategori business icindeki ana gezinme birimidir
- public menu category route'u ayrik acilabilir
- category bazli analytics olusur
- discovery veya paylasilan linklerden kategoriye derin link yapmak mumkundur

### 6.7 Urunler nasil tanimlanir

Menu item seviyesinde sistem su tip bilgileri tasiyabilir:

- urun adi
- aciklama
- ana fiyat
- varyantlar
- fotograflar
- dietary veya benzeri etiketler
- bulunurluk bilgisi
- tarihsel fiyat metadata'si

### 6.8 Fiyatlar nasil tutulur

Yeedoy'da fiyat, statik bir text alanindan daha fazlasidir.

Fiyatla ilgili gozlenen katmanlar:

- mevcut canli fiyat
- onceki fiyatlar veya history
- source bilgisi
- confidence score
- quality confidence
- anomaly score
- verified recency
- positive/negative vote sinyalleri

Bu, sistemin fiyat bilgisini "tek dogru" kabul etmek yerine, bir guven modeli icinde sundugunu gosterir.

### 6.9 Fiyat guncelleme kaynaklari

Kod ve migration izleri, fiyat degisikliginin birden fazla kaynaktan gelebilecegini gosteriyor:

- owner guncellemesi
- admin guncellemesi
- topluluk suggestion'i
- verified degisiklikler

Alert ve confidence mantiginda bu source ayrimi onemli rol oynuyor.

### 6.10 Fiyat guven mantigi

Tespit: Sistemde fiyat guven puani ve benzeri kavramlar sadece UI etiketi degil; veritabani tarafinda da uretilen yapilar.

Guven mantigini besleyen olasi bilesenler:

- son dogrulama zamani
- ayni item icin son donem oy dagilimi
- kullanici reputasyonu
- suggestion kalitesi
- anomali seviyesi
- price stability
- evidence varligi

Bu sayede kullaniciya sadece "fiyat = 240 TL" degil, "bu fiyat ne kadar guvenilir" sorusunun da cevabi verilmeye calisilir.

### 6.11 Gorsel yonetimi

Menu sistemi ve business sunumu icin farkli medya turleri vardir:

- business logo
- business cover
- QR/public menu background
- menu item photo

Bunlar hem public sunum hem de kalite algisi icin kritik roldedir. Sistem, business branding medyasini item medyasindan ayiran bir yapida calisir.

### 6.12 Ceviri ve cok dilli sunum

Public menu tarafinda dil parametresi normalize edilir ve menu translations kullanilir.

Bunun urun anlami:

- isletme ayni menuyu farkli dillerde sunabilir
- QR veya link parametresi ile dil deneyimi kontrol edilebilir
- SEO acisindan daha zengin bir public sayfa uretilir

### 6.13 QR Studio ile baglanti

Menu sistemi, QR Studio'nun da merkezindeki veridir.

Aklinaki urun akis su sekildedir:

- owner panelde bir business secer
- Next tarafindaki QR Studio'ya gecer
- mevcut public menu URL'si hesaplanir
- owner marka ayarlarini degistirir
- ayni menu farkli sunum sekliyle disariya dagitilir

### 6.14 Public menu presentation settings

QR/public menu katmani, isletmenin ana business_media kaydina ek olarak presentation settings saklar.

Bu ayarlar sunlari kapsar:

- varsayilan tema
- varsayilan dil
- logo override
- cover/background override
- link ve onizleme tercihleri

Yorum: Sistem menuyu icerik olarak bir yerde, sunum kimligi olarak baska bir yerde yonetmeyi sectigi icin hem operasyonel esneklik hem de branding kontrolu sunuyor.

### 6.15 OCR entegrasyonu

Menu sistemi OCR akisinin hedef katmanidir.

OCR'in sistem icindeki islevi:

- goruntuden metin cikarmak
- fiyat satirlarini yakalamak
- mevcut item listesiyle eslestirmek
- kullanicidan son onayi alip suggestion zincirine sokmak

Bu model, "sifirdan menu yaz" yerine "mevcut menuyu gunceI tut" mantigiyla daha uyumludur.

### 6.16 Receipt submission ile baglanti

Receipt/fis akisi, menunun saha gercegiyle eslestirilmesine yardim eder.

Urun acisindan bunun anlami:

- kullanici bir fiyat degisiminin kanitini sisteme verebilir
- admin/owner kararlarinda gorusel veriye ek olarak belge sinyali olur
- kalite motoru icin evidence agirligi yaratir

### 6.17 Menu sisteminin urun icindeki merkezi rolu

Baska bir deyişle menu sistemi, su modullerin baglandigi ortak omurgadir:

- discovery
- business detail
- public menu
- QR
- OCR
- favorites
- price alerts
- owner analytics
- moderation
- audit

Bu yuzden menu tarafindaki veri kalitesi, neredeyse tum urun kalitesini belirler.

## 7) Moderasyon Sistemi

Moderasyon, Yeedoy'un kod tabaninda kenarda duran bir destek mekanizmasi degil; urunun ana emniyet ve kalite omurgalarindan biridir.

### 7.1 Moderasyon neden merkezi onemde

Yeedoy topluluk katkisini aktif kullanir. Bu, iki sonucu beraber getirir:

- bilgi daha hizli guncellenir
- yanlis, kotu niyetli veya dusuk kaliteli veri riski artar

Bu nedenle sistem, katkıyı acarken ayni anda kontrol noktalarini da buyutmustur.

### 7.2 Moderasyona giren icerik tipleri

Tek kuyruk mantiginda birlesen ana tipler:

- report
- owner claim
- price suggestion
- business submission
- media flag

Ayrica ozel admin sayfalarinda bagimsiz operasyon yuzeyi olan tipler:

- receipt submissions
- suggestions
- suspended meal claims
- appeals
- temp uploads ile bagli medya riskleri

### 7.3 Moderasyonun giris kanallari

Moderasyona veri birden fazla kaynaktan gelir:

- mobil kullanici reportu
- mobil fiyat suggestion'i
- OCR/receipt tabanli gonderim
- owner claim talebi
- yeni business submission'i
- admin tarafindan tespit edilen business sorunu
- media upload veya photo flag

### 7.4 Queue mantigi

Tespit: Admin queue, farkli icerik tiplerini normalize ederek tek operasyon ekraninda topluyor.

Bu ekranin urun avantaji:

- operator birden fazla tabloyu tek tek bilmek zorunda kalmaz
- atama, SLA ve durum takibi tek davranis modeline baglanir
- bulk karar alma mumkun olur
- detay drawer ile ortak bir inceleme dili olusur

### 7.5 Uzmanlasmis moderasyon ekranlari

Queue genel bir merkezdir ama her sey orada sonlanmaz. Sistem ayni zamanda uzmanlasmis ekranlar da barindirir:

- claims sayfasi
- reports sayfasi
- price suggestions sayfasi
- business submissions sayfasi
- appeals sayfasi
- receipt submissions sayfasi

Bu modelin anlami:

- operasyon, genis bakis ile derin uzmanligi ayni anda destekliyor

### 7.6 Atama ve SLA mantigi

Kod ve dokumanlar, moderasyonda yalnizca status degil, zaman ve sorumluluk takibi de oldugunu gosteriyor.

Ornekler:

- raporlar icin 24 saat hedefi
- claimler icin 48 saat hedefi
- listelerde SLA badge gosterimi
- assign to me / clear assignment gibi aksiyonlar

Bu, sistemin moderasyonu "biri bakar" mantigindan cikardigini, operasyonel performans metriği haline getirdigini gosterir.

### 7.7 Claim moderasyonu

Claim moderasyonu, isletme sahipligini dogrulama isidir.

Tipik surec:

1. Kullanici sahiplik talebi gonderir.
2. Talep belge/detay ile kaydedilir.
3. Admin inceleme yapar.
4. Onay halinde owner iliskisi kurulabilir.
5. Red halinde gerekce saklanir ve notification uretilir.
6. Itiraz hakki dogabilir.

### 7.8 Business submission moderasyonu

Yeni business kayitlari kontrolsuz sekilde canliya alinmiyor.

Surec:

1. Submission sisteme duser.
2. Admin bunu business submissions ekraninda inceler.
3. Onaylarsa ana envantere eklenir.
4. Reddederse kayit canli urune yansimaz.

Bu, veri tabaninin buyumesini kontrol eden bir kapidir.

### 7.9 Price suggestion moderasyonu

Fiyat onerisi moderasyonu, Yeedoy'un en kritik kalite sureclerinden biridir.

Sebep:

- public yuzeyde en cok guven kaybina yol acan veri fiyattir
- topluluk katkisi burada yuksektir
- kucuk hatalar bile algiyi bozar

Sistem bu yuzden suggestion'lari asagidaki sinyallerle degerlendirir:

- reputasyon
- evidence
- zaman
- anomali
- ayni item icin diger suggestionlarla uyum
- owner/admin kayitlariyla celiski

### 7.10 Receipt submission moderasyonu

Receipt ekraninin ayri admin sayfasi olmasi, sistemin kanitli fiyat guncellemelerine ayri onem verdigini gosterir.

Bu akis muhtemelen su ihtiyaci cozer:

- price suggestion tek basina yetersiz kalinca belge uzerinden ikinci dogrulama
- sahte veya alakasiz gorsellerin elenmesi
- daha sonra audit edilebilir kanit kaydi tutulmasi

### 7.11 Review ve photo moderasyonu

Yorum ve fotograf tarafinda da koruyucu mekanizmalar vardir:

- verified contact zorunlulugu
- vote ve write guard
- report akisi
- photo vote ve media flag yapilari

Bu durum, kullanici uretimli gorsel ve yorumlarin serbest ama kontrolsuz olmadigini gosterir.

### 7.12 Itiraz mekanizmasi

Moderation appeal yapisinin ayri tablo, RPC ve admin yuzeyine sahip olmasi onemlidir.

Bu ne anlama gelir:

- platform tek asamali "red verdik bitti" mantiginda degil
- owner veya kullanici belirli kararlar icin ikinci inceleme isteyebilir
- kararlar notification template ve audit izi ile kayda girer

Bu, kurumsal olgunluk acisindan pozitif bir isarettir.

### 7.13 Otomatik kalite ve fraud sinyalleri

Migration izleri, moderasyonun tamamen manuel olmadigini gosteriyor.

Sistem tarafindan izlenen sinyaller:

- risk score
- anomaly score
- quality confidence
- shadow ban / auto pending gibi davranislar
- new user limitleri
- IP bazli sinyaller

Bu, moderasyonun yalnizca operatorun gozune degil, kurallastirilmis savunma katmanlarina da dayandigini gosterir.

### 7.14 Anti spam ve yazma koruma

Iki katman ayirt ediliyor:

- `anti-spam-guard`: kullanici aksiyon hacmini ve yeni hesap davranisini sinirlar
- `write-gatekeeper`: belirli write aksiyonlarini kontrollu kanaldan gecirir

Urun anlami:

- bir kullanici kisa surede asiri sayida review, verify, photo veya report gonderemez
- bazi write turleri dogrudan istemci tabanli spam riskine birakilmaz

### 7.15 Moderasyon sonucunun urune etkisi

Bir moderasyon karari yalnizca queue'da kalmaz. Etkileri sunlardir:

- public verinin kabul/red edilmesi
- owner rolunun verilmesi veya verilmemesi
- notification gonderimi
- audit kaydi
- guven ve kalite sistemine yeni sinyal eklenmesi
- bazen price alert veya analytics tarafina dolayli etki

## 8) Oylama, Siralama ve Kesif Mekanizmalari

Bu bolum, kullanicinin neyi once gorecegini ve neyin daha guvenilir sayilacagini belirleyen mantiklari toplar.

### 8.1 Siralama yaklasimi

Tespit: Mobil tarafta kullaniciya acikca anlatilan bir ranking formulu bulunuyor.

Aciklanan ana bilesenler:

- %30 mesafe
- %30 accuracy veya recent verification agirligi
- %20 etkileşim
- %20 kalite skoru

Bu, urunun iki seyi ayni anda soylemeye calistigini gosterir:

- yakin olan her sey otomatik en iyi degil
- sadece populer olan da otomatik en iyi degil
- veri kalitesi ve fiyat dogrulugu kesifte ciddi rol oynuyor

### 8.2 Kesifte kullanilan olasi sinyaller

Kod ve dokumanlardan cikan siralama sinyalleri:

- distance
- recent verification density
- average rating veya engagement
- quality score
- trust score
- local popularity
- district rank
- sponsored placement

Yorum: Bazilari ana ranking puanina, bazilari ise ayri gorunurluk bloklarina hizmet ediyor olabilir.

### 8.3 Helpful vote sistemi

Review tarafinda helpful vote mekanizmasi gorunuyor.

Urun faydasi:

- sadece cok yorum alan degil, kaliteli yorumlar da one cikar
- topluluk, hangi yorumun daha yararli oldugunu isaretler
- kullanicinin profilindeki yardimci oy metrikleri reputasyona katkı verebilir

### 8.4 Price vote sistemi

Menu item price vote yapisi, suggestion'larin yalnizca tek kisiye dayanmadigini gosterir.

Bu ne saglar:

- fiyat icin mini consensus olusturur
- son 30 gun oy dağilimi confidence hesaplamasina beslenir
- kullaniciya price confidence skorunun arka planinda topluluk sinyali oldugu anlatilabilir

### 8.5 Photo vote sistemi

Menu item photo oy yapisi da bulunuyor.

Bu, gorseller icin sunu saglar:

- hangi gorselin daha yararli veya dogru oldugu ayrisabilir
- alakasiz veya dusuk kaliteli gorseller daha kolay tespit edilir
- community moderation sadece text ile sınırlı kalmaz

### 8.6 Business fee crowd verification

Kodda `business_fee_votes` yapisi bulunmasi dikkat cekicidir.

Bu modulin urun anlami:

- sadece urun fiyati degil, ekstra masraf kalemleri de topluluk tarafindan isaretlenebilir
- kapak ucreti, servis ucreti, su ucreti gibi alanlar crowd verified mantikla tutulabilir
- bu bilgiler kullanici guveni icin kritik olabilir

Yorum: Bu alan, urunun menuyu finansal seffaflik platformuna dogru genisletme niyetini gosterir.

### 8.7 Trust score ve reputation modeli

Farkli yuzeylerde gorulen puanlar:

- kullanici trust score
- business trust score
- contribution trust
- silent quality score
- reputation score

Bunlarin urun icindeki rolleri farklidir:

- kullanici trust score: katkı kalitesine dayali bireysel guven
- business trust: isletmenin genel veri guvenilirligi
- contribution trust: katkı havuzunun genel sagligi
- quality score: menu kalitesini veya icerik tamligini gosteren metrik

Mobil urun dili 13.6 gelistirmesiyle bu karmasikligi iki ana katmana indirir:

- kullanici guveni: profilde gorulen topluluk guveni
- veri guveni: business/menu/item yuzeylerinde gorulen menu/fiyat guvenilirligi

Reputation, silent quality, accuracy, freshness, consensus ve benzeri alt metrikler artik son kullaniciya ana skor olarak degil, bu iki katmani besleyen destek sinyali veya bilgi skoru olarak aciklanir.

### 8.8 Heroes, gourmets ve achievement katmani

Sosyal/deneysel yuzeyler de oylama ve ranking mantigina baglidir.

Ornekler:

- `heroes`: askida yemek birakan kisileri one cikarir
- `gourmets`: lezzet uzmanlari veya katkı liderleri gibi bir topluluk katmani uretir
- achievement sistemi: verified streak, district top10 vb. unvanlar verir

Yorum: Bunlar yalnizca sosyal aksesuar degil; aktif katkıyı oyunlastirma ve topluluk liderligi uretme denemesidir.

### 8.9 Sponsored placement mantigi

Sponsorlu alanlarda ana urun riski, organik sira ile reklam cizgisinin karismasidir. Kod ve metinlerde buna karsi guardrail bulunuyor.

Gorulen prensipler:

- sponsorlu icerik etiketlenmeli
- sponsorlu yuzey organik kalite siralamasini bozmamali
- minimum trust veya rating esigi olabilir

Bu sayede ticari gelir ile guven arasinda denge kurulmaya calisiliyor.

### 8.10 Alerts ve anlamli degisim mantigi

Price alert katmani, her degisikligi bildirmemeye calisiyor.

Migration notlarindan cikan mantik:

- yalnizca anlamli delta'lar
- verified change onceligi
- favorites baglami

Yorum: Sistem "bildirim spam'i" yerine kullanicinin gercekten onemseyecegi fiyat hareketlerini hedefliyor.

### 8.11 Kesifin seffaflik boyutu

Tespit: Mobil metinlerde ranking formula ve trust score bilgi mesajlari acikca bulunuyor.

Bu tercih, urunun siralama ve puanlama mekanigini tamamen kara kutu yapmama niyetini gosteriyor. Yani sistem sadece sonuc gostermiyor, sonuc neden oyle oldugunu da en azindan kismen anlatmak istiyor.

## 9) Ekran Davranislari

Bu bolum, sistemde tespit edilebilen ana ekranlari uygulama bazinda aciklar. Her ekran icin hangi amaca hizmet ettigi, kullaniciya ne gosterdigi ve hangi aksiyonlara izin verdigi ozetlenir.

### 9.1 Mobil uygulama ekranlari

#### Splash

Amaci:

- Uygulama acilisinda gerekli durum kontrollerini yapmak

Ne gosterir:

- gecici yukleme veya markali acilis durumu

Kullanici ne yapabilir:

- aktif bir islem yapmaz; yonlendirme bekler

Hangi veri gelir:

- auth durumu
- onboarding durumu
- olasi ilk route karari

#### Onboarding

Amaci:

- yeni kullaniciya urun vaadini ve izinleri anlatmak

Ne gosterir:

- uygulamanin temel degerleri
- muhtemel konum veya bildirim beklentileri

Kullanici ne yapabilir:

- onboarding'i tamamlayip discovery'e gecer

#### Discovery

Amaci:

- uygulamanin ana kesif merkezi olmak

Ne gosterir:

- yakin isletmeler
- trend bloklari
- sponsorlu alanlar
- campaign stories
- kategori veya tematik girisler

Kullanici ne yapabilir:

- business acabilir
- kesif filtreleri veya siralama mantigina gore ilerleyebilir
- bazi deneysel modullere atlayabilir

Hangi veri gelir:

- business kartlari
- trend ve populerlik sinyalleri
- sponsorlu placement'lar
- kalite/trust/verification sinyalleri

#### Smart Feed

Amaci:

- discovery'den daha akissal, deneysel bir icerik tuketim yuzeyi sunmak

Ne gosterir:

- ilgilestirilmis veya siralanmis feed kartlari

Kullanici ne yapabilir:

- feed uzerinden business veya item acabilir
- hizli aksiyonlarla devam edebilir

Durum:

- deneysel/labs seviyesinde

#### Business detail

Amaci:

- tek business'i tum baglami ile gostermek

Ne gosterir:

- business ozeti
- menuye giris
- yorumlar
- rapor/favori aksiyonlari
- guven ve dogrulama sinyalleri
- bazi ek moduller: perks, nearby baglam, trendler

Kullanici ne yapabilir:

- menu acar
- review yazar
- review listesine gider
- report verir
- favoriye ekler

#### Chain sayfasi

Amaci:

- zincir veya bagli sube mantigini gostermek

Ne gosterir:

- ilgili zincire bagli business'ler veya ozet veriler

Kullanici ne yapabilir:

- belirli sube/business'lere gecis yapar

#### Menu sayfasi

Amaci:

- business menuyu kategori bazli gostermek

Ne gosterir:

- category listesi
- item kartlari
- fiyat ve bulunurluk
- bazen hizli filter/scroll yapisi

Kullanici ne yapabilir:

- item detayina gecer
- public share aksiyonlarina yonlenebilir

#### Menu item detail

Amaci:

- tek urun ve fiyat gercegini detaylandirmak

Ne gosterir:

- urun adi ve aciklamasi
- mevcut fiyat
- fiyat history ve confidence
- gorseller
- varyantlar
- dogrulama ve suggestion aksiyonlari

Kullanici ne yapabilir:

- fiyat verify eder
- fiyat onerir
- foto veya kanit akislara yonlenebilir
- paylasim yapabilir

#### Review create

Amaci:

- kullanicinin business deneyimini yaziya dokmesi

Ne gosterir:

- form ve puanlama bileşenleri

Kullanici ne yapabilir:

- yorum gonderir

#### Business reviews
Amaci:

- bir business icin toplulugun deneyimlerini listelemek

Ne gosterir:

- review listesi
- quality/helpful sinyalleri
- siralama secenekleri

Kullanici ne yapabilir:

- helpful vote verir
- report akisi baslatir

#### Favorites

Amaci:

- kullanicinin kaydettigi business'leri toplamak

Ne gosterir:

- favori kartlari
- bos durumda yonlendirici mesajlar

Kullanici ne yapabilir:

- favoriyi acar, kaldirir, bazen paylasir

#### Profile

Amaci:

- kullanici kimligi, trust ve katkı ilerlemesini gostermek

Ne gosterir:

- profil istatistikleri
- trust score
- helpful vote gibi katkı sinyalleri
- settings veya bagli yuzeylere gecis

Kullanici ne yapabilir:

- profil bilgilerini duzenler
- katkı sayfalarina gider
- hukuki ve ayar ekranlarina gecis yapar

#### Inbox

Amaci:

- bildirim ve olay kutusu olmak

Ne gosterir:

- bildirim listesi
- claim, report, price suggestion, review reply gibi olaylar

Kullanici ne yapabilir:

- bildirime tiklayip ilgili hedefe gecer

#### Suggest business

Amaci:

- kullanicidan yeni business adaylari toplamak

Ne gosterir:

- business bilgisi giris formu

Kullanici ne yapabilir:

- yeni mekan onerebilir

#### My suggestions

Amaci:

- kullanicinin onceki business suggestion veya benzeri katkilarini izlemesi

Ne gosterir:

- kendi suggestion kayitlari ve durumlari

Kullanici ne yapabilir:

- gecmis katkilari gorur

#### Compare
Amaci:

- business veya menu bazli kiyas deneyimi sunmak

Durum:

- var olan ama cekirdek olmayan genisleme yuzeyi

#### Budget combos

Amaci:

- butceye gore kombin veya item grubu onermek

Durum:

- deneysel

#### Group requests list/create/detail

Amaci:

- bir grup adina teklif veya secim toplama akisi sunmak

Ne gosterir:

- grup istekleri listesi
- yeni grup istegi olusturma wizard'i
- detay ve oy durumlari

Kullanici ne yapabilir:

- yeni grup istegi baslatir
- secenek ekler
- oy kullanir veya geri alir
- link paylasir

Durum:

- deneysel ama cok adimli calisan bir community modulu

#### Top businesses

Amaci:

- bolgesel veya sistem genelinde one cikan isletmeleri gostermek

Ne gosterir:

- sirali business listeleri

Kullanici ne yapabilir:

- business detail'e gecer

#### Gourmets / Following / social feed

Amaci:

- katki liderlerini veya takip iliskilerini one cikarmak

Ne gosterir:

- gourmet listeleri
- takip edilen kisiler
- ilgili feed akislari

Durum:

- deneysel/sosyal genisleme modulu

#### Taste Twin

Amaci:

- benzer damak zevki veya eslesen kullanici sinyalleri uretmek

Ne gosterir:

- match/similarity odakli ozetler

Durum:

- deneysel

#### Heroes

Amaci:

- askida yemek veya iyilik bazli topluluk liderligini gostermek

Ne gosterir:

- one cikan kullanicilar ve katkı sayilari

Durum:

- deneysel ancak urun kimligi acisindan anlamli bir sosyal katman

#### My suspended meals

Amaci:

- kullanicinin askida yemek claim gecmisini gostermek

Ne gosterir:

- durum kodlari
- teslim kodu
- fulfilled/pending review durumlari

Durum:

- deneysel/kismi

#### Developer tools

Amaci:

- QA ve gelistirme ekiplerine internal smoke/test yardimi vermek

Ne gosterir:

- runtime simulasyonlar
- push payload simulator benzeri yardimcilar

Bu ekran son kullanici urununun bir parcasi degil; operasyonel kalitenin parcasidir.

#### Legal

Amaci:

- hukuki metinlere erisim vermek, zorunlu policy acceptance'i yonetmek ve kullanici veri taleplerini baslatmak

Ne gosterir:

- ana legal merkeze giden dis linkler
- zorunlu policy acceptance ekraninda aktif versiyon kartlari
- terms/privacy/cookies/community/trust and safety linkleri
- profil ayarlarinda privacy request ve account deletion aksiyonlari
- bekleyen privacy/account deletion taleplerinin durum ozeti

Kullanici ne yapabilir:

- kayit ve login sonrasinda guncel policy versiyonlarini kabul eder
- `yeedoy.com/legal/...` uzerinden ana legal sayfalari acar
- verilerini disa aktarma veya gizlilik basvurusu yollar
- hesap silme surecini guclu onay adimi ile baslatir

#### Panel handoff ekranlari

Amaci:

- mobilde owner/admin rotalarina gidildiginde kullaniciyi dogru panel/web katmanina tasimak

### 9.2 Panel web ve owner ekranlari

#### Ana landing page

Amaci:

- `yeedoy.com` ana web yuzunu, urun konumlamasini ve guven anlatimini sunmak

Ne gosterir:

- hero, urun ozetleri ve QR sistemi nasil calisir bloklari
- trust/seffaflik/legal vurgu alanlari
- panel girisi, isletme kaydi ve legal merkezine gecis
- footer icinde ana legal linkler

#### Legal merkezi

Amaci:

- tum hukuki belgeleri tek merkezde yayinlamak

Ne gosterir:

- `/legal` index kartlari
- slug bazli legal detay sayfalari
- versiyon ve son guncelleme tarihleri
- TOC / icindekiler yapisi
- footer uzerinden ayni legal link agi

#### Owner operations dashboard

Amaci:

- owner icin operasyon ve kalite merkezi olmak

Ne gosterir:

- operasyon aksiyon kisayollari
- quality score
- trust/freshness/accuracy metrikleri
- local rank veya district rank
- growth merkezine gecis

Kullanici ne yapabilir:

- menu, fiyat onerileri, ekip ve aktivite akislari arasinda gecis yapar
- aktif business baglamini anlar

#### Owner growth hub

Amaci:

- owner icin talep, gorunurluk ve monetization merkezi olmak

Ne gosterir:

- son 30 gun KPI'lari
- analytics ozeti
- growth sinyalleri
- aktif sponsorluk paket katalogu, bos slot baskisi ve son kampanya erisimi
- pro/sponsorship lead formu

Kullanici ne yapabilir:

- detay analytics'e gider
- hangi sponsorluk yuzeyinde bos kapasite kaldigini gorur
- growth ilgisi gonderebilir
- fiyat pozisyonu ve donusum davranisini izler

#### Owner businesses

Amaci:

- kullanicinin yonettigi business'leri listelemek

Ne gosterir:

- business kartlari ve claim/business durumlari

Kullanici ne yapabilir:

- belirli business'i secer
- yeni business yaratir
- ilgili owner akislarini acar

#### Owner new business

Amaci:

- sisteme yeni business eklemek

#### Owner business submissions

Amaci:

- owner tarafindan gonderilen business ekleme sureclerini izlemek

#### Owner onboarding

Amaci:

- business'i henuz tam olmayan owner'a yonlendirici bir kurulum deneyimi sunmak

#### Owner menus

Amaci:

- menu listesi ve giris noktasi olmak

Ne gosterir:

- mevcut menuler
- durumlar
- editor/trash/restore gecisleri

Kullanici ne yapabilir:

- yeni menu acar
- mevcut menuyu duzenler
- yayinlar

#### Owner menu editor

Amaci:

- menu agacini duzenlemek

Ne gosterir:

- section/category/item duzenleyicileri
- photo ve varyant alanlari
- onizleme/yardimci akislari

Kullanici ne yapabilir:

- menuyu fiilen kurar ve gunceller

#### Owner section editor

Amaci:

- menu bolumlerini daha detayli duzenlemek

#### Owner trash / versions

Amaci:

- silinen veya arsivlenen icerigi geri getirmek

Ne gosterir:

- archived menu varliklari
- restore secenekleri

#### Owner analytics

Amaci:

- QR, menu acilis, category goruntuleme, item click ve donusum benzeri metrikleri gostermek

#### Owner price suggestions

Amaci:

- business odakli fiyat onerilerini incelemek

Ne gosterir:

- pending veya karar bekleyen suggestion'lar
- gerekirse approve/reject aksiyonlari

#### Owner suspended claims

Amaci:

- askida yemek ile ilgili owner tarafindaki operasyonlari gostermek

#### Owner requests
Amaci:

- group request veya benzeri community kaynakli istekleri owner baglaminda gostermek

#### Owner team

Amaci:

- ekip uyelerini ve rollerini yonetmek

#### Owner activity / audit

Amaci:

- owner kapsamindaki audit timeline'i gostermek

### 9.3 Admin panel ekranlari

#### Admin dashboard

Amaci:

- genel operasyon ozetini vermek

Ne gosterir:

- pending kuyruklar
- claims, reports ve diger KPI'lar

#### Admin search

Amaci:

- tum sistemde hizli arama yapmak

Ne gosterir:

- business, user, claim, report, submission, menu item vb. sonuc gruplari

Kullanici ne yapabilir:

- ilgili hedef ekrana derin link ile gecer

#### Admin queue

Amaci:

- tum moderasyon tiplerini tek listede yonetmek

#### Admin reports

Amaci:

- report kaynakli sorunlari ayrik uzman ekranda cozmeye yardim etmek

#### Admin appeals

Amaci:

- itirazlari yeniden incelemek

#### Admin claims

Amaci:

- sahiplik claim operasyonunu uzman ekranla yonetmek

#### Admin suspended claims

Amaci:

- askida yemek claimlerini incelemek

#### Admin price suggestions

Amaci:

- fiyat suggestion operasyonunu uzman ekranda yonetmek

#### Admin receipt submissions

Amaci:

- receipt/fis bazli kanit akisini workbench mantigi ile islemek
- OCR eslesmelerini, review durumunu ve batch inceleme firsatlarini ayni yuzeyde gostermek

Tek operasyon sozlesmesi `docs/admin_receipt_workbench.md` dosyasidir.

#### Admin suggestions

Amaci:

- business veya metin/suggestion kaynaklarini yonetmek

#### Admin businesses

Amaci:

- tum business kayitlarinin merkez yonetim ekrani olmak

Ne gosterir:

- arama, filtre, siralama, pagination, bulk secim
- verified ve atama durumlari

Kullanici ne yapabilir:

- duzenler, merge eder, verified yapar, public menu/QR aksiyonlarina gider

#### Admin business submissions

Amaci:

- yeni business adaylarini onaylamak veya reddetmek

#### Admin verified

Amaci:

- verified status ve tier mantigini yonetmek

#### Admin sponsorships

Amaci:

- sponsorlu kampanyalari olusturmak, gelir/erisimi izlemek ve yuzey dolulugunu yonetmek

#### Admin sponsorship packages

Amaci:

- satilabilir sponsorluk paketlerini fiyat, para birimi ve inventory limiti ile tanimlamak

#### Admin sponsorship leads

Amaci:

- owner tarafindan veya formlardan gelen ticari lead'leri paket ve yuzey kapasitesi baglaminda yonetmek

#### Admin group requests

Amaci:

- topluluk bazli grup talebi modulu uzerinde operasyonel gorunurluk saglamak

#### Admin audit

Amaci:

- tum platformda olan kritik aksiyonlari incelemek

#### Admin trash

Amaci:

- geri alinabilir iceriklerin veya restore akislarinin operasyon tarafini gormek

#### Admin table feedback

Amaci:

- veri tabani tablo geri bildirimleri veya operasyonel feedback alanini yonetmek

#### Admin dev tools

Amaci:

- urun guardrail ve test/yonetim yardimcilarini sunmak

#### Admin observability

Amaci:

- saglik, olay ve izlenebilirlik sinyallerini gostermek
- offline replay outcome'larini pencere bazli gormek, health summary threshold'lari ile alarm/warning durumunu ayirmak

#### Admin B2B exports

Amaci:

- anonim trend, bolgesel fiyat endeksi, menu enflasyonu ve price anomaly ciktisini CSV olarak sunmak
- her export'u ic operasyon, premium raporlama adayi veya dis veri urunu adayi olarak siniflandirmak
- export'larin anonimlestirme sinirini operatora acikca gostermek

Bu ekran, Yeedoy'un sadece son kullanici urunu degil, veri urunu olma potansiyelini de gosterir.
Tek urun sozlesmesi `docs/b2b_exports.md` dosyasidir.

#### Admin incidents

Amaci:

- belirli olay tipleri icin incident update kayitlarini toplamak

#### Admin temp uploads

Amaci:

- gecici yuklemeleri ve temizlik operasyonlarini izlemek

#### Admin user access

Amaci:

- tek bir kullanici icin rol, erisim ve impersonation baglamini gormek

### 9.4 Next.js web ekranlari

#### Public landing page

Amaci:

- Next katmaninin sinirini anlatmak ve kullaniciyi public QR/menu urunune yonlendirmek

Ne gosterir:

- public menu, QR ve SEO odakli konumlama
- owner/admin CRUD'un bu uygulamada olmadigina dair net sinir

#### Login

Amaci:

- QR Studio veya auth korumali web yuzeyleri icin giris noktasi olmak

#### Public menu ana sayfasi

Amaci:

- business'in paylasilabilir web menusu olmak

Ne gosterir:

- business adi
- branding gorselleri
- aktif menu
- kategori ve item listesi
- dil/tema tercihi

Kullanici ne yapabilir:

- kategori veya item detayina gecer
- menu icerigini tarar
- footer icindeki minimum Terms/Privacy/Cookies linklerini acabilir

#### Public category page

Amaci:

- belirli kategoriye derin link verip odakli bir gorunum sunmak

#### Public item page

Amaci:

- belirli item icin paylasilabilir detay URL'si sunmak

#### QR Studio

Amaci:

- owner/admin icin QR uretimi ve public sunum ayarlarini saglamak

Ne gosterir:

- canonical public link
- kisa link
- QR gorseli
- logo/cover/background secenekleri
- varsayilan tema ve dil

Kullanici ne yapabilir:

- ayarlari kaydeder
- PNG/SVG indirir
- link kopyalar

#### Forbidden

Amaci:

- yetkisiz ulasim denemesini net sekilde sonlandirmak

#### Short link route

Amaci:

- kisa kodu public menuye yonlendirmek ve tarama eventi yazmak

## 10) Is Kurallari

Bu bolum, kod ve veri modelinden cikarilabilen urun seviyesindeki is kurallarini toplar.

### 10.1 Bir kullanici birden fazla business yonetebilir

Tespit: Owner shell icinde business context bar ve "my businesses" listesi bulunmasi, kullanicinin birden fazla business ile iliskili olabilecegini gosterir.

Sonuc:

- owner hesabinin tek business ile sinirli olmadigi varsayilmalidir
- ekranlar aktif business secimi ile calisir

### 10.2 Ekip tabanli business yonetimi vardir

Tespit: owner team ve RBAC matrisleri, bir business'in tek kisiye ait yalin bir hesap modeliyle sinirli olmadigini gosterir.

Sonuc:

- ayni business birden fazla ekip uyesi tarafindan yonetilebilir
- herkes ayni write yetkisini almaz

### 10.3 Menu degisikligi versionli ve geri alinabilir sekilde ele alinir

Tespit: snapshot, trash ve restore modulleri mevcuttur.

Sonuc:

- menu degisikligi kritik operasyon kabul edilir
- hata durumunda geri donus beklenir

### 10.4 Fiyat guncellemeleri ayni agirlikta degildir

Tespit: source, quality confidence, anomaly score ve verified change mantigi vardir.

Sonuc:

- owner, admin ve topluluk kaynakli degisiklikler ayni guven seviyesinde ele alinmaz
- her fiyat degisikligi dogrudan public gercege donusmeyebilir

### 10.5 Her suggestion aninda yayina alinmaz

Tespit: suggestion, anomaly ve moderation queue altyapisi vardir.

Sonuc:

- fiyat ve bazi diger katkilar inceleme veya kalite filtresinden gecer

### 10.6 Katki icerigi icin kullanici guveni onemlidir

Tespit: verified contact zorunlulugu ve reputation skor mekanizmasi bulunur.

Sonuc:

- yeni veya dusuk guvenli hesaplar katkida daha cok kisit veya inceleme ile karsilasabilir

### 10.7 Review vote ve bazi write aksiyonlari kontrollu kanaldan gecer

Tespit: write-gatekeeper ve ilgili trigger'lar mevcuttur.

Sonuc:

- istemci dogrudan sinirsiz DB write yapamaz
- belirli write'lar sistem tarafindan rate limited sekilde uygulanir

### 10.8 Public menu erisimi genel olarak public okuma mantigina dayanir

Tespit: public menu tablolari icin public read RLS mevcuttur.

Sonuc:

- anonim web kullanicisi auth olmadan menu gorebilir
- owner/admin login ancak QR Studio gibi korumali alanlar icin gerekir

### 10.9 QR Studio business yetkisi gerektirir

Tespit: `can_manage_business` benzeri kontrol ve panel handoff mantigi vardir.

Sonuc:

- bir kullanici herhangi bir business icin QR olusturamaz
- sadece yetkili owner veya admin erisebilir

### 10.10 Public linkler canonical slug modeliyle calisir

Tespit: `public.businesses.public_slug` migration'i ve web route resolver'i public linkleri canonical slug modeline tasimistir.

Sonuc:

- dis dunyaya acik link modeli artik insan okunur `public_slug` uzerinden calisir
- eski `businessId` ve legacy slug linkleri backward-compatible redirect ile korunur

### 10.11 Sponsored icerik etiketlenmelidir

Tespit: sponsored disclosure, require sponsored label ve benzeri guardrail izleri mevcuttur.

Sonuc:

- ticari gorunurluk ile organik siralama birbirine karistirilmak istenmiyor

### 10.12 Sponsorlu placement icin kalite esigi olabilir

Tespit: minimum sponsored trust ve minimum sponsored rating guardrail anahtarlari gorunur.

Sonuc:

- her business reklam verse bile otomatik sponsorlu olarak one cikmayabilir

### 10.13 Claim kararlarina itiraz edilebilir

Tespit: moderation appeals ve claim notification template'leri vardir.

Sonuc:

- sahiplik karari tek adimli nihai karar olarak tasarlanmamis

### 10.14 Review, report, photo ve price verify akislarinda rate limit vardir

Tespit: anti spam guard bu aksiyonlar icin farkli limitler tanimlar.

Sonuc:

- kotuye kullanim ve hacimsel spam engellenmeye calisilir

### 10.15 Alert'ler yalnizca anlamli degisiklikler icin uretilir

Tespit: real alert trigger'lari favorites ve meaningful delta mantigina baglidir.

Sonuc:

- her mikro fiyat hareketi kullaniciya bildirilmez
- verified veya anlamli degisimler oncelenir

### 10.16 Audit kaydi urunun cekirdek kuralidir

Tespit: owner ve admin audit yuzeyleri, impersonation ve pek cok kritik write icin audit log tutar.

Sonuc:

- operasyonel kararlar izlenebilir olmak zorundadir
- support ve denetim surecleri buna dayanir

### 10.17 Soft delete tercih edilir

Tespit: menu archived, item availability ve deleted_at/deletion queue benzeri kaliplar kullanilir.

Sonuc:

- veri kaybi yerine geri alinabilirlik onceliklidir

### 10.18 Push ve inbox ayni hedef route mantigina baglanir

Tespit: push tap route resolver ve inbox hedef cozumleyicisi ortaklastirilmis.

Sonuc:

- kullanici ayni olaya ister push'tan ister inbox'tan gelsin, tutarli hedefe gitmelidir

### 10.19 Owner panel ile web QR yuzeyi ayrik origin olabilir

Tespit: panel handoff ve deploy sozlesmeleri ayri domain/origin modelini destekler.

Sonuc:

- urun dagitimi tek hosta bagli degildir
- session transfer kontrollu sekilde yapilir

### 10.20 Isletme verified statusu ayri bir yonetim nesnesidir

Tespit: admin verified ekranlari ve `admin_set_business_verified_v1` yapisi mevcuttur.

Sonuc:

- verified olmak yalnizca bir gorunum etiketi degil, yonetilen bir platform karari olarak ele alinir

### 10.21 Ana legal merkezi panel uygulamasinda tutulur

Tespit: panel uygulamasi landing page, `/legal` index, `/legal/:slug` detaylari ve footer legal linklerini ayni route yapisinda toplar.

Sonuc:

- ana landing ve ana hukuki merkez Next.js'e dagitilmaz
- mobil ve public QR yuzeyleri tek kanonik legal merkeze baglanir

### 10.22 Policy acceptance versiyon bazli takip edilir

Tespit: aktif policy versiyonlari `policy_versions` tablosunda tutulur; mobil acceptance akisi `terms` ve `privacy` versiyonlarini login sonrasi kontrol eder.

Sonuc:

- yeni policy versiyonu ciktiginda kullanici yeniden kabul vermek zorunda kalabilir
- acceptance kaydi yalnizca "checkbox gordu" degil, belirli versiyona verilmis onay olarak saklanir

### 10.23 Privacy request ve account deletion taleplerinde acik is tekil tutulur

Tespit: mobil repository duplicate guard uygular, migration tarafinda da acik request status'leri icin partial unique index bulunur.

Sonuc:

- ayni kullanici ayni anda birden fazla acik privacy request biriktiremez
- ayni kullanici ayni anda birden fazla acik account deletion talebi olusturamaz
- ayarlar ekraninda bekleyen taleplerin durumu yeni aksiyondan once gorunur

## 11) Eksik, Yarim veya Catismali Alanlar

Bu bolum, sistemde gorulen ama henuz tam kapanmamis, olgunlasmamis veya birbiriyle kismen catisan alanlari urun diliyle listeler.

### 11.1 Mobil sosyal katman tam olgun degil

Bosluk:

- smart feed
- taste twin
- gourmets/following
- group requests
- heroes
- suspended meals
- budget combos

Bu alanlarda kod, ekran ve bazi veri akislari mevcut; ancak cekirdek urun kadar olgun ve release merkezli degiller.

Urun anlami:

- sosyal ve topluluk tarafinda net bir genisleme vizyonu var
- fakat bugunku ana gelir/guven omurgasi buralar degil

### 11.2 Offline deneyimi ana backlogunu buyuk olcude kapatti

Tespit:

- SQLite-backed snapshot store, unified mutation queue, replay servisi, connectivity-restore tetigi ve client-side idempotency standardi var
- review/report/business suggestion/menu price suggestion/menu item suggestion write'lari icin explicit server-side idempotency de var; buna `favorite`, `price vote`, `follow`, `photo vote`, `price alert create`, `group offer vote` ve `presence submit` write'lari da eklendi. Devtools queue diagnostics, conflict policy ve suggested action yanina panel `/admin/observability` icindeki replay outcome gorunurlugu da geldi. Ancak daha kenar gelecekteki interaction write'lar ayni standardla surdurulmelidir

Sonuc:

- sistem halen online-first urun mantigiyla konumlanir
- ancak onceki kritik offline backlog'un buyuk kismi kapanmistir; bugunku risk bir temel eksiklikten cok, standardin gelecekte de korunmasidir
- kalan bosluk daha cok iOS, cihaz matrisi ve operasyon runbook disiplinindedir; temel mobile write/replay omurgasi artik kismi prototip seviyesinde degildir

### 11.3 True push e2e kapsami tam kapanmamis

Bosluk:

- push route intent omurgasi ve simulator/debug katmanlari mevcut
- ancak true FCM transport ve iOS cihaz dogrulamasi tam kapanmamis gorunuyor

Bu daha cok kalite ve operasyon boslugudur; urun akisinin tasarimi ise belirginlestirilmis durumdadir.

### 11.4 Next.js kapsaminda belge ve isimlendirme drift'i var

Tespit:

- Bazi ust dokumanlar veya README anlatilari Next katmanini daha genis bir owner dashboard gibi soyleyebiliyor
- fiili uygulama ise public menu, QR, branding ve minimum legal cikis tarafina daralmis durumda

Ayrica:

- route klasorunde `[slug]` ismi vardir; fiili davranis `publicSlugOrId` kabul eder ve canonical hedef slug modelidir

Durum notu:

- son legal/compliance hardening ile ana landing ve ana legal merkezin panel uygulamasinda oldugu ayrim daha net hale gelmistir
- buna ragmen ust seviye dokumanlarda "web" ifadesi gecerken panel public web ile Next public QR katmaninin karismamasi gerekir

Sonuc:

- yeni gelen ekipler icin kapsam yanilmasi olusabilir
- urun dili ile teknik isimlendirme bir noktada yeniden hizalanmali

### 11.5 Bazi backend yetenekleri UI'da sinirli gorunuyor

Ornekler:

- business fee votes gibi crowd transparency altyapilari backend'de belirgin, ama son kullaniciya sunulan UI yuzeyi sinirli veya daginik olabilir
- fraud/risk altyapisi guclu; ancak operator icin karar destek aciklamalari her yerde esit gorunmeyebilir

Bu durum, backend'in bazi alanlarda UI'dan ileride oldugunu dusundurur.

### 11.6 Bazi UI yuzeyleri backend olgunlugunu tam kullanmiyor olabilir

Ornek yorumlar:

- owner analytics ve moat/trust sinyalleri guclu bir omurga gosteriyor, fakat urun paketleme dili bunlari tam bir premium veri urunune cevirmemis olabilir
- B2B exports ekraninda urun hatti ve gizlilik siniri artik net; buna ragmen customer-facing satis ve lisans akislarinin ayrica urunlestirilmesi gerekir

### 11.7 Test ve CI operasyonu merkezilesti, derinlik acigi suruyor

Tespit:

- repo kokunde istemci bazli workflow omurgasi artik aciktir:
  - `mobile_quality`
  - `mobile_readiness`
  - `panel_quality`
  - `web_quality`
- mobile tarafinda `flutter analyze`, `flutter test test`, offline write guard, release gate dry-run ve iOS readiness audit merkezi workflow seviyesinde kosulabilir
- panel tarafinda analyze/test/build + `api_version_gate_check` ve `security_review_check --strict` artik repo-root workflow ile zorunlu kalite kapisina baglidir
- panel browser smoke hedefi Playwright'a tasinmis, derlenmis `main_web_smoke` artifact'i uzerinden owner shell + owner businesses + owner business submissions + owner new business submit + owner menus + owner menu editor + owner trash + owner trash restore + owner onboarding + owner requests + owner suspended + owner activity + owner analytics + owner audit alias + owner growth + owner growth lead submit + owner team + owner price suggestions + admin dashboard + admin login redirect + admin search + admin queue + admin reports + admin businesses + admin receipt submissions + admin observability route smoke'u ayni suite icinde toplanmistir; secili operator aksiyonlari olarak owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, admin queue assign, admin reports assign ve admin observability calibration save de browser seviyesinde dogrulanir. Son dogrulama `30 passed` olarak alinmistir
- web tarafinda typecheck/lint/unit/e2e/build zinciri repo-root workflow ile merkezi hale gelmistir
- iOS readiness audit repo icerigine gore artik `Podfile`, entitlements, export template ve push capability kanitlarini gordugu icin `BLOCK` yerine `WARN` seviyesine yakinlasmistir; kalan acik signed release asset'lari ve gercek cihaz smoke'tur
- iOS signed release icin team/provisioning/certificate secret modeli ve `ios_release_dry_run` workflow job'u tanimlanmistir; workflow artik `ios_signing_check.dart` ile placeholder/format/base64 audit'i, `ios_signing_assets_check.dart` ile decoded provisioning profile + export options + `Runner.entitlements` uyum denetimini yapar, export method'e gore `aps-environment` degerini normalize eder, IPA artifact'ini run sonucuna yukler ve signing artifact'larini build sonrasi temizler

Sonuc:

- release guvencesi onceki duruma gore belirgin sekilde daha az manuel
- kalan operasyon riski artik workflow yoklugu degil, smoke kapsami ve signed-device kanitlarinin derinligidir

### 11.8 Public URL ergonomisi gelisim alani

Durum:

- Kapatildi. Canonical public route artik `public_slug -> slug -> businessId` fallback zinciriyle calisiyor; legacy UUID path'leri redirect ile korunuyor.

### 11.9 Admin panelinde buyuk kapsam, daginik uzmanlasma riski

Tespit:

- admin yuzeyi cok sayida operasyon modulu barindiriyor
- queue, claims, reports, appeals, suggestions, verified, sponsorships, incidents, temp uploads, exports gibi alanlar buyuk bir operasyon yukunu tek uygulamada topluyor

Sonuc:

- buyume ile birlikte bilgi mimarisi karmasiklasabilir
- ekip bazli role specific konsollar ihtiyaci dogabilir

### 11.10 Owner tarafinda operasyon ve growth ayrimi kuruldu, growth katmani halen olgunlasiyor

Tespit:

- owner yuzeyi artik ikiye ayrildi:
  - `/owner`: kalite, trust ve operasyon akislar
  - `/owner/growth`: KPI, gorunurluk ve sponsorship lead akislar

Yorum:

- bilgi mimarisi onceki duruma gore daha net
- buna ragmen growth/pro/sponsorship katmani halen owner operasyon omurgasi kadar olgun degil

## 12) Sistemin Su Anki Durumu

Bu bolum, bugunku kod tabanina gore urunun fiili durumunu ozetler.

### 12.1 MVP'de guclu calisan alanlar

Asagidaki yuzeyler bugunku urun omurgasi olarak en olgun gorunen alanlardir:

- discovery
- business detail
- menu ve menu item detail
- review create ve review listesi
- helpful vote/report gibi temel topluluk sinyalleri
- favorites
- profile ve temel trust gostergeleri
- suggest business
- QR parse ve public menu acilisi
- owner business secimi ve menu CRUD omurgasi
- owner analytics ana gorevleri
- admin queue ve uzman moderasyon yuzeyleri
- business submissions ve claims operasyonu
- Next.js public menu ve QR Studio
- session handoff ve public tracking omurgasi
- panel legal merkezi ve mobile policy acceptance omurgasi

### 12.2 Kismen calisan veya olgunlasan alanlar

Su alanlar urunde belirgin ama henuz tam "cekirdek kadar guvenli" degil:

- push e2e kapsami
- embed ve entegrasyon sertlestirmeleri
- owner growth/pro/sponsorship lead deneyimi
- receipt submission operasyonunun tam saha olgunlugu
- bazi observability/incident operasyonlari
- signed iOS release kaniti ve cihaz matrisi

### 12.3 Deneysel veya labs seviyesindeki alanlar

- smart feed
- taste twin
- gourmets/following
- group requests
- heroes
- budget combos
- suspended meals sosyal/yardim odakli akislar

Bu alanlar urunun vizyonunu zenginlestiriyor ama cekirdek revenue ve guven omurgasi degiller.

### 12.4 Mobil uygulamanin bugunku urun pozisyonu

Mobil uygulama artik sadece katalog tarayan bir istemci degil. Bugunku durumda:

- discovery merkezli bir son kullanici urunu
- fiyat seffafligini ana farklastirici olarak kullaniyor
- topluluk katkisini aktif kullaniyor
- push ve inbox ile geri donus mekanizmasi kuruyor
- owner/admin operasyonunu bilincli sekilde panel disina tasiyor
- legal acceptance, privacy request ve account deletion akislarini artik cekirdek hesap deneyiminin parcasi olarak tasiyor

### 12.5 Panel uygulamasinin bugunku urun pozisyonu

Panel, artik basit bir admin araci olmaktan cikmis durumda.

Bugunku rolu:

- owner operasyon platformu
- admin governance platformu
- ana web landing ve footer merkezi
- ana legal merkezi
- audit ve role management merkezi
- monetization ve verified yonetim konsolu

### 12.6 Next.js uygulamasinin bugunku urun pozisyonu

Next katmaninin bugunku net rolu sunlardir:

- public menu yayinlama
- SEO katmani
- QR Studio
- branding/presentation settings
- public web analytics
- minimum Terms/Privacy/Cookies cikisi

Acik sinir:

- ana landing page burada degil
- ana legal merkezi burada degil
- owner/admin yazma operasyonlari burada degil

Bu rol, teknik olarak dar ama ticari olarak kritik bir katmandir. Cunku isletmenin dis dunyaya acilan vitrini burada bulunur.

### 12.7 Supabase backend'in bugunku olgunlugu

Backend katmaninda en guclu izlenen alanlar:

- RLS ve role hardening
- RPC tabanli is mantigi
- moderation ve quality engine
- anti spam ve controlled writes
- audit ve notifications
- analytics ve tracking
- owner team RBAC
- versioning ve soft delete
- policy_versions ve acceptance/request lifecycle tablolari

Yorum: Backend olgunlugu, bazi UI katmanlarinin onunde ilerliyor. Bu guzel bir taban, ancak urunlestirme ve operator deneyimi tarafinda hala alana ihtiyac var.

### 12.8 Urunun genel olgunluk karari

Kod tabanina gore Yeedoy bugun su noktadadir:

- MVP asamasini asmıs
- fakat tum genisleme modullerini tam production seviyesine getirmemis
- cekirdek veri guveni ve operasyon kontrolunde oldukca guclu
- sosyal/community v2 alanlarinda halen secici rollout asamasinda
- yonetim disiplini dogru kurulursa, yeni modul icadindan cok mevcut cekirdegi olceklendirme safhasina girebilir

## 13) Gelistirme Onerileri

Bu bolum, kod tabanindan cikan risk ve firsatlara gore onerileri listeler.

### 13.1 Cekirdek ile deneyseli urun navigasyonunda daha sert ayirin

Neden:

- Discovery, menu, price verify ve owner/admin operasyonu bugun cekirdek.
- Sosyal ve labs yuzeyleri ise daha farkli olgunlukta.

Oneri:

- Mobilde labs veya genisleme modullerini daha net feature gate ve navigasyon sinirlari ile ayirmak
- Urun KPI'larini cekirdek ve deneysel yuzeyler icin ayri izlemek

Durum notu:

- `2026-03-06` itibariyla mobil tarafta cekirdek alt-nav yeniden `/discover` etrafinda sabitlendi
- deneysel feed, gourmets, group requests, heroes, compare, budget combos ve benzeri yuzeyler tek `Labs` hub altina toplandi
- `enableLabs` ve `enablePhotoFeed` varsayilan olarak kapatildi; kapali deneysel rotalar discovery'e geri duser

### 13.2 Public web link modelini slug tabanli hale getirin

Neden:

- UUID tabanli public URL, SEO, marka algisi ve paylasim kolayligini sinirlar.

Durum:

- Tamamlandi. `2026-03-06` itibariyla `public.businesses.public_slug` bazli canonical public menu modeli devrede.

Uygulanan degisiklik:

- canonical public menu linki `public_slug`, fallback olarak `slug`, son fallback olarak `businessId` kullanir
- `/m/{businessId}` ve legacy slug istekleri canonical public slug rotasina redirect edilir
- panelde owner/admin public menu linki olusturma aksiyonlari slug tercihli calisir
- QR Studio canonical public linki ve preview linki slug merkezli uretir
- presentation settings kaydi sonrasi canonical slug path de revalidate edilir
- `2026-03-09` itibariyla `businesses.slug` ve `businesses.public_slug` kolonlari canli schema'da backfill edilmis durumdadir
- `2026-03-09` sertlestirmesiyle middleware artik slug path'lerini erken 404'a dusurmez
- live smoke kontrati `PLAYWRIGHT_SMOKE_BUSINESS_PATH` ile canonical slug hedefini ve legacy UUID redirect zincirini dogrulayabilir

### 13.3 Moderasyon karar destek aciklamalarini operator icin daha da zenginlestirin

Durum: Tamamlandi.

Uygulanan gelistirme:

- unified admin queue detail drawer artik yalnizca normalize ozet ve ham payload gostermiyor
- operator icin ayri bir `decision support` karti var
- burada `neden pending` ve `neden anomaly` ozetleri acik metin olarak uretiliyor
- ayni kartta quality confidence, anomaly score, conflict varyantlari, contributor reputation, risk score ve business quality gibi sinyaller severity bazli etiketlerle gosteriliyor
- claim ve report akislarinda claimant/reporter risk sinyalleri ile missing evidence veya auto-moderated baglami da ayni yuzeye tasindi
- business submission detail'i eksik alanlari ve review reason bilgisini acikca tasiyor
- operator drawer icinde son benzer kararlar da gosteriliyor
- bu history, audit timeline verisinden ayni kayit veya ayni business baglamindaki benzer hedef tipleri icin cekiliyor
- boylece operator bir kaydin yalnizca bugunku durumunu degil, yakin gecmiste nasil ele alindigini da gorebiliyor

Sonuc:

- moderation queue artik sadece is listesi degil, karar kalitesi destekleyen bir operator console davranisi gosteriyor
- backend quality / fraud / reputation sinyalleri UI'da aciklandigi icin kararlar daha tutarli hale geliyor

### 13.4 Owner urununu ikiye ayirin: operasyon ve growth

Durum:

- Tamamlandi.

Uygulanan gelistirme:

- `/owner` route'u owner operasyon merkezi olarak sadeletildi
- kalite skoru, trust/freshness ve operasyon aksiyonlari bu ekranda toplandi
- yeni `/owner/growth` route'u ile KPI, growth sinyalleri ve sponsorship lead formu ayrildi
- `/owner/analytics` growth alaninin detay analitik alt sayfasi olarak konumlandi
- owner shell navigation artik operasyon ve growth ayrimini birincil bilgi mimarisi olarak yansitiyor

### 13.5 Offline ve dusuk baglanti deneyimini kapatin

Durum:

- Tamamlandi.

Uygulanan gelistirme:

- disk-backed gecis katmani olarak `SharedPrefsLocalDbStore` devreye alindi
- `discovery`, `business detail`, `business menus`, `menu sections` ve `menu items` read path'leri ortak snapshot store'a write-through + fallback baglandi
- app root seviyesinde `OfflineSyncService` ile verify/submission queue replay ve expired snapshot prune foreground/resume tetigine baglandi
- devtools yuzeyine snapshot count + prune operasyonu eklendi
- `SqfliteLocalDbStore` ile Android/iOS runtime icin SQLite-backed bucket tablolar eklendi
- shared-prefs snapshot'lari ilk acilista SQLite store'a migrate edilir hale getirildi
- `ConnectivityRestoreService` ile offline -> online gecisinde replay backoff disi tetiklenir hale getirildi
- replay ve connectivity state degisimi telemetry event'lerine baglandi
- verify/submission queue kayitlari ortak `offlineMutationQueue` bucket'ina tasindi
- retry metadata queue kaydinda tutulur hale geldi ve replay sirasinda retry / resolve-conflict / drop karari ayrildi
- action-bazli `idempotency_key` standardi eklendi; ayni logical payload yeniden queue'lanirsa mevcut kayit guncellenir
- `submit_review_v2`, `submit_report_v2`, `submit_business_suggestion_v2`, `submit_menu_item_price_suggestion_v5`, `submit_menu_item_suggestion_v2`, `create_price_alert_v2`, `submit_presence_v2`, `set_group_offer_vote_v2`, `set_favorite_v2`, `set_menu_item_price_vote_v2`, `set_follow_v2` ve `set_menu_item_photo_vote_v2` ile cekirdek katki ve kritik secondary write'lara explicit server-side idempotency eklendi
- action-bazli retry/backoff politikasi network/auth/rate-limit/server siniflarina gore ayristirildi
- mobile devtools icinde offline queue diagnostics yuzeyi eklendi; retry/pending/bloklu durum, top retry reasons, conflict policy, suggested action ve dikkat isteyen item'lar operator tarafinda gorunur hale geldi
- panel `/admin/observability` yuzeyi `offline_mutation_outcome` event'lerini operator takip kartina tasidi
- panel health summary retry/drop oranlarini ve auth/server hotspot'larini threshold bazli alarm/warning olarak ayiriyor
- panel runtime calibration yuzeyi eklendi; offline alert threshold ve escalation persistence kurallari panelden deploy'suz ayarlanabilir hale geldi
- panel alarm emisyonu artik escalation hedefi ve seviyesiyle birlikte yaziliyor
- `tool/offline_write_guard_check.dart` ile mobile write RPC/direct-write envanteri registry altina alindi; yeni write yuzeyi registry'ye girmeden merge edilemez
- repo-root mobile_quality workflow'u artik offline write guard adimini da kosuyor

Operasyon notu:

- gercek trafik geldikce paneldeki threshold degerleri ops tarafindan yeniden kalibre edilebilir; bu artik urun/operasyon ayaridir, engineering blocker degildir

### 13.6 Community puanlarini kullaniciya daha tutarli aciklayin

Durum:

- Tamamlandi.

Uygulanan gelistirme:

- mobilde ortak `CommunityScoreExplainerSheet` ve `CommunityScoreGuideCard` katmani eklendi
- son kullaniciya aciklanan skor dili iki ana kategoriye indirildi:
  - kullanici guveni
  - veri guveni
- profile ekraninda ana skor `Topluluk guveni` olarak sabitlendi; accuracy, approval rate, contribution style ve quality streak gibi alanlar `Destek sinyalleri` altina alindi
- business detail ve trust breakdown yuzeylerinde `trust score` dili `veri guveni` olarak birlestirildi
- menu ekraninda freshness bazli skor artik `menu guncelligi` diye adlandiriliyor; trust terimiyle karistirilmiyor
- item detail tarafinda `price confidence` veri guveninin parcasi, `price/performance` ise bilgi skoru olarak aciklanir hale geldi

Etki:

- ayni sayfada birden fazla farkli skor gorulse bile bunlar artik ayni urun sozluguyle aciklanir
- yeni skor eklendiginde ortak sheet ve iki katmanli dil korunarak drift riski azalir

### 13.7 Sponsorlugu ayri veri urunu olarak olgunlastirin

Durum:

- Tamamlandi.

Neden:

- sponsorlu placement, guardrail ve lead/package yapisi gercek monetization iskeleti kuruyor

Uygulanan gelistirme:

- `sponsorship_packages` artik yalnizca etiket degil, yapisal fiyat ve kapasite verisi tasir:
  - `price_cents`
  - `currency_code`
  - `inventory_limit`
- admin paket yonetimi fiyat gosterimi disinda gercek satis parametrelerini de duzenler hale geldi
- admin sponsorship ana ekranina iki yeni urun gorunurlugu eklendi:
  - portfolio summary
  - surface inventory dashboard
- admin artik her yuzey icin su sorulari ayni ekranda gorebilir:
  - kac aktif paket var
  - kac canli unit dolu
  - kac bos slot kaldi
  - kac open lead bekliyor
  - son 30 gunde ne kadar erisim uretildi
  - tahmini aktif gelir ne seviyede
- owner growth hub yalnizca lead formu degil, self-serve sponsorship katalogu da gosterir hale geldi
- owner katalogu her aktif paket icin su sinyalleri verir:
  - sure ve fiyat
  - yuzeyteki mevcut doluluk ve bos kapasite
  - ayni business'in o yuzeyde zaten canli birimi olup olmadigi
  - son 30 gundeki kampanya erisimi
  - son lead durumunun ne oldugu
- owner lead formu artik `discovery` ve `business_page` disinda `stories`, `verified` ve `premium` yuzeyleri icin de talep toplayabilir
- sponsorship create akisi paket surface'i ile hizalanarak admin tarafinda yanlis surface/paket eslesmesini azaltir

Etki:

- sponsorship artik yalnizca manuel satis notu degil, inventory ve revenue takibi olan ayri veri urunudur
- owner ve admin ayni monetization omurgasina bakar; biri talep ve katalogu, digeri doluluk ve operasyonu gorur
- yeni sponsorlu yuzey acildiginda package + inventory + owner katalog zinciri icinde productize edilmesi daha kolay hale gelir

### 13.8 B2B exports ve veri urunu potansiyelini netlestirin

Durum:

- Tamamlandi.

Neden:

- bolgesel trend, menu enflasyonu, fiyat anomaly exportlari siradan bir restoran uygulamasinin uzerinde bir veri katmani oldugunu gosteriyor

Uygulanan gelistirme:

- admin B2B exports yuzeyi statik CSV listesi olmaktan cikarildi; her export icin urun hatti, gizlilik sinifi, freshness ve status bilgisi gorunur hale geldi
- export katalogu tek domain dosyasinda toplandi:
  - internal ops
  - premium reporting candidate
  - external data product candidate
- dort mevcut export net sekilde ayrildi:
  - `anonymous_trends` -> external data product candidate
  - `regional_price_index` -> external data product candidate
  - `menu_inflation` -> premium reporting candidate
  - `price_anomalies` -> internal ops
- gizlilik sinifi dili teklestirildi:
  - `anonymous_aggregate`
  - `restricted_aggregate`
  - `contract_only`
- panelde governance karti eklendi; operator artik hangi dataset'in hangi sinirla kullanilacagini UI icinde gorur
- `docs/b2b_exports.md` ile bu alanin urun siniri, dataset katalogu ve kullanilabilirlik kurallari tek kaynaga baglandi

Etki:

- B2B export alaninin ne zaman ic arac, ne zaman premium rapor, ne zaman dis veri urunu adayi oldugu artik yoruma acik degil
- yeni export eklendiginde product lane ve privacy class almadan yayinlanmamasi gereken bir sozlesme olustu
- veri urunu potansiyeli teknik kalinti degil, urun dili ve operasyon siniri olan bir modula donustu

### 13.9 CI ve release kapilarini merkezi hale getirin

Durum:

- Tamamlandi.

Uygulanan gelistirme:

- repo kokunde `.github/workflows/mobile_quality.yml` eklendi
- mobile quality workflow'u `flutter pub get`, `flutter analyze`, `flutter test test` ve `release_gate_check.dart` dry-run adimlarini otomatiklestirdi
- `.github/workflows/mobile_readiness.yml` ile manuel iOS readiness audit, release gate audit ve opsiyonel Android release dry-run tek giris noktasina toplandi; iOS signed release kolu artik `ios_signing_check.dart` yanina `ios_signing_assets_check.dart` ekleyerek provisioning profile / entitlements / export options kontratini de zorunlu kilar
- `tool/ios_readiness_check.dart` ile iOS proje dosyalari, entitlements, push capability, build wiring ve export kanitlari script ile denetlenir hale geldi
- `docs/mobile_ci_ios_readiness.md` ile workflow/secret/readiness sozlesmesi tek dokumana baglandi
- `.github/workflows/panel_quality.yml` ile panel analyze/test/build + API version/security gate scriptleri merkezi CI omurgasina baglandi
- panel smoke hatti `integration_test` yerine Playwright browser smoke'a tasindi; derlenmis `lib/main_web_smoke.dart` artifact'i static server uzerinden owner shell, owner businesses, owner business submissions, owner new business submit, owner menus, owner menu editor, owner trash, owner trash restore, owner onboarding, owner requests, owner suspended, owner activity, owner analytics, owner audit alias, owner growth, owner growth lead submit, owner team, owner price suggestions, admin dashboard, admin login redirect, admin search, admin queue, admin reports, admin businesses, admin receipt submissions ve admin observability rotalarini dogrular hale geldi. Ayni suite artik owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, admin queue assign, admin reports assign ve admin observability calibration save aksiyonlarini da kosar; son kosum `30 passed` ile temizdir
- `.github/workflows/web_quality.yml` ile web typecheck/lint/unit/e2e/build zinciri repo-root workflow seviyesinde zorunlu hale geldi

Kalan:

- panel browser smoke tarafinda cekirdek owner/admin route ve secili write/modal kapsami artik yeterli seviyededir; bundan sonraki gereklilik yeni route veya kritik write akislarinin ayni sprint icinde smoke suite'e eklenmesidir
- mobile gercek cihaz smoke ve iOS signed release kanitini daha sistematik hale getirmek
- secret scan ve device matrix gibi ek operasyon kapilarinin zamanla workflow katmanina tasinmasi

### 13.10 Dokuman kapsam drift'ini temizleyin

Durum:

- Tamamlandi.

Uygulanan gelistirme:

- `docs/system_full_documentation.md` merkez davranis dokumani olarak olusturuldu
- mobile offline/idempotency, owner growth ayrimi, admin decision support ve public slug modeli gibi son degisiklikler ust dokumanlara islenmeye baslandi
- `docs/mobile_ci_ios_readiness.md`, `docs/setup.md`, `docs/mobile_release_checklist.md` ve `apps/mobile_flutter/README.md` uzerinden mobile build/readiness dili daha tutarli hale getirildi
- `apps/panel_flutter_web/README.md` eklendi; panelin owner/admin operasyon siniri, QR/public handoff kontrati ve Playwright smoke modeli tek giris dokumanina baglandi
- `apps/web_next/README.md` merkez davranis dokumaniyla hizalandi; canonical public route artik acik sekilde `public_slug` merkezli olarak tarifleniyor
- `docs/apps.md` ve `docs/setup.md` panel/web icin app-bazli giris belgelerini referanslayacak sekilde sadeleştirildi

Kalan:

- gelecekteki urun ayrimlarinda ayni sprint icinde dokuman senkronunun zorunlu isletilmesi

### 13.11 Business data quality icin saha destekli operator araci dusunun

Durum:

- Tamamlandi.

Neden:

- OCR ve receipt akislari var ama buyuk olcekte menu kalitesi hala operasyonel is yukune donebilir

Uygulanan gelistirme:

- admin `receipt submissions` ekrani liste gorunumunden mini operator workbench'e tasindi
- receipt kayitlari icin review durumu eklendi:
  - `pending`
  - `reviewed`
  - `needs_followup`
- operator notu ve review zamani kayit bazinda tutulur hale geldi
- ekran artik sadece gorsel kanit degil, su katmanlari birlikte sunar:
  - filtrelenebilir queue
  - summary KPI kartlari
  - OCR match detail
  - batch review opportunities
- batch opportunity katmani ayni business veya chain icinde biriken receipt'leri one cikartir; operatora toplu menu inceleme adayi verir
- OCR match tablosu tespit edilen fiyat ile sistem fiyatini yan yana gostererek gercek drift ile OCR hatasini ayirmayi kolaylastirir
- `docs/admin_receipt_workbench.md` ile ekranin urun ve operasyon siniri tek dokumana baglandi

Etki:

- receipt/OCR akisi artik pasif kanit deposu degil, aktif veri kalite operasyon yuzeyidir
- sifir eslesmeli veya tekrar eden kayitlar operatorde kaybolmak yerine batch sinyaline donusur
- menu kalite operasyonu ile saha kaniti arasinda daha belirgin bir handoff olustu

### 13.12 Kullaniciya acik guven vaadini daha sistematik urunlestirin

Neden:

- ranking formula, verified labels, confidence score ve transparency mantigi urunun en farklastirici tarafi

Oneri:

- business page ve item detail tarafinda bu vaadi daha birlesik anlatan standart trust paneli
- "neden guvenilir" ve "neden supheli" dilini tek kalipta sunmak

## Ek A) Veri Akisi Ozeti

### A.1 Son kullanici veri akisi

1. Mobil kullanici discovery veya QR ile business/menu aciklar.
2. Login sonrasi gerekli policy versiyonlari kontrol edilir; eksikse legal acceptance kapisi acilir.
3. Okuma katmani public veya auth tabanli RPC'lerden veri alir.
4. Kullanici katkı yaparsa write guard, anti spam ve RLS devreye girer.
5. Sonuc moderation, audit, notification, quality engine ve gerekli ise legal request lifecycle'ina sinyal uretir.
6. Onayli veri menu/business gosterimine geri beslenir.

### A.2 Owner veri akisi

1. Owner panelde business baglamini secer.
2. Gerekli business terms kabulunu legal merkezle bagli akista verir.
3. Menu veya business guncellemesi yapar.
4. Yayinlanan veri public menuye yansir.
5. QR Studio branding ve dagitim katmanini ayarlar.
6. Analytics owner'a geri donus sinyali verir.

### A.3 Admin veri akisi

1. Admin queue veya uzman ekranda kaydi gorur.
2. Karar verir veya atama yapar.
3. Sonuc ilgili nesnenin statusunu degistirir.
4. Notification ve audit kayitlari yazilir.
5. Gerekirse owner/user deneyimi aninda degisir.

## Ek B) Klasor Bazli Sistem Ozeti

Bu alt bolum, kullanici talebindeki klasor tarama beklentisini urun mantigi ile eslestirir.

### `apps/`

- Tum istemci uygulamalarinin catisidir.
- Mobil, panel ve public web ayrimi burada netlesir.

### `apps/mobile_flutter/`

- Son kullanici urununun ana uygulamasidir.
- Kesif, menu, review, profile, notifications, topluluk ve legal acceptance akislarini tasir.

### `apps/panel_flutter_web/`

- Owner/admin operasyon merkezi ile birlikte ana web landing ve legal merkezidir.
- Sistemin en yogun write, governance, audit ve hukuki yayin davranisi buradadir.

### `apps/web_next/`

- Public menu vitrini ve QR Studio katmanidir.
- Marka, SEO, paylasilabilir menu deneyimi ve minimum legal cikisini tasir.

### `packages/`

- Paylasilan tip, config, API ve lokalizasyon yardimci katmanlaridir.
- Urunun platform ailesi olarak gelistirildigini gosterir.

### `supabase/`

- Sistemin gercek is kurallari, erisim sinirlari, kalite motoru ve legal compliance kayitlari burada tanimlanir.
- Migrations, urunun tarihsel evrimini de acikca gosterir.

### `docs/`

- Farkli urun alanlari icin aktif source of truth belgelerinin toplandigi klasordur.
- Bu buyuk belge, o parcali yapinin ustten sentezidir.

### `tools/`

- Build, seed, import, l10n ve workspace operasyonlarini destekler.
- Urunun sadece kod degil, veri ve dagitim operasyonu da oldugunu gosterir.

### `deploy/`

- owner/admin/next build ciktisi ayrimina isaret eder.
- Dagitimin tek yuzlu olmadigini, uygulama bazli oldugunu gosterir.

## Sonuc

Kod tabanindan cikan tablo nettir: Yeedoy, canli menu ve verified price ekseninde konumlanan; topluluk katkisini ciddiye alan; isletme sahiplerine operasyon paneli sunan; admin tarafinda ise guclu bir governance omurgasi kurmus olan cok katmanli bir urundur.

Bugunku sistemin en guclu tarafi, veri guvenini sadece UX soylemi olarak degil, bizzat veri modeli, moderasyon, quality engine, audit ve role management katmanlariyla birlikte ele almasidir.

En buyuk firsat alani ise sunlardir:

- cekirdek ile deneyseli daha sert ayirmak
- iOS ve push transport dogrulamasini kapatmak
- topluluk puan modellerini daha sade anlatmak
- signed iOS release, cihaz matrisi ve gercek push transport kanitlarini tamamlamak

Ozetle sistem, daginik bir prototip degil; fakat her modulu ayni olgunlukta olmayan, buna karsin cekirdek omurgasi oldukca guclu bir urun platformudur.

Yonetici icin son karar:

- Uygulama ailesi artik urun-market uyumu arayan ham bir prototip gibi degil, birden fazla istemcisi olan kurumsallasmaya aday bir platform gibi davranmaktadir.
- Cekirdek deger onerisi nettir: guvenilir menu, fiyat seffafligi, owner operasyonu ve kontrollu public dagitim.
- Sonraki buyuk kazanc yeni alan acmaktan cok, mevcut cekirdegi daha tahmin edilebilir, daha olculebilir ve daha release-safe hale getirmekten gelecektir.
- Bu nedenle siradaki yonetim onceligi ozellik sayisini artirmak degil; signed iOS release, gercek cihaz/push matrisi, rollout disiplini ve deneysel yuzey ayrimini tamamlamaktir.

