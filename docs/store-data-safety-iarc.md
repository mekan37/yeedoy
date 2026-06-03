# Yeedoy — Google Play Data Safety & IARC Taslak Beyanı

> **Tarih:** Haziran 2026
> **Durum:** TASLAK — Store formuna girilecek
> Uyari: Bu belge hukuki nihai onay yerine gecmez. Yayin oncesi bir hukuk danismaninin
> gozden gecirmesi onerilir. Kesin garanti icermez.
>
> **Privacy Policy URL:** https://yeedoy.com/gizlilik

---

## 1. Google Play Data Safety — Veri Envanteri

Asagidaki envanter AndroidManifest.xml (uygulamalar/mobil/android/app/src/main/AndroidManifest.xml)
ve iOS Info.plist (uygulamalar/mobil/ios/Runner/Info.plist) kaynak dosyalari incelenerek
olusturulmustur. Her kategorinin store formunda isaretlenmesi gereken degerler tabloda gosterilmistir.

### 1.1 Konum Verisi

| Alan | Deger |
|---|---|
| **Veri Turu** | Yaklasik konum (city-level) |
| **Toplanıyor mu?** | Evet — yakindaki isletmeler icin |
| **Kullanim Amaci** | Yakin isletme aramasi (app functionality) |
| **Kullaniciyla Iliskilendiriliyor mu?** | Hayir — anlik sorgu, saklanmiyor |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Hayir |
| **Veri Silebilir mi?** | N/A — saklanmiyor |
| **Sifreli Aktarim** | Evet (HTTPS/TLS) |
| **Play Form Kategorisi** | Location → Approximate location |

**Manifest kaynagi:** `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`

**Not:** GPS hassas konum kullaniliyor ancak backend'e sadece sehir/ilce duzeyinde
(arama filtresi olarak) iletiliyor. Tam koordinat loglanmiyor veya saklanmiyor.
Bu durumun gizlilik politikasinda acikca belirtilmesi gerekir.

---

### 1.2 Kamera ve Fotograf

| Alan | Deger |
|---|---|
| **Veri Turu** | Kullanici fotograflari (profil, menu) |
| **Toplanıyor mu?** | Evet — kullanici yuklerse |
| **Kullanim Amaci** | Profil fotografi ve menu gorsellerinin gosterilmesi |
| **Kullaniciyla Iliskilendiriliyor mu?** | Evet (hesap profili) |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Hayir (Supabase Storage uzerinde saklanir) |
| **Veri Silebilir mi?** | Evet — hesap silindiginde |
| **Sifreli Aktarim** | Evet (HTTPS/TLS) |
| **Play Form Kategorisi** | Photos and videos → Photos |

**Manifest kaynagi:** `CAMERA` + `READ_MEDIA_IMAGES` + `READ_EXTERNAL_STORAGE` (maxSdkVersion=32)

---

### 1.3 Hesap ve Profil Bilgileri

| Alan | Deger |
|---|---|
| **Veri Turu** | E-posta, kullanici adi, profil fotografı |
| **Toplanıyor mu?** | Evet — kayit sirasinda |
| **Kullanim Amaci** | Hesap yonetimi, kisisellestime |
| **Kullaniciyla Iliskilendiriliyor mu?** | Evet |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Hayir |
| **Veri Silebilir mi?** | Evet — hesap silme istegi |
| **Sifreli Aktarim** | Evet (HTTPS/TLS) |
| **Play Form Kategorisi** | Personal info → Name, Email address |

---

### 1.4 Yorumlar ve Kullanici Katkilari

| Alan | Deger |
|---|---|
| **Veri Turu** | Isletme yorumlari, menu fiyat bildirimleri |
| **Toplanıyor mu?** | Evet — kullanici gonderirse |
| **Kullanim Amaci** | Topluluk icerigi, fiyat veritabani |
| **Kullaniciyla Iliskilendiriliyor mu?** | Evet (hesap baglantili) |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Hayir (topluluk icerigi olarak platform icinde gosterilir) |
| **Veri Silebilir mi?** | Evet — kullanici kendi katkilarini silebilir |
| **Sifreli Aktarim** | Evet |
| **Play Form Kategorisi** | User content → User-generated content |

---

### 1.5 Cihaz Tanimlayicilari (AdMob)

