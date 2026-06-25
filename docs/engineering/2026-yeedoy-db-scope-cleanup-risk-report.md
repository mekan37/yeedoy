# Yeedoy DB Scope Cleanup Risk Raporu

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

> **Tarih:** 2026-06-23
> **Kapsam:** `supabase/migrations/`, `supabase/functions/` — salt okunur statik analiz
> **Referans dosyalar:** `docs/research/2026-yeedoy-stratejik-karar-raporu.md`, `docs/engineering/2026-yeedoy-mvp-scope-prune-audit.md`
> **Yöntem:** Migration dosyalarının doğrudan okunması (satır seviyesinde), grep/glob ile çapraz referans, frontend (mobil/web/personel) çağrı noktalarının statik taranması.
> **Bu oturumda Supabase MCP read-only tool'ları (`list_tables`, `list_migrations`, `list_edge_functions`, `get_advisors`) TANIMLI DEĞİLDİ** — önceki audit oturumlarında da aynı durum not edilmişti. Dolayısıyla production'a gerçekte hangi migration'ların uygulanmış olduğu, gerçek tablo şemaları ve satır sayıları **bu oturumda da doğrulanamadı**. Tüm bulgular dosya/kod seviyesinde statik kanıttır; production durumu insan veya MCP-erişimli bir oturum tarafından ayrıca teyit edilmelidir.
> **Hiçbir migration dosyası oluşturulmadı, değiştirilmedi. Hiçbir DROP/ALTER SQL yazılmadı veya çalıştırılmadı.** Bu rapor sadece bulgu ve öneri içerir.

---

## 1. Executive Summary

- Bu rapor, önceki MVP scope-prune audit'inin (`2026-yeedoy-mvp-scope-prune-audit.md` §3, §13) DB bulgularını doğrulamak ve özellikle iki kritik bulguyu (loyalty şema çakışması, check-in çift-zincir) derinleştirmek için yapıldı.
- **`loyalty_programs` şema çakışması doğrulandı ve teyit edildi.** İki migration aynı tabloyu farklı PK/kolon şemasıyla `CREATE TABLE IF NOT EXISTS` ile tanımlıyor: `20260424000007_loyalty_program.sql` (puan modeli, `business_id` PK) önce çalışır ve tabloyu yaratır; `20260507000008_sadakat_karti.sql` (damga modeli, `id` PK) sonra çalışır ama `IF NOT EXISTS` nedeniyle **muhtemelen sessizce no-op kalır**. Sonuç: `sadakat_karti.sql`'in kendi RPC'leri (`create_loyalty_program_v1`, `add_loyalty_stamp_v1`, damga-modeli `get_my_loyalty_cards_v1`) muhtemelen **var olmayan kolonlara** (`name`, `stamps_needed`, `reward_desc`) karşı çalışıyor ve runtime'da hata veriyor olabilir. Bu, MVP kapsam kararından bağımsız, olası **canlı bir backend bug**'dır.
- **Check-in çift-zincir bulgusu doğrulandı VE daha kesin bir kanıtla güçlendirildi.** Önceki audit "muhtemelen" diyordu; bu oturum üçüncü bir migration (`20260523000005_perf_rpc_query_fixes.sql`) buldu ve bu migration `get_business_recent_checkins_v1`'i **açıkça ve kesin olarak `public.visits` tablosundan okuyacak şekilde** son kez tanımlıyor (migration tarih sırasına göre en son kazanan budur). Mobil uygulama ise `log_checkin_v1` RPC'si ile `business_checkins` tablosuna yazıyor — bu iki tablo birbirinden tamamen bağımsız. **Sonuç: mobil check-in'ler hiçbir zaman "son 2 saat check-in sayısı" rozetine yansımıyor; rozet sadece web `submit_checkin_v1`/`visits` check-in'lerini sayıyor.** Bu statik analizle kesinleştirilebilen, doğrulanmış bir canlı veri-tutarsızlığı bugı'dır (önceki rapordaki "muhtemelen" ifadesi bu oturumda "kesin" seviyesine yükseltildi).
- **Metodolojik düzeltme:** `00000000000000_base_schema.sql` dosyasının diskteki değişiklik tarihi **2026-04-13**'tür — yani bu dosya, loyalty (`20260424...`), sadakat kartı (`20260507...`) ve check-in (`20260507...`) migration'larından **önceki** bir snapshot'tır. Önceki audit'lerin "`base_schema.sql`'de görülmesi production'a uygulandığının güçlü işaretidir" varsayımı, bu üç özellik grubu için **geçerli değildir** — bu tablolar/RPC'ler base_schema'da hiç yok, sadece sonraki tarihli ayrı migration dosyalarında var. `base_schema.sql`'in ne zaman/nereden alındığı (hangi migration'a kadar consolide edildiği) belgelenmemiş; bu da kendisi bir doğrulama açığıdır.
- Diğer MVP-dışı aday alanlar (sipariş/POS, sponsorluk, achievements/gamification, kampanya/pazarlama) için önceki audit'in sınıflandırması büyük ölçüde doğrulandı, bu raporda tekrar üretilmedi — sadece referans verildi ve P0 listesi netleştirildi.

