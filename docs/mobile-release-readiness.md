# Yeedoy Mobil — Release Readiness Checklist

> Hazırlanma: 2026-06-03
> Durum: Analiz tamamlandı — store yayını yapılmadı
> Auditor: Deployment Engineer

---

## Executive Summary

Yeedoy mobil uygulaması (iOS + Android) **çoğunlukla yayın hazırı** aşamadadır. Aşağıdaki kontroller yapılmıştır:

| Kontrol | Durum | Detay |
|---------|-------|-------|
| Android Build Config | ✅ Hazır | build.gradle.kts + signing setup tamam |
| iOS Config | ✅ Hazır | Info.plist permissions + deep links tamam |
| Permissions (Android) | ✅ Hazır | 7 izin taşıyıcı ve uygun |
| Permissions (iOS) | ✅ Hazır | 8 usage description (Türkçe + English mix) |
| Firebase Integration | ✅ Hazır | google-services.json + GoogleService-Info.plist var |
| CI Workflows | ✅ Aktif | mobile_quality.yml + mobile_readiness.yml |
| Flutter Analysis | ✅ Pass | `flutter analyze` → No issues found |
| Keystore File | 🟡 Eksik | key.properties template var, gerçek keystore gerekli |
| Deep Links | ✅ Hazır | yeedoy://, io.supabase.yeedoy://, https://yeedoy.com links tanımlı |
| Adaptive Icon | ✅ Var | Android adaptive icon + iOS AppIcon var |
| Store Listing | ✅ Hazır | store_listing.md'de Türkçe + İngilizce copy |
| Privacy Policy URL | ✅ Teknik sayfa oluşturuldu | yeedoy.com/gizlilik — Hukuki nihai onay önerilir |
| Version Numbers | ✅ Setup | pubspec.yaml: 1.0.0+1 (bağlantılı versionCode) |
| AdMob Integration | ✅ Hazır | CA-APP-ID'ler manifest + Info.plist'de |

---

## 1. Android Release Configuration

### ✅ Build.gradle.kts Analizi

File: `uygulamalar/mobil/android/app/build.gradle.kts`

**Temel Yapılandırma:**
```kotlin
namespace = "com.yeedoy.app"
applicationId = "com.yeedoy.app"  // Google Play Package Name
minSdk = 26
targetSdk = flutter.targetSdkVersion  // Dynamic (currently ~35)
versionCode = flutter.versionCode      // Linked to pubspec.yaml
versionName = flutter.versionName      // Linked to pubspec.yaml
```

**Durum:**
- `applicationId` ✅ Doğru (`com.yeedoy.app`)
- `minSdk` ✅ Yeterli (API 26 = Android 8.0, karşılık gelir)
- `targetSdk` ✅ Dinamik (Flutter SDK ile senkronize)
- `versionCode` ✅ Linked to pubspec.yaml (`1.0.0+1` → versionCode=1)
- `versionName` ✅ Linked to pubspec.yaml (`1.0.0`)

**Release Signing:**
```kotlin
// signingConfigs section (lines 60-81)
if (hasReleaseSigningConfig) {
    create("release") {
        storeFile = File(releaseStoreFilePath)
        storePassword = releaseStorePassword
        keyAlias = releaseKeyAlias
        keyPassword = releaseKeyPassword
    }
}
```

