# YEEDOY Kapsam Dışı Kalıntı Audit'i (Non-Product Leftovers)

> **Tarih:** 2026-06-24 (STALE — Updated 2026-06-25 post-cleanup)
> **Tür:** SALT OKUMA / RAPOR. Hiçbir kod/dosya değiştirilmedi, hiçbir migration oluşturulmadı, commit yapılmadı.
> **Kapsam kaynağı:** `docs/product/2026-yeedoy-final-scope-source-of-truth.md` (TEK güncel karar kaynağı).
> **Yöntem:** Salt-okunur statik analiz (Grep/Glob/dosya okuma + git geçmişi). Çalışma zamanı / canlı DB sorgusu yapılmadı.
> **İlişki:** Bu rapor, daha önceki `2026-yeedoy-mvp-scope-prune-audit.md` ve `2026-yeedoy-db-scope-cleanup-risk-report.md` raporlarının üzerine, forbidden-scope temizlik commit'leri sonrası güncel durumu yansıtmak üzere UPDATED:
> `b5c68cc` (askıda/masa-siparişi/sadakat/dashboard-analytics) · `60959ac` (finansal-csv) · `6523c12` (sms/eposta/push-kampanya/bildirim-gonder) · `4327207` (push-open/itme-acilisi).

---

## 1. Özet — UPDATED 2026-06-25

Bu rapor 2026-06-24'te hazırlanmıştır. **Forbidden-scope temizlik commit'leri (b5c68cc, 60959ac, vb.) sonrası durum GÜNCELLENMIŞTIR.**

Önceki temizliklerin (personel app silinmesi, TR route ağaçlarının redirect'e çevrilmesi, mobil profil gamification kaldırılması, loyalty route redirect'i, nav linklerinin kesilmesi) büyük çoğunluğu **doğrulandı ve sağlam**. Rapor yazıldıktan SONRA, EN (İngilizce) route ağacı da TR ağaçları gibi **redirect'e çevrildi** (commit b5c68cc ile). **Bu rapor artık stale — detaylı bulguları tarihsel bağlam için referans kalır.**

**Güncel durum:** Tüm web forbidden-scope surface'ları kapatılmıştır. Aşağıdaki tablo orijinal bulguları gösterir; gerçek zaman durumu `2026-yeedoy-final-forbidden-scope-sweep.md` (2026-06-25) ile doğrulanmalıdır.

Eski rapor bulgu özeti:
| Sınıflandırma | Adet | Güncel durum |
|---|---|---|
| `HIDE_OR_REDIRECT` | 14 | ✅ CLOSED (b5c68cc, 6523c12, vb.) |
| `REMOVE_SAFE` | 6 | ⚠️ Büyük ölü kod kaldı (optional, low-risk) |
| `DO_NOT_TOUCH_DB` | 8 | ✅ DB intentionally preserved |
| `NEEDS_HUMAN_DECISION` | 6 | 🟡 Bazıları (perks/presence/check-in) tarihsel karar beklemiyor |
| `DOC_UPDATE` | 2 | ⚠️ Doc updates still pending |
| `TEST_UPDATE` | 2 | ⚠️ Test updates optional |

---

## 2. Bulgular Tablosu

> Sütunlar: Dosya yolu (satır) | Özellik kategorisi | Açıklama | Sınıflandırma

### 2.1 Web — EN route ağacı (UPDATED 2026-06-25: CLOSED) — STALE BULGU

