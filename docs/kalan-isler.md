# Yeedoy — Kalan İşler

> **Son Güncelleme:** 2026-08-17 (kod audit — dosya 5+ hafta bayattı; her madde git/kod ile tek tek yeniden doğrulandı, çoğu "açık" madde aslında tamamlanmış ama nav/flag arkasında kilitliymiş)
> **Kural:** Bu dosya tek kanonik açık iş listesidir. Yeni iş eklenince buraya yazılır. `docs/eksik-listesi.md` bu dosyaya birleştirilip silindi.
> **Şablon:** Her madde `Durum / Kanıt / Etki / Bağımlılık / Önerilen branch / Önerilen agent / Kabul kriteri` alanlarını kullanır.

---

## P0 — Release Blocker (Bunlar olmadan store yayını yapılamaz)

### Android Release AAB Artifact Doğrulaması
- **Durum:** 🟡 Pipeline 3 gerçek bug'dan arındırıldı, derleme imzalama adımına kadar ilerliyor — ancak GitHub secret **değerleri** birbiriyle uyuşmuyor (kod değil, config/secret sorunu — repo sahibi tarafından çözülmeli)
- **Kanıt:** `fix/mobile-p0-release-blockers` branch'inde 3 ayrı, gerçek, önceden var olan bug bulundu ve düzeltildi (her biri CI run loglarından teşhis edildi, varsayım yapılmadı):
  1. **Geçersiz `if: secrets.X != ''` job-seviyesi syntax** (`ebc6a98`, `a5d31a0`) — GitHub Actions job-level `if:` koşullarında `secrets` context kullanılamıyor; HTTP 422 ile tüm dispatch'leri bloke ediyordu. Step-output gate (`steps.check.outputs.configured`) ile yeniden yazıldı.
  2. **Step sıralama / working-directory hatası** (`a5d31a0`) — "Check release signing secrets" adımı "Checkout"tan önce çalışıyordu. Checkout ilk adıma taşındı.
  3. **Keystore `storeFile` yol çözümleme uyuşmazlığı** (`5628d7f`) — `file()` → `rootProject.file()` + CI default path düzeltildi.
  - **Son hata:** `ANDROID_KEYSTORE_BASE64` ile `ANDROID_RELEASE_KEY_ALIAS` uyuşmuyor (config sorunu, kod sorunu değil).
- **Etki:** Play Store submit şu an mümkün değil
- **Bağımlılık (repo sahibi/yetkili tarafından yapılmalı):**
  1. `.keystore` dosyasını `keytool -list -v -keystore <dosya>` ile aç, alias adını gör
  2. `ANDROID_RELEASE_KEY_ALIAS` secret değerini düzelt (`gh secret set ANDROID_RELEASE_KEY_ALIAS`)
  3. `gh workflow run mobile_release.yml --ref fix/mobile-p0-release-blockers` ile yeniden tetikle