---

## 2. Kaldırılmaması Gereken P0 DB Nesneleri

Aşağıdakiler stratejik karar raporu §7 P0 listesine ve görev talebindeki P0 kategorilerine (claim, menu, favorite, review/evidence, QR, open status, search RPC, report/storage policy) karşılık gelir. **Bunlara REMOVE_WITH_MIGRATION önerisi verilmez.**

| Kategori | Nesneler | Dosya/kanıt |
|---|---|---|
| Claim/sahiplenme | `owner_claims` tablosu, `submit_owner_claim_v1`, `admin_decide_owner_claim_v1`, `admin_assign_owner_claim_v1` | `20260620000004_claim_evidence_storage.sql`, `20260622000004_owner_claims_evidence_storage_path.sql`, `20260622000002_admin_decide_owner_claim_v1_guards.sql` |
| Menü | `menus`, `menu_items` tabloları, fiyat/içerik güncelleme RPC'leri, `bulk_import_menu_items` | base_schema + çoklu sonraki migration |
| Favoriler | `favorites` tablosu + RPC'leri | base_schema |
| Yorum/kanıt | `reviews`, `verified_visit`, `_review_verified_visit`, `review_photos` | `20260422000001_verified_visit_badge.sql`, `20260620000008_review_photos_table.sql` |
| QR | `karekod`/`qr`/`q`/`kod` route'larına karşılık gelen public menü RPC'leri, storage policy'leri | `20260609000005_fix_storage_policies.sql` |
| Açık/kapalı | `business_hours`, `is_open_now`, `businesses_with_stats` | `20260424000001_business_hours.sql` |
| Konum/arama RPC | `search_nearby_businesses_v3`, PostGIS index'leri | `20260515000002_postgis_yakin_arama.sql`, `20260526000001_postgis_business_location_index.sql` |
| Report/storage policy | `menu_feedback`, moderation queue, `*_security_*`/`*_rls_*`/`*_revoke_*`/`*_tighten_*` migration'ları, `write-gatekeeper`, `anti-spam-guard` edge fn'leri | `20260422000002_menu_feedback.sql`, `20260526000006_*`, ilgili güvenlik migration'ları |
| Admin moderasyon | `admin_assign_report_v1`, `admin_bulk_update_reports_status_v2`, `apply_auto_moderation_rules_v1` (admin-api edge fn üzerinden) | `supabase/functions/admin-api` |

**Not:** `visits` tablosu da bu listeye dolaylı olarak girer — sadece check-in mekaniği için değil, `get_my_profile_stats_v1` gibi P0/karışık RPC'lerde okunuyor olabilir (önceki audit'te işaretlenmişti). `visits` tablosu DROP edilmemeli.

---

## 3. MVP Dışı DB Adayları (Sınıflandırılmış Liste)

> Önceki audit'in (`2026-yeedoy-mvp-scope-prune-audit.md` §3) tablosu bu oturumda satır-seviyesinde tekrar doğrulandı; tekrar üretilmiyor, sadece bu oturumda değişen/yeni bulgular ve teyit notları aşağıda.

