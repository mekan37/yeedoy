# Yeedoy Commit Mesaj Kılavuzu

> Standart: [Conventional Commits](https://www.conventionalcommits.org/) + Türkçe
> Son güncelleme: 2026-05-23

Tüm Yeedoy commit'leri bu kılavuz izlemelidir. CI/CD pipeline'ları ve PR review'lar bu standardı kontrol eder.

---

## 1. Format

```
type(scope): açıklama [issue]

[opsiyonel body]

[opsiyonel footer]
```

### Başlık (Zorunlu)
- **Uzunluk:** 50 karakterden az (ideal)
- **Case:** lowercase
- **Nokta:** Sonunda nokta YOK
- **Type:** Aşağıdaki listeden biri
- **Scope:** Parantez içinde, değişim alanı
- **Açıklama:** Imperative mood, "fixed" değil "fix" yaz

### Body (Opsiyonel)
- Yalnızca non-obvious değişikliklerde yaz
- "Why" açıkla, "what" değil (kod zaten gösteriyor)
- 72 karakterde satır kır

### Footer (Opsiyonel)
- Breaking change açıklama
- Issue referansı: `Closes #123`

---

## 2. Type Listesi

| Type | Kullanım | Örnek |
|---|---|---|
| **feat** | Yeni özellik | `feat(mobile): discovery skeleton state ekle` |
| **fix** | Bug düzeltme | `fix(web): report csv auth bypass kapat` |
| **refactor** | Kod yeniden yapılandırması (davranış yok) | `refactor(mobile): review list state organize` |
| **perf** | Performans iyileştirmesi | `perf(mobile): favorites cache refresh optimize` |
| **test** | Test dosyası ekleme/güncelleme | `test(web): export handler coverage ekle` |
| **docs** | Dokümantasyon (kod değişikliği yok) | `docs: git workflow strategy kılavuzu` |
| **chore** | Build, dependency, config | `chore: packages-riverpod update to 3.1.0` |
| **ci** | CI/CD pipeline | `ci: mobile quality timeout 30 dk yap` |
| **build** | Build sistemi, bundler, Docker | `build: flutter release gate check script` |
| **security** | Güvenlik sorunu (CVE, auth, validation) | `security(web): user input sanitization` |
| **migration** | Supabase migration (veritabanı schema) | `migration(supabase): verified visit column ekle` |

---

## 3. Scope Listesi

**App'lar:**
- `mobile` — `uygulamalar/mobil`
- `web` — `uygulamalar/web`
- `personel` — `uygulamalar/personel`

**Backend:**
- `supabase` — SQL migrations, genel
- `edge` — `supabase/functions/**`

**Ortak:**
- `packages` — Herhangi bir package
- `l10n` — Çeviri dosyaları (ARB)

**DevOps:**
- `ci` — `.github/workflows`
- `docs` — Dokümantasyon
- `assets` — Resim, font, icon

**Kategori:**
- `security` — Güvenlik
- `performance` — Performans
- `api` — API schema
- `db` — Database
- `ui` — UI framework
- `auth` — Authentication/authorization

---

## 4. Örnekler

### Yeni Özellik

```
feat(mobile): discovery listesine skeleton state ekle

Skeleton shimmer effect, sayfa yüklenirken UX iyileştirmesi.
Riverpod async state başında gösterilir.

Closes #456
```

### Bug Düzeltme

```
fix(web): raporlar-csv endpoint auth kontrolü eksikliğini düzelt

is_admin RPC check yoktu; authenticated herkes 5000 satır
moderation CSV indirebiliyordu.

Risk: HIGH → CVSS 8.2

Testtir:
- Admin tarafından CSV: PASS
- Non-admin direkt URL: 403 FAIL (düzeltildi)

Closes #789
```

### Refactor

```
refactor(mobile): review list riverpod state organization

Nested AsyncValue.when çağrılarını dedicated builder'a taşıdı.
ReviewListSection ölçeğini ~150 LOC azalttı.
```

### Performans

```
perf(mobile): offline queue batch import optimization

Queue'dan veritabanına yazarken 100'lük batch'ler kullan.
Disk I/O 40% azaldı, import hızı 2.1x arttı.
```

### Chore

```
chore(packages): shared_ui_components token export güncelle

AppTokens.of(context) space token aralığını genişlet.
space3 (12px) eklendi; eski radius8 deprecated.
```

### Dokümantasyon

```
docs: git workflow strategy + commit message guide

PR template, issue template, commit format, branch naming.
Conventional Commits standardı uygulanmaya başladı.
```

### Güvenlik

```
security(edge): import_places auth header validation ekle

Bearer token'ı header'dan parse et, is_admin check ekle.
Tüm edge functions için uygulanabilir template sağlandı.
```

### Migration

```
migration(supabase): menu feedback table with RLS

New table: menu_feedback (id, menu_id, user_id, feedback_type, content)
RLS: anon INSERT, owner SELECT (kendi menülerine)
Index: menu_id, created_at

Rollback: DROP TABLE IF EXISTS menu_feedback CASCADE;

Etkilenen RPC yok (yeni tablo).

Closes #567
```

### Breaking Change

```
feat(api)!: response schema'da total_count zorunlu hale getir

BREAKING CHANGE: /api/items endpoint response'ında `total_count` 
artık zorunludur. Eski client'ler parse etmeden çöker.

Migration: Frontend'i 1 gün önce update et, sonra backend deploy.

Closes #890
```

### Çoklu Dil Karışık (Kabul Edilir)

```
fix(mobile): QR scanner focus lock issue — recursive build loop fix
```

---

## 5. Body Yazılması Gereken Durumlar

Body'yi aşağıdaki durumlarda yaz:

1. **Non-obvious karar:** Neden bu şekilde yapıldığını açıkla
   ```
   refactor: cache invalidation strategy
   
   Çıkış işleminde tüm cache'i temizle (evict all), 
   kısmi invalidation değil. Nedeni: partial invalidation 
   complex state machine'i gerektirir ve bug riskini arttırır.
   ```

2. **Bug'ın kök nedeni:** Başlangıç neden nedir?
   ```
   fix: auth token renewal retry logic
   
   Token expire olduğunda refresh endpoint yeniden deneme yapmaması:
   state.isRenewing flag'i asla unset olmuyordu.
   Nested AsyncValue.when içinde Riverpod invalidate() çağrısı 
   senkron değildir; yeni try/catch ekledik.
   ```

3. **RPC/RLS değişikliği:** Etkilenen caller'ları listele
   ```
   migration(supabase): get_business_reviews_v3 sort param
   
   New parameter: p_sort varchar = 'recent' 
   Options: 'recent', 'helpful', 'verified'
   
   Etkilenen callerlar:
   - mobile: lib/features/reviews/data/reviews_deposu.dart
   - web: src/lib/reviews.ts
   - personel: lib/features/reviews/data/reviews_deposu.dart
   
   Tüm callerlar update edildi (backward compat).
   ```

4. **Security fix:** Exploit vektörü kısaca açıkla (PII expose etme)
   ```
   security(web): sanitize error messages before client response
   
   API errors'daki database constraint messages (column names, 
   foreign key names) client'a leak oluyordu. Bu schema reverse 
   engineeri'ne yardımcı oluyor.
   
   Çözüm: Generic "Validation failed" message, logs'ta detail.
   ```

5. **Supabase migration:** Rollback komut'u
   ```
   migration(supabase): add verified_visit_badge
   
   New field: reviews.verified_visit (boolean, default false)
   New function: _review_verified_visit (SQL helper)
   
   Rollback:
   ALTER TABLE reviews DROP COLUMN IF EXISTS verified_visit;
   DROP FUNCTION IF EXISTS _review_verified_visit();
   ```

---

## 6. Body İçeriği Kuralları

**YAZMA (Açıkla):**
- Neden bu değişiklik yapıldı?
- Non-obvious teknik karar
- Etkilenen roller/callerlar
- Performance impact
- Breaking changes

**YAZMA (Ne değil, çünkü kod gösteriyor):**
- "Added new if statement" — Diff zaten gösterir
- "Changed variable name" — Git log --stat gösterir
- "Updated dependencies" — package.json diff gösterir

---

## 7. Issue Referansı

PR veya commit'te GitHub issue'yu referans et:

```
Closes #123
Resolves #456
Related to #789
Fixes #101
```

Kurallı adlandırma:
- `Closes` — Bu PR/commit bu issue'yu çözer
- `Resolves` — `Closes` ile aynı
- `Fixes` — Bug fix (security, critical)
- `Related to` — Bağlantılı ama doğrudan çözmez

---

## 8. Commit Mesajı Checklist

Commit'i git push'lamadan önce kontrol et:

- [ ] Type doğru mu? (feat/fix/refactor/etc)
- [ ] Scope parantez içinde mi? (lowercase)
- [ ] Açıklama imperative mood? ("add" değil "added")
- [ ] Açıklama 50 char altında (ideal)?
- [ ] Nokta yok mu sonunda?
- [ ] Breaking change varsa `BREAKING CHANGE:` footer'ında mı?
- [ ] Issue referansı varsa `Closes #XXX` footer'ında mı?
- [ ] Multi-line commit'in body'si 72 karakterde kırılmış mı?

---

## 9. Genel En İyi Uygulamalar

### Küçük, Fokuslu Commit'ler

```
✅ İyi:
feat(mobile): discovery sort options UI

fix(mobile): discovery sort cache invalidation

refactor(mobile): discovery provider reorganize
```

```
❌ Kötü:
feat: discovery page tamamı ve caching ve UI ve state
```

### Açık Commit Mesajları

```
✅ İyi:
fix(web): rate limit header parsing for millisecond values

✅ İyi (body ile):
fix(web): rate limit header parsing for millisecond values

Retry-After header millisecond bazında şu halde gelemez (HTTP spec),
fakat OpenAPI spec'inde geri dönüyor. Parse logic'ine fallback ekledik.
```

```
❌ Kötü:
fix: bug

❌ Kötü:
wip: stuff

❌ Kötü:
asdfgh: random change
```

### Breaking Changes'ı Açık Et

```
✅ İyi:
feat(api)!: total_count field zorunlu yap

BREAKING CHANGE: /api/items response'ı total_count olmadan gelmez.

❌ Kötü:
feat(api): total_count field zorunlu yap
(not indicating breaking change)
```

---

## 10. Automation

Bu kılavuz CI/CD tarafından desteklenir:

- **Husky pre-commit hook:** Commit mesajı doğrulaması (opsiyonel setup)
- **GitHub PR template:** PR açılınca reminder
- **CI validation:** `npm run lint:commits` (tarafı)

Manuel validation:

```bash
# Commit mesajını kontrol et
git log --oneline -5
```

---

## İlgili Belgeler

- [`docs/git-workflow-strategy.md`](./git-workflow-strategy.md) — Branch strategy, PR rules
- [Conventional Commits](https://www.conventionalcommits.org/) — Standart belge
- `README.md` — Repository genel yapısı

---

*Son güncelleme: 2026-05-23*
*Versiyon: 1.0*
*Dil: Türkçe + İngilizce*
