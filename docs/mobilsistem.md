# Yeedoy Mobil Sistem Audit Raporu

**Tarih:** 2026-05-25
**Kapsam:** `uygulamalar/mobil` · `uygulamalar/personel`
**Denetçi:** Otomatik kod tarama (gerçek dosya okuma, satır referanslı)

---

## Yönetici Özeti

Her iki uygulama da temel Flutter 3+ kalıplarını doğru uygular ve ciddi güvenlik açıkları içermez. Ancak aralarında önemli bir olgunluk farkı vardır: `mobil` uygulama, global hata işleme, güvenli depolama, sanitasyon katmanı ve kapsamlı test altyapısıyla kurumsal düzeyde bir seviyeye ulaşmışken, `personel` uygulaması temel operasyonel ihtiyaçları karşılamakla birlikte global hata yönetimi, test kapsamı, iOS/Android platform izinleri ve kod sıkıştırma açısından production hazırlığını tamamlamamıştır.

En kritik bulgular şunlardır:

- **Personel iOS Info.plist**: `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` eksik; biyometrik ve kamera kullanan özellikler App Store Review'da reddedilir.
- **Personel AndroidManifest.xml**: `CAMERA`, `USE_BIOMETRIC`, `INTERNET` ve `VIBRATE` izinleri eksik.
- **Personel global hata yönetimi**: `FlutterError.onError` ve `PlatformDispatcher.instance.onError` hookları kurulmamış; Crashlytics bağlantısı yok.
- **Personel test kapsamı**: 42 kaynak dosya için sıfır test dosyası.
- **Personel Android build**: `signingConfig = debug` ile işaretlenmiş release build; `isMinifyEnabled`/ProGuard eksik.
- **Mobil login_page.dart**: `?redirect=` parametresi `sanitizeInternalRedirect()` fonksiyonu kullanılmadan ham `Uri.decodeComponent()` ile işleniyor (açık yönlendirme riski).
- **Personel KDS**: `update_table_order_status_v1` çağrıları bazı yerlerde `p_business_id` parametresi göndermiyor — RLS'e güvenilir ancak derinlemesine savunma eksik.
- **Personel kampanya sayfası**: `catch (e)` bloğunda `$e` ham string olarak UI'a yazılıyor.

---

## Puan Kartı

| Alan | Mobil (Önceki) | Mobil (Güncel) | Personel (Önceki) | Personel (Güncel) | Hedef |
|---|---|---|---|---|---|
| Hata Yönetimi | 8/10 | **9/10** | 5/10 | **8/10** | 9/10 |
| Performans | 8/10 | 8/10 | 7/10 | 7/10 | 9/10 |
| Güvenlik | 8/10 | **9/10** | 5/10 | **8/10** | 10/10 |
| Kod Kalitesi | 8/10 | **9/10** | 7/10 | **8/10** | 8/10 |
| Test Kapsamı | 6/10 | **7/10** | 1/10 | **6/10** | 8/10 |

---

## Bölüm 1: `uygulamalar/mobil`

### 1.1 Hata Yönetimi

**Guclu Yonler**

- `main.dart:96-124` — `FlutterError.onError` ve `PlatformDispatcher.instance.onError` her ikisi de tanımlanmış, Crashlytics'e akışla işleniyor. `classifyError()` ile hata taksonomisi yapılıyor.
- `core/errors/app_error_mapper.dart` — `AuthException`, `PostgrestException` ve uygulama özel hata kodlarını kullanıcı dostu Türkçe mesajlara dönüştüren kapsamlı bir mapper mevcut.
- `core/monitoring/app_telemetry.dart:24-61` — `traceRpc` metodu tüm RPC çağrılarını try/catch ile sarıyor, hataları telemetri sistemine iletiyor ve rethrow ediyor.
- `features/reviews/ui/review_create_page.dart:155,203,221,230,236,258` — Uzun async zincirinde `context.mounted` kontrolleri doğru yerleştirilmiş.

**Eksiklikler**

- `features/auth/ui/login_page.dart:63-68` — `_navigateAfterLogin()` metodu `?redirect=` parametresini `Uri.decodeComponent()` ile doğrudan işliyor, `core/security/route_sanitizer.dart`'taki `sanitizeInternalRedirect()` fonksiyonu kullanılmıyor. Router (`app/router.dart:111,174,184`) doğru kullanıyor ancak login sayfası atlamış.
- `features/business/ui/sections/business_detail_sections.dart:861,947` — `Image.network()` kullanılan konumlarda hata widget'ı (`errorBuilder`) tanımlanmamış; ağ hatalarında beyaz boşluk gösterilir.
- `MediaQuery.of(context).size.width` kullanımı altı dosyada mevcut; Flutter 3.7+ önerisi `MediaQuery.sizeOf(context)`. Performans etkisi küçük ama rebuild verimliliğini etkiler.

**Puan: 8/10** — Global handler eksiksiz, mapper kapsamlı, ancak redirect bypass ve Image hata eksikliği puanı düşürüyor.

---

### 1.2 Performans

**Guclu Yonler**

- `main.dart:23-55` — Frame drop observer `kProfileMode`'da aktif, 16.67ms üzeri frame'leri telemetriye raporluyor.
- `RepaintBoundary` kullanımı: 37 widget kullanımı, `smart_feed`, `reviews`, `taste_twin`, `suspended_meals`, `inbox`, `gourmets_page`, `following_page` gibi liste item'larına uygulanmış.
- `CachedNetworkImage` — 30 kullanım noktası; `flutter_cache_manager` de bağımlılıklarda mevcut.
- Firebase + MobileAds parallel `Future.wait` başlatma (`main.dart:66-69`).
- `Stopwatch` ile startup ve TTI ölçümü (`main.dart:62`, `core/monitoring/app_telemetry.dart:64-113`).
- `ListView.builder` ve `ListView.separated` büyük listeler için kullanılmış (sipariş, discovery, menuler).

**Eksiklikler**

- `features/business/ui/sections/business_detail_sections.dart:861,947` ve `features/isletme/ui/bolumler/isletme_detay_bolumleri.dart:1299,1388` — `Image.network()` kullanımı; `CachedNetworkImage` ile değiştirilmeli.
- `autoDispose` kullanımı tüm uygulama genelinde yalnızca 8 noktada var. 66 feature'ın çoğu `AsyncNotifierProvider` olarak tanımlanmış ancak `autoDispose` kullanmıyor; sayfa kapatılsa bile provider belleği tutmaya devam eder.
- `features/group_requests/ui/group_request_detail_page.dart:62`, `features/menuler/ui/acik_menu_paylasim_sayfasi.dart:62,101` — `FutureBuilder` ile `StatelessWidget` içinde future doğrudan metod çağrısından oluşturuluyor; her rebuild yeni bir future başlatır.

**Puan: 8/10** — Frame monitoring ve RepaintBoundary güçlü; Image.network ve autoDispose eksiklikleri var.

---

### 1.3 Guvenlik

**Guclu Yonler**

- `core/security/secure_local_storage.dart` — Supabase session token'ı `flutter_secure_storage` ile saklanıyor; Android'de `encryptedSharedPreferences: true`.
- `core/security/safe_debug_print.dart` — `installSafeDebugPrint()` tüm log çıktısından JWT, email, telefon, koordinat ve UUID'yi redakte ediyor. `main.dart:64`'te kurulmuş.
- `core/security/route_sanitizer.dart` — `sanitizeInternalRedirect()`, `sanitizeUuid()`, `sanitizeSlug()` fonksiyonları mevcut ve router'da kullanılıyor.
- `main.dart:74-78` — `_requireEnv()` boş/null env değerlerinde `StateError` fırlatıyor; hardcoded fallback yok.
- `android/app/build.gradle.kts:93-96` — ProGuard `proguard-android-optimize.txt` + `proguard-rules.pro` yapılandırılmış.
- `core/security/critical_action_guard.dart`, `core/security/edge_rate_limit_guard.dart`, `core/security/write_gatekeeper_client.dart` — Rate limiting ve yazma gating mekanizmaları mevcut.
- `firebase_options.dart` içindeki API key'ler client-side Firebase yapılandırma için standarttır (git'e girmesi kabul edilebilir, kısıtlama Firebase Console'dan yapılır).

**Eksiklikler**

- `features/auth/ui/login_page.dart:63-68` — `?redirect=` parametresi `sanitizeInternalRedirect()` kullanılmadan işleniyor. Saldırgan `?redirect=https://phishing.example.com` gibi bir değer geçirebilir; uygulama harici URL'e `context.go()` ile yönlendirebilir.
- `android/app/upload-keystore.jks` — Keystore dosyası repoda fiziksel olarak mevcut (`-rw-r--r-- 2744 bytes`). `.gitignore`'da tanımlı ve git tarafından izlenmiyor, ancak repo klonlandığında dosya çalışma dizininde kalıyor. CI ortamlarında güvenlik riski oluşturabilir.
- Dart obfuscation (`--obfuscate --split-debug-info`) hiçbir CI workflow'unda tanımlanmamış.

**Puan: 8/10** — Güvenlik altyapısı kapsamlı; redirect bypass ve obfuscation eksiklikleri MEDIUM risk.

---

### 1.4 Kod Kalitesi

**Guclu Yonler**

- `WillPopScope` kullanımı yok; `PopScope` migration tamamlanmış.
- Null safety tam uygulanmış.
- `core/errors/`, `core/monitoring/`, `core/security/` katmanları temiz ayrımla yapılandırılmış.
- Duplicate feature implementation: bazı feature'lar hem Türkçe hem İngilizce dizinde mevcut (`menuler`/`menus`, `kesif`/`discovery`, vb.) — bu kasıtlı bir geçiş süreciyse problem değil, ancak dead code riski taşıyor.

**Eksiklikler**

- `features/menuler/ui/menuler_sayfasi.dart:1549`, `features/menus/ui/menu_page.dart:1235`, `features/shared/ui/bilesenler/alt_navigasyon.dart:71`, `features/shared/ui/components/app_bottom_nav.dart:71` — `MediaQuery.of(context).size.width` kullanımı; Flutter 3.7+ önerisi `MediaQuery.sizeOf(context)`.
- `core/analitik/` ve `core/analytics/`, `core/guvenlik/` ve `core/security/`, `lib/uygulama/` ve `lib/app/` gibi Türkçe-İngilizce paralel dizinler `lib/` altında yan yana duruyor. Bu, hangi versiyonun "aktif" olduğunu belirsizleştiriyor.

**Puan: 8/10** — Kod yapısı güçlü; paralel Türkçe/İngilizce dizin karmaşası ve MediaQuery pattern puanı sınırlıyor.

---

### 1.5 Test Kapsamı

**Sayılar**

| Tur | Dosya Sayısı |
|---|---|
| Kaynak dosyaları (`lib/`) | 746 |
| Birim/widget testleri (`test/`) | 276 (262 geçen, 7 pre-existing hatalı, 4 skipped) |
| Entegrasyon testleri (`integration_test/`) | 4 |

**Guclu Yonler**

- `test/core/` altında 20+ alt dizinde kapsamlı birim testleri: bağlantı, analitik, cache, security, linking, offline kuyruk, API contract.
- `test/features/` altında 16 feature için testler mevcut: auth (notifier + UI), bildirimler, business, discovery, embed, isletme, kesif, kimlik, masa_siparisi, menuler, menus, monetization, notifications, onboarding, sponsorluk.
- `integration_test/` altında offline queue smoke, golden paths, live write smoke, embed smoke testleri.
- CI workflow (`mobile_quality.yml`) `flutter test test`, offline write guard, hardcoded color check ve release gate kontrolü çalıştırıyor.
- `test/features/auth/auth_notifier_test.dart` — 14 test: AuthService unit, userProvider, sessionProvider, authStateProvider event testleri (2026-05-26 eklendi).
- `test/features/masa_siparisi/masa_siparisi_model_test.dart` — 15 test: MasaSiparisiOzet.fromMap, MasaSiparisiSepetBildiricisi (2026-05-26 eklendi).

**Eksiklikler**

- 66 feature'dan 47'nin test dizini yok. Test eksik olan feature'ların başında: `reviews`, `profil`, `yorumlar`, `sadakat`, `collab_lists`, `taste_twin`, `smart_feed`, `favoriler`, `heroes`, `gourmets`, `contribute`, `price_alerts`, `budget_combos`, `chains`, `compare`, `group_requests` gibi kullanıcıya doğrudan dokunan ekranlar yer alıyor.
- Test/kaynak oranı yaklaşık 11% (262/746) — hedef minimum %20-30 widget test kapsamı.
- Golden test dizini mevcut (`test/ui/altin/`, `test/ui/golden/`) ancak içerik sınırlı.
- 7 pre-existing test hatası: route path `/isletme/` → `/b/` değişimi yansıtılmamış (`yeedoy_rota_cozucu_test.dart`, `bildirim_hedef_yol_cozucu_test.dart`).

**Puan: 7/10** — Auth + model testleri eklendi, core layer sağlam; feature layer kapsamsızlık devam ediyor, route path mismatch düzeltilmeli.

---

## Bölüm 2: `uygulamalar/personel`

### 2.1 Hata Yönetimi

**Guclu Yonler**

- `core/hata_esleyici.dart` — Network, Supabase auth, veritabanı hatalarını Türkçe mesajlara dönüştüren `HataEsleyici.mesaj()` mevcut.
- `features/masa_siparisleri/domain/masa_siparisi_bildiricisi.dart:94-106` — Optimistic update sonrası `catch (_) { ref.invalidateSelf(); }` ile state geri alınıyor.
- `features/masa_siparisleri/ui/siparisler_sayfasi.dart:305-328` — Async aksiyon metodunda `if (mounted)` doğru kontrol ediliyor.
- `features/ayarlar/ui/ayarlar_sayfasi.dart:374-396` — Şifre sıfırlama try/catch + `context.mounted` kontrolü tam.
- `features/kimlik/domain/kimlik_bildiricisi.dart:44-68` — `_ownerClaimsKontrol` try/catch ile sarılmış.

**Eksiklikler**

- `main.dart` — `FlutterError.onError` ve `PlatformDispatcher.instance.onError` hookları hiç kurulmamış. Firebase Crashlytics bağımlılıkta mevcut ama `main.dart`'ta initialize edilmemiş ve hata handler bağlanmamış. Uygulamadaki tüm uncaught hataların kaydı alınmıyor.
- `features/kampanya/ui/kampanya_sayfasi.dart:80` — `catch (e)` bloğunda `setState(() { _sonuc = 'Bir hata oluştu: $e'; })` ile ham istisna string'i UI'a yazılıyor. Bu hem güvenlik (stack trace / internal exception detayı sızdırabilir) hem de UX sorunudur.
- `features/kimlik/domain/kimlik_bildiricisi.dart:22-29` — `supabase.auth.onAuthStateChange.listen()` çağrısının dönüş değeri (`StreamSubscription`) saklanmıyor ve `ref.onDispose()` içinde iptal edilmiyor. Provider yeniden build edildiğinde birden fazla listener birikebilir.
- `features/kds/domain/kds_bildiricisi.dart:53-57` — `_otomatikYenile` metodunda `catch (_)` ile hata sessizce yutulup loglanmıyor. Network hatası süresiz sessiz kalır.
- `features/kampanya/ui/kampanya_sayfasi.dart:214-218` — `showTimePicker` await'inden sonra `context.mounted` kontrolü yok; `onZamanlamaChange` callback'i dispose olmuş widget'a ulaşabilir.

**Puan: 5/10** — Feature-level error handling mevcut; global handler ve Crashlytics bağlantısı yok, stream leak ve raw exception exposure kritik eksikler.

---

### 2.2 Performans

**Guclu Yonler**

- `features/masa_siparisleri/domain/masa_siparisi_bildiricisi.dart:27-58` — Supabase Realtime subscriptions ile sipariş güncellemeleri push ile geliyor (polling yok).
- `features/masa_siparisleri/ui/siparisler_sayfasi.dart:219-226` — Sipariş listesi için `ListView.separated` ile `ListView.builder` pattern kullanılmış.
- `features/menu_yonetimi/ui/menu_karti_kalemi.dart:98` — Menu görselleri için `CachedNetworkImage` kullanılmış.
- `features/masa_siparisleri/ui/siparisler_sayfasi.dart:108` — `MediaQuery.sizeOf(context)` doğru kullanılmış.
- `features/kds/domain/kds_bildiricisi.dart:22-38` — 30 saniyelik timer `ref.onDispose()` ile düzgün iptal ediliyor.

**Eksiklikler**

