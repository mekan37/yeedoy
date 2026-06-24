# Yeedoy Monorepo

**Yeedoy** — Restoran ve yemek keşif platformu. Kullanıcılar yemek keşfeder, menüleri inceler ve yorum bırakır; işletme sahipleri menü ve operasyonlarını web panelinden yönetir.

*A food and restaurant discovery platform. Consumers discover and review venues; business owners manage menus and operations through the web panel.*

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        YEEDOY MONOREPO                          │
│                                                                 │
│  uygulamalar/mobil          uygulamalar/web                     │
│  Flutter (iOS / Android)    Next.js 15 App Router               │
│  Consumer discovery,        Public menus, QR Studio,            │
│  reviews, favorites,        owner/admin operations,             │
│  offline queue, AI OCR      branding, analytics                 │
│                                                                 │
│  packages/                                                      │
│  shared_ui_components       Shared Flutter design primitives    │
│  shared_models              Shared pure-Dart models             │
│  l10n_assets                Common ARB translation files        │
│  ui_tokens                  Tailwind/CSS token preset           │
│                                                                 │
│                     Supabase                                    │
│              Auth · PostgreSQL · RLS · Storage                  │
│              Edge Functions (Deno) · Realtime                   │
│                                                                 │
│              supabase/migrations/   — SQL migrations            │
│              supabase/functions/    — Edge Functions            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| App | Language / Framework | State | Router | Key Libraries |
|---|---|---|---|---|
| `uygulamalar/mobil` | Dart / Flutter (iOS + Android) | Riverpod 3.x | GoRouter 17.x | Supabase Flutter 2.x, Firebase, Google ML Kit, google_mobile_ads |
| `uygulamalar/web` | TypeScript / Next.js 15 | Zustand 5, TanStack Query 5 | Next.js App Router | Supabase SSR, Radix UI, Tailwind CSS 3, Zod 4, Playwright |
| `supabase/functions` | TypeScript / Deno | — | — | Supabase client, OpenRouter, Resend, FCM |

---

## Repository Structure

```
yeedoy/
├── uygulamalar/
│   ├── mobil/              Flutter iOS/Android consumer app
│   │   ├── lib/
│   │   │   ├── uygulama/   App bootstrap, routes, theme
│   │   │   ├── core/       Cross-cutting: analytics, cache, security, net
│   │   │   └── features/   Feature modules (data / domain / ui)
│   │   └── pubspec.yaml    Dart SDK ^3.10.7
│   ├── web/                Next.js 15 public + owner/admin surfaces
│   │   ├── app/            Route segments (App Router)
│   │   │   ├── (genel)/    Public-facing pages (discovery, menus, QR)
│   │   │   ├── (kimlik)/   Authenticated consumer pages
│   │   │   ├── sahip/      Owner panel pages
│   │   │   ├── yonetici/   Admin panel pages
│   │   │   └── sunucu/     Route handlers (API endpoints)
│   │   └── src/
│   │       ├── lib/        Server helpers, data fetchers, i18n
│   │       └── ui/         Client components and sections
├── packages/
│   ├── shared_ui_components/   AppTokens, AppColors, AppDarkColors, brand assets
│   ├── shared_models/          Pure-Dart models shared across Flutter apps
│   ├── l10n_assets/            common_tr.arb + common_en.arb (synced ARB)
│   └── ui_tokens/              tailwind.preset.cjs + tokens.css (web mirror)
├── supabase/
│   ├── functions/          Edge Functions (Deno) — see list below
│   └── migrations/         Ordered SQL migration files
├── scripts/
│   ├── local-db-setup.sh   Start Supabase + push all migrations
│   └── release-smoke.sh    Run web E2E smoke (local or live)
├── tools/                  Node.js scripts: l10n audit, OSM/FSQ import, hooks
├── .github/workflows/      CI pipelines (see CI/CD section)
├── package.json            Monorepo root (npm workspaces)
├── AGENTS.md               Architectural rules for AI agents
├── CLAUDE.md               Claude/AI workflow notes
└── STYLE.md                Code and architecture style guide
```