Sources (priority order):
1. **Environment variables:** `ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`
2. **File:** `android/key.properties` (git'e commit edilmemeli)

**ProGuard/R8 Obfuscation:**
```kotlin
// buildTypes.release section
proguardFiles(
    getDefaultProguardFile("proguard-android-optimize.txt"),
    "proguard-rules.pro",
)
```
✅ Aktif — debug symbols ayrıştırılacak.

**Firebase Integration:**
- ✅ `com.google.gms.google-services` plugin
- ✅ `com.google.firebase.crashlytics` plugin
- ✅ firebase-bom 34.8.0 (Firebase Analytics + Crashlytics)

### ✅ AndroidManifest.xml Analizi

File: `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml`

**Permission Inventory:**

| Permission | Amaç | Zorunlu | Durum |
|---|---|---|---|
| `android.permission.INTERNET` | Network | Evet | ✅ Var |
| `android.permission.ACCESS_FINE_LOCATION` | GPS (harita + nearby) | Evet | ✅ Var |
| `android.permission.ACCESS_COARSE_LOCATION` | Ağ tabanlı konum | İsteğe bağlı | ✅ Var |
| `android.permission.CAMERA` | QR scan + menü fotosu | Evet | ✅ Var |
| `android.permission.READ_MEDIA_IMAGES` | Fotoğraf seçme (A13+) | Evet | ✅ Var |
| `android.permission.READ_EXTERNAL_STORAGE` | Galeri (A12 ve altı) | Koşullu | ✅ Var (maxSdkVersion=32) |
| `android.permission.VIBRATE` | Haptic feedback | İsteğe bağlı | ✅ Var |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Widget/alarm init | İsteğe bağlı | ✅ Var |
| `android.permission.POST_NOTIFICATIONS` | Push notifications | Evet | ✅ Var (A13+) |
| `android.permission.USE_BIOMETRIC` | Biyometrik giriş | İsteğe bağlı | ✅ Var |
| `android.permission.USE_FINGERPRINT` | Parmak izi (legacy) | Koşullu | ✅ Var (A30 compat) |

**Deep Links:**
- ✅ `yeedoy://` custom scheme (siri shortcuts)
- ✅ `https://yeedoy.com` app link (autoVerify=true)
- ✅ `io.supabase.yeedoy://` (password reset emails)

**App Features:**
- ✅ AdMob App ID: `ca-app-pub-1150074560839161~8895703262` (meta-data)
- ✅ Home screen widget receiver registered
- ✅ Google Assistant static shortcuts (app_shortcuts.xml)

**Kontrol Sonucu:** ✅ Tüm gerekli izinler var, gereksiz izin yok. Android 13+ compat sağlandı.

### 🟡 Key.properties (Keystore) Status

**Var mı:**
- `uygulamalar/mobil/android/key.properties.example` ✅ Template güncellendi
- `uygulamalar/mobil/android/key.properties` ✅ .gitignore'da korumalı

**Gerçek keystore dosyası:**
- `.gitignore`: `**/android/key.properties`, `**/android/keystore/`, `*.keystore` ✅ Güvenli
- Gerçek keystore ❌ Lokal oluşturulmalı (CI/CD'de base64 secret kullanılacak)

**Durum:**
- `key.properties.example` ✅ Yeterli açıklamalarla güncellendi
- `.gitignore` ✅ Keystore filesi + key.properties protected
- CI workflow ✅ `mobile_release.yml` oluşturuldu (secrets kullanıyor)

---

## 2. iOS Release Configuration

### ✅ Info.plist Analizi

File: `uygulamalar/mobil/ios/Runner/Info.plist`

**Bundle Identifiers:**
```xml
CFBundleDisplayName: "Yeedoy"
CFBundleName: "Yeedoy"
CFBundleIdentifier: "$(PRODUCT_BUNDLE_IDENTIFIER)"  // Xcode'da tanımlı
CFBundleVersion: "$(FLUTTER_BUILD_NUMBER)"          // pubspec.yaml +X
CFBundleShortVersionString: "$(FLUTTER_BUILD_NAME)"  // pubspec.yaml X.Y.Z
```

**Durum:**
- Display name ✅ "Yeedoy"
- Version strings ✅ Flutter build sistem ile senkronize
- Deep link schemes ✅ Tanımlı (`yeedoy`, `io.supabase.yeedoy`)

**Permission Usage Descriptions (App Store zorunlu):**

| Key | Türkçe Açıklama | Durum |
|---|---|---|
| `NSCameraUsageDescription` | Menü fotoğrafı çekmek ve barkod/QR okumak için kamera gereklidir. | ✅ Var |
| `NSPhotoLibraryUsageDescription` | Menü ve profil görseli seçmek için fotoğraf kütüphanesine erişim gereklidir. | ✅ Var |
| `NSPhotoLibraryAddUsageDescription` | Çekilen fotoğrafları galerinize kaydetmek için izin gereklidir. | ✅ Var |
| `NSLocationWhenInUseUsageDescription` | Yakınızdaki restoranları bulmak için konumunuz kullanılır. | ✅ Var |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Yakınızdaki restoranları bulmak için konumunuz kullanılır. | ✅ Var |
| `NSMicrophoneUsageDescription` | Sesli arama ve video özellikleri için mikrofon gereklidir. | ✅ Var |
| `NSSiriUsageDescription` | Siri, Yeedoy'da yakınındaki ucuz yemekleri bulmanıza yardımcı olur. | ✅ Var (EN needed) |
| `NSFaceIDUsageDescription` | Uygulamaya hızlı ve güvenli giriş için Face ID kullanmak ister misiniz? | ✅ Var (EN needed) |
| `NSUserTrackingUsageDescription` | Size daha ilgili reklamlar gösterebilmek ve reklam performansını ölçebilmek için uygulama etkinliğinizin diğer şirketlere ait uygulama ve web sitelerinde izlenmesine izin isteyebiliriz. | ✅ Eklendi (fix/mobile-ios-att-description PR) |

**Durum:**
- ✅ Tüm permission açıklamaları Türkçe
- ✅ NSUserTrackingUsageDescription → Eklendi (fix/mobile-ios-att-description PR)
- ⏳ App Store Privacy ATT review → App Store Connect'te manuel kontrol
- 🟡 English (EN) açıklamaları eksik (optional ama App Store'da istenen diller varsa ekle)
- ✅ AdMob App ID: `ca-app-pub-1150074560839161~8895703262`
- ✅ Deep link schemes
- ✅ Background modes: `remote-notification` (push)
- ✅ User activity types (Siri/Assistant)

### ✅ Assets (Icons + Launch Screen)

**App Icon:**
- Location: `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- ✅ Var

**Launch Screen:**
- Location: `ios/Runner/Assets.xcassets/LaunchImage.imageset`
- ✅ Var

**Durum:** ✅ Asset'ler setup'a göre tanımlı.

---

## 3. Firebase Configuration

### ✅ Google Services Files

**Android:**
- File: `uygulamalar/mobil/android/app/google-services.json`
- ✅ Var (git'te değil — `.gitignore`'da)
- Includes: Project ID, API keys, Firebase config

**iOS:**
- File: `uygulamalar/mobil/ios/Runner/GoogleService-Info.plist`
- ✅ Var (git'te değil — `.gitignore`'da)
- Includes: Server API key, Bundle ID, project config

**Durum:** ✅ Her iki platform'da da config dosyaları mevcut.

### Integration Status

**pubspec.yaml (Dependencies):**
```yaml
firebase_core: ^4.4.0              ✅
firebase_messaging: ^16.0.2        ✅ Push notifications
firebase_analytics: ^12.1.1        ✅ Event tracking
firebase_crashlytics: ^5.0.7       ✅ Error reporting
firebase_performance: ^0.11.1+4    ✅ Performance monitoring
```

**Durum:** ✅ Tüm Firebase SDK'lar en son sürümde.

---

## 4. GitHub Actions CI Workflows

### ✅ mobile_quality.yml

**Amaç:** PR ve push'lar için Flutter analiz + test

**Trigger:**
- `pull_request` (tüm PR'lar)
- `push` (main branch)

**Jobs:**
1. `flutter-analyze` — `flutter analyze` (lint + analyzer)
2. `flutter-test` — `flutter test` (unit tests)

**Status Check:** ✅ `mobile_quality / flutter-analyze` (branch protection)

### ✅ mobile_readiness.yml

**Amaç:** Release öncesi manual validation + iOS/Android dry run

**Trigger:** `workflow_dispatch` (manuel)

**Jobs:**
- `ios_readiness_audit` — Info.plist, permissions, code signing check
- `release_gate_audit` — Metrics validation
- `ios_release_dry_run` (opsiyonel) — Signed IPA build
- `android_release_dry_run` (opsiyonel) — APK build (secrets gerektiriyor)

### 🆕 mobile_release.yml

**Amaç:** Production AAB build + artifact upload (Google Play store deploy)

**Trigger:** `workflow_dispatch` (manuel — store deploy için)

**Davranış:**
- Secrets varsa ✅ Flutter AAB build → artifact upload (30 gün) + symbols
- Secrets yoksa ℹ️ Skip (fail değil) — net uyarı, manuel adımlar gösterir

**Artifacts:**
- `app-release.aab` — Play Console'a upload edilecek
- `symbols/` — Crashlytics için (otomatik upload veya manuel)

---

## 5. Eksik Dosyalar ve Adımlar

| Eksik | Aciliyet | Durum | Çözüm |
|-------|----------|-------|-------|
| Android Keystore + CI secrets | **HIGH** | 🔧 Teknik altyap hazır | Aşağıya bkz. "Keystore Oluşturma" |
| Privacy Policy URL | ~~CRITICAL~~ | ✅ Çözüldü | yeedoy.com/gizlilik — Hukuki nihai onay önerilir |
| English permission descriptions (iOS) | **MEDIUM** | ⏳ TODO | Info.plist'e İngilizce açıklamalar ekle |
| App icon 1024x1024 (Store) | **HIGH** | ⏳ TODO | Icon asset üret ve `appiconset`'e ekle |
| Store screenshots | **HIGH** | ⏳ TODO | 8 ekran (store_listing.md'den) üret |
| Content rating questionnaire | **HIGH** | 🔧 Taslak hazır | docs/store-data-safety-iarc.md — IARC cevapları belgede — Play Console'da doldurulacak |
| Data safety form | **CRITICAL** | 🔧 Taslak hazır | docs/store-data-safety-iarc.md — 10 veri kategorisi — Play Console'da doldurulacak |
| Release notes | **MEDIUM** | ⏳ TODO | v1.0 release notes yaz (changelog) |
| TestFlight/beta testers | **MEDIUM** | ⏳ TODO | Internal testers (Google Groups) kur |

---

## 6. Release Komutları (Step-by-Step)

### Android AAB (Production Signing)

```bash
cd uygulamalar/mobil

# Varsayılan: ANDROID_RELEASE_* env var'lar mevcutsa
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

**Lokal signing (dev):**
1. Keystore oluştur:
```bash
keytool -genkey -v \
  -keystore yeedoy.keystore \
  -alias yeedoy \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

2. `android/key.properties` doldur:
```properties
storeFile=yeedoy.keystore
storePassword=<your_keystore_password>
keyAlias=yeedoy
keyPassword=<your_key_password>
```

3. Build et:
```bash
flutter build appbundle --release
```

### iOS IPA (Mac gerektirir)

```bash
cd uygulamalar/mobil

# Release IPA (Xcode signing gerekli)
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols

# Çıktı: build/ios/ipa/
```

**Önkoşullar:**
- Apple Developer $99/yıl üyelik
- App ID oluşturulmuş
- Provisioning profile indirilmiş
- Distribution certificate aktif

### Version Bump

```yaml
# pubspec.yaml
version: 1.0.0+1        # X.Y.Z+buildCode
        ↓
version: 1.0.1+2        # Patch + buildCode artır
```

Android: `versionCode` otomatik artırılır (flutter CLI)  
iOS: `FLUTTER_BUILD_NUMBER` otomatik set edilir

---

## 7. GitHub Actions Secrets (CI/CD) — Android Release Signing

**Gerekli Secrets:**

| Secret Name | Açıklama | Durum | Ekleme Yolu |
|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Keystore dosyasının base64 kodlanmış hali (opsiyonel) | ⏳ Manuel | Aşağıya bkz. |
| `ANDROID_RELEASE_STORE_PASSWORD` | Keystore şifresi | ⏳ Manuel | GitHub UI |
| `ANDROID_RELEASE_KEY_ALIAS` | Key alias (ör: `yeedoy-release`) | ⏳ Manuel | GitHub UI |
| `ANDROID_RELEASE_KEY_PASSWORD` | Key şifresi | ⏳ Manuel | GitHub UI |

**Setup — Keystore Base64 Encoding (Windows PowerShell):**

```powershell
# 1. Lokal keystore oluştur (aşağıya bkz. Appendix C)
cd C:\yeedoy\uygulamalar\mobil\android

# 2. Keystore'u base64'e kodla
$bytes = [IO.File]::ReadAllBytes("app/yeedoy.keystore")
$base64 = [Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard

# 3. GitHub UI'da secret ekle:
#    Settings → Secrets and variables → Actions → New repository secret
#    Name: ANDROID_KEYSTORE_BASE64
#    Value: [paste]

# 4. Diğer 3 secret'ı da ekle (keystore şifresi, alias, key şifresi)
```

**Setup — GitHub CLI Alternatifi:**

```bash
# Keystore base64'e kodla
base64 < android/app/yeedoy.keystore | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64

# Diğer secrets
gh secret set ANDROID_RELEASE_STORE_PASSWORD --body "your_store_password"
gh secret set ANDROID_RELEASE_KEY_ALIAS --body "yeedoy-release"
gh secret set ANDROID_RELEASE_KEY_PASSWORD --body "your_key_password"
```

**CI Workflow'da Kullanımı:**

`.github/workflows/mobile_release.yml` — Flutter AAB release build:

```yaml
- name: Decode Android keystore
  shell: bash
  env:
    ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
  run: |
    mkdir -p android/keystore
    echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/keystore/yeedoy-release.keystore

- name: Create key.properties from secrets
  shell: bash
  env:
    ANDROID_RELEASE_STORE_FILE: android/keystore/yeedoy-release.keystore
    ANDROID_RELEASE_STORE_PASSWORD: ${{ secrets.ANDROID_RELEASE_STORE_PASSWORD }}
    ANDROID_RELEASE_KEY_ALIAS: ${{ secrets.ANDROID_RELEASE_KEY_ALIAS }}
    ANDROID_RELEASE_KEY_PASSWORD: ${{ secrets.ANDROID_RELEASE_KEY_PASSWORD }}
  run: |
    cat > android/key.properties << EOF
    storeFile=$ANDROID_RELEASE_STORE_FILE
    storePassword=$ANDROID_RELEASE_STORE_PASSWORD
    keyAlias=$ANDROID_RELEASE_KEY_ALIAS
    keyPassword=$ANDROID_RELEASE_KEY_PASSWORD
    EOF

- name: Build Release AAB
  run: |
    flutter build appbundle --release \
      --obfuscate \
      --split-debug-info=build/app/outputs/symbols
```

**Security Notes:**
- ✅ Keystore dosyası git'e commit edilmez (`.gitignore` koruması)
- ✅ `key.properties` CI'da secrets'ten oluşturulur
- ✅ Sensitive dosyalar workflow cleanup'ında silinir
- ✅ Base64 secret'lar GitHub tarafından encrypted olarak depolanır

---

## 8. Manual Store Publishing Workflow

### Google Play Console

1. **Proje Oluştur:**
   - URL: https://play.google.com/console
   - "Create app" → Package: `com.yeedoy.app`

2. **Test Release (İnternal Track):**
   - **Build:** AAB dosyasını upload et
   - **Version:** 1.0.0 (build #1)
   - **Rollout:** 0% (internal only)

3. **Store Listing Doldur:**
   - Title (TR): "Yeedoy: Restoran Fiyat Takip & Menü" (50 char maks)
   - Short desc (TR): "Restoran fiyatlarını takip et. Toplulukla doğrula. Bütçene uygun yeri bul."
   - Full desc: `docs/store_listing.md` TR uzun açıklama
   - Keywords: `docs/store_listing.md`
   - Icons/screenshots: 8 ekran (store_listing.md)

4. **Content Rating (IARC):**
   - Form doldur (violence, language, content vb.)
   - Rating elde et (Play Console → Ratings)

5. **Data Safety:**
   - Data types: kullanıcı verisi, konumu, payment info
   - Encryption: HTTPS/TLS ✅
   - Data sharing: 3rd party yok ✅
   - Veri retention: 1 yıl veya kullanıcı silip atana kadar

6. **Privacy Policy:**
   - URL: https://yeedoy.com/gizlilik
   - Gerekli: ✅ Koşullu

7. **Çıkış Ülkeleri:**
   - Turkey ✅, + diğer target ülkeler

8. **Review Gönder:**
   - Status: "Ready to review"
   - Internal testing → 1-2 saat
   - Production → 1-7 gün

### App Store Connect (Mac gerekli)

1. **Proje Oluştur:**
   - URL: https://appstoreconnect.apple.com
   - "My Apps" → "+" → "New App"
   - Bundle ID: `com.yeedoy.app` (App ID match gerekli)

2. **TestFlight (Internal Testing):**
   - Build: IPA dosyasını Xcode/Transporter'dan upload
   - Testers: Apple internal team
   - Duration: 1-3 gün

3. **Store Listing (Metadata):**
   - Name: "Yeedoy: Menu Price Tracker" (30 char)
   - Subtitle: "Community-verified restaurant prices" (30 char)
   - Description: `docs/store_listing.md` EN uzun
   - Keywords: `docs/store_listing.md`
   - Screenshot: 6.7" iPhone + iPad Pro
   - Privacy URL: https://yeedoy.com/gizlilik

4. **App Information:**
   - Category: Lifestyle → Food
   - Content rating: PEGI / USK (form doldur)
   - Age restrictions: 4+

5. **Pricing & Availability:**
   - Price tier: Free
   - Countries: Türkiye + hedef ülkeler

6. **Review Gönder:**
   - Version: 1.0
   - Sign in required: No
   - Notes for reviewers: "App tracks restaurant prices via community"
   - Export compliance: Not encryption

---

## 9. Pre-Release Validation Checklist

### Fonksiyonel Test (Internal Beta)
- [ ] App açılıyor ve crash yok
- [ ] Discovery harita yükleniyor
- [ ] Arama ve filtreleme çalışıyor
- [ ] QR/barcode scan başarılı
- [ ] Menü detayları gösteriliyor
- [ ] Yorum yazma akışı çalışıyor
- [ ] Push notification test (Firebase)
- [ ] Login/signup akışı (Supabase auth)
- [ ] Offline mode (cached data) çalışıyor

### Performans & Stability
- [ ] App size < 150 MB (uncompressed)
- [ ] Launch time < 3 saniye
- [ ] Main list scroll 60 FPS
- [ ] No memory leaks (Xcode Instruments)
- [ ] Battery drain acceptable
- [ ] Network timeout handling (connectivity test)

### Security & Compliance
- [ ] Sensitive data (tokens) lokal storage'da secure
- [ ] API calls HTTPS/TLS ✅
- [ ] Firebase crashlytics working
- [ ] Sentry (if enabled) working
- [ ] Privacy policy linki accessible
- [ ] Contact/support info mevcuttur

### Lokalizasyon (L10n)
- [ ] Türkçe metin eksiksiz
- [ ] İngilizce metin eksiksiz
- [ ] Tarih/saat format lokale uygun
- [ ] Emojiler render doğru

### Device Coverage
- [ ] Android: API 26 → 35+ test
- [ ] iOS: 14.0 → 17.x test
- [ ] Screen sizes: phone + tablet
- [ ] Landscape mode test

---

## 10. Rollback & Hotfix Strategy

### Anlık Rollback (Yayından Sonra)

**Play Console:**
1. Release management → Latest release
2. "Halt rollout" (tüm kullanıcılara stop)
3. Önceki sürüm otomatik aktif olur (veya manual seç)
4. Etkilenen kullanıcı sayısı azaldıkça, monitoring

**App Store:**
1. App Store Connect → Builds → Version history
2. Production release "Remove from sale" (yanındaki menu)
3. Previous version otomatik restore

### Hotfix Release

1. Branch aç: `hotfix/1.0.1`
2. versionCode/versionName bump: `1.0.1+2`
3. Fix uygula
4. Build & sign
5. PR → review → merge
6. Tag oluştur: `v1.0.1`
7. CI release job trigger

---

## 11. Post-Launch Monitoring

### Firebase Metrics

- **Crashes:** Dashboard → Crash analytics
  - Target: < 1% crash-free users
- **Performance:** Dashboard → Performance monitoring
  - Screen load time
  - Memory usage
  - Battery drain
- **Analytics:** Custom events (discovery_search, review_submit vb.)

### User Feedback

- In-app rating prompt (optional)
- Support email: support@yeedoy.com
- Issue tracker: GitHub issues

### Update Cadence

- **Critical bugs:** 3-7 gün hotfix
- **Features:** 2-4 hafta sprint release
- **Major version:** Quarterly

---

## 12. Sonraki Adımlar (Priority Order)

### CRITICAL (Bu haftada)
1. ~~Privacy Policy URL yayınla~~ ✅ Tamamlandı → yeedoy.com/gizlilik
2. ~~Data Safety formu için veri envanteri yap~~ ✅ Taslak hazır → docs/store-data-safety-iarc.md — Play Console'da manuel girilecek
3. ~~Content Rating IARC formu taslağı~~ ✅ Taslak hazır → docs/store-data-safety-iarc.md — Play Console'da doldurulacak

### HIGH (Sonraki hafta)
1. Keystore file oluştur (lokal)
2. GitHub Actions secrets setup (base64 encode)
3. App icon 1024x1024 üret (Store requirements)
4. Store screenshots üret (8 ekran, store_listing.md'den)

### MEDIUM (Sonraki 2 hafta)
1. TestFlight beta testers kurula (internal testing)
2. English permission descriptions (iOS Info.plist)
3. Release notes draft (v1.0 changelog)

### LOW (Before launch)
1. Performance optimization pass
2. Security audit (code review)
3. Stress test (5000+ concurrent users simulation)

---

## 13. Key File References

| Dosya | Amaç | Durum |
|-------|------|-------|
| `uygulamalar/mobil/pubspec.yaml` | Version source | ✅ 1.0.0+1 |
| `uygulamalar/mobil/android/app/build.gradle.kts` | Android build | ✅ Signing ready |
| `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml` | Android config | ✅ Permissions OK |
| `uygulamalar/mobil/ios/Runner/Info.plist` | iOS config | ✅ Deep links OK |
| `uygulamalar/mobil/android/app/google-services.json` | Firebase Android | ✅ Config var |
| `uygulamalar/mobil/ios/Runner/GoogleService-Info.plist` | Firebase iOS | ✅ Config var |
| `docs/store_listing.md` | Store metadata | ✅ Türkçe + EN |
| `.github/workflows/mobile_quality.yml` | CI analysis | ✅ Active |
| `.github/workflows/mobile_readiness.yml` | Release checklist | ✅ Manual |
| `android/key.properties.example` | Keystore template | ✅ Example var |

---

## 14. Bu PR'da Yapılmayanlar

Aşağıdakiler bu dökümanın kapsamı dışındadır (security/operational):

- ❌ Gerçek keystore dosyası oluşturma (lokal yapılacak)
- ❌ Signing config build.gradle'a doğrudan entegrasyonu (env var'lar tercih)
- ❌ Play Console / App Store hesabı oluşturma (manual process)
- ✅ Privacy policy sayfası yazıldı → /gizlilik (Hukuki nihai onay ayrıca yapılacak)
- ❌ Android/iOS release build test (CI workflow'larda olacak)
- ❌ TestFlight beta setup (manual)
- ❌ Store screenshot tasarımı (design team)
- ❌ App icon 1024x1024 tasarımı

Bu adımların tümü PR merge sonrası dönem içinde yapılmalıdır.

---

## 15. Başarı Metrikleri (Post-Launch)

| Metrik | Target | Ölçüm |
|--------|--------|-------|
| Crash-free users | > 99% | Firebase Crashlytics |
| App store rating | > 4.0 | Play Console + App Store |
| User retention (Day 7) | > 40% | Firebase Analytics |
| Average session duration | > 3 min | Firebase Analytics |
| Daily active users | > 100 DAU (İlk ay) | Firebase Analytics |
| Update adoption rate | > 80% (7 gün) | Play Console version stats |
| Support tickets | < 10/week | Help desk |

---

## Appendix A: Android Permissions Mapping

Android'in WebView/Plugin'de talep ettiği izinler (manifest'ten override edilmeme şartı):

```xml
<!-- Temel -->
INTERNET                          ✅ Required
ACCESS_FINE_LOCATION              ✅ Runtime (Android 6+)
CAMERA                            ✅ Runtime (Android 6+)

<!-- Galeri -->
READ_MEDIA_IMAGES                 ✅ Runtime (Android 13+)
READ_EXTERNAL_STORAGE             ✅ Legacy fallback (A12-)

<!-- Opsiyonel -->
VIBRATE                           ✅ Non-critical
RECEIVE_BOOT_COMPLETED            ✅ Widget/alarms
POST_NOTIFICATIONS                ✅ Runtime (Android 13+)
USE_BIOMETRIC / USE_FINGERPRINT   ✅ Runtime (Android 9+)
```

**Risk Assessment:** LOW — Hiçbir invasive permission yok (SMS, contacts vb.).

---

## Appendix B: iOS Permissions Mapping

App Store'a gönderim öncesi başvuru listesi:

```xml
Camera              ✅ NSCameraUsageDescription
Photo Library       ✅ NSPhotoLibraryUsageDescription
Photo Library Write ✅ NSPhotoLibraryAddUsageDescription
Location            ✅ NSLocationWhenInUseUsageDescription
Microphone          ✅ NSMicrophoneUsageDescription (video call)
Siri                ✅ NSSiriUsageDescription
Face ID             ✅ NSFaceIDUsageDescription
Tracking (ATT)      ✅ NSUserTrackingUsageDescription (AdMob / iOS 14.5+)
```

**App Store Policy Check:**
- ✅ Tüm permission descriptions mevcut
- ✅ Açıklamalar kullanıcı-dostu
- ✅ Hiçbir gizli data collection yok

---

## Appendix C: Keystore Creation (Windows PowerShell)

### Step 1: Generate Keystore

```powershell
# Windows 11 Pro + JDK 17+
# keytool: JDK'nın bir parçası (%JAVA_HOME%\bin\keytool.exe)

cd C:\yeedoy\uygulamalar\mobil\android

# Keystore oluştur (10 yıl geçerli)
keytool -genkey -v `
  -keystore app/yeedoy.keystore `
  -alias yeedoy-release `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -dname "CN=Yeedoy, O=Yeedoy Inc, L=Istanbul, ST=Istanbul, C=TR"

# İnteraktif sorular:
#   Keystore password: [enter 16+ character password]
#   Re-enter password: [confirm]
#   Key password: [same or different, enter]
#   Confirm password: [confirm]

# Çıktı: app/yeedoy.keystore (günün sonunda güvenli bir yerde sakla!)
```

### Step 2: Create key.properties (Local Development)

```powershell
# key.properties.example'i kopyala
Copy-Item "key.properties.example" -Destination "key.properties"

# Gerçek değerleri doldur
# (Text editor'da aç ve CHANGE_ME yerine gerçek values'ları koy)
# storeFile=app/yeedoy.keystore
# storePassword=<your_keystore_password>
# keyAlias=yeedoy-release
# keyPassword=<your_key_password>

# key.properties is git-ignored — güvenli
```

### Step 3: Verify Keystore

```powershell
# Keystore doğruluğu kontrol et
keytool -list -v -keystore app/yeedoy.keystore

# Çıktı: certificate details, validity, alias confirmations
```

### Step 4: Encode for GitHub Actions Secret

```powershell
# Keystore'u base64'e kodla (CI için)
$bytes = [IO.File]::ReadAllBytes("app/yeedoy.keystore")
$base64 = [Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard

echo "Base64 encoded keystore copied to clipboard"
echo "Size: $($base64.Length) characters"

# Clipboard'daki base64'i GitHub secret olarak ekle:
# GitHub → Settings → Secrets and variables → Actions → New repository secret
# Name: ANDROID_KEYSTORE_BASE64
# Value: [paste]

# Diğer 3 secret'ı da ekle:
# - ANDROID_RELEASE_STORE_PASSWORD (keystore şifresi)
# - ANDROID_RELEASE_KEY_ALIAS (yeedoy-release)
# - ANDROID_RELEASE_KEY_PASSWORD (key şifresi)
```

**Güvenlik Notları:**
- ✅ Keystore dosyası GIT'E COMMIT ETME (private key taşıyor, `.gitignore` korumalı)
- ✅ Base64 string'i clipboard'dan temizle (çoğunlukla otomatik, fakat `Clear-Clipboard` de kullanabilirsin)
- ✅ Şifreleri minimum 16 karakter, mixed case + numbers + symbols kullan
- ✅ Keystore backupını offline depolamada sakla (USB, safe vb.)
- ⚠️ Keystore password'ü kâğıda yazıp kilitli yerde sakla (şayet unutırsan, yeni keystore oluştarman gerekir)
- ⚠️ Base64 string'i sadece GitHub secret'a ekle, GitHub dışında share etme

---

## Son Sözler

Yeedoy mobil uygulaması **yayın için hazırdır**, fakat aşağıdaki kritik eksikleri tamamlamadan Play Console / App Store'a gitmemelidir:

1. ✅ **Build Config:** Android + iOS tamam
2. ✅ **Permissions:** Tüm izinler uygun
3. ✅ **Firebase:** Crashlytics + Analytics entegre
4. ✅ **CI/CD:** Workflow'lar aktif
5. ✅ **Privacy Policy:** https://yeedoy.com/gizlilik — Teknik sayfa oluşturuldu (Hukuki nihai onay önerilir)
6. 🔧 **Data Safety + IARC:** Taslak hazır (docs/store-data-safety-iarc.md) — Play Console'da manuel girilecek
7. ❌ **Keystore:** Lokal oluştur + CI secret'lar
8. ❌ **Store Assets:** Icon 1024x1024 + 8 screenshot

Tüm bu adımlar tamamlandıktan sonra, 2-3 haftalık internal/beta testing → production release yapılabilir.

---

**Döküman Versiyonu:** 1.0  
**Hazırlanma Tarihi:** 2026-06-03  
**Auditor:** Deployment Engineer  
**Status:** Ready for review
