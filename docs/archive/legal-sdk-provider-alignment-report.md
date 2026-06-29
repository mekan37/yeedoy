# Yeedoy Hukuki Belge — Üçüncü Taraf SDK/Servis Hizalama Raporu

**Hazırlayan:** compliance-auditor (teknik tarama) + koordinatör (dosya yazımı)  
**Tarih:** 2026-06-19  
**Durum:** TAMAMLANDI (son güncelleme: 2026-06-19 — veri-silme-talebi.md Bölüm 13 hizalandı)

---

## 1. Tarama Özeti

### Okunan dosyalar

- `C:\yeedoy\docs\legal\kvkk-aydinlatma-metni.md`
- `C:\yeedoy\docs\legal\gizlilik-politikasi.md`
- `C:\yeedoy\docs\legal\cerez-politikasi.md`
- `C:\yeedoy\uygulamalar\mobil\pubspec.yaml`
- `C:\yeedoy\uygulamalar\web\package.json`

### Kod tarama bulguları (gerçeklik doğrulaması)

| Arama | Sonuç |
|---|---|
| Mobil `lib/` Sentry | **0 dosya** — Sentry mobilde yok |
| Mobil Firebase Crashlytics | `lib/main.dart` — `FirebaseCrashlytics.instance.recordFlutterFatalError`, `recordError`, `setCustomKey` |
| Mobil Firebase Analytics | `lib/main.dart` — `FirebaseAnalytics.instance` |
| Mobil Firebase Performance | `lib/core/perf/firebase_perf_trace.dart` |
| Mobil AdMob | `lib/features/ads/data/native_ad_controller.dart`, `lib/features/ads/ui/native_ad_card.dart` — `NativeAd`, `AdRequest` |
| `pubspec.yaml` Sentry paketi | **Yok** |
| `pubspec.yaml` Firebase paketleri | `firebase_crashlytics ^5.0.7`, `firebase_analytics ^12.1.1`, `firebase_performance ^0.11.1+4`, `firebase_messaging ^16.0.2` |
| `pubspec.yaml` AdMob | `google_mobile_ads ^7.0.0` |
| Web `src/` Sentry | **0 dosya** |
| Web package.json üçüncü taraf analitik | GA/GTM/Plausible/Hotjar/Clarity/Mixpanel/`@vercel/analytics` — **yok** |
| Web Firebase | Yalnızca `firebase ^12.12.1` (FCM push) |

### Ana tutarsızlık