| Alan | Deger |
|---|---|
| **Veri Turu** | Android Advertising ID, cihaz modeli |
| **Toplanıyor mu?** | Evet — AdMob tarafindan |
| **Kullanim Amaci** | Reklam kisisellestirme (AdMob) |
| **Kullaniciyla Iliskilendiriliyor mu?** | Evet (reklam kimligi) |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Evet — Google AdMob |
| **Veri Silebilir mi?** | Cihaz ayarlarindan Advertising ID sifirlanabilir |
| **Sifreli Aktarim** | Evet |
| **Play Form Kategorisi** | Device or other IDs → Device or other IDs |

**Manifest kaynagi:** AdMob App ID `ca-app-pub-1150074560839161~8895703262` meta-data olarak tanimli.

**Onemli:** AdMob kullaniminda Google'in UMP (User Messaging Platform) SDK entegrasyonu
AB/AT bolgelerinde zorunludur (GDPR). Bu surum icin degerlendirilmesi gerekir.

---

### 1.6 Crash Logs ve Diagnostics

| Alan | Deger |
|---|---|
| **Veri Turu** | Hata raporlari, stack trace, cihaz bilgisi |
| **Toplanıyor mu?** | Evet — Firebase Crashlytics |
| **Kullanim Amaci** | Uygulama kararliligi ve hata duzeltme |
| **Kullaniciyla Iliskilendiriliyor mu?** | Hayir (anonim) |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Evet — Google Firebase |
| **Veri Silebilir mi?** | N/A — Firebase retention politikasi 90 gun |
| **Sifreli Aktarim** | Evet |
| **Play Form Kategorisi** | App info and performance → Crash logs, Diagnostics |

**pubspec kaynagi:** `firebase_crashlytics: ^5.0.7`

---

### 1.7 Analytics Events

| Alan | Deger |
|---|---|
| **Veri Turu** | Ekran goruntumeleri, tiklamalar, search queries |
| **Toplanıyor mu?** | Evet — Firebase Analytics + Yeedoy analytics_events tablosu |
| **Kullanim Amaci** | Uygulama iyilestirme, yogun saat analizi |
| **Kullaniciyla Iliskilendiriliyor mu?** | Hayir (anonim aggregate) |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Evet — Firebase Analytics (Google) |
| **Veri Silebilir mi?** | Firebase: 14-63 gun retention; Yeedoy analytics_events: 90 gun |
| **Sifreli Aktarim** | Evet |
| **Play Form Kategorisi** | App info and performance → Analytics data |

**pubspec kaynagi:** `firebase_analytics: ^12.1.1`

---

### 1.8 Push Notification Token

| Alan | Deger |
|---|---|
| **Veri Turu** | FCM registration token |
| **Toplanıyor mu?** | Evet — kullanici izin verirse |
| **Kullanim Amaci** | Push bildirim gonderimleri |
| **Kullaniciyla Iliskilendiriliyor mu?** | Evet |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Evet — Google FCM |
| **Veri Silebilir mi?** | Evet — hesap silindiginde token iptal edilir |
| **Sifreli Aktarim** | Evet |
| **Play Form Kategorisi** | Identifiers → User IDs (FCM token) |

**Manifest kaynagi:** `POST_NOTIFICATIONS` izni; **pubspec kaynagi:** `firebase_messaging: ^16.0.2`

---

### 1.9 Biyometrik Veri (Referans)

| Alan | Deger |
|---|---|
| **Veri Turu** | Parmak izi / Face ID — YALNIZCA cihaz dogrulama |
| **Toplanıyor mu?** | Hayir — biyometrik veri cihazdan cikmaz |
| **Kullanim Amaci** | Hizli uygulama girisi (local_auth) |
| **Kullaniciyla Iliskilendiriliyor mu?** | N/A — veriye erisim yok |
| **Ucuncu Taraflarla Paylasiliyor mu?** | Hayir |
| **Play Form Kategorisi** | Beyan GEREKTIRMEZ (cihaz-icinde OS destegi) |

**Manifest kaynagi:** `USE_BIOMETRIC` + `USE_FINGERPRINT`
**iOS kaynagi:** `NSFaceIDUsageDescription` Info.plist'te tanimli

**Not:** Flutter `local_auth` paketi biyometrik ham veriyi hicbir zaman uygulama katmanina
aktarmaz; OS API sonucunu (basarili/basarisiz) alir. Bu nedenle Play Data Safety formunda
biometric data kategorisinde beyan gerekmez.

