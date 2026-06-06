# Yeedoy — Kalan İşler

> **Son Güncelleme:** 2026-06-05
> **Kural:** Bu dosya tek kanonik açık iş listesidir. Yeni iş eklenince buraya yazılır.

---

## P0 — Release Blocker (Bunlar olmadan store yayını yapılamaz)

### Firebase Init Crash Fix
- **Durum:** Açık
- **Neden:** Emulator + background message handler çakışıyor → uygulama crash oluyor
- **Bağımlılık:** Android screenshot capture buraya bağlı
- **Önerilen branch:** `fix/mobile-firebase-init-crash`
- **Commit:** `fix(mobile): guard firebase init against duplicate app`
- **Not:** main.dart'ta `Firebase.initializeApp()` try-catch ile guard edilmeli

### Android Release AAB Artifact Doğrulaması
- **Durum:** Açık
- **Neden:** mobile_release.yml var ama gerçek signed AAB derlenmedi/doğrulanmadı
- **Bağımlılık:** 3 GitHub secret (ANDROID_RELEASE_KEY_ALIAS, STORE_PASSWORD, KEY_PASSWORD) eklendi mi?
- **Önerilen branch:** `store/android-release-build-verify`
- **Commit:** `store: verify signed android release build`

---

## P1 — Store Yayın Hazırlığı

### Android Store Screenshots (0/8)
- **Durum:** Açık — Firebase crash yüzünden park edildi
- **Bağımlılık:** P0 Firebase fix
- **Önerilen branch:** `store/android-screenshots`
- **Not:** Pixel_9_Pro emülatör mevcut, adb screencap hazır, demo mode komutları docs/store-screenshot-capture-guide.md'de

### iOS Store Screenshots (0/8)
- **Durum:** Açık — macOS + Xcode gerekiyor
- **Bağımlılık:** macOS cihaz
- **Önerilen branch:** `store/ios-screenshots`
- **Not:** iPhone 14 Plus 1284×2778 + iPhone 8 Plus 1242×2208 zorunlu

### Play Console Data Safety Manuel Giriş
- **Durum:** Açık — taslak hazır
- **Bağımlılık:** docs/store-data-safety-iarc.md
- **Not:** ~30-60 dakika manuel Play Console formu

### Play Console IARC Derecelendirme Formu
- **Durum:** Açık
- **Not:** ~15-30 dakika manuel

### Internal Testing / Beta Testers
- **Durum:** Açık
- **Not:** 5-10 tester Play Console → Testing → Internal testing

### Release Notes Final Kontrol
- **Durum:** 🟡 Taslak var (docs/store-assets-release-plan.md)
- **Not:** TR + EN release notes mevcut, son gözden geçirme gerekiyor

### Store Asset Upload Checklist
- **Durum:** Açık
- **Assetler hazır:**
  - store-assets/icon/yeedoy-master-icon-1024.png ✅
  - store-assets/icon/yeedoy-play-icon-512.png ✅
  - store-assets/feature/yeedoy-feature-graphic-1200x500.png ✅
- **Assetler eksik:**
  - 8× Android screenshot ❌
  - 8× iOS screenshot ❌

---

## P2 — Runtime Env / Dış Entegrasyonlar

### Firebase FCM Runtime Env
- **Durum:** ✅ HAZIR — GitHub secrets ✅, local .env.local ✅ (2026-06-06 verified)
- **GitHub Secrets:** FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY ✅ tanımlı
- **Local .env.local:** Tüm 3 Firebase var'ı set
- **Lokal test:** npm run dev → /yonetici/push-kampanyalari → test kampanyası → `providerNotConfigured: false` doğrula
- **Production:** Vercel env vars → Dashboard → Environment Variables → 3 Firebase var ekle → redeploy
- **Bkz:** docs/push-delivery-integration-plan.md

### Resend Email Runtime Env
- **Durum:** 🟡 KISMEN HAZIR — kod hazır, RESEND_API_KEY runtime'a eklenmedi
- **GitHub Secrets:** ❌ RESEND_API_KEY missing
- **Local .env.local:** ❌ RESEND_API_KEY missing
- **Gerekli:** RESEND_API_KEY, (opsiyonel: RESEND_FROM_EMAIL, SUPABASE_SERVICE_ROLE_KEY)
- **Hedef:** .env.local veya deployment platform → Resend Dashboard'dan API key al → ekle
- **Bkz:** docs/email-delivery-integration-plan.md

### SMS Entegrasyonu (6 Blocker)
- **Durum:** 🔴 BLOCKER — route deployed ama tüm altyapı eksik
- **GitHub Secrets:** ❌ SMS_API_KEY, SMS_PROVIDER missing
- **Local .env.local:** ❌ Hiçbir SMS var'ı yok
- **Bkz:** docs/sms-delivery-integration-plan.md
- **Blocker'lar:** migration (user_profiles.phone, business_follows.is_subscribed_sms, sms_campaigns table), KVKK consent, opt-out handler, provider (Netgsm/Ileti Merkezi/Twilio)

---

## P3 — Mobil Teknik Borçlar

### Profil Sosyal Bağlantı Kaydetme
- **Durum:** Blocker — user_profiles.social_links kolonu yok
- **Neden:** Flutter modeli ve URL normalizasyon hazır; DB kolonu eksik
- **Gerekli:** `user_profiles` tablosuna `social_links JSONB DEFAULT '{}'::jsonb` kolonu eklenecek migration
- **Mevcut dosya:** `features/profile/data/profile_repository.dart` — upsertMyProfile() sosyal linkleri normalize ediyor ama DB'ye kaydetmiyor (kolon yok)
- **UI:** `features/profile/ui/profile_page.dart:179` — profileSocialSaveComingSoon placeholder
- **Önerilen branch:** `migration/supabase-user-profile-social-links` (migration) → `feature/mobile-profile-social-links-save` (Flutter)
- **Commit:** `migration(supabase): add social_links to user_profiles` → `feat(mobile): save profile social links`
- **Not:** Migration onaylandıktan sonra upsertMyProfile() içinde payload'a `'social_links': normalizedLinks` eklenmesi yeterli

### estimate_email_segment_v1 — follower_id Kullanımı
- **Durum:** ✅ PR #55 ile düzeltildi

### business_automations RLS
- **Durum:** ✅ PR #50 ile düzeltildi

---

## P4 — Web/Admin/Owner Geliştirme Backlog

Mevcut açık web işleri için bkz. `docs/eksik-listesi.md`

---

## P5 — Fikir Havuzu / Daha Sonra

- Fiyat Endeksi medya lansmanı (bkz. docs/archive/fiyat-endeksi-medya-raporu.md)
- Search Console submit (tamamlandı, ek optimizasyon yapılabilir)
- A/B test alt yapısı
- 2FA / hesap güvenliği — TOTP enroll/verify aktif ✅ (PR #84). Eski stub redirect tamamlandı ✅ (PR #85). AAL2 middleware rollout planı hazır ✅ (PR #86). Soft banner (Faz 1) tamamlandı ✅ (PR #87, bkz. docs/account-security-aal2-middleware-plan.md). Sıradaki: admin high-risk AAL2 middleware (Faz 2) → owner high-risk AAL2 middleware (Faz 3) → E2E smoke testleri
- Collab lists v2
