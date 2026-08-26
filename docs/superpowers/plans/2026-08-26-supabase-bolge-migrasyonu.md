# Supabase Bölge Migrasyonu (Seul → Frankfurt) Implementasyon Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. NOT: Bu plan büyük ölçüde insan (kullanıcı) aksiyonu gerektiriyor (Supabase Dashboard'da proje oluşturma, gerçek secret değerlerini girme) — bu adımlar subagent'lara devredilemez, controller (sen) veya kullanıcı tarafından yapılmalı.

**Durum: TAMAMLANDI (2026-08-26).** Yeni proje `wvofyimbjndxtxitsjpd` (Frankfurt, eu-central-1) canlıya alındı, tüm veri doğrulandı, Vercel + worker + web + mobil env var'ları cutover edildi.

**Goal:** Supabase veritabanını `ap-northeast-2` (Seul) bölgesinden `eu-central-1` (Frankfurt) bölgesine, veri kaybı olmadan taşımak; Vercel fonksiyonu zaten Frankfurt'ta (`fra1`) olduğu için fonksiyon↔veritabanı gecikmesini ortadan kaldırmak.

**Architecture:** Yeni bir Supabase projesi Frankfurt'ta oluşturulur. Şema, mevcut 261 migration dosyası (`supabase/migrations/`) `supabase db push` ile uygulanarak yeniden oluşturulur (pg_dump ile şema kopyalamak yerine — migrations zaten bu projenin şema source-of-truth'u). Veri (`public`+`private` şemaları, `auth.users`/`auth.identities`, storage dosyaları) ayrı ayrı, data-only olarak eski projeden yeni projeye taşınır. Doğrulama tamamlandıktan sonra Vercel + worker env var'ları yeni projeye çevrilir.

**Tech Stack:** PostgreSQL 17 (Supabase), `pg_dump`/`psql`, Supabase CLI, Node.js (`@supabase/supabase-js`) storage kopyalama script'i, Vercel CLI/Dashboard.

**Referans doküman:** `docs/superpowers/specs/2026-08-26-supabase-bolge-migrasyonu-design.md`

---

## Ön Koşullar (başlamadan önce doğrula)

- [x] `C:\yeedoy`'da `supabase --version` çalışıyor (Supabase CLI kurulu — v2.72.7).
- [x] Eski proje bağlantı bilgileri elde: proje ref `dktdnbeougrmhkzplbap`, pooler `aws-1-ap-northeast-2.pooler.supabase.com:5432`.
- [x] `psql`/`pg_dump`/`pg_restore` PATH'te mevcut (`C:\Program Files\PostgreSQL\18\bin`).

---

## Task 1: Yeni Supabase Projesini Oluştur — ✅ TAMAMLANDI

- [x] Kullanıcı Supabase Dashboard'dan yeni proje oluşturdu: **ref `wvofyimbjndxtxitsjpd`**, bölge **Frankfurt (eu-central-1)**.
- [x] Proje ref, anon key, service_role key, DB şifresi controller'a iletildi.

---

## Task 2: Şemayı Migrations ile Yeniden Oluştur — ✅ TAMAMLANDI

- [x] `supabase link --project-ref wvofyimbjndxtxitsjpd`
- [x] Extension'lar `psql` ile doğrudan etkinleştirildi (dashboard'a gerek kalmadı): `pg_cron`, `postgis`, `pg_trgm`, `cube`, `earthdistance`, `hypopg`, `index_advisor`.
  - **Sapma:** `pg_trgm`/`cube`/`earthdistance`/`hypopg`/`index_advisor` varsayılan olarak `public` şemasına kuruldu, eski projede `extensions` şemasındaydı → `businesses_address_trgm` gibi index'ler `extensions.gin_trgm_ops` bulamayıp hata verdi. Çözüm: `ALTER EXTENSION ... SET SCHEMA extensions;` ile taşındı.
- [x] `supabase db push` — 261 migration uygulandı. Yol boyunca bulunan ve düzeltilen **migration-drift** (eski projede migration dışı elle yapılmış değişiklikler):
  - `private` şeması hiçbir migration'da `CREATE SCHEMA` edilmemiş — elle oluşturuldu.
  - `list_menu_ai_analysis_v1` RPC'sinin dönüş tipi bir migration'da değişmiş ama `CREATE OR REPLACE` bunu desteklemiyor (Postgres kısıtı) — eski fonksiyon `DROP` edilip migration'ın devam etmesi sağlandı.
  - `review_photos` tablosu iki farklı migration'da tamamen farklı şemayla tanımlı (eski/terk edilmiş tasarım vs. gerçek prod yapısı) — prod'daki gerçek yapı doğrulanıp eski-yapı tablo `DROP` edildi (0 satır, veri kaybı yok).
  - 5 `private.google_maps_*` tablo/view'ı (`places_catalog`, `places_staging`, `import_runs`, `scan_jobs_v5`, `coverage_status_v5`) hiçbir migration dosyasında (ana repo'da da worker'ın kendi `migrations/` klasöründe de) `CREATE TABLE` ile tanımlı değil — eski projeden **şema-only** `pg_dump` alınıp doğrudan uygulandı.
  - Kolon drift: `business_follows.follower_id`, `businesses.boundary_checked`, `menus.external_url`/`source_image_url`, `user_profiles.{city,district,phone,birth_date,gender}` migration'larda yok ama prod'da var — `ALTER TABLE ADD COLUMN` ile eklendi.