---

## Edge Functions

Located in `supabase/functions/`. Each subdirectory contains an `index.ts` entry point served by Supabase CLI.

| Function | Purpose |
|---|---|
| `ai-allergen-detect` | Extract allergen candidates from menu/product text |
| `ai-ingredient-detect` | Extract ingredient candidates from menu/product text |
| `ai-menu-analyze` | Batch AI menu analysis from image or raw text (OpenRouter) |
| `ai-menu-image-gen` | Generate food photography via Gemma + Pollinations.ai |
| `ai-nutrition-estimate` | Approximate nutrition values from menu text |
| `admin-api` | Allowlisted admin RPC and write flows through a single edge entry |
| `anti-spam-guard` | Anti-spam and rate-limit enforcement on review/report/verify writes |
| `get-exchange-rates` | Fetch exchange rate data for multi-currency panel flows |
| `import_places_json` | Bulk place import from JSON source |
| `media-upload` | Panel/admin media upload endpoint (WordPress media API compat layer) |
| `media-upload-user` | Mobile/user-scoped upload endpoint — writes to Supabase Storage |
| `purge-temp-uploads` | Periodic cleanup of temporary uploads |
| `push-dispatch` | Dispatch queued push notifications to providers |
| `send-push-campaign` | Owner-triggered push campaigns via FCM batch |
| `send-email-campaign` | Owner-triggered email campaigns via Resend batch API |
| `verify-domain` | Domain verification flow for owner branding |
| `write-gatekeeper` | Central guard layer for sensitive write operations |

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter | stable channel, SDK `^3.10.7` | `flutter upgrade` to get stable |
| Dart | included with Flutter | `^3.10.7` |
| Node.js | 20 | Web CI uses Node 20; 18+ works locally |
| npm | included with Node | Workspaces used at root |
| Java | 17 (Zulu) | Android builds only |
| Supabase CLI | `^2.x` | `npm install -g supabase` |
| Docker Desktop | running | Required for `supabase start` |

---

## Getting Started

### 1. Start Local Supabase

Docker Desktop must be running before this step.

```bash
# First time or after a full reset — starts stack and applies all migrations
bash scripts/local-db-setup.sh

# Check endpoints and keys
supabase status

# Stop the stack
supabase stop
```

Local endpoints after `supabase start`:

| | |
|---|---|
| API URL | `http://127.0.0.1:54321` |
| Studio | `http://127.0.0.1:54323` |
| Database | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |
| Anon Key | printed by `supabase status` |

### 2. Mobile Flutter App

```bash
cd uygulamalar/mobil

flutter pub get

# Run on connected Android device or emulator
flutter run

# Run on iOS simulator
flutter run -d ios

# List available devices
flutter devices
```

Create `uygulamalar/mobil/.env`:
```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<from supabase status>
```

### 3. Next.js Web App

```bash
cd uygulamalar/web

npm install

# Development server → http://localhost:3000
npm run dev

# Type-check
npm run typecheck

# Lint
npm run lint

# Run unit tests
npm run test:unit

# Production build
npm run build
npm run start
```

Create `uygulamalar/web/.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<from supabase status>
SUPABASE_SERVICE_ROLE_KEY=<from supabase status>
```

Public routes are under `app/(genel)/`. Owner routes are under `app/sahip/`. Admin routes are under `app/yonetici/`.

### 4. Edge Functions (Local)

```bash
# Serve a single function
supabase functions serve ai-menu-analyze --env-file supabase/.env.local

# Serve all functions
supabase functions serve --env-file supabase/.env.local
```

Create `supabase/.env.local`:
```
OPENROUTER_API_KEY=<from openrouter.ai — free plan sufficient>
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<from supabase status>
SUPABASE_SERVICE_ROLE_KEY=<from supabase status>
EDGE_RATE_LIMIT_SALT=<random strong string>
# For send-email-campaign only:
RESEND_API_KEY=<from resend.com>
```

