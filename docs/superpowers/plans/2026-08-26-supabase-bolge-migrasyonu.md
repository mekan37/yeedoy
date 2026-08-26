# Supabase Bölge Migrasyonu (Seul → Frankfurt) Implementasyon Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. NOT: Bu plan büyük ölçüde insan (kullanıcı) aksiyonu gerektiriyor (Supabase Dashboard'da proje oluşturma, gerçek secret değerlerini girme) — bu adımlar subagent'lara devredilemez, controller (sen) veya kullanıcı tarafından yapılmalı.

**Goal:** Supabase veritabanını `ap-northeast-2` (Seul) bölgesinden `eu-central-1` (Frankfurt) bölgesine, veri kaybı olmadan taşımak; Vercel fonksiyonu zaten Frankfurt'ta (`fra1`) olduğu için fonksiyon↔veritabanı gecikmesini ortadan kaldırmak.

**Architecture:** Yeni bir Supabase projesi Frankfurt'ta oluşturulur. Şema, mevcut 261 migration dosyası (`supabase/migrations/`) `supabase db push` ile uygulanarak yeniden oluşturulur (pg_dump ile şema kopyalamak yerine — migrations zaten bu projenin şema source-of-truth'u). Veri (`public`+`private` şemaları, `auth.users`/`auth.identities`, storage dosyaları) ayrı ayrı, data-only olarak eski projeden yeni projeye taşınır. Doğrulama tamamlandıktan sonra Vercel + worker env var'ları yeni projeye çevrilir.

**Tech Stack:** PostgreSQL 17 (Supabase), `pg_dump`/`psql`, Supabase CLI, Node.js (`@supabase/supabase-js`) storage kopyalama script'i, Vercel CLI/Dashboard.

**Referans doküman:** `docs/superpowers/specs/2026-08-26-supabase-bolge-migrasyonu-design.md`

---

## Ön Koşullar (başlamadan önce doğrula)

- [ ] `C:\yeedoy`'da `supabase --version` çalışıyor (Supabase CLI kurulu).
- [ ] Eski proje bağlantı bilgileri elde: proje ref `dktdnbeougrmhkzplbap`, pooler `aws-1-ap-northeast-2.pooler.supabase.com:5432`, veritabanı şifresi kullanıcıda mevcut (worker `.env`'de veya password manager'da).
- [ ] `psql` PATH'te mevcut (önceki oturumlarda `C:\Program Files\PostgreSQL\18\bin\psql` kullanılmış — bu path'i kullan).

---

## Task 1: Yeni Supabase Projesini Oluştur

**Bu adım tamamen manuel — kullanıcı (sen) Supabase Dashboard'dan yapmalı, ben API ile yeni proje oluşturamıyorum.**

- [ ] Kullanıcı https://supabase.com/dashboard adresine gider, "New Project" tıklar.
- [ ] Organizasyon: mevcut organizasyon seçilir (eski projeyle aynı organizasyon).
- [ ] Proje adı: `yeedoy-webim-eu` (veya tercih edilen bir isim — eski projeyle karışmaması için farklı olsun).
- [ ] Database Password: güçlü, yeni bir şifre üretilir ve **kaydedilir** (bu şifre sonraki adımlarda `psql`/`pg_dump` bağlantı string'lerinde kullanılacak).
- [ ] Region: **Frankfurt (eu-central-1)** seçilir.
- [ ] Pricing Plan: eski projeyle aynı plan seçilir.
- [ ] "Create new project" tıklanır, proje provision edilene kadar (~2 dakika) beklenir.
- [ ] Proje hazır olduğunda: **Project Settings → General**'dan yeni proje ref'i (`https://<YENİ_REF>.supabase.co` formatındaki subdomain) kopyalanır.
- [ ] **Project Settings → API**'den: yeni `anon` (publishable) key ve `service_role` key kopyalanır.
- [ ] **Project Settings → Database → Connection string → Session pooler**'dan tam bağlantı string'i kopyalanır (format: `postgresql://postgres.<YENİ_REF>:[YOUR-PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres`).
- [ ] Bu 4 bilgiyi (proje ref, anon key, service role key, DB şifresi) controller'a (bana) ilet — sonraki adımlarda kullanılacak. **Şifre ve service_role key'i asla git'e commit etme veya bana açık metin olarak sohbette yapıştırma dışında bir yerde saklama — sadece bu oturumda kullanılacak.**

Bu adım tamamlanmadan Task 2'ye geçilemez (sonraki tüm adımlar yeni proje ref'ine ihtiyaç duyuyor).