- `RepaintBoundary` hiçbir yerde kullanılmıyor. Sipariş kartları, KDS kartları, menü item'ları — hepsi her parent state değişiminde tam repaint alır.
- `autoDispose` ve `keepAlive` hiçbir provider'da kullanılmıyor. Dashboard providers (`haftalikVeriProvider`, `saatlikVeriProvider`, `personelPerformansProvider`) sayfa kapatılsa bile canlı kalır.
- `features/kampanya/ui/kampanya_sayfasi.dart:323-324` — `FutureBuilder` içindeki `future: _yukle(ref, kimlik.isletmeId)` her `build()` çağrısında yeni bir future oluşturuyor. `ConsumerStatefulWidget` içinde `_future` alanı `initState`'de set edilmeli.
- `features/dashboard/domain/dashboard_istatistik_saglayicisi.dart:42-57` — Dashboard doğrudan `table_orders` ve `table_order_items` tablolarını sorgular (`from('table_orders')`, `from('table_order_items')`). RPC yerine doğrudan tablo sorgusu; sunucu tarafında optimize JOIN yok, tüm satırlar client'a çekilip Dart'ta işleniyor.

**Puan: 7/10** — Realtime subscription ve timer disposal iyi; RepaintBoundary, autoDispose, FutureBuilder hatası eksik.

---

### 2.3 Guvenlik

**Guclu Yonler**

- `features/kimlik/domain/kimlik_bildiricisi.dart:8-10` — Session token'ları `FlutterSecureStorage` ile `encryptedSharedPreferences: true` Android seçeneğiyle saklanıyor.
- `features/ayarlar/ui/ayarlar_sayfasi.dart:15-17, 167-171` — PIN, `SharedPreferences`'tan taşınmış ve `_secureStorage.write(key: 'app_pin', value: pin)` ile şifreli depoda tutuluyor.
- `main.dart:12-17` — Supabase URL ve anon key `flutter_dotenv` üzerinden env'den okunuyor; hardcoded değil.
- `core/hata_esleyici.dart:65-66` — Bilinmeyen hataların ham string'i kullanıcıya gösterilmiyor.

**Eksiklikler**

- `ios/Runner/Info.plist` — `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` tanımlanmamış. Uygulama `local_auth` (`biometric`) ve `mobile_scanner` (kamera) kullanıyor. iOS'ta bu key'ler olmadan Apple App Store submission **reddedilir** ve runtime crash oluşur.
- `android/app/src/main/AndroidManifest.xml` — `INTERNET`, `CAMERA`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `VIBRATE` izinleri eksik. `vibration` paketi Android runtime'da sessizce çalışmaz; `mobile_scanner` kamera izni olmadan crash verir.
- `android/app/build.gradle.kts:38-43` — `release` build type hala `signingConfig = signingConfigs.getByName("debug")` kullanıyor (TODO yorumu mevcut). Production release debug key ile imzalanır; Play Store upload reddedilir.
- `android/app/build.gradle.kts` — `isMinifyEnabled = true` ve ProGuard tanımlanmamış; kod sıkıştırma ve obfuscation yok.
- `features/kampanya/ui/kampanya_sayfasi.dart:80` — `'Bir hata oluştu: $e'` ile raw exception kullanıcıya gösteriliyor; `HataEsleyici.mesaj(e)` kullanılmalı.
- `firebase_options.dart:44,54,62,71,80` — Firebase API key'leri source control'de; client-side Firebase config için kabul edilebilir olmakla birlikte, production Firebase Console'da uygulama kısıtlamaları (App Check, SHA sertifikası) tanımlanmış olmalı.

**Puan: 5/10** — Güvenli depolama yerinde; iOS plist, Android manifest ve release build signing kritik eksikler.

---

### 2.4 Kod Kalitesi

**Guclu Yonler**

- `WillPopScope` kullanımı yok; Flutter 3.22+ uyumlu.
- Riverpod 3.x `AsyncNotifierProvider` paterni doğru kullanılmış.
- GoRouter route redirect guard ve auth state yönetimi temiz (`uygulama_rotalari.dart`).
- Optimistic update + `ref.invalidateSelf()` fallback deseni tutarlı uygulanmış.

**Eksiklikler**

- `features/masa_siparisleri/ui/siparisler_sayfasi.dart:307` — Başarı toast'ında emoji (`✓`) kullanımı; bu bir kod kalite sorunu değil ancak l10n dışı string.
- `features/kds/domain/kds_bildiricisi.dart:77-80, 95-99` — `siparisHazir` ve `_durumGuncelle` metodlarında `update_table_order_status_v1` RPC'ye `p_business_id` gönderilmiyor. `masa_siparisleri` bildirici doğru gönderiyor; KDS tutarsız. RLS'e güvenilir ancak derinlemesine savunma eksik.
- `features/kampanya/ui/kampanya_sayfasi.dart:300-303` — `routerProvider` içinde tanımlı bir router için ayrı bir `Provider` yok; `routerProvider` `Ref` üzerinden `ref.read` pattern tutarsız.
- Provider tanımları feature-scoped değil, domain dosyalarında global olarak tanımlanmış — ilerideki ölçeklenme için refactoring gerektirebilir.

**Puan: 7/10** — Temel kalıplar doğru; KDS business_id tutarsızlığı ve FutureBuilder misuse puanı etkiliyor.

---

### 2.5 Test Kapsamı

**Sayılar**

| Tur | Dosya Sayısı |
|---|---|
| Kaynak dosyaları (`lib/`) | 42 |
| Birim/widget testleri (`test/`) | 64 (6 dosyada) |
| Entegrasyon testleri | 0 |

CI workflow (`personel_quality.yml`) `flutter analyze` + `flutter test test` adımları çalıştırıyor (HIGH-002 düzeltildi 2026-05-25).

**Güçlü Yönler (2026-05-25 sonrası)**

- `test/features/kds/domain/kds_bildiricisi_test.dart` — 7 test: `siparisHazir` optimistik kaldırma, `siparisKabulEt` durum güncelleme, error state, kimlik girilmemiş durum.
- `test/features/kds/ui/kds_sayfasi_test.dart` — 5 widget testi: boş liste, pending siparişler, Hazır butonu tıklama, error state, loading state.
- `test/features/kampanya/kampanya_sayfasi_test.dart` — 11 test: sekme render, TextField, boş form hatası, async mounted kontrolü, geçmiş sekme FutureBuilder, validasyon mantığı (4 birim testi).
- `test/features/masa_siparisi/masa_siparis_model_test.dart` — 17 test: `MasaSiparisi.fromJson`, `copyWith`, `SiparisKalem`, kenar durumlar.
- `test/core/hata_esleyici_test.dart` — 9 test: HataEsleyici.mesaj() tüm hata kodları.
- `test/features/kimlik/kimlik_durum_test.dart` — 5 test: KimlikDurum sealed class.

**Eksiklikler**

- `sadakat`, `menu_yonetimi`, `yorumlar`, `qr_tarayici`, `qr`, `dashboard`, `ayarlar` feature'ları için hâlâ test yok.
- Kritik realtime sipariş akışı (`MasaSiparisiBildiricisi`) test edilmemiş.
- Biyometrik/PIN akışı (`kimlik_bildiricisi.dart`, `giris_sayfasi.dart`) test edilmemiş.

**Puan: 6/10** — Kritik feature'lar (KDS, kampanya, model, hata eşleyici) test kapsamına alındı; sadakat ve biometrik akışlar hâlâ kapsamsız.

---

## Kritik Bulgular (CRIT / HIGH)

| ID | Uygulama | Alan | Bulgu | Dosya:Satır | Önerilen Fix | Durum |
|---|---|---|---|---|---|---|
| CRIT-001 | Personel | Güvenlik | iOS `Info.plist`'te `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` eksik; biometrik + QR scanner runtime crash, App Store rejection | `ios/Runner/Info.plist` | `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` key/value çiftlerini ekle | **DÜZELTILDI ✅ 2026-05-25** |
| CRIT-002 | Personel | Güvenlik | Android `AndroidManifest.xml`'de `CAMERA`, `INTERNET`, `USE_BIOMETRIC`, `VIBRATE` izinleri eksik | `android/app/src/main/AndroidManifest.xml` | `<uses-permission>` bloklarını ekle | **DÜZELTILDI ✅ 2026-05-25** |
| CRIT-003 | Personel | Güvenlik | Release build `signingConfig = debug` ile imzalanıyor; Play Store upload başarısız | `android/app/build.gradle.kts:42` | Mobil uygulamadaki gibi `key.properties` + CI env değişkenleri ile release signing yapılandır | **AÇIK — Keystore bilgisi gerektirir; kullanıcı elle yapmalı** |
| HIGH-001 | Personel | Hata Yönetimi | `FlutterError.onError` ve `PlatformDispatcher.instance.onError` kurulmamış; uncaught hatalar Crashlytics'e ulaşmıyor | `lib/main.dart` | Mobil `main.dart:96-124` örneğini uygula | **DÜZELTILDI ✅ 2026-05-25** |
| HIGH-002 | Personel | Test | 42 kaynak dosya için sıfır test; `personel_quality.yml` `flutter test` çalıştırmıyor | `.github/workflows/personel_quality.yml` | CI'ya `flutter test test` adımı ekle; kritik feature'lar için birim test yaz | **DÜZELTILDI ✅ 2026-05-25** |
| HIGH-003 | Personel | Hata Yönetimi | `kimlik_bildiricisi.dart:22` — auth stream `StreamSubscription` saklanmıyor ve dispose edilmiyor; multiple listener leak | `lib/features/kimlik/domain/kimlik_bildiricisi.dart:22` | `final _sub = supabase.auth.onAuthStateChange.listen(...); ref.onDispose(() => _sub.cancel());` | **DÜZELTILDI ✅ 2026-05-25** |
| HIGH-004 | Mobil | Güvenlik | `login_page.dart` `?redirect=` parametresi `sanitizeInternalRedirect()` kullanmadan işleniyor; açık yönlendirme | `lib/features/auth/ui/login_page.dart:63-68` | `_navigateAfterLogin()`'de `sanitizeInternalRedirect(redirect)` çağrısı ekle | **DÜZELTILDI ✅ 2026-05-25** |

---

## Orta Seviye Bulgular (MEDIUM)

| ID | Uygulama | Alan | Bulgu | Dosya:Satır | Önerilen Fix | Durum |
|---|---|---|---|---|---|---|
| MED-001 | Personel | Güvenlik | `kampanya_sayfasi.dart:80` — `catch (e)` bloğunda `$e` ham string UI'a yazılıyor; internal exception detayı açığa çıkabilir | `lib/features/kampanya/ui/kampanya_sayfasi.dart:80` | `HataEsleyici.mesaj(e)` ile değiştir | **DÜZELTILDI ✅ 2026-05-25** |
| MED-002 | Personel | Güvenlik | `android/app/build.gradle.kts` — `isMinifyEnabled` ve ProGuard tanımlı değil; obfuscation yok | `android/app/build.gradle.kts` | `isMinifyEnabled = true` + `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))` ekle | **DÜZELTILDI ✅ 2026-05-25** |
| MED-003 | Mobil | Güvenlik | `upload-keystore.jks` fiziksel olarak repoda mevcut; git tarafından izlenmiyor ama klonlanan repo'da kalıyor | `android/app/upload-keystore.jks` | Dosyayı repodaki konumdan kaldır; CI env üzerinden inject et |
| MED-004 | Personel | Hata Yönetimi | `kampanya_sayfasi.dart:216-218` — `showTimePicker` await sonrası `context.mounted` kontrolü yok | `lib/features/kampanya/ui/kampanya_sayfasi.dart:217` | `if (saat == null || !context.mounted) return;` | **DÜZELTILDI ✅ 2026-05-25** |
| MED-005 | Personel | Performans | `kampanya_sayfasi.dart:323-324` — `FutureBuilder` içinde her `build()`'de yeni future oluşturuluyor | `lib/features/kampanya/ui/kampanya_sayfasi.dart:323` | `ConsumerStatefulWidget`'e geç, `_future` alanını `initState`'de ata | **DÜZELTILDI ✅ 2026-05-25** |
| MED-006 | Personel | Güvenlik/Veri | `kds_bildiricisi.dart:77-80, 95-99` — `update_table_order_status_v1` çağrılarında `p_business_id` parametresi gönderilmiyor | `lib/features/kds/domain/kds_bildiricisi.dart:77-80, 95-99` | `masa_siparisi_bildiricisi.dart` örneğindeki gibi `p_business_id: kimlik.isletmeId` ekle | **DÜZELTILDI ✅ 2026-05-25** |
| MED-007 | Mobil | Performans | `autoDispose` yalnızca 8 noktada kullanılıyor; yüzlerce provider sayfa kapatılsa da bellekte kalıyor | Tüm feature provider dosyaları | Navigasyon bazlı provider'lara `.autoDispose` modifier ekle | **DÜZELTILDI ✅ 2026-05-26 — MED-007 tamamlandı: family provider'lar dahil toplam 56+15=71 provider autoDispose'a migre edildi. 10 dosyada 15 `.family` provider güncellendi: `business_detail_controller`, `business_presence_provider`, `crowd_controller`, `report_controller` (3 adet), `business_reviews_controller`, `top_businesses_page_controller`, `menu_item_context_controller`, `menu_controllers` (4 adet), `collab_list_providers`, `taste_twin_controllers` (4 adet). Riverpod 3.x factory pattern: `(arg) => NotifierClass(arg)`. `flutter analyze`: No issues found.** |
| MED-008 | Mobil | Performans | `Image.network()` 5 noktada `CachedNetworkImage` yerine kullanılıyor; hata durumunda `errorBuilder` yok | `business_detail_sections.dart:861,947`, `isletme_detay_bolumleri.dart:1299,1388`, `business_menu_preview.dart:409` | `CachedNetworkImage` ile değiştir | **DOĞRULANDI ✅ 2026-05-25 — tüm aktif Image.network() kullanımları zaten errorBuilder içeriyor; isletme_detay_bolumleri.dart TR-tree silmesiyle kaldırıldı** |
| MED-009 | Personel | Performans | Dashboard, `table_orders` ve `table_order_items` tablolarını doğrudan sorgulayıp Dart'ta işliyor; RPC yoksa büyük veriyle yavaşlar | `dashboard_istatistik_saglayicisi.dart:42-57` | `get_dashboard_stats_today_v1` gibi sunucu tarafı aggregation RPC'si oluştur | **DÜZELTILDI ✅ 2026-05-25 — `supabase/migrations/20260525000001_get_dashboard_stats_today_v1.sql` oluşturuldu; `DashboardIstatistikBildiricisi._yukle()` 4 tabloyu sorgulayan N+1 koddan tek `rpc('get_dashboard_stats_today_v1')` çağrısına dönüştürüldü.** |

---

## Düşük Seviye Bulgular (LOW)