Test a function locally:
```bash
curl -X POST http://127.0.0.1:54321/functions/v1/ai-menu-analyze \
  -H "Authorization: Bearer <user-jwt>" \
  -H "apikey: <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "https://...", "locale": "tr"}'
```

Deploy to production:
```bash
supabase functions deploy ai-menu-analyze --project-ref <project-ref>
supabase secrets set OPENROUTER_API_KEY=<key>
```

### 5. Run Everything Together

```bash
# Terminal 1
supabase start

# Terminal 2
cd uygulamalar/web && npm run dev

# Terminal 3
cd uygulamalar/mobil && flutter run
```

---

## Database

```bash
# Apply migrations to local DB
supabase db push --local

# Pull remote schema (requires active project)
SUPABASE_DB_PASSWORD=<password> supabase db pull --schema public,auth,storage

# Reset local DB — replays all migrations from scratch
supabase db reset
```

Migration files live in `supabase/migrations/`. Archived migrations are in `supabase/migrations/_archive/` and are not replayed.

---

## CI/CD

All workflows are in `.github/workflows/`.

| Workflow | File | Trigger | What it does |
|---|---|---|---|
| Mobile Quality | `mobile_quality.yml` | PR or push to `main` touching `uygulamalar/mobil/**` | `flutter pub get` → `flutter analyze` → `flutter test` → offline write guard check → hardcoded color check → release gate dry run |
| Mobile Readiness | `mobile_readiness.yml` | Manual (`workflow_dispatch`) | iOS readiness audit, release gate audit; optional signed IPA or APK dry-run with CI secrets |
| Web Quality | `web_quality.yml` | PR or push to `main` touching `uygulamalar/web/**` or `packages/ui_tokens/**` | `npm ci` → typecheck → lint → unit tests → Playwright E2E → `npm run build` → `npm audit` → RLS coverage check |
| Web Release Smoke | `web_release_smoke.yml` | Manual (`workflow_dispatch`) | Playwright smoke against production Supabase with configurable business UUID and language |

The former `personel_quality.yml` workflow has been removed along with the `uygulamalar/personel` app (decommissioned — owner/admin operations now live entirely in `uygulamalar/web`).

---

## Root Scripts

From the repo root:

```bash
# L10n key audit — fails if keys are missing or mismatched across ARB files
npm run l10n:audit

# Run web lint + mobile lint
npm run verify:matrix:lint

# Full pre-merge check: l10n audit + lint + web smoke
npm run verify:matrix

# Install git hooks
npm run hooks:install

# Clean workspace outputs
npm run clean
```

---

## Key Conventions

### File and Directory Naming

- Dart files: `snake_case.dart`
- TypeScript/TSX files: `kebab-case.ts`, `kebab-case.tsx`
- Dart classes and widgets: `PascalCase`
- Feature directory structure is a fixed three-layer split:
  - `data/` — repository, remote/local data source, cache, IO
  - `domain/` — Riverpod provider, controller, state, model
  - `ui/` — page, section, widget, sheet

### File Suffix Rules (Flutter)

| Suffix | Meaning |
|---|---|
| `*_page.dart` | Routable page widget |
| `*_sheet.dart` | Bottom sheet |
| `*_card.dart` | Card widget |
| `*_provider.dart` | Riverpod provider |
| `*_controller.dart` | Riverpod notifier/controller |
| `*_deposu.dart` | Repository class |

### Naming Conventions

- Riverpod providers: `*Provider`
- Notifier/controller classes: `*Controller` or `*Bildiricisi`
- Repository classes: `*Repository` or `*Deposu`
- Page widgets: `*Page` or `*Sayfasi`
- Supabase RPC names follow versioned contract: `*_v1`, `*_v2`

### Design System

