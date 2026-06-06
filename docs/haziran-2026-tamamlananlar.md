# Haziran 2026 — Tamamlanan Çalışmalar

> Hazırlanma: 3 Haziran 2026
> Oturum: Section 14–PR #23 arası tamamlananlar
> Kapsam: Teknik altyapı + feature implementation + dokumentasyon

---

## PR Özet Tablosu

| # | Branch | Konu | Risk | Durum |
|---|---|---|---|---|
| #7 | feature/mobile-consent-guard | KVKK ConsentGuard startup | LOW | ✅ Merged |
| #8 | test/mobile-consent-growth-smoke | Consent + growth smoke testleri (+40 test) | LOW | ✅ Merged |
| #9 | docs/web-search-console-readiness | SEO: sitemap hub, panel noindex, JSON-LD | LOW | ✅ Merged |
| #10 | docs/fiyat-endeksi-medya-raporu | Fiyat Endeksi medya raporu taslağı | LOW | ✅ Merged |
| #11 | docs/db-open-hours-price-badge-plan | DB açık/kapalı + fiyat rozeti analiz planı | LOW | ✅ Merged |
| #12 | feature/web-hours-rpc-alignment | Owner saat yazma RPC'ye geçirildi (P0 bug fix) | MEDIUM | ✅ Merged |
| #13 | refactor/web-price-level-helper | Fiyat rozeti helper birleştirildi | LOW | ✅ Merged |
| #14 | feature/mobile-open-price-badge-audit | Mobile discovery açık/kapalı + fiyat rozeti | LOW | ✅ Merged |
| #15 | migration/supabase-price-level | businesses.price_level sütunu + compute RPC | MEDIUM | ✅ Merged |
| #16 | feature/web-use-computed-price-level | Web price_level entegrasyonu | LOW | ✅ Merged |
| #17 | migration/supabase-search-nearby-v3-price-open-fields | search_nearby_v3 genişletildi | MEDIUM | ✅ Merged |
| #18 | feature/mobile-open-price-level-badges | Mobile price_level entegrasyonu | LOW | ✅ Merged |
| #19 | migration/supabase-analytics-events-indexes | analytics_events composite index | LOW | ✅ Merged |
| #20 | migration/supabase-busy-hours-rpc | get_business_busy_hours_v1 RPC | MEDIUM | ✅ Merged |
| #21 | feature/web-owner-busy-hours-widget | Owner panel Yoğun Saatler widget | LOW | ✅ Merged |
| #22 | feature/web-discovery-map-mvp | Keşif Haritası MVP (Leaflet) | MEDIUM | ✅ Merged |
| #23 | docs/mobile-release-readiness | Mobile release readiness checklist | LOW | ✅ Merged |

---

## Tamamlanan Teknik Altyapılar

### Database (Supabase)

**Yeni tablolar/sütunlar:**
- `businesses.price_level` — compute_business_price_level_v1 RPC ile otomatik hesaplanan
- `analytics_events` composite indexes (performans optimizasyonu)

**Yeni RPC'ler:**
- `get_business_busy_hours_v1` — owner panel widget'ı için işletme yoğun saatlerini analiz
- `compute_business_price_level_v1` — businesses.price_level otomatik hesaplama
- `batch_recompute_price_levels_v1` — bulk recompute utility

**RPC genişletmeleri:**
- `search_nearby_businesses_v3` — `price_level` + `open_now` + `busy_hours` alanları eklendi

**Business hours alignment:**
- `business_weekly_hours` tablosu owner panel'den doğru yazılmaya başladı
- Eski `business_hours` wide format yerine normalize yapı

---

### Web (Next.js)