---

### 1.10 Ozet Tablo — Data Safety Form Girisi

| Kategori | Alt Kategori | Toplanıyor | Paylasiliyor | Iliskilendiriliyor |
|---|---|:---:|:---:|:---:|
| Location | Approximate location | Evet | Hayir | Hayir |
| Personal info | Name | Evet | Hayir | Evet |
| Personal info | Email address | Evet | Hayir | Evet |
| Photos and videos | Photos | Evet | Hayir | Evet |
| User content | User-generated content | Evet | Hayir | Evet |
| Device or other IDs | Device or other IDs | Evet | Evet (AdMob) | Evet |
| App info and performance | Crash logs | Evet | Evet (Firebase) | Hayir |
| App info and performance | Diagnostics | Evet | Evet (Firebase) | Hayir |
| App info and performance | Analytics | Evet | Evet (Firebase) | Hayir |
| Identifiers | User IDs (FCM token) | Evet | Evet (FCM) | Evet |

**Data Safety Form — Genel Sorular:**
- Veri sifreli aktariliyor mu? → **Evet** (TLS/HTTPS)
- Kullanici veri silme talep edebiliyor mu? → **Evet** (hesap silme)

---

## 2. IARC Icerik Derecelendirme Taslagi

> IARC (International Age Rating Coalition) Play Console uzerinden doldurulur.
> Asagidaki cevaplar IARC anket formuna gore hazirlanmistir.
> Form yolu: Play Console → App content → Ratings → Start questionnaire

### 2.1 Siddet

| Soru | Cevap |
|---|---|
| Kullanicilari korkutabilecek siddet icerigi var mi? | **Hayir** |
| Gercekci olmayan siddet var mi? | **Hayir** |
| Gercekci siddet var mi? | **Hayir** |

### 2.2 Cinsel Icerik

| Soru | Cevap |
|---|---|
| Cinsel veya romantik icerik var mi? | **Hayir** |
| Mustehcen icerik var mi? | **Hayir** |

### 2.3 Kumar

| Soru | Cevap |
|---|---|
| Gercek para ile kumar islevi var mi? | **Hayir** |
| Sanal para birimi ile kumar var mi? | **Hayir** |

### 2.4 Kullanici Uretimli Icerik (UGC)

| Soru | Cevap | Aciklama |
|---|---|---|
| Kullanici metin paylasabiliyor mu? | **Evet** | Isletme yorumlari |
| Kullanici fotograf paylasabiliyor mu? | **Evet** | Menu/isletme fotograflari |
| Kullanici diger kullanicilarla iletisim kurabiliyor mu? | **Hayir** | Direkt mesajlasma yok |
| UGC moderasyonu var mi? | **Evet** | Isletme sahipleri + admin moderasyonu |

**IARC Beklenen Derecelendirme:** 3+ veya 7+ (UGC nedeniiyle)

**Not:** UGC iceriginin kotu amacli kullanimi icin moderasyon mekanizmasi
(raporlama + admin panel silme) uygulamada mevcuttur. IARC formunda bu aciklanmalidir.

### 2.5 Konum Paylasimi

| Soru | Cevap |
|---|---|
| Kullanici konumu diger kullanicilara gosteriliyor mu? | **Hayir** |
| Konum verisi yerel/sunucu isleme icin kullaniliyor mu? | **Evet** — arama odakli |

### 2.6 Reklam

| Soru | Cevap |
|---|---|
| Uygulama reklam gosteriyor mu? | **Evet** — AdMob |
| Reklamlar cocuklara yonelik mi? | **Hayir** |
| Interstitial/davranissal reklamlar var mi? | Belirsiz — AdMob konfigure durumuna gore |

---

## 3. App Store Privacy Nutrition Labels (iOS)

> Apple App Store "Privacy" bolumu icin eslestirme.
> App Store Connect → App → App Privacy → Privacy Practices

### Data Used to Track You

| Kategori | Durum | Aciklama |
|---|---|---|
| Identifiers | Evet | AdMob advertising ID (ATT kapsaminda) |

**Not:** iOS 14.5+ ATT (App Tracking Transparency) framework zorunluluğu:
- [x] `NSUserTrackingUsageDescription` Info.plist'e eklendi (PR fix/mobile-ios-att-description)
- [ ] ATT popup (UMP SDK) — opsiyonel ama önerilir (GDPR/AB için)