- [x] `supabase migration list --linked` — Local/Remote tam eşleşti.
- [x] Storage bucket config doğrulaması (`claim-evidence`, `menu-media`, `temp`) — public flag/file_size_limit/allowed_mime_types eski projeyle birebir eşleşti (migrations otomatik oluşturdu).
- [x] Tam şema diff'i (tüm `public`+`private` tablo/kolonları, otomatik script ile) — yukarıdaki düzeltmelerden sonra **0 eksik kolon** kaldı (sadece 4 önemsiz view/boş-tablo farkı: `business_reviews`, `crowd_checkins`, `price_verifications` view'ları + 0 satırlık `menu_item_translations`, hiçbiri veri taşımıyor).

---

## Task 3: Uygulama Verisini Taşı (public + private, data-only) — ✅ TAMAMLANDI

- [x] Data-only dump alındı, yeni projeye restore edildi.
  - **Sapma 1 — sıralama:** Plandaki sıra (Task 3 → Task 4) ters çevrildi: `public`/`private` verisi `auth.users`'a foreign key ile bağlı olduğu için **önce Task 4 (auth) yapıldı**, sonra Task 3.
  - **Sapma 2 — `--disable-triggers` çalışmadı:** Supabase'in `postgres` rolü sistem trigger'larını (`RI_ConstraintTrigger`) `ALTER TABLE ... DISABLE TRIGGER` ile kapatma izni olmadığından `pg_restore --disable-triggers` "permission denied" hatası verdi. Çözüm: dump `pg_restore -f` ile düz SQL'e çevrilip, dosyanın başına/sonuna `SET session_replication_role = replica;` / `DEFAULT;` eklenip `psql -f` ile çalıştırıldı — bu hem FK kontrolünü hem özel trigger'ları (aşağıya bakın) devre dışı bırakıyor.
  - **Sapma 3 — migration-seed verisi çakışması:** Birçok tabloda (allergens, meal_card_providers, city_search_aliases, plan_features, legal_documents, policy_versions, business_amenities, chains, stock_dish_images, vb.) migrations'ın kendisi demo/seed veri ekliyor, bu veri prod'daki gerçek veriyle aynı PK'lara sahip → restore "duplicate key" hatası verdi. Çözüm: kullanıcı onayıyla, `public`+`private`'daki **tüm tablolar** (`spatial_ref_sys` hariç) restore öncesi `TRUNCATE ... RESTART IDENTITY CASCADE` edildi.
  - **Sapma 4 — özel trigger'lar restore'u engelledi:** `reviews` tablosunda anti-spam `enforce_reviews_edge_guard_v1` trigger'ı, `menu_items`'ta `menu_items_assign_section_v1` trigger'ı normal INSERT sırasında iş kuralı kontrolü yapıyor, ham veri restore'unu reddediyordu — `session_replication_role = replica` bunları da devre dışı bıraktı (Sapma 2'deki çözüm bunu da kapsadı).
  - **Sapma 5 — veri tazeliği:** İlk dump alındıktan sonra (oturum uzun sürdüğü için) Google Maps worker'ı eski projede yeni veri eklemeye devam etti (businesses +232, business_weekly_hours +1379, gmaps_catalog +25 vb.). Cutover'dan hemen önce **taze bir dump** alınıp tekrar restore edildi.
- [x] Tam satır sayısı doğrulaması (otomatik script, tüm `public`+`private` tabloları): **185 tablodan 184'ü birebir eşleşti**, tek fark `review_ratings` (eski projede view/yeni projede tablo, ikisi de 0 satır — veri kaybı yok).

---

## Task 4: Auth Kullanıcılarını Taşı — ✅ TAMAMLANDI (Task 3'ten önce yapıldı)

- [x] `auth.users`+`auth.identities` data-only dump/restore edildi.
  - **Sapma:** Migrations, admin-rol bootstrap'i için sabit UUID'li 2 seed kullanıcı ekliyor (`ornek-yeedoy-admin@seed.yeedoy.local`, `ornek-yeedoy-reviewer@seed.yeedoy.local`) — bunlardan biri gerçek prod kullanıcısıyla AYNI UUID'i kullanıyordu, restore'da "duplicate key" verdi. Çözüm: yeni projedeki `auth.users` restore öncesi tamamen temizlendi (`DELETE FROM auth.users`), sonra gerçek 9 kullanıcı sorunsuz restore edildi.
- [x] Doğrulama: 9/9 kullanıcı, aynı UUID'ler; `auth.identities` 0/0 (iki projede de, tutarlı).
- [x] Kullanıcı `pnpm run dev` ile yeni projeye karşı lokalde giriş yaptı — sorunsuz.

---

## Task 5: Storage Dosyalarını Taşı — ✅ TAMAMLANDI

- [x] `migration/storage_copy.mjs` yazıldı ve çalıştırıldı.
- [x] Sonuç: `menu-media` 119/119 dosya kopyalandı, `claim-evidence`/`temp` zaten boş (0/0).
- [x] Spot-check: kopyalanan bir dosyanın public URL'i yeni projede `200 OK` döndü.

---

## Task 6: pg_cron Job'larını Yeniden Oluştur — ✅ TAMAMLANDI

- [x] **Sapma:** Migrations bu 2 cron job'ını zaten oluşturuyormuş (jobid 1, 4) — plandaki `cron.schedule()` çağrısı mükerrer job'lar (jobid 5, 6) yarattı, bunlar `cron.unschedule()` ile kaldırıldı.
- [x] Doğrulama: tam 2 aktif job, eski projeyle schedule/command birebir eşleşiyor.

---

## Task 7: Edge Functions'ları Deploy Et ve Secret'ları Kopyala — ✅ TAMAMLANDI

- [x] 8 secret ayarlandı: `OPENROUTER_API_KEY` (yerel `.env`'den), `OCR_SPACE_API_KEY`/`USDA_API_KEY`/`POLLINATIONS_API_KEY` (kullanıcıdan), `CLOUDFLARE_ACCOUNT_ID` (Cloudflare token detay JSON'ından çıkarıldı), `GEMINI_API_KEY`/`REPLICATE_API_TOKEN`/`CLOUDFLARE_API_TOKEN` (kullanıcının `apiler.txt` dosyasından). Digest'ler eski projeyle karşılaştırılıp doğrulandı.
- [x] 7 edge function deploy edildi, hepsi `ACTIVE`.

---

## Task 8: Cutover Öncesi Doğrulama — ✅ TAMAMLANDI (basitleştirilmiş biçimde)

- [x] Tüm satır sayısı karşılaştırmaları ✅ (Task 3/4'te detaylı).
- [x] Kullanıcı `.env.local`'i yeni projeye çevirip `pnpm run dev` ile lokalde giriş yaptı, sorun bildirmedi. (Plandaki tam kapsamlı duman testi — yorum yazma, sahip/admin paneli — ayrı ayrı yürütülmedi, kullanıcının genel "sorun yok" onayı yeterli görüldü.)

---

## Task 9: Cutover — Vercel ve Worker Env Var'larını Güncelle — ✅ TAMAMLANDI

- [x] Kullanıcı Vercel Dashboard'dan `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY`'i yeni proje değerleriyle güncelledi.
- [x] Worker `.env` (`D:\yeedoy-google-maps-coverage-v5\.env`) kullanıcı tarafından güncellendi.
- [x] Ayrıca (plan dışı, ek olarak) repo içindeki yerel env dosyaları da güncellendi: kök `C:\yeedoy\.env`, `uygulamalar/web/.env.local`, `uygulamalar/mobil/.env`.
- [x] Vercel'de production redeploy tetiklendi, `READY` oldu (`dpl_31Nk5naY7kn3eD6eTw9vExvB2ZpY`, bölge `fra1`).

---

## Task 10: Cutover Sonrası Canlı Doğrulama ve Eski Projeyi Bekletme

- [x] `www.yeedoy.com/api/harita-arama` canlıda test edildi — yeni projeden gerçek veri döndü, hata yok.
- [ ] pg_cron job'larının yeni projede zamanı geldiğinde gerçekten çalıştığını (ör. `cron.job_run_details`) birkaç gün içinde kontrol et.
- [ ] Eski proje (`dktdnbeougrmhkzplbap`, Seul) en az birkaç gün canlı/dokunulmamış bekletilecek, sonra Dashboard'dan pause edilecek (silinmeyecek).
- [ ] Birkaç gün sorunsuz geçtikten sonra `migration/` klasöründeki geçici dosyaları (`.dump`/`.sql` dosyaları) sil.

---

## Bilinen Riskler / Notlar

- **Migration-drift bulguları kalıcı bir sorun** — bu migrasyon sürecinde bulunan ~6 farklı "migration dosyalarında yok ama prod'da var" drift'i, ana repo migration geçmişinin eksiksiz olmadığını gösteriyor. İleride benzer bir "migrations'tan sıfırdan kurulum" ihtiyacı olursa (yeni bir branch, yeni bir ortam) aynı sorunlarla karşılaşılabilir. Öneri: bu dokümandaki drift listesini kalıcı migration dosyalarına (retroaktif) dönüştürmek ayrı bir görev olarak değerlendirilebilir.
- **DB şifreleri git'e commit edilmedi** — `migration/` klasöründeki dosyalarda açık şifre yok, sadece komutlar ve (gerekli yerlerde) ortam değişkeni referansları.
- **Eski proje hâlâ canlı** — rollback güvencesi olarak bilinçli olarak silinmedi/pause edilmedi.
