# Yeedoy — Kalan İşler

> **Son Güncelleme:** 2026-06-09 (city alias search altyapısı eklendi — bkz. `feature/city-alias-search` branch)
> **Kural:** Bu dosya tek kanonik açık iş listesidir. Yeni iş eklenince buraya yazılır. `docs/eksik-listesi.md` bu dosyaya birleştirilip silindi.
> **Şablon:** Her madde `Durum / Kanıt / Etki / Bağımlılık / Önerilen branch / Önerilen agent / Kabul kriteri` alanlarını kullanır.

---

## P0 — Release Blocker (Bunlar olmadan store yayını yapılamaz)

### Firebase Init Crash Fix
- **Durum:** ✅ Çözüldü — her iki katman da main'de doğrulandı + ek savunma katmanı eklendi
- **Kanıt:** Doğrulama (2026-06-08, `fix/mobile-p0-release-blockers` branch'inden): bu maddenin önceki notu **yanlıştı** — manifest düzeltmesinin yalnızca unmerged `store/android-screenshot-set` branch'inde (`33cb1a8`) olduğu iddiası geçersiz. Gerçek durum: (1) Dart guard commit `4f8772f` (`fix(mobile): guard firebase initialization against duplicate app`) main'de — `git merge-base --is-ancestor 4f8772f main` → YES; (2) AndroidManifest `FirebaseInitProvider` `tools:node="remove"` düzeltmesi commit `517be7b` (`fix(mobile): disable duplicate firebase auto initialization`) main'de — `git merge-base --is-ancestor 517be7b main` → YES, `uygulamalar/mobil/android/app/src/main/AndroidManifest.xml:93-100` doğrulandı. **Ek olarak** bu oturumda commit `ebc6a98` ile `lib/main.dart`'a savunma katmanı eklendi: `Firebase.initializeApp()` + `MobileAds.instance.initialize()` artık `try/catch` içinde, başarısızlık durumunda `firebaseReady=false` ile devam ediyor (Crashlytics çağrıları `if (firebaseReady)` ile korunuyor) — böylece dokümante edilmemiş bir init hatası bile artık açılışta crash'e yol açamaz.
- **Etki:** Android screenshot capture ve emulator testleri bu fixe bağlıydı — artık engel değil
- **Bağımlılık:** Yok — her iki katman main'de, ek savunma katmanı `fix/mobile-p0-release-blockers` branch'inde (PR bekliyor)
- **Önerilen branch:** `fix/mobile-p0-release-blockers` (mevcut — review + merge)
- **Önerilen agent:** mobile-developer (flutter-expert sistemde yok, en yakın uzman)
- **Kabul kriteri:** ✅ `Firebase.apps.isEmpty` guard main'de (`4f8772f`) · ✅ `FirebaseInitProvider` manifest'ten kaldırılmış (`517be7b`) · ✅ `flutter analyze lib/main.dart` → "No issues found!" · ✅ try/catch savunma katmanı eklendi (`ebc6a98`) — emulator runtime testi store/screenshot işiyle birlikte ayrıca yapılmalı (statik doğrulama tamamlandı, runtime smoke test P1'e taşındı, bkz. aşağıda)

### Android Release AAB Artifact Doğrulaması
- **Durum:** 🟡 Pipeline 3 gerçek bug'dan arındırıldı, derleme imzalama adımına kadar ilerliyor — ancak GitHub secret **değerleri** birbiriyle uyuşmuyor (kod değil, config/secret sorunu — repo sahibi tarafından çözülmeli)
- **Kanıt:** `fix/mobile-p0-release-blockers` branch'inde 3 ayrı, gerçek, önceden var olan bug bulundu ve düzeltildi (her biri CI run loglarından teşhis edildi, varsayım yapılmadı):
  1. **Geçersiz `if: secrets.X != ''` job-seviyesi syntax** (`ebc6a98`, `a5d31a0`) — GitHub Actions job-level `if:` koşullarında `secrets` context kullanılamıyor (sadece `github/needs/vars/inputs`); bu HTTP 422 ile **tüm dispatch'leri bloke ediyordu** ve **her push'ta repo genelinde hayalet "failure" run kayıtları** oluşturuyordu (`gh run list` ile doğrulandı — bu run'ların hiçbirinde gerçek job çalışmamış). Step-output gate (`steps.check.outputs.configured`) ile yeniden yazıldı.
  2. **Step sıralama / working-directory hatası** (`a5d31a0`) — "Check release signing secrets" adımı "Checkout"tan önce çalışıyor ama `defaults.run.working-directory: uygulamalar/mobil` kullanıyordu (checkout öncesi yok). Checkout ilk adıma taşındı + `working-directory: .` eklendi.
  3. **Keystore `storeFile` yol çözümleme uyuşmazlığı** (`5628d7f`) — `android/app/build.gradle.kts` içinde `file(storeFilePath)` Gradle tarafından `android/app/` dizinine göre çözümleniyordu, ama "Decode Android keystore" adımı dosyayı `android/keystore/`'a yazıyor ve `key.properties.example` "relative to android/ directory" diyor. Sonuç: Gradle `android/app/android/keystore/...` arıyordu (yanlış, var olmayan yol). `file()` → `rootProject.file()` + CI default path `'android/keystore/...'` → `'keystore/...'` olarak düzeltildi (her ikisi `android/`'a göre tutarlı).
  - **Doğrulama run'ları:** Run 1 (`27130708095`) → step-ordering hatasıyla 8s'de fail · Run 2 (`27130751947`) → keystore path hatasıyla `bundleRelease` adımında 1m23s'de fail · **Run 3 (`27130981247`, tüm 3 fix uygulanmış halde, https://github.com/mekan37/yeedoy/actions/runs/27130981247) → keystore artık DOĞRU okunuyor, build 11m9s sürdü ve `:app:signReleaseBundle` adımında şu hatayla fail oldu: `Failed to read key *** from store ".../android/keystore/yeedoy-release.keystore": No key with alias '***' found in keystore`.**
  - **Bu son hata kod/pipeline hatası DEĞİL** — `ANDROID_KEYSTORE_BASE64` secret'ının decode ettiği keystore dosyası ile `ANDROID_RELEASE_KEY_ALIAS` secret'ının değeri birbiriyle uyuşmuyor (ya yanlış keystore yüklenmiş ya da alias adı yanlış yazılmış). Secret değerlerini görme/değiştirme yetkim yok ve olmamalı.
- **Etki:** Play Store submit şu an mümkün değil — ama artık net, tek bir engel var: secret değer uyuşmazlığı (config sorunu, kod sorunu değil)
- **Bağımlılık (yeni — repo sahibi/yetkili tarafından yapılmalı):**
  1. Yerelde `ANDROID_KEYSTORE_BASE64` secret'ının kaynağı olan `.keystore`/`.jks` dosyasını `keytool -list -v -keystore <dosya>` ile aç, içindeki gerçek alias adını/adlarını gör
  2. `ANDROID_RELEASE_KEY_ALIAS` secret değerini bu gerçek alias ile eşleştir (`gh secret set ANDROID_RELEASE_KEY_ALIAS`) — ya da yanlış keystore yüklendiyse doğru `.keystore` dosyasını yeniden base64 encode edip `ANDROID_KEYSTORE_BASE64`'ü güncelle
  3. `gh workflow run mobile_release.yml --ref fix/mobile-p0-release-blockers` ile yeniden tetikle
- **Önerilen branch:** `fix/mobile-p0-release-blockers` (mevcut — pipeline fix'leri burada, review + merge edilebilir; secret düzeltmesi sonrası tekrar doğrulama gerekir)
- **Önerilen agent:** devops-engineer (pipeline) + repo sahibi (secret değerleri)
- **Kabul kriteri:** 🟡 Kısmi — ✅ pipeline 3 bug'dan arındı ve imzalama adımına kadar başarıyla ilerliyor · ❌ signed AAB henüz üretilemedi (secret uyuşmazlığı nedeniyle) · ⏳ secret düzeltmesi sonrası: CI'da signed release AAB derlenmeli, `mobile-android-aab-<run_number>` artifact'i yüklenmeli, `apksigner verify` ile imza doğrulanmalı

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

### City Alias / Search Normalizasyonu
- **Durum:** ✅ Altyapı hazır — `feature/city-alias-search` branch'inde migration'lar yazıldı, commit bekleniyor
- **Kanıt:** 3 migration dosyası oluşturuldu (2026-06-09):
  - `supabase/migrations/20260609000001_city_search_aliases.sql` — `city_search_aliases` tablosu + 9 alias seed + RLS (anon SELECT, admin write)
  - `supabase/migrations/20260609000002_normalize_tr_location.sql` — `normalize_tr_location_text()` helper fonksiyon
  - `supabase/migrations/20260609000003_update_search_rpcs_city_alias.sql` — `search_businesses_v1` ve `search_nearby_businesses_v3` alias CTE güncelleme
- **Etki:** PR #94 (chore/normalize-business-location-data) production'a alınmadan önce bu migration'lar uygulanmalı; aksi halde "İzmit"/"Adapazarı"/"Afyon"/"Antakya" aramaları boş sonuç döner
- **Bağımlılık:** PR #94 (`chore/normalize-business-location-data`) ile bağımlılık sırası:
  1. `feature/city-alias-search` → merge et ve Supabase'e uygula (20260609000001, 000002, 000003)
  2. `chore/normalize-business-location-data` (PR #94) → merge et ve Supabase'e uygula
  3. Production arama testleri: "İzmit", "Adapazarı", "Afyon", "Antakya" için sonuç döndüğünü doğrula
- **Önerilen branch:** `feature/city-alias-search` (mevcut — review + merge)
- **Önerilen agent:** postgres-pro
- **Kabul kriteri:** `SELECT * FROM city_search_aliases` 9 satır döner · `normalize_tr_location_text('İzmit') = 'izmit'` · `search_businesses_v1(p_query=>'...', p_city=>'İzmit')` Kocaeli/İzmit işletmelerini döndürür · PR #94 sonrası arama sonuçları bozmaz

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

### Admin Sponsorluk Modülü (3 Stub Sayfa) — ⛔ MVP-dışı / P2
- **Durum:** ⛔ MVP-dışı (P2) — sponsorlu görünürlük final stratejik karar raporuna
  göre (`docs/research/2026-yeedoy-stratejik-karar-raporu.md` §16) MVP'de kapalıdır.
  TR (`/yonetici/sponsorluklar` vb.) ve EN (`/admin/sponsorships`, `sponsorship-leads`,
  `sponsorship-packages`) route'ları redirect stub'a indirildi; admin nav'dan link
  kaldırıldı. Bu madde MVP kapsamında **yapılmayacaktır**; ileride P2 olarak ele alınır.
- **Kanıt:** EN/TR sayfalar artık `redirect('/admin/dashboard')` / `'/yonetici/gosterge-panosu'`
  döndürüyor. DB tarafı (sponsorship tabloları/RPC'leri, `20260601_sponsorship_vitrin_package`
  migration'ı) dokunulmadan bırakıldı — bkz. `2026-yeedoy-db-scope-cleanup-risk-report.md`.
- **Etki:** Yok (MVP) — admin ops manuel kalmaya devam eder.
- **Bağımlılık:** Ürün kararı (P2 sponsorluk stratejisi).

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
- **Kanıt:** Web 8 unit test dosyası (`src/lib/*` çoğu testsiz), 7 E2E spec (owner flow/2FA/taste-twin/admin flow yok); Mobil sadece offline-queue smoke testi var. (Not: `uygulamalar/personel` 2026-06-24'te üründen kaldırıldı; o uygulamaya ait test kapsamı maddesi de bu nedenle düştü.)
- **Etki:** Orta — regresyon riski yüksek
- **Bağımlılık:** —
- **Önerilen branch:** `test/web-owner-flow-e2e`
- **Önerilen agent:** test-automator (qa-expert sistemde — en yakın: `qa-expert`)
- **Kabul kriteri:** Owner flow + 2FA + admin flow için en az birer E2E spec eklendi

### PMTiles — S7 Mobil Performans İzleme
- **Durum:** Açık — production yayın sonrası izlenecek
- **Kanıt:** `vector_map_tiles 8.0.0` + `vector_map_tiles_pmtiles 1.5.0` entegre edildi; S7 gibi düşük güçlü cihazlarda vektör tile rendering GPU/bellek baskısı yaratabilir
- **Etki:** Orta — S7'de harita akıcılığı sorunları kullanıcı deneyimini etkiler
- **Bağımlılık:** Production kullanıcı metrikleri (Firebase Performance)
- **Önerilen branch:** `fix/mobile-map-s7-perf` (gerekirse)
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** S7 benzeri düşük güçlü cihazda harita 60fps veya >40fps render ediyor; bellek artışı 50MB altında. Sorun çıkarsa Cloudflare Worker XYZ proxy fallback'e geç (bkz. `docs/engineering/pmtiles-map-integration.md` — Rollback Planı)

### PMTiles — Leaflet Bağımlılığı Temizliği (Web)
- **Durum:** Açık — PMTiles entegrasyonu sonrası ertelenmiş teknik borç
- **Kanıt:** `leaflet`, `react-leaflet`, `@types/leaflet` `package.json`'da mevcut; `src/components/maps/` altında 6 Leaflet bileşeni (KonumGoruntuleyici, LeafletMap, LocationPickerMap, LocationPickerMapClient, BusinessMap, OsmHarita) kullanımda. Bu bileşenler harita önizlemesi/konum seçici için kullanılmakta; PMTiles keşif haritasına dahil değil
- **Etki:** Düşük — bundle boyutunu etkiler; işlevselliği bozmaz
- **Bağımlılık:** Bu 6 bileşenin PMTiles/MapLibre GL ile yeniden yazılması veya kaldırılması
- **Önerilen branch:** `chore/web-leaflet-cleanup`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** `leaflet`, `react-leaflet`, `@types/leaflet` `package.json`'dan kaldırıldı; tüm Leaflet bileşenleri MapLibre GL eşdeğeriyle değiştirildi veya silinip kullanım noktaları güncellendi; `npm run typecheck` + `npm run lint` temiz geçiyor

### Geocoding / Koordinat Backfill

**Öncelik:** Orta  
**Bağlam:** Haritada sadece gerçek lat/lng olan işletmeler gösterilmektedir. Koordinatsız işletmelerin haritada görünebilmesi için geocoding backfill gereklidir.

**Yapılacaklar:**
- [ ] `businesses` tablosundaki `lat IS NULL OR lng IS NULL` kayıtlarını say
- [ ] Google Geocoding API veya Nominatim ile adres → koordinat dönüşümü
- [ ] Toplu backfill scripti yaz (ör. `tools/geocode-backfill.mjs`)
- [ ] Backfill sonrası `lat/lng` ve `geog` kolonlarını güncelle (migration gerekmez, UPDATE yeterli)
- [ ] Yeni işletme eklendiğinde otomatik geocoding için trigger veya edge function değerlendir

- **Etki:** Orta — koordinatsız işletmeler haritada görünmüyor
- **Bağımlılık:** Provider seçimi (Google Geocoding API veya Nominatim)
- **Önerilen branch:** `chore/geocode-backfill`
- **Önerilen agent:** postgres-pro + data-engineer
- **Kabul kriteri:** `lat IS NULL OR lng IS NULL` olan işletme sayısı raporu çıktı; backfill scripti çalıştırıldı; harita sayfasında koordinatı doldurulan işletmeler marker olarak görünüyor

---

## P5 — Fikir Havuzu / Daha Sonra

- Fiyat Endeksi medya lansmanı (bkz. `docs/archive/fiyat-endeksi-medya-raporu.md` — link doğrulandı, kırık değil)
- Search Console submit (tamamlandı, ek optimizasyon yapılabilir)
- A/B test alt yapısı
- 2FA / hesap güvenliği — TOTP enroll/verify aktif ✅ (PR #84). Eski stub redirect tamamlandı ✅ (PR #85). AAL2 middleware rollout planı hazır ✅ (PR #86). Soft banner (Faz 1) tamamlandı ✅ (PR #87). Test planı + TwoFactorBanner unit testleri ✅ (PR #88, bkz. `docs/security/account-security.md`). Sıradaki: admin high-risk AAL2 middleware (Faz 2) → owner high-risk AAL2 middleware (Faz 3) → E2E smoke testleri
- Collab lists v2 (mobil "Grup Oy" özelliğiyle birleştirilebilir — bkz. P4)