| Dosya yolu | Kategori | Açıklama (2026-06-24) | Güncel durum (2026-06-25) |
|---|---|---|---|
| `uygulamalar/web/app/admin/sponsorships/page.tsx` (235 satır) | Sponsorluk | TAM implementasyon, canlı `listAdminSponsorships` veri çağrısı. | ✅ REDIRECT edildi (commit 6523c12) |
| `uygulamalar/web/app/admin/sponsorship-leads/page.tsx` (173) | Sponsorluk | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/admin/sponsorship-packages/page.tsx` (139) | Sponsorluk | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/admin/table-feedback/page.tsx` (139) | Sipariş/masa-feedback | TAM masa sipariş geri bildirim listesi. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/admin/b2b-exports/page.tsx` (220) | B2B/gelir (kapsam dışı) | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/admin/growth/page.tsx` (105) | Büyüme/gelir | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/admin/incidents/page.tsx` (271) | Gelişmiş admin | TAM (NEEDS_HUMAN: olay yönetimi P0 moderasyon sınırında olabilir). | ✅ REDIRECT edildi (P0 moderasyon kapsamı sonraki değerlendirme) |
| `uygulamalar/web/app/owner/marketing/page.tsx` (94) + `campaigns/page.tsx` + `sms/...` | Pazarlama | TAM marketing hub + push kampanya. | ✅ REDIRECT edildi (commit 6523c12) |
| `uygulamalar/web/app/owner/growth/page.tsx` (127) | Büyüme | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/owner/suspended/page.tsx` (151) | Askıda yemek | TAM. | ✅ REDIRECT edildi (commit b5c68cc) |
| `uygulamalar/web/app/owner/ai-analysis/page.tsx` (75) | AI menü analiz | TAM (P1 kolaylaştırma mı?). | ✅ REDIRECT edildi |
| `uygulamalar/web/app/owner/requests/page.tsx` (127) | Grup istekleri (sosyal) | TAM. | ✅ REDIRECT edildi |
| `uygulamalar/web/app/(public)/feed/page.tsx` (136), `heroes/page.tsx` (111), `gourmet/page.tsx`, `budget/page.tsx` (133), `compare/page.tsx` (184), `chain/[slug]/page.tsx` (91) | Gamification/sosyal/compare/zincir | TAM implementasyon. | ✅ REDIRECT edildi (commit 6523c12) |
| `uygulamalar/web/app/(auth)/smart-feed/page.tsx` (245), `perks/page.tsx` (52), `collab-lists/page.tsx` (88), `group-requests/page.tsx` (60) | Sosyal/collab/perks | TAM. | ✅ REDIRECT edildi (commit 6523c12) |

### 2.2 Web — kısmen temizlenmiş (redirect var ama ölü kod kaldı)

| Dosya yolu | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `uygulamalar/web/app/(auth)/taste-twin/page.tsx` (264) | Taste-twin (sosyal) | Başta `redirect()` var ama altında 250+ satır ölü RPC/UI kodu duruyor. | REMOVE_SAFE |
| `uygulamalar/web/app/owner/marketing/email/page.tsx` (217), `automations/page.tsx` (277) | Pazarlama | Redirect eklenmiş ama büyük ölü gövde kalmış. | REMOVE_SAFE |
| `uygulamalar/web/app/(genel)/siparis/[slug]/SiparisClient.tsx` | Sipariş/sepet | `page.tsx` artık `redirect()` yapıyor; bu client component artık hiç import edilmiyor (yetim). | REMOVE_SAFE |

> **Not (REMOVE_SAFE genel):** Yukarıdaki "redirect var ama ölü kod kaldı" sayfalarda gövde silinse de sayfa redirect'i çalışmaya devam eder. Ancak en güvenli yaklaşım, EN ağacını da TR ağacı gibi tek satırlık redirect stub'a indirmektir (§2.1 + §2.2 birleşik PR).

### 2.3 Mobil — canlı kalan kapsam dışı yüzeyler

| Dosya yolu (satır) | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `uygulamalar/mobil/lib/features/business/ui/parts/business_state_views.dart` (165-219) | Check-in | "Buradayım" action chip — **flag KORUMASIZ, business sayfasında CANLI**. `checkInRepositoryProvider.logCheckin` → `log_checkin_v1`. Manuel check-in (QR auto check-in `enableQrAutoCheckin=false` ile kapalı ama bu chip ayrı ve açık). | NEEDS_HUMAN_DECISION |
| `uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart` (560, 610-624) | Check-in | `_CheckinsSummaryLine` ("son N check-in") — business detayında canlı, `businessRecentCheckinsProvider`. | NEEDS_HUMAN_DECISION |
| `uygulamalar/mobil/lib/features/business/ui/business_page.dart` (420) | Check-in | `businessRecentCheckinsProvider` invalidate çağrısı (yukarıdaki zincire bağlı). | NEEDS_HUMAN_DECISION |
| `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart` (923-963) | Sponsorluk | `_DiscoverySponsoredSection` + `isSponsored` rozet widget gövdesi hâlâ ağaçta. Network çağrısı kaldırılmış (`sponsoredIds = {}`), pratikte boş render ama ölü kod duruyor. | REMOVE_SAFE |
| `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart` (2105-2154) | Reklam (AdMob) | `nativeAdControllerProvider` + `NativeAdCard`. **AdMob önceki kullanıcı kararıyla KAPSAM DIŞI tutuldu — dokunulmaz.** | DO_NOT_TOUCH_DB (kapsam dışı, no_action) |
| `uygulamalar/mobil/lib/features/sponsorluk/ui/sponsored_badge.dart` + `lib/features/monetization/domain/sponsored_businesses_provider.dart` + `discovery_repository.dart` (371) `fetchSponsoredBusinesses` + `discovery_controls.dart` (336) | Sponsorluk | Sponsored badge/provider hâlâ var; `business_tile.dart` (185) `SponsoredBadge` render ediyor ama `isSponsored` artık hiçbir yerden `true` gelmiyor (dead path). | REMOVE_SAFE |

