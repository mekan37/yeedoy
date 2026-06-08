# Yeedoy — Kalan İşler

> **Son Güncelleme:** 2026-06-08 (docs audit ile doğrulanarak güncellendi — bkz. `docs/doc-audit-2026-06.md`)
> **Kural:** Bu dosya tek kanonik açık iş listesidir. Yeni iş eklenince buraya yazılır. `docs/eksik-listesi.md` bu dosyaya birleştirilip silindi.
> **Şablon:** Her madde `Durum / Kanıt / Etki / Bağımlılık / Önerilen branch / Önerilen agent / Kabul kriteri` alanlarını kullanır.

---

## P0 — Release Blocker (Bunlar olmadan store yayını yapılamaz)

### Firebase Init Crash Fix
- **Durum:** 🟡 Main'de kısmen çözüldü, ek düzeltme unmerged branch'te bekliyor
- **Kanıt:** PR #66 (`fix(mobile): guard firebase initialization against duplicate app`, commit `8928034`) ve PR #68 (`fix(mobile): disable duplicate firebase auto initialization`, commit `a4c15cd`) main'e merge edildi — `uygulamalar/mobil/lib/main.dart:58-60` artık `if (Firebase.apps.isEmpty) { await Firebase.initializeApp(...) }` guard'ı içeriyor. **Ancak** `store/android-screenshot-set` branch'i (commit `33cb1a8`, main'e merge edilmemiş) "Fixed Firebase duplicate-app crash: removed FirebaseInitProvider from AndroidManifest.xml" notuyla **ek bir manifest düzeltmesi** içeriyor — bu da PR #66/#68'in tek başına yeterli olmayabileceğini gösteriyor.
- **Etki:** Android screenshot capture ve emulator testleri bu fixe bağlı
- **Bağımlılık:** `store/android-screenshot-set` branch'inin gözden geçirilip merge edilmesi
- **Önerilen branch:** `store/android-screenshot-set` (mevcut, merge'e hazır olabilir — review gerekir)
- **Önerilen agent:** mobile-developer (flutter-expert sistemde yok, en yakın uzman)
- **Kabul kriteri:** Pixel 9 Pro emulator'da uygulama Firebase init sırasında crash olmadan açılır; `store/android-screenshot-set` branch'i main'e merge edilir veya çakışmaları çözülerek yeniden uygulanır

### Android Release AAB Artifact Doğrulaması
- **Durum:** Açık
- **Kanıt:** `mobile_release.yml` workflow dosyası mevcut ancak gerçek signed AAB derlenip doğrulanmadı
- **Etki:** Play Store submit imkansız kalır
- **Bağımlılık:** 3 GitHub secret (`ANDROID_RELEASE_KEY_ALIAS`, `STORE_PASSWORD`, `KEY_PASSWORD`) eklendi mi doğrulanmalı (`gh secret list`)
- **Önerilen branch:** `store/android-release-build-verify`
- **Önerilen agent:** devops-engineer
- **Kabul kriteri:** CI'da signed release AAB derlenir, indirilebilir, `apksigner verify` ile imza doğrulanır

---

## P1 — Store Yayın Hazırlığı

### Android Store Screenshots (0/8 main'de — 8/8 unmerged branch'te hazır)
- **Durum:** 🟡 Çözüme çok yakın — unmerged branch'te tamamlanmış halde duruyor
- **Kanıt:** `store/android-screenshot-set` branch'i (commit `33cb1a8 store: add android store screenshot set (8/8)`) 8 adet 1280×2856px Android ekran görüntüsü içeriyor (`store-assets/screenshots/android/android_01..08_*.png`, demo mode 09:41/batarya 100%/wifi 4 bar). main'de bu dosyalar henüz yok (`git ls-files store-assets/` boş döndü)
- **Etki:** Play Store Store Listing yükleme bu görsellere bağlı
- **Bağımlılık:** P0 Firebase fix branch'i ile aynı commit — ikisi birlikte merge edilmeli
- **Önerilen branch:** `store/android-screenshot-set` (mevcut — review + merge)
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** 8 PNG dosyası main'de `store-assets/screenshots/android/` altında; `docs/release/store-screenshot-capture-guide.md` senaryolarıyla eşleşiyor

### iOS Store Screenshots (0/8)
- **Durum:** Açık — macOS + Xcode gerekiyor
- **Kanıt:** `store-assets/screenshots/ios/` dizini boş (sadece klasör var)
- **Etki:** App Store Connect'e yükleme bu görsellere bağlı
- **Bağımlılık:** macOS cihaz erişimi
- **Önerilen branch:** `store/ios-screenshots`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** iPhone 14 Plus (1284×2778) + iPhone 8 Plus (1242×2208) için 8'er ekran görüntüsü `store-assets/screenshots/ios/` altında

### Play Console Data Safety Manuel Giriş
- **Durum:** Açık — taslak hazır
- **Kanıt:** `docs/release/store-data-safety-iarc.md` (taşındı) detaylı taslak içeriyor; ATT (`NSUserTrackingUsageDescription`) repo'da uygulanmış durumda
- **Etki:** Play Console'da form doldurulmadan yayın yapılamaz
- **Bağımlılık:** Play Console erişimi
- **Önerilen branch:** — (kod değişikliği yok, manuel form)
- **Önerilen agent:** project-manager
- **Kabul kriteri:** Play Console → App content → Data safety formu taslağa göre doldurulup gönderildi (~30-60 dk)

### Play Console IARC Derecelendirme Formu
- **Durum:** Açık
- **Kanıt:** `docs/release/store-data-safety-iarc.md` IARC bölümü taslak içeriyor
- **Etki:** IARC derecelendirmesi olmadan store listing tamamlanamaz
- **Bağımlılık:** Play Console erişimi
- **Önerilen branch:** —
- **Önerilen agent:** project-manager
- **Kabul kriteri:** IARC formu gönderildi, derecelendirme sertifikası alındı (~15-30 dk)

### Internal Testing / Beta Testers
- **Durum:** Açık
- **Kanıt:** Henüz tester davet edilmedi
- **Etki:** Crash/feedback verisi olmadan public release riskli
- **Bağımlılık:** Signed AAB (P0) + ekran görüntüleri (P1)
- **Önerilen branch:** —
- **Önerilen agent:** project-manager
- **Kabul kriteri:** 5-10 tester Play Console → Testing → Internal testing kanalına eklendi, en az 3 gün geri bildirim toplandı

### Release Notes Final Kontrol
- **Durum:** 🟡 Taslak hazır, son gözden geçirme gerekiyor
- **Kanıt:** `docs/release/mobile-release-readiness.md` içinde TR + EN release notes şablonları kullanıma hazır halde mevcut
- **Etki:** Düşük — taslak zaten kullanılabilir durumda
- **Bağımlılık:** Yok
- **Önerilen branch:** —
- **Önerilen agent:** content-marketer
- **Kabul kriteri:** TR/EN release notes son kez okunup onaylandı, store listing'e yapıştırıldı

### Store Asset Upload Checklist
- **Durum:** Açık — kısmen tamamlandı
- **Kanıt:** Hazır olanlar: `store-assets/icon/yeedoy-master-icon-1024.png` ✅, `store-assets/icon/yeedoy-play-icon-512.png` ✅, `store-assets/feature/yeedoy-feature-graphic-1200x500.png` ✅ (`git ls-files` ile doğrulandı). Eksik: 8× Android screenshot main'de yok (ama unmerged branch'te hazır — yukarı bkz.), 8× iOS screenshot hiç yok
- **Etki:** Store listing tamamlanamaz
- **Bağımlılık:** P0/P1 screenshot maddeleri
- **Önerilen branch:** —
- **Önerilen agent:** project-manager
- **Kabul kriteri:** Tüm asset checklist maddeleri ✅ — icon, feature graphic, 8 Android + 8 iOS screenshot store-assets/ altında