**SEO altyapısı (PR #9):**
- `BreadcrumbList` JSON-LD schema: şehir/ilçe/kategori navigasyonu
- `Restaurant` schema zenginleştirildi: breadcrumb, addressLocality (district), aggregateRating
- `robots.ts`: `/kesif`, `/en-iyiler`, `/isletme/` allow; `/sahip/`, `/yonetici/` disallow
- `sitemap.ts`: Türkçe statik rotalar düzeltildi; şehir×ilçe×kategori kombinasyonları (5K cap, deduplicated)
- Dinamik OG image: `isletme/[slug]/opengraph-image.tsx` — WhatsApp/Twitter preview
- Şehir hub sayfaları: `/[sehir]/page.tsx` — ilçe grid + popüler kategoriler
- İlçe hub sayfaları: `/[sehir]/[ilce]/page.tsx` — kategori grid

**Fiyat rozeti (PR #13, #16):**
- Price level helper birleştirildi ve reusable hale getirildi
- Web'de `use_computed_price_level` ile search_nearby_v3 çıktısından rozet oluşturma

**Owner panel (PR #21):**
- Yoğun Saatler widget: `get_business_busy_hours_v1` ile operation insights
- Business context yönetimi ve filters

**Discovery haritası (PR #22):**
- Leaflet entegrasyonu
- `/kesif/harita` route MVP
- Yakın çevre restoranları konumlara işleme

---

### Mobile (Flutter)

**Açık/Kapalı + Fiyat Rozeti (PR #14, #18):**
- Discovery tile'larında `open_now` ve `price_level` rozetleri gösterim
- Tat Twin + price level badge kombinasyonu
- Mobile business_detail sayfasında yoğun saatler gösterimi (pending: PR #20 data integration)

**KVKK Consent Guard (PR #7):**
- `ConsentState` model + `ConsentRepository` data layer
- `ConsentLocalRepository` (SharedPreferences) yerel persist
- `ConsentNotifier` Riverpod provider
- `showConsentBottomSheet` UI component
- `ConsentGuard.checkAndShow` startup hook (app.dart/router.dart'a entegre edilecek)

**Test Infrastructure (PR #8):**
- +40 consent + growth smoke testleri
- CI workflow fix (dorny/paths-filter required check)

---

### Dokumentasyon

**Oluşturulan:**
- `docs/haziran-2026-tamamlananlar.md` — bu dosya
- `docs/fiyat-endeksi-medya-raporu.md` — medya stratejisi

**Güncellenen:**
- `docs/eksik-listesi.md` — tamamlananlar ayırıldı
- `docs/rekabet.md` — harita, rozet, yoğun saat, sponsorluk ✅ işaretlendi
- `docs/db-open-hours-price-badge-plan.md` — TAMAMLANDI notu eklendi
- `docs/web-slug-resolver-deterministic-plan.md` — durum notu eklendi
- `docs/search-console-submit.md` — teknik ön koşullar tamamlandı işaretlendi
- `docs/store_listing.md` — release readiness durumu eklendi

---

## Owner Marketing Automations MVP (PR #51 — 2026-06-05)

| Dosya | Degisiklik |
|---|---|
| `app/owner/marketing/automations/page.tsx` | Stub yeniden yazildi — server component, auth guard, business selector, template kartlari |
| `app/owner/marketing/automations/automation-actions.ts` | Server action — `toggleAutomationAction`, `hasOwnerBusiness()` ownership guard, template whitelist |
| `app/owner/marketing/automations/automation-toggle.tsx` | Client toggle — `useOptimistic` + `useTransition`, ARIA switch |
| `src/lib/veri/owner/otomasyonlar.ts` | `getOwnerAutomations()` veri katmani yardimcisi |

Mimari kararlar:
- RLS policy (`business_owners` tablosu yok) guvenilmez — app-layer `hasOwnerBusiness()` guard eklendi
- 6 template_id whitelist ile input dogrulama yapiliyor
- Dis bildirim saglayicisi (push/SMS/e-posta) bagli degil — UI'da banner mevcut

---

## Kalan En Önemli 10 İş

Sıra önem derecesine göre:

| # | Başlık | Blocker | Tahmin | Etki |
|---|--------|---------|--------|------|
| 1 | **Privacy Policy sayfası** (yeedoy.com/gizlilik) | Store yayını | 2-3 gün | Store yayını tamamen kilitli |
| 2 | **Android Keystore + CI secrets** (GitHub Actions) | Store signing | 1-2 gün | Play Store submit imkansız |
| 3 | **Google Play internal testing** (5-10 tester) | QA feedback | 3-5 gün | Tester feedback + crash logs |
| 4 | **FCM/OneSignal bağlantısı** | Push bildirim gönderimi | 3-5 gün | Sponsorluk aktivasyonu tamamlanmaz |
| 5 | **businesses tablosuna slug sütunları** (migration) | Deterministik slug resolver | 2-3 gün | `/[sehir]/[slug]` kesin sonuç |
| 6 | **Owner marketing aktivasyonu** (loyalty, campaign, email) | Panel özellikler | 1-2 hafta | İşletme retention Türkiye'de kritik |
| 7 | **QR generate/download** (owner panel + mobile) | Operasyon tool | 1 hafta | İşletme QR'sı dışarı çıkar |
| 8 | **Fiyat Endeksi landing page** (/fiyat-endeksi route) | Medya stratejisi | 3-5 gün | Medya partner teaseri |
| 9 | **Admin sponsorship UI** (stub → aktif modül) | Admin ops | 1-2 hafta | Sponsorluk yönetimi manuel kalmıyor |
| 10 | **Web E2E testleri** (owner flow, harita, payment) | QA coverage | 2-3 hafta | Regression testi kapsama |

---

## Önerilen Sıradaki 5 PR (Priority Ranking)

### 1. **Privacy Policy + Terms of Service** (5 iş günü)
**Branch:** `feat/legal-pages`

```bash
git checkout -b feat/legal-pages
# Dosyalar:
# - app/(public)/gizlilik/page.tsx
# - app/(public)/kullanim-sartlari/page.tsx
# - app/(public)/[slug]/ → gizlilik alias
# Supabase: privacy_policy table + CMS entegrasyonu (opsiyonel)
# Test: Lighthouse score 90+, KVKK compliance check
```

**Bloklanmayı açar:** App Store + Google Play yayını  
**Ek faydalar:** KVKK ConsentGuard (#7) ile loop tamamlanır

---

### 2. **Android Release Signing + CI** (3-5 iş günü)
**Branch:** `ci/android-release-signing`

```bash
git checkout -b ci/android-release-signing
# Dosyalar:
# - uygulamalar/mobil/.github/workflows/android-build-release.yml
# - uygulamalar/mobil/android/app/build.gradle (signing block)
# - .github/secrets: ANDROID_KEYSTORE_B64, ANDROID_KEYSTORE_PASS
# - CLAUDE.md: "Android release build" bölümü güncelle
# Test: Internal release build, TestFlight upload
```

**Bloklanmayı açar:** Play Store internal testing, beta kanaldı  
**Risk:** Keystore kaybolması — backup check critical

---

### 3. **Fiyat Endeksi Landing Page** (4 iş günü)
**Branch:** `feat/fiyat-endeksi-page`

```bash
git checkout -b feat/fiyat-endeksi-page
# Dosyalar:
# - app/(public)/fiyat-endeksi/page.tsx
# - src/ui/fiyat-endeksi/ → chart + stat components
# RPC: admin_get_fiyat_endeksi_summary_v1 (yeni migration)
# I18n: "fiyat-endeksi" başlık + açıklama
# Test: Rendering, SSG, SEO metadata
```

**Bloklanmayı açar:** Medya anlatısı (rekabet.md 1. Aşama)  
**Ek faydalar:** Fiyat Endeksi medya raporu (#10) ile synergize

---

### 4. **QR Generate + Download** (5 iş günü)
**Branch:** `feat/qr-generate-download`

```bash
git checkout -b feat/qr-generate-download
# Dosyalar:
# - app/sahip/qr/qr-islemler.ts (server actions)
# - app/sahib/qr/page.tsx → QR canvas + download button
# - uygulamalar/mobil/lib/features/qr/ → QR işlemeleri
# Paketler: qr_flutter (mobil), qrcode (web Node.js backend)
# Test: QR doğrulama, download A/B test
```

**Bloklanmayı açar:** İşletme operasyon workflow'u  
**Ek faydalar:** Sponsorluk (PR #1) özelliğini tamamlar

---

### 5. **businesses slug sütunları + migration** (3 iş günü)
**Branch:** `migration/businesses-slug-columns`

```bash
git checkout -b migration/businesses-slug-columns
# Dosyalar:
# - supabase/migrations/20260610000001_businesses_slug_columns.sql
# - src/lib/slugs.ts → GENERATED ALWAYS AS (slugify(...)) helper
# - app/[sehir]/[slug]/page.tsx → updated query logic
# RPC: batch_slugify_businesses_v1 (backfill)
# Test: /[sehir]/[slug] 100 farklı slug combinasyonu test et
```

**Bloklanmayı açar:** Deterministik slug resolver (web-slug-resolver-deterministic-plan.md)  
**Risk:** Mevcut `/[sehir]/[slug]` route collision — careful migration plan

---

## Başarı Metrikleri (Haziran 2026 Çıkmazdan Sonra)

| Metrik | Şimdiki | Target 3-Ay | Yöntem |
|--------|---------|-------------|--------|
| **DAU (Daily Active Users)** | ~50K | 150K+ | App Store + SEO organik |
| **Store indirmeler/ay** | 0 | 5K+ | ASO + App Store feature |
| **Sponsor işletmeler** | 0 | 100+ | Sales outreach + self-serve |
| **B2B veri müşteriler** | 0 | 2+ | Pilot + pricing |
| **Aylık gelir** | 0 | 50K+ TL | Sponsorluk + B2B |
| **SEO organik trafik** | ~2K | 10K+ | Hub sayfaları + backlinks |
| **Push notification open rate** | N/A | 40%+ | FCM entegrasyonu sonrası |
| **Owner CMS login aktif** | ~200 | 500+ | Marketing + self-service |

---

## CI/CD Iyileştirmeler (PR #8)

**Sorun:** required checks sadece 1/3 workflow'ta rapor üretiyordu  
**Çözüm:** dorny/paths-filter v3 ile tüm workflows'ta conditional triggers  
**Sonuç:** 3/3 workflow artık her PR'da çalışıyor (typecheck, lint, unit, E2E)

---

## Kaynaklar ve Referanslar

- `docs/rekabet.md` — Rekabet analizi + stratejik yol haritası
- `docs/eksik-listesi.md` — Kalan açık işler
- `docs/store_listing.md` — Store listing checklist
- `docs/fiyat-endeksi-medya-raporu.md` — Medya raporu taslağı
- `docs/mobile-release-readiness.md` — Release blockers
- `CLAUDE.md` (repo root) — Genel proje mimarisi

---

## Notlar

- **Branch adlandırması:** feat/, fix/, docs/, migration/, ci/, refactor/ prefix kullan
- **Commit message:** Bkz. docs/commit-message-guide.md
- **Test koşutma:** Minimum validation per change type tablosunu bkz. docs/CLAUDE.md

**Son Düzenleme:** 3 Haziran 2026  
**Sonraki Güncelleme:** 5 gün sonra (Privacy Policy PR tamamlandıktan sonra)