---

## Task 2: Şemayı Migrations ile Yeniden Oluştur

**Dosyalar:** `C:\yeedoy\supabase\migrations\*.sql` (261 dosya, mevcut, değiştirilmeyecek)

- [ ] Ortam değişkeni olarak yeni proje bilgilerini ayarla (PowerShell):
  ```powershell
  $NEW_REF = "<Task 1'den alınan proje ref>"
  $NEW_DB_PASSWORD = "<Task 1'de oluşturulan DB şifresi>"
  ```
- [ ] `C:\yeedoy` dizininde Supabase CLI'ı yeni projeye linkle:
  ```bash
  cd C:/yeedoy
  supabase link --project-ref $NEW_REF
  ```
  (Şifre sorulursa `$NEW_DB_PASSWORD` gir.)
- [ ] Gerekli extension'ların önceden etkinleştirildiğinden emin ol — Supabase Dashboard'da yeni proje için **Database → Extensions**'a git ve şunları etkinleştir (migrations `CREATE EXTENSION IF NOT EXISTS` çağırıyor ama `pg_cron` gibi bazıları dashboard'dan ilk etkinleştirme gerektirebilir):
  - `pg_cron`
  - `postgis`
  - `pg_trgm`
  - `cube`
  - `earthdistance`
  - `hypopg`
  - `index_advisor`

  (`uuid-ossp`, `pgcrypto`, `pg_stat_statements`, `supabase_vault`, `plpgsql` her yeni Supabase projesinde varsayılan olarak zaten etkin.)
- [ ] Tüm migration'ları yeni projeye uygula:
  ```bash
  supabase db push
  ```
  Bu işlem 261 migration'ı sırayla uygular — birkaç dakika sürebilir. Hata alırsa (örn. eksik extension), hatayı çöz ve `supabase db push` komutunu tekrar çalıştır (idempotent, kaldığı yerden devam eder çünkü zaten uygulanmış migration'lar tekrar çalıştırılmaz).
- [ ] Doğrula: migration'ların hepsi başarıyla uygulandı mı?
  ```bash
  supabase migration list --linked
  ```
  Çıktıda tüm migration'ların hem "Local" hem "Remote" sütununda göründüğünü, farkı olmadığını kontrol et.
- [ ] Doğrula: storage bucket'ları migrations aracılığıyla otomatik oluştu mu (`20260709000002_menu_media_bucket.sql` vb. bunu yapıyor)?
  ```bash
  psql "postgresql://postgres.$NEW_REF:$NEW_DB_PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" -c "select id, public, file_size_limit from storage.buckets order by id;"
  ```
  Çıktıda `claim-evidence`, `menu-media`, `temp` bucket'larının, Task 1 öncesi eski projedeki config'lerle (public flag, file_size_limit) birebir eşleştiğini doğrula.

---

## Task 3: Uygulama Verisini Taşı (public + private şemaları, data-only)

**Dosyalar:**
- Oluştur: `C:\yeedoy\migration\dump_restore.md` (komut geçmişi/notlar için)
- Oluştur (geçici): `C:\yeedoy\migration\public_private_data.dump`

- [ ] `migration/` klasörünü oluştur:
  ```bash
  mkdir -p C:/yeedoy/migration
  ```
