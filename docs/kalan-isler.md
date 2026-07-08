# Yeedoy — Kalan İşler

> **Son Güncelleme:** 2026-07-08 (kod audit — tamamlananlar işaretlendi, eskiler kaldırıldı)
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
- **Kanıt:** `docs/release/store-data-safety-iarc.md` detaylı taslak içeriyor
- **Etki:** Play Console'da form doldurulmadan yayın yapılamaz
- **Bağımlılık:** Play Console erişimi
- **Önerilen branch:** — (kod değişikliği yok, manuel form)
- **Önerilen agent:** project-manager
- **Kabul kriteri:** Play Console → App content → Data safety formu taslağa göre doldurulup gönderildi

### Play Console IARC Derecelendirme Formu
- **Durum:** Açık
- **Kanıt:** `docs/release/store-data-safety-iarc.md` IARC bölümü taslak içeriyor
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
- **Kanıt:** `docs/release/mobile-release-readiness.md` TR + EN release notes şablonları kullanıma hazır
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

> Detaylı entegrasyon durumu için bkz. `docs/delivery/delivery-integration-status.md`

---

## P3.5 — Güvenlik Restore İşleri

### Reviews Edge Guard Restore

**Öncelik:** Yüksek (edge functions deploy edilince yapılmalı)
**Bağlam:** `20260630000001_disable_reviews_edge_guard_trigger.sql` ile `trg_reviews_edge_guard_v1` trigger'ının içi no-op yapıldı çünkü `consume_edge_guard_event_v1` edge function deploy edilmemişti ve her yorum INSERT'i blokluyordu. Şu an anti-spam trigger devre dışı — yorum spam riski aktif.

**Yapılacaklar:**
- [ ] `anti-spam-guard` ve `write-gatekeeper` edge functions'ı deploy et
- [ ] `consume_edge_guard_event_v1` RPC'sinin çalıştığını doğrula
- [ ] `20260708000002_restore_reviews_edge_guard.sql` migration'ı yaz ve uygula:
  ```sql
  CREATE OR REPLACE FUNCTION public.enforce_reviews_edge_guard_v1()
  RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
  AS $$
  BEGIN
    PERFORM public.consume_edge_guard_event_v1(
      p_user_id   => NEW.user_id,
      p_action    => 'review_insert',
      p_entity_id => NEW.business_id
    );
    RETURN NEW;
  END;
  $$;
  COMMENT ON FUNCTION public.enforce_reviews_edge_guard_v1() IS
    'Edge guard aktif (20260708000002). anti-spam-guard edge function gerektirir.';
  ```
- [ ] Trigger'ın `BEFORE INSERT ON reviews` üzerinde aktif olduğunu doğrula
- [ ] Yorum gönderim akışını uçtan uca test et

**Bağımlılık:** `anti-spam-guard` edge function kaynak kodu + deploy erişimi
**Önerilen branch:** `fix/restore-reviews-edge-guard`
**Önerilen agent:** postgres-pro + devops-engineer
**Kabul kriteri:** Edge function deploy edildi · trigger no-op değil, gerçek guard çalışıyor · rate-limit aşıldığında yorum INSERT'i reddediliyor

---

## P4 — Web/Admin/Owner Geliştirme Backlog

### Custom Domain Doğrulama (Owner)
- **Durum:** Açık — backend hazır, UI bağlı değil
- **Kanıt:** `verify-domain` edge function yazılmış (119 satır); `owner/settings/domain` UI↔backend bağlantısı yok
- **Etki:** Orta — özel domain isteyen işletmeler için blocker
- **Önerilen branch:** `feature/web-owner-domain-verification-ui`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** Owner panelinden domain ekleyip `verify-domain` fonksiyonu üzerinden doğrulama yapılabiliyor

### AI Menü Analizi (Owner)
- **Durum:** Açık — backend hazır, panel entegrasyonu yok
- **Kanıt:** `ai-menu-analyze` edge function yazılmış (345 satır); `owner/ai-analysis` route'unda entegrasyon yok
- **Etki:** Orta — owner'lar için değer katacak özellik kullanılmıyor
- **Önerilen branch:** `feature/web-owner-ai-menu-analysis-ui`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** Owner panelinde menü analizi tetiklenip sonuçlar gösterilebiliyor

### Admin Sponsorluk Modülü (3 Stub Sayfa) — ⛔ MVP-dışı / P2
- **Durum:** ⛔ MVP-dışı (P2) — sponsorlu görünürlük final stratejik karar raporuna
  göre (`docs/research/2026-yeedoy-stratejik-karar-raporu.md` §16) MVP'de kapalıdır.
  TR/EN route'ları redirect stub'a indirildi; admin nav'dan link kaldırıldı.
  Bu madde MVP kapsamında **yapılmayacaktır**; ileride P2 olarak ele alınır.
