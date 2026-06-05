# Yeedoy Mobil — Store Assets & Release Plan

> **Hazırlanma:** 2026-06-05  
> **Durum:** Kalan açık işler — yayın öncesi zorunlu aktiviteler  
> **Amaç:** App store asset gereksinimleri, screenshot senaryoları, release notes şablonu, internal testing checklist

---

## Özet: Mevcut Hazır Olanlar

Aşağıdakiler tamamlandı ve yayın için hazırlanmıştır:

| Kontrol | Durum | Detay |
|---------|-------|-------|
| Android Build Config | ✅ Hazır | build.gradle.kts + signing ready |
| iOS Config | ✅ Hazır | Info.plist permissions + deep links |
| Permissions (Android/iOS) | ✅ Hazır | 7 Android + 8 iOS izin taşıyıcı |
| Firebase Integration | ✅ Hazır | Crashlytics + Analytics entegre |
| CI Workflows | ✅ Aktif | mobile_quality.yml + mobile_readiness.yml + mobile_release.yml |
| Flutter Analysis | ✅ Pass | `flutter analyze` → 0 issues |
| **Keystore File** | ✅ Tamamlandı | ANDROID_KEYSTORE_BASE64 secret eklendi (2026-06-05) |
| Deep Links | ✅ Hazır | yeedoy://, io.supabase.yeedoy://, https://yeedoy.com |
| Adaptive Icon | ✅ Var | Android adaptive icon + iOS AppIcon |
| Store Listing Copy | ✅ Hazır | docs/store_listing.md (TR + EN) |
| Privacy Policy URL | ✅ Teknik | https://yeedoy.com/gizlilik |
| Version Numbers | ✅ Setup | pubspec.yaml: 1.0.0+1 |
| AdMob Integration | ✅ Hazır | CA-APP-ID manifest + Info.plist'de |
| Data Safety + IARC Taslak | ✅ Hazır | docs/store-data-safety-iarc.md |

---

## Kalan Açık İşler — Yayın Öncesi Zorunlu

Aşağıdaki aktiviteler **bu haftada/haftaya** tamamlanmalıdır:

| # | İş | Platform | Durum | Sorumlu | Tahmini Süre |
|---|---|---|---|---|---|
| **1** | App icon 1024×1024 PNG üretimi | Her iki | ⏳ TODO | Design | 2-4 saat |
| **2** | Google Play screenshots (2-8 adet) | Android | ⏳ TODO | Design/Ürün | 4-6 saat |
| **3** | App Store screenshots | iOS | ⏳ TODO | Design/Ürün | 4-6 saat |
| **4** | Feature graphic 1200×500 PNG | Google Play | ⏳ TODO | Design | 2 saat |
| **5** | v1.0 release notes (TR+EN) | Her iki | 🟡 Aşağıda | Ürün | 1 saat |
| **6** | Internal testing kullanıcıları setup | Android | ⏳ TODO | Ürün | 30 min |
| **7** | Data Safety formu — Play Console manuel | Android | ⏳ TODO | İdari | 30-60 min |
| **8** | IARC derecelendirme formu — Play Console | Android | ⏳ TODO | İdari | 15-30 min |
| **9** | AAB build oluşturma (mobile_release.yml) | Android | ⏳ Workflow ready | DevOps | 15 min (automated) |
| **10** | Kalan 3 GitHub Actions secret setup | CI | 🟡 ANDROID_KEYSTORE_BASE64 ✅ | DevOps | 5 min × 3 |

---

## 1. App Icon Gereksinimleri

### 1.1 Specifikasyonlar

**Google Play Store:**
- **512×512 px** PNG (high resolution icon)
  - Min resolution: 512×512
  - Açıklaması: Play Store listing'de gösterilen ikon
  - Köşe yuvarlama: Google otomatik uygular
  - Alfa kanalı: İsteğe bağlı (png8 veya png32)

- **1024×500 px** PNG (feature graphic — opsiyonel ama önerilir)
  - Aspect ratio: 2.04:1
  - Kullanım: Store listing üstünde görünen promo banner
  - Tavsiye: Yeedoy logosu + slogan ("Topluluk Destekli Fiyat Takip")