- **Önerilen branch:** `fix/mobile-p0-release-blockers` (pipeline fix'leri hazır — secret düzeltmesi sonrası test)
- **Önerilen agent:** devops-engineer + repo sahibi
- **Kabul kriteri:** CI'da signed release AAB derlendi · `apksigner verify` ile imza doğrulandı

---

## P1 — Store Yayın Hazırlığı

### Android Store Screenshots (0/8 main'de — 8/8 unmerged branch'te hazır)
- **Durum:** 🟡 Çözüme çok yakın — unmerged branch'te tamamlanmış halde duruyor
- **Kanıt:** `store/android-screenshot-set` branch'i (commit `33cb1a8`) 8 adet 1280×2856px Android ekran görüntüsü içeriyor. main'de henüz yok.
- **Etki:** Play Store Store Listing yükleme bu görsellere bağlı
- **Bağımlılık:** P0 AAB branch'i ile birlikte merge edilmeli
- **Önerilen branch:** `store/android-screenshot-set` (mevcut — review + merge)
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** 8 PNG dosyası main'de `store-assets/screenshots/android/` altında

### iOS Store Screenshots (0/8)
- **Durum:** Açık — macOS + Xcode gerekiyor
- **Kanıt:** `store-assets/screenshots/ios/` dizini boş
- **Etki:** App Store Connect'e yükleme bu görsellere bağlı
- **Bağımlılık:** macOS cihaz erişimi
- **Önerilen branch:** `store/ios-screenshots`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** iPhone 14 Plus (1284×2778) + iPhone 8 Plus (1242×2208) için 8'er ekran görüntüsü

### Play Console Data Safety Manuel Giriş
- **Durum:** Açık — taslak hazır
- **Kanıt:** `docs/yayin/store-data-safety-iarc.md` detaylı taslak içeriyor
- **Etki:** Play Console'da form doldurulmadan yayın yapılamaz
- **Bağımlılık:** Play Console erişimi
- **Önerilen branch:** — (kod değişikliği yok, manuel form)
- **Önerilen agent:** project-manager
- **Kabul kriteri:** Play Console → App content → Data safety formu taslağa göre doldurulup gönderildi

### Play Console IARC Derecelendirme Formu
- **Durum:** Açık
- **Kanıt:** `docs/yayin/store-data-safety-iarc.md` IARC bölümü taslak içeriyor
- **Etki:** IARC derecelendirmesi olmadan store listing tamamlanamaz
- **Bağımlılık:** Play Console erişimi
- **Önerilen branch:** —
- **Önerilen agent:** project-manager
- **Kabul kriteri:** IARC formu gönderildi, derecelendirme sertifikası alındı

### Internal Testing / Beta Testers
- **Durum:** Açık — henüz tester davet edilmedi
- **Etki:** Crash/feedback verisi olmadan public release riskli
- **Bağımlılık:** Signed AAB (P0) + ekran görüntüleri (P1)
- **Önerilen branch:** —
- **Önerilen agent:** project-manager
- **Kabul kriteri:** 5-10 tester Play Console → Testing → Internal testing kanalına eklendi, en az 3 gün geri bildirim toplandı

### Release Notes Final Kontrol
- **Durum:** 🟡 Taslak hazır, son gözden geçirme gerekiyor
- **Kanıt:** `docs/yayin/mobile-release-readiness.md` TR + EN release notes şablonları kullanıma hazır
- **Etki:** Düşük — taslak zaten kullanılabilir durumda
- **Önerilen agent:** content-marketer
- **Kabul kriteri:** TR/EN release notes onaylandı, store listing'e yapıştırıldı

### Store Asset Upload Checklist
- **Durum:** Açık — kısmen tamamlandı
- **Kanıt:** Hazır: `store-assets/icon/yeedoy-master-icon-1024.png` ✅, `store-assets/icon/yeedoy-play-icon-512.png` ✅, `store-assets/feature/yeedoy-feature-graphic-1200x500.png` ✅. Eksik: Android screenshots main'de yok (unmerged branch'te hazır), iOS screenshots hiç yok.
- **Etki:** Store listing tamamlanamaz
- **Bağımlılık:** Screenshot maddeleri
- **Kabul kriteri:** Tüm asset checklist ✅ — icon, feature graphic, 8 Android + 8 iOS screenshot

---

## P2 — Runtime Env / Dış Entegrasyonlar

> Detaylı entegrasyon durumu için bkz. `docs/bildirim-teslimati/delivery-integration-status.md`

---

## P4 — Web/Admin/Owner Geliştirme Backlog