Flutter apps consume the shared design system through `packages/shared_ui_components`:

- Colors: `AppColors` (primary deep red `#7F1D1D`), `AppDarkColors` for dark mode
- Spacing and radii: `AppTokens.of(context)` → `space4`, `space8`, `space12`, `space16`, `space20`, `space24`, `radius12`, `radius16`, `radius20`, `radius24`
- Typography: `AppTypography`
- Theme builder: `buildAppTheme()` — do not set colors or spacing inline
- Dark mode: `themeModeProvider` and `buildDarkAppTheme()` wired in the mobile app

Web design tokens are mirrored in `packages/ui_tokens/tailwind.preset.cjs` and `tokens.css`. Web components use semantic Tailwind classes (`bg-card`, `text-textStrong`, `border-border`) rather than raw hex values or arbitrary Tailwind numbers.

### Internationalization

- Flutter consumer app: all user-visible strings go into `lib/l10n/app_tr.arb` and `lib/l10n/app_en.arb` (template: `app_tr.arb`, output class: `AppLocalizations`)
- Shared strings used across multiple Flutter apps: `packages/l10n_assets/common_tr.arb` and `common_en.arb`; sync with `node packages/l10n_assets/scripts/sync-l10n.mjs`
- Web public UI copy: `uygulamalar/web/src/lib/` central files; no hardcoded strings inside components
- Supported locales: Turkish (`tr`) and English (`en`)

### Architecture Boundaries

These cross-app rules are enforced by CI tools and code review:

- Mobile app (`uygulamalar/mobil`) handles: discovery, menus, reviews, favorites, profile, contributions, offline queue, push notifications
- Web app (`uygulamalar/web`) handles: public SEO menu rendering, QR Studio, branding, owner/admin operations, onboarding, analytics
- Do not add owner/admin CRUD surfaces to the mobile app
- Do not move public SEO menu rendering out of Next.js
- New Supabase writes must go through a repository layer, not directly from UI code
- All new Next.js route handlers must include `zod.safeParse` validation, auth checking, and rate limiting

---

## Contributing

### Branch Strategy

Work on feature branches. Open pull requests against `main`. CI runs automatically on PRs that touch the relevant app path.

### Minimum Validation Before Pushing

Run only the surface you modified:

**Flutter mobile:**
```bash
# From the app directory
flutter analyze
flutter test test
```

**Next.js web:**
```bash
cd uygulamalar/web
npm run typecheck
npm run lint
npm run test:unit
```

**L10n changes:**
```bash
npm run l10n:audit
```

**Full pre-merge check (all surfaces):**
```bash
npm run verify:matrix
```

Documentation-only changes do not require running tests, but state explicitly which commands were skipped.

### Hardcoded Values

Do not commit:
- Inline colors, spacing, or raw hex values in Flutter code
- Raw Tailwind hex or arbitrary spacing numbers in web code
- Hardcoded secrets, API keys, or connection strings in any file
- User-facing strings outside the ARB / i18n system

---

## Reference Docs

| File | Contents |
|---|---|
| `AGENTS.md` | Architectural rules and boundaries for AI agents |
| `CLAUDE.md` | Claude/AI workflow notes and operation rules |
| `STYLE.md` | Code and architecture style guide (v1.0, 2026-04-08) |
| `PLAN.md` | Active doc pointers (backlog, setup, deploy, operations) |
| `docs/SYSTEM_OVERVIEW.md` | Three-app architecture and flow overview |
| `docs/ARCHITECTURE_AUDIT.md` | Strengths, risks, recommended actions |
| `docs/DATABASE_REVIEW.md` | Table groups, RPC inventory, RLS status |
| `docs/ADMIN_OWNER_GAP_ANALYSIS.md` | Feature status matrix (owner / admin) |
| `docs/SCALING_ROADMAP.md` | Three-phase scaling plan |
| `supabase/functions/README.md` | Edge function local run and deploy guide |
