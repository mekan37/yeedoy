# Yeedoy Git Workflow Strategy

## 1. Executive Summary

Yeedoy monorepo, Flutter mobil (iOS/Android), Next.js web (public + admin + owner), ve Supabase backend (PostgreSQL + Edge Functions + Realtime) olmak üzere üç runtime katmanından oluşur. Version control stratejisi, bu karmaşık mimariyi koordine ederken kod kalitesini, birleştirme çatışmalarını az tutmak ve üretim dağıtımlarını hızlandırmayı hedefler. Trunk-based development (ana branch yapısı) GitHub Actions CI/CD otomasyonu ile birleştiğinde, risky değişikliklerin (database migration, auth, RLS, public route) ayrı PR'larda yönetilmesini sağlar.

> **Not (2026-06-24):** `uygulamalar/personel` Flutter uygulaması ürün kapsamından tamamen kaldırıldı. Bu dokümandaki Personel'e özgü branch/scope/CI referansları artık geçersizdir; sadece tarihsel bağlam için bırakılmıştır.

---

## 2. Branch Strategy

Yeedoy için önerilen branch stratejisi, feature branch'leri kısa ömürlü tutarak trunk-based development prensiplerine uyar. `develop` branch şu anda gerekli değildir; tüm çalışma `main` branch'i etrafında döner.

### Main Branch
- **Kuralı:** Her zaman deploy edilebilir durumda.
- **Erişim:** Doğrudan commit yasak. Sadece PR merge'leri kabul edilir.
- **PR gereksinimi:** Tüm CI kontrolleri pass edildikten sonra minimum 1 reviewer onayı zorunlu.
- **Merge stratejisi:** Squash merge (temiz history) veya fast-forward merge tercih edilir.

### Feature Branches
- **Adlandırma:** `feature/[surface]-[short-desc]`
- **Kaynağı:** `main` branch'i.
- **Ömrü:** 3-7 gün. Uzun PR'lar parçalanarak push edilmeli.
- **Erişim:** Açıldığında doğrudan push edilir, `upstream` seçeneği `-u` ile ayarlanır.
- **Silme:** Merge sonrası otomatik silinir.

### Hotfix Branches
- **Adlandırma:** `hotfix/[surface]-[issue]`
- **Kaynağı:** `main` branch'i.
- **Kullanım:** Acil prodüksiyon hataları. Test öncesi merge yapılmaz.
- **Merge hedefi:** Doğrudan `main` branch'ine.
- **PR:** HIGH risk olarak işaretlenir, yükseltilmiş review gerekir.

### Refactor Branches
- **Adlandırma:** `refactor/[surface]-[scope]`
- **Kuralı:** Davranış değiştirmeyen sadece kod yeniden yapılandırması.
- **Ömrü:** Feature branch'i gibi, fakat daha hızlı merge'lenir.
- **Örnek:** `refactor/mobile-state-management-cleanup`, `refactor/web-component-consolidation`

### Chore Branches
- **Adlandırma:** `chore/[scope]`
- **Kullanım:** Bağımlılık güncellemeleri, config değişiklikleri, tooling.
- **Örnek:** `chore/packages-update-riverpod`, `chore/dependencies-npm-update`

### Docs Branches
- **Adlandırma:** `docs/[doc-title]`
- **Kuralı:** Sadece dokümantasyon (.md) değişiklikleri. Kod değişikliği olmaz.
- **Test:** Genellikle test gerekmez; linkler manuel kontrol edilir.
- **Örnek:** `docs/git-workflow-strategy`, `docs/api-audit-update`

### Supabase Migration Branches
- **Adlandırma:** `migration/supabase-YYYYMMDD-[description]`
- **Kuralı:** SADECE migration dosyası(ları) değiştirilir. Frontend refactor ayrı PR'da.
- **Format:** Migration dosya adı `YYYYMMDD[order]_[description].sql` (mevcut konvensiyona uy).
- **Örnek:** `migration/supabase-20260524-rls-policy-cleanup`, `migration/supabase-20260525-add-verified-visit-column`

### Release Branches (Opsiyonel)
- **Adlandırma:** `release/[version]` (örn. `release/v2.5.0`)
- **Kaynağı:** `main` branch'i (büyük release öncesi).
- **Kullanım:** Sadece bug fix'ler. Yeni feature'lar değil.
- **Merge hedefi:** `main` branch'ine sonrasında `main` tag'lenir.
- **Şu anda:** Yeedoy için isteğe bağlı; CI otomasyonu yeterli.

---

## 3. Branch Naming Rules (Yeedoy'a Özel)

Yüzey (surface) türüne göre prefix standartları:

### Mobil (`uygulamalar/mobil`)
```
feature/mobile-[short-desc]
fix/mobile-[issue]
refactor/mobile-[scope]
perf/mobile-[optimization]
```
**Örnekler:**
- `feature/mobile-discovery-skeleton-state`
- `fix/mobile-qr-scan-camera-permission-crash`
- `refactor/mobile-review-list-riverpod-state`
- `perf/mobile-offline-queue-batch-optimization`

### Web (`uygulamalar/web`)
```
feature/web-[short-desc]
fix/web-[issue]
refactor/web-[scope]
perf/web-[optimization]
```
**Örnekler:**
- `feature/web-campaign-preview-builder`
- `fix/web-report-csv-auth-bypass`
- `refactor/web-admin-table-components-consolidation`
- `perf/web-menu-image-lazy-load`

### Supabase Migrations
```
migration/supabase-YYYYMMDD-[description]
```
**Örnekler:**
- `migration/supabase-20260524-add-menu-feedback-table`
- `migration/supabase-20260525-rls-ownership-tightening`

### Edge Functions
```
feature/edge-[function-name]-[desc]
fix/edge-[function-name]-[issue]
perf/edge-[function-name]-[optimization]
```
**Örnekler:**
- `fix/edge-import-places-auth-header-validation`
- `feature/edge-ai-menu-analyze-streaming-response`