### AI Menü Analizi (Owner) — ⛔ insan kararı bekliyor
- **Durum:** ⛔ Kod tamamen hazır ve daha önce bağlanmıştı (`a136f1b6`, 2026-06-04:
  `yapay-zeka-analiz-islemi.ts` + `yapay-zeka-analiz-karti.tsx`, `ai-menu-analyze`
  edge function'a bağlı), ama sonradan bilinçli olarak kilitlendi. Sayfa şu an
  koşulsuz `redirect('/sahip/gosterge-panosu')` döndüren bir stub —
  kaynak yorumu: *"AI menü analizi ürün kararı netleşmeden kapsam dışı
  tutulmuştur (NEEDS_HUMAN_DECISION)"*.
- **Kanıt:** `app/sahip/yapay-zeka-analizi/page.tsx`. Referans verdiği
  `docs/muhendislik/2026-yeedoy-mvp-scope-prune-audit.md` artık repo'da yok.
- **Etki:** Yok (kasıtlı) — açılırsa gerçek bir feature, teknik iş yok.
- **Bağımlılık:** Ürün kararı — özellik açılsın mı, kapalı mı kalsın?
- **Önerilen branch:** — (kod zaten var, sadece stub'ı kaldırıp gerçek page'i geri almak yeterli)
- **Kabul kriteri:** Karar netleşince: ya stub kalıcı hale getirilip kod silinir, ya da redirect kaldırılıp `REPLICATE_API_TOKEN`/`OPENROUTER_API_KEY` secret'ları doğrulanarak açılır.

### Mobil — Grup Oy — ⛔ insan kararı bekliyor
- **Durum:** ⛔ Kod tamamen hazır (data: `collab_list_repository.dart`
  `fetchGroupVoteData`/`upsertVote`; UI: `oy_ver_sayfasi.dart`, tam işlevsel),
  ama `/group-vote/:token` route'u router.dart'ta koşulsuz `redirect: (c,s) =>
  '/discover'` ile kilitli. Kaynak yorumu: *"MVP scope dışı: grup oylama
  (sosyal kapsam) MVP'de kapalı"*.
- **Etki:** Yok (kasıtlı) — açılırsa gerçek bir feature, teknik iş yok.
- **Bağımlılık:** Ürün kararı — özellik açılsın mı, kapalı mı kalsın?
- **Kabul kriteri:** Karar netleşince: redirect kaldırılır ve nav'a bir giriş noktası eklenir (collab_lists ile birleştirme değerlendirilebilir).

### Admin Sponsorluk Modülü (3 Stub Sayfa) — ⛔ MVP-dışı / P2
- **Durum:** ⛔ MVP-dışı (P2) — sponsorlu görünürlük final stratejik karar raporuna
  göre (`docs/research/2026-yeedoy-stratejik-karar-raporu.md` §16) MVP'de kapalıdır.
  TR/EN route'ları redirect stub'a indirildi; admin nav'dan link kaldırıldı.
  Bu madde MVP kapsamında **yapılmayacaktır**; ileride P2 olarak ele alınır.
- **Kanıt:** Sayfalar `redirect('/admin/dashboard')` döndürüyor. DB tarafı (sponsorship tabloları/RPC'leri) dokunulmadan bırakıldı.
- **Etki:** Yok (MVP) — admin ops manuel kalmaya devam eder.
- **Bağımlılık:** Ürün kararı (P2 sponsorluk stratejisi).

### PMTiles — S7 Mobil Performans İzleme
- **Durum:** Açık — production yayın sonrası izlenecek
- **Kanıt:** `vector_map_tiles 8.0.0` + `vector_map_tiles_pmtiles 1.5.0` entegre edildi (`uygulamalar/mobil/pubspec.yaml`); S7 gibi düşük güçlü cihazlarda vektör tile rendering GPU/bellek baskısı yaratabilir
- **Etki:** Orta — S7'de harita akıcılığı sorunları kullanıcı deneyimini etkiler
- **Bağımlılık:** Production kullanıcı metrikleri (Firebase Performance)
- **Önerilen branch:** `fix/mobile-map-s7-perf` (gerekirse)
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** S7 benzeri düşük güçlü cihazda harita 60fps veya >40fps render ediyor; bellek artışı 50MB altında

---

## P5 — Fikir Havuzu / Daha Sonra

- Fiyat Endeksi medya lansmanı
- Search Console submit (tamamlandı, ek optimizasyon yapılabilir)
- A/B test alt yapısı
- 2FA / hesap güvenliği — TOTP enroll/verify aktif ✅ (PR #84). Stub redirect ✅ (PR #85). AAL2 middleware rollout planı ✅ (PR #86). Soft banner (Faz 1) ✅ (PR #87). Test planı + TwoFactorBanner unit testleri ✅ (PR #88). Sıradaki: admin high-risk AAL2 middleware (Faz 2) → owner high-risk AAL2 middleware (Faz 3) → E2E smoke testleri
- Collab lists v2 (mobil "Grup Oy" özelliğiyle birleştirilebilir — bkz. P4)

---

## Tamamlananlar

> Bu bölüm, daha önce açık olan veya bu audit sırasında doğrulanan tamamlanmış maddeleri içerir.

### Reviews Edge Guard Restore ✅
- **Kanıt:** `trg_reviews_edge_guard_v1` trigger'ı `reviews` tablosunda `BEFORE INSERT` ile aktif; `enforce_reviews_edge_guard_v1()` gerçekten `consume_edge_guard_event_v1('review_submit', business_id, 900)` çağırıyor (no-op değil). `anti-spam-guard` ve `write-gatekeeper` edge function'ları production'da `ACTIVE`. Migration hangi dosyada yapıldığı bu audit'te bulunamadı ama DB'de doğrulandı (2026-08-17).

### Custom Domain Doğrulama (Owner) ✅
- **Kanıt:** `/sahip/ayarlar/alan-adi` sayfası, formu ve server action'ları (`alan-adi-formu.tsx`, `alan-adi-islemleri.ts`) tam ve `verify-domain` edge function + `upsert/get/delete_custom_domain_v1` RPC'lerine bağlıydı; tek eksik `app/sahip/ayarlar/page.tsx`'teki nav girişinin `disabled: true` bırakılmış olmasıydı. 2026-08-17'de `disabled: false` yapıldı.

### Mobil — Zincir İşletmeler ✅
- **Kanıt:** `business_chain_repository.dart`, `chain_info.dart`, `chain_page.dart` ve `business_page.dart`'taki zincir rozeti tam bağlıydı (`get_business_chain_info_v1`, `get_chain_overview_v1/v2`). Tek eksik router.dart'ta `/chain` rotasının unutulmuş bir `enableLabs` guard'ı arkasında kilitli olmasıydı. 2026-08-17'de guard kaldırıldı.

### Test Kapsamı Boşlukları ✅ (madde bayatlamıştı)
- **Kanıt:** Web'de 25 unit test dosyası + 8 E2E spec (owner flow dahil), mobilde 78 test dosyası mevcut (2026-08-17 itibarıyla).

### PMTiles — Leaflet Bağımlılığı Temizliği (Web) ✅ (madde bayatlamıştı)
- **Kanıt:** `leaflet`, `react-leaflet`, `@types/leaflet` artık `package.json`'da yok (2026-08-17 itibarıyla).

### Geocoding / Koordinat Backfill ✅
- **Kanıt:** `lat IS NULL OR lng IS NULL` olan aktif işletme sayısı 1'di (55K+ OSM/FSQ import'undan sonra); tek kayıt bir demo işletmeydi ("Örnek Yeedoy Şube 2"). Nominatim ile Çankaya/Ankara ilçe merkezi koordinatı (39.8853321, 32.8554966) bulunup `lat`/`lng`/`geog` dolduruldu. 2026-08-17 itibarıyla eksik koordinatlı aktif işletme sayısı 0.

### Firebase Init Crash Fix ✅
- **Kanıt:** Dart guard `4f8772f` main'de; AndroidManifest `FirebaseInitProvider` kaldırması `517be7b` main'de; `try/catch` savunma katmanı `ebc6a98` eklendi.

### City Alias / Search Normalizasyonu ✅
- **Kanıt:** 3 migration main'de mevcut: `20260609000001_city_search_aliases.sql`, `20260609000002_normalize_tr_location.sql`, `20260609000003_update_search_rpcs_city_alias.sql`; hata düzeltmesi `20260609000004_fix_normalize_tr_location_combining_dot.sql` de uygulandı. `search_businesses_v1` ve `search_nearby_businesses_v3` alias CTE güncellendi.

### Firebase FCM Runtime Env ✅
- **Kanıt:** `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` — `gh secret list` ile doğrulandı; PR #52 FCM delivery kodu deploy edildi.

### Profil Sosyal Bağlantı Kaydetme ✅
- **Kanıt:** Migration `20260603000011_user_profiles_social_links.sql` mevcut; `features/profile/data/profile_repository.dart:80` payload'a yazıyor.

### estimate_email_segment_v1 — follower_id Düzeltmesi ✅
- **Kanıt:** Migration `20260603000010_fix_estimate_email_segment_v1.sql` uygulandı.

### business_automations RLS ✅
- **Kanıt:** Migration mevcut, PR #50 merge edildi.

### PMTiles / MapLibre GL Web Harita Entegrasyonu ✅
- **Kanıt:** `uygulamalar/web/src/ui/acik/harita-istemcisi.tsx` mevcut; `maplibre-gl: ^5.24.0` ve `pmtiles: ^4.4.1` `package.json`'da; `app/(genel)/kesif/harita/harita-sarmalayici.tsx` route'u bağlı.

### vector_map_tiles Mobil Harita Entegrasyonu ✅
- **Kanıt:** `vector_map_tiles: ^8.0.0` ve `vector_map_tiles_pmtiles: ^1.5.0` `uygulamalar/mobil/pubspec.yaml`'da mevcut.

### WebP Görseller ✅
- **Kanıt:** `uygulamalar/web/public/` altında `hero-gorsel.webp`, `giris-gorsel.webp`, `burger.webp`, `cafe.webp`, `doner.webp`, `kahvalti.webp` ve diğer WebP dosyalar mevcut.

### Rate Limiting Harita API ✅
- **Kanıt:** `uygulamalar/web/app/api/harita-isletmeler/route.ts` içinde `rateLimit('harita:{identity}', 60, 60_000)` kullanımda.

### Profil Stat Kartları Tıklanabilir ✅
- **Kanıt:** `_ClickableStatCell` sınıfı `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` içinde mevcut.

### Ziyaret Takibi ✅
- **Kanıt:** `_trackBusinessPageView` metodu `uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart` içinde mevcut.

### Collab Lists Mobil ✅
- **Kanıt:** `lib/features/collab_lists/` altında `data/`, `domain/`, `ui/` tam yapı; migration `20260422000006_collab_lists.sql` uygulandı; router'da `/collab-lists`, `/collab-lists/join`, `/collab-lists/:id` rotaları mevcut.

### Weekly Leaderboard ✅
- **Kanıt:** `20260422000004_weekly_leaderboard.sql` — `get_weekly_contributor_leaderboard_v1` RPC uygulandı; `features/heroes/` altında UI mevcut.

### Verified Visit Badge ✅
- **Kanıt:** `20260422000001_verified_visit_badge.sql` uygulandı; `features/reviews/domain/review.dart` içinde `verifiedVisit` alanı; `business_reviews_page.dart` içinde badge gösterimi mevcut.

### Feedback API (Web) ✅
- **Kanıt:** `uygulamalar/web/app/api/feedback/route.ts` mevcut; migration `20260422000002_menu_feedback.sql` uygulandı.

### Rozet / Achievements Sistemi ✅
- **Kanıt:** `20260707000002_achievements_extended.sql` uygulandı; `lib/features/profile/ui/components/achievements_grid.dart` ve `lib/features/profile/domain/achievements_provider.dart` mevcut.

### get_business_badges_v1 + get_business_reviews_v4 ✅
- **Kanıt:** `20260707000003_business_badges_reviews_v4.sql` migration'ı uygulandı.

### submit_business_suggestion_v1 + Anon Rate Limit ✅
- **Kanıt:** `20260703000001_business_suggestions_anon_insert.sql` — `submit_business_suggestion_v1` RPC oluşturuldu; `20260708000001_business_suggestions_anon_ratelimit.sql` — rate limit guard eklendi.

### Deprecated RPC'ler (Hatırlatma: Deadline 2026-08-01 / 2026-09-01)

| Fonksiyon | Yerine | Son Tarih | Durum |
|---|---|---|---|
| `approve_business_suggestion` | `admin_approve_business_suggestion_v1` | 2026-08-01 | ✅ 2026-08-17'de DROP edildi (`20260817000001`) |
| `approve_owner_claim` | `admin_decide_owner_claim_v1` | 2026-08-01 | ✅ 2026-08-17'de DROP edildi (`20260817000001`) |
| `reject_business_suggestion` | `admin_reject_business_suggestion_v1` | 2026-08-01 | ✅ 2026-08-17'de DROP edildi (`20260817000001`) |
| `create_owner_claim` | `submit_owner_claim_v1` | 2026-08-01 | ✅ 2026-08-17'de DROP edildi (`20260817000001`) |
| `get_top_businesses` | `get_top_businesses_period_v1` | 2026-08-01 | ⛔ **KALDIRILMADI** — fonksiyon `DANGEROUS_TO_REMOVE: still referenced by app/runtime paths` yorumuyla işaretli, hâlâ aktif çağrı yolu var. Kaldırmadan önce gerçek caller'lar bulunup `_v1`'e taşınmalı. |
| `search_nearby_businesses_v1` | `search_nearby_businesses_v3` | 2026-09-01 | Açık (deadline henüz gelmedi) |
| `search_nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 | Açık (deadline henüz gelmedi) |
| `admin_list_business_suggestions_v1` | `admin_list_business_suggestions_v3` | 2026-09-01 | Açık (deadline henüz gelmedi) |
| `nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 | Açık (deadline henüz gelmedi) |