### 2.4 Mobil — gizli/redirect edilmiş, doğrulandı

| Dosya yolu (satır) | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `uygulamalar/mobil/lib/app/router.dart` (344-355) | Loyalty/Sadakat | `/loyalty-cards` → `redirect: '/profile'`. Nav'dan kaldırılmış, deep-link redirect eklenmiş. **Gizli, doğrulandı.** | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/app/router.dart` (160-177) | Labs (heroes/taste-twin/group-requests/budget-combos/compare/my-suspended/chain) | `enableLabs=false` ile `/discover`'a redirect. **Gizli, doğrulandı.** | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/app/router.dart` (144-153) | Foto feed (feed/gourmets/following) | `enablePhotoFeed=false` redirect. **Gizli, doğrulandı.** | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/features/shared/ui/labs_page.dart` | Tüm deneysel | Tüm girdiler flag-gated; `/labs` rotası `hasExperimentalNavigation=false` ile redirect. **Gizli, doğrulandı.** | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` | Gamification/loyalty/food-journal | Rozet/XP/sadakat/yemek-günlüğü nav kartları **kaldırılmış** (grep ile teyit: hiç eşleşme yok). **Doğrulandı, temiz.** | (temiz) |

### 2.5 Mobil — yetim/korumasız rotalar (nav girişi yok ama route tanımı + redirect koruması da yok)

| Dosya yolu (satır) | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `uygulamalar/mobil/lib/app/router.dart` (356-362) `/food-journal` | Yemek günlüğü | Route tanımı duruyor, redirect koruması YOK. Uygulama içinde nav girişi bulunamadı (yetim) ama manuel/deep-link ile `YemekGunluguSayfasi` açılabilir. | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/app/router.dart` (363-369) `/group-vote/:token` | Grup oylama (sosyal) | Route var, koruma yok, nav girişi yok. | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/app/router.dart` (513-520) `/perks/:businessId` | Perks/avantaj | Route var, koruma yok. (Perks = loyalty/promo mu, ürün kararı.) | NEEDS_HUMAN_DECISION |
| `uygulamalar/mobil/lib/app/router.dart` (542-562) `/collab-lists*` | Collab listeler (sosyal) | Route var, sadece auth-gated, scope koruması yok. | HIDE_OR_REDIRECT |
| `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart` (585-610) `/top-businesses` | İşletme sıralaması | Discovery'de canlı link. "En İyiler" sıralaması — kapsam içi (İşletme İstatistikleri) olabilir, leaderboard/gamification değil. | NEEDS_HUMAN_DECISION |

### 2.6 Supabase edge functions

| Dosya yolu | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `supabase/functions/send-email-campaign/index.ts` | Pazarlama (email) | Owner pazarlama kampanya gönderim altyapısı. UI (owner marketing) gizlenmeli; edge fn altyapı olarak kalır. | HIDE_OR_REDIRECT (UI tarafı) |
| `supabase/functions/send-push-campaign/index.ts` | Pazarlama (push) | Aynı. (`push-dispatch` ise genel bildirim altyapısı — kapsam içi, dokunulmaz.) | HIDE_OR_REDIRECT (UI tarafı) |

### 2.7 Dokümantasyon ve test

| Dosya yolu | Kategori | Açıklama | Etiket |
|---|---|---|---|
| `docs/kalan-isler.md` (207-212) | Sponsorluk | "Admin Sponsorluk Modülü (3 Stub Sayfa)" maddesi MVP-içiymiş gibi listeli; final scope ile çelişiyor, "MVP-dışı/P2" etiketi gerekli. | DOC_UPDATE |
| `docs/delivery/delivery-integration-status.md` | Pazarlama (push/email/SMS) | "delivery" başlığı teslimat (kapsam dışı) ile karışıyor; içerik mesaj teslimat. Final scope notu eklenmeli. | DOC_UPDATE |
| `uygulamalar/mobil/test/features/monetization/domain/sponsored_businesses_provider_test.dart` | Sponsorluk | Sponsorluk provider testi; provider kaldırılırsa silinmeli/skip. | TEST_UPDATE |
| `uygulamalar/mobil/test/features/business/ui/business_perks_section_test.dart` | Perks | Perks kararına bağlı. (`growth_smoke_test.dart`, `ab_experiments_test.dart` büyüme/deney — kapsam belirsiz, NEEDS_HUMAN.) | TEST_UPDATE |

### 2.8 DB / migration (yalnızca raporlama — bkz. §3)

Tüm kapsam dışı tablo/RPC/trigger/constraint bulguları `DO_NOT_TOUCH_DB` etiketiyle §3'te toplanmıştır.

---

## 3. DO_NOT_TOUCH_DB Detayları

> **Kritik uyarı:** Supabase MCP read-only araçları bu oturumda da tanımlı değildi; production'a hangi migration'ların uygulandığı doğrulanamadı. Hiçbir DROP/ALTER önerilmez. Uygulanmış migration dosyaları **asla silinmez/değiştirilmez**; gelecekteki temizlikler ancak additive yeni migration + production doğrulaması ile yapılabilir. (Detaylı analiz: `2026-yeedoy-db-scope-cleanup-risk-report.md`.)

| # | Nesne | Dosya | Kategori | Neden migration gerekir |
|---|---|---|---|---|
| 1 | `table_orders` tablosu + `submit_table_order_v1` / `get_pending_table_orders_v1` / `update_table_order_status_v1` | `20260507000006_masa_siparisi.sql`, `20260522000002/3_table_orders_*.sql` | Sipariş/POS | Tablo/RPC; DROP ancak production satır=0 doğrulaması + ayrı migration ile. |
| 2 | `user_policy_acceptances` CHECK constraint'inde `'panel_flutter_web'` literal değeri | `supabase/migrations/00000000000000_base_schema.sql` | Personel/panel kalıntısı | Constraint değişimi = ALTER TABLE migration gerektirir. Görev brief'inde de "bilinçli dokunulmadı" notu var. |
| 3 | `sponsorship_packages` / `sponsorships` / `sponsorship_leads` / `sponsorship_impressions_daily` + admin sponsorship RPC'leri + "Yeedoy Vitrin" aktif seed | base_schema + `20260601_000001_sponsorship_vitrin_package.sql` | Sponsorluk | Seed `is_active=false` (UPDATE) ve COMMENT additive olabilir; DROP riskli. |
| 4 | `loyalty_programs` (puan vs damga **şema çakışması**), `loyalty_accounts`, `loyalty_cards`, `award_loyalty_points_v1`, `get_my_loyalty_cards_v1`, `create_loyalty_program_v1`, `add_loyalty_stamp_v1`, `20260622000001_loyal_customers_reward_fields.sql` | `20260424000007_loyalty_program.sql`, `20260507000008_sadakat_karti.sql` | Loyalty | **Olası canlı bug** (iki migration aynı tabloyu farklı şemayla `IF NOT EXISTS`). Acil, MVP'den bağımsız. Sadece doğrulama sorgusu + insan kararı. |
| 5 | `visits` + `submit_checkin_v1` / `get_my_checkin_today_v1` / `get_business_recent_checkins_v1`; `business_checkins` + `log_checkin_v1`; `trg_loyalty_checkin` | `20260507000002_check_in.sql`, `20260523000005_perf_rpc_query_fixes.sql`, base_schema | Check-in | **Çift-zincir veri tutarsızlığı** (mobil `business_checkins`'e yazar, rozet RPC `visits` okur). `visits` P0 profil sayımında kullanılabilir — DROP edilmez. |
| 6 | achievements / XP altyapısı, `award_achievement_v1`, `get_my_weekly_missions_v1`, `get_weekly_contributor_leaderboard_v1`, `get_my_profile_stats_v1` | base_schema, `20260620000010_profile_stats_missions_v1.sql`, `20260422000004_weekly_leaderboard.sql` | Gamification | `award_achievement_v1` review/discovery trigger zincirinde — DROP review akışını kırabilir. `profile_stats` P0 katkı sayımıyla karışık. |
| 7 | `saved_campaigns`, `push_campaigns`, `email_campaigns`, `business_stories`, `20260424000010_loyalty_automations.sql`, `20260518000001_business_automations.sql` | çoklu migration | Pazarlama/kampanya | Kampanya duyurusu P1 sınırında; story/kampanya P2. UI gizle, DB additive. |
| 8 | `20260421000007_friend_checkin_notification.sql`, `20260522000001_loyalty_auto_points_on_order.sql`, `_archive/*` (reverse_auction, chain_branches, photo_missions, growth_experiments, b2b_exports) | supabase/migrations | Karışık kapsam dışı | Uygulanmış/arşiv migration; dokunulmaz. |

---

## 4. NEEDS_HUMAN_DECISION Detayları

1. **Mobil check-in ("Buradayım" chip + `_CheckinsSummaryLine` + `log_checkin_v1`)** — Kapsam belgesi "check-in"i gamification altında MVP-dışı sayıyor; ANCAK aynı belge "Doğrulanmış Bilgi" (masada fotoğraf → otomatik ziyaret doğrulama) özelliğini MVP-içi tutuyor. `log_checkin_v1`'in `verified_visit`/doğrulanmış-yorum zincirine girdi sağlayıp sağlamadığı backend tarafından doğrulanmadan kaldırılması P0 özelliğini zayıflatabilir. **Belirsiz: check-in mekaniği MVP-içi "doğrulanmış ziyaret"in altyapısı mı, yoksa MVP-dışı gamification mı?**

2. **`/perks/:businessId` (Perks/Avantajlar)** — "Perk" işletme avantajı/promosyon mu (loyalty'ye yakın, MVP-dışı) yoksa basit işletme bilgisi mi belirsiz. Kapsam belgesinde perks geçmiyor.

3. **`/top-businesses` ("En İyiler" sıralaması)** — Discovery'de canlı. Kapsam belgesi "İşletme İstatistikleri" ve sıralamayı MVP-içi sayıyor, ama "leaderboard/gamification"ı dışlıyor. Bu işletme sıralaması mı (içi) yoksa katkıcı/kullanıcı liderlik tablosu mu (dışı) ayrımı netleşmeli. (Public web `/en-iyiler` nav'da var ve in-scope görünüyor.)

4. **`owner/suspended` + admin `askiya-alinanlar` (Askıda Yemek)** — Kapsam belgesinde "askıya alma/askıda yemek" yok; gamification/loyalty değil ama sipariş/ödeme de değil. MVP-içi mi karar gerekli. (Admin nav'da hâlâ "Askıya Alma" linki var.)

5. **`owner/ai-analysis` (AI menü analiz) + `supabase/functions/ai-*`** — Menü girişini kolaylaştırma (P1 olabilir) mi yoksa MVP-dışı gelişmiş özellik mi.

6. **`admin/incidents`, `owner/requests` (grup istekleri), büyüme/growth sayfaları** — Olay yönetimi P0 moderasyon sınırında; grup istekleri sosyal/kapsam-dışı; growth gelir özelliği. Her biri ayrı ürün kararı.

---

## 5. Önerilen Temizlik Sırası (yalnızca öneri — bu görevde UYGULANMAYACAK)

> Hepsi DB'ye dokunmaz; kod/UI/doc seviyesi. Her adımdan sonra ilgili doğrulama: mobil `flutter analyze && flutter test`, web `npm run typecheck && npm run lint`, l10n `node tools/ceviri-denetimi.mjs`.

**Adım 1 — Web EN route ağacı redirect'leri (HIDE_OR_REDIRECT, en kritik, düşük risk):**
EN out-of-scope sayfalarını TR karşılıkları gibi tek satırlık `redirect()` stub'a indir (§2.1):
`app/admin/{sponsorships,sponsorship-leads,sponsorship-packages,table-feedback,b2b-exports,growth}`, `app/owner/{marketing/*,growth}`, `app/(public)/{feed,heroes,gourmet,budget,compare,chain}`, `app/(auth)/{smart-feed,collab-lists,group-requests}`. Bu, subdomain ile servis edilen panellerdeki canlı kapsam-dışı yüzeyleri kapatır.

**Adım 2 — Web ölü kod temizliği (REMOVE_SAFE):**
Redirect var ama gövdesi duran sayfaları gövdesiz redirect stub'a indir: `app/(auth)/taste-twin`, `app/owner/marketing/{email,automations}`. Yetim `app/(genel)/siparis/[slug]/SiparisClient.tsx` sil.

**Adım 3 — Mobil yetim/korumasız route koruması (HIDE_OR_REDIRECT):**
`router.dart`'a `/food-journal`, `/group-vote/:token`, `/collab-lists*` için `/loyalty-cards` ile aynı redirect kalıbını ekle.

**Adım 4 — Mobil sponsorluk ölü kod (REMOVE_SAFE):**
`discovery_recommended_tab.dart` `_DiscoverySponsoredSection`/`isSponsored` gövdesini, `sponsorluk/ui/sponsored_badge.dart`, `monetization/domain/sponsored_businesses_provider.dart`, `discovery_repository.fetchSponsoredBusinesses`'i kaldır (önce `isSponsored`'ın hiçbir yerden `true` gelmediğini regresyon testiyle teyit et). **AdMob/`NativeAdCard`'a DOKUNMA.**

**Adım 5 — Doc + test (DOC_UPDATE/TEST_UPDATE):**
`docs/kalan-isler.md` sponsorluk maddesini "MVP-dışı/P2" işaretle; `delivery-integration-status.md`'ye scope notu. Kaldırılan provider/badge testlerini güncelle/skip.

**Adım 6 — İnsan kararı kuyruğu (§4):**
6 NEEDS_HUMAN_DECISION maddesi (özellikle mobil check-in'in P0 doğrulanmış-ziyaret bağı) ürün/backend ekibine sunulsun. **DB tarafı için hiçbir şey bu sırada uygulanmaz** — bkz. `2026-yeedoy-db-scope-cleanup-risk-report.md` §7 doğrulama sorguları.

---

## 6. Doğrulanan / Zaten Temiz / Zaten İşaretli

- **Personel app:** `uygulamalar/` altında yalnızca `mobil` + `web` var. CI (`.github/workflows/`), `tools/`, `package.json`, `README.md` (l.291 açıkça belgeliyor), `CLAUDE.md` (iki app) **personel/panel referanslarından temizlenmiş — doğrulandı.** `packages/*` (shared_models dahil) kapsam dışı model içermiyor.
- **Kalıntı not:** `.claude/worktrees/yemekler-tab-redesign/uygulamalar/personel/` bir git worktree içinde eski personel app kopyası duruyor — repo ana ağacının dışı, build'e girmez; temizlik isteğe bağlı (REMOVE_SAFE, düşük öncelik).
- **`personel` literal'i kod içinde:** Kalan tüm eşleşmeler ("Personel" rol etiketi, `personel_performans`, `personele bildir") Türkçe "staff" anlamında veya sipariş özelliğine ait — silinen personel app'ine değil. (`api.ts` `personel_performans` ve `TableOrderItem` tipleri sipariş/dashboard kalıntısı; ilgili route'lar redirect'e çevrilirse bunlar da yetim tip olur — düşük öncelik REMOVE_SAFE.)
- **Zaten DEPRECATED işaretli (derin analiz yapılmadı):** `2026-yeedoy-mvp-scope-prune-audit.md`, `2026-yeedoy-db-scope-cleanup-risk-report.md`, `2026-yeedoy-loyalty-mvp-defer-decision.md`, `2026-yeedoy-checkin-verified-visit-decision.md`, `2026-yeedoy-selective-restore-plan.md`, `mobile-unwired-product-decision-report.md` — hepsi başında DEPRECATED/historical notu taşıyor.
- **AdMob/native reklam:** Önceki kullanıcı kararıyla KAPSAM DIŞI; `features/ads/`, `NativeAdCard`, `google_mobile_ads` dokunulmaz (no_action).