- [ ] Eski projeden data-only dump al (şema zaten Task 2'de migrations ile oluşturuldu, sadece VERİ taşınıyor). `public.spatial_ref_sys` PostGIS extension'ının kendi referans verisi — yeni projede `CREATE EXTENSION postgis` zaten bunu doldurdu, bu yüzden dahil edilmiyor:
  ```bash
  PGPASSWORD="<eski proje DB şifresi>" pg_dump \
    "postgresql://postgres.dktdnbeougrmhkzplbap@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres" \
    --schema=public --schema=private \
    --data-only \
    --no-owner --no-privileges \
    --exclude-table-data=public.spatial_ref_sys \
    --format=custom \
    --file=C:/yeedoy/migration/public_private_data.dump
  ```
- [ ] Dump'ı yeni projeye restore et:
  ```bash
  PGPASSWORD="$NEW_DB_PASSWORD" pg_restore \
    --dbname="postgresql://postgres.$NEW_REF@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" \
    --no-owner --no-privileges \
    --disable-triggers \
    C:/yeedoy/migration/public_private_data.dump
  ```
  (`--disable-triggers`: restore sırasında foreign-key/trigger sırası karmaşasını önler; veri zaten eski projede tutarlı halde toplanmıştı.)
- [ ] Restore çıktısında `ERROR` var mı kontrol et. `already exists` gibi zararsız uyarılar (ör. bazı lookup/seed verisi migrations tarafından zaten eklenmişse) olabilir — gerçek veri kaybına yol açan hatalar (constraint violation, tablo bulunamadı) olmadığından emin ol.
- [ ] Satır sayısı doğrulaması — her önemli tablo için eski/yeni proje satır sayılarını karşılaştır. Eski projede (mevcut MCP bağlantısı ile):
  ```sql
  select
    (select count(*) from public.businesses) as businesses,
    (select count(*) from public.business_external_sources) as business_external_sources,
    (select count(*) from public.business_weekly_hours) as business_weekly_hours,
    (select count(*) from public.reviews) as reviews,
    (select count(*) from private.google_maps_places_catalog) as gmaps_catalog,
    (select count(*) from private.google_maps_import_runs) as gmaps_import_runs,
    (select count(*) from private.google_maps_scan_jobs_v5) as gmaps_scan_jobs,
    (select count(*) from private.google_maps_unresolved_candidates) as gmaps_unresolved;
  ```
  Yeni projede aynı sorguyu çalıştır:
  ```bash
  psql "postgresql://postgres.$NEW_REF:$NEW_DB_PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" -c "select (select count(*) from public.businesses) as businesses, (select count(*) from public.business_external_sources) as business_external_sources, (select count(*) from public.business_weekly_hours) as business_weekly_hours, (select count(*) from public.reviews) as reviews, (select count(*) from private.google_maps_places_catalog) as gmaps_catalog, (select count(*) from private.google_maps_import_runs) as gmaps_import_runs, (select count(*) from private.google_maps_scan_jobs_v5) as gmaps_scan_jobs, (select count(*) from private.google_maps_unresolved_candidates) as gmaps_unresolved;"
  ```
  **İki sonuç birebir eşleşmeli.** Eşleşmezse dur, farkı araştır (hangi tablo eksik/fazla), Task 4'e geçme.

---

## Task 4: Auth Kullanıcılarını Taşı

**Neden ayrı:** `auth.users`/`auth.identities` Supabase'in yönettiği bir şema; tam şema DDL'ini dump/restore etmek yerine sadece VERİYİ (mevcut, Task 2'de zaten doğru şekilde oluşturulmuş tablolara) aktarıyoruz. Sadece 9 test kullanıcısı olduğu için düşük risk.

- [ ] Auth verisini eski projeden data-only dump al:
  ```bash
  PGPASSWORD="<eski proje DB şifresi>" pg_dump \
    "postgresql://postgres.dktdnbeougrmhkzplbap@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres" \
    --data-only \
    --table=auth.users --table=auth.identities \
    --format=custom \
    --file=C:/yeedoy/migration/auth_data.dump
  ```
  (`confirmed_at` GENERATED ALWAYS kolonu, `identities.email` GENERATED ALWAYS kolonu — `pg_dump` bunları otomatik olarak INSERT listesinden hariç tutar, ekstra bir işlem gerekmiyor.)
- [ ] Yeni projeye restore et:
  ```bash
  PGPASSWORD="$NEW_DB_PASSWORD" pg_restore \
    --dbname="postgresql://postgres.$NEW_REF@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" \
    --no-owner --no-privileges \
    --disable-triggers \
    C:/yeedoy/migration/auth_data.dump
  ```
- [ ] Doğrula — eski projede kullanıcı sayısı ve id listesi:
  ```sql
  select id, email, created_at from auth.users order by created_at;
  ```
  Yeni projede aynı sorgu, **aynı 9 satır, aynı `id` (UUID) değerleriyle** dönmeli (UUID'lerin aynı kalması kritik — `reviews.user_id`, `owner_claims.user_id` gibi foreign key'ler bu ID'lere bağlı, Task 3'te zaten doğru taşındı çünkü aynı UUID'leri referans ediyorlar).
- [ ] Manuel giriş testi (Task 8'de tekrar, daha kapsamlı yapılacak ama burada hızlı bir kontrol): yeni proje URL'i + anon key ile bir test scriptinde/Postman'de mevcut bir test kullanıcısının şifresiyle `signInWithPassword` dene — encrypted_password hash'i taşındığı için aynı şifreyle giriş yapabilmeli.

---

## Task 5: Storage Dosyalarını Taşı

**Dosyalar:**
- Oluştur: `C:\yeedoy\migration\storage_copy.mjs`

- [ ] Script'i yaz:
  ```javascript
  // C:\yeedoy\migration\storage_copy.mjs
  // Tek seferlik kullanım: eski projedeki tüm storage nesnelerini yeni projeye kopyalar.
  import { createClient } from '@supabase/supabase-js';

  const OLD_URL = 'https://dktdnbeougrmhkzplbap.supabase.co';
  const OLD_SERVICE_KEY = process.env.OLD_SERVICE_ROLE_KEY;
  const NEW_URL = process.env.NEW_SUPABASE_URL;
  const NEW_SERVICE_KEY = process.env.NEW_SERVICE_ROLE_KEY;

  if (!OLD_SERVICE_KEY || !NEW_URL || !NEW_SERVICE_KEY) {
    throw new Error('OLD_SERVICE_ROLE_KEY, NEW_SUPABASE_URL, NEW_SERVICE_ROLE_KEY env var\'ları gerekli.');
  }

  const oldClient = createClient(OLD_URL, OLD_SERVICE_KEY);
  const newClient = createClient(NEW_URL, NEW_SERVICE_KEY);

  const BUCKETS = ['claim-evidence', 'menu-media', 'temp'];

  async function listAllFiles(client, bucket, prefix = '') {
    const { data, error } = await client.storage.from(bucket).list(prefix, { limit: 1000 });
    if (error) throw error;
    let files = [];
    for (const item of data) {
      const path = prefix ? `${prefix}/${item.name}` : item.name;
      if (item.id === null) {
        // klasör — içine in
        files = files.concat(await listAllFiles(client, bucket, path));
      } else {
        files.push(path);
      }
    }
    return files;
  }

  async function copyBucket(bucket) {
    const files = await listAllFiles(oldClient, bucket);
    console.log(`[${bucket}] ${files.length} dosya bulundu.`);
    let copied = 0;
    for (const path of files) {
      const { data: blob, error: downloadError } = await oldClient.storage.from(bucket).download(path);
      if (downloadError) {
        console.error(`  İNDİRME HATASI ${path}:`, downloadError.message);
        continue;
      }
      const { error: uploadError } = await newClient.storage
        .from(bucket)
        .upload(path, blob, { upsert: true, contentType: blob.type || 'application/octet-stream' });
      if (uploadError) {
        console.error(`  YÜKLEME HATASI ${path}:`, uploadError.message);
        continue;
      }
      copied += 1;
    }
    console.log(`[${bucket}] ${copied}/${files.length} dosya kopyalandı.`);
    return { bucket, total: files.length, copied };
  }

  const results = [];
  for (const bucket of BUCKETS) {
    results.push(await copyBucket(bucket));
  }

  console.log('\nÖzet:');
  for (const r of results) {
    console.log(`  ${r.bucket}: ${r.copied}/${r.total}`);
  }
  const failed = results.some((r) => r.copied !== r.total);
  if (failed) {
    console.error('\nBazı dosyalar kopyalanamadı — yukarıdaki hataları incele, kopyalanmayanları elle taşı.');
    process.exit(1);
  }
  ```
- [ ] Script'i çalıştır (repo root'ta, `@supabase/supabase-js` zaten `uygulamalar/web`'de bağımlılık olarak mevcut — `uygulamalar/web/node_modules`'dan çalıştır veya `npx`):
  ```bash
  cd C:/yeedoy/uygulamalar/web
  OLD_SERVICE_ROLE_KEY="<eski proje service_role key>" \
  NEW_SUPABASE_URL="https://$NEW_REF.supabase.co" \
  NEW_SERVICE_ROLE_KEY="<yeni proje service_role key>" \
  node ../../migration/storage_copy.mjs
  ```
- [ ] Çıktıda her bucket için `copied === total` olduğunu doğrula (`menu-media` için 119/119 bekleniyor, diğer ikisi 0/0 zaten boş).
- [ ] Spot-check: yeni projede rastgele bir `menu-media` dosyasının public URL'ini tarayıcıda aç, görselin gerçekten yüklendiğini doğrula (`https://$NEW_REF.supabase.co/storage/v1/object/public/menu-media/<bir dosya yolu>`).

---

## Task 6: pg_cron Job'larını Yeniden Oluştur

- [ ] Yeni projede iki job'ı oluştur:
  ```bash
  psql "postgresql://postgres.$NEW_REF:$NEW_DB_PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" <<'EOF'
  select cron.schedule('notify-favorite-revisit-reminders', '0 10 * * *', $$SELECT public.notify_favorite_revisit_reminders_v1(200)$$);
  select cron.schedule('purge-expired-business-audit-log', '0 3 * * *', $$select public.purge_expired_business_audit_log();$$);
  EOF
  ```
- [ ] Doğrula:
  ```bash
  psql "postgresql://postgres.$NEW_REF:$NEW_DB_PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" -c "select jobid, schedule, command, active from cron.job order by jobid;"
  ```
  Çıktıda 2 aktif job, eski projedeki schedule/command değerleriyle birebir eşleşmeli.

---

## Task 7: Edge Functions'ları Deploy Et ve Secret'ları Kopyala

**Dosyalar:** `C:\yeedoy\supabase\functions\*` (mevcut, değiştirilmeyecek)

- [ ] Eski projedeki secret isimlerini listele (değerler görünmez, sadece isimler):
  ```bash
  supabase secrets list --project-ref dktdnbeougrmhkzplbap
  ```
- [ ] Her secret için gerçek değeri (bu değerler Supabase API'sinden okunamaz — kullanıcının kendi kayıtlarından: password manager, ilgili sağlayıcının kendi dashboard'u, veya `.env.local`/CI secret store'dan) yeni projeye ayarla:
  ```bash
  supabase secrets set --project-ref $NEW_REF \
    OPENROUTER_API_KEY="<değer>" \
    RESEND_API_KEY="<değer>" \
    [supabase secrets list çıktısındaki diğer her isim için tekrarla]
  ```
- [ ] 7 edge function'ı yeni projeye deploy et:
  ```bash
  supabase link --project-ref $NEW_REF
  supabase functions deploy anti-spam-guard
  supabase functions deploy write-gatekeeper
  supabase functions deploy verify-domain
  supabase functions deploy ai-allergen-detect
  supabase functions deploy ai-nutrition-estimate
  supabase functions deploy ai-menu-image-gen
  supabase functions deploy ai-menu-analyze
  ```
- [ ] Doğrula:
  ```bash
  supabase functions list --project-ref $NEW_REF
  ```
  7 fonksiyonun da `ACTIVE` durumda olduğunu doğrula.

---

## Task 8: Cutover Öncesi Kapsamlı Doğrulama

**Bu adıma kadar production hâlâ eski projeye bağlı — hiçbir kullanıcı etkilenmiyor.**

- [ ] Tüm satır sayısı karşılaştırmalarını (Task 3, Task 4) tekrar gözden geçir, hepsi ✅ olmalı.
- [ ] Yeni projeye karşı bir test ortamı kur: `uygulamalar/web/.env.local`'in bir kopyasını al (`.env.local.migration-test` gibi), içindeki `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY`'i yeni proje değerleriyle değiştir.
- [ ] Bu env dosyasıyla `pnpm run dev` başlat (`cp .env.local.migration-test .env.local` geçici olarak, test bitince eski `.env.local`'i geri koy — ya da `dotenv-cli` ile izole çalıştır).
- [ ] Manuel duman testi (yeni projeye karşı, lokalde):
  - [ ] Anasayfa açılıyor, işletmeler listeleniyor mu?
  - [ ] Bir işletme detay sayfası açılıyor mu (menü, saatler, dış kaynak verisi doğru görünüyor mu)?
  - [ ] Mevcut bir test kullanıcısıyla giriş yapılabiliyor mu?
  - [ ] Giriş yaptıktan sonra bir yorum yazılabiliyor mu?
  - [ ] Sahip paneline (varsa test kullanıcısı sahipse) giriş yapılıp bir işlem (ör. menü düzenleme) yapılabiliyor mu?
  - [ ] Admin paneline (varsa test kullanıcısı adminse) giriş yapılıp bir işlem yapılabiliyor mu?
  - [ ] Bir `menu-media` görseli doğru yükleniyor mu (Task 5'te taşınan dosyalardan)?
- [ ] Herhangi biri başarısız olursa **dur** — Task 2-7'ye dön, sorunu bul ve düzelt. Cutover'a geçme.

---

## Task 9: Cutover — Vercel ve Worker Env Var'larını Güncelle

**Yalnızca Task 8 tamamen ✅ olduktan sonra yapılır.**

- [ ] Vercel Dashboard → `yeedoy-webim` projesi → Settings → Environment Variables (Production):
  - `NEXT_PUBLIC_SUPABASE_URL` → `https://$NEW_REF.supabase.co`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY` → yeni proje anon key
  - `SUPABASE_SERVICE_ROLE_KEY` → yeni proje service_role key
- [ ] Worker `.env` güncelle (`D:\yeedoy-google-maps-coverage-v5\.env`):
  ```
  SUPABASE_DB_URL=postgresql://postgres.$NEW_REF:$NEW_DB_PASSWORD@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
  ```
- [ ] Mobil app `.env` güncelle (varsa, `uygulamalar/mobil/.env` — `SUPABASE_URL`, `SUPABASE_ANON_KEY`). **Not:** mobil app henüz store'a yeni build ile gönderilmediği sürece bu değişiklik canlı kullanıcıları etkilemez — acil değil, ama unutulmasın diye burada not edildi.
- [ ] Vercel'de yeni bir production deploy tetikle (env var değişikliği otomatik yeni deploy tetiklemez, mevcut deployment'ı redeploy et):
  - Vercel Dashboard → Deployments → en son production deployment → "Redeploy" (cache temizlenmeden).
- [ ] Deploy `READY` olana kadar bekle (~2-3 dakika, önceki oturumdaki build sürelerine göre).

---

## Task 10: Cutover Sonrası Canlı Doğrulama ve Eski Projeyi Bekletme

- [ ] `https://www.yeedoy.com` üzerinde Task 8'deki aynı duman testini tekrarla (bu sefer gerçek production'da).
- [ ] Vercel deployment loglarında (Runtime Logs) yeni Supabase projesine bağlandığını, hata olmadığını doğrula.
- [ ] pg_cron job'larının yeni projede zamanı geldiğinde gerçekten çalıştığını bir sonraki tetiklenme zamanında kontrol et (`cron.job_run_details` tablosu).
- [ ] Eski proje (`dktdnbeougrmhkzplbap`, Seul) **silinmez, pause edilmez** — en az birkaç gün canlı ve dokunulmamış halde bekletilir (rollback güvencesi). Bir sorun çıkarsa Task 9'daki env var'lar anında eski projeye geri çevrilebilir.
- [ ] Birkaç gün sorunsuz geçtikten sonra: `migration/` klasöründeki geçici dosyaları (`.dump` dosyaları, `storage_copy.mjs`) sil, eski projeyi Supabase Dashboard'dan pause et (silme, sadece pause — ekstra güvenlik).
- [ ] Bu plan dokümanındaki tüm checkbox'ları `[x]` olarak işaretle, commit et.

---

## Bilinen Riskler / Notlar

- **Edge function secret değerleri bende yok** — Task 7'de bu değerleri sağlamak kullanıcının sorumluluğunda (password manager veya ilgili sağlayıcı dashboard'undan).
- **`--disable-triggers` restore sırasında** RLS policy'lerini veya trigger'ları geçici olarak devre dışı bırakır — bu sadece restore işlemi sırasında güvenlidir (tek kullanıcı, tek session), production trafiği o sırada yeni projeye gitmediği için risk yok.
- **DB şifreleri asla git'e commit edilmemeli** — `migration/` klasöründeki hiçbir dosyada açık şifre/key bulunmamalı, sadece komutlar (değerler ortam değişkeni olarak elle girilir).