| Nesne tipi | Nesne adı | Dosya:satır | Sınıf | Bu oturumdaki teyit/not |
|---|---|---|---|---|
| table | `table_orders` | `20260507000006_masa_siparisi.sql:3` | DO_NOT_REMOVE_PROD_RISK | Değişmedi, doğrulandı |
| table+RPC | `sponsorship_packages`, `sponsorships`, `sponsorship_leads`, `sponsorship_impressions_daily` | `00000000000000_base_schema.sql` (l.23807-23857 civarı) | DO_NOT_REMOVE_PROD_RISK | base_schema bu tabloları içeriyor (sponsorluk özelliği base_schema tarihinden — 2026-04-13 — önce var olmalı; bu özellik için base_schema güvenilir bir kaynak) |
| table | `loyalty_programs` (puan modeli, `business_id` PK) | `20260424000007_loyalty_program.sql:4-15` | **NEEDS_HUMAN_DECISION (acil)** | §4'te detaylı analiz |
| table | `loyalty_programs` (damga modeli, `id` PK) — muhtemelen no-op | `20260507000008_sadakat_karti.sql:4-12` | **NEEDS_HUMAN_DECISION (acil)** | §4'te detaylı analiz |
| table | `loyalty_cards` | `20260507000008_sadakat_karti.sql:14-22` | DO_NOT_REMOVE_PROD_RISK | `loyalty_programs.id` FK'sine bağlı; tablo kendisi muhtemelen var ama referans verdiği `loyalty_programs.id` kolonu yoksa hiçbir satır yazılamaz |
| table | `loyalty_accounts` | `20260424000007_loyalty_program.sql:18-27` | DO_NOT_REMOVE_PROD_RISK | Puan modeli, P2 |
| RPC | `award_loyalty_points_v1`, `get_loyalty_status_v1`, `upsert_loyalty_program_v1`, `get_business_loyal_customers_v1` (puan modeli RPC seti) | `20260424000007_loyalty_program.sql:58-297` | DEFER_P2 | Personel app bunları çağırıyor — §4 |
| RPC | `create_loyalty_program_v1`, `add_loyalty_stamp_v1`, `get_my_loyalty_cards_v1` (damga modeli RPC seti, **2 kez** `CREATE OR REPLACE` ile tanımlı, son sürüm 20260507000008'deki) | `20260507000008_sadakat_karti.sql:25-124` | **NEEDS_HUMAN_DECISION (acil)** | Mobil çağırıyor — §4. `get_my_loyalty_cards_v1` her iki migration'da da var, ikincisi (damga) `CREATE OR REPLACE` ile üzerine yazar, dolayısıyla mobil çağrısının fonksiyon-tarafı sorunsuz çalışır; sorun fonksiyonun erişmeye çalıştığı `loyalty_programs` TABLOSUNUN şemasındadır |
| table | `business_checkins` | `00000000000000_base_schema.sql:22251` | DO_NOT_REMOVE_PROD_RISK | **Düzeltme:** önceki audit "muhtemelen production'da hiç kurulmamış" demişti — **bu YANLIŞ**, tablo base_schema'da `CREATE TABLE IF NOT EXISTS` ile tam şemasıyla (RLS, index, FK, GRANT dahil) tanımlı, base_schema=production konsolide snapshot olduğuna göre bu tablo kesin var |
| table | `visits` | `20260507000002_check_in.sql:78-87` | KEEP (P0'a yakın, dolaylı) | `get_my_profile_stats_v1` gibi RPC'lerin bağımlı olabileceği not edilmişti |
| RPC | `log_checkin_v1` | `00000000000000_base_schema.sql:12868-12930` | **NEEDS_HUMAN_DECISION (acil)** | §4'te detaylı — `business_checkins`'e yazıyor, hiçbir okuma RPC'si artık bunu okumuyor |
| RPC | `submit_checkin_v1`, `get_my_checkin_today_v1` | `20260507000002_check_in.sql:5-75` | KEEP (web kullanıyor, P1/P2 sınırında check-in mekaniği) | `visits`'e yazıyor/okuyor, tutarlı |
| RPC | `get_business_recent_checkins_v1` (3 farklı tanım, sonuncusu kazanır) | `00000000000000_base_schema.sql:8466` (eski, business_checkins) → `20260507000002_check_in.sql:90` (visits) → `20260523000005_perf_rpc_query_fixes.sql:125` (visits, search_path eklenmiş, KESİN SON SÜRÜM) | **NEEDS_HUMAN_DECISION (acil)** | §4'te detaylı |
| trigger | `trg_loyalty_checkin` | `20260424000007_loyalty_program.sql:138-146` | DO_NOT_REMOVE_PROD_RISK | Koşullu (`DO $$ IF EXISTS ... business_checkins ...`) kuruluyor; `business_checkins` artık var olduğu doğrulandığına göre (yukarıdaki düzeltme) **bu trigger muhtemelen production'da kurulmuş olabilir** — önceki audit'in "muhtemelen kurulmamıştır, pratik risk düşük" notu **bu oturumla zayıfladı**, risk yeniden "orta/belirsiz" seviyesine çekilmelidir |
| achievements/XP | base_schema achievement_* nesneleri | base_schema | DO_NOT_REMOVE_PROD_RISK | Değişmedi |
| kampanya/pazarlama | `saved_campaigns`, `push_campaigns`, `email_campaigns`, ilgili edge fn'ler | çoklu migration | DEFER_P2 | Değişmedi |

---

## 4. Production Riski Olanlar — Detaylı Analiz

### 4.1 `loyalty_programs` şema çakışması

**Migration sırası (dosya adı = uygulama sırası, Supabase migration'ları adlarına göre sıralı uygulanır):**

1. `20260424000007_loyalty_program.sql` — `CREATE TABLE IF NOT EXISTS public.loyalty_programs (business_id uuid PRIMARY KEY ..., is_active, checkin_points, review_points, photo_points, reward_threshold_pts, reward_type, reward_value, birthday_bonus_pts, created_at)`. Bu çalıştığında tablo **bu şemayla** oluşturulur.
2. `20260507000008_sadakat_karti.sql` — `CREATE TABLE IF NOT EXISTS public.loyalty_programs (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL, name text NOT NULL, stamps_needed int, reward_desc text, is_active, created_at)`. Tablo zaten var olduğundan (`IF NOT EXISTS`), **bu CREATE TABLE muhtemelen sessizce hiçbir şey yapmaz** — PostgreSQL `IF NOT EXISTS` kolon şemasını kontrol etmez, sadece tablo adının varlığını kontrol eder.

**Sonuç (statik analizle çıkarılabilen en olası senaryo, kesin teyit production sorgusu gerektirir):**
- Gerçek tablo şeması muhtemelen **puan modeli** (`business_id` PK, `name`/`stamps_needed`/`reward_desc` kolonları YOK).
- `sadakat_karti.sql`'deki `create_loyalty_program_v1` fonksiyonu `INSERT INTO loyalty_programs (business_id, name, stamps_needed, reward_desc) VALUES (...)` çalıştırmaya çalışır — eğer gerçek tabloda `name`/`stamps_needed`/`reward_desc` kolonları yoksa bu **`column does not exist` hatasıyla başarısız olur**.
- `add_loyalty_stamp_v1` ve damga-modeli `get_my_loyalty_cards_v1` de aynı şekilde var olmayan kolonlara (`stamps_needed`, `reward_desc`, `name`) erişmeye çalışır.
- Mobil app'in çağırdığı `get_my_loyalty_cards_v1`, **iki migration'da da tanımlı** ve ikincisi (`CREATE OR REPLACE FUNCTION`) kesin olarak kazanır (fonksiyon tanımları `IF NOT EXISTS` değil `OR REPLACE` kullanır) — yani fonksiyonun KENDİSİ damga-modeli sürümdür, ama eriştiği TABLO puan-modeli şemasında olabilir. Bu durumda mobil'in `get_my_loyalty_cards_v1` çağrısı **runtime hatası verir veya hiçbir satır dönmez** (LEFT JOIN/JOIN'e bağlı olarak).
- Personel app'in çağırdığı `get_business_loyal_customers_v1`, `award_loyalty_points_v1` (puan-modeli RPC seti) ise gerçek tablo şemasıyla (puan modeli) uyumlu olduğundan **muhtemelen sorunsuz çalışıyor**.

**Bu projenin kendi farkındalığı:** `20260523000002_security_rls_new_tables.sql` (l.10-11 civarı) bu konuyu "normalize both" notuyla işaretlemiş ama RLS policy normalizasyonu yapılmış, **şema çakışmasının kendisi çözülmemiş**. `20260622000001_loyal_customers_reward_fields.sql` (bugünün tarihine yakın, 2026-06-22) puan modeline yeni alan ekliyor — yani puan modeli üzerinde **hâlâ aktif geliştirme var**, bu da çakışmanın aciliyetini artırıyor.

**Aksiyon (öneri, SQL yazılmadı):** Production'da `information_schema.columns` sorgusuyla gerçek şema doğrulanmalı (bkz. §7). Sonuca göre ya damga-modeli RPC seti devre dışı bırakılmalı (mobil tarafı puan-modeli API'sine geçirilmeli) ya da iki şema birleştirecek bir migration (mevcut veriyi koruyarak kolon ekleme) tasarlanmalı — ama bu karar backend/ürün ekibinin onayı gerektirir, bu rapor bir SQL önermez.

### 4.2 Check-in çift-zincir

**Zincir A (mobil):** `check_in_repository.dart` → RPC `log_checkin_v1` → **`business_checkins`** tablosuna INSERT (`menu_id`, `table_no`, `client_id`, `user_id` ile, 10 dakikalık dedup).

**Zincir B (web):** `eylem-istemcisi.tsx:376` → RPC `submit_checkin_v1` → **`visits`** tablosuna INSERT (`note`, `checked_in_at` ile, günlük 1 limit).

**Ortak okuma noktası:** Hem mobil (`business_checkins_provider.dart`) hem web (`(genel)/isletme/[slug]/page.tsx:80`) aynı RPC'yi çağırıyor: `get_business_recent_checkins_v1(p_business_id, p_hours=2)`.

**Bu RPC'nin 3 farklı tanımı, tarih sırasıyla:**

| Sıra | Dosya | Kaynak tablo | Not |
|---|---|---|---|
| 1 | `00000000000000_base_schema.sql:8466` | `business_checkins` | base_schema snapshot tarihi (2026-04-13), bu fonksiyonun **ilk/eski** hali |
| 2 | `20260507000002_check_in.sql:90-106` | `visits` | `CREATE OR REPLACE FUNCTION` — tablo kaynağını `business_checkins`'ten `visits`'e değiştirir |
| 3 | `20260523000005_perf_rpc_query_fixes.sql:125-144` | `visits` | `CREATE OR REPLACE FUNCTION`, sadece `search_path` ekliyor (güvenlik amaçlı), kaynak tablo aynı kalır: **`visits`** |

**Kesin sonuç:** Migration dosya adları kronolojik sırayla uygulandığına göre (Supabase migration sistemi bunu garanti eder), en son ve kazanan tanım **`visits` tablosunu okur**. Bu, statik analizle ulaşılabilecek en kesin sonuçtur — `CREATE OR REPLACE FUNCTION` `IF NOT EXISTS` gibi belirsiz değildir, kesin olarak üzerine yazar.

**Pratik etki:** Mobil kullanıcı bir işletmede check-in yaptığında (`log_checkin_v1` → `business_checkins`), o işletmenin "son 2 saatte N check-in" rozeti/`_CheckinsSummaryLine` (her iki platformda da aynı RPC'yi okur) **bu check-in'i hiçbir zaman görmez** — çünkü rozet RPC'si artık `visits` tablosunu sorgular, mobil ise `business_checkins`'e yazar. Rozet sadece web tarafından gelen `submit_checkin_v1` check-in'lerini sayar. Bu, **kullanıcıya gösterilen bir sayının yanlış/eksik olduğu, doğrulanmış (statik analizle kesinleştirilmiş, sadece runtime teyidi eksik) bir veri tutarsızlığı bug'ıdır.**

**Ek risk:** `trg_loyalty_checkin` trigger'ı (`20260424000007_loyalty_program.sql:138-146`) koşullu olarak `business_checkins` tablosu üzerine kuruluyor (`DO $$ IF EXISTS (... table_name='business_checkins') THEN CREATE TRIGGER ...`). Bu oturum `business_checkins`'in base_schema'da **var olduğunu** doğruladığına göre (§3 düzeltmesi), bu trigger'ın production'da kurulu olma olasılığı önceki audit'in tahmin ettiğinden **daha yüksektir**. Eğer kuruluysa, mobil check-in'ler (`log_checkin_v1` → `business_checkins` INSERT) sadakat puan-modeli hesabına (`loyalty_accounts`) otomatik puan yazıyor olabilir — bu da §4.1'deki şema çakışmasıyla birleştiğinde, mobil tarafının aslında (bilmeden) puan-modeli loyalty sistemine veri besliyor olabileceği anlamına gelir, halbuki mobil kullanıcı arayüzü damga-modeli (`get_my_loyalty_cards_v1` / `SadakatKartlarimSayfasi`) gösteriyor.

**Aksiyon (öneri, SQL yazılmadı):** Backend ekibi şu soruları netleştirmeli: (1) mobil check-in'in amacı neydi — gerçekten `business_checkins`'e mi yazılmalıydı yoksa `visits`'e mi? (2) iki zincir birleştirilmeli mi (mobil de `submit_checkin_v1`'i çağırsın) yoksa `get_business_recent_checkins_v1` her iki tabloyu da (UNION) saymalı mı? Bu bir ürün/backend kararıdır, bu rapor sadece kanıtı sunar.

---

## 5. Yeni Cleanup Migration Gerektirebilecekler (Sadece Liste — SQL Yazılmadı)

| # | İçerik | Gerekçe | Risk seviyesi |
|---|---|---|---|
| 1 | `loyalty_programs` gerçek production şemasını teyit eden salt-okunur sorgu (insan/MCP oturumu) | §4.1 — hangi RPC setinin gerçekten çalıştığını netleştirmeden hiçbir düzeltme migration'ı tasarlanamaz | Yok (SELECT) |
| 2 | `loyalty_programs` şema birleştirme/ayrıştırma migration'ı (örn. damga-modeli alanlarını puan-modeli tabloya ek kolon olarak ekleme, veya iki ayrı tabloya ayırma — `loyalty_programs_stamps` gibi yeni bir ad) | İki bağımsız ürün ihtiyacı (puan vs damga) aynı tabloyu paylaşamaz; additive olabilir, DROP gerektirmez | Orta — additive, dikkatli tasarlanmalı |
| 3 | `get_business_recent_checkins_v1`'in her iki tabloyu da (`business_checkins` UNION `visits`) sayacak şekilde güncellenmesi, VEYA mobil tarafının `submit_checkin_v1`'e geçirilmesi | §4.2 — veri tutarsızlığını gidermek için; SQL tarafı küçük bir additive RPC güncellemesi olabilir ama hangi tarafın "doğru" davranış olduğu ürün kararı gerektirir | Orta |
| 4 | `trg_loyalty_checkin` trigger'ının production'da gerçekten kurulu olup olmadığının teyidi + eğer kuruluysa hangi loyalty şemasına yazdığının doğrulanması | §4.2 — şema çakışmasıyla birleşince çift risk oluşturuyor | Yok (SELECT/inceleme) |
| 5 | `sponsorship_packages` "Yeedoy Vitrin" kaydının `is_active=false` yapılması (önceki audit'te de önerilmişti, bu oturumda tekrar teyit edildi, hâlâ uygulanmamış) | Strateji raporu §16 — MVP'de sponsorluk kapalı olmalı, ama aktif/satılabilir paket tohumlanmış durumda | Düşük (UPDATE, DROP değil) |
| 6 | MVP-dışı tablo/RPC'lere `COMMENT ON ... IS 'DEFERRED P2 ...'` ekleyen additive dokümantasyon migration'ı | Gelecekteki geliştiricilerin bu tabloların neden var olduğunu/aktif geliştirilip geliştirilmediğini bilmesi için | Yok (sadece COMMENT) |

**Not:** Yukarıdaki hiçbiri bu oturumda dosyaya yazılmadı. Hepsi "ileride böyle bir migration gerekebilir" şeklinde sadece tarif edilmiştir.

---

## 6. Dokunulmaması Gerekenler

- `00000000000000_base_schema.sql` — büyük konsolide migration, asla elle değiştirilmemeli (zaten CLAUDE.md kuralı).
- Tüm `*_security_*`, `*_rls_*`, `*_revoke_*`, `*_tighten_*` migration'ları.
- §2'deki tüm P0 nesneler.
- Uygulanmış hiçbir migration dosyasının içeriği — yeni bulgular her zaman additive yeni migration'larla ele alınmalı.
- `business_checkins`, `visits`, `loyalty_programs`, `loyalty_accounts`, `loyalty_cards`, `table_orders`, `sponsorship_*` tabloları — DROP edilmemeli, sadece §5'teki gibi additive/COMMENT/UPDATE seviyesinde dokunulabilir, hepsi production doğrulaması sonrası.
- `trg_loyalty_review`, `trg_loyalty_checkin` trigger'ları — DROP edilirse review/check-in akışını sessizce kırabilir.
- `admin-api` edge function'ı (P0 claim/report moderasyon RPC'lerini de çağırıyor).

---

## 7. Güvenli Sıradaki Adım Önerisi

Aşağıdaki sorgular **sadece SELECT/read-only**dır, örnek olarak verilmiştir, bir insan veya Supabase MCP erişimli bir oturum tarafından production'da çalıştırılmalıdır. **Bu rapor bunları çalıştırmamıştır.**

```sql
-- 1. loyalty_programs gerçek şemasını teyit et (puan modeli mi damga modeli mi kazandı)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'loyalty_programs'
ORDER BY ordinal_position;

-- 2. business_checkins tablosunun var olup olmadığını ve satır sayısını teyit et
SELECT to_regclass('public.business_checkins') AS table_exists;
SELECT count(*) FROM public.business_checkins;

-- 3. visits tablosundaki check-in dağılımını gör (hangi taraf gerçekten check-in üretiyor)
SELECT count(*) FROM public.visits;

-- 4. trg_loyalty_checkin trigger'ının kurulu olup olmadığını teyit et
SELECT tgname, tgrelid::regclass AS table_name, tgenabled
FROM pg_trigger
WHERE tgname = 'trg_loyalty_checkin';

-- 5. get_business_recent_checkins_v1 fonksiyonunun production'daki GERÇEK gövdesini gör
-- (hangi tabloyu okuduğunu son kez teyit eder)
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'get_business_recent_checkins_v1';

-- 6. loyalty_cards / loyalty_accounts satır sayıları (gerçek kullanım var mı)
SELECT count(*) FROM public.loyalty_cards;
SELECT count(*) FROM public.loyalty_accounts;

-- 7. sponsorship_packages aktif/satılabilir paket kontrolü
SELECT id, name, is_active FROM public.sponsorship_packages;

-- 8. table_orders / sponsorships satır sayıları (gerçek kullanım var mı, cleanup önceliklendirmesi için)
SELECT count(*) FROM public.table_orders;
SELECT count(*) FROM public.sponsorships;
```

**Bu sorguların sonucuna göre öncelik sırası:**
1. Sorgu 1, 4, 5 — loyalty/check-in bug'larının gerçekliğini kesinleştirir (en acil, §4.1 ve §4.2).
2. Sorgu 2, 3, 6, 8 — hangi tabloların gerçekten veri içerdiğini (yani DROP riskinin gerçek boyutunu) gösterir.
3. Sorgu 7 — sponsorship paketinin pasifleştirilmesi öncesi son kontrol.

**Bu rapor herhangi bir DROP/ALTER önermez.** Yukarıdaki sorgular sonuçlandıktan sonra, §5'teki additive migration adayları backend/ürün ekibiyle birlikte değerlendirilmelidir.
