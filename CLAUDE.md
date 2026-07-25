# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Ürün Kapsamı Uyarısı:** Güncel ürün kapsamı için sadece `docs/product/2026-yeedoy-final-scope-source-of-truth.md` baz alınacak. `docs/research` ve `docs/engineering` içindeki eski raporlar tarihsel bağlamdır, tek başına karar kaynağı değildir.

## Repository Structure

Yeedoy is a monorepo with two active Flutter/Next.js apps backed by Supabase:

| App | Path | Purpose |
|-----|------|---------|
| Mobile | `uygulamalar/mobil/` | End-user Flutter app (Android/iOS) |
| Web | `uygulamalar/web/` | Next.js 15 — public menu, QR, owner & admin panels |

Shared packages (Dart/Flutter):
- `packages/shared_models/` — canonical domain models
- `packages/shared_ui_components/` — shared Flutter primitives
- `packages/l10n_assets/` — common ARB strings (TR+EN)
- `packages/ui_tokens/` — design tokens (CSS + JSON; web mirror only)

`packages/api_client`, `packages/shared_config`, and `packages/shared_types` were removed 2026-07-25 — unused stubs with zero consumers in either app.

## Commands

### Flutter (mobile app)
```bash
# Run from app directory (uygulamalar/mobil)
flutter analyze
flutter test
flutter test test/path/to/single_test.dart
flutter run -d <device>
```

### Web (Next.js)
```bash
# Run from uygulamalar/web/
npm run dev
npm run typecheck        # tsc --noEmit
npm run lint
npm run test:unit        # vitest run
npm run test:unit:watch  # vitest watch
npm run test:e2e         # playwright (public-menu)
npm run test:ci          # typecheck + lint + unit + build
```

### L10n / audit (repo root)
```bash
node tools/ceviri-denetimi.mjs   # i18n key audit
npm run l10n:audit
npm run verify:matrix
```

Sync shared ARB changes to apps:
```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
```

### Supabase local dev
```bash
supabase start          # starts local stack on ports 54321-54326
supabase db reset       # re-applies migrations + seed
supabase migration new <name>
```

### Minimum validation per change type
| Change | Required commands |
|--------|------------------|
| Flutter code | `flutter analyze` |
| Panel (Flutter web) | `flutter analyze` + `flutter test` |
| Web (Next.js) | `npm run typecheck` + `npm run lint` |
| L10n | `node tools/ceviri-denetimi.mjs` |
| Docs only | none required (state which were skipped) |

## Architecture

### Flutter apps — feature-first, `data/domain/ui`

Every feature folder follows three layers:
- **`data/`** — Supabase/RPC calls, cache, local storage, uploads. All new Supabase access starts here in a `*Repository` class.
- **`domain/`** — Riverpod `Provider`, `Notifier`, `AsyncNotifier` orchestration. Controllers/state live here.
- **`ui/`** — `*Page`, `*Sheet`, `*Card`, `*Section` widgets. UI never writes Supabase directly.

Naming conventions:
- Files: `snake_case.dart`
- Classes/widgets: `PascalCase`
- Providers: `*Provider`, notifiers: `*Controller`, repos: `*Repository`, pages: `*Page`
- Supabase RPC wrappers match existing names (`*_v1`, `*_v2`)

Mobile entry: `lib/main_mobile.dart` → router: `lib/app/router.dart`  
Theme source-of-truth: `lib/app/theme/*`

### Next.js web app

```
app/          — Next.js App Router routes, metadata, route handlers
src/lib/      — db helpers, supabase clients, schemas, i18n, rate-limit, analytics
src/ui/       — client components and sections
src/styles/   — tokens.css, globals.css
```

Key lib files: `supabaseServer.ts`, `supabaseClient.ts`, `rate-limit.ts`, `i18n.ts`, `media-url.ts`  
Route groups: `(public)`, `(auth)`, `owner/`, `admin/`, `api/`

Every mutation route handler must include `zod.safeParse`, auth check, and rate limiting.

### Supabase