### Ortak Packages
```
chore/packages-[package-name]-[change]
refactor/packages-[package-name]-[scope]
```
**Örnekler:**
- `chore/packages-shared-ui-tokens-export-fix`
- `refactor/packages-shared-models-riverpod-migration`

### Dokümantasyon
```
docs/[brief-title]
```
**Örnekler:**
- `docs/git-workflow-strategy`
- `docs/database-migration-guide`
- `docs/guvenlik-audit-summary`

### L10n / Translation
```
l10n/[language]-[scope]
```
**Örnekler:**
- `l10n/turkish-owner-panel-ui`
- `l10n/english-review-copy-update`

---

## 4. Commit Message Standard (Conventional Commits + TR)

### Format
```
type(scope): açıklama

[opsiyonel body]

[opsiyonel footer]
```

### Type Listesi
- **feat** — Yeni özellik
- **fix** — Bug düzeltme
- **refactor** — Davranış değiştirmeyen kod yeniden yapılandırması
- **perf** — Performans iyileştirmesi
- **test** — Test dosyası ekleme / güncelleme
- **docs** — Dokümantasyon değişikliği (kod değişikliği olmaz)
- **chore** — Build, dependency, config (değişiklik gerektiren)
- **ci** — CI/CD pipeline değişikliği
- **build** — Compile, bundler, Docker değişiklikleri
- **security** — Güvenlik sorunu düzeltme (CVE, auth, validation)
- **migration** — Supabase migration (özel, database schema değişikliği için)

### Scope Listesi
```
mobile, web, personel, supabase, edge, packages, l10n,
ci, docs, assets, security, performance, ui, api, db,
script, config
```

### Örnek Commit'ler (Türkçe)
```
feat(mobile): discovery listesine skeleton state ekle

fix(web): raporlar-csv endpoint auth kontrolü eksikliğini düzelt

refactor(supabase): N+1 verified_visit sorgusu satır içi EXISTS ile değiştirildi

chore(packages): shared_ui_components token export güncellendi

docs(api): edge function güvenlik audit raporu eklendi

perf(mobile): favorites cache refresh tekrarı azaltıldı

security(web): user input sanitization güvenlik açığı kapatıldı

ci(.github): mobile quality workflow timeout 15dk → 30dk

migration(supabase): rls-to-authenticated policy kısıtlaması
```

### Body Yazılırsa (Önemli Değişiklikler İçin)
```
fix(web): raporlar-csv endpoint auth kontrolü eksikliğini düzelt

is_admin RPC kontrolü eksikti; tüm authenticated kullanıcılar 5000
satır moderation CSV indirebiliyordu.

Etkilenen işlemler:
- Admin panel → Raporlar sayfası
- CSV download endpoint (public accessible)

Risk: HIGH → CVSS 8.2 (FIXED)

Testtir:
- Admin tarafından CSV indir: PASS
- Non-admin tarafından direkt URL: 403 FAIL (before fix)

Closes #1234
```

### Breaking Changes
```
feat(api): response schema'da total_count zorunlu hale getirildi

BREAKING CHANGE: /api/items endpoint response'ında `total_count` alan artık zorunludur.
Eski client'ler bu field'ı parse etmeden çöker.

Migration adımı: Client kodu update et.
```

### Türkçe + İngilizce Karışık (Kabul Edilir)
```
fix(mobile): QR scanner focus lock issue — recursive build loop düzeltildi
chore: Update Supabase Flutter client to ^2.5.0
```

### `@ ` Prefix (AI/Agent Commit'leri)

AI agent veya harici araç yardımıyla oluşturulan commit'ler başına `@ ` eklenir:

```
@ docs: SEO stratejisi — URL mimarisi, schema.org, sitemap
@ feat(mobile): discovery skeleton — AI paired session
```

Normal geliştirici commit'leri `@ ` almaz.

### Co-Authored-By Footer

AI yardımlı commit'lerde footer'a ekle:

```
Co-Authored-By: claude-flow <ruv@ruv.net>
```

---

## 5. Pull Request Rules

### PR Başlığı Formatı
```
type(scope): açıklama [PR NUMBER]
```

Başlık örnekleri:
- `feat(mobile): discovery list skeleton state #456`
- `fix(web): report csv auth bypass #457`
- `migration(supabase): add feedback table #458`

### PR Template (`.github/pull_request_template.md`)

Template `.github/pull_request_template.md` dosyasında mevcuttur. Mevcut (güncel) içeriği:

```markdown
## Özet
<!-- Ne değişti ve neden? 1-2 cümle -->

## Değişen Yüzeyler
<!-- Hangi app'ler ve modüller etkilendi? -->
- [ ] uygulamalar/mobil
- [ ] uygulamalar/web
- [ ] supabase/migrations
- [ ] supabase/functions
- [ ] packages/*
- [ ] .github/workflows
- [ ] docs/*

## Risk Seviyesi
<!-- LOW / MEDIUM / HIGH -->
**Risk:** 

**Gerekçe:** 

## Değişim Türü
- [ ] Yeni özellik (feature)
- [ ] Bug düzeltme (fix)
- [ ] Yeniden yapılandırma (refactor)
- [ ] Performans iyileştirmesi (perf)
- [ ] Test ekleme
- [ ] Dokümantasyon (docs-only)
- [ ] Bağımlılık güncellemesi (chore)

## Test Edilen Komutlar
```bash
# Örnek:
# cd uygulamalar/web && npm run typecheck && npm run lint
# cd uygulamalar/mobil && flutter analyze
```

## Test Edilmeyen Komutlar (Neden?)
<!-- Eğer birkaç kontrol yapılmadıysa açıkla -->

## Supabase Değişiklikleri
<!-- SADECE migration/edge function branch'leri için gerekli -->
- [ ] Yeni migration dosyası var (örn. `20260524000001_*.sql`)
- [ ] RPC signature değişti → etkilenen callerlar: 
- [ ] RLS policy değişti → etkilenen roller: 
- [ ] Yeni tablo/sütun eklendi → data migration gerekli mi?
- [ ] Edge Function auth değişti → test edildi mi?

## Davranış Değişiklikleri
- [ ] Public route davranışı değişti (SEO, cache, auth)
- [ ] Owner/admin panel davranışı değişti
- [ ] Auth/session akışı değişti
- [ ] API schema değişti (breaking?)

## Ekran Görüntüsü / Video
<!-- UI değişikliği varsa eklendi mi? Responsive test linki varsa ekle -->

## Rollback Planı
<!-- Bu PR'ı geri almak için ne yapılmalı? -->
Örnek:
- Migration: `supabase db reset` (lokal) veya `supabase migrations delete [version]`
- Code: `git revert` ve redeploy
- Config: restore `.env` veya previous deployment

## Checklist
- [ ] Commit mesajı conventional commit formatı (`type(scope): description`)
- [ ] Tests pass (CI logs gösteriliyor mu?)
- [ ] Hiç secret / API key / `.env` commit etmedim
- [ ] Generated dosya (`.next/`, `build/`, `.dart_tool/`) commit etmedim
- [ ] TypeScript / Dart code kalitesi kontrolleri pass
- [ ] L10n audit pass (eğer ARB dosyası değiştirdim)
- [ ] PR doğru branch'te mi? (`feature/*`, `fix/*`, `hotfix/*`, `migration/*`)

---

**İlgili Issue:** <!-- Closes #123 varsa yaz -->

**Ek Açıklamalar:**
<!-- Reviewer'lar için ekstra bağlam varsa yaz -->
```

### PR Review Süreci
1. **Author:** PR açmadan önce `git diff --stat` çıktısını kontrol et.
2. **CI:** Tüm otomatik kontroller pass olmalı.
3. **Reviewer:** MEDIUM/HIGH risk PR'lar >1 reviewer gerektirir.
4. **Supabase:** Migration PR'lar DBA/DevOps tarafından doğrulanmalı.
5. **Merge:** Squash merge (temiz history) tercih edilir.

### PR Merge Sonrası
- Branch otomatik silinir (GitHub Settings).
- PR commit history korunur (squash olsa da linked.

---

## 6. Validation Matrix

Hangi yüzey değiştiyse, hangi komutlar MUTLAKA çalışmalı:

| Yüzey | Zorunlu Kontroller | Opsiyonel | CI Gate? |
|---|---|---|---|
| `uygulamalar/mobil/**` | `flutter analyze` | `flutter test` | ✅ Yes |
| `uygulamalar/web/**` | `npm typecheck` + `npm lint` | `npm build`, `npm audit` | ✅ Yes |
| `supabase/migrations/**` | `supabase db push --local` | `supabase db diff` | ✅ Yes (manual) |
| `supabase/functions/**` | `supabase functions serve` (smoke) | `npm run build` | ✅ Yes (smoke) |
| `packages/shared_ui_components/**` | `flutter analyze` (mobil) | — | ✅ Yes |
| `packages/shared_models/**` | `flutter analyze` (mobil) | — | ✅ Yes |
| `packages/l10n_assets/**` | `npm run l10n:audit` | — | ✅ Yes |
| `.github/workflows/**` | YAML lint (local) | `workflow_dispatch` test | 🚧 No |
| `docs/**` | Link check (manual) | — | ❌ No |

### Çalıştırılması Gereken Komutlar (Surface Bazında)

**Flutter Mobil:**
```bash
cd uygulamalar/mobil
flutter pub get
flutter analyze
flutter test test
```

**Next.js Web:**
```bash
cd uygulamalar/web
npm ci
npm run typecheck
npm run lint
npm run test:unit
npx playwright install --with-deps chromium
npm run test:e2e
npm run build
npm audit --audit-level=high
```

**Supabase Migration (Local):**
```bash
cd supabase
supabase start
supabase db push --local
supabase db reset  # verify rollback
```

**L10n Audit (Repo Root):**
```bash
npm run l10n:audit
```

**Full Pre-Merge (Repo Root):**
```bash
npm run verify:matrix
```

---

## 7. Risky File Rules

Şu dosyalarda değişiklik varsa, PR otomatik MEDIUM veya HIGH risk kategorisine girer:

### HIGH RISK
Şu dosyalarda değişiklik → yükseltilmiş review gerekir, test zorunlu:

**Database & Auth:**
- `supabase/migrations/**` — Her migration geri alınamaz, prod schema değişikliği
- `supabase/functions/verify-domain/**` — Domain ownership validation
- `supabase/functions/write-gatekeeper/**` — Central write guard, auth enforcement
- `supabase/functions/anti-spam-guard/**` — Rate limiting, spam detection

**Backend Routes (Next.js):**
- `uygulamalar/web/app/*/route.ts` — API endpoint'leri
- `uygulamalar/web/src/lib/taban-sunucu.ts` — Base server utilities
- `uygulamalar/web/src/lib/oran-siniri.ts` — Rate limiting helpers
- `uygulamalar/web/src/lib/auth/**` — Auth logic

**RLS & RPC:**
- `supabase/migrations/**` — RLS policy'ler
- `supabase/functions/` — Service role key kullanan edge functions
- `supabase/` — is_admin, is_owner_of_business RPC helper'ları

**CI/CD Pipeline:**
- `.github/workflows/**` — CI/CD tetikleyici ve gating
- `scripts/release-smoke.sh` — Release automation

### MEDIUM RISK
- `package.json`, `pubspec.yaml` — Bağımlılık versiyonu
- `packages/shared_models/**` — Tüm Flutter app'ları etkiler
- `packages/shared_ui_components/**` — Tüm Flutter app'ları etkiler
- `uygulamalar/web/.env.example` — Public config
- `packages/l10n_assets/**` — Tüm language file'ları

### LOW RISK (Hızlı merge)
- `docs/**` — Sadece dokümantasyon
- `README.md`, `AGENTS.md`, `STYLE.md` — Sadece referans
- `.gitignore` güncellemeleri
- Yorum ve linting düzeltmeleri (davranış değişikliği yok)

---

## 8. Supabase Migration Workflow

### Güvenli Migration Akışı

#### Adım 1: Branch Aç
```bash
git checkout main
git pull
git checkout -b migration/supabase-20260524-feature-name
```

#### Adım 2: Migration Dosyası Oluştur
Dosya formatı: `supabase/migrations/YYYYMMDD[order]_description.sql`

Örnek: `supabase/migrations/20260524000001_add_menu_feedback_table.sql`

```sql
-- Migration: Add menu feedback table (20260524000001)
-- Rollback: DROP TABLE IF EXISTS menu_feedback CASCADE;

CREATE TABLE IF NOT EXISTS menu_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  menu_id UUID NOT NULL REFERENCES menus (id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users (id) ON DELETE SET NULL,
  feedback_type TEXT NOT NULL CHECK (feedback_type IN ('bug', 'feature', 'content')),
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS Policies
ALTER TABLE menu_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon can insert feedback" ON menu_feedback
  FOR INSERT TO anon
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "users can view feedback on their menus" ON menu_feedback
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM menus m
      WHERE m.id = menu_feedback.menu_id
        AND m.business_id = (SELECT business_id FROM is_owner_of_business(auth.uid()))
    )
  );

-- Index for performance
CREATE INDEX idx_menu_feedback_menu_id ON menu_feedback (menu_id);
CREATE INDEX idx_menu_feedback_created_at ON menu_feedback (created_at DESC);
```

#### Adım 3: SQL Doğrulama

Local test:
```bash
cd supabase
supabase start  # Docker Desktop running?
supabase db push --local
```

Rollback test:
```bash
supabase db reset  # Tüm migration'ları replay et
```

Diff kontrol:
```bash
supabase db diff  # Beklenmeyen değişiklik var mı?
```

#### Adım 4: Etkilenen Caller'ları Listele

Migration RPC signature değişiyorsa, tüm callerları grep ile bul:

```bash
cd uygulamalar/mobil
grep -r "get_business_reviews" lib/ --include="*.dart"

cd ../web
grep -r "get_business_reviews" . --include="*.ts" --include="*.tsx"
```

#### Adım 5: PR Açmadan Önce RLS Doğrula

RLS policy'ler test edildi mi?

- `SELECT` — Doğru role'ler okuyabilir?
- `INSERT` — Doğru role'ler ekleyebilir?
- `UPDATE` — Doğru role'ler güncelleyebilir?
- `DELETE` — Doğru role'ler silebilir?

#### Adım 6: PR Açma (Migration Branş'i)

```bash
git add supabase/migrations/20260524000001_add_menu_feedback_table.sql
git commit -m "migration(supabase): add menu feedback table with RLS"
git push -u origin migration/supabase-20260524-add-menu-feedback-table
gh pr create --title "migration(supabase): add menu feedback table" \
  --body "..."
```

PR body'de:
- Migration file path
- RPC signature değişiyorsa affected callers listesi
- RLS policy açıklaması
- Rollback komutu

#### Adım 7: Reviewer Kontrolü

Reviewer (@mekan37 vb) şunları kontrol eder:
- SQL sözdizimi doğru?
- RLS policy'ler tight? (minimal access)
- Performans endeksleri eklenmiş?
- Eski data migration gerekli?

#### Adım 8: Merge & Deploy

```bash
# Local final test
supabase db reset
supabase db push --local

# Merge to main
git checkout main
git pull
git merge migration/supabase-20260524-add-menu-feedback-table
git push

# Remote apply (production — manual step)
# Use Supabase dashboard or CLI with service role:
# supabase db push --project-ref <prod-ref>
```

### Migration Anti-Patterns (YAPMA)

1. **Migration dosyasını birden çok kez değiştirme** — İdempotent başarısız olabilir
2. **Migration'ı push ettikten sonra frontend refactor aynı PR'da** — İki ayrı PR
3. **Eski callerları update etmeden signature değiştirme** — Breaking change
4. **RLS olmadan yeni tablo oluşturma** — DEFAULT IS PERMISSIVE
5. **Non-idempotent SQL** — `CREATE TABLE` yerine `CREATE TABLE IF NOT EXISTS` yaz

---

## 9. Edge Function Workflow

### Geliştirme Adımları

#### Adım 1: Branch Aç
```bash
git checkout main
git pull
git checkout -b fix/edge-import-places-auth-validation
```

#### Adım 2: Function Kod'u Yaz/Düzenle
```typescript
// supabase/functions/import_places_json/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";

serve(async (req: Request) => {
  // 1. Auth check
  const token = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!token) return new Response("Unauthorized", { status: 401 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) return new Response("Invalid token", { status: 401 });

  // 2. Permission check
  if (!(await isAdmin(user.id))) {
    return new Response("Forbidden", { status: 403 });
  }

  // 3. Rate limiting check
  const rateLimitOk = await checkRateLimit(user.id, "import_places");
  if (!rateLimitOk) {
    return new Response("Rate limit exceeded", { status: 429 });
  }

  // 4. Main logic
  const { file_url } = await req.json();
  // ... import places from JSON

  return new Response("OK", { status: 200 });
});
```

#### Adım 3: Local Test
```bash
cd supabase
supabase functions serve --env-file .env.local
```

Smoke test curl:
```bash
curl -X POST http://localhost:54321/functions/v1/import_places_json \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"file_url": "https://..."}'
```

#### Adım 4: Güvenlik Kontrolleri
- [ ] Token validation (Bearer)
- [ ] Auth check (getUser)
- [ ] Permission check (role-based)
- [ ] Rate limiting check
- [ ] Input validation (zod/schema)
- [ ] SQL injection check (parameterized queries)
- [ ] XSS check (no inline HTML)
- [ ] CORS headers (if needed)

#### Adım 5: Commit & Push
```bash
git add supabase/functions/import_places_json/index.ts
git commit -m "fix(edge): import_places auth header validation"
git push -u origin fix/edge-import-places-auth-validation
gh pr create --title "fix(edge): import_places auth header validation"
```

#### Adım 6: Deploy to Production
```bash
supabase functions deploy import_places_json --project-ref <prod-ref>

# Verify
supabase functions list --project-ref <prod-ref>
```

### Edge Function Anti-Patterns (YAPMA)

1. **Service role key hardcoded** — Env variable'dan oku
2. **Rate limit check'i skip etme** — Abuse riski
3. **Auth validation olmadan write operation** — Public veri tahrip
4. **Super long timeout** — 60s default, 600s max
5. **Unhandled promise rejection** — Try/catch her yerde
6. **Logging sensitive data** — PII/token'ları loglama

---

## 10. AI Agent Git Rules

Claude / Codex / LLM agent'leri için bağlayıcı kurallar:

1. **Main'e doğrudan commit yasak.** Her iş feature branch'inde yapılmalı.
   - Kontrol: `git status` → `On branch main` ise uyarı ver.

2. **Docs önce, kod sonra.** Büyük değişiklikler (>50 dosya, >1000 satır) öncesi `docs/` raporu üret.
   - Raporlar: ADR, API audit, security scan vb.

3. **Küçük commit'ler.** Her safe-fix kendi commit'inde.
   - Yasak: `fix: fixed everything` (100 dosya birlikte)
   - Doğru: `fix: auth check`, `refactor: state`, `perf: cache` (ayrı commit'ler)

4. **Ayrı PR zorunluluğu:** Şu işler MUTLAKA separate branch + PR:
   - Supabase migration
   - RLS policy değişikliği
   - Auth/session flow değişikliği
   - Public route behavior değişikliği
   - API schema breaking change

5. **Commit öncesi diff özeti.** Agent `git diff --stat` çıktısını kullanıcıya göstermeli.
   - Risk: HIGH mi? Reviewer warning yap.

6. **Silmeden önce kanıt.** Dosya silinmeden önce "bu dosyaya başka yerden referans var mı?" grep ile kanıtla.
   - Komut: `grep -r "deleted_file.dart" . --include="*.dart"`

7. **Generated dosya commit yasak:**
   - `.next/`, `build/`, `dist/`, `.dart_tool/`, `coverage/`
   - Aksiyon: Kontrol et, `.gitignore`'a ekle.

8. **Secrets commit yasak.** MUTLAK KURAL.
   - Yasak: `.env`, `*.pem`, `*.key`, API key'ler, token'lar, password'lar
   - Aksiyon: Eğer commit edilirse, `git reset --soft HEAD~1` ve `.gitignore` update et.

9. **Force push yasak.** Main'e asla `push --force`.
   - Alternative: `git revert` ile yeni commit.

10. **--no-verify yasak.** Hook'ları atlamak yasak.
    - Hook hata veriyorsa: root cause fix et, re-stage, new commit.

11. **Monorepo workspace'i kırma.** npm workspaces, Flutter pub integrity.
    - Kontrol: `npm install` sonrası lock file değişimi minimal mi?

---

## 11. Daily Git Commands (Windows PowerShell)

Yeedoy projesi için günlük Git işlemleri (Windows 11 Pro + PowerShell):

### Branch ve Remote Durumunu Kontrol
```powershell
cd C:\yeedoy
git status
git branch -a
git remote -v
```

### Yeni Feature Branch Açma
```powershell
git checkout main
git pull
git checkout -b feature/web-dashboard-redesign
```

### Değişiklik Kontrolü
```powershell
git status
git diff --stat              # Ne kaç satır değişti?
git diff                     # Detaylı diff
git log --oneline -5         # Son 5 commit
```

### Belirli Dosyaları Stage'lemek (Güvenli Yol)
```powershell
# Single file
git add uygulamalar/web/app/dashboard/page.tsx

# Multiple specific files
git add uygulamalar/web/src/lib/dashboard.ts
git add uygulamalar/web/src/ui/dashboard-chart.tsx

# Tüm workspace'i YAPMA — risky
# git add .
```

### Commit Etme
```powershell
git commit -m "feat(web): dashboard redesign with new analytics"

# Veya multi-line (important changes)
git commit -m "feat(web): dashboard redesign with new analytics

- Added real-time metrics widget
- Integrated TanStack Query for server state
- Added dark mode support
- Refactored chart components

Fixes #1234"
```

### Push ve PR Açma
```powershell
git push -u origin feature/web-dashboard-redesign

# PR'ı GitHub CLI ile aç
gh pr create --title "feat(web): dashboard redesign" `
  --body "Redesigned owner dashboard with new analytics. Includes chart components, real-time metrics, dark mode support."
```

### Main'e Dönme ve Cleanup
```powershell
git checkout main
git pull

# Merge sonrası branch silme (local)
git branch -d feature/web-dashboard-redesign

# Remote branch silme
git push origin --delete feature/web-dashboard-redesign
```

### Son N Commit Görüntüleme
```powershell
git log --oneline -10         # Son 10 commit
git log --oneline --grep="mobile"  # Mobil commit'leri
```

### Belirli Dosyanın Geçmişi
```powershell
git log --oneline -- uygulamalar/web/app/dashboard/page.tsx

git log -p -- supabase/migrations/20260524000001_*.sql  # Detaylı değişiklik
```

### Unstaging
```powershell
git restore --staged uygulamalar/web/app/dashboard/page.tsx  # Stage'den çıkar
git restore uygulamalar/web/app/dashboard/page.tsx          # Diskten restore et
```

### Branch Bilgisi
```powershell
git branch -v              # Local branch'leri versiyonla
git branch -a              # Tüm branch'ler (local + remote)
git branch -d feature/...  # Branch sil (merged olmalı)
git branch -D feature/...  # Force delete (merged olmasa da)
```

### Merge ve Rebase (Opsiyonel)
```powershell
# Feature branch'i main'e merge et
git checkout main
git pull
git merge --squash feature/web-dashboard-redesign
git commit -m "feat(web): dashboard redesign"

# Veya rebase (linear history)
git checkout feature/web-dashboard-redesign
git rebase main
git push --force-with-lease origin feature/web-dashboard-redesign
```

---

## 12. Recovery Playbook

Git işlemlerinde hatalar için adım adım kurtarma planları:

### Senaryo A: Henüz Commit Edilmemiş Değişikliği Geri Al

```powershell
# Tek dosyayı restore et
git restore uygulamalar/web/app/page.tsx

# Tüm değişiklikleri geri al (DİKKAT: GERI ALINAMAZ)
git restore .
```

**Risk:** LOW. Commit edilmediğinden, git tarihinde kayıp yoktur.

### Senaryo B: Stage'lenmiş Dosyayı Unstage Et (Değişiklik Korunur)

```powershell
git restore --staged uygulamalar/web/app/page.tsx

# Kontrol et
git status  # Modified but not staged
```

**Risk:** LOW. Değişiklikler disk'te kalır, undo edilebilir.

### Senaryo C: Hatalı Commit'i Geri Al (Push Yapılmadıysa)

```powershell
# Soft reset: Commit'i geri al, değişiklikleri staged tut
git reset --soft HEAD~1

# Hard reset: Commit'i ve değişiklikleri geri al (DİKKAT)
git reset --hard HEAD~1
```

**Risk:** SOFT = LOW, HARD = MEDIUM (git reflog ile kurtarılabilir)

**Kurtarma (Hard Reset sonrası):**
```powershell
git reflog              # Tüm HEAD hareketleri
git reset --hard <sha>  # Önceki commit'e geri dön
```

### Senaryo D: Yanlışlıkla Eklenen Dosyayı İzlemden Çıkar

```powershell
# Git'ten kaldır, disk'te bırak
git rm --cached .env

# .gitignore'a ekle
echo ".env" >> .gitignore

# Commit et
git add .gitignore
git commit -m "chore: ignore .env file"
```

**Risk:** LOW (henüz push yapılmadıysa).

### Senaryo E: Kaybolmuş Commit'i Bul (Reflog)

```powershell
git reflog                           # Tüm git işlemleri
# Örnek çıktı:
# 12a3b4c (HEAD -> main) commit: fix: auth
# 9z8y7x6 checkout: moving to main
# ...

git show 12a3b4c                     # O commit'i göster
git checkout -b recovery/fix-12a3b4c 12a3b4c  # Recovery branch'i aç
```

**Risk:** LOW. Commit geri alınabilir.

### Senaryo F: AI Değişikliğini Tamamen Geri Al

```powershell
# Option 1: Commit öncesi (push edilmemişse)
git reset --hard HEAD~5  # Son 5 commit'i geri al

# Option 2: Commit sonrası, push öncesi
git revert <sha>  # O commit'i geri alan yeni commit oluştur

# Option 3: Push sonrası (production'da)
git revert <sha>  # Yeni commit ile geri al
git push origin main
```

**Risk:** Option 1 = HIGH, Option 2 = MEDIUM, Option 3 = LOW (reversible)

### Senaryo G: Main'e Yanlışlıkla Commit Atıldı

```powershell
# Push öncesi kurtarma
git reset --soft HEAD~1    # Commit'i geri al, değişiklikleri staged tut
git stash                  # Veya değişiklikleri sakla

# Doğru branch'i aç
git checkout -b fix/my-feature
git stash pop              # Değişiklikleri getir
git commit -m "fix(...): ..."
git push -u origin fix/my-feature

# Main'i kontrol et (commit yok artık)
git checkout main
git log --oneline -1
```

**Risk:** LOW (reflog ile kurtarılabilir)

### Senaryo H: Merge Çatışması Çözmek

```powershell
# Merge başlat
git merge feature/new-feature

# Çatışma algılanırsa:
git status  # Conflicted files listelenir

# Manual düzeltme
# VS Code'da çatışmayı düzelt

git add <fixed-file>
git commit -m "Merge resolved: feature/new-feature"
```

**Risk:** MEDIUM. Yanlış çatışma çözümü logic hatası yaratabilir.

### Senaryo I: Force Push Karışıklığı (YAPMA, Ama Olursa)

```powershell
# Push --force YAPMA, ancak olmuşsa:

# Kurtarma (sadece sen yaptıysan ve henüz başkası pull etmediyse)
git push --force-with-lease origin main  # Safer alternative

# Veya local olarak kurtarma
git reset --hard origin/main  # Remote'u al (eğer force push'lanmışsa)
```

**Risk:** CRITICAL. Shared history bozulur. Tüm team'e uyar.

### Senaryo J: Git Tanımlanmadı (Yeni Kurulum)

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Kontrol et
git config --list | grep user
```

**Risk:** LOW. Commit'leri düzeltmek için `git commit --amend` ve force-push (SADECE unpushed commits).

---

## 13. .gitignore Checklist

Mevcut `.gitignore` analizi ve eksiklik kontrolü:

### Tarafından Takip Edilmemesi Gereken (IGNORE edilmeli)

**Build & Cache:**
- `node_modules/` ✅ Var
- `.next/` ✅ Var
- `dist/` ✅ Var
- `build/` ✅ Var
- `coverage/` ✅ Var
- `.dart_tool/` ✅ Var
- `.flutter-plugins` ✅ Var
- `android/app/build/` ✅ Var
- `ios/Pods/` ✅ Var

**Environment & Secrets:**
- `.env` ✅ Var
- `.env.*` ✅ Var (local files)
- `*.pem`, `*.key`, `*.p12` ✅ Var (implicit)
- `supabase/.env.local` ✅ Var

**Logs & Temp:**
- `*.log` ✅ Var
- Supabase temp: `supabase/.temp/` ✅ Var
- Agent temp: `.claude/`, `.swarm/`, `.codex/` ✅ Var

**AI/Tool State:**
- `agentdb.db`, `agentdb.rvf` ✅ Var
- `.mcp.json` ✅ Var

### Tarafından MUTLAKA Takip Edilmesi Gereken (IGNORE edilmemeli)

**App Assets:**
- `uygulamalar/*/assets/**` ✅ Tracked
- `packages/l10n_assets/lib/**` ✅ Tracked (ARB dosyaları)

**Supabase:**
- `supabase/migrations/**` ✅ Tracked
- `supabase/functions/**` ✅ Tracked

**CI/CD:**
- `.github/**` ✅ Tracked
- `scripts/**` ✅ Tracked

**Web Public:**
- `uygulamalar/web/public/**` ✅ Tracked

### Mevcut .gitignore Analizi (C:\yeedoy\.gitignore)

Dosya detaylı kontrol edildi:
- ✅ `node_modules/` → ignored (correct)
- ✅ `.next/` → ignored (correct)
- ✅ `.dart_tool/` → ignored (correct)
- ✅ `supabase/.temp/` → ignored (correct)
- ✅ `.env` → ignored (correct)
- ✅ `agentdb.*` → ignored (correct)

**Sonuç:** .gitignore güvenli ve yeterli. Eklemeye ihtiyaç yok.

---

## 14. Recommended Next Steps

Yeedoy Git workflow stratejisinin etkin kullanımı için sırasıyla yapılacaklar:

### Adım 1: PR Template Oluştur (İmmediate)

> ✅ **TAMAMLANDI** — `.github/pull_request_template.md` mevcut ve güncel (2026-06-02 kontrol edildi).
> Template içeriği Section 5'te tanımlanan formata uygun.

### Adım 2: .gitignore Doğrulaması (1 gün)

> ✅ **TAMAMLANDI** — `.gitignore` yeterli ve kapsamlı.

Mevcut `.gitignore` şu öğeleri kontrol ediyor:
- Build artifacts (`.next/`, `build/`, `.dart_tool/`)
- Dependencies (`node_modules/`, `.pub-cache/`)
- Secrets (`.env`, `*.pem`, config files)
- OS files (`.DS_Store`, `Thumbs.db`)
- IDE cache (`.vscode/`, `.idea/`)

İlave yapılması gereken yok.

### Adım 3: Branch Protection Rule'ları Ayarla (GitHub)

> ✅ **TAMAMLANDI** — `gh` CLI ile uygulandı (2026-06-02). Repo public yapıldı. Kurallar: 1 reviewer zorunlu, stale review dismiss, flutter-analyze + web-typecheck-lint status checks, force push/deletion kapalı, enforce_admins aktif.

URL: `https://github.com/mekan37/yeedoy/settings/branches`

#### Otomatik Kurulum (GitHub CLI)

Sistem üzerinde `gh` kurulu ise (ve kimlik doğrulanmış ise: `gh auth login`), aşağıdaki komutu çalıştır:

**Bash/PowerShell:**
```bash
# /c/yeedoy klasöründe çalıştır
cd /c/yeedoy

# Branch protection rules'ı uygula
gh api repos/mekan37/yeedoy/branches/main/protection \
  --method PUT \
  --field 'required_status_checks={"strict":true,"contexts":["mobile_quality / flutter-analyze","web_quality / typecheck","web_quality / lint"]}' \
  --field enforce_admins=false \
  --field 'required_pull_request_reviews={"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field dismiss_stale_reviews=true \
  --field auto_delete_head_branch=true
```

**PowerShell (alternatif):**
```powershell
cd C:\yeedoy

gh api repos/mekan37/yeedoy/branches/main/protection `
  --method PUT `
  --field 'required_status_checks={"strict":true,"contexts":["mobile_quality / flutter-analyze","web_quality / typecheck","web_quality / lint"]}' `
  --field enforce_admins=false `
  --field 'required_pull_request_reviews={"required_approving_review_count":1,"dismiss_stale_reviews":true}' `
  --field restrictions=null `
  --field allow_force_pushes=false `
  --field allow_deletions=false `
  --field dismiss_stale_reviews=true `
  --field auto_delete_head_branch=true
```

**Doğrulama:** Kurulum başarılı olursa, aşağıdaki komut korunan branch'i gösterecektir:
```bash
gh api repos/mekan37/yeedoy/branches/main/protection
```

#### Manuel Kurulum (GitHub UI)

GitHub web arayüzünü kullanarak:
1. `https://github.com/mekan37/yeedoy/settings/branches` URL'sine git
2. "Add branch protection rule" tıkla
3. Branch adı: `main`
4. Şu ayarları etkinleştir:

| Ayar | Durum |
|---|---|
| Require pull request reviews before merging | ✅ Enable, 1 reviewer |
| Dismiss stale pull request approvals | ✅ Enable |
| Require status checks to pass | ✅ Enable, "strict" |
| Status checks: `mobile_quality / flutter-analyze` | ✅ Select |
| Status checks: `web_quality / typecheck` | ✅ Select |
| Status checks: `web_quality / lint` | ✅ Select |
| Require branches to be up to date | ✅ Enable |
| Require code reviews from code owners | ❌ (Opsiyonel, varsa CODEOWNERS) |
| Allow force pushes | ❌ Disable |
| Allow deletions | ❌ Disable |
| Auto delete head branches | ✅ Enable |

5. "Create" tıkla.

**Sonrası:** `main` branch'e doğrudan push yapılamayacak, tüm değişiklikler PR üzerinden ve tüm kontroller pass olduktan sonra merge edilebilecektir.

**Kurulum Tarih:** Bekliyor (manual veya CLI kurulum gerekli)

### Adım 4: CI Validation Kurulumu (Var, Kontrol)

> ✅ **TAMAMLANDI** — Tüm workflow'lar aktif ve doğru şekilde çalışıyor (2026-06-02 kontrol edildi).

Mevcut aktif workflow'lar:

| Workflow | Amaç | Trigger | Durum |
|---|---|---|---|
| `mobile_quality.yml` | Flutter mobil analiz + test | PR, push to main | ✅ Active |
| `web_quality.yml` | Next.js typecheck + lint | PR, push to main | ✅ Active |
| `personel_quality.yml` | Flutter personel analiz | PR, push to main | ✅ Active (2026-05-25) |
| `packages_quality.yml` | Shared packages analiz | PR, push to main | ✅ Active (2026-05-25) |
| `edge_function_smoke.yml` | Edge functions smoke test | PR migrations, push to main | ✅ Active (2026-05-25) |
| `web_release_smoke.yml` | Web full build + test | Manual dispatch | ✅ Manual (release öncesi) |
| `mobile_readiness.yml` | Mobile release readiness | Manual dispatch | ✅ Manual (release öncesi) |

**Check adları** (branch protection için gerekli — gerçek check-run isimleri, 2026-06-08 doğrulandı):
- `web_quality`
- `mobile_quality`
- `personel_quality`

> ⚠️ **Not (2026-06-08):** Yukarıdaki üç madde önceden `mobile_quality / flutter-analyze`,
> `web_quality / typecheck`, `web_quality / lint` ve sonra `Web Quality / web_quality` gibi
> bileşik "Workflow Adı / Job Adı" formatlarıyla yazılmıştı. Workflow dosyalarında job'lara
> ayrı bir `name:` verilmediği için GitHub Actions check-run'ları sade job id ile raporluyor
> (`web_quality`, `mobile_quality`, `personel_quality` — workflow adı prefix'i yok). Bu
> mismatch yüzünden CI gerçekte PASS olsa bile PR'lar `mergeStateStatus: BLOCKED` kalıyor ve
> admin bypass (`gh pr merge --admin`) gerekiyordu (bkz. PR #87, #88). Required status check
> context listesi `gh api .../protection/required_status_checks --method PATCH` ile gerçek
> check-run isimlerine güncellendi; diğer branch protection ayarları (enforce_admins,
> force-push/deletion koruması, required reviews) değişmedi.

Bu adımlar Adım 3 (Branch Protection) ayarlanırken kullanılacaktır.

### Adım 5: İlk Feature'ı Pratik Yap (1 hafta)

> ✅ **TAMAMLANDI** — Test PR #1 açıldı, branch protection doğrulandı (2026-06-02). `personel_quality` ✅ `web_quality` ✅ zorunlu check'ler çalışıyor. PR closed without merge.

Feature-branch modeli pratiğe koyma:

```powershell
cd C:\yeedoy

# Main'i güncelle
git checkout main
git pull origin main

# Feature branch'i aç
git checkout -b feature/web-[feature-adı]

# Değişiklik yap, commit et (conventional format)
git add .
git commit -m "feat(web): [açıklama]"

# Push et
git push -u origin feature/web-[feature-adı]

# PR aç (GitHub UI veya CLI)
gh pr create --title "feat(web): [kısa açıklama]"
```

İş akışı:
1. CI tüm kontroller pass olana kadar dene
2. Reviewer onayını al (Adım 3'ten sonra zorunlu)
3. "Squash and merge" ile temiz history tut
4. Feature branch otomatik silinir

**Hedef:** 3-5 gün içinde merge edilmiş ilk feature

### Recommended Default Branch Model

**Yeedoy için önerilen model:** Trunk-Based Development (TBD) + GitHub Flow

- **Main:** Deployment-ready, protected
- **Feature branches:** Kısa ömürlü (3-7 gün), `main` source
- **No develop:** Şu an gerekli değil
- **Release:** Tag + CI otomasyonu (release-smoke manual)

### Ayrı PR Olması MUTLAKA Gereken İşler

Her şu işlem kendi feature branch + PR'da yapılmalı:

1. **Supabase migration** → `migration/supabase-*` branch
2. **RLS policy değişikliği** → migration branch + reviewer (DBA)
3. **Auth/session flow değişikliği** → `feature/[app]-auth-*` + reviewer
4. **Public route behavior değişikliği** → `feature/web-public-*` + reviewer
5. **API schema breaking change** → `feature/api-*` + versioning plan
6. **Bağımlılık update (major)** → `chore/packages-update-*` ayrı test
7. **Shared package değişikliği** → `chore/packages-[name]-*` tüm app'ler test

### Claude/Codex İçin Güvenli Çalışma Kuralı

Agent başlamadan:
```
1. git status → main mi? Uyarı ver.
2. Büyük değişiklik mi (>50 dosya)? Önce RFC/ADR doc yaz.
3. Migration/Auth/RLS değişikliği mi? Ayrı branch + PR öner.
4. git diff --stat çıktısını göster, risk level warn.
5. Commit öncesi grep kanıtı (silme operasyonu için).
6. Secret check: .env, *.pem, API key scan.
```

### Başarı Metrikleri (4 Hafta Sonrası)

Target KPI'lar:

| Metrik | Target | Measurement |
|---|---|---|
| PR review time | <4 hours | GitHub API `time_to_review` |
| Merge conflict rate | <5% | `git log --merges` analysis |
| Commit message quality | >95% conventional | Manual spot check |
| Test pass rate | 100% | CI logs |
| Main branch uptime | 100% | Deployment tracking |
| Rollback incidents | <1/month | Release notes |

### Genel En İyi Uygulamalar (Özet)

1. **Branch'i hep güncelle:** `git pull` merge öncesi
2. **Commit mesajı açık:** `feat(scope): description`
3. **Küçük PR'lar:** 200 satır altı ideal
4. **Kod review'ı ciddiye al:** Comment'leri tartış
5. **Test et:** Lokal CI geçtikten sonra push et
6. **Secret'i commit etme:** .env, key dosyaları kontrol et
7. **Force push yapma:** Main'e hiçbir zaman
8. **Migration test et:** `supabase db reset` sonrası replay
9. **Hook'ları bypass etme:** Hata düzelt, re-stage et
10. **Dokümantasyon yapıştır:** Büyük değişiklik → ADR/RFC doc

---

## İlgili Belgeler

- `README.md` — Repository genel yapısı
- `AGENTS.md` — Mimari kurallar
- `CLAUDE.md` — Claude workflow kuralları
- `STYLE.md` — Kod stili rehberi
- `.github/pull_request_template.md` — PR template (create)
- `.github/workflows/*.yml` — CI/CD pipeline tanımları

---

*Son güncelleme: 2026-06-02*
*Versiyon: 1.1*
*Yazar: Git Workflow Manager*