---

## P2 — Runtime Env / Dış Entegrasyonlar

> Detaylı entegrasyon durumu için bkz. `docs/delivery/delivery-integration-status.md` (push/email/sms tek tabloda)

### Firebase FCM Runtime Env
- **Durum:** ✅ HAZIR — GitHub secrets ✅, local .env.local ✅ (2026-06-06 doğrulandı)
- **Kanıt:** `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` — `gh secret list` ile doğrulandı; PR #52 (commit `8d3e6dd`) FCM delivery kodu deploy edildi
- **Etki:** Düşük — sadece Vercel production env var ekleme kaldı
- **Bağımlılık:** Yok
- **Önerilen branch:** —
- **Önerilen agent:** devops-engineer
- **Kabul kriteri:** Production'da test kampanyası `providerNotConfigured: false` döner

### Resend Email Runtime Env
- **Durum:** 🟡 KISMEN HAZIR — kod hazır, `RESEND_API_KEY` runtime'a eklenmedi
- **Kanıt:** `gh secret list` ile `RESEND_API_KEY` GitHub secrets'ta yok; local `.env.local`'de de yok; `resend-client.ts` fail-safe `provider_not_configured: true` döndürüyor (PR #54, commit `b8826bc`)
- **Etki:** Orta — owner email kampanyaları gönderilemiyor
- **Bağımlılık:** Resend hesabı + API key
- **Önerilen branch:** —
- **Önerilen agent:** devops-engineer
- **Kabul kriteri:** `RESEND_API_KEY` (+ opsiyonel `RESEND_FROM_EMAIL`, `SUPABASE_SERVICE_ROLE_KEY`) eklendi; test kampanyası `provider_not_configured: false` ve `sent_to > 0` döner

### SMS Entegrasyonu (6 Blocker)
- **Durum:** 🔴 BLOCKER — route deploy edildi ama tüm altyapı eksik
- **Kanıt:** `app/sunucu/sahip/sms-kampanya/route.ts:72` mevcut; migration yok, `user_profiles.phone` / `business_follows.is_subscribed_sms` / `sms_campaigns` tabloları yok; `SMS_API_KEY`/`SMS_PROVIDER` env var'ları tanımlı değil
- **Etki:** Yüksek — KVKK/IYS uyumsuz gönderim riski olmadan hiçbir SMS özelliği çalışmaz
- **Bağımlılık:** Provider seçimi (Netgsm/İleti Merkezi/Twilio), KVKK consent + opt-out altyapısı
- **Önerilen branch:** `migration/supabase-sms-campaign-infra` → `feature/web-sms-campaign-delivery`
- **Önerilen agent:** postgres-pro (migration) → nextjs-developer (route)
- **Kabul kriteri:** Migration uygulandı, opt-out handler çalışıyor, provider seçildi ve KVKK/IYS onayı alındı, test SMS'i `provider_not_configured: false` ile gönderildi

---

## P3 — Mobil Teknik Borçlar

### Profil Sosyal Bağlantı Kaydetme
- **Durum:** ✅ Tamamlandı (PR #65, #69)
- **Kanıt:** Migration `20260603000011_user_profiles_social_links.sql` mevcut (PR #69, commit `2727c72`); `features/profile/data/profile_repository.dart:80` artık `'social_links': normalizedLinks.isEmpty ? null : normalizedLinks` payload'a yazıyor (PR #70/#65, commit `20bd1d5`)
- **Etki:** —
- **Bağımlılık:** —
- **Önerilen branch:** —
- **Önerilen agent:** —
- **Kabul kriteri:** ✅ Karşılandı — kullanıcı sosyal linklerini kaydedebiliyor, DB'ye yazılıyor

### estimate_email_segment_v1 — follower_id Kullanımı
- **Durum:** ✅ PR #55 ile düzeltildi
- **Kanıt:** Migration `20260603000010_fix_estimate_email_segment_v1.sql` — `follower_id` kullanımı kaldırıldı, `bf.business_id` + `is_subscribed_email` filtresi + `is_admin()/is_owner_of_business()` yetki kontrolü eklendi (PR #55, commit `964d1ac`)
- **Etki:** —
- **Bağımlılık:** —
- **Önerilen branch:** —
- **Önerilen agent:** —
- **Kabul kriteri:** ✅ Karşılandı

### business_automations RLS
- **Durum:** ✅ PR #50 ile düzeltildi
- **Kanıt:** Migration mevcut, PR #50 (commit `f3723cb`) merge edildi
- **Etki:** —
- **Bağımlılık:** —
- **Önerilen branch:** —
- **Önerilen agent:** —
- **Kabul kriteri:** ✅ Karşılandı

---

## P4 — Web/Admin/Owner Geliştirme Backlog

> `docs/eksik-listesi.md` bu bölüme birleştirildi ve silindi. Aşağıdaki maddeler doğrulama sırasında hâlâ açık olduğu teyit edilenlerdir (eski dosyadaki bazı maddeler — Taste Twin, Inbox toplu okundu, owner QR — artık tamamlanmış olduğu için listeye alınmadı, bkz. `docs/doc-audit-2026-06.md` "Doğrulanamayanlar" bölümü).

### Custom Domain Doğrulama (Owner)
- **Durum:** Açık — backend hazır, UI bağlı değil
- **Kanıt:** `verify-domain` edge function yazılmış (119 satır); `owner/settings/domain` UI↔backend bağlantısı yok
- **Etki:** Orta — özel domain isteyen işletmeler için blocker
- **Bağımlılık:** Yok
- **Önerilen branch:** `feature/web-owner-domain-verification-ui`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** Owner panelinden domain ekleyip `verify-domain` fonksiyonu üzerinden doğrulama yapılabiliyor

### AI Menü Analizi (Owner)
- **Durum:** Açık — backend hazır, panel entegrasyonu yok
- **Kanıt:** `ai-menu-analyze` edge function yazılmış (345 satır); `owner/ai-analysis` route'unda entegrasyon yok
- **Etki:** Orta — owner'lar için değer katacak özellik kullanılmıyor
- **Bağımlılık:** Yok
- **Önerilen branch:** `feature/web-owner-ai-menu-analysis-ui`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** Owner panelinde menü analizi tetiklenip sonuçlar gösterilebiliyor

### Admin Sponsorluk Modülü (3 Stub Sayfa)
- **Durum:** 🟡 Kısmen — sayfalar var, gerçek veri/aksiyon bağlantısı doğrulanmalı
- **Kanıt:** `app/admin/sponsorships/page.tsx` (235 satır), `sponsorship-leads/page.tsx` (173 satır), `sponsorship-packages/page.tsx` (139 satır) mevcut; migration `20260601_sponsorship_vitrin_package` var — ancak içeriklerinin "stub" mu "MVP" mi olduğu kod-seviyesinde ayrıca doğrulanmalı
- **Etki:** Düşük-orta — admin ops manuel kalmaya devam edebilir
- **Bağımlılık:** —
- **Önerilen branch:** `feature/web-admin-sponsorship-mvp-audit` (gerekirse)
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** 3 sayfanın da gerçek RPC/veri bağlantısıyla çalıştığı doğrulanır veya eksikler tamamlanır

### Mobil — Zincir İşletmeler
- **Durum:** Açık — implementasyon başlanmamış
- **Kanıt:** `features/chains/` klasöründe 1 dosya
- **Etki:** Düşük — ileri seviye özellik
- **Bağımlılık:** —
- **Önerilen branch:** `feature/mobile-business-chains`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** Zincir işletme listesi + detay sayfası temel akışla çalışıyor

### Mobil — Grup Oy
- **Durum:** Açık — implementasyon başlanmamış
- **Kanıt:** `features/grup_oy/` klasöründe 1 dosya
- **Etki:** Düşük — P5 fikir havuzundaki "Collab lists v2" ile ilişkili olabilir
- **Bağımlılık:** Collab Lists altyapısı (`20260422000006_collab_lists.sql`) ile birleştirilebilir
- **Önerilen branch:** `feature/mobile-group-vote`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** Grup oylama akışı temel senaryoyla uçtan uca çalışıyor

### Boş Edge Function Placeholder'ları
- **Durum:** Açık — 0 satır placeholder
- **Kanıt:** `supabase/functions/wp-upload/` ve `supabase/functions/wp-upload-user/` boş dizinler
- **Etki:** Düşük — kafa karışıklığı dışında risk yok
- **Bağımlılık:** —
- **Önerilen branch:** `chore/supabase-remove-empty-edge-functions`
- **Önerilen agent:** postgres-pro
- **Kabul kriteri:** Placeholder'lar silindi veya gerçek implementasyonla dolduruldu

### Test Kapsamı Boşlukları
- **Durum:** Açık
- **Kanıt:** Personel 7 test dosyası (data/domain katmanı testsiz); Web 8 unit test dosyası (`src/lib/*` çoğu testsiz), 7 E2E spec (owner flow/2FA/taste-twin/admin flow yok); Mobil sadece offline-queue smoke testi var
- **Etki:** Orta — regresyon riski yüksek
- **Bağımlılık:** —
- **Önerilen branch:** `test/web-owner-flow-e2e`, `test/personel-data-domain-coverage`
- **Önerilen agent:** test-automator (qa-expert sistemde — en yakın: `qa-expert`)
- **Kabul kriteri:** Owner flow + 2FA + admin flow için en az birer E2E spec eklendi; personel data/domain katmanı için birim test kapsamı oluşturuldu

---

## P5 — Fikir Havuzu / Daha Sonra

- Fiyat Endeksi medya lansmanı (bkz. `docs/archive/fiyat-endeksi-medya-raporu.md` — link doğrulandı, kırık değil)
- Search Console submit (tamamlandı, ek optimizasyon yapılabilir)
- A/B test alt yapısı
- 2FA / hesap güvenliği — TOTP enroll/verify aktif ✅ (PR #84). Eski stub redirect tamamlandı ✅ (PR #85). AAL2 middleware rollout planı hazır ✅ (PR #86). Soft banner (Faz 1) tamamlandı ✅ (PR #87). Test planı + TwoFactorBanner unit testleri ✅ (PR #88, bkz. `docs/security/account-security.md`). Sıradaki: admin high-risk AAL2 middleware (Faz 2) → owner high-risk AAL2 middleware (Faz 3) → E2E smoke testleri
- Collab lists v2 (mobil "Grup Oy" özelliğiyle birleştirilebilir — bkz. P4)