- **Kanıt:** Sayfalar `redirect('/admin/dashboard')` döndürüyor. DB tarafı (sponsorship tabloları/RPC'leri) dokunulmadan bırakıldı.
- **Etki:** Yok (MVP) — admin ops manuel kalmaya devam eder.
- **Bağımlılık:** Ürün kararı (P2 sponsorluk stratejisi).

### Mobil — Zincir İşletmeler
- **Durum:** Açık — iskelet mevcut, tamamlanmamış
- **Kanıt:** `features/chains/ui/chain_page.dart` mevcut (1 dosya); data layer `features/business/data/business_chain_repository.dart` altında; domain providers eksik. `get_business_chain_info_v1` migration'ı (`20260629000001`) uygulanmış. Router'da `/chain/:id` rotası var.
- **Etki:** Düşük — ileri seviye özellik
- **Bağımlılık:** —
- **Önerilen branch:** `feature/mobile-business-chains`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** Zincir işletme listesi + detay sayfası temel akışla çalışıyor; domain providers tamamlandı

### Mobil — Grup Oy
- **Durum:** Açık — iskelet mevcut, tamamlanmamış
- **Kanıt:** `features/grup_oy/ui/oy_ver_sayfasi.dart` (1 dosya); data/domain layer yok
- **Etki:** Düşük — P5 fikir havuzundaki "Collab lists v2" ile birleştirilebilir
- **Bağımlılık:** Collab Lists altyapısı (`20260422000006_collab_lists.sql`) ile birleştirilebilir
- **Önerilen branch:** `feature/mobile-group-vote`
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** Grup oylama akışı temel senaryoyla uçtan uca çalışıyor

### Test Kapsamı Boşlukları
- **Durum:** Açık
- **Kanıt:** Web 8 unit test dosyası (`src/lib/*` çoğu testsiz), 7 E2E spec (owner flow/2FA/taste-twin/admin flow yok); Mobil sadece offline-queue smoke testi var. (Not: `uygulamalar/personel` 2026-06-24'te üründen kaldırıldı; o uygulamaya ait test kapsamı maddesi de bu nedenle düştü.)
- **Etki:** Orta — regresyon riski yüksek
- **Önerilen branch:** `test/web-owner-flow-e2e`
- **Önerilen agent:** qa-expert
- **Kabul kriteri:** Owner flow + 2FA + admin flow için en az birer E2E spec eklendi

### PMTiles — S7 Mobil Performans İzleme
- **Durum:** Açık — production yayın sonrası izlenecek
- **Kanıt:** `vector_map_tiles 8.0.0` + `vector_map_tiles_pmtiles 1.5.0` entegre edildi (`uygulamalar/mobil/pubspec.yaml`); S7 gibi düşük güçlü cihazlarda vektör tile rendering GPU/bellek baskısı yaratabilir
- **Etki:** Orta — S7'de harita akıcılığı sorunları kullanıcı deneyimini etkiler
- **Bağımlılık:** Production kullanıcı metrikleri (Firebase Performance)
- **Önerilen branch:** `fix/mobile-map-s7-perf` (gerekirse)
- **Önerilen agent:** mobile-developer
- **Kabul kriteri:** S7 benzeri düşük güçlü cihazda harita 60fps veya >40fps render ediyor; bellek artışı 50MB altında

### PMTiles — Leaflet Bağımlılığı Temizliği (Web)
- **Durum:** Açık — PMTiles/MapLibre GL entegrasyonu sonrası ertelenmiş teknik borç
- **Kanıt:** `leaflet ^1.9.4`, `react-leaflet ^5.0.0`, `@types/leaflet ^1.9.21` `uygulamalar/web/package.json`'da mevcut; `src/components/maps/` altında 6 Leaflet bileşeni (KonumGoruntuleyici, LeafletMap, LocationPickerMap, LocationPickerMapClient, BusinessMap, OsmHarita) kullanımda. Keşif haritası MapLibre GL'e taşındı ama bu 6 bileşen hâlâ Leaflet kullanıyor.
- **Etki:** Düşük — bundle boyutunu etkiler; işlevselliği bozmaz
- **Bağımlılık:** 6 bileşenin MapLibre GL ile yeniden yazılması veya kaldırılması
- **Önerilen branch:** `chore/web-leaflet-cleanup`
- **Önerilen agent:** nextjs-developer
- **Kabul kriteri:** `leaflet`, `react-leaflet`, `@types/leaflet` `package.json`'dan kaldırıldı; `npm run typecheck` + `npm run lint` temiz

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

- Fiyat Endeksi medya lansmanı (bkz. `docs/archive/fiyat-endeksi-medya-raporu.md`)
- Search Console submit (tamamlandı, ek optimizasyon yapılabilir)
- A/B test alt yapısı
- 2FA / hesap güvenliği — TOTP enroll/verify aktif ✅ (PR #84). Stub redirect ✅ (PR #85). AAL2 middleware rollout planı ✅ (PR #86). Soft banner (Faz 1) ✅ (PR #87). Test planı + TwoFactorBanner unit testleri ✅ (PR #88). Sıradaki: admin high-risk AAL2 middleware (Faz 2) → owner high-risk AAL2 middleware (Faz 3) → E2E smoke testleri
- Collab lists v2 (mobil "Grup Oy" özelliğiyle birleştirilebilir — bkz. P4)

---

## Tamamlananlar

> Bu bölüm, daha önce açık olan veya bu audit sırasında doğrulanan tamamlanmış maddeleri içerir.

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

| Fonksiyon | Yerine | Son Tarih |
|---|---|---|
| `approve_business_suggestion` | `admin_approve_business_suggestion_v1` | 2026-08-01 |
| `approve_owner_claim` | `admin_decide_owner_claim_v1` | 2026-08-01 |
| `reject_business_suggestion` | `admin_reject_business_suggestion_v1` | 2026-08-01 |
| `create_owner_claim` | `submit_owner_claim_v1` | 2026-08-01 |
| `get_top_businesses` | `get_top_businesses_period_v1` | 2026-08-01 |
| `search_nearby_businesses_v1` | `search_nearby_businesses_v3` | 2026-09-01 |
| `search_nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 |
| `admin_list_business_suggestions_v1` | `admin_list_business_suggestions_v3` | 2026-09-01 |
| `nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 |