Migrations in `supabase/migrations/` (numbered `YYYYMMDD######_name.sql`).  
Edge functions in `supabase/functions/`.  
All privileged RPCs follow `*_v1` / `*_v2` naming. New Supabase access goes through repositories; UI/route handlers never call RPC directly.

## Design System Rules

**Flutter:**
- Colors: `AppColors` (primary `#7F1D1D` deep red, slate tones)
- Tokens: `AppTokens.of(context)` → `space4/8/12/16/20/24`, `radius12/16/20/24`
- Breakpoints: `AppTokens.bp720/860/980/1180/1280` — never magic numbers
- No inline color, spacing, or hex. No raw `TextStyle(fontSize:16)` hardcodes — use `AppTypography`
- Min tap target: 44 px
- Font family: Sora

**Web:**
- Use semantic token classes: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`
- No raw Tailwind hex. No inline user strings — use `src/lib/i18n.ts`
- Web tokens mirror Flutter theme; `packages/ui_tokens` is the bridge (read-only for web)

## Constraints

- No admin/owner CRUD in mobile app.
- No second state management library (Riverpod in Flutter, Zustand in web).
- No new Supabase access outside a repository class in Flutter.
- No new architecture on the stub packages (`api_client`, `shared_config`, `shared_types`).
- No inline ARB-less user strings in Flutter; no inline copy in Next.js components.
- If you see a duplicated primitive, use the existing one or target `packages/shared_ui_components` — don't write a fourth copy.

## API / RPC Standards

### Supabase RPC Naming

Format: `{action}_{subject}_{version}` — snake_case, English, always start with `_v1`.

```
get_business_reviews_v1      ✓
admin_approve_owner_claim_v1 ✓
getBusinessReviews           ✗  camelCase
isletme_yorum_getir          ✗  Turkish
get_reviews                  ✗  no version
```

- Breaking change (remove param, remove return field, narrow GRANT) → open `_v2`; keep old version 90 days with `COMMENT ON FUNCTION ... IS 'DEPRECATED YYYY-MM-DD: use _v2';`
- Adding a param with DEFAULT is **not** a breaking change
- Trigger functions: `tg_` / `trg_` prefix, no versioning required
- Internal helpers: `_` prefix (`_review_verified_visit`), no versioning required

### SQLSTATE Error Codes (RAISE EXCEPTION)

| ERRCODE | Meaning | When |
|---|---|---|
| `P0001` | `not_found` | Record not found |
| `P0002` | `unauthorized` | No session / wrong role |
| `P0003` | `validation_error` | Invalid parameter value |
| `P0004` | `not_implemented` | Stub placeholder |

```sql
RAISE EXCEPTION 'not_found: İşletme bulunamadı' USING ERRCODE = 'P0001';
RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
```

### New RPC Template

```sql
CREATE OR REPLACE FUNCTION public.{action}_{subject}_v1(
  p_{param} {type},
  p_{optional} {type} DEFAULT {default}
)
RETURNS {json | TABLE(...) | void}
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  -- logic
END;
$$;

REVOKE ALL ON FUNCTION public.{action}_{subject}_v1(...) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.{action}_{subject}_v1(...) TO authenticated;
COMMENT ON FUNCTION public.{action}_{subject}_v1 IS 'Short description. Called by: {file}.';
```

### Next.js Route Handler Rules

Every mutation handler must have: `zod.safeParse` + auth check + rate limit.

```typescript
// Response shapes
NextResponse.json({ data: T, meta?: { total, page, page_size } }, { status: 200 });
NextResponse.json({ error: string, issues?: Record<string, string[]> }, { status: 4xx });
// Never: { message: string } or { ok: false }
// Exception: /api/feedback and /api/revalidate return { ok: true } — backward compat.
```

HTTP error codes: `400` invalid_payload | `401` unauthorized | `403` forbidden | `404` not_found | `409` conflict | `413` size_limit | `422` unprocessable | `429` rate_limited | `500` internal_error

### Deprecated RPCs (remove after client migration)

| Function | Replace with | Deadline |
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
