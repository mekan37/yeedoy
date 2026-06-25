# Yeedoy MVP Scope-Prune Audit

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

> **Tarih:** 2026-06-22
> **Kapsam:** Tüm monorepo (mobil, personel, web, supabase, packages, docs, test)
> **Referans karar metni:** `docs/research/2026-yeedoy-stratejik-karar-raporu.md` (Final Stratejik Karar Raporu)
> **Yöntem:** Salt-okunur statik analiz — Grep/Glob/dosya okuma. Çalışma zamanı / canlı DB sorgusu yapılmadı.
> **Kod değişikliği / dosya silme / migration oluşturma YAPILMADI.** Bu dosya yalnızca bulgu ve öneri içerir.

> **DB apply-durumu doğrulaması hakkında kritik uyarı:** Bu oturumda `mcp__supabase__list_migrations` ve `mcp__supabase__execute_sql` araçları **tanımlı değildi**. Dolayısıyla bir DB nesnesinin production'a gerçekten uygulanıp uygulanmadığını **bu oturum doğrulayamamıştır**. Tüm DB DROP önerileri "önce production şema/migration geçmişi bir insan veya Supabase MCP erişimi olan bir oturum tarafından doğrulanmalı" koşuluna bağlıdır. `00000000000000_base_schema.sql` (31K+ satır, konsolide remote schema) içinde nesne görülmesi onun production'da olduğuna güçlü işarettir ama bu oturumun kesin teyidi değildir.

> **Kapsam güncellemesi (kullanıcı talebi):** **AdMob / native reklam altyapısı bu audit'in kapsamı dışına alınmıştır** — `features/ads/`, `core/config/ad_config.dart`, `google_mobile_ads` bağımlılığı ve `NativeAdCard` ile ilgili tüm bulgular **KEEP_NOW / OUT_OF_SCOPE** olarak yeniden sınıflandırılmıştır, dokunulmayacaktır. **"Sponsorlu işletme" / sponsorship (sponsored business listing, `sponsorship_*` tabloları, discovery'deki sponsorlu bölüm ve sponsored rozet) bulguları bu güncellemeden etkilenmemiştir ve aynen geçerlidir** — bu iki konu birbirinden ayrı: AdMob üçüncü taraf genel reklam ağıdır, sponsorluk ise işletme sponsorluğu/öne çıkarma özelliğidir.

---

## 1. Executive Summary