Her üç hukuki belge de hata izleme sağlayıcısı olarak **Sentry**'yi listeliyordu. Gerçek kod tabanında Sentry yoktur; yerine **Firebase Crashlytics** kullanılmaktadır. Ek olarak **Firebase Analytics, Firebase Performance ve Google AdMob** KVKK ve Gizlilik Politikası'nda hiç anılmıyordu (yalnızca Çerez Politikası Bölüm 3'te doğru listelenmiş).

---

## 2. Sentry Durumu

| Belge | Sentry geçen yerler | Yapılan değişiklik |
|---|---|---|
| KVKK Aydınlatma | Bölüm 3.8, Bölüm 6 (aktarım bloğu), Bölüm 13 özet, Bölüm 14 S-7 | Tümü **Firebase Crashlytics/Analytics/Performance** ile değiştirildi |
| Gizlilik Politikası | Bölüm 3.8, Bölüm 7 alt başlık+tablo, Bölüm 8 PII notu, Bölüm 14 özet, Bölüm 15 S-2 | Tümü **Firebase Crashlytics** ile değiştirildi |
| Çerez Politikası | Bölüm 3 `[KONTROL_EDILECEK]` notu | Hizalandı — artık "kaldırıldı" notu mevcut; Ç-5 **KAPATILDI** |

**Gerekçe:** Sentry hiçbir platformda kullanılmıyor. Mobilde hata/çökme izleme Firebase Crashlytics ile yapılıyor. Çift liste ("Sentry ve Firebase Crashlytics") yazılmadı.

---

## 3. Firebase SDK'ları

### Firebase Crashlytics (Çökme İzleme)

- **KVKK Aydınlatma Metni:** Bölüm 3.8 (Sentry satırı kaldırıldı, Crashlytics satırı eklendi) + Bölüm 6 (Sentry bloğu kaldırıldı, Firebase Crashlytics/Analytics/Performance bloğu eklendi)
- **Gizlilik Politikası:** Bölüm 3.8 tablo satırı değiştirildi; Bölüm 7 Sentry alt başlığı kaldırıldı, Firebase Crashlytics/Analytics/Performance alt başlığı eklendi; Bölüm 8 PII notu güncellendi
- **Çerez Politikası:** Bölüm 3 zaten doğru listeliyordu — değişiklik gerekmedi

### Firebase Analytics (Kullanım Analitiği)

- **KVKK Aydınlatma Metni:** Bölüm 3.8'e yeni satır eklendi; Bölüm 6 Firebase bloğuna dahil edildi
- **Gizlilik Politikası:** Bölüm 3.9'a yeni satır eklendi; Bölüm 7 Firebase bloğuna dahil edildi
- **Çerez Politikası:** Bölüm 3 zaten listeliyordu

### Firebase Performance (Performans İzleme)

- **KVKK Aydınlatma Metni:** Bölüm 3.8'e yeni satır eklendi; Bölüm 6 Firebase bloğuna dahil edildi
- **Gizlilik Politikası:** Bölüm 3.9'a yeni satır eklendi; Bölüm 7 Firebase bloğuna dahil edildi
- **Çerez Politikası:** Bölüm 3 zaten listeliyordu

---

## 4. AdMob

### Google AdMob (Uygulama İçi Reklam)

- **KVKK Aydınlatma Metni:** Bölüm 3.8'e reklam satırı + iOS ATT notu eklendi; Bölüm 6'ya ayrı AdMob bloğu eklendi (`[ADMOB_DPA_DURUMU]` placeholder'ı ile); Bölüm 13 özet güncellendi; Bölüm 14 S-7 güncellendi + yeni S-16 eklendi
- **Gizlilik Politikası:** Bölüm 3.9'a AdMob satırı eklendi; Bölüm 7'ye ayrı AdMob alt başlığı eklendi; Bölüm 14 özet güncellendi; Bölüm 15 S-2 güncellendi + yeni S-16 eklendi
- **Çerez Politikası:** Bölüm 3 ve 4.3 zaten "web çerezi değil" notu ile doğru listeliyordu

**iOS ATT / Data Safety notu:** Her iki ana belgeye (KVKK + Gizlilik) `[HUKUKCU_KONTROLU]` işaretiyle iOS ATT izin mekanizması ve Google Play Data Safety beyanı zorunluluğu eklendi.

---

## 5. Web Analitik/Tracker Durumu

Web tarafında **hiçbir üçüncü taraf analitik/izleme betiği bulunmadığı doğrulandı:**
- Google Analytics/Tag Manager: Yok
- Plausible, Hotjar, Microsoft Clarity: Yok
- Meta (Facebook) Pixel: Yok
- `@vercel/analytics`: Yok
- Segment, Mixpanel, Amplitude: Yok

Web'deki tek Firebase kullanımı FCM push bildirimidir.

**Gizlilik Politikası Bölüm 3.9'a** web analitik yalnızca birinci taraf olduğunu açıklayan not eklendi:
> "Web tarafında üçüncü taraf web analitiği (Google Analytics, Tag Manager vb.) kullanılmamaktadır; analitik tanımlayıcı yalnızca Yeedoy'un kendi sunucusuna gönderilir."

---

## 6. Çerez Envanteri Uyumu

| Teknoloji | Çerez Politikası'ndaki durum | Diğer belgeler |
|---|---|---|
| `sb-...-auth-token` | Bölüm 4.1 ✅ kesin tespit | Gizlilik Bölüm 10 + KVKK Bölüm 7 → Çerez Politikası'na atıf |
| `yd_client_id` | Bölüm 4.2 ✅ kesin tespit | Gizlilik Bölüm 3.9 + KVKK Bölüm 3.8 → analitik satırı |
| `yd-theme` | Bölüm 4.1 ✅ kesin tespit | Ayrı sayılmasına gerek yok |
| `panel-store` | Bölüm 4.1 ✅ kesin tespit | Ayrı sayılmasına gerek yok |

Bu dört kalemin Çerez Politikası dışındaki belgelerde ayrı ayrı listelenmesi zorunlu değil; her iki belge Çerez Politikası'na referans veriyor.

---

## 7. Kalan Placeholder'lar

### KVKK Aydınlatma Metni

- `[VERI_SORUMLUSU_UNVANI]`, `[VERI_SORUMLUSU_ADRES]`, `[KVKK_BASVURU_EPOSTA]`
- `[SAKLAMA_SURESI_*]` (birden fazla)
- `[FIREBASE_DPA_DURUMU]`, `[ADMOB_DPA_DURUMU]` ← **yeni eklendi**
- `[RESEND_DPA_DURUMU]`, `[SMS_SAGLAYICI_DPA_DURUMU]`, `[SMS_SAGLAYICI_ADI]`
- `[YURT_DISI_AKTARIM_DURUMU]`
- `[YAS_SINIRI]`, `[WEB_SITESI]`, `[YURURLUK_TARIHI]`

### Gizlilik Politikası

- Aynı veri sorumlusu, DPA, aktarım placeholder'ları
- `[ADMOB_DPA_DURUMU]` ← **yeni eklendi**
- `[HOSTING_SAGLAYICI]`, `[DESTEK_EPOSTA]`

### Çerez Politikası

- `[URL_EKLENECEK]` (3 adet), `[EMAIL_EKLENECEK]` (2 adet)
- `[YURURLUK_TARIHI]`, `[VERI_SORUMLUSU_UNVANI]`

---

## 8. Hukukçuya Kritik Sorular

| # | Soru | Öncelik |
|---|---|---|
| H-1 | Firebase Analytics ve Performance kullanıcı kimliğiyle ilişkili veri topladığından meşru menfaat yeterli mi, yoksa açık rıza mı gereklidir? | Kritik |
| H-2 | AdMob için iOS ATT izni ve Google Play Data Safety beyanı zorunlu mu; kişiselleştirilmiş reklam için ayrı açık rıza gerekli mi? | Kritik |
| H-3 | Firebase Crashlytics stack trace'lerinde istem dışı PII bulunma riski nasıl belgelenmeli; Google DPA/SCCs tek başına yeterli mi? | Kritik |
| H-4 | AdMob reklam tanımlayıcısı (Android Advertising ID / IDFA) KVKK kapsamında kişisel veri sayılır mı; saklama/aktarım nasıl beyan edilmeli? | Kritik |
| H-5 | Firebase Crashlytics/Analytics/Performance ve AdMob için Google Cloud DPA (Data Processing Amendment) imzalanmalı mı? SCCs yeterli mi? | Kritik |
| H-6 | `analytics_events` tablosundaki user_id içeren olay logları — meşru menfaat KVKK md.5/2-f kapsamında savunulabilir mi? | Yüksek |

---

## 9. Production Öncesi Teknik Bloklayıcılar

| # | Bloklayıcı |
|---|---|
| T-1 | iOS `Info.plist` içinde `NSUserTrackingUsageDescription` (ATT) ve AdMob `GADApplicationIdentifier` doğrulanmalı; ATT izin akışı `native_ad_controller.dart`'ta tetikleniyor mu kontrol edilmeli. |
| T-2 | Google Play Console Data Safety formu ve App Store Privacy "Nutrition Label" Crashlytics/Analytics/Performance/AdMob veri toplama beyanlarıyla güncellenmeli. |
| T-3 | Firebase Analytics/Crashlytics için kullanıcı opt-out mekanizması (collection enabled toggle) ürün içinde mevcut mu doğrulanmalı; aksi hâlde itiraz hakkı teknik olarak karşılanamaz. |

---

## 10. Değişiklik Özeti Tablosu

| Belge | Sentry kaldırıldı | Firebase Crashlytics eklendi | Firebase Analytics eklendi | Firebase Performance eklendi | AdMob eklendi | Ç-5 kapatıldı |
|---|---|---|---|---|---|---|
| KVKK Aydınlatma | ✅ (3.8, 6, 13, 14/S-7) | ✅ (3.8, 6) | ✅ (3.8, 6) | ✅ (3.8, 6) | ✅ (3.8, 6, 13, yeni S-16) | — |
| Gizlilik Politikası | ✅ (3.8, 7, 8, 14, 15/S-2) | ✅ (3.8, 7) | ✅ (3.9, 7) | ✅ (3.9, 7) | ✅ (3.9, 7, 14, yeni S-16) | — |
| Çerez Politikası | ✅ (Bölüm 3 notu güncellendi) | — (zaten vardı) | — (zaten vardı) | — (zaten vardı) | — (zaten vardı) | ✅ |
| **Veri Silme Talebi** | **✅ (Bölüm 13 — 2026-06-19)** | **✅ (Bölüm 13)** | **✅ (Bölüm 13)** | **✅ (Bölüm 13)** | **✅ (Bölüm 13, yeni satır)** | — |

**Kısıt uyumu:**
- Hiçbir kod/migration dosyasına dokunulmadı
- Mevcut `[PLACEHOLDER]` alanları korundu (`[ADMOB_DPA_DURUMU]` yeni placeholder olarak Veri Silme belgesine de eklendi)
- Kanun maddesi uydurulmadı — belirsiz nitelendirmeler `[HUKUKCU_KONTROLU]` ile işaretlendi
- Güncellenen belgeler: dört hukuki belge + bu rapor