**App Store (iOS):**
- **1024×1024 px** PNG (App Store Connect)
  - Köşe yuvarlama: OLMAZ (Apple otomatik uygular)
  - Alfa kanalı: OLMAZ (opaque background)
  - Renk: SRGB color space
  - Dosya adı: `Icon-Marketing.png` (tanımlama amaçlı)

**Mevcut:**
- `uygulamalar/mobil/ios/Runner/Assets.xcassets/AppIcon.appiconset/` — var
- `uygulamalar/mobil/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher*.png` — var
- Adaptive icon: `uygulamalar/mobil/android/app/src/main/res/mipmap-anydpi-v33/ic_launcher*.xml` — var

**Sonraki adım:** 1024×1024 master icon tasarımını ekrana render ve PNG olarak export edin (şu an yoktur).

---

### 1.2 Design Rehberi

- **Renk palette:** Yeedoy deep red (#7F1D1D) + white/slate tones (AppColors.dart)
- **Font:** Sora (mobil themede kullanılan font)
- **Stil:** Minimal, modern, kapalı şehir silueti + utensil motifi
- **Erişilebilirlik:** 4.5:1 contrast ratio (WCAG AA)
- **Daha fazla rehber:** docs/component_catalog.md → "Icon Design Standards"

---

## 2. Screenshot Gereksinimleri

### 2.1 Specifikasyonlar

**Google Play Store:**
- **Sayı:** 2-8 adet (asgari 2, maksimum 8)
- **Boyut:** Min 320px, max 3840px (herhangi kenar)
- **En-boy oranı:** 16:9 veya 9:16 (telefon dikey, tablet yatay)
- **Formatlar:** PNG veya JPG

**Önerilen:** 9:16 (telefon dikey view) — çoğu kullanıcı bunu görür

**App Store (iOS):**
- **iPhone 6.5":** 1284×2778 px (zorunlu — Pro Max compat)
- **iPhone 5.5":** 1242×2208 px (zorunlu — 6/7/8 compat)
- **iPad 12.9":** 2048×2732 px (iPad varsa; opsiyonel)
- **Formatlar:** PNG veya JPG
- **Metin overlay:** Max 2 satır başlık + 2 satır açıklama

**Tavsiye:**
- iOS: 3 dili (TR/EN + 1 diğer) × 2 device = 6 screenshot (minimum)
- Android: 2 dili × 4 scenario = 8 screenshot (maksimum)

---

### 2.2 Önerilen 8 Screenshot Senaryosu

Aşağıdaki akışlardan alınacak. Her screenshot'ta bir özellik vurgulanmalıdır:

| # | Ekran | Feature | Başlık (TR) | Başlık (EN) | Açıklama |
|---|---|---|---|---|---|
| **1** | Discovery listesi (harita üstü) | Keşif + location | "Yakınındaki Yerleri Bul" | "Discover Nearby Spots" | İşletme listesi, fiyat rozetleri (₺/₺₺/₺₺₺) görülmeli |
| **2** | Harita view | Harita | "Haritada Keşfet" | "Explore on Map" | Pin'ler, yakınlık göstergesi |
| **3** | Business detail page | İşletme detay | "Her Detay Bir Arada" | "All Details in One Place" | Rating, menü, fiyat geçmişi grafiği, "X kişi onayladı" rozeti |
| **4** | Menu item detail (fiyat grafiği) | Fiyat trendleri | "Fiyat Trendini Takip Et" | "Track Price Trends" | Fiyat geçmişi çizgi grafiği (son 90 gün), min/max labels |
| **5** | Review create sheet | Yorum yazma | "Toplulukla Doğrula" | "Verify with Community" | 5-yıldız rating UI, 5 kriter (lezzet, servis vb.), fotoğraf ekle butonu |
| **6** | Budget Combo (arama sonuçları) | Bütçe filtresi | "Bütçene Uygun Yer Bul" | "Find Within Your Budget" | Filter chips (2 kişi, 100₺), sonuç listesi |
| **7** | Home screen widget | Widget | "Ana Ekrandaki Akışını Takip Et" | "Track on Your Home Screen" | Widget gösterimi (business card + weather-style compact) |
| **8** | Business owner reply (yorum detayı) | İşletme yanıtı | "Fiyat Hakkında Daha Bils" | "Learn More About Pricing" | Yorum + owner yanıt convo |

**Nota bene:**
- QR scanner ekranı eklenebilir (9. alternatif)
- Favorite/notification chip ekranı opsiyonel
- En önemli 3: Discovery (1), Business detail (3), Price trend (4)

---

### 2.3 Screenshot Oluşturma Adımları

1. **Emulator / Device Setup:**
   - Android: Android Emulator (Nexel 5, API 34) — 1080×2340 px
   - iOS: iOS Simulator (iPhone 15 Pro Max, iOS 17.x) — 1284×2778 px

2. **App Açma ve Navigasyon:**
   - `flutter run -d emulator-5554` (Android)
   - `flutter run -d ios-simulator` (iOS)

3. **Fake Data / Test Account:**
   - Supabase demo account veya local seed data
   - Ekranda gerçek işletme/menü verisi gösterilmeli

4. **Screenshot Alma:**
   - Android: `adb shell screencap -p /sdcard/screenshot1.png && adb pull /sdcard/screenshot1.png`
   - iOS: `xcrun simctl io booted screenshot screenshot1.png`

5. **Annotation Ekleme:**
   - Figma, Photoshop veya free Canva
   - Başlık + açıklama textini overlay et
   - Renk: Yeedoy red (#7F1D1D) başlık, white muted text açıklama
   - Font: Sora bold (başlık), Sora regular (açıklama)
   - Padding: 24px tüm taraflardan

6. **Export:**
   - Google Play: PNG 1080×1920 (9:16)
   - App Store iOS 6.5": PNG 1284×2778
   - App Store iOS 5.5": PNG 1242×2208

---

## 3. v1.0 Release Notes Şablonu

### 3.1 Türkçe Release Notes

```
Yeedoy v1.0'a Hoş Geldiniz!

🎉 İlk resmi sürüm yayında!

Yeedoy, Türkiye'nin ilk topluluk destekli restoran fiyat takip uygulamasıdır.

⭐ Öne Çıkan Özellikler:
• Yakınındaki restoran fiyatlarını keşfet ve karşılaştır
• Menü fiyatlarının geçmiş trendlerini görüntüle
• Favori menü öğelerinde fiyat değişimi olduğunda bildirim al
• Menü fotoğrafı çek ve toplulukla doğrula
• Harita üzerinde bütçene uygun yerler bul
• QR kod ile masadan doğrudan menüye erişim sağla
• Yorum yaz, fiyatları doğrula, topluluğa katkıda bulun

🚀 Teknik İyileştirmeler:
• Firebase Crashlytics ile hata takibi
• Çevrimdışı mod desteği
• Siri Shortcuts entegrasyonu
• iOS 14+ ve Android 8.0+ uyumu

💬 Geri Bildirim:
Herhangi bir sorun veya öneriniz varsa, [support@yeedoy.com](mailto:support@yeedoy.com) adresine yazınız.

Yeedoy'u sevenler: Lütfen 5 yıldız verin! 🌟
```

**Karakter Sayısı:** ~450 karakter (Play Store limiti ~500 — güvenli)

---

### 3.2 English Release Notes

```
Welcome to Yeedoy v1.0!

🎉 Official launch edition!

Yeedoy is Turkey's first community-driven restaurant price tracking app.

⭐ Key Features:
• Discover and compare nearby restaurant prices
• Track price history trends for your favorite menu items
• Get notified instantly when prices change
• Add photos and verify prices with the community
• Find budget-friendly restaurants on the map
• Access menus instantly with QR code scanning
• Write reviews, verify prices, contribute to the community

🚀 Technical Improvements:
• Firebase Crashlytics crash reporting
• Offline mode support
• Siri Shortcuts integration
• iOS 14+ and Android 8.0+ compatibility

💬 Feedback:
Found a bug or have a suggestion? Email us at [support@yeedoy.com](mailto:support@yeedoy.com).

Love Yeedoy? Please rate us 5 stars! 🌟
```

**Character Count:** ~420 characters (Play Store limit ~500 — safe)

---

### 3.3 Nereye Girer

- **Google Play:** Release management → Latest release → Release notes tab
- **App Store:** Version history → 1.0 → Release notes field

---

## 4. Feature Graphic Gereksinimleri (Google Play)

**Spec:**
- Boyut: 1200×500 px
- Format: PNG veya JPG
- Amaç: Store listing top banner (opsiyonel ama ASO için tavsiye)
- Gösterim: Android listesinin en üst kısmında

**Tasarım Önerisi:**
- Sol taraf: Yeedoy logosu veya ikon (300×300 px, center)
- Sağ taraf: Slogan vb. text
  - Başlık: "Yeedoy: Topluluk Destekli Fiyat Takip"
  - Açıklama: "Menü fiyatlarını sen belirliyorsun"
- Arka plan: Gradient (red #7F1D1D → slate)
- Font: Sora bold

**Sonraki adım:** Figma'da draft et, PNG export et.

---

## 5. Internal Testing Setup Checklist

Google Play'de beta testing başlamadan önce:

### 5.1 Internal Testing Track Oluşturma

**Google Play Console adımları:**
1. App → Release → Internal testing → Create release
2. APK/AAB upload (mobile_release.yml workflow çıktısı)
3. Version code: 1 (pubspec.yaml: 1.0.0+1)
4. Release notes: Yukarıdaki template (Türkçe)
5. Status: **Draft** (hazır olunca "Review" → "Release" yap)

### 5.2 Tester Ekleme

1. Play Console → Testers → Internal testing → Create mailing list
   - Adı: `yeedoy-internal-testers@`
   - Üyeler: 5-10 internal user (team members + selected beta users)
   
2. Invite link'i tester'lara gönder
   - Link format: `https://play.google.com/apps/testing/com.yeedoy.app`
   - Tester'lar Google Play Store'dan "Join beta" yapacak

### 5.3 Pre-Launch Report Checks

Uploadtan sonra Play Console otomatik rapor üretir:

```
✓ Yapılacak Kontroller:
  □ Target API level 34+ — minimal API 26 — ✅ OK
  □ 64-bit binary — Flutter default ✅
  □ Permissions — "excessive" flag yok — ✅ (7 izin tamam)
  □ Malware scan — "Low risk" — ✅
  □ Content rating — IARC form tamamlandıktan sonra
```

---

## 6. Data Safety & IARC Play Console Manuel Adımları

**Referans:** docs/store-data-safety-iarc.md

### 6.1 Data Safety Form (30-60 dakika)

**Play Console yolu:**
1. App content → Data safety
2. "Does your app collect or share any required user data types?" → **Start**
3. Veri kategorileri (1.10 Summary Tablo'dan):
   - [ ] Location → Approximate location → **Collect** ✅
   - [ ] Personal info → Name → **Collect** ✅
   - [ ] Personal info → Email → **Collect** ✅
   - [ ] Photos and videos → Photos → **Collect** ✅
   - [ ] User content → User-generated content → **Collect** ✅
   - [ ] Device or other IDs → Device IDs (AdMob) → **Collect + Share** ✅
   - [ ] App info and performance → Crash logs → **Collect + Share (Firebase)** ✅
   - [ ] App info and performance → Diagnostics → **Collect + Share (Firebase)** ✅
   - [ ] App info and performance → Analytics → **Collect + Share (Firebase)** ✅
   - [ ] Identifiers → User IDs (FCM) → **Collect + Share (FCM)** ✅

4. Genel sorular:
   - "Is all of the user data collected by your app encrypted in transit?" → **Yes** (HTTPS/TLS)
   - "Do you provide a way for users to request that their data is deleted?" → **Yes** (Account deletion)
   - "Is this policy easily accessible from within the app?" → **Yes** (Settings link)

5. Preview ve Save
6. Submit (review ~24-48 saat)

---

### 6.2 IARC Content Rating (15-30 dakika)

**Play Console yolu:**
1. App content → Ratings → Start questionnaire
2. App category: **Lifestyle** (veya **Food & Drink** — var ise)
3. Content answers (docs/store-data-safety-iarc.md Bölüm 2'den):
   - Violence: **None**
   - Sexual content: **None**
   - Gambling: **None**
   - User-generated content: **Yes** (moderated)
   - Location sharing: **No user-to-user sharing**
   - Advertising: **Yes (AdMob)**

4. Submit
5. IARC otomatik rating verir (typical: 3+ or 7+ — UGC nedeniyle)
6. Rating ülkelere göre uygulanır

---

## 7. GitHub Actions Secrets — Kalan 3 Secret Setup

**Durum:** ANDROID_KEYSTORE_BASE64 ✅ (2026-06-05 tamamlandı)  
**Kalan:** 3 secret daha (`mobile_release.yml` workflow'da gerekli)

### 7.1 Gerekli Secrets

| Secret Name | Açıklama | Örnek Değer |
|---|---|---|
| `ANDROID_RELEASE_STORE_PASSWORD` | Keystore şifresi | `P@ssw0rdKeystore123!` |
| `ANDROID_RELEASE_KEY_ALIAS` | Alias (keystore oluştur sırasında belirtildi) | `yeedoy-release` |
| `ANDROID_RELEASE_KEY_PASSWORD` | Key şifresi (keystore oluştur sırasında belirtildi) | `P@ssw0rdKey123!` |

### 7.2 Setup — GitHub CLI (Terminal)

```bash
# Terminal'de çalıştır (3 komut):

gh secret set ANDROID_RELEASE_STORE_PASSWORD --repo mekan37/yeedoy
# Terminal soracak: Enter password for ANDROID_RELEASE_STORE_PASSWORD:
# [gizli olarak yaz, enter]

gh secret set ANDROID_RELEASE_KEY_ALIAS --repo mekan37/yeedoy
# Terminal soracak: Enter value for ANDROID_RELEASE_KEY_ALIAS:
# [yeedoy-release veya kullandığın alias, enter]

gh secret set ANDROID_RELEASE_KEY_PASSWORD --repo mekan37/yeedoy
# Terminal soracak: Enter password for ANDROID_RELEASE_KEY_PASSWORD:
# [gizli olarak yaz, enter]

# Kontrol: gh secret list --repo mekan37/yeedoy
# (tüm 4 secret görülmeli: ANDROID_KEYSTORE_BASE64 + yukarıdaki 3)
```

### 7.3 Alternative — GitHub UI

1. GitHub repo → Settings → Secrets and variables → Actions
2. "New repository secret" × 3
3. Name + Value ekle (secrets dialog'da)
4. Save

---

## 8. AAB Build & Upload Workflow

### 8.1 Otomatik Build (mobile_release.yml)

**Trigger:** Manuel (`workflow_dispatch`)  
**Çalıştır:**
1. GitHub repo → Actions → "Mobile Release" workflow
2. "Run workflow" → Branch: **main** → "Run workflow"
3. Workflow 15-20 dakika çalışır
4. Artifacts:
   - `app-release.aab` (Play Console'a upload et)
   - `symbols/` (Crashlytics debug symbols)

### 8.2 Play Console'a Upload

1. Play Console → App → Release → Internal testing → "Create release"
2. "Browse files" → artifact'ı seç: `app-release.aab`
3. Version code & release notes doldur
4. "Review release" → "Release to internal testing"

### 8.3 Internal Testing Validation

Testers'lar Google Play Store'dan indirip test ederler:
- [ ] App açılıyor, crash yok
- [ ] Login akışı — signup/email verification çalışıyor
- [ ] Discovery harita yükleniyor, search çalışıyor
- [ ] Business detail — grafik, yorum akışı render
- [ ] QR scan — camera izni, menu açılıyor
- [ ] Yorum yazma — upload, server response
- [ ] Push notification — Firebase FCM test
- [ ] Offline mode — cached data erişim
- [ ] Locale — Türkçe/English switch çalışıyor

---

## 9. Closed Beta → Production Release Akışı

### 9.1 Zaman Çizelgesi

```
Gün 1-2: Internal testing (5-10 tester, 24-48 saat)
         ↓ Critical bugs bulunursa: hotfix + redeploy

Gün 3-4: Closed beta (50-500 tester, ~1 hafta)
         ↓ Feedback topla, metrikleri izle

Gün 8-14: Production rollout
         ├─ 10% → 24 saat izle (crash rate, ANR, ratings)
         ├─ 50% → crash-free users > 99.5% ise
         └─ 100% → all metrics green ise
```

### 9.2 Rollout Türleri

**Google Play:**
1. **Internal Testing** — AAB upload → instant availability (internal testers)
2. **Closed Beta** — Invite link + Play Store listing → 1 hafta (close network testers)
3. **Open Beta** — Public but labeled "Beta" → 1-2 hafta (all users can opt-in)
4. **Production** — Public release → world

**App Store (TestFlight):**
1. **Internal Testing** — IPA upload → instant (Apple team)
2. **External Testing** — Invite link + build link → 24-48 saat review → tester'lara mail
3. **Review Submission** — "Submit for Review" → 1-3 gün Apple review → approve/reject
4. **Production Release** — "Release this version" → instant App Store

---

## 10. Post-Launch Monitoring Checklist

### 10.1 Day 1-3

```
□ Firebase Crashlytics dashboard
  ├─ Crash-free users: > 99.0%? (target)
  ├─ Top crash: inspect ve hotfix priority
  └─ ANR rate: < 0.5%?

□ Firebase Analytics
  ├─ Daily active users (DAU)
  ├─ Session duration (avg > 2 min)
  ├─ Retention (Day 1: > 50%)
  └─ Top 10 screens (conversion funnel)

□ Play Console Vitals
  ├─ Crash rate: < 1%
  ├─ ANR rate: < 0.1%
  └─ Frozen frames: < 5%

□ User feedback
  ├─ Play Store reviews: trending topics?
  ├─ Support emails: critical issues?
  └─ Social media: @yeedoy mentions
```

### 10.2 Week 1

```
□ Retention metrics
  ├─ Day 1 retention: > 40% (target)
  ├─ Day 7 retention: > 25% (target)
  └─ Session frequency: increasing?

□ Feature adoption
  ├─ Discovery feature usage: ?%
  ├─ Review submissions: ?/day
  ├─ Favorite additions: ?/day
  └─ QR scans: ?/day

□ Performance
  ├─ App size: < 150 MB (goal)
  ├─ Launch time: < 3 sec (goal)
  ├─ Scroll performance: 60 FPS (goal)
  └─ Memory usage: stable?

□ Monetization (AdMob)
  ├─ Impressions/DAU
  ├─ Click-through rate (CTR)
  ├─ Revenue (if applicable)
  └─ No policy violations?
```

### 10.3 Week 2+

```
□ Version adoption
  ├─ 1.0 usage: % of DAU
  └─ Update abandonment: < 10%?

□ Critical issues
  ├─ Blocking bugs: fixed?
  ├─ Server-side issues: monitored?
  └─ Third-party SDK issues: reported?

□ Marketing metrics
  ├─ Download rate: trending?
  ├─ Geographic distribution: as expected?
  ├─ Device distribution: API 26+ coverage OK?
  └─ OS split: Android vs iOS breakdown
```

---

## 11. Sonraki Adımlar — Priority Order

### Bu Hafta (CRITICAL)

1. [ ] App icon 1024×1024 tasarımını tamamla
2. [ ] Feature graphic 1200×500 tasarımını tamamla
3. [ ] 8 screenshot senaryosu için cihaz/emulator hazırla
4. [ ] Kalan 3 GitHub Actions secret'ı terminal'de set et:
   - `gh secret set ANDROID_RELEASE_STORE_PASSWORD`
   - `gh secret set ANDROID_RELEASE_KEY_ALIAS`
   - `gh secret set ANDROID_RELEASE_KEY_PASSWORD`

### Sonraki Hafta (HIGH)

1. [ ] 8 screenshot çek (Android emulator + iOS simulator)
2. [ ] Screenshot'lara başlık/açıklama text overlay ekle (Figma/Canva)
3. [ ] v1.0 release notes'u doğrula ve finalize et (TR + EN)
4. [ ] mobile_release.yml workflow'u trigger et → AAB build al
5. [ ] Internal testing testers grubunu kur (Play Console)

### 2 Hafta Sonrası (MEDIUM)

1. [ ] Play Console Data Safety formu — manual doldur (30-60 min)
2. [ ] Play Console IARC formu — manual doldur (15-30 min)
3. [ ] Play Console → Internal testing release oluştur → testers'a gönder
4. [ ] Closed beta için feedback formu hazırla
5. [ ] Post-launch monitoring dashboard'unu Firebase'da setup et

### Production Launch (After Beta)

1. [ ] Internal testing (2-3 gün) — critical bugs fixed?
2. [ ] Closed beta (5-7 gün) — retention > 40%, crash-free > 99%?
3. [ ] Production rollout (10% → 50% → 100% staging)
4. [ ] App Store — TestFlight + Review Submission (parallel)

---

## 12. Başarı Metrikleri

### Launch Hedefleri

| Metrik | Target | Ölçüm |
|--------|--------|-------|
| Crash-free users | > 99.5% | Firebase Crashlytics |
| App Store rating | ≥ 4.0 stars | Play Console + App Store |
| Day 1 retention | > 40% | Firebase Analytics |
| Day 7 retention | > 25% | Firebase Analytics |
| Session duration | > 3 min avg | Firebase Analytics |
| Download speed (Day 1) | > 100 | Play Store downloads |
| Update adoption (7 days) | > 80% | Play Console version stats |

### Post-Launch Continuous

| Metrik | Target | Cadence |
|--------|--------|---------|
| Daily active users | Growing 10%+ /week | Daily |
| Feature engagement | Feature adoption > 30% | Weekly |
| Support ticket volume | < 10/week | Weekly |
| Critical bugs | < 1/month | Monthly |
| User feedback | 4.0+ rating maintained | Continuous |

---

## 13. Risk & Mitigation

| Risk | Olasılık | Etki | Mitigation |
|---|---|---|---|
| Critical crash bug found during beta | Medium | High | Hotfix + redeploy (24 hour max) |
| Low app store rating (< 3.5) | Low | High | Urgent issue triage + UI/UX fix sprint |
| Play Store review rejection | Low | Critical | Pre-review API check + content rating audit |
| Data Safety form mismatch | Low | Medium | Legal review before submission |
| Slow server under traffic spike | Medium | Medium | Load test + auto-scaling enable |
| Firebase quota exceeded | Low | High | Quota increase request + cost monitoring |
| AdMob policy violation | Very Low | Medium | Policy audit before launch |

---

## 14. Ressources & Templates

### Key Documents

- `docs/mobile-release-readiness.md` — Full release checklist
- `docs/store_listing.md` — ASO copy (TR + EN)
- `docs/store-data-safety-iarc.md` — Data Safety & IARC taslak
- `.github/workflows/mobile_release.yml` — AAB build automation

### Tools & Links

- **Google Play Console:** https://play.google.com/console
- **App Store Connect:** https://appstoreconnect.apple.com
- **Firebase Console:** https://console.firebase.google.com
- **GitHub Actions:** repo → Actions → "Mobile Release"
- **Figma/Canva:** Screenshot annotation için

### Contacts

- Support email: support@yeedoy.com
- Legal: [Hukuk danışmanı email]
- Product owner: [Ürün müdürü email]

---

## 15. Glossary

| Term | Açıklama |
|---|---|
| **AAB** | Android App Bundle (Google Play format) |
| **APK** | Android app package (direct device install) |
| **IPA** | iOS app package (App Store format) |
| **ASO** | App Store Optimization |
| **FCM** | Firebase Cloud Messaging |
| **IARC** | International Age Rating Coalition |
| **UGC** | User-generated content |
| **DAU** | Daily active users |
| **ANR** | Application not responding (freeze) |
| **Vitals** | Play Console performance metrics |

---

**Versiyon:** 1.0  
**Hazırlanma Tarihi:** 2026-06-05  
**Hazırlayan:** Deployment Engineer  
**Status:** Release plan — activation pending store assets