- **MVP dışı aday alan (özellik grubu) sayısı:** 22 ayrı özellik alanı tespit edildi (sipariş/POS, sponsorluk, sadakat, check-in, gamification/rozet/XP/missions, food journal, sosyal feed/gourmet/following/taste-twin, collab/grup oylama, perks, askıda yemek, çok-şube/zincir, kampanya/pazarlama/CRM/finansal, custom domain, allergen/kalori, busy-hours/yoğunluk, embed/yerlestir, compare, smart recommendation/bütçe, weekly leaderboard, AI menü analiz, B2B export). **AdMob/native reklam kapsam dışına alınmıştır (kullanıcı talebi) — bu sayıya dahil değildir, dokunulmayacaktır.**
- **Kesin (kod tarafında düşük riskle) silinebilir:** ~4 (mobil duplicate `sponsorluk/` provider + testi, kullanılmayan `embed`/`link_paste_field`, drawer'daki ölü vaat linkleri, `Flexing` font).
- **Sadece UI'dan gizlenmeli (kod/DB kalsın):** ~7 (discovery sponsorlu bölüm + sponsored badge, profil gamification kartları, profil sadakat/food-journal nav kartları, public web nav'daki MVP-dışı linkler, owner panel sidebar MVP-dışı menüler, personel app POS/KDS/sadakat sekmeleri, mobil drawer compare/budget-combos, public web budget/leaderboard/compare/feed sayfaları).
- **P1/P2 için saklanmalı (dokunma, ürün backlog'una taşı):** ~10 (allergen/kalori alanları, busy-hours, custom domain, scheduled menu, çok-dilli menü, kampanya duyurusu, topluluk fiyat doğrulama, fotoğraf katkı, gelişmiş analitik, embed/yerlestir owner aracı).
- **DB tarafında riskli olduğu için şimdilik dokunulmamalı:** Tüm sponsorship_*, table_orders, loyalty_*, visits/checkin, food journal RPC'leri, achievements, campaign tabloları — `base_schema.sql`'de görülenler production'a uygulanmış görünüyor; **DROP önerilmez, önce şema/migration geçmişi doğrulanmalı.**
- **Kapsam dışı (dokunulmayacak):** AdMob / native reklam altyapısı (`features/ads/`, `core/config/ad_config.dart`, `google_mobile_ads` bağımlılığı, `NativeAdCard`) — kullanıcı talebi üzerine bu audit'in dışında tutulmuştur.
- **Mobil düzeltmeler (flutter-expert incelemesi, §14):** Sponsorlu discovery bölümü muhtemelen zaten **dead code** (her zaman `useMaterial3=true`, legacy dal hiç render edilmiyor) — önceki "Yüksek risk, canlı" etiketi gözden geçirildi. `embed/` modülü hakkındaki "REMOVE_SAFE" iddiası **yanlıştı** — `EmbedViewerPage` profil sosyal medya linklerinde aktif kullanılıyor, **silinmemeli**. Audit'in atladığı 2 yeni MVP-dışı yüzey eklendi: check-in chip ("Buradayım") ve profildeki Günlük Görevler/gamification kartı.
- **MVP-prune'dan bağımsız kritik bulgu (postgres-pro incelemesi, §13.2):** `loyalty_programs` tablosu için iki migration çakışan şema tanımlıyor (puan modeli vs damga modeli); `IF NOT EXISTS` nedeniyle biri sessizce etkisiz kalmış olabilir — **olası canlı bir RPC hatası/sessiz başarısızlık riski.** Bu, MVP kapsam kararı değil, backend ekibine acil iletilmesi gereken bir teknik bulgudur.
- **Düzeltme:** §4'teki `supabase/functions/admin-api-keys` yolu hatalıydı, gerçek dizin `admin-api`; bu fonksiyon P0 claim/report moderasyon RPC'lerini de çağırıyor, **KEEP_P0 olarak düzeltildi** (önceki DEFER_P2 hatalıydı).
- **En büyük risk:** İki ayrı yerde, **feature-flag KORUMASIZ ve canlı kullanıcıya görünen** MVP-dışı yüzeyler var ve final strateji ile doğrudan çelişiyor:
  1. **Mobil discovery ana akışında canlı sponsorlu bölüm + sponsored rozet** (AdMob/reklam hariç — sadece sponsorlu işletme listeleme kısmı; final strateji §4/§16: "MVP'de sponsorluk yok").
  2. **Mobil profil sekmesinde canlı gamification** (rozet/XP/Başarı Rozetlerim + Sadakat + Yemek Günlüğü nav kartları) (final strateji §4: "gamification merkezi mekanik değildir").
  3. **Personel uygulamasının tamamı bir POS/adisyon/KDS sistemi** — initial route `/siparisler`, alt menüde Siparişler+Sadakat+Mutfak (final strateji §4: "Bir POS/adisyon sistemi değildir").

  Bunlar "kod var ama gizli" değil; **şu an üründe görünür** olduğu için en yüksek öncelikli temizlik adaylarıdır.

---

## 2. Final Stratejiye Göre Kapsam Sınırı

(Kaynak: `docs/research/2026-yeedoy-stratejik-karar-raporu.md` §7, §23, "Nihai MVP Kararı")

**KALACAK — P0 (MVP):**
Claim/sahiplenme · temel işletme profili · temel bilgi düzenleme · çalışma saatleri / açık-kapalı · menü oluşturma+düzenleme · menü fiyatı güncelleme · public temel QR menü · konum bazlı yakın mekan keşfi · temel arama/filtre (kategori, mesafe, fiyat aralığı, açık olanlar) · temel doğrulanmış yorum/kanıt sistemi (`verified_visit`) · favoriler · admin/owner claim doğrulama için minimum panel · veri kalitesi/raporlama/kötü-veri bildirimi için minimum sistemler.

**P1 (MVP hemen sonrası):**
QR tasarım özelleştirme, galeri foto · temel analitik · topluluk fiyat doğrulama · kullanıcı fotoğraf ekleme · alerjen/kalori alanları · kampanya duyurusu · çok-dilli menü.

**P2 (kanıtlanmış talep üzerine):**
Rozet/görev/gamification · check-in (izole) · kalabalık/yoğunluk · çok-şube/merkezi yönetim · sponsorlu görünürlük (pilot) · gelişmiş analitik/raporlama.

**MVP DIŞI (şimdilik tamamen kapsam dışı / §23 Yapılmayacaklar):**
Sipariş/sepet/ödeme/teslimat · komisyon · kendi haritacılık · kendi influencer/içerik ekosistemi · reklam/CPC · gamification'ı merkezi mekanik yapmak · çok-şube/kurumsal ilk hedef · çok-şehirli eşzamanlı lansman.

---

## 3. Database / Supabase Bulguları

> Hatırlatma: Hiçbir DROP doğrudan önerilmemiştir. "REMOVE_CANDIDATE" işareti = ileride bir cleanup migration ile ele alınabilir, ancak **önce production apply doğrulaması şarttır.**

| Nesne tipi | Nesne adı | Dosya yolu | İlgili migration | Özellik | Sınıf | Kanıt | Önerilen aksiyon | Risk | Not |
|---|---|---|---|---|---|---|---|---|---|
| table | `table_orders` | `00000000000000_base_schema.sql` + `20260507000006_masa_siparisi.sql` | 20260507000006 | Masa siparişi / POS | DO_NOT_REMOVE_PROD_RISK | `CREATE TABLE IF NOT EXISTS table_orders` (l.3) | DROP önerilmez; apply doğrulanana dek bırak | Yüksek | Sipariş = §23 yapılmayacaklar |
| RPC | `submit_table_order_v1`, `get_pending_table_orders_v1`, `update_table_order_status_v1` | `20260507000006_masa_siparisi.sql` | 20260507000006 | Masa siparişi | DO_NOT_REMOVE_PROD_RISK | l.16/58/84 | UI'dan kesilince DB'de bekletilir | Orta | Personel app çağırıyor |
| migration | `20260522000002_table_orders_staff_note_waiting.sql`, `20260522000003_table_orders_processed_by.sql`, `20260522000001_loyalty_auto_points_on_order.sql` | supabase/migrations | — | Sipariş+sadakat | DO_NOT_REMOVE_PROD_RISK | dosya adları | Uygulanmış migration SİLİNMEZ | Yüksek | Sadece ileride additive deprecate |
| table+RPC | `sponsorship_packages`, `sponsorships`, `sponsorship_leads`, `sponsorship_impressions_daily` + ilgili RPC'ler | `00000000000000_base_schema.sql` (l.23807-23857) | base + `20260601_000001_sponsorship_vitrin_package.sql` | Sponsorlu görünürlük | DO_NOT_REMOVE_PROD_RISK | base_schema'da CREATE TABLE + RLS + GRANT | DROP önerilmez; P2'ye kadar pasif tut | Yüksek | §16 MVP'de kapalı |
| seed | "Yeedoy Vitrin" paket insert'i | `20260601_000001_sponsorship_vitrin_package.sql` | 20260601 | Sponsorluk paketi | DISABLE_ONLY | `insert into sponsorship_packages ... is_active true` | Paketi `is_active=false` yapan yeni migration ÖNERİLİR (oluşturma) | Orta | Satılabilir paket aktif tohumlanmış — strateji ile çelişir |
| table | `loyalty_programs`, `loyalty_cards` (damga modeli) | `20260507000008_sadakat_karti.sql` | 20260507000008 | Sadakat (damga) | NEEDS_HUMAN_DECISION | l.4/14 | Points modeliyle split-brain — ürün kararı | Orta | İki ayrı loyalty şeması var |
| table+RPC | `loyalty_accounts`, `loyalty_programs` + `award_loyalty_points_v1`, `get_loyalty_status_v1`, `upsert_loyalty_program_v1` (puan modeli) | `20260424000007_loyalty_program.sql` | 20260424000007 | Sadakat (puan) | DEFER_P2 | l.18/58/149/228 | P2; DB'de bırak, UI'dan kes | Orta | §7 P2 |
| trigger | `trg_loyalty_review`, `trg_loyalty_checkin` | `20260424000007_loyalty_program.sql` | 20260424000007 | Sadakat otomasyonu | DO_NOT_REMOVE_PROD_RISK | l.113/142 | Trigger DROP riskli; bırak | Orta | Review yazınca puan veriyor |
| table+RPC | `visits` + `submit_checkin_v1`, `get_my_checkin_today_v1`, `get_business_recent_checkins_v1` | `20260507000002_check_in.sql` | 20260507000002 | Check-in | DEFER_P2 | l.5/49/78/90 | DB'de bırak; `visits` profil sayımında kullanılıyor | Orta | `get_my_profile_stats_v1` `visits` okuyor |
| RPC | `get_my_food_journal_v1`, `update_visit_details_v1`, `get_my_spending_summary_v1` | `20260507000009_yemek_gunlugu.sql` | 20260507000009 | Yemek günlüğü | DEFER_P2 | l.10/35/74 | DB'de bırak; UI'dan kes | Düşük | §5 belirsiz |
| RPC | `get_my_weekly_missions_v1`, `get_my_profile_stats_v1` | `20260620000010_profile_stats_missions_v1.sql` | 20260620000010 | Gamification/missions | NEEDS_HUMAN_DECISION | l.7/46 | `profile_stats` P0 (katkı), `weekly_missions` P2 — ayrıştır | Düşük | Aynı migration iki amacı karıştırıyor |
| RPC+table | `get_weekly_contributor_leaderboard_v1` | `20260422000004_weekly_leaderboard.sql` | 20260422000004 | Haftalık liderlik (gamification) | DEFER_P2 | dosya | DB'de bırak; UI'dan kes | Düşük | §7 P2 |
| table+RPC | achievements / XP altyapısı | `00000000000000_base_schema.sql` (achievement_* objeleri) | base | Rozet/XP | DO_NOT_REMOVE_PROD_RISK | base_schema achievement nesneleri | DROP önerilmez | Orta | UI gizlenmeli |
| table+RPC | `saved_campaigns` + `get_nearby_campaign_stories_v2`, `toggle_saved_campaign_v1` | `20260613000001_campaign_redesign.sql` | 20260613000001 | Kampanya/story | DEFER_P2 | l.17/38/143 | P1 (kampanya duyurusu) yakın — incele | Düşük | Kampanya duyurusu P1, "story" formatı P2 |
| table+edge | `push_campaigns`, `email_campaigns` + edge fn `send-email-campaign`, `send-push-campaign` | `20260424000008/9`, `supabase/functions/` | 20260424 | Pazarlama (push/email/SMS) | DEFER_P2 | dosya + delivery doc | Owner panel'den gizle; altyapı kalsın | Orta | §9 "gelir özellikleri MVP'de pasif" |
| migration | `20260424000010_loyalty_automations.sql`, `20260518000001_business_automations.sql`, `20260603000009_marketing_automations_rls_owner_claims.sql` | supabase/migrations | — | Otomasyon/pazarlama | DO_NOT_REMOVE_PROD_RISK | dosya adları | Uygulanmış migration silinmez | Orta | UI gizle |
| migration | `20260424000002_custom_domains.sql` | supabase/migrations | — | Custom domain (branded QR) | DEFER_P2 | dosya adı | DB'de bırak | Düşük | §7 P2 |
| migration | `20260424000003_scheduled_menu_activation.sql` | supabase/migrations | — | Zamanlanmış menü | KEEP_P1_READY | dosya adı | P1 | Düşük | Menü güncelliğiyle uyumlu |
| migration | `20260414000001_menu_item_nutrition.sql`, `20260414000002_menu_item_allergens.sql`, `20260507000003_kalori_porsiyon.sql` | supabase/migrations | — | Alerjen/kalori | KEEP_P1_READY | dosya adları | P1 alan; bırak | Düşük | §7 P1 |
| migration | `20260424000004_menu_item_translation_rpc.sql`, `20260427000001_menu_section_translation_rpc.sql`, `20260424000011_bulk_menu_translations.sql` | supabase/migrations | — | Çok-dilli menü | KEEP_P1_READY | dosya adları | P1 | Düşük | §7 P1 |
| migration | `20260603000006_business_busy_hours_rpc.sql`, `20260603000005_analytics_events_busy_hours_indexes.sql` | supabase/migrations | — | Yoğunluk/busy-hours | DEFER_P2 | dosya adları | P2 (kalabalık göstergesi) | Düşük | §7 P2 |
| migration | `20260520000001_admin_api_keys_support_tickets.sql` | supabase/migrations | — | Admin API keys + destek | KEEP_P1_READY | dosya adı | Admin minimum; incele | Düşük | API key gelişmiş, destek minimum panel |
| RPC | `get_dashboard_weekly_v1`, `get_staff_performance_today_v1`, `admin_get_overview_stats_v1`, `get_business_full_profile_v1` | `20260526000002_planned_rpc_stubs.sql` | 20260526000002 | Owner/admin dashboard | NEEDS_HUMAN_DECISION | l.20/57/114/146 | `get_business_full_profile_v1` P0; staff_performance P2 | Düşük | Karışık |
| migration dizini | `supabase/migrations/_archive/*` (achievements, sponsorships, reverse_auction, chain_branches, photo_missions, growth_experiments, b2b_exports, vb.) | `_archive/` | — | Eski MVP-dışı | DEFER_DOC_ONLY | `_archive` klasörü | Arşivde; dokunma | Düşük | Zaten uygulama yolunda değil |

---

## 4. Backend / API / RPC Bulguları

| Dosya yolu | Fonksiyon/API/RPC | Özellik | Kullanıldığı yerler | Sınıf | Önerilen aksiyon | Risk | Test ihtiyacı |
|---|---|---|---|---|---|---|---|
| `supabase/functions/send-email-campaign/index.ts` | edge fn | Email kampanya (pazarlama) | Owner panel marketing | DEFER_P2 | no_action (UI gizle) | Orta | Mevcut testler bozulmaz |
| `supabase/functions/send-push-campaign/` | edge fn | Push kampanya | Owner panel | DEFER_P2 | no_action | Orta | — |
| `uygulamalar/web/app/sunucu/sahip/sms-kampanya/route.ts` | SMS route (stub) | SMS pazarlama | Owner panel | DEFER_P2 | no_action (zaten gerçek gönderim yok) | Düşük | `docs/delivery/...` "BLOCKER" diyor |
| `supabase/functions/ai-menu-analyze`, `ai-allergen-detect`, `ai-ingredient-detect`, `ai-nutrition-estimate`, `ai-menu-image-gen` | AI menü/analiz edge fn'leri | AI menü analizi | Owner AI sayfası | NEEDS_HUMAN_DECISION | feature_flag | Orta | Menü girişini kolaylaştırma P1 olabilir; "AI analiz" ürün kararı |
| `supabase/functions/admin-api` (düzeltme: dizin adı `admin-api-keys` DEĞİL, `admin-api`) | admin API | Admin API keys + **P0 claim/report moderasyon RPC'leri** (`admin_assign_owner_claim_v1`, `admin_assign_report_v1`, `admin_bulk_update_reports_status_v2`, `apply_auto_moderation_rules_v1`) | Admin panel | **KEEP_P0** (düzeltme — eski DEFER_P2 hatalı) | keep | — | postgres-pro incelemesi §13.1 — dokunma |
| `supabase/functions/import_places_json` | OSM/FSQ import | Veri seed/kalite | Backend pipeline | KEEP_P0 | keep | — | P0 veri kalitesi |
| `supabase/functions/media-upload*`, `wp-upload*`, `purge-temp-uploads`, `write-gatekeeper`, `anti-spam-guard` | medya/güvenlik | Yorum/foto/güvenlik altyapısı | Tüm app | KEEP_P0 | keep | — | P0 güvenlik |
| `uygulamalar/web/app/api/owner/*`, `api/admin/*` | owner/admin CRUD route | Menü/işletme yönetimi + claim | Web panel | KEEP_P0 | keep | — | P0 |
| Mobil `discovery_repository.dart` | `sponsoredBusinessesProvider` veri yolu | Sponsorlu keşif | discovery_recommended_tab | DISABLE_ONLY | hide (UI'dan kaldır) | Orta | sponsored_businesses_provider_test güncellenmeli |
| Mobil `features/ads/data/native_ad_controller.dart` | AdMob native ad | Reklam | discovery_recommended_tab | **OUT_OF_SCOPE** | **no_action — kullanıcı talebiyle kapsam dışı, dokunulmayacak** | — | — |
| **Çelişki notu** | `mobile-unwired-product-decision-report.md` | masa_siparisi/sadakat/heroes "KEEP_*" | önceki oturum | — | Final strateji ile ÇELİŞİYOR | — | Bu rapor MVP-dışı sayar |

> **Önceki rapor çelişkisi:** `docs/engineering/mobile-unwired-product-decision-report.md`, masa_siparisi'ni "KEEP_BUT_LATER", sadakat/food-journal'ı "KEEP_AND_CONNECT" (route bağlandı), hero leaderboard'u "KEEP_AND_CONNECT" olarak işaretliyor. Final stratejik karar raporu bunların **tümünü MVP-dışı (P2)** sayar. Önceki rapor "bağlı olmayan kod" merceğiyle yazılmıştı; bu audit "MVP scope" merceğiyle yazıldı — sonuç farklı. Bu çelişki ürün ekibine açıkça sunulmalı.

---

## 5. Mobil Uygulama Bulguları

> Router gerçeği: `enablePhotoFeed = false`, `enableLabs = false` (`core/config/feature_flags.dart` l.8-9). Bu nedenle `/heroes`, `/taste-twin`, `/group-requests`, `/budget-combos`, `/compare`, `/my-suspended`, `/chain`, `/feed`, `/gourmets`, `/following` route'ları **varsayılan olarak `/discover`'a redirect ediliyor** (router.dart l.145-178) — yani zaten kullanıcıya kapalı. Buna rağmen bazı yüzeyler flag-koruması OLMADAN canlı.

| Dosya yolu | Widget/screen | Özellik | Sınıf | UI'da aktif mi | Önerilen aksiyon | Risk | Test ihtiyacı |
|---|---|---|---|---|---|---|---|
| `features/discovery/ui/parts/discovery_recommended_tab.dart` (l.942, l.982) | `_DiscoverySponsoredSection`, `isSponsored` rozet | Sponsorlu bölüm (işletme sponsorluğu) | DISABLE_ONLY | **EVET (flag KORUMASIZ, canlı)** | hide: sponsorlu bölüm bloklarını koşula al/kaldır | **Yüksek** | discovery widget testleri |
| `features/discovery/ui/parts/discovery_recommended_tab.dart` (l.2168-2179) `NativeAdCard` ekleme bloğu | AdMob native ad gösterimi | Reklam (AdMob) | **OUT_OF_SCOPE** | EVET | **no_action — kapsam dışı, dokunulmayacak** | — | — |
| `features/ads/data/native_ad_controller.dart`, `features/ads/ui/native_ad_card.dart` | AdMob native ad | Reklam (AdMob) | **OUT_OF_SCOPE** | EVET | **no_action — kullanıcı talebiyle kapsam dışı tutuldu, modül/bağımlılık korunur** | — | — |
| `core/config/ad_config.dart` | `AdConfig.nativeUnitId` (gerçek default unit ID gömülü, l.16-21) | Reklam config | **OUT_OF_SCOPE** | EVET (release'de aktif) | **no_action — kapsam dışı** | — | — |
| `features/sponsorluk/ui/sponsored_badge.dart` | `SponsoredBadge` | Sponsorlu rozet | DISABLE_ONLY | `business_tile.dart` kullanıyor | hide (isSponsored hep false) | Orta | business_tile testi |
| `features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` | duplicate provider | Sponsorluk (kopya) | REMOVE_SAFE | Hayır (sadece test) | remove + testi | Düşük | `test/features/sponsorluk/...` |
| `features/monetization/domain/sponsored_businesses_provider.dart` | `sponsoredBusinessesProvider` | Sponsorluk (kanon) | DISABLE_ONLY | EVET (discovery) | hide | Orta | sponsored_businesses_provider_test |
| `features/profile/ui/profile_page.dart` (l.82-124, l.291-329, l.426-454, l.555-564) | `_AchievementsNavCard`, "İçerik Üretici Rozeti", "Başarı Rozetlerim/XP", Sadakat+Yemek Günlüğü nav kartları | Gamification + sadakat + food journal | DISABLE_ONLY | **EVET (flag KORUMASIZ, profil sekmesi)** | hide: rozet/XP/loyalty/food-journal kartlarını kaldır | **Yüksek** | profile_page_test |
| `features/profile/ui/achievements_page.dart` (route `/achievements`) | AchievementsPage | Rozet ekranı | DISABLE_ONLY | EVET (`/achievements` flag-korumasız route) | hide route + nav | Orta | — |
| `features/heroes/` (route `/heroes`) | HeroesPage + weekly leaderboard | Liderlik/gamification | KEEP_HIDDEN | Hayır (enableLabs=false) | no_action (zaten gizli) | Düşük | — |
| `features/taste_twin/` (route `/taste-twin`) | TasteTwinPage | Tat ikizi keşif | KEEP_HIDDEN | Hayır (flag) | no_action | Düşük | drawer'da kullanılıyor (taste_twin_controllers import) |
| `features/gourmets/` (`/gourmets`,`/following`) + `smart_feed/` (`/feed`) | sosyal feed | Sosyal/içerik feed | KEEP_HIDDEN | Hayır (enablePhotoFeed=false) | no_action | Düşük | feed_page legacy şüphesi (önceki rapor) |
| `features/grup_oy/` + `collab_lists/` (`/group-vote`,`/collab-lists`) | grup oylama | Sosyal/collab | KEEP_HIDDEN | Kısmen (`/collab-lists` flag-korumasız ama auth-gated) | no_action / incele | Düşük | collab route auth gerektiriyor |
| `features/group_requests/` (`/group-requests`) | grup teklif | Sosyal | KEEP_HIDDEN | Hayır (labsRoute) | no_action | Düşük | — |
| `features/compare/` (`/compare` + drawer link) | ComparePage | Karşılaştırma | DISABLE_ONLY | **Drawer'da link var ama route enableLabs=false → ÖLÜ LİNK** | hide: drawer'dan `/compare` kaldır | Orta | drawer testi |
| `features/smart_recommendation/` (`/budget-combos` + drawer link) | SmartRecommendationPage | Bütçe kombinasyonları | DISABLE_ONLY | **Drawer'da "2 kişi x fiyat" link ama labsRoute → ÖLÜ LİNK** | hide: drawer'dan kaldır veya P2'ye al | Orta | drawer testi |
| `features/sadakat/` (`/loyalty-cards`) | SadakatKartlarimSayfasi | Sadakat | DEFER_P2 | EVET (profil nav kartı flag-korumasız) | hide nav + route | Orta | — |
| `features/yemek_gunlugu/` (`/food-journal`) | YemekGunluguSayfasi | Yemek günlüğü | DEFER_P2 | EVET (profil nav kartı) | hide nav + route | Düşük | — |
| `features/perks/` (`/perks/:businessId`) | PerksPage | İşletme avantajları | NEEDS_HUMAN_DECISION | EVET (business_page'den) | incele (perk = loyalty/promo mu?) | Orta | business_perks_section_test |
| `features/chains/` (`/chain/:id`) | ChainPage | Çok-şube/zincir | KEEP_HIDDEN | Hayır (labsRoute) | no_action | Düşük | §23 çok-şube ilk hedef değil |
| `features/suspended_meals/` (`/my-suspended`) | MySuspendedClaimsPage | Askıda yemek | KEEP_HIDDEN | Hayır (labsRoute) | no_action / NEEDS_HUMAN_DECISION | Düşük | askıda yemek = hayır işi, MVP-dışı |
| `features/embed/data/embed_repository.dart`, `core/ui/link_paste_field.dart` | EmbedRepository, LinkPasteField | Embed/yerlestir | **Bu iki dosya repoda mevcut değil** (önceki bir oturumda zaten silinmiş) | — | no_action — zaten yapılmış | — | flutter-expert incelemesi §14.1 ile teyit edildi |
| `features/embed/ui/embed_viewer_page.dart` | `EmbedViewerPage` | Sosyal medya link önizleme | **KEEP_P0 (düzeltme — önceki REMOVE_SAFE hatalı)** | **EVET — `profile_identity_card.dart` l.237'de aktif kullanılıyor** | keep, dokunma | — | flutter-expert incelemesi §14.1 |
| `assets/fonts` `Flexing-Black.ttf` | font | — | REMOVE_SAFE | Hayır (kodda fontFamily 'Flexing' yok) | remove (tasarım onayı) | Düşük | — |

---

## 6. Personel / Owner Panel Bulguları

> **En kritik bulgu:** Personel uygulaması fiilen bir **POS/adisyon/KDS** sistemidir. `uygulama_rotalari.dart` initial route = `/siparisler`; `ana_kabuk.dart` alt menüsü: Siparişler (badge'li bekleyen sipariş sayacı), Dashboard, Menü, Sadakat, **Mutfak (KDS)**, Ayarlar. Final strateji §4: "Yeedoy bir POS/adisyon sistemi DEĞİLDİR." Bu, tek bir özellik değil, **uygulamanın varlık sebebinin yarısı** kapsam dışı demektir. (Not: CLAUDE.md de personel app'i "owner/waiter POS operations" diye tanımlıyor — bu da güncellenmeli.)

| Dosya yolu | Özellik | Aktif route/menu var mı | Sınıf | Önerilen aksiyon | Risk | Test ihtiyacı |
|---|---|---|---|---|---|---|
| `features/masa_siparisleri/` (ui/siparisler_sayfasi.dart) | Masa siparişi / adisyon | **EVET — initial route `/siparisler`, alt menü #1** | DISABLE_ONLY | hide: route + nav; initial route'u `/menu` veya `/dashboard` yap | **Yüksek** | siparis testleri |
| `features/kds/` (kds_sayfasi, kds_siparis_karti, kds_yazici_ayarlari) | Mutfak ekranı / yazıcı (POS) | **EVET — alt menü "Mutfak"** | DISABLE_ONLY | hide: route + nav | **Yüksek** | kds testleri |
| `features/sadakat/` (sadakat_sayfasi) | Sadakat (puan) | **EVET — alt menü "Sadakat"** | DEFER_P2 | hide: nav + route | Orta | sadakat testleri (64 test geçiyor — bkz önceki rapor) |
| `features/kampanya/` (kampanya_sayfasi, route `/kampanya`) | Kampanya | EVET (route var, alt menüde değil) | DEFER_P2 → KEEP_P1_READY | incele: kampanya duyurusu P1 | Düşük | — |
| `ana_kabuk.dart` bekleyen sipariş badge'i + `masa_siparisi_bildiricisi` | Sipariş sayacı | EVET | DISABLE_ONLY | hide: badge'i kaldır | Orta | — |
| `features/menu_yonetimi/` (route `/menu`) | Menü yönetimi | EVET | KEEP_P0 | keep | — | P0 |
| `features/yorumlar/` (route `/yorumlar`) | Yorumlar | EVET | KEEP_P0 | keep | — | P0 |
| `features/qr/`, `features/qr_tarayici/` | QR / QR tarayıcı | EVET | KEEP_P0 | keep (QR doğrulanmış ziyaret/menü) | — | P0 |
| `features/dashboard/` (route `/dashboard`) | Dashboard | EVET | KEEP_P1_READY | keep (temel analitik P1) | Düşük | — |

### Web Owner Panel (`sahip/`) — sidebar (`src/ui/kabuk/sahip-kabuk-istemcisi.tsx`)

| Sidebar öğesi (href) | Özellik | Sınıf | Önerilen aksiyon | Risk |
|---|---|---|---|---|
| `/sahip/siparisler` "Masa Siparişleri" (l.30) | Sipariş/POS | DISABLE_ONLY | hide nav + route | Yüksek |
| `/sahip/sponsorluk` "Sponsorluk" (l.33) | Sponsorluk | DISABLE_ONLY | hide nav + route | Yüksek |
| `/sahip/pazarlama` "Pazarlama" (l.34) | Pazarlama (push/email/SMS) | DEFER_P2 | hide nav | Orta |
| `/sahip/crm` "Müşteri CRM" (l.27) | CRM | DEFER_P2 | hide nav | Orta |
| `/sahip/finansal` "Finansal Raporlar" (l.26) | Finansal | DEFER_P2 | hide nav | Orta |
| `/sahip/buyume` "Büyüme" (l.29) | Büyüme | DEFER_P2 | hide nav | Düşük |
| `/sahip/envanter` "Envanter" (l.41) | Envanter | DEFER_P2 | hide nav | Düşük |
| `/sahip/askiya-alinanlar` "Askıya Alma" (l.44) | Askıda yemek | NEEDS_HUMAN_DECISION | hide nav | Düşük |
| `/sahip/yapay-zeka-analizi` "Yapay Zeka" (l.46) | AI analiz | NEEDS_HUMAN_DECISION | feature_flag | Orta |
| `/sahip/fiyat-onerileri`, `/sahip/istekler`, `/sahip/etkinlik` | Fiyat öneri / grup istek / aktivite | NEEDS_HUMAN_DECISION | incele | Düşük |
| `/sahip/gosterge-panosu`, `/isletmeler`, `/menuler`, `/baslangic`, `/yorumlar`, `/karekod`, `/analitik`, `/fiyat-raporu`, `/ekip`, `/ayarlar` | P0/P1 owner çekirdeği | KEEP_P0 / KEEP_P1_READY | keep | — |

---

## 7. Next.js Web / Public QR Bulguları

| Dosya yolu | Özellik | Sınıf | Önerilen aksiyon | Risk | Test ihtiyacı |
|---|---|---|---|---|---|
| `app/(genel)/siparis/[slug]/` (page + SiparisClient) | Public sipariş | DISABLE_ONLY | hide route (link kaynaklarını kes) | Yüksek | — |
| `app/sunucu/masa-siparisi/` | Masa siparişi (TR alt yol) | DISABLE_ONLY | hide | Yüksek | — |
| `app/admin/table-feedback/`, `app/yonetici/masa-geri-bildirimleri/` | Masa geri bildirim | DISABLE_ONLY | hide | Orta | — |
| `app/admin/sponsorship-packages`, `sponsorships`, `sponsorship-leads` + `yonetici/sponsor-paketleri`, `sponsorluklar`, `sponsor-adaylari` | Sponsorluk yönetimi | DISABLE_ONLY | hide nav (admin) | Orta | — |
| `app/(kimlik)/sadakat/`, `(auth)/loyalty/` | Sadakat | DEFER_P2 | hide | Düşük | — |
| `app/(kimlik)/yemek-gunlugum/`, `(auth)/...` | Yemek günlüğü | DEFER_P2 | hide | Düşük | — |
| `app/(genel)/liderler/`, `(public)/heroes/` | Liderlik (gamification) | DISABLE_ONLY | hide + public nav'dan kaldır (yerlesim.tsx l.20) | Orta | — |
| `app/(genel)/butce/`, `(public)/budget/` | Bütçe kombinasyonları | DISABLE_ONLY | hide + nav'dan kaldır (yerlesim.tsx l.21) | Orta | — |
| `app/(genel)/karsilastir/`, `(public)/compare/` | Karşılaştır | DISABLE_ONLY | hide + footer link kaldır (yerlesim.tsx l.190) | Orta | — |
| `app/(genel)/akis/`, `(kimlik)/akilli-akis/`, `(public)/feed/`, `(auth)/smart-feed/`, `(public)/gourmet/`, `(genel)/gurmeler/`, `(kimlik)/takip/`, `(kimlik)/tat-ikizi/`, `(auth)/taste-twin/`, `(auth)/following/` | Sosyal feed/gourmet/taste-twin | DISABLE_ONLY | hide + nav (yerlesim.tsx l.198,257) | Orta | — |
| `app/(genel)/zincir/`, `zincirler/`, `(public)/chain/` | Zincir/çok-şube | DISABLE_ONLY | hide | Düşük | — |
| `app/(genel)/oyoyla/`, `(kimlik)/ortak-listeler/`, `(genel)/askida/`, `(auth)/collab-lists/`, `(auth)/group-requests/`, `(kimlik)/grup-istekleri/` | Collab/grup/askıda | DISABLE_ONLY | hide | Düşük | — |
| `app/(kimlik)/avantajlar/`, `(auth)/perks/` | Perks | NEEDS_HUMAN_DECISION | incele | Düşük | — |
| `app/yonetici/ab-test/`, `feature-flags/`, `finansal-yonetim/`, `fraud-tespiti/`, `push-kampanyalari/`, `b2b-dis-aktarim/`, `musteri-destek/`, `toplu-islemler/` | Gelişmiş admin | DEFER_P2 | hide nav | Düşük | claim doğrulama için gerekmiyor |
| `app/admin/b2b-exports/`, `growth/`, `incidents/`, `appeals/` | Gelişmiş admin (EN tree) | DEFER_P2 | hide | Düşük | — |
| **Duplicate route ağaçları:** `(public)` (EN) ↔ `(genel)/(kimlik)` (TR); `owner/` (EN) ↔ `sahip/` (TR); `admin/` (EN) ↔ `yonetici/` (TR); `sunucu/` (TR server tree) | İki dilli/üç katmanlı duplicate sayfa ağacı | NEEDS_HUMAN_DECISION | İnsan kararı: hangi ağaç kanon? (örn. `(public)/compare/page.tsx` tam standalone sayfa, redirect değil) | Orta | typecheck/lint |
| `app/karekod/[businessId]`, `qr/[businessId]`, `q/[code]`, `kod/[code]`, `m/`, `(public)/b/`, `(genel)/isletme/` | Public QR menü + işletme sayfası | KEEP_P0 | keep | — | P0 ÇEKİRDEK |
| `app/(genel)/kesif/`, `arama/`, `[sehir]/`, `sahiplen/` | Keşif + arama + şehir + sahiplenme | KEEP_P0 | keep | — | P0 |
| `app/api/feedback/`, `api/track/`, `api/media/`, `api/revalidate/`, `api/owner/`, `api/admin/` | Geri bildirim + medya + owner/admin CRUD | KEEP_P0 | keep | — | P0 |

---

## 8. Test ve Dokümantasyon Bulguları

| Dosya yolu | İçerik / sorun | Sınıf | Aksiyon |
|---|---|---|---|
| `uygulamalar/mobil/test/features/monetization/domain/sponsored_businesses_provider_test.dart` | Sponsorluk provider testi (aktif kod) | DISABLE_ONLY | UI gizlenirse test kalabilir veya skip |
| `uygulamalar/mobil/test/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi_test.dart` | Duplicate provider testi | REMOVE_SAFE | provider ile birlikte sil |
| `uygulamalar/mobil/test/features/business/ui/business_perks_section_test.dart` | Perks testi | NEEDS_HUMAN_DECISION | perks kararına bağlı |
| `uygulamalar/mobil/test/features/growth/growth_smoke_test.dart` | Growth/sponsor referansı | DISABLE_ONLY | incele |
| `docs/delivery/delivery-integration-status.md` | Push/Email/SMS pazarlama "delivery" entegrasyonu — final strateji §14 "MVP'de gelir/pazarlama pasif" ile gerilimli; başlık "delivery" (teslimat) ile karışabilir ama içerik mesajlaşmadır | DEFER_DOC_ONLY | Notla: bu "kurye teslimat" değil, mesaj teslimat; MVP'de pasif kalmalı |
| `docs/engineering/mobile-unwired-product-decision-report.md` | masa_siparisi/sadakat/heroes "KEEP" kararları | DEFER_DOC_ONLY | Final strateji ile çelişiyor — üstüne not düşülmeli (bu rapora referans ver) |
| `docs/kalan-isler.md`, `docs/tamamlananlar-2026-06.md` | Sipariş/SMS/sponsorluk açık/tamamlanan kalemleri | DEFER_DOC_ONLY | MVP-dışı kalemler "P2/dondu" etiketlenmeli |
| `docs/rekabet.md`, `docs/archive/fiyat-endeksi-medya-raporu.md` | Eski strateji/medya | DEFER_DOC_ONLY | Final karar raporuyla uyumla |
| `CLAUDE.md` (personel = "owner/waiter POS operations") | Personel app POS olarak tanımlı | DEFER_DOC_ONLY | Final strateji ile çelişir; güncellenmeli (POS değil, owner menü/profil/yorum) |
| `docs/superpowers/specs/2026-06-13-kampanyalar-tab-redesign-design.md` vb. | Kampanya/yemekler tab redesign specleri | DEFER_DOC_ONLY | P1/P2 olarak işaretle |

---

## 9. Silme / Gizleme / Erteleme Karar Matrisi

**REMOVE_SAFE (kod tarafı, düşük risk — DB'ye dokunmaz):**
- `features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` + testi (duplicate)
- `features/embed/data/embed_repository.dart`, `core/ui/link_paste_field.dart` (hiç import edilmiyor)
- `Flexing-Black.ttf` (kullanılmıyor, tasarım onayı sonrası)

**REMOVE_WITH_MIGRATION (önce production apply doğrulaması ŞART, sonra ayrı cleanup migration ÖNERİLİR — bu oturum oluşturmaz):**
- Sponsorship_*, table_orders, loyalty_* DROP'ları — **şu an ÖNERİLMEZ**, sadece "ileride doğrulamayla" notu.

**OUT_OF_SCOPE (kullanıcı talebiyle bu audit dışında — dokunulmaz):**
- AdMob / native reklam altyapısı: `features/ads/`, `core/config/ad_config.dart`, `google_mobile_ads` bağımlılığı, `NativeAdCard` ekleme bloğu.

**KEEP_HIDDEN (kod + DB kalır, UI'dan görünmez yapılır):**
- Mobil discovery sponsorlu bölüm + sponsored rozet (AdMob reklamı hariç — o kapsam dışı)
- Mobil profil gamification (rozet/XP) + sadakat + food-journal nav kartları + `/achievements` route
- Mobil drawer `/compare` + `/budget-combos` ölü linkleri
- Personel app POS sekmeleri (Siparişler, Mutfak/KDS, Sadakat) + initial route değişimi
- Web owner sidebar MVP-dışı menüler
- Web public nav MVP-dışı linkler (Liderler, Bütçe, Karşılaştır, Akıllı Akış, Gurmeler)
- Web MVP-dışı sayfa ağaçları (siparis, sponsorluk, sadakat, feed, vb.)

**DEFER_DOC_ONLY (sadece dokümantasyon güncelle):**
- CLAUDE.md personel tanımı, mobile-unwired-product-decision-report, kalan-isler/tamamlananlar, delivery-integration-status, redesign specleri.

**DO_NOT_REMOVE_PROD_RISK:**
- Tüm uygulanmış migration dosyaları (silinmez), base_schema'daki tüm sponsorship/order/loyalty/achievement nesneleri, ilgili trigger'lar.

**NEEDS_HUMAN_DECISION:**
- Loyalty split-brain (damga vs puan modeli hangisi kalsın)
- `get_my_weekly_missions_v1` (missions P2) ile `get_my_profile_stats_v1` (P0) ayrıştırması
- Perks (avantajlar) MVP'de mi?
- Askıda yemek (askıya alma) ürün kararı
- AI menü analiz edge fn'leri (P1 kolaylaştırma mı, P2 mi?)
- Web duplicate route ağaçlarından hangisi kanon
- Kampanya (campaign) — P1 duyuru mu yoksa P2 story mı

---

## 10. Önerilen Cleanup PR Planı

### PR 1 — Docs / route / menu vaat temizliği
- **Amaç:** Final strateji ile çelişen dokümanları ve ölü navigasyon vaatlerini düzeltmek.
- **Kapsam:** `CLAUDE.md` (personel POS tanımı), `docs/engineering/mobile-unwired-product-decision-report.md` (çelişki notu), `docs/kalan-isler.md`, `docs/delivery/delivery-integration-status.md` (başlık netleştir), mobil `app_drawer.dart` (`/compare`, `/budget-combos` ölü linkleri kaldır), web `src/ui/acik/yerlesim.tsx` (Liderler/Bütçe/Karşılaştır/Akıllı Akış/Gurmeler nav linkleri kaldır).
- **Risk:** Düşük.
- **Test:** `node tools/ceviri-denetimi.mjs`; mobil `flutter analyze`; web `npm run lint`.
- **Rollback:** git revert (sadece doc/nav).

### PR 2 — Mobil UI scope temizliği
- **Amaç:** Flag-korumasız canlı MVP-dışı yüzeyleri gizlemek. **AdMob/native reklam bu PR'ın kapsamı dışındadır — `features/ads/*`, `ad_config.dart`, `google_mobile_ads` bağımlılığına ve `NativeAdCard` bloğuna dokunulmaz.**
- **Kapsam:** `discovery_recommended_tab.dart` (sadece sponsorlu bölüm + isSponsored bloklarını koşula al/kaldır — `NativeAdCard` bloğu hariç), `profile_page.dart` (rozet/XP/sadakat/food-journal kartlarını kaldır), `/achievements` route + nav, duplicate `sponsorluk/` provider+test.
- **Risk:** Yüksek (ana ekranlar). Önce widget testleri güncellensin.
- **Test:** `flutter analyze` + `flutter test` (özellikle discovery + profile testleri).
- **Rollback:** git revert.

### PR 3 — Personel panel scope temizliği
- **Amaç:** Personel app'i POS'tan owner menü/profil/yorum aracına indirgemek.
- **Kapsam:** `uygulama_rotalari.dart` (initial route `/siparisler` → `/menu` veya `/dashboard`; `/siparisler`, `/kds`, `/sadakat` route'larını kaldır/gizle), `ana_kabuk.dart` (Siparişler, Mutfak, Sadakat sekmelerini + bekleyen sipariş badge'ini kaldır).
- **Risk:** Yüksek (uygulamanın ana akışı değişiyor).
- **Test:** `flutter analyze` + `flutter test`.
- **Rollback:** git revert.

### PR 4 — Web / QR scope temizliği
- **Amaç:** Public + owner + admin nav'dan MVP-dışı girişleri kesmek.
- **Kapsam:** `sahip-kabuk-istemcisi.tsx` (Masa Siparişleri, Sponsorluk, Pazarlama, CRM, Finansal, Büyüme, Envanter, Askıya Alma, Yapay Zeka menülerini kaldır/gizle), `yonetici-kabuk-istemcisi.tsx` (sponsor*, ab-test, finansal, masa-geri-bildirim vb.), public nav. Sayfa dosyaları SİLİNMEZ — sadece nav/link kaynakları kesilir (route doğrudan URL ile erişilse bile keşfedilemez).
- **Risk:** Orta.
- **Test:** `npm run typecheck` + `npm run lint`.
- **Rollback:** git revert.

### PR 5 — Backend / API dead code temizliği
- **Amaç:** Yalnızca kod tarafında güvenli, DB'ye dokunmayan kaldırmalar.
- **Kapsam:** Mobil `features/embed/*`, `core/ui/link_paste_field.dart` (REMOVE_SAFE). Edge fn'ler ve route'lar SİLİNMEZ (UI gizleme yeterli).
- **Risk:** Düşük.
- **Test:** `flutter analyze` + `flutter test`.
- **Rollback:** git revert.

### PR 6 — DB cleanup migration planı (YALNIZCA PLAN — bu PR'da migration OLUŞTURULMAZ)
- **Amaç:** Production apply doğrulaması sonrası ele alınacak DB temizliğini belgelemek.
- **Kapsam:** (a) `sponsorship_packages` "Yeedoy Vitrin" kaydını `is_active=false` yapan additive migration ÖNERİSİ. (b) MVP-dışı RPC'lere `COMMENT ... 'DEFERRED P2: ...'` ekleme ÖNERİSİ. (c) Hiçbir DROP, production schema/migration geçmişi bir insan/Supabase-MCP oturumu tarafından doğrulanmadan önerilmez.
- **Risk:** Yüksek (DB) — bu yüzden sadece plan.
- **Test:** `supabase db reset` (lokal) doğrulaması migration yazılırsa.
- **Rollback:** migration henüz yok.

### PR 7 — Test güncellemeleri
- **Amaç:** Gizlenen/kaldırılan yüzeyler için testleri uyumlamak.
- **Kapsam:** discovery/profile widget testleri, `sponsorlu_isletmeler_saglayicisi_test.dart` (sil), personel siparis/kds/sadakat testleri (skip/sil), perks testi (karara bağlı).
- **Risk:** Düşük.
- **Test:** `flutter test` (mobil + personel).
- **Rollback:** git revert.

---

## 11. Kesin Silinmemesi Gerekenler (P0)

Aşağıdakiler hem kod hem DB tarafında **korunur** — final strateji P0 listesi:

- **Claim/sahiplenme:** web `sahiplen/`, `sunucu/sahiplik-talebi/`, `submit_owner_claim_v1`, `admin_decide_owner_claim_v1`, `owner_claims` tablosu + `20260620000004_claim_evidence_storage.sql`, `20260622000004_owner_claims_evidence_storage_path.sql` (storage/policy).
- **Temel işletme profili + bilgi düzenleme:** `businesses` tablosu, owner `isletmeler/menuler` sayfaları, `get_business_full_profile_v1`.
- **Çalışma saatleri / açık-kapalı:** `20260424000001_business_hours.sql`, `is_open_now`, `businesses_with_stats`.
- **Menü oluşturma/düzenleme + fiyat:** `menus`, `menu_items`, owner menü editör, `bulk_import_menu_items`, fiyat güncelleme RPC'leri.
- **Public temel QR menü:** web `karekod/`, `qr/`, `q/`, `kod/`, `(public)/b/`; mobil `public_menu_share_page.dart`; `20260609000005_fix_storage_policies.sql`.
- **Konum keşfi:** `search_nearby_businesses_v3`, `20260515000002_postgis_yakin_arama.sql`, `20260526000001_postgis_business_location_index.sql`, mobil `discovery/`.
- **Temel arama/filtre:** `search_nearby_price_open`, kategori/mesafe/fiyat/açık filtreleri.
- **Temel doğrulanmış yorum/kanıt:** `reviews`, `verified_visit` (`20260422000001_verified_visit_badge.sql`), `_review_verified_visit`, review storage/policy, `20260620000008_review_photos_table.sql`.
- **Favoriler:** `favorites` tablosu + RPC'leri.
- **Veri kalitesi / rapor / kötü-veri bildirimi:** `menu_feedback` (`20260422000002`), moderation queue (`20260526000006`), audit logs/triggers, anti-spam-guard, write-gatekeeper, OSM/FSQ import pipeline, admin claim/queue/reports sayfaları.
- **Güvenlik/RLS sertleştirmeleri:** tüm `*_security_*`, `*_rls_*`, `*_revoke_*`, `*_tighten_*` migration'ları — **dokunulmaz.**

---

## 12. Sonuç

**Hemen temizlenebilecekler (kod, düşük risk):** duplicate sponsorluk provider+test, kullanılmayan embed/link_paste_field, Flexing fontu, drawer ölü linkleri.

**UI'dan gizlenecekler (kod+DB kalır — EN YÜKSEK ÖNCELİK, çünkü şu an canlı):**
1. Mobil discovery sponsorlu bölüm + sponsored rozet (AdMob reklamı **kapsam dışı**, dokunulmaz).
2. Mobil profil gamification (rozet/XP) + sadakat + food-journal kartları + `/achievements`.
3. Personel app POS sekmeleri (Siparişler/KDS/Sadakat) + initial route.
4. Web owner sidebar + public nav + MVP-dışı sayfa ağaçları.

**Kapsam dışı (kullanıcı talebi, dokunulmaz):** AdMob / native reklam altyapısı.

**DB'de bekletilecekler (DROP YOK, apply doğrulaması şart):** tüm sponsorship/order/loyalty/checkin/achievement/campaign nesneleri ve uygulanmış migration'lar.

**P1/P2 için saklanacaklar:** allergen/kalori, çok-dilli menü, scheduled menu, busy-hours, custom domain, kampanya duyurusu, topluluk fiyat doğrulama, fotoğraf katkı, gelişmiş analitik, embed/yerlestir, owner pazarlama/CRM/finansal/büyüme.

**İnsan kararı gerekenler:** loyalty split-brain, missions vs profile_stats ayrıştırması, perks, askıda yemek, AI menü analiz, web duplicate route kanon ağacı, kampanya P1/P2 sınıfı.

**Final strateji ile en net çelişkiler (üründe canlı):** (1) discovery sponsorluk (AdMob hariç), (2) profil gamification, (3) personel POS — üçü de feature-flag korumasız ve son kullanıcıya görünür. `mobile-unwired-product-decision-report.md` ve `CLAUDE.md` da bu özellikleri MVP'nin parçası gibi sunduğu için doküman düzeyinde de çelişki var.

**Not:** AdMob/native reklam bu audit'in kapsamı dışında tutulmuştur (kullanıcı talebi) — final strateji raporunun "MVP'de reklam yok" maddesiyle teorik bir gerilim olsa da, bu rapor bu konuda aksiyon önermez; karar kapsam dışı bırakılmıştır.

---

## 13. DB Derin Analiz (postgres-pro İncelemesi, 2026-06-22)

> Bu bölüm, §3'teki DB bulgularının `postgres-pro` agent'ı tarafından satır satır teyit edilmesi, eksik bulguların eklenmesi ve güvenli bir cleanup PR planının çıkarılması amacıyla yapılmış bağımsız bir derin incelemenin özetidir. **Hiçbir migration değiştirilmedi, hiçbir DROP çalıştırılmadı.** Supabase MCP araçları bu incelemede de tanımlı değildi — production apply durumu yine doğrulanamadı.

### 13.1 Teyit sonucu
§3'teki tüm tablo/RPC/dosya/satır referansları doğrulandı ve **büyük çoğunlukla doğru** bulundu. İki düzeltme:
- §4 l.91'deki `supabase/functions/admin-api-keys` yolu hatalı — gerçek dizin `supabase/functions/admin-api`.
- Bu fonksiyon sadece "gelişmiş admin API keys" değil, `admin_assign_owner_claim_v1`, `admin_assign_report_v1`, `admin_bulk_update_reports_status_v2`, `apply_auto_moderation_rules_v1` gibi **P0 claim/report moderasyon RPC'lerini de** çağırıyor — **bu fonksiyona hide/deprecate önerisi uygulanmamalı, KEEP_P0 olarak düzeltilmeli.**

### 13.2 KRİTİK YENİ BULGU — `loyalty_programs` şema çakışması (MVP-prune'dan bağımsız, olası canlı bug)

İki migration **aynı tabloyu** (`loyalty_programs`) farklı şemalarla `CREATE TABLE IF NOT EXISTS` ile oluşturmaya çalışıyor:
- `20260424000007_loyalty_program.sql` — **puan modeli** (`business_id` PK, `is_active`, `checkin_points`...)
- `20260507000008_sadakat_karti.sql` (sonra çalışır) — **damga modeli** (`id` PK, `stamps_needed`, `reward_desc`...)

`IF NOT EXISTS` nedeniyle ikinci tanım muhtemelen sessizce hiç uygulanmadı — yani `sadakat_karti.sql`'in RPC'leri (`create_loyalty_program_v1`, `add_loyalty_stamp_v1`, damga-modeli `get_my_loyalty_cards_v1`) **gerçek tabloya karşı (puan şeması) çalışıyor olabilir ve runtime'da hata/sessiz başarısızlık üretebilir.**

Bu durum projenin kendi `20260523000002_security_rls_new_tables.sql` migration'ında (l.10-11) zaten not edilmiş ("normalize both") ama **şema çakışmasının kendisi hiç çözülmemiş** — sadece RLS policy'leri normalize edilmiş.

> **Bu bulgu MVP-prune kararından tamamen bağımsızdır ve final stratejik karar raporuyla ilgisi yoktur — backend/ürün ekibine ayrı, öncelikli bir teknik konu olarak iletilmelidir.** Doğrulama adımı: `select column_name, data_type from information_schema.columns where table_name='loyalty_programs'` (insan veya Supabase-MCP erişimli bir oturum tarafından).

### 13.3 Diğer ek bulgular
- `trg_loyalty_checkin` trigger'ı, varlığını `business_checkins` tablosuna bağlı koşullu (`DO $$ IF EXISTS ...`) kuruyor; taranan migration'larda `business_checkins` adında bir tablo hiç oluşturulmamış (check-in özelliği `visits` tablosunu kullanıyor) — **bu trigger muhtemelen production'da hiç kurulmamıştır.** DO_NOT_REMOVE_PROD_RISK etiketi yine de doğru (doğrulama gerekir) ama pratik risk düşük olabilir.
- `award_achievement_v1` RPC'si review/discovery insert path'lerinde trigger zinciri içinden çağrılıyor — **DROP edilirse review/rating akışını kırabilir.** UI-hide güvenli, DB-DROP yüksek riskli.
- `admin_get/list_sponsorship_*` admin RPC'leri (4 adet, base_schema l.2016/3009/3135/~3170) §3'te isim olarak verilmemişti, eklendi — admin panel sponsorship sayfaları muhtemelen bunlara bağlı.
- `business_stories` temel tablosu (kampanya/story altyapısının kökü) §3'te ayrı satır olarak yoktu — `saved_campaigns`'den ayrı değerlendirilmeli, çünkü `business_stories` P1 (kampanya duyurusu) sınırında olabilir, P2 olan sadece `is_featured`/story-format kısmı.
- `_archive/20260323000027_db_cleanup_drop_plan.sql` — geçmişte yazılmış, kendini `RAISE EXCEPTION` ile devre dışı bırakan, yorum satırına alınmış güvenli-DROP-taslağı şablonu bulundu. İleride PR6.4 için stil örneği olarak kullanılabilir.
- `20260622000001_loyal_customers_reward_fields.sql` — bugünün tarihli bir migration, loyalty puan modeline alan ekliyor; loyalty'nin hâlâ aktif geliştirildiğine işaret — §13.2'deki şema çakışması kararının **aciliyetini artırıyor.**

### 13.4 Güvenli DB Cleanup PR Planı (PR6'nın detaylandırılması — hiçbiri DROP içermez, hiçbiri bu oturumda dosyaya yazılmadı)

| Adım | İçerik | DROP var mı | Önkoşul |
|---|---|---|---|
| **PR6.0** | Production doğrulama sorguları: `loyalty_programs` gerçek şeması, `business_checkins` var mı, `table_orders`/`sponsorships`/`loyalty_accounts`/`loyalty_cards` satır sayıları (sadece SELECT) | Hayır | İnsan/Supabase-MCP erişimi |
| **PR6.1** | Additive migration: ilgili MVP-dışı tablo/RPC'lere `COMMENT ON ... IS 'DEFERRED P2 2026-06-22: ...'` ekleme | Hayır | Yok — risksiz, hemen yapılabilir |
| **PR6.2** | Additive migration: `UPDATE sponsorship_packages SET is_active=false WHERE name='Yeedoy Vitrin'` | Hayır (UPDATE) | PR6.0'da aktif/pending sponsorluk kontrolü |
| **PR6.3** | `loyalty_programs` şema çakışması için insan kararı + (gerekirse) "kazanmayan" RPC grubuna `RAISE EXCEPTION 'not_implemented' USING ERRCODE='P0004'` guard migration'ı | Hayır (guard) | PR6.0 + ürün/backend kararı — **acil, MVP-prune'dan bağımsız** |
| **PR6.4** | Gerçek DROP'lar (sadece PR6.0 satır-sayısı=0 VE frontend tarafı PR1-PR5 ile tamamen kesildiği teyit edildikten sonra, ayrı onay döngüsüyle) | **Evet** | Tümü + ek onay |

**Taslak SQL örnekleri (gösterim amaçlı, hiçbiri dosyaya yazılmadı):**
```sql
-- PR6.1 örneği
COMMENT ON TABLE public.sponsorship_packages IS
  'DEFERRED P2 2026-06-22: MVP scope dışı (final stratejik karar raporu §16). UI gizlendi, DB korunuyor.';
COMMENT ON TABLE public.table_orders IS
  'DEFERRED MVP-OUT 2026-06-22: sipariş/POS final stratejide §23 yapılmayacaklar listesinde.';

-- PR6.2 örneği
UPDATE public.sponsorship_packages SET is_active = false WHERE name = 'Yeedoy Vitrin';
```

---

## 14. Mobil Derin Analiz (flutter-expert İncelemesi, 2026-06-22)

> Bu bölüm, §5'teki mobil bulguların `flutter-expert` agent'ı tarafından kod-seviyesinde teyit edilmesi ve sadece **güvenli** bir aksiyon planı çıkarılması amacıyla yapılmış bağımsız bir incelemenin özetidir. Kapsam: yalnızca sipariş/ödeme, check-in, rozet/görev, sponsorlu işletme listeleme (AdMob hariç), sosyal feed, çok-şube. **Hiçbir kod değiştirilmedi.**

### 14.1 §5'e düzeltmeler

- **Sponsorlu bölüm muhtemelen zaten dead code, audit'in "EVET canlı/Yüksek risk" etiketi yanlış/eksik.** `discovery_recommended_tab.dart` l.305 `usePremiumLayout = Theme.of(context).useMaterial3` — `app_theme.dart` l.33 ve l.210'da hem light hem dark tema `useMaterial3: true` sabit. Yani `usePremiumLayout` her zaman `true`, `_DiscoverySponsoredSection`/`isSponsored` rozetini içeren legacy `Stack(...)` dalı **hiçbir koşulda render edilmiyor**; gerçek premium yol (`_buildPremiumDiscoveryLayout`) bu bölümü hiç kullanmıyor ve `BusinessTile`'a `isSponsored` geçirmiyor.
- **`embed/` modülü hakkındaki "REMOVE_SAFE, hiç import edilmiyor" iddiası YANLIŞ — düzeltme: KEEP_P0, silinmemeli.** `EmbedViewerPage` (`features/embed/ui/embed_viewer_page.dart`), `features/profile/ui/components/profile_identity_card.dart` l.237'de profildeki sosyal medya linkini güvenli açmak için **aktif kullanılıyor** — bu P0 profil özelliğinin parçası. (`embed_repository.dart` ve `link_paste_field.dart` ise artık repoda mevcut değil — muhtemelen önceki bir oturumda zaten temizlenmiş, REMOVE_SAFE önerisi o ikisi için zaten gerçekleşmiş.)
- **`features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` (duplicate provider) ve testi artık repoda mevcut değil** — muhtemelen önceki bir oturumda zaten silinmiş. Sadece `features/sponsorluk/ui/sponsored_badge.dart` kaldı (yukarıdaki dead-code zincirine bağlı, ayrıca aşağıda ele alınıyor).
- **Audit'in atladığı 2 yeni MVP-dışı yüzey (7 kategoriden ikisi, hiç §5'te yoktu):**
  1. **Check-in:** `features/business/ui/parts/business_state_views.dart` l.165-219 — "Buradayım" action chip, flag-korumasız, business sayfasında canlı; `check_in_repository.dart` → `log_checkin_v1` RPC. Ayrıca `business_detail_sections.dart` l.610-624 `_CheckinsSummaryLine` ("Konum doğrulaması: N") aynı zincire bağlı.
  2. **Günlük Görevler/gamification:** `profile_page.dart` l.94-107 (`_DailyTaskCard`) + l.124 (`_AchievementsNavCard`, "Başarı Rozetlerim") — ikisi de flag-korumasız, profil sekmesinde canlı; `_DailyTaskCard` ayrıca `/achievements`'a ikinci bir giriş noktası sağlıyor (l.981 "İlerleme ödülleri").

### 14.2 Sadece Güvenli Aksiyon Planı (sıralı — kod değiştirilmedi, sadece plan)

1. **`profile_page.dart`** — Günlük Görevler kartını kaldır: l.94-107 bloğu + `_DailyTaskCard`/`_TaskRow`/`_kDailyTasks`/`_TaskDef` sınıfları + `myDailyMicroTaskProvider` watch/invalidate. *Güvenli çünkü:* provider izole, başka feature import etmiyor, mevcut testler bu karta referans vermiyor.
2. **`profile_page.dart`** — Başarı Rozetlerim kartını kaldır: `_AchievementsNavCard` çağrısı + sınıfı + `achievementsAsync` watch/invalidate. *Güvenli çünkü:* `myAchievementsProvider`/`achievementProgressProvider` sadece bu sayfa + `achievements_page.dart` içinde tüketiliyor.
3. **`router.dart`** — `/achievements` route'unu kaldır (Adım 1-2 sonrası, artık hiçbir UI bu route'a push yapmıyor olmalı). *Güvenli çünkü:* public/paylaşılan bir deep link değil, sadece kullanıcı-içi navigasyon.
4. **`discovery_recommended_tab.dart`** — sponsorlu network çağrılarını kaldır: l.283-292 + l.320-328 `sponsoredBusinessesProvider` watch/invalidate + `_DiscoverySponsoredSection` çağrısı + `isSponsored:` parametresi. *Güvenli çünkü:* bu kod yolu zaten render edilmiyor (14.1), kaldırılması görünür hiçbir şeyi değiştirmez, sadece gereksiz RPC isteğini durdurur. **Önerilen ek güvenlik adımı:** önce bir widget test ekleyip `_DiscoverySponsoredSection`/`SponsoredBadge`'in ağaçta hiç bulunmadığını runtime'da doğrulayan bir regresyon testi yazılması önerilir.
5. **`sponsored_badge.dart` + `business_tile.dart`** — Adım 4 sonrası `isSponsored` parametresi hiçbir çağrıdan `true` alamayacağı için kaldırılabilir. *Dikkat:* `favorites_page.dart`'taki `isSponsored` **ayrı bir model alanı** (`FavoriteCollection.isSponsored`), bununla karıştırılmamalı, ona dokunulmuyor.
6. **Test:** `flutter analyze` + `flutter test` (özellikle `profile_page_test.dart` ve discovery testleri).

### 14.3 Riskli / İnsan Kararı Gerektiren (aksiyon planına dahil edilmedi)

- **Check-in ("Buradayım" chip + `log_checkin_v1` + `_CheckinsSummaryLine`)** — `log_checkin_v1`'in P0 `verified_visit`/doğrulanmış-yorum zincirine girdi sağlayıp sağlamadığı statik analizle netleşmedi; kaldırılırsa P0 özelliği zayıflatabilir. **Backend tarafından `log_checkin_v1` gövdesi incelenmeden dokunulmamalı.**
- **`_CreatorBadgeCard`/"İçerik Üretici Rozeti"** (`profile_page.dart` l.82-92, l.291-329) — "rozet" kelimesi geçse de aslında `creatorProfileControllerProvider.setIsCreator` ile çalışan bir profil-modu toggle'ı; klasik XP/achievement değil. MVP-dışı "gamification" kategorisine girip girmediği ürün kararı gerektirir.
- **`_DiscoverySponsoredSection` widget gövdesinin tamamen silinmesi** (sadece network çağrısının durdurulmasından farklı olarak) — büyük refactor, "gerçekten unreachable" iddiasının runtime/widget testiyle kesinleştirilmesi önce gerekir.
- Sadakat (`/loyalty-cards`), yemek günlüğü (`/food-journal`), perks (`/perks/:businessId`) — kullanıcının bu turda istediği 7 kategoriye tam girmediği için bu incelemenin kapsamı dışında tutuldu, ayrı bir turda ele alınabilir.

---

## Uygulama Promptu İçin Hazır Görev Listesi

> Aşağıdaki maddeler başka bir oturum/agent'ın doğrudan uygulayabileceği netliktedir. Her madde için ilgili dosya + kanıt yukarıdaki bölümlerde mevcuttur. **DB DROP içeren hiçbir madde yoktur; tümü kod/UI/doc veya additive plandır.**

1. **[PR2 / Düşük — düzeltme: önceki "Yüksek" hatalıydı]** `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart`: bu kod yolu `usePremiumLayout` her zaman `true` olduğu için zaten render edilmiyor (§14.1). Önce l.283-292 + l.320-328 `sponsoredBusinessesProvider` watch/invalidate çağrılarını kaldır (gereksiz network isteğini durdurur, sıfır UI riski); sonra `_DiscoverySponsoredSection` (l.942) ve `isSponsored` rozet (l.982) widget gövdesini kaldır (önce regresyon testiyle "unreachable" teyit edilmesi önerilir). **`NativeAdCard` ekleme bloğuna (l.2162-2179) DOKUNMA — AdMob kapsam dışıdır.**
2. ~~[PR2 / Orta] Reklam altyapısını kaldır~~ — **KAPSAM DIŞI (kullanıcı talebi).** `features/ads/`, `core/config/ad_config.dart`, `pubspec.yaml` l.53 `google_mobile_ads: ^7.0.0`'a dokunulmayacak.
3. **[PR2 / Yüksek]** `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart`: "İçerik Üretici Rozeti" (l.291-329), `_AchievementsNavCard` (l.124,426-454), Sadakat (l.555) ve Yemek Günlüğü (l.564) nav kartlarını kaldır. `/achievements` route'unu `router.dart`'tan çıkar.
4. ~~[PR2 / Düşük] `sponsorlu_isletmeler_saglayicisi.dart` + testi sil~~ — **ZATEN YAPILMIŞ.** Bu dosyalar repoda artık mevcut değil (flutter-expert incelemesi §14.1 ile teyit edildi), aksiyon gerekmiyor.
4b. **[Yeni / Düşük, NEEDS_HUMAN_DECISION]** Check-in: `features/business/ui/parts/business_state_views.dart` l.165-219 ("Buradayım" chip) + `business_detail_sections.dart` l.610-624 (`_CheckinsSummaryLine`). **Önce backend `log_checkin_v1`'in `verified_visit`/doğrulanmış-yorum zincirine girdi sağlayıp sağlamadığı incelenmeli** — sağlıyorsa kaldırma P0 özelliğini zayıflatabilir (§14.3).
4c. **[Yeni / Düşük]** `profile_page.dart` Günlük Görevler kartı (l.94-107, `_DailyTaskCard`/`_TaskRow`/`_kDailyTasks`/`_TaskDef`, `myDailyMicroTaskProvider`) kaldırılabilir — izole, başka feature import etmiyor (§14.2 adım 1).
5. **[PR1 / Düşük]** `uygulamalar/mobil/lib/features/shared/ui/components/app_drawer.dart`: `/budget-combos` (l.163-170) ve `/compare` (l.208-214) ölü linklerini kaldır (her ikisi de `enableLabs=false` ile redirect ediliyor).
6. **[PR3 / Yüksek]** `uygulamalar/personel/lib/uygulama/uygulama_rotalari.dart`: `initialLocation`'ı `/siparisler`'den `/menu`'ye al; `/siparisler`, `/kds`, `/sadakat` GoRoute'larını kaldır/gizle.
7. **[PR3 / Yüksek]** `uygulamalar/personel/lib/features/shared/ui/ana_kabuk.dart`: alt menüden Siparişler, Mutfak (KDS), Sadakat destinasyonlarını + bekleyen sipariş badge'ini (`bekleyenSiparisSayisiProvider`) kaldır; `_rotalar` listesini güncelle.
8. **[PR4 / Orta]** `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`: l.26-46 arası Finansal, CRM, Büyüme, Masa Siparişleri, Sponsorluk, Pazarlama, Envanter, Askıya Alma, Yapay Zeka menü öğelerini kaldır/koşula al.
9. **[PR4 / Orta]** `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`: sponsor*, ab-test, finansal-yonetim, masa-geri-bildirimleri, push-kampanyalari, b2b-dis-aktarim, toplu-islemler nav öğelerini kaldır/gizle (claim doğrulama için gerekmiyorlar).
10. **[PR1 / Orta]** `uygulamalar/web/src/ui/acik/yerlesim.tsx`: l.20 Liderler, l.21 Bütçe, l.190 Karşılaştır, l.198/257 Akıllı Akız, Gurmeler linklerini kaldır.
11. ~~[PR5 / Düşük] `features/embed/` sil~~ — **DÜZELTME: KISMEN GEÇERSİZ.** `embed_repository.dart` ve `link_paste_field.dart` repoda zaten mevcut değil (zaten yapılmış). Ama `features/embed/ui/embed_viewer_page.dart` **aktif kullanılıyor** (`profile_identity_card.dart` l.237, sosyal medya link önizleme) — **bu dosyaya DOKUNULMAMALI, KEEP_P0** (§14.1 düzeltmesi).
12. **[PR1 / Düşük]** `CLAUDE.md` personel açıklamasını "owner/waiter POS operations" → "owner menü/profil/yorum yönetimi" olarak güncelle (final strateji §4 ile uyum).
13. **[PR1 / Düşük]** `docs/engineering/mobile-unwired-product-decision-report.md` başına "ÇELİŞKİ NOTU: masa_siparisi/sadakat/heroes final stratejide MVP-dışı (P2); bu rapor bağlı-kod merceğiyle yazıldı" notu ekle ve bu audit'e referans ver.
14. **[PR6.0 / Acil, MVP-prune'dan bağımsız]** Bir insan veya Supabase-MCP erişimli oturum şunu çalıştırsın: `select column_name, data_type from information_schema.columns where table_name='loyalty_programs'` — `loyalty_programs`'ın gerçekte puan mı damga modeliyle mi production'da var olduğunu doğrulamak için (§13.2). Bu, sessiz bir RPC hatası riskini netleştirir, MVP kapsamından bağımsız bir bug tespiti olabilir.
15. **[PR6.0]** Aynı oturum `business_checkins` tablosunun var olup olmadığını (`select to_regclass('public.business_checkins')`) ve `table_orders`/`sponsorships`/`loyalty_accounts`/`loyalty_cards` satır sayılarını doğrulasın.
16. **[PR6.1 / Plan]** PR6.0 sonrası: MVP-dışı tablo/RPC'lere `COMMENT ON ... IS 'DEFERRED P2 ...'` ekleyen additive migration önerilsin (taslak §13.4'te).
17. **[PR6.2 / Plan]** PR6.0'da aktif/pending sponsorluk yoksa: `sponsorship_packages` "Yeedoy Vitrin" kaydını `is_active=false` yapan additive migration önerilsin. **Bu oturumda hiçbir migration OLUŞTURULMADI.**
18. **[İnsan kararı]** Şu 8 başlık ürün/backend ekibine sunulsun: loyalty damga-vs-puan şema çakışması (acil, §13.2), missions/profile_stats ayrımı, perks, askıda yemek, AI menü analiz, web TR/EN duplicate route kanon ağacı, kampanya P1/P2, `business_stories` temel tablosunun P1/P2 sınırı.
19. **[PR7]** Yukarıdaki gizleme/kaldırma sonrası: mobil `flutter analyze && flutter test`, personel `flutter analyze && flutter test`, web `npm run typecheck && npm run lint`, `node tools/ceviri-denetimi.mjs` çalıştırılsın.