### Data Linked to You

| Kategori | Durum |
|---|---|
| Contact Info (email) | Evet |
| User Content (reviews, photos) | Evet |
| Identifiers (user ID) | Evet |
| Location (coarse) | Hayir — saklanmiyor |

### Data Not Linked to You

| Kategori | Durum |
|---|---|
| Crash Data | Evet |
| Performance Data | Evet |
| Usage Data | Evet |

---

## 4. Manuel Yapilacak Store Adimlari

### Google Play Console

1. App content → Data safety → Start
2. Her veri kategorisi icin 1.10 Ozet Tablo'daki degerleri gir
3. "Does your app collect or share any required user data types?" → **Evet**
4. "Is all of the user data collected by your app encrypted in transit?" → **Evet**
5. "Do you provide a way for users to request that their data is deleted?" → **Evet**
6. Preview → Save → Submit

**Tahmini sure:** 30-60 dakika

### IARC (Google Play)

1. Play Console → App content → Ratings → Start questionnaire
2. App category: **Lifestyle** veya **Food & Drink**
3. Bolum 2'deki cevaplari kullan
4. Form gonderildikten sonra otomatik derecelendirme uretilir (genellikle 3+ veya PEGI 3)

### App Store Connect (iOS)

1. App → App Privacy → Privacy Practices → Edit
2. Her kategori icin Bolum 3'teki "Privacy Nutrition Labels" tablosunu kullan
3. ATT popup icin `NSUserTrackingUsageDescription` Info.plist'e ekle (AdMob geregi)
4. AdMob UMP SDK entegrasyonunu tamamla (GDPR bolgeler icin)

---

## 5. Acik Maddeler ve Oncelikli Eylemler

### KRITIK — Yayindan Once Zorunlu

| # | Madde | Aciklama |
|---|---|---|
| 1 | ATT Framework (iOS) | ~~`NSUserTrackingUsageDescription` Info.plist'e eklenmeli~~ ✅ Eklendi (PR fix/mobile-ios-att-description) — ATT popup (UMP SDK) opsiyonel ama önerilir |
| 2 | Google Play Data Safety formu | Bu belgeden yararlanarak Play Console'da manuel doldurulacak |
| 3 | IARC formu | Play Console'da questionnaire tamamlanacak |

### YUKSEK ONCELIK — Guclu Tavsiye

| # | Madde | Aciklama |
|---|---|---|
| 4 | AdMob UMP SDK | AB/AT kullanicilari icin GDPR riza mekanizmasi (Google UMP SDK) |
| 5 | KVKK VERBIS | Veri sorumlusu kaydi kontrol edilmeli (T.C. kanunu) |
| 6 | Gizlilik politikasi guncelleme | Konum verisinin saklanmadigini, FCM token kullanimini ve Firebase paylasimini acikca belirtmeli |

### ORTA ONCELIK

| # | Madde | Aciklama |
|---|---|---|
| 7 | Hesap silme akisi | In-app hesap silme secenegi Play politikasi geregince saglanmali (API 33+) |
| 8 | Veri retention suresi | Gizlilik politikasinda analytics_events (90 gun) ve Firebase (90 gun) aciklanmali |

---

## 6. Sinirlamalar ve Uyarilar

> Bu belge bir urun/teknik veri envanteri niteligindedir.
> Hukuki nihai beyan niteligini TASIIMAZ.

**Referans alinan kaynaklar:**
- `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml` (dogrudan incelendi)
- `uygulamalar/mobil/ios/Runner/Info.plist` (dogrudan incelendi)
- `docs/mobile-release-readiness.md`
- `docs/store_listing.md`
- pubspec.yaml Firebase/AdMob bagimlilik listesi

**Kapsam disi konular:**
- Supabase veri isleme anlasmasi (DPA) — ayrica degerlendirilmeli
- Ucuncu parti SDK veri politikalari (Firebase, AdMob) — ilgili SDK dokumantasyonlarina bakilmali
- Calisanlar veya B2B verileri — bu belge yalnizca son kullanici verisini kapsar

---

*Son Guncelleme: Haziran 2026*
*Hazirlayan: Legal Advisor (claude-sonnet-4-6)*
*Referans: docs/mobile-release-readiness.md, docs/store_listing.md, AndroidManifest.xml, Info.plist*