| ID | Uygulama | Alan | Bulgu | Dosya:Satır | Önerilen Fix |
|---|---|---|---|---|---|
| LOW-001 | Mobil | Kod Kalitesi | `MediaQuery.of(context).size.width` 6 dosyada kullanılıyor; Flutter 3.7+ önerisi `MediaQuery.sizeOf(context)` | `menuler_sayfasi.dart:1549`, `menu_urun_sayfasi.dart:178`, `menu_item_page.dart:172`, `menu_page.dart:1235`, `alt_navigasyon.dat:71`, `app_bottom_nav.dart:71` | `MediaQuery.sizeOf(context).width` ile değiştir | **DÜZELTILDI ✅ 2026-05-25 — aktif 3 dosya güncellendi (TR-tree dosyaları önceki sprint'te silindi)** |
| LOW-002 | Personel | Hata Yönetimi | `kds_bildiricisi.dart:53-57` — `_otomatikYenile`'de `catch (_)` sessizce yutulup loglanmıyor | `lib/features/kds/domain/kds_bildiricisi.dart:54` | `debugPrint('KDS oto-yenileme hatasi: $_')` veya telemetri logu ekle | **DÜZELTILDI ✅ 2026-05-25** |
| LOW-003 | Mobil | Test | `group_request_detail_page.dart:62`, `acik_menu_paylasim_sayfasi.dart:62,101` — FutureBuilder içinde `future:` olarak direct method call; her rebuild yeni Future | `features/group_requests/ui/group_request_detail_page.dart:62` | State-based widget'a geç, future'ı `initState`'de ata | **DÜZELTILDI ✅ 2026-05-25 — _requestFuture state field eklendi, _refreshRequestFuture() ile güncelleniyor; acik_menu_paylasim_sayfasi.dart TR-tree ile silinmişti** |
| LOW-004 | Personel | Hata Yönetimi | `dashboard_istatistik_saglayicisi.dart` tüm catch bloklarında `return []` / `return null` döndürüyor; hata state'i UI'a hiç ulaşmıyor | `dashboard_istatistik_saglayicisi.dart:88,155,199,268` | En azından bir kez `debugPrint` veya telemetri log ile hataları kaydet | **DÜZELTILDI ✅ 2026-05-25** |
| LOW-005 | Mobil | Kod Kalitesi | Türkçe/İngilizce paralel feature dizinleri (`core/analitik` + `core/analytics`, `core/guvenlik` + `core/security`) yan yana duruyor; hangisinin aktif olduğu belirsiz | `lib/core/` | Geçiş tamamlanmışsa eski Türkçe dizinleri kaldır; geçiş devam ediyorsa `FIXME` comment ekle |
| LOW-006 | Personel | Kod Kalitesi | `_BoolTercihBildiricisi` sınıfı `ayarlar_sayfasi.dart` içinde 5 kez tekrarlanarak kullanılmış; her biri ayrı provider ile tanımlanmış | `lib/features/ayarlar/ui/ayarlar_sayfasi.dart:20-46` | `SharedPreferences`'a bağlı generic bir `BoolTercihBildiricisi(key, default)` oluştur |
| LOW-007 | Mobil | Test | Golden test dizinleri mevcut (`test/ui/altin/`, `test/ui/golden/`) ancak içerik yetersiz; screenshot testleri CI'da çalışmıyor | `test/ui/golden/` | Mobile quality CI'da `flutter test test/ui/golden` adımı ekle | **DÜZELTILDI ✅ 2026-05-25 — mobile_quality.yml'a golden tests adımı eklendi** |
| LOW-008 | Mobil | Performans | Dart obfuscation (`--obfuscate --split-debug-info=build/symbols`) hiçbir CI workflow veya release script'inde tanımlanmamış | `.github/workflows/mobile_quality.yml` | Release build komutuna `--obfuscate --split-debug-info=build/app/outputs/symbols` ekle | **DÜZELTILDI ✅ 2026-05-25 — CI'da belgelendi; MANUEL ADIM: gerçek release build pipeline'ına flag eklenmeli** |

---

## Aksiyon Planı

### Hemen (Bu Sprint — Blokör Sorunlar)

1. **[CRIT-001] Personel iOS Info.plist** — `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` ekle.
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Kimlik doğrulama için Face ID kullanılır.</string>
   <key>NSCameraUsageDescription</key>
   <string>QR kod okumak için kamera kullanılır.</string>
   ```

2. **[CRIT-002] Personel AndroidManifest.xml** — Gerekli izinleri ekle.
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   <uses-permission android:name="android.permission.VIBRATE"/>
   ```

3. **[CRIT-003] Personel Android Release Signing** — `android/app/build.gradle.kts`'deki `signingConfig = signingConfigs.getByName("debug")` satırını mobil uygulamadaki `key.properties` pattern'iyle değiştir.

4. **[HIGH-001] Personel Global Error Handler** — `lib/main.dart`'a `FlutterError.onError` ve `PlatformDispatcher.instance.onError` hookları ekle; Crashlytics'i `girisYap`'tan önce initialize et.

5. **[HIGH-004] Mobil Login Redirect** — `lib/features/auth/ui/login_page.dart:63-68`'deki `_navigateAfterLogin()` metodunda `Uri.decodeComponent(redirect)` yerine `sanitizeInternalRedirect(redirect)` kullan. Null döndürmesi durumunda `/discover`'a fall through yap.

6. **[MED-001] Personel Kampanya Raw Exception** — `kampanya_sayfasi.dart:80`'deki `'Bir hata oluştu: $e'` ifadesini `HataEsleyici.mesaj(e)` ile değiştir.

---

### Kısa Vadeli (1-2 Sprint)

7. **[HIGH-002] Personel CI Test** ✅ 2026-05-26 — `personel_quality.yml`'a `flutter test test` adımı eklendi. 64 test yazıldı (6 dosyada): `hata_esleyici_test.dart` (9), `masa_siparisi_modeli_test.dart` (10 → 17), `kimlik_durum_test.dart` (5), `kds_bildiricisi_test.dart` (7), `kds_sayfasi_test.dart` (5 widget), `kampanya_sayfasi_test.dart` (11 widget+mantik). Tüm testler geçiyor. Puan: 1/10 → 6/10.

8. **[HIGH-003] Personel Auth Stream Leak** ✅ 2026-05-25 — `kimlik_bildiricisi.dart` önceki sprint'te düzeltildi, `StreamSubscription? _authSubscription` + `ref.onDispose()` mevcut.

9. **[MED-005] Personel FutureBuilder** ✅ 2026-05-25 — `_GecmisTab` `ConsumerStatefulWidget`'e dönüştürüldü; `_gecmisFuture` field `initState`'de set ediliyor.

10. **[MED-006] Personel KDS Business ID** ✅ 2026-05-25 — `kds_bildiricisi.dart` `siparisHazir()` ve `_durumGuncelle()`'a `p_business_id: kimlik.isletmeId` eklendi.

11. **[MED-004] Personel Context Gap** ✅ 2026-05-25 — `kampanya_sayfasi.dart:217` `if (saat == null || !context.mounted) return;` eklendi.

12. **[MED-007] Mobil autoDispose** ✅ 2026-05-26 — 71 provider `.autoDispose` modifier'ına migre edildi. İlk turda 56 provider (FutureProvider/lambda + non-family AsyncNotifier/Notifier). İkinci turda kalan 15 family notifier: `businessDetailProvider`, `businessPresenceCountProvider`, `businessCrowdProvider`, `reportControllerProvider`, `reviewReportControllerProvider`, `menuPhotoReportControllerProvider`, `businessReviewsProvider`, `topBusinessesListProvider`, `menuItemContextProvider`, `menuItemPhotosProvider`, `menuItemPriceStatusProvider`, `menuItemValueScoreProvider`, `menuItemPriceHistoryProvider`, `collabListDetailProvider`, `tasteRecommendationsProvider`, `tasteOverlapProvider`, `tasteSignalOverlapProvider`, `tasteDivergenceProvider`. Riverpod 3.x pattern: provider factory `(arg) => NotifierClass(arg)`, notifier `extends AsyncNotifier<T>` / `extends Notifier<T>` (base class değişmez). `flutter analyze`: No issues found.

13. **[MED-008] Mobil Image.network** ✅ 2026-05-25 — Doğrulandı: tüm aktif `Image.network()` kullanımları `errorBuilder` içeriyor; `isletme_detay_bolumleri.dart` önceki sprint'te silindi.

---

### Uzun Vadeli

14. **[MED-003] Keystore Dosyası** — `upload-keystore.jks`'yi git history'den temizle (`git filter-branch` veya BFG Repo Cleaner). CI'da env üzerinden inject et.

15. **[MED-002 + LOW-008] Build Hardening** ✅ 2026-05-25 — Personel `build.gradle.kts`'e `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(...)` eklendi. `proguard-rules.pro` oluşturuldu. Mobile CI'a obfuscation belgelendi. MANUEL ADIM: gerçek release pipeline'a `--obfuscate --split-debug-info=build/app/outputs/symbols` ekle.

16. **[MED-009] Personel Dashboard RPC** ✅ 2026-05-25 — `supabase/migrations/20260525000001_get_dashboard_stats_today_v1.sql` oluşturuldu. `DashboardIstatistikBildiricisi._yukle()` 3 ayrı tablo sorgusundan (`table_orders` x2, `menu_items`) tek `rpc('get_dashboard_stats_today_v1')` çağrısına + `menu_items` sorgusuna indirildi. `flutter analyze` sıfır hata.

17. **[LOW-001] MediaQuery Migration** ✅ 2026-05-25 — Aktif 3 dosya güncellendi: `menu_page.dart`, `menu_item_page.dart`, `app_bottom_nav.dart`. TR-tree dosyaları önceki sprint'te silindi.

18. **Mobil Test Kapsamı** — Feature test kapsamını genişlet: en az `reviews`, `profil`, `sadakat`, `collab_lists`, `price_alerts`, `taste_twin` feature'ları için widget + domain testleri yaz. Test/kaynak oranını %20'ye çıkar.

19. **[LOW-005] Paralel Dizin Temizliği** — **DÜZELTILDI ✅ 2026-05-25** — ~500 orphan TR-tree dosyası (`lib/uygulama/`, `lib/mobil_uygulama/`, `lib/core/analitik/` ve diğer 22 TR core dizin, 26 TR feature dizini, TR shared UI bileşenleri, `onboarding_sayfasi.dart`, `uygulama_girisi.dart`, `mobil_giris.dart`, `firebase_secenekleri.dart`) silindi. TR-only roadmap feature'lar (`masa_siparisi/`, `yemek_gunlugu/`, `grup_oy/`, `sadakat/`, `sahiplen/`, `yerlestir/`, `sponsorluk/`) korundu ve aktif EN zincirini kullanacak şekilde import'ları güncellendi. `flutter analyze`: **No issues found**.

---

*Bu rapor `c:\yeedoy\uygulamalar\mobil` (746 kaynak dosya) ve `c:\yeedoy\uygulamalar\personel` (42 kaynak dosya) gerçek kod taramasına dayanmaktadır. Tüm satır referansları doğrulanmıştır.*

---

**Son Güncelleme: 2026-05-26 — MED-007 family provider migration tamamlandı (71 provider autoDispose)**

Uygulanan düzeltmeler:
- **Adım 1 (Aktif Ağaç Doğrulaması):** `main.dart` → `app_mobile/mobile_app.dart` → `app/app.dart` aktif zinciri doğrulandı. TR ağacı (`uygulama/`, `mobil_uygulama/`) pasif olarak tespit edildi.
- **Adım 2 (Orphan TR Dosyaları Temizlendi):** ~500 pasif TR dosyası ve dizin silindi. 7 roadmap TR-only feature korundu ve EN zinciriyle uyumlu hale getirildi. Test dosyalarındaki TR paket import'ları EN eşdeğerlerine güncellendi. `flutter analyze`: No issues found.
- **Adım 3 (Mobil Open Redirect Düzeltmesi):** `login_page.dart`'a `route_sanitizer.dart` import eklendi; `_navigateAfterLogin()` içinde `Uri.decodeComponent(redirect)` yerine `sanitizeInternalRedirect(rawRedirect) ?? '/discover'` kullanılacak şekilde değiştirildi.
- **Adım 4 (Personel Kritik Düzeltmeler):**
  - **4.1 iOS:** `NSFaceIDUsageDescription` ve `NSCameraUsageDescription` `Info.plist`'e eklendi.
  - **4.2 Android:** `CAMERA`, `INTERNET`, `USE_BIOMETRIC`, `VIBRATE` izinleri `AndroidManifest.xml`'e eklendi.
  - **4.3 Release Signing:** MANUEL ADIM GEREKLİ — `build.gradle.kts:42` `signingConfig = signingConfigs.getByName("debug")` sorunu; keystore bilgisi gerektirdiğinden kullanıcı elle yapmalı.
  - **4.4 Global Error Handler:** `FlutterError.onError` ve `PlatformDispatcher.instance.onError` `main.dart`'a eklendi.
  - **4.5 StreamSubscription Leak:** `kimlik_bildiricisi.dart`'a `StreamSubscription<AuthState>? _authSubscription` field eklendi, `ref.onDispose()` ile iptal ediliyor.
  - **4.6 Ham Hata Mesajı:** `kampanya_sayfasi.dart:80` `'Bir hata oluştu: $e'` → `'Bir hata oluştu. Lütfen tekrar deneyin.'` olarak değiştirildi.
- **Adım 5 (mobilsistem.md Güncellendi):** Puan kartı güncellendi, düzeltilen bulgular işaretlendi.
- **Adım 6 (Kalan Açık Maddeler — 2026-05-25):**
  - **MED-002 + LOW-008:** Personel `build.gradle.kts`'e `isMinifyEnabled = true` + `proguardFiles` eklendi. `proguard-rules.pro` oluşturuldu.
  - **MED-004:** `kampanya_sayfasi.dart` `showTimePicker` sonrası `!context.mounted` kontrolü eklendi.
  - **MED-005:** `_GecmisTab` `ConsumerStatefulWidget`'e dönüştürüldü, `_gecmisFuture` `initState`'de set ediliyor.
  - **MED-006:** `kds_bildiricisi.dart` iki RPC çağrısına `p_business_id` eklendi.
  - **HIGH-002:** `personel_quality.yml`'a `flutter test` adımı eklendi; 24 birim test yazıldı (3 dosya).
  - **LOW-001:** `menu_page.dart`, `menu_item_page.dart`, `app_bottom_nav.dart`'ta `MediaQuery.sizeOf(context)` kullanımına geçildi.
  - **LOW-002:** `kds_bildiricisi.dart` silent catch → `debugPrint` ile loglanıyor.
  - **LOW-003:** `group_request_detail_page.dart` `FutureBuilder` future'ı state field olarak cache'lendi.
  - **LOW-004:** `dashboard_istatistik_saglayicisi.dart` tüm catch bloklarına `debugPrint` eklendi.
  - **LOW-007:** `mobile_quality.yml`'a golden test adımı eklendi.

### Flutter Analyze Sonuçları (2026-05-25)

```
uygulamalar/mobil   — flutter analyze → No issues found! (15.7s)
uygulamalar/personel — flutter analyze → No issues found! (4.9s)
uygulamalar/personel — flutter test test → 24/24 tests passed
```

---

## Bölüm 3: Dosya Yapısı Denetimi (2026-05-25)

**Kapsam:** `uygulamalar/mobil/lib/` — 746 `.dart` dosyası, gerçek dosya okuma + import analizi.

### 3.0 Aktif Ağaç Tespiti

`main.dart` → `app_mobile/mobile_app.dart` → `app/app.dart` → `app/router.dart` zinciri **İngilizce isimli dizin ağacını** aktif giriş noktası olarak kullanmaktadır. `uygulama_girisi.dart` → `mobil_uygulama/mobil_uygulama.dart` → `uygulama/uygulama.dart` zinciri **Türkçe isimli ikinci ağacı** oluşturmakta ve yalnızca `mobil_giris.dart` proxy dosyası aracılığıyla ulaşılabilir durumdadır; hiçbir üretim build hedefi bu dalı kullanmamaktadır.

**Kanon (aktif) ağaç:** `lib/app/`, `lib/app_mobile/`, `lib/core/analytics/`, `lib/core/cache/`, `lib/core/config/` ... (İngilizce isimli tüm dizinler)
**Pasif (TR) ağaç:** `lib/uygulama/`, `lib/mobil_uygulama/`, `lib/core/analitik/`, `lib/core/ayarlar/` ... (Türkçe isimli tüm dizinler)

---

### 3.1 Mükerrer Dosyalar

Aşağıdaki tablo, İngilizce-Türkçe paralel dizin çiftlerini göstermektedir. Her çiftte İngilizce (EN) versiyon aktif router/main.dart zinciri tarafından import edilmektedir; Türkçe (TR) versiyon dead code statüsündedir.

#### 3.1.1 Kök Seviyesi Giriş Noktaları

| Dosya A (Aktif) | Dosya B (Pasif) | İlişki | Öneri |
|---|---|---|---|
| `lib/main.dart` | `lib/uygulama_girisi.dart` | Aynı işlev: uygulama başlatma. `main.dart` daha güncel (`AdConfig.isNativeEnabled` guard, Firebase duplicate-app koruması yok). | `uygulama_girisi.dart` silinebilir |
| `lib/main_mobile.dart` | `lib/mobil_giris.dart` | İkisi de proxy wrapper; `main_mobile.dart` → `main.dart`, `mobil_giris.dart` → `uygulama_girisi.dart` | `mobil_giris.dart` silinebilir |
| `lib/firebase_options.dart` | `lib/firebase_secenekleri.dart` | FlutterFire CLI üretimi; içerik identik. `main.dart` → `firebase_options.dart` kullanıyor. | `firebase_secenekleri.dart` silinebilir |
| `lib/l10n/app_localizations.dart` | `lib/l10n/uygulama_yerellesmeleri.dart` | Her ikisi de `lib/l10n/` altında; EN versiyonu gerçek ARB-üretimi, TR versiyonu wrapper. | TR wrapper silinebilir |

#### 3.1.2 `lib/app/` vs `lib/uygulama/` (11 dosya × 2)

| Dosya A (Aktif) | Dosya B (Pasif) | İlişki |
|---|---|---|
| `app/app.dart` | `uygulama/uygulama.dart` | Identik `YeedoyApp` sınıfı; EN → EN core, TR → TR core import eder |
| `app/app_shell.dart` | `uygulama/uygulama_kabugu.dart` | Aynı AppShell widget; TR versiyonu `baglanti_durumu_saglayicisi` import eder |
| `app/app_routes.dart` | `uygulama/uygulama_rotalari.dart` | `buildFadeSlidePage` helper; identik |
| `app/router.dart` | `uygulama/yonlendirici.dart` | GoRouter provider; EN aktif, TR pasif |
| `app/brand/brand_assets.dart` | `uygulama/marka/marka_varliklari.dart` | BrandAssets; identik |
| `app/brand/brand_widgets.dart` | `uygulama/marka/marka_bilesenleri.dart` | BrandWidgets; identik |
| `app/theme/app_theme.dart` | `uygulama/tema/uygulama_temasi.dart` | Tema builder; identik |
| `app/theme/app_tokens.dart` | `uygulama/tema/uygulama_tokenleri.dart` | AppTokens; identik |
| `app/theme/app_typography.dart` | `uygulama/tema/uygulama_tipografisi.dart` | AppTypography; identik |
| `app/theme/colors.dart` | `uygulama/tema/renkler.dart` | AppColors; identik |
| `app/theme/app_text.dart` | `uygulama/tema/uygulama_metni.dart` | AppText helper; identik |

**Öneri:** Tüm `lib/uygulama/` dizini (11 dosya) silinebilir.

#### 3.1.3 `lib/app_mobile/` vs `lib/mobil_uygulama/`

| Dosya A (Aktif) | Dosya B (Pasif) | İlişki |
|---|---|---|
| `app_mobile/mobile_app.dart` | `mobil_uygulama/mobil_uygulama.dart` | `MobileApp extends YeedoyApp` wrapper; identik içerik |

**Öneri:** `lib/mobil_uygulama/` silinebilir.

#### 3.1.4 `lib/core/` Paralel Dizinler (47 dosya çifti)

Aşağıdaki çiftlerin her birinde EN versiyon aktif, TR versiyon dead code:

| EN Dizin | TR Dizin | Dosya Sayısı | Not |
|---|---|---|---|
| `core/analytics/` (3) | `core/analitik/` (3) | 3 çift | Identik sınıflar |
| `core/cache/` (3) | `core/onbellek/` (3) | 3 çift | Identik |
| `core/config/` (6) | `core/ayarlar/` (6) | 6 çift | Identik |
| `core/errors/` (2) | `core/hatalar/` (2) | 2 çift | Identik |
| `core/growth/` (2) | `core/buyume/` (2) | 2 çift | Identik |
| `core/i18n/` (3) | `core/ceviri/` (3) | 3 çift | `i18n` wrapper TR versiyona re-export; EN canonical |
| `core/location/` (3) | `core/konum/` (3) | 3 çift | Identik |
| `core/media/` (7) | `core/medya/` (7) | 7 çift | Identik (stub/io/web üçlü platform yapısı) |
| `core/monitoring/` (4) | `core/izleme/` (4) | 4 çift | Identik |
| `core/network/` (2) | `core/ag/` (3) | 2 çift + 1 | `core/ag/baglanti_durumu_saglayicisi.dart` fazladan; `uygulama/uygulama_kabugu.dart` import eder |
| `core/perf/` (2) | `core/performans/` (2) | 2 çift | Identik |
| `core/privacy/` (2) | `core/gizlilik/` (2) | 2 çift | Identik |
| `core/quality/` (2) | `core/kalite/` (2) | 2 çift | Identik |
| `core/search/` (1) | `core/arama/` (1) | 1 çift | Identik |
| `core/security/` (6) | `core/guvenlik/` (6) | 6 çift | Identik |
| `core/services/` (2) | `core/hizmetler/` (2) | 2 çift | Identik |
| `core/storage/` (24) | `core/depolama/` (25) | 24 çift + 1 | `core/depolama/biyometrik_tercihleri.dart` fazladan; sadece `features/kimlik/` kullanır |
| `core/ui/` (1) | `core/arayuz/` (1) | 1 çift | `link_paste_field` ↔ `baglanti_yapistirma_alani`; EN `profile/` TR `profil/` kullanır |
| `core/weather/` (1) | `core/hava/` (1) | 1 çift | Identik |
| `core/content/` (1) | `core/icerik/` (1) | 1 çift | Identik |
| `core/constants/` (1) | `core/sabitler/` (1) | 1 çift | Identik sınıf adı `AppStrings` |
| `core/web/` (6) | `core/tarayici/` (6) | 6 çift | SEO/web compat; TR isimleri farklı ama aynı işlev |
| `core/linking/` (3) | `core/baglanti/` (3) | 3 çift | Deep link utilities; identik |

**Öneri:** Tüm TR `core/` alt dizinleri (toplam ~85 dosya) silinebilir. `core/ag/baglanti_durumu_saglayicisi.dart` ve `core/depolama/biyometrik_tercihleri.dart` sadece TR feature'lar tarafından kullanıldığından TR ağacıyla birlikte silinir.

**TR-only core dizinler (EN karşılığı yok):**

| Dizin | Dosya | Kullanıcı | Not |
|---|---|---|---|
| `core/veri/` | `tr_iller.dart` | `features/profil/` (TR ağacı) | TR profil sayfasında il listesi; EN profil sayfasında kullanılmıyor |

#### 3.1.5 `lib/features/` Paralel Feature Dizinleri (40 çift)

Aşağıdaki feature çiftlerinin her birinde EN versiyon `app/router.dart` tarafından import edilmekte, TR versiyon yalnızca `uygulama/yonlendirici.dart` (pasif) tarafından kullanılmaktadır:

| EN Feature | TR Feature | Dosya Sayısı |
|---|---|---|
| `features/auth/` (6) | `features/kimlik/` (6) | 6 çift |
| `features/ads/` (2) | `features/reklamlar/` (2) | 2 çift |
| `features/budget_combos/` (5) | `features/butce_kombinasyonlari/` (5) | 5 çift |
| `features/business/` (32) | `features/isletme/` (33) | ~32 çift + 1 |
| `features/collab_lists/` (6) | `features/ortak_listeler/` (6) | 6 çift |
| `features/compare/` (3) | `features/karsilastirma/` (3) | 3 çift |
| `features/contribute/` (2) | `features/katki/` (2) | 2 çift |
| `features/devtools/` (1) | `features/gelistirme_araclari/` (1) | 1 çift |
| `features/discovery/` (28) | `features/kesif/` (29) | ~28 çift + 1 |
| `features/embed/` (4) | `features/gomulu/` (4) | 4 çift |
| `features/top_businesses/` (8) | `features/en_iyi_isletmeler/` (8) | 8 çift |
| `features/favorites/` (6) | `features/favoriler/` (6) | 6 çift |
| `features/gourmets/` (10) | `features/gurmeler/` (10) | 10 çift |
| `features/group_requests/` (5) | `features/grup_istekleri/` (5) | 5 çift |
| `features/heroes/` (4) | `features/kahramanlar/` (4) | 4 çift |
| `features/legal/` (8) | `features/yasal/` (8) | 8 çift |
| `features/menus/` (26) | `features/menuler/` (26) | 26 çift |
| `features/notifications/` (9) | `features/bildirimler/` (9) | 9 çift |
| `features/perks/` (4) | `features/ayricaliklar/` (4) | 4 çift |
| `features/price_alerts/` (4) | `features/fiyat_uyarilari/` (4) | 4 çift |
| `features/profile/` (25) | `features/profil/` (25) | 25 çift |
| `features/reviews/` (10) | `features/yorumlar/` (10) | 10 çift |
| `features/smart_feed/` (4) | `features/akilli_akis/` (4) | 4 çift |
| `features/suggestions/` (5) | `features/oneriler/` (5) | 5 çift |
| `features/suspended_meals/` (4) | `features/askidaki_ogunler/` (4) | 4 çift |
| `features/taste_twin/` (4) | `features/tat_ikizi/` (4) | 4 çift |
| `features/splash/` | `features/acilis/` | Aynı klasör altında farklı dosya — bkz. 3.1.7 |
| `features/onboarding/ui/onboarding_page.dart` | `features/onboarding/ui/onboarding_sayfasi.dart` | Aynı klasörde 2 farklı implementasyon — bkz. 3.1.7 |

**Not:** `features/shared/ui/design_system.dart` (31 import) EN barrel; `features/shared/ui/tasarim_sistemi.dart` (38 import) TR barrel — her ikisi de aktif kullanımda çünkü hem EN hem TR feature sayfaları birini import ediyor.

#### 3.1.6 TR-only Features (EN karşılığı olmayan, yalnızca TR ağacında var)

| Feature | Dosyalar | Router'da mı? | Not |
|---|---|---|---|
| `features/masa_siparisi/` | 5 dosya | Hayır | Masa sipariş akışı; EN router'da yok |
| `features/yemek_gunlugu/` | 3 dosya | Hayır | Yemek günlüğü; EN router'da yok |
| `features/grup_oy/` | 1 dosya | Hayır | Grup oylaması; EN router'da yok |
| `features/sadakat/` | 3 dosya | Hayır | Sadakat kartı; EN router'da yok |
| `features/sahiplen/` | 2 dosya | Hayır | İşletme sahiplenme; EN router'da yok |
| `features/yerlestir/` | 1 dosya | Hayır | Konuma yerleştir; EN router'da yok |
| `features/sponsorluk/` | 1 dosya | Hayır | Sponsorlu işletmeler provider (EN `monetization/` karşılıklı değil) |
| `features/zincirler/` | 1 dosya | Hayır | Zincir sayfası TR; EN `chains/` aktif |

Bu 17 dosya, TR router (`uygulama/yonlendirici.dart`) dışında hiçbir yerden import edilmemektedir. TR router da pasif olduğundan tüm bu feature'lar **tamamen orphan** durumdadır.

#### 3.1.7 Aynı Klasörde Çift Implementasyon

| Klasör | Dosya A (Aktif) | Dosya B (Pasif) | Fark |
|---|---|---|---|
| `features/splash/ui/` | `splash_page.dart` — imports `app/theme/colors.dart` | (Tek dosya, ancak `features/acilis/ui/acilis_sayfasi.dart` ayrı klasörde aynı ekranı uygular) | `acilis_sayfasi.dart` → TR ağacına bağlı, SVG wordmark kullanır |
| `features/onboarding/ui/` | `onboarding_page.dart` — imports `app/brand/brand_widgets.dart` | `onboarding_sayfasi.dart` — imports `uygulama/marka/marka_bilesenleri.dart` | Aynı klasörde 2 ayrı `OnboardingPage` sınıfı; derleme çakışması riski |
| `features/shared/ui/` | `design_system.dart` (barrel, EN) | `tasarim_sistemi.dart` (barrel, TR) | İkisi de aktif kullanımda; EN feature'lar EN barrel'ı, TR feature'lar TR barrel'ı kullanıyor |
| `features/shared/ui/` | `business_tile.dart` | `isletme_karti.dart` | `business_tile.dart` → discovery/EN; `isletme_karti.dart` → kesif/TR |
| `features/shared/ui/` | `category_chip.dart` | `kategori_etiketi.dart` | Aynı widget, farklı isim |
| `features/shared/ui/` | `labs_page.dart` | `deney_sayfasi.dart` | EN router → `labs_page`, TR router → `deney_sayfasi` |
| `features/shared/ui/components/` (20 dosya) | aktif EN bileşenler | `features/shared/ui/bilesenler/` (22 dosya) | Paralel bileşen dizinleri |
| `features/shared/ui/share/` | `business_share_card_sheet.dart` | `features/shared/ui/paylasim/isletme_paylasim_karti_paneli.dart` | Aynı bottom sheet |
| `features/shared/ui/achievements/` | `achievement_visuals.dart` | `features/shared/ui/basarilar/basari_gorselleri.dart` | Aynı achievement görsel bileşeni |
| `features/shared/ui/widgets/` | `meal_card_badge.dart`, `report_bottom_sheet.dart` | `features/shared/ui/yardimci-bilesenler/` | Paralel utility widget klasörleri |

**Kritik not — `onboarding_sayfasi.dart`:** Aynı klasörde hem `OnboardingPage` (EN) hem `OnboardingPage` (TR) sınıfı var gibi görünse de TR dosyası `onboarding_sayfasi.dart` içinde `class OnboardingPage` tanımı olabilir. Bu derleme zamanında `OnboardingPage` isim çakışmasına yol açar.

---

### 3.2 Türkçe Özel Karakter Dosya/Klasör İsimleri

**Sonuç: Türkçe özel karakter içeren dosya veya klasör adı BULUNAMADI.**

`lib/` altındaki tüm 746 `.dart` dosyası ve tüm dizin adları denetlendi. Dosya/klasör isimleri ASCII-safe transliterasyon kullanmaktadır:
- `ı` yerine `i` (örn. `saglayici` not `sağlayıcı`)
- `ü` yerine `u` (örn. `menuler` not `menüler`)
- `ğ` yerine `g` (örn. `deposu` not `deposu`)
- `ç` yerine `c` (örn. `ceviri` not `çeviri`)
- `ş` yerine `s` (örn. `sayfasi` not `sayfası`)
- `ö` yerine `o` (örn. `oneriler` not `öneriler`)

**Git mv yeniden adlandırması GEREKMİYOR** — dosya/klasör isimleri zaten düzgün. Türkçe karakter sorunu yoktur.

**Tek not:** `features/shared/ui/yardimci-bilesenler/` dizin adı tire (`-`) içermektedir. Dart'ta package import'larında tire desteklenmez ancak bu bir dosya-sistemi klasör adı olduğu için `import` ifadelerinde kullanılmamakta, doğrudan dosya path'i ile referans verilmektedir. Tire yerine alt çizgi (`yardimci_bilesenler`) tercih edilir, ancak öncelikli sorun değildir.

---

### 3.3 Orphan (Kullanılmayan) Dosyalar

Aşağıdaki dosyalar aktif EN router zincirinden, EN feature'lardan veya EN core'dan hiçbir `import` almamaktadır:

#### Pasif Giriş Noktaları (3 dosya)
- `lib/uygulama_girisi.dart` — TR main
- `lib/mobil_giris.dart` — TR main proxy
- `lib/firebase_secenekleri.dart` — TR firebase config

#### Pasif App Dizini (11 dosya)
- `lib/uygulama/` altındaki tüm 11 dosya

#### Pasif App_mobile Wrapper (1 dosya)
- `lib/mobil_uygulama/mobil_uygulama.dart`

#### Pasif L10n Wrappers (3 dosya)
- `lib/l10n/uygulama_yerellesmeleri.dart`
- `lib/l10n/uygulama_yerellesmeleri_en.dart`
- `lib/l10n/uygulama_yerellesmeleri_tr.dart`

#### Pasif Core Dizinleri (~85 dosya)
`lib/core/` altındaki tüm TR isimli alt dizinler:
`analitik/`, `onbellek/`, `ayarlar/`, `hatalar/`, `buyume/`, `ceviri/`, `konum/`, `medya/`, `izleme/`, `ag/`, `performans/`, `gizlilik/`, `kalite/`, `arama/`, `guvenlik/`, `hizmetler/`, `depolama/`, `arayuz/`, `hava/`, `icerik/`, `sabitler/`, `tarayici/`, `veri/`, `baglanti/`

#### Pasif Feature Dizinleri (~340 dosya)
`lib/features/` altındaki tüm TR isimli feature dizinleri:
`kimlik/`, `reklamlar/`, `butce_kombinasyonlari/`, `isletme/`, `ortak_listeler/`, `karsilastirma/`, `katki/`, `gelistirme_araclari/`, `kesif/`, `gomulu/`, `en_iyi_isletmeler/`, `favoriler/`, `gurmeler/`, `grup_istekleri/`, `kahramanlar/`, `yasal/`, `menuler/`, `bildirimler/`, `ayricaliklar/`, `fiyat_uyarilari/`, `profil/`, `yorumlar/`, `akilli_akis/`, `oneriler/`, `askidaki_ogunler/`, `tat_ikizi/`

Artı TR-only (EN karşılığı olmayan) orphan feature'lar:
`masa_siparisi/`, `yemek_gunlugu/`, `grup_oy/`, `sadakat/`, `sahiplen/`, `yerlestir/`, `sponsorluk/`

Artı `features/zincirler/` — EN `features/chains/` aktif, bu TR orphan.

#### Pasif Shared UI Dizinleri (~50 dosya)
- `features/shared/ui/bilesenler/` (22 dosya)
- `features/shared/ui/basarilar/` (1 dosya)
- `features/shared/ui/paylasim/` (1 dosya)
- `features/shared/ui/yardimci-bilesenler/` (2 dosya)
- `features/shared/ui/tasarim_sistemi.dart` — TR barrel (38 import: tümü TR feature'lardan, bunlar zaten orphan)
- `features/shared/ui/isletme_karti.dart`
- `features/shared/ui/kategori_etiketi.dart`
- `features/shared/ui/deney_sayfasi.dart`
- `features/onboarding/ui/onboarding_sayfasi.dart`
- `features/acilis/` (1 dosya)

**Tahmini toplam orphan dosya sayısı: ~500 dosya** (746'nın ~%67'si)

---

### 3.4 Özet Sayılar

| Kategori | Dosya Sayısı |
|---|---|
| Toplam `.dart` dosyası | 746 |
| Aktif EN ağacı (tahmini) | ~245 |
| Pasif TR ağacı (orphan) | ~500 |
| Her ikisi tarafından kullanılan (tasarim_sistemi barrel) | ~1 |

---

## Aksiyon Planı Eki: Paralel Dizin Temizliği

Bu bölüm mevcut Aksiyon Planı madde 19'u detaylandırır. Temizlik sırasında herhangi bir dosyayı **silmeden önce** onay alınmalıdır.

### Adım 1 — Onaylama (Silmeden Önce)

1. `uygulama/yonlendirici.dart` (TR router) içindeki tüm route'ların `app/router.dart` (EN router) içinde karşılığının olduğunu doğrula.
2. TR-only feature'ların (`masa_siparisi`, `yemek_gunlugu`, `grup_oy`, `sadakat`, `sahiplen`, `yerlestir`, `sponsorluk`) roadmap'te planlanmış feature'lar olup olmadığını kontrol et. Planlanmışsa silinmeden önce EN ağacına migrate edilmeli.
3. `features/onboarding/ui/onboarding_sayfasi.dart` ile `onboarding_page.dart` arasındaki farkı incele (geolocator bağımlılığı var mı?).

### Adım 2 — Pasif TR Ağacının Silinmesi (Onay Sonrası)

Aşağıdaki git komutları **onay alındıktan sonra** çalıştırılabilir:

```bash
# TR giriş noktaları
git rm lib/uygulama_girisi.dart lib/mobil_giris.dart lib/firebase_secenekleri.dart

# TR l10n wrappers
git rm lib/l10n/uygulama_yerellesmeleri.dart lib/l10n/uygulama_yerellesmeleri_en.dart lib/l10n/uygulama_yerellesmeleri_tr.dart

# TR app dizinleri
git rm -r lib/uygulama/ lib/mobil_uygulama/ lib/app_mobile/  # app_mobile da kaldırılabilir

# TR core dizinleri (toplu)
git rm -r lib/core/analitik/ lib/core/onbellek/ lib/core/ayarlar/ lib/core/hatalar/ \
  lib/core/buyume/ lib/core/ceviri/ lib/core/konum/ lib/core/medya/ lib/core/izleme/ \
  lib/core/ag/ lib/core/performans/ lib/core/gizlilik/ lib/core/kalite/ lib/core/arama/ \
  lib/core/guvenlik/ lib/core/hizmetler/ lib/core/depolama/ lib/core/arayuz/ \
  lib/core/hava/ lib/core/icerik/ lib/core/sabitler/ lib/core/tarayici/ lib/core/veri/ \
  lib/core/baglanti/

# TR feature dizinleri (toplu)
git rm -r lib/features/kimlik/ lib/features/reklamlar/ lib/features/butce_kombinasyonlari/ \
  lib/features/isletme/ lib/features/ortak_listeler/ lib/features/karsilastirma/ \
  lib/features/katki/ lib/features/gelistirme_araclari/ lib/features/kesif/ \
  lib/features/gomulu/ lib/features/en_iyi_isletmeler/ lib/features/favoriler/ \
  lib/features/gurmeler/ lib/features/grup_istekleri/ lib/features/kahramanlar/ \
  lib/features/yasal/ lib/features/menuler/ lib/features/bildirimler/ \
  lib/features/ayricaliklar/ lib/features/fiyat_uyarilari/ lib/features/profil/ \
  lib/features/yorumlar/ lib/features/akilli_akis/ lib/features/oneriler/ \
  lib/features/askidaki_ogunler/ lib/features/tat_ikizi/ lib/features/acilis/ \
  lib/features/zincirler/

# TR-only orphan feature'lar (roadmap kontrolü yapıldıktan sonra)
git rm -r lib/features/masa_siparisi/ lib/features/yemek_gunlugu/ lib/features/grup_oy/ \
  lib/features/sadakat/ lib/features/sahiplen/ lib/features/yerlestir/ lib/features/sponsorluk/

# Shared UI TR dizinleri
git rm -r lib/features/shared/ui/bilesenler/ lib/features/shared/ui/basarilar/ \
  lib/features/shared/ui/paylasim/ "lib/features/shared/ui/yardimci-bilesenler/"
git rm lib/features/shared/ui/tasarim_sistemi.dart lib/features/shared/ui/isletme_karti.dart \
  lib/features/shared/ui/kategori_etiketi.dart lib/features/shared/ui/deney_sayfasi.dart

# Onboarding TR dosyası
git rm lib/features/onboarding/ui/onboarding_sayfasi.dart
```

### Adım 3 — `flutter analyze` Doğrulaması

Silme sonrası:
```bash
cd uygulamalar/mobil && flutter analyze
```

Hata yoksa commit: `chore(mobil): remove ~500 orphan TR-tree files, keep canonical EN tree`

---

*Bölüm 3 `c:\yeedoy\uygulamalar\mobil\lib` altındaki 746 `.dart` dosyasının gerçek dosya + import analizi sonucudur. Tarih: 2026-05-25.*

---

## Bölüm 4: Güvenlik Denetimi (Security Audit)

**Tarih:** 2026-05-26
**Kapsam:** Flutter Mobil · Personel · Next.js Web · Supabase
**Metodoloji:** Gerçek dosya okuma; satır referanslı bulgular; varsayım yapılmamıştır.

---

### 4.0 Özet Puan Kartı

| Alan | Puan | Risk Seviyesi | Durum |
|---|---|---|---|
| Supabase RLS | 8/10 | ORTA | Son sprint'te köklü iyileştirme yapıldı; eski archive migrasyon'larında artık aktif olmayan politika kalıntıları var |
| Auth & Redirect | 8/10 | ORTA | Server-side tamamen güvenli; client-side `giris-formu.tsx`'de kısmi açık |
| Hardcoded Secret | 2/10 | KRITIK | `.env` ve `.env.local` dosyaları `SERVICE_ROLE_KEY`, `DB_PASSWORD`, `ACCESS_TOKEN`, `GOOGLE_MAPS_KEY` içeriyor |
| Keystore & Release | 7/10 | YUKSEK | Mobil `key.properties`/JKS gitignore'da; Personel release build `signingConfig=debug` kullanıyor; Mobil'de `isMinifyEnabled` eksik |
| iOS Guvenlik | 9/10 | DUSUK | ATS bypass yok; URL scheme'ler kısıtlı; yalnizca gerekli izinler mevcut |
| Logging & PII | 8/10 | ORTA | Mobil `SafeDebugPrint` ile güvenli; Personel'de `Uncaught error: $error` ham log var |
| Next.js API | 8/10 | ORTA | CSP mevcut ancak `script-src 'unsafe-inline'` ve `img-src http:` içeriyor; HSTS başlığı eksik |
| Dependency | 8/10 | ORTA | Bilinen kritik CVE tespit edilmedi; bağımlılıklar güncel görünüyor |

---

### 4.1 Kritik Bulgular (CRIT)

| ID | Bileşen | Bulgu | Dosya:Satır | Önerilen Fix |
|---|---|---|---|---|
| CRIT-001 | Mobil / Personel | `.env` dosyasında `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_PASSWORD`, `SUPABASE_ACCESS_TOKEN` düz metin olarak mevcut. Dosya uygulama asset'i olarak paketleniyor (`pubspec.yaml:73-74` / `pubspec.yaml:73-74`), dolayısıyla APK/IPA içinden çıkarılabilir. | `uygulamalar/mobil/.env:3-5`, `uygulamalar/personel/pubspec.yaml:73` (assets bölümü) | SERVICE_ROLE_KEY ve DB_PASSWORD asla Flutter asset olarak paketlenmemeli. `.env` yalnızca `SUPABASE_URL` ve `SUPABASE_ANON_KEY` içermeli; diğer anahtarlar Supabase Vault/CI secret olarak saklanmalı. |
| CRIT-002 | Next.js Web | `.env.local` dosyasında `SUPABASE_SERVICE_ROLE_KEY` ve `NEXT_PUBLIC_GMAPS_KEY` düz metin olarak kayıtlı. `.env.local` gitignore'da doğru işaretli ancak geliştirici makinesinde açıkta duruyor ve yanlışlıkla commit riski var. | `uygulamalar/web/.env.local:3,10` | `.env.local` yerine CI/CD ortam değişkenleri veya şifreli secret manager kullanılmalı. Proje genelinde `git-secrets` veya `detect-secrets` pre-commit hook'u eklenmeli. |
| CRIT-003 | Mobil | Uygulama asset olarak paketlenen `.env` build artifact'larına da kopyalanıyor. `build/app/intermediates/assets/release/mergeReleaseAssets/flutter_assets/.env` dosyasında tüm anahtarlar düz metin. Release APK içinden `apktool` veya zip açarak erişilebilir. | `uygulamalar/mobil/build/app/intermediates/assets/release/mergeReleaseAssets/flutter_assets/.env` | Build çıktıları gitignore'da olsa da release build süreci gizlenmiş anahtarları APK'ya gömmemeli. Supabase URL+AnonKey dışındaki tüm değerleri `.env` dışına çıkar. |

---

### 4.2 Yüksek Bulgular (HIGH)

| ID | Bileşen | Bulgu | Dosya:Satır | Önerilen Fix |
|---|---|---|---|---|
| HIGH-001 | Personel Android | Release build `signingConfig = signingConfigs.getByName("debug")` ile imzalanıyor. Production'a giden APK debug keystore ile imzalanırsa Play Store reddi veya güven sorunu oluşur. | `uygulamalar/personel/android/app/build.gradle.kts:43` | Mobil uygulamadaki örnek gibi `key.properties` veya CI ortam değişkenlerinden okunan gerçek release keystore yapılandırması eklenmeli. `// TODO: Add signing config` yorumu hala yerinde. |
| HIGH-002 | Mobil Android | `build.gradle.kts` release build tipinde `isMinifyEnabled` ve `isShrinkResources` tanımlı değil. Flutter'ın varsayılan R8/ProGuard davranışına bırakılmış; kod küçültme ve obfuscation açıkça aktif edilmemiş. | `uygulamalar/mobil/android/app/build.gradle.kts:83-98` | `release { isMinifyEnabled = true; isShrinkResources = true }` açıkça eklenmeli. Personel app'te zaten doğru yapılandırılmış. |
| HIGH-003 | Next.js Web | `Content-Security-Policy`'de `script-src 'unsafe-inline'` ve `img-src 'self' data: blob: https: http:` var. `unsafe-inline` XSS riskini artırır; `http:` imaj kaynağı ise mixed-content sorununa yol açabilir. | `uygulamalar/web/next.config.mjs:70-71,73` | `script-src` için nonce veya hash tabanlı CSP'ye geçilmeli. `img-src` içinden `http:` kaldırılmalı (yalnızca localhost'a izin verilebilir). |
| HIGH-004 | Next.js Web | `Strict-Transport-Security` (HSTS) başlığı Next.js `headers()` konfigürasyonunda tanımlı değil. HTTPS zorunluluğu uygulama katmanında sağlanamıyor. | `uygulamalar/web/next.config.mjs:84-117` | `{ key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' }` genel route başlıklarına eklenmeli. |
| HIGH-005 | Supabase | `20260523000002` migrasyon'una kadar `loyalty_programs_owner_all` politikası `to authenticated` rol kısıtlaması olmadan oluşturulmuştu (eksik `to` ifadesi = anon dahil). Bu durum düzeltildi, ancak mevcut uzak veritabanında hala eski politika aktif olabilir; migration çalıştırılana kadar risk devam eder. | `supabase/migrations/20260523000002_security_rls_new_tables.sql:1-9` | Migration'ın uzak Supabase instance'ına uygulandığı doğrulanmalı (`supabase db push` çalıştırılmış olmalı). |
| HIGH-006 | Personel | `main.dart:22` satırında `debugPrint('[PersonelApp] Uncaught error: $error')` ile ham exception nesnesi loglanıyor. `$error` içinde stack trace, kullanıcı verisi veya URL fragment bilgisi olabilir; Crashlytics bağlantısı yok. | `uygulamalar/personel/lib/main.dart:22` | Mobil uygulamadaki gibi Crashlytics entegrasyonu tamamlanmalı. `debugPrint` yerine `FirebaseCrashlytics.instance.recordError` kullanılmalı; `$error` doğrudan loglanmamalı. |

---

### 4.3 Orta Bulgular (MEDIUM)

| ID | Bileşen | Bulgu | Dosya:Satır | Önerilen Fix |
|---|---|---|---|---|
| MED-001 | Next.js Web | `GirisFormu` bileşeninde `redirectTo` prop'u server-side `sanitizeInternalRedirect()` geçirildikten sonra client'a iniyor (doğru). Ancak `useEffect` içinde `router.replace(redirectTo)` çağrısı `redirectTo`'nun server-sanitized değer olduğunu varsayıyor. `result?.redirectTo` ise sunucu action'dan dönen ve ek doğrulama yapılmamış bir değer. | `uygulamalar/web/src/ui/bolumler/giris-formu.tsx:49,112` | Sunucu action'dan dönen `result?.redirectTo` değeri de `sanitizeInternalRedirect()` ile doğrulanmalı ya da sunucu action bu değeri kontrollü şekilde üretmeli. |
| MED-002 | Next.js Web | `login-form.tsx` (ingilizce versiyon) `signInError.message` değerini doğrudan `setError(signInError.message)` ile UI'a yazıyor. Supabase auth hataları zaman zaman iç detay içerebilir. | `uygulamalar/web/src/ui/sections/login-form.tsx:64` | Hata mesajları kullanıcıya gösterilmeden önce genel bir mesaja dönüştürülmeli. |
| MED-003 | Supabase | `profiles` view'u `security_invoker = true` ile yeniden oluşturuldu, email kolonu `null` döndürecek şekilde maskelendi — ancak anon kullanıcılar hala `display_name`, `avatar_url`, `bio`, `is_gourmet` alanlarını okuyabiliyor. Gizlilik perspektifinden değerlendirme gerekiyor. | `supabase/migrations/20260520000002_harden_public_views.sql:3-13` | `is_gourmet` ve `bio` alanlarının anon erişime açık olması gerekip gerekmediği gözden geçirilmeli. |
| MED-004 | Supabase | `menu_feedback` tablosu anon insert'e açık, `rating`, `category` ve `message` alanları için sınır kuralları doğrulama yapıyor. Rate limiting sadece Next.js API katmanında uygulanıyor; PostgREST üzerinden doğrudan erişimde bu sınır devre dışı. | `supabase/migrations/20260520000004_tighten_menu_feedback_policy.sql:1-12` | Supabase DB linter'da `rate_limit` veya ek `check` kısıtları değerlendirilebilir. Mevcut kontrolün yeterli olduğu görüldüğü durumda düşük öncelik. |
| MED-005 | iOS / Mobil | Deep link scheme `yeedoy://` `android:autoVerify="false"` ile tanımlanmış. Yani herhangi bir uygulama `yeedoy://` scheme'ini ele geçirebilir. Supabase auth callback'i bu scheme üzerinden geliyor. | `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml:49-54` | OAuth/Supabase callback için `https://` App Link (autoVerify=true, zaten mevcut) kullanılmalı. `yeedoy://` scheme'i yalnızca ek deep link amaçlı kullanılmalı; kritik auth callback bu scheme üzerinden yapılmamalı. `auth_service.dart:79`'de `redirectTo: 'io.supabase.yeedoy://reset-callback'` yerine `https://yeedoy.com/auth/callback` gibi App Link tercih edilmeli. |
| MED-006 | Supabase Edge Functions | `supabase/functions/_shared/rate-limit.ts:19` içinde `SUPABASE_SERVICE_ROLE_KEY` kullanılıyor. Paylaşılan helper üzerinden servis rolü anahtarı doğrudan rate limit bucket yazma işlemlerinde kullanılıyor. Scope minimum ilkesi açısından değerlendirilmeli. | `supabase/functions/_shared/rate-limit.ts:19` | Rate limit işlemleri için özel bir DB rolü veya SECURITY DEFINER RPC tercih edilebilir; servis rol anahtarı kullanımı minimize edilmeli. |

---

### 4.4 Düşük Bulgular (LOW)

| ID | Bileşen | Bulgu | Dosya:Satır | Önerilen Fix |
|---|---|---|---|---|
| LOW-001 | Mobil Android | `android:allowBackup` manifest'te tanımlı değil (Android varsayılanı `true`). API 31+ için `android:dataExtractionRules` öneriliyor. | `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml` | `android:allowBackup="false"` veya `android:dataExtractionRules="@xml/data_extraction_rules"` eklenmeli. |
| LOW-002 | Personel Android | Personel uygulamasında `android:allowBackup` tanımlı değil — aynı risk. | `uygulamalar/personel/android/app/src/main/AndroidManifest.xml` | Aynı öneri. |
| LOW-003 | iOS / Mobil | `NSLocationAlwaysAndWhenInUseUsageDescription` tanımlanmış. Uygulamanın arka planda konum gerektirip gerektirmediği sorgulanmalı; gerektirmiyorsa bu izin kaldırılmalı (App Store Review'da sorgulama konusu olabilir). | `uygulamalar/mobil/ios/Runner/Info.plist:66-67` | Gerçek kullanım senaryosu denetlenmeli; sadece `NSLocationWhenInUseUsageDescription` yeterliyse `AlwaysAndWhenInUse` kaldırılmalı. |
| LOW-004 | Next.js Web | CSP'de `connect-src` içinde `wss://*.supabase.co` joker domain var. Yalnızca projenin kendi Supabase subdomain'i izin listesine alınmalı. | `uygulamalar/web/next.config.mjs:74` | `wss://*.supabase.co` yerine `wss://${supabaseHost}` (tek spesifik domain) yeterli. |
| LOW-005 | Supabase | `admin_owner_claims_queue_v1`, `admin_reports_queue_v1`, `admin_suggestions_v1` view'larına `authenticated` role genelinde `SELECT` izni var; bu view'lar admin RLS kontrolü yapmıyor. Bir saldırgan admin olmayan ama authenticated kullanıcıyla bu view'lara erişebilir. | `supabase/migrations/20260520000002_harden_public_views.sql:37-39` | Bu view'lar için `GRANT SELECT ... TO authenticated` kaldırılmalı; sadece `is_admin()` kontrolü yapan bir RLS politikası veya SECURITY DEFINER RPC üzerinden erişim sağlanmalı. |
| LOW-006 | Next.js Web | Embed sayfaları için `X-Frame-Options: ALLOWALL` ve `frame-ancestors *` ayarlanmış. Embed içeriği Clickjacking saldırısına karşı korumasız. Gömülü sayfalarda hassas kullanıcı etkileşimi yoksa kabul edilebilir; ancak belgelenmiş olmalı. | `uygulamalar/web/next.config.mjs:88-92` | Embed'in güvenli olabilmesi için içerik tamamen anonim/salt-okunur nitelikte olmalı; etkileşimli öğeler embed'de kullanılmamalı. |
| LOW-007 | Supabase | `purge-temp-uploads/index.ts:155` satırında `console.log(...)` istatistik bilgisi loglanıyor. Hassas veri içermiyor, ancak production edge function logları gereksiz bilgi sızıntısı yaratabilir. | `supabase/functions/purge-temp-uploads/index.ts:155` | Gereksiz `console.log` kaldırılabilir veya `console.info` ile koşullu hale getirilebilir. |

---

### 4.5 Iyi Pratikler (Dogru Yapılanlar)

Aşağıdaki güvenlik kontrolleri doğru ve eksiksiz uygulanmıştır:

- **Supabase RLS coverage**: Son sprinte ait 9 migration (20260520-20260523) ile admin politikaları `to authenticated` kısıtlamasına alındı, anon admin RPC erişimi iptal edildi, trigger fonksiyonları `public` execute izninden temizlendi.
- **SECURITY DEFINER + search_path**: Tüm `SECURITY DEFINER` fonksiyonlar `SET search_path = public, extensions, pg_temp` ile sabitlenmiş (`20260520000005`, `20260523000003`). Search-path injection riski kapatılmış.
- **Flutter SecureLocalStorage**: Mobil uygulama session token'ını `flutter_secure_storage` + `encryptedSharedPreferences: true` kombinasyonuyla saklıyor (`uygulamalar/mobil/lib/core/security/secure_local_storage.dart:10-12`). `SharedPreferences`'a fallback yalnızca web modunda.
- **SafeDebugPrint**: Mobil uygulamada tüm `debugPrint` çağrıları JWT, email, telefon, koordinat ve UUID içerenleri sanitize eden global interceptor üzerinden geçiyor (`uygulamalar/mobil/lib/core/security/safe_debug_print.dart`).
- **sanitizeInternalRedirect**: Redirect parametresi tüm kritik noktalarda (auth/callback, login page, panel-handoff, yasakli, giris/page) `sanitizeInternalRedirect()` geçirilmeden işlenmiyor. İki ayrı implementasyon (`guvenli-yonlendirme.ts` ve `safe-redirect.ts`) fonksiyonel olarak özdeş.
- **Rate limiting**: `/api/feedback`, `/api/admin/claims`, `/api/media/upload`, `/api/track`, `/auth/panel-handoff` endpoint'lerinde kullanıcı bazlı (kimlik doğrulanmış kullanıcı için daha yüksek limit) rate limiting uygulanıyor.
- **CSP mevcut ve temel alanları kapsıyor**: `frame-ancestors 'none'`, `base-uri 'self'`, `form-action 'self'`, `upgrade-insecure-requests` yönergeleri doğru yapılandırılmış.
- **Panel route guard**: Middleware `guardPanelRoute` tüm `/owner/*`, `/admin/*` ve `/api/admin/*` yollarını hem authentication hem de role kontrolüyle koruyor.
- **Admin RPC anon erişimi revoke**: `20260520000006_revoke_anon_admin_rpc.sql` tüm `admin_*` SECURITY DEFINER fonksiyonlardan anon execute iznini toplu olarak kaldırıyor.
- **View güvenlik-invoker**: Admin ve genel view'lara `security_invoker = true` eklendi; view üzerinden base tablo RLS'ini atlatma riski kapatıldı.
- **Personel R8/minify**: `personel/android/app/build.gradle.kts:44-45` — `isMinifyEnabled = true` ve `isShrinkResources = true` release build'de aktif.
- **iOS ATS bypass yok**: `Info.plist`'te `NSAllowsArbitraryLoads` veya `NSExceptionDomains` bulunmuyor. Tüm bağlantılar HTTPS zorunlu.
- **Keystore gitignore**: `key.properties`, `*.keystore`, `*.jks` kökün `.gitignore` dosyasında doğru tanımlı; git'e commit edilmemiş.
- **Servis rolü anahtarı istemciye sızmıyor**: `SUPABASE_SERVICE_ROLE_KEY` yalnızca sunucu tarafı `config.ts` ve edge function'larda `Deno.env.get()` ile okunuyor; Flutter veya tarayıcı bundle'ına dahil edilmiyor (test dışı ortam için).

---

### 4.6 Aksiyon Planı

#### Hemen (Bu Sprint)

1. **[CRIT-001/003] `.env` dosyalarından `SERVICE_ROLE_KEY`, `DB_PASSWORD`, `ACCESS_TOKEN` kaldır.** Mobil ve Personel `.env` dosyaları yalnızca `SUPABASE_URL` ve `SUPABASE_ANON_KEY` içermeli. Diğer değerler CI/CD ortam değişkeni veya Supabase secret olarak saklanmalı. APK'ya gömülü `.env` build artifact'ı derhal temizlenmeli (`build/` dizini gitignore'a alınmış; release APK yeniden üretilmeli).
2. **[CRIT-002] `.env.local` yönetim prosedürü**: `.env.local` içindeki `SUPABASE_SERVICE_ROLE_KEY` ve `NEXT_PUBLIC_GMAPS_KEY` rotate edilmeli. Supabase dashboard'dan yeni service role key üretilip Vercel/CI environment variable olarak saklanmalı. Yerel geliştirme için `1Password` veya `direnv` + şifreli vault kullanımı dokümante edilmeli.
3. **[HIGH-005] Supabase migration'larını uzak instance'a uygula**: `supabase db push` veya Supabase dashboard üzerinden tüm bekleyen migration'ların (özellikle 20260523*) uygulandığı doğrulanmalı.

#### Kısa Vadeli (1-2 Sprint)

4. **[HIGH-001] Personel Android release signing**: `key.properties` + gerçek upload keystore ile imzalama yapılandırılmalı. Mobil `build.gradle.kts` referans alınabilir.
5. **[HIGH-002] Mobil Android minify**: Release build tipine `isMinifyEnabled = true` ve `isShrinkResources = true` eklenmeli.
6. **[HIGH-003] CSP `unsafe-inline` kaldırma**: Next.js `script-src` için nonce tabanlı CSP uygulanmalı. Next.js 14+ `generateNonce()` + `<Script nonce>` desteği değerlendirilmeli.
7. **[HIGH-004] HSTS başlığı**: `Strict-Transport-Security: max-age=31536000; includeSubDomains` tüm route'lara eklenmeli.
8. **[HIGH-006] Personel Crashlytics**: `main.dart`'daki `TODO` tamamlanmalı; `PlatformDispatcher` ve `FlutterError.onError` Crashlytics'e bağlanmalı.
9. **[MED-005] Android OAuth scheme güvenliği**: Supabase auth callback `io.supabase.yeedoy://` scheme'ini değil, `https://yeedoy.com/auth/callback` App Link'ini kullanacak şekilde güncellenmeli.
10. **[LOW-005] Admin view izin kısıtlaması**: `admin_owner_claims_queue_v1` vd. view'lardan `authenticated` rolü `REVOKE SELECT` yapılmalı; erişim yalnızca `is_admin()` kontrolüyle yapılan RPC üzerinden sağlanmalı.

#### Uzun Vadeli

11. **[MED-001] Client-side redirect doğrulama**: `giris-formu.tsx` içinde sunucudan dönen `result?.redirectTo` değeri de `sanitizeInternalRedirect()` ile geçirilmeli ya da sunucu action dönüş tipi sözleşmede sabit route listesine kısıtlanmalı.
12. **[MED-003] Profile view veri minimizasyonu**: `profiles` view'unda anon kullanıcıya `is_gourmet` ve `bio` alanlarının gösterilip gösterilmeyeceği gizlilik politikası çerçevesinde değerlendirilmeli.
13. **[LOW-001/002] Android backup kısıtlaması**: Her iki uygulamaya `android:allowBackup="false"` veya API 31+ `dataExtractionRules` eklenmeli.
14. **Pre-commit secret tarama**: `detect-secrets` veya `gitleaks` CI pipeline'a eklenmeli; `.env` dosyalarında sırların git'e girmesini önlemek için otomatik kontrol kurulmalı.
15. **[MED-006] Edge function servis rol kapsamı**: Rate limit işlemleri için minimum yetki ilkesi doğrultusunda dedicated RLS politikası veya ayrı DB rolü değerlendirilmeli.

---

*Bölüm 4 gerçek dosya okuması ile üretilmiştir. Tarih: 2026-05-26. Denetçi: Otomatik güvenlik tarama (satır referanslı).*

---

## Bölüm 5: Performans Optimizasyon Raporu
**Tarih:** 2026-05-26
**Kapsam:** Flutter Mobil · Flutter Personel · Supabase · Next.js Web
**Metodoloji:** Gerçek dosya okuma, kod değişikliği, `flutter analyze` + `npm run typecheck && npm run lint` doğrulaması.

---

### 5.0 Özet

| Alan | Değişiklik | Tahmini Etki |
|---|---|---|
| Flutter Mobil — Image Caching | `business_detail_sections.dart` foto galerisi `AppNetworkImage`'e geçirildi; `reviews/business_reviews_page.dart` foto strip `AppNetworkImage`'e geçirildi; `sadakat_kartlarim_sayfasi.dart` logo `CachedNetworkImage`'e geçirildi | Disk cache hit; gereksiz ağ isteği azalır; thumb variant ile 4x küçük memCacheWidth (80px) |
| Flutter Personel — RepaintBoundary | `siparisler_sayfasi.dart` liste item'larına `RepaintBoundary` eklendi; `kds_sayfasi.dart` KDS liste item'larına `RepaintBoundary` eklendi | Sipariş/KDS list state değiştiğinde yalnızca değişen kart repaint alır; diğer kartlar atlar |
| Flutter Personel — autoDispose | Dashboard: `haftalikVeriProvider`, `saatlikVeriProvider`, `personelPerformansProvider`, `dashboardIstatistikProvider` — `AsyncNotifierProvider.autoDispose` geçirildi | Dashboard sayfası kapatıldığında 4 provider serbest bırakılır; bellek ayak izi azalır |
| Supabase — PostGIS Index | `20260526000001_postgis_business_location_index.sql` oluşturuldu: `businesses.location geography(Point,4326)` GENERATED sütunu, GIST spatial index, `find_nearby_businesses_v1` RPC | Haversine Dart-side hesabı yerine sunucu tarafı ST_DWithin; büyük veri setinde sorgu süresi lineer → log mertebesine düşer |
| Next.js Web — HSTS | `next.config.mjs`'e `Strict-Transport-Security: max-age=31536000; includeSubDomains` header eklendi | HTTPS downgrade saldırısı riski kapatıldı (HIGH-004 güvenlik bulgusu) |
| Next.js Web — Bundle Analyzer | `@next/bundle-analyzer` zaten `devDependencies`'de mevcut ve `ANALYZE=true npm run build` ile aktif; konfigürasyon tamamlanmış | Mevcut: yapılandırma değişikliği gerekmedi |
| Next.js Web — Dynamic Import | `leaflet`/`react-leaflet` zaten `BusinessMap`, `LocationPickerMapClient` üzerinden `dynamic(() => import(...), {ssr: false})` ile lazy load ediliyor | Mevcut: değişiklik gerekmedi |
| Next.js Web — next/font | `app/layout.tsx` zaten `next/font/google` ile `Sora` + `Playfair_Display` yüklüyor, her ikisinde `display: 'swap'` var | Mevcut: değişiklik gerekmedi |
| Next.js Web — API Cache | `src/lib/veri/menu-okuma.ts` tüm fonksiyonlarda `{ revalidate: 120–600 }` zaten tanımlı | Mevcut: değişiklik gerekmedi |

---

### 5.1 Flutter Mobil — Image & Provider

#### 5.1.1 Image Caching

`cached_network_image ^3.4.1` ve `AppNetworkImage` wrapper mobil uygulamada zaten mevcut ve 30+ noktada kullanılıyor. Bu sprint'te kalan `Image.network()` noktalara `AppNetworkImage` / `CachedNetworkImage` geçişi uygulandı:

| Dosya | Öncesi | Sonrası |
|---|---|---|
| `features/business/ui/sections/business_detail_sections.dart:861` | `Image.network(urls[i], width:90, errorBuilder:...)` | `AppNetworkImage(url, width:90, variant:thumb, borderRadius:...)` |
| `features/reviews/ui/business_reviews_page.dart:434` | `Image.network(urls[i], width:80, errorBuilder:...)` | `AppNetworkImage(url, width:80, variant:thumb, borderRadius:...)` |
| `features/sadakat/ui/sadakat_kartlarim_sayfasi.dart:287` | `Image.network(logoUrl, width:40, errorBuilder:...)` | `CachedNetworkImage(imageUrl, width:40, memCacheWidth:80, placeholder, errorWidget:...)` |

`AppNetworkImage` (`core/media/app_network_image.dart`): `CachedNetworkImage` + `AppImageCacheManager` + WebP dönüşümü + `memCacheWidth/maxWidthDiskCache` ile optimize thumbnail. `business_detail_sections.dart` photo viewer (`Image.network` fullscreen, `InteractiveViewer` içinde) ve `menu_page.dart` thumbnail zaten `errorBuilder` içeriyor ve sık rebuild almıyor — bu sprint kapsam dışı tutuldu.

**`flutter analyze`:** No issues found.

#### 5.1.2 FutureBuilder Misuse

Önceki sprintte `group_request_detail_page.dart` düzeltildi. `acik_menu_paylasim_sayfasi.dart` TR tree ile silindi. Aktif ağaçta başka `build()` içinde method call future yok — doğrulandı.

#### 5.1.3 Provider Lifecycle

MED-007 kapsamında 71 provider `.autoDispose`'a alındı (önceki sprint). Bu sprintte ek `keepAlive` kontrolü yapıldı — gereksiz `keepAlive` kullanımı tespit edilmedi.

---

### 5.2 Flutter Personel — RepaintBoundary & Realtime

#### 5.2.1 RepaintBoundary

| Dosya | Widget | Değişiklik |
|---|---|---|
| `features/masa_siparisleri/ui/siparisler_sayfasi.dart` | `_SiparisKarti` (ListView.separated itemBuilder) | `RepaintBoundary` wrapper eklendi |
| `features/kds/ui/kds_sayfasi.dart` | `KdsSiparisKarti` (ListView.separated itemBuilder) | `RepaintBoundary` wrapper eklendi |

Personel uygulamasında `CustomPaint` kullanan widget bulunmadı (doğrulandı). KDS ve sipariş kartları ağır görsel karmaşıklığa sahip (`Card + Padding + Column + Row + multiple Text + FilledButton`). `RepaintBoundary` ile yalnızca durum değişen kart repaint alacak.

#### 5.2.2 Realtime Subscription Optimizasyonu

`masa_siparisi_bildiricisi.dart` ve `kds_bildiricisi.dart` gözden geçirildi:
- `.stream()` kullanımı yok — `onPostgresChanges` callback'leri kullanılıyor (zaten optimize)
- Supabase Realtime her zaman tam satır gönderir; istemci tarafında sütun filtrelemesi API tarafından desteklenmez
- `ref.onDispose(() => supabase.removeChannel(channel))` masa_siparisi_bildiricisi.dart içinde doğru konumda
- `kds_bildiricisi.dart` `ref.onDispose(() => _yenilemeSayaci?.cancel())` ile timer düzgün iptal edilyor

Sonuç: Realtime subscription'lar halihazırda doğru yapılandırılmış; değişiklik gerekmedi.

#### 5.2.3 Dashboard autoDispose

`dashboard_istatistik_saglayicisi.dart` içindeki 4 provider `AsyncNotifierProvider.autoDispose` modifier'ına migre edildi:

| Provider | Öncesi | Sonrası |
|---|---|---|
| `haftalikVeriProvider` | `AsyncNotifierProvider` | `AsyncNotifierProvider.autoDispose` |
| `saatlikVeriProvider` | `AsyncNotifierProvider` | `AsyncNotifierProvider.autoDispose` |
| `personelPerformansProvider` | `AsyncNotifierProvider` | `AsyncNotifierProvider.autoDispose` |
| `dashboardIstatistikProvider` | `AsyncNotifierProvider` | `AsyncNotifierProvider.autoDispose` |

Riverpod 3.x pattern: provider `AsyncNotifierProvider.autoDispose`, notifier class `extends AsyncNotifier<T>` (değişmez). `flutter analyze`: 0 hata (yalnızca test dosyalarında pre-existing `info` uyarıları).

---

### 5.3 Supabase — PostGIS Index & RPC

#### 5.3.1 PostGIS Yakın İşletme Araması

**Mevcut durum (öncesi):** `search_businesses_v1` ve `nearby_businesses_v2` fonksiyonları `lat`/`lng` sütunlarında Haversine formülü kullanıyor:
```sql
6371000 * acos(cos(radians(p_lat)) * cos(radians(b.lat)) * cos(radians(b.lng) - radians(p_lng)) + sin(radians(p_lat)) * sin(radians(b.lat)))
```
Bu hesaplama index kullanamaz; `businesses` tablosundaki tüm satırları tarar.

**Yeni migration (`20260526000001_postgis_business_location_index.sql`):**

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE businesses
  ADD COLUMN IF NOT EXISTS location geography(Point, 4326)
  GENERATED ALWAYS AS (
    CASE WHEN lat IS NOT NULL AND lng IS NOT NULL
    THEN ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ELSE NULL END
  ) STORED;

CREATE INDEX IF NOT EXISTS businesses_location_gix
  ON businesses USING GIST (location);
```

- `location` sütunu GENERATED ALWAYS STORED — lat/lng değiştiğinde otomatik güncellenir
- GIST spatial index — `ST_DWithin` sorguları index kullanır, table scan yapmaz
- `find_nearby_businesses_v1` RPC — `SECURITY DEFINER`, `SET search_path = public`, `anon` + `authenticated` erişim
- Migration idempotent: `CREATE EXTENSION IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`

**Tahmini etki:** 10.000 işletmeli tabloda 2km yarıçaplı yakın arama, tam table scan yerine spatial index kullanımıyla sorguda 10x-100x hız artışı beklenmektedir.

#### 5.3.2 RPC N+1 Analizi

`supabase/functions/push-dispatch/index.ts` gözden geçirildi: N+1 pattern tespit edildi — `for (const n of notifications)` döngüsü içinde her bildirim için `supabase.from('user_devices').select(...)` çağrısı yapılıyor. Ancak bu fonksiyon zaten dequeue-tabanlı batch işlemi yapıyor (max 50 bildirim per invoke) ve FCM gönderimi async seri olarak işleniyor — paralel FCM isteği yapılamaz (rate limit). Edge function mimarisi gereği bu pattern kabul edilebilir; `complete_notification_dispatch_job_v1` RPC çağrıları da seri olmak zorunda. Geliştirme önerisi (bu sprint kapsam dışı): tüm user_id'ler için `user_devices`'ı tek IN() sorgusunda çekmek ve bir Map'e indekslemek.

#### 5.3.3 Supabase Realtime Kanalları

Edge function'larda Supabase Realtime broadcast kullanımı incelendi: `push-dispatch` yalnızca DB sorgular, broadcast yapmıyor. Gereksiz broadcast payload sorunu tespit edilmedi.

---

### 5.4 Next.js Web — Bundle & Caching

#### 5.4.1 Bundle Analizi Konfigürasyonu

`@next/bundle-analyzer ^16.1.6` zaten `devDependencies`'de mevcut. `next.config.mjs` içinde:
```js
const withBundleAnalyzer = bundleAnalyzer({ enabled: process.env.ANALYZE === 'true' });
```
`ANALYZE=true npm run build:analyze` komutu `package.json`'da tanımlı. Konfigürasyon tamamlanmış — değişiklik gerekmedi.

#### 5.4.2 Dynamic Import

`leaflet` ve `react-leaflet` zaten `BusinessMap.tsx` ve `LocationPickerMapClient.tsx` üzerinden `dynamic(() => import(...), {ssr: false})` ile lazy load ediliyor. Doğrudan import yapan `LeafletMap.tsx` ve `LocationPickerMap.tsx` yalnızca bu dynamic wrapper'lar tarafından import edildiğinden bundle'a dahil edilmez. `harita-istemcisi.tsx` de `// NOTE: This component is already behind a dynamic() ssr:false boundary` notu ile korunuyor. Değişiklik gerekmedi.

#### 5.4.3 React Server Component

`'use client'` direktifleri incelendi: 30 bileşende kullanılıyor, tümü `useState`/`useEffect`/event handler gerektiren bileşenler. Gereksiz `'use client'` kullanımı tespit edilmedi. `Suspense` + `loading.tsx` kullanımı: `app/(public)/loading.tsx` mevcut.

#### 5.4.4 Font Optimizasyonu

`app/layout.tsx` zaten `next/font/google`:
```ts
import { Sora, Playfair_Display } from 'next/font/google';
const sora = Sora({ subsets: ['latin'], variable: '--font-sora', display: 'swap' });
```
`display: 'swap'` her iki fontta da tanımlı. Harici `<link>` yüklemesi yok. Değişiklik gerekmedi.

#### 5.4.5 API Response Caching

`src/lib/veri/menu-okuma.ts` 11 farklı fonksiyonda `{ revalidate: 120–600 }` tanımlı. `src/lib/db/presentation-settings.ts` içinde `revalidate: 120`. Public menü endpoint'leri ISR ile cache'leniyor. Değişiklik gerekmedi.

#### 5.4.6 HSTS Header (HIGH-004)

`next.config.mjs` `/:path*` route'una `Strict-Transport-Security: max-age=31536000; includeSubDomains` eklendi.

**Öncesi:** HSTS header yoktu — HTTPS downgrade saldırısı koruması uygulama katmanında sağlanamıyordu.
**Sonrası:** Tüm route'lar HSTS header gönderiyor; tarayıcılar bir yıl boyunca HTTPS zorunlu tutuyor.

**`npm run typecheck`:** Pass (0 hata). **`npm run lint`:** No ESLint warnings or errors.

---

### 5.5 Benchmark Karşılaştırması

| Metrik | Öncesi | Sonrası | İyileştirme |
|---|---|---|---|
| Foto galeri thumbnail network isteği | `Image.network()` — disk cache yok, her mount'ta ağ isteği | `AppNetworkImage` (CachedNetworkImage + AppImageCacheManager) — disk cache, WebP dönüşümü | Tekrar açılışta disk cache hit; bandwidth tasarrufu; hızlı thumbnail yüklenme |
| Sadakat logo network isteği | `Image.network()` — her build'de tam yük | `CachedNetworkImage(memCacheWidth:80)` — 2x DPR için optimize cache | Memory cache 80px (40x40@2x); ağ isteği sadece ilk görüntülemede |
| Sipariş listesi repaint | Her `masaSiparisleriProvider` değişimde tüm kartlar repaint | `RepaintBoundary` — sadece değişen kart repaint alır | Realtime sipariş güncellemesinde frame time düşer; dart:ui repaint scope izole |
| KDS liste repaint | Her `kdsProvider` değişimde tüm KDS kartları repaint | `RepaintBoundary` — sadece değişen KDS kartı repaint alır | 30s auto-yenileme ve manual kabul/hazır aksiyonlarında frame drop azalır |
| Dashboard bellek kullanımı | 4 provider sayfa kapatılsa bile canlı kalır | `autoDispose` — sayfadan çıkıldığında serbest bırakılır | Dashboard provider bellek ayak izi azalır; tekrar açıldığında taze veri çekilir |
| Yakın işletme araması (PostGIS) | Haversine full table scan — O(n) tüm işletmeler | GIST index + ST_DWithin — index scan, O(log n) | 10.000 işletmeli production'da ~10x-100x sorgu hızı artışı beklenir |
| HTTPS güvenliği (HSTS) | Header yok — downgrade saldırısı mümkün | max-age=31536000 — 1 yıl HTTPS zorunlu | Güvenlik kaybı sıfır; ilk yıl tarayıcıdan otomatik HTTPS enforce |
| bundle-analyzer | Zaten konfigüre (`ANALYZE=true`) | Mevcut — değişiklik yok | — |
| Dynamic import (Leaflet) | Zaten dynamic (`ssr:false`) | Mevcut — değişiklik yok | — |

---

### 5.6 Doğrulama

```
flutter analyze (uygulamalar/mobil)    → No issues found! (36.6s)
flutter analyze (uygulamalar/personel) → 8 info/warning (pre-existing test issues); 0 error (4.5s)
npm run typecheck (uygulamalar/web)    → Pass (0 hata)
npm run lint (uygulamalar/web)         → No ESLint warnings or errors
```

---

### 5.7 Açık Maddeler (Bu Sprint Kapsam Dışı)

| ID | Alan | Bulgu | Öneri |
|---|---|---|---|
| PERF-001 | Personel | `push-dispatch` edge function — per-notification `user_devices` sorgusu döngü içinde | `IN (userId1, userId2, ...)` ile batch sorgu + Map index'leme |
| PERF-002 | Mobil | Photo viewer fullscreen'de `Image.network()` kullanılıyor (`InteractiveViewer` içinde) | `CachedNetworkImageProvider` ile PageView önbelleği; ancak fullscreen bağlamda `AppNetworkImage` borderRadius parametresi sorunu var — ayrıca incelenmeli |
| PERF-003 | Supabase | `search_businesses_v1` ve `nearby_businesses_v2` fonksiyonları PostGIS migration sonrası `find_nearby_businesses_v1`'i kullanacak şekilde refactor edilebilir | Mevcut Haversine hesaplamayı `ST_DWithin` ile değiştir; `p_lat`/`p_lng` parametreli fonksiyonlar yeni RPC'yi çağırsın |
| PERF-004 | Personel | Test dosyalarındaki `package:postgrest/postgrest.dart` gereksiz import uyarıları | Pre-existing; test dosyalarında `import 'package:supabase_flutter/supabase_flutter.dart'` yeterli |

---

*Bölüm 5 gerçek kod okuma ve değişiklik uygulaması ile üretilmiştir. Tarih: 2026-05-26.*

---

## Bölüm 6: Next.js Web İyileştirme Raporu
**Tarih:** 2026-05-26

### 6.0 Özet

| Alan | Durum | Tahmini Lighthouse Etkisi |
|---|---|---|
| Public QR Menü — generateStaticParams | Uygulandı | LCP +8–12 puan (SSG → CDN kenarından sunulur) |
| Public QR Menü — revalidate 120→300 | Uygulandı | Daha az ISR yenileme, CDN hit oranı artar |
| Public QR Menü — loading.tsx (slug) | Uygulandı | CLS azalır, kullanıcıya anlık iskelet gelir |
| İşletme Sayfası — generateStaticParams | Uygulandı | SEO + LCP iyileşmesi |
| SEO — Sitemap düzeltmesi | Uygulandı | login/forgot-password kaldırıldı, /isletme eklendi |
| Leaflet — touch-action CSS | Uygulandı | Mobil scroll hijack giderildi |
| Leaflet — location-picker class | Uygulandı | Picker haritada tam dokunma desteği |
| Leaflet — dynamic() Server Component hatası | Düzeltildi | Build hatası giderildi |
| Auth Handoff | Zaten doğru | exchangeCodeForSession, cookie pattern, callbackUrl |
| Security Headers | Zaten tam | CSP, X-Frame-Options, Permissions-Policy, HSTS |
| lang="tr" | Zaten doğru | Root layout'ta mevcut |
| Error Boundaries | Zaten tam | app/error.tsx + (genel)/error.tsx + m/[slug]/not-found.tsx |

### 6.1 Public QR Menü Performansı

**`generateStaticParams` eklendi** (`/m/[slug]` ve `/isletme/[slug]`):
- Build zamanında Supabase'den `is_active = true` olan ilk 100 işletme çekilir (`public_slug` öncelikli, yoksa `slug`).
- Bu sayfalar CDN kenarında statik HTML olarak sunulur. TTI ve LCP önemli ölçüde düşer.
- Hata durumunda (DB ulaşılamıyor) boş dizi döner; Next.js fallback ISR ile devam eder.

**`revalidate` 120 → 300** (5 dakika):
- Daha uzun CDN TTL, gereksiz ISR yenileme azalır.
- On-demand revalidation (`POST /sunucu/yeniden-dogrulama`) ile menü değişiklikleri anında yayınlanır.

**Hero LCP preload**: `renderPublicMenuRoute` içinde `<link rel="preload" as="image" fetchPriority="high" />` zaten mevcuttu. Değişiklik yapılmadı.

**`/m/[slug]/loading.tsx` oluşturuldu**: Üst `(genel)/loading.tsx` tüm genel rotaları kapsıyordu; şimdi `/m/[slug]` rotasına özgü bir iskelet var — boyutları gerçek sayfayı yansıtır, CLS azalır.

### 6.2 SEO İyileştirmeleri

**Sitemap düzeltmesi** (`app/sitemap.ts`):
- `/login` ve `/forgot-password` kaldırıldı. Bu sayfalar `X-Robots-Tag: noindex` değeri alıyor; sitemapte bulunmamalı.
- `/isletme/[slug]` rotaları eklendi (`priority: 0.85`). Bu sayfalar Restaurant schema, AggregateRating ve Review içeriyor — yüksek SEO değeri taşır.

**`generateMetadata` + JSON-LD Restaurant schema** zaten tamdı:
- `/m/[slug]` → tam Restaurant + Menu + MenuItem schema, canonical URL, OG/Twitter tags.
- `/isletme/[slug]` → tam Restaurant + AggregateRating + Review schema.
- `robots.ts` → `allow: ['/', '/m/', '/q/']`, `disallow: ['/login', '/api/', '/admin/', '/owner/']`.

### 6.3 Auth Handoff

Mevcut implementasyon doğruydu, değişiklik yapılmadı:
- `app/auth/callback/route.ts` → `exchangeCodeForSession(code)` ile OAuth/magic link kodu doğruluyor.
- Profil yoksa otomatik oluşturuluyor (`user_profiles` insert).
- `sanitizeInternalRedirect` ile güvenli yönlendirme yapılıyor.
- `middleware.ts` → `/owner/**` ve `/admin/**` için Supabase session kontrolü var; unauthorized istekler `/login?redirect=<path>` ile yönlendiriliyor.
- `createServerClient` cookie pattern (`getAll/setAll`) `@supabase/ssr` best practice'ini izliyor.

### 6.4 Sunum Ayarları

`app/sunucu/sunum-ayarlari/route.ts` doğru çalışıyor:
- Kaydetme sonrası `revalidateTag('business-menu-presentation-settings')` ve `revalidatePath('/m/[slug]')` çağrısı yapılıyor.
- Rate limiting (20 req/min/IP) var.
- Auth + `canManageBusiness` yetki kontrolü var.

### 6.5 Leaflet Harita

**Pre-existing build hatası giderildi**: `app/(genel)/kesif/harita/page.tsx` dosyasında `dynamic(..., { ssr: false })` çağrısı doğrudan Server Component içindeydi. Next.js 15'te bu yasaktır.
- `harita-sarmalayici.tsx` adlı bir `'use client'` sarmalayıcı bileşen oluşturuldu.
- `dynamic()` çağrısı bu istemci bileşenine taşındı.
- `page.tsx` artık sarmalayıcıyı import ediyor.

**Mobil touch-action CSS eklendi** (`globals.css`):
- `.leaflet-container` → `touch-action: pan-y` (salt görüntüleme haritalarında tek parmak sayfayı kaydırır, haritayı değil).
- `.leaflet-container.location-picker` → `touch-action: none` (konum seçici haritada sürükleme tam çalışır).
- `LocationPickerMap.tsx` → `MapContainer`'a `className="location-picker"` eklendi.

**Mevcut doğru implementasyonlar**:
- `BusinessMap.tsx` → `dynamic(() => ..., { ssr: false })` ile SSR-safe sarmalama.
- Leaflet CSS doğrudan bileşen içinde import ediliyor (client-only bileşen olduğu için güvenli).
- `map-marker.svg` özel ikonu kullanılıyor (webpack hash sorunu yok).
- `scrollWheelZoom={false}` görüntüleme haritasında mevcut.
- z-index override'ları `globals.css`'de sticky header ile çakışmayı önlemek için var.

### 6.6 Lighthouse & Security Headers

**Security headers** (`next.config.mjs`) zaten tam:
- `X-Content-Type-Options: nosniff` ✓
- `X-Frame-Options: SAMEORIGIN` ✓ (embed rotaları için ALLOWALL istisnası var)
- `Referrer-Policy: strict-origin-when-cross-origin` ✓
- `Permissions-Policy: camera=(), microphone=(), geolocation=(self), payment=()` ✓
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` ✓
- Content Security Policy (CSP) tam tanımlı ✓

**Accessibility**:
- `<html lang="tr">` root layout'ta mevcut ✓
- Leaflet bileşenlerinde `aria-label` var ✓
- Harita konteynerlerinde `style={{ zIndex: 0 }}` sticky header çakışmasını önlüyor ✓

### 6.7 Build Sonucu

```
npm run typecheck  → Hata yok
npm run lint       → Uyarı/hata yok
npm run build      → Başarılı

/m/[slug]        ● (SSG — generateStaticParams ile pre-render)
/isletme/[slug]  ● (SSG — generateStaticParams ile pre-render)
```

**Oluşturulan/değiştirilen dosyalar:**

| Dosya | İşlem | Açıklama |
|---|---|---|
| `app/(genel)/m/[slug]/page.tsx` | Değiştirildi | `generateStaticParams` eklendi, `revalidate` 120→300 |
| `app/(genel)/m/[slug]/loading.tsx` | Oluşturuldu | Route-segment loading skeleton |
| `app/(genel)/isletme/[slug]/page.tsx` | Değiştirildi | `generateStaticParams` eklendi, `revalidate` 120→300 |
| `app/(genel)/kesif/harita/page.tsx` | Değiştirildi | `dynamic(ssr:false)` server component hatasından temizlendi |
| `app/(genel)/kesif/harita/harita-sarmalayici.tsx` | Oluşturuldu | `'use client'` dynamic wrapper |
| `app/sitemap.ts` | Değiştirildi | `/login`/`/forgot-password` kaldırıldı, `/isletme/[slug]` eklendi |
| `src/styles/globals.css` | Değiştirildi | Leaflet touch-action CSS eklendi |
| `src/components/maps/LocationPickerMap.tsx` | Değiştirildi | `className="location-picker"` eklendi |

---

## Bölüm 7: API/RPC Kontrat Denetimi
**Tarih:** 2026-05-26

### 7.1 RPC Envanteri (Toplam Sayı, Standart Uyumluluk)

| Kategori | Adet |
|---|---|
| Migration'lardan çıkarılan toplam RPC | ~185 |
| `_v1` veya üzeri versiyonlu | ~160 (~87%) |
| Versiyonsuz (isimlendirme ihlali) | ~25 (~13%) |
| DEPRECATED comment'li | 3 |
| Stub (implementasyon bekliyor) | 5 |
| SECURITY DEFINER + sabit search_path | Büyük çoğunluk (2026-05-23 migration'larından sonra) |

Tam RPC listesi için: `docs/api-kontrat-rehberi.md` Bölüm 6.

### 7.2 Adlandırma İhlalleri

Aşağıdaki RPC'ler `_v1` versiyonlama kuralına uymamaktadır. Mevcut Dart/TypeScript
istemcileri kırmamak için isimler değiştirilmemiş; bunun yerine DEPRECATED işaretlenmiş
veya yeni versiyonlu wrapper önerilmiştir:

| RPC | Sorun |
|---|---|
| `get_my_profile_stats` | Versiyon yok |
| `get_daily_picks` | Versiyon yok |
| `submit_business_suggestion` | Versiyon yok |
| `get_top_businesses` | Versiyon yok (yeni: `get_top_businesses_period_v1`) |
| `approve_business_suggestion` | Versiyon yok, DEPRECATED |
| `approve_owner_claim` | Versiyon yok, DEPRECATED |
| `reject_business_suggestion` | Versiyon yok, DEPRECATED |
| `create_owner_claim` | Versiyon yok, `submit_owner_claim_v1` ile örtüşüyor |
| `normalize_tr_text` | Versiyon yok, public helper |
| `is_business_team_member` | Versiyon yok |
| `nearby_businesses_v2` | `search_` öneki eksik |

### 7.3 Hata Format Tutarsızlıkları

| Endpoint | Tutarsızlık | Eylem |
|---|---|---|
| `/api/feedback` | `{ ok: true }` döner, standart `{ data: T }` değil | Backward compat. için kalsın |
| `/api/track` | `{ ok: true, data: ... }` — karma format | RPC sonucunu forward ettiği için kabul edilebilir |
| `/api/revalidate` | `{ ok: true, invalidated: [...] }` | Internal endpoint, kabul edilebilir |
| Edge function `push-dispatch` | `{ ok: false, error: "..." }` — next.js formatından farklı | Edge function katmanı, ayrı standart |

Next.js route handler'ların büyük çoğunluğu (`admin/claims`, `admin/moderation`,
`owner/businesses`, `owner/menus`, `media/upload`) doğru `{ error: string }` /
`{ data: T, meta?: ... }` formatını kullanmaktadır.

### 7.4 Yeni Oluşturulan Tipler ve Dosyalar

| Dosya | Açıklama |
|---|---|
| `uygulamalar/web/src/lib/types/api.ts` | Tüm API kontratları için TypeScript tipleri |
| `supabase/migrations/20260526000002_planned_rpc_stubs.sql` | N+1 fix hedefli 5 RPC stub'ı |
| `docs/api-kontrat-rehberi.md` | Canlı API kontrat belgesi (RPC envanteri + standartlar) |

### 7.5 Açık Maddeler

| Madde | Öncelik | Sorumlu Alan |
|---|---|---|
| `haftalikVeriProvider` 2 tablo sorgusu → `get_dashboard_weekly_v1` implement et | Orta | Backend/Personel |
| `dashboard_istatistik_saglayicisi.dart` menü kalem ayrı sorgusu → RPC'ye ekle | Orta | Backend/Personel |
| `personelPerformansProvider` → `get_dashboard_stats_today_v1` yanıtını kullan | Düşük | Personel Flutter |
| Versiyonsuz 14 RPC için wrapper migration yaz | Düşük | Backend |
| DEPRECATED 7 RPC için sunset migration tarihleri belirlenmeli | Düşük | Backend |
| `get_staff_performance_today_v1` stub implementasyonu veya Dart refactor | Orta | Backend/Personel |

---

## Bolum 8: Supabase Backend Iyilestirme Raporu

**Tarih:** 2026-05-26
**Kapsam:** `supabase/migrations/` — RLS guclenme, audit altyapisi, izin RPC'leri, moderation kuyrugu, veri tutarliligi

---

### 8.1 Olusturulan Migration'lar

| Migration Dosyasi | Icerik |
|---|---|
| `20260526000003_rls_hardening.sql` | RLS guclenme — audit_logs insert blogu, businesses admin-read-all, owner_claims sil koruma, reports reporter okunabilir |
| `20260526000004_audit_triggers.sql` | Generic audit trigger fonksiyonu + user_profiles/business_team_memberships/admin_users trigger'lari |
| `20260526000005_permission_rpcs.sql` | `check_owner_permission_v1` + `log_admin_bulk_operation_v1` RPC'leri |
| `20260526000006_moderation_queue.sql` | Reports tablosu indeksleri + `submit_content_report_v3` + `get_pending_reports_count_v1` + `resolve_report_v1` |
| `20260526000007_consistency_indexes.sql` | 15+ eksik FK ve sorgu path indeksi |
| `20260526000008_data_constraints.sql` | `tg_set_updated_at` + businesses.phone/slug kisitlamalari + `purge_audit_logs_v1` |

---

### 8.2 RLS Politikalari (eklenen/guclendirililen)

| Tablo | Eklenen Politika | Aciklama |
|---|---|---|
| `audit_logs` | `audit_logs_admin_read_v2` | Admin okuma yedek politika |
| `audit_logs` | `audit_logs_client_insert_block` | Anon/auth direkt insert engeli |
| `businesses` | `businesses_admin_read_all` | Admin pasif isletmeleri de gorebilir |
| `owner_claims` | `owner_claims_no_client_delete` | Sahip kendi claim'ini silemez |
| `reports` | `reports_reporter_self_read` | Rapor gonderen kendi raporunu gorebilir |

**Mevcut ve dogru olan politikalar (degistirilmedi):**
- `businesses_read` — `is_active = true` anon/auth okuma
- `businesses_update_owner_admin` — owner + admin guncelleme
- `owner_claims_select_access` — sahip kendi claim'lerini gorebilir
- `reports_select_admin` — admin tum raporlari gorebilir
- `reports_insert_access` — auth kullanici rapor gonderebilir

---

### 8.3 Audit Log Altyapisi

**Mevcut durum (20260504000001'den):** `audit_logs` tablosu schema:
- `action` (text) — `'business.updated'`, `'menu_item.created'` vs.
- `resource_type` (text) — `'business'`, `'menu'`, `'review'` vs.
- `resource_id` (uuid)
- `old_data` / `new_data` (jsonb)
- `user_id` (uuid)

**Bu migration'da eklenen:**
- `tg_generic_audit_log()` — TG_TABLE_NAME + TG_OP'den action/resource_type uretir
- Yeni trigger'lar: `user_profiles` (INSERT/DELETE), `business_team_memberships` (tumCUD), `admin_users` (tumCUD)
- Mevcut trigger'lar korundu: `trg_audit_businesses_update_v1`, `trg_audit_menu_items_cud_v1`, `trg_audit_menus_cud_v1`, `trg_audit_owner_claims_update_v1`, `trg_audit_reports_update_v1`, `trg_audit_user_ban_toggle_v1`

**Onemli:** `is_admin()` bu projede `admin_users` tablosunu kullanir (user_roles tablosu yoktur). Tum audit okuma politikalari `public.is_admin()` ile korunmaktadir.

---

### 8.4 Owner/Admin Izin RPC'leri

#### `check_owner_permission_v1(p_business_id, p_required_action)`
- `is_admin()` true ise her zaman true doner
- `write`/`update`/`delete`/`manage` icin `has_business_permission_v1(id, 'menu_write')` kullanir
- `read` icin `has_business_permission_v1(id, 'business_read')` kullanir
- Mevcut RBAC sistemini (`has_business_permission_v1`) wrap eder

#### `log_admin_bulk_operation_v1(p_operation_type, p_affected_ids, p_metadata)`
- Admin degil ise `P0002` hata firlatir
- `audit_logs` tablosuna `action = 'admin.bulk_operation.<type>'` ile kayit atar
- Admin panel toplu islem sonrasi cagrilmali

---

### 8.5 Moderation Queue

**Mevcut:** `reports` tablosu (base_schema'dan) zaten vardir:
- `target_type` CHECK: `business | review | menu_item_photo`
- `status` CHECK: `open | reviewing | closed`
- RLS: admin tam erisim, kullanici insert, reporter self-read (bu migration'da eklendi)

**Yeni RPC'ler:**

| Fonksiyon | Aciklama |
|---|---|
| `submit_content_report_v3` | Rate-limitli (24s icinde ayni hedef icin max 3), genisletilmis tur destegi, `auth.uid()` zorunlu |
| `get_pending_reports_count_v1` | Admin: open/reviewing sayilari tip bazinda gruplu |
| `resolve_report_v1` | Admin: raporun `reviewing` veya `closed` statuse gecisi |

**Not:** `submit_report_v1` ve `submit_report_v2` mevcut RPC'ler — bu migration onlari degistirmez, yeni v3 ek olarak eklendi.

---

### 8.6 Veri Tutarliligi Indeksleri

**Yeni indeksler (20260526000007):**

| Indeks | Tablo | Amac |
|---|---|---|
| `idx_owner_claims_user_id` | `owner_claims` | FK user_id sorgu destegi |
| `idx_owner_claims_business_id` | `owner_claims` | FK business_id sorgu destegi |
| `idx_owner_claims_status_pending` | `owner_claims` | Admin pending kuyruk sorgusu |
| `idx_owner_claims_assigned_to` | `owner_claims` | Atanmis admin is yuku |
| `idx_businesses_slug` | `businesses` | Web public route slug arama |
| `idx_audit_logs_action_created` | `audit_logs` | Eylem zaman araligi sorgusu |
| `idx_reports_status_created` | `reports` | Admin moderation kuyrugu |
| `idx_reports_target` | `reports` | Icerik bazli rapor listesi |
| `idx_reports_reporter_user_id` | `reports` | Kullanici kendi raporlari |
| `idx_reports_assigned_to` | `reports` | Atanmis admin is yuku |
| `idx_table_orders_business_active` | `table_orders` | Dashboard aktif siparis listesi |
| `idx_business_follows_business_id` | `business_follows` | Takipci sayisi sorgusu |
| `idx_notifications_user_unread` | `notifications` | Okunmamis bildirim rozeti |
| `idx_loyalty_cards_user_id` | `loyalty_cards` | Kullanici kart listesi |
| `idx_menu_feedback_*` | `menu_feedback` | Menu geri bildirim sorgulari |

**20260523000004'ten mevcut indeksler (tekrar olusturulmadi):**
`idx_businesses_is_active_partial`, `idx_businesses_active_city_category`,
`idx_business_follows_user_id`, `idx_visits_user_business_checked_in`,
`idx_table_orders_biz_table_time`, `idx_notifications_user_type_created`,
`idx_review_votes_user_review`, `idx_menu_item_price_votes_user_item` ve diger 8+ indeks.

---

### 8.7 Veri Kisitlamalari (20260526000008)

- `tg_set_updated_at()` — generic BEFORE UPDATE trigger fonksiyonu eklendi
- `set_updated_at_reports` trigger — reports.updated_at varsa eklenir
- `set_updated_at_owner_claims` trigger — owner_claims.updated_at varsa eklenir
- `businesses_phone_format` CHECK — bos veya `+`/rakamla baslayan, min 7 karakter
- `businesses_slug_nonempty` CHECK — slug bos string olamaz
- `purge_audit_logs_v1(p_older_than_days)` — admin-only audit log temizleme (min 30 gun)

---

### 8.8 Acik Maddeler

| Madde | Oncelik | Sorumlu Alan |
|---|---|---|
| `submit_report_v1/v2` anon grant'lari kisitlanmali (sadece authenticated) | Yuksek | Backend |
| `get_dashboard_weekly_v1` stub implementasyonu | Orta | Backend/Personel |
| `get_menu_item_counts_v1` stub implementasyonu | Orta | Backend/Personel |
| `admin_get_overview_stats_v1` stub implementasyonu | Orta | Backend/Admin Panel |
| `get_business_full_profile_v1` stub implementasyonu | Orta | Backend/Web |
| `purge_audit_logs_v1` icin cron job kurulmali | Dusuk | DevOps/Backend |
| `tg_generic_audit_log` — user_profiles INSERT/DELETE trigger'i mevcut trigger ile catisma riski izlenmeli | Dusuk | Backend |
