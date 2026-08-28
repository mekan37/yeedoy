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

Sync shared ARB changes to apps:
```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
```

### Minimum validation per change type
| Change | Required commands |
|--------|------------------|
| Flutter code | `flutter analyze` |
| Panel (Flutter web) | `flutter analyze` + `flutter test` |
| Web (Next.js) | `pnpm run typecheck` + `pnpm run lint` |
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

Every mutation route handler must include `zod.safeParse`, auth check, and rate limiting.

### Supabase

Migrations in `supabase/migrations/` (numbered `YYYYMMDD######_name.sql`).  
Edge functions in `supabase/functions/`.  
All privileged RPCs follow `*_v1` / `*_v2` naming. New Supabase access goes through repositories; UI/route handlers never call RPC directly.

## Constraints

- No admin/owner CRUD in mobile app.
- **Web and mobile move together.** Before building a user-facing feature on one platform, check whether the other already has it (don't assume web is "primary" — mobile is sometimes ahead) and build/flag the missing side as part of the same task. If the feature is something an owner or admin would plausibly need to configure or manage, also check whether `/sahip` or `/yonetici` needs an equivalent.
- No second state management library (Riverpod in Flutter, Zustand in web).
- No new Supabase access outside a repository class in Flutter.
- No new architecture on the stub packages (`api_client`, `shared_config`, `shared_types`).
- No inline ARB-less user strings in Flutter; no inline copy in Next.js components.
- If you see a duplicated primitive, use the existing one or target `packages/shared_ui_components` — don't write a fourth copy.
- **`admin_*` RPC functions must always add an explicit anon revoke.** Production has a standing `ALTER DEFAULT PRIVILEGES` entry that auto-grants `anon` EXECUTE on every new function created by the `postgres` role. `REVOKE ALL ... FROM PUBLIC` does **not** undo this (`anon` is a real role, not the `PUBLIC` pseudo-role). This has caused three separate production security fixes so far (`20260810000006_sadakat_v1_revoke_anon_execute`, `20260820062028_fix_admin_alert_rules_anon_execute`, `20260824000008_admin_stock_dish_image_rpcs_revoke_anon`). Any new `admin_*` RPC must include `REVOKE EXECUTE ON FUNCTION public.admin_{subject}_v1(...) FROM anon;` right after the `GRANT EXECUTE ... TO authenticated` line — don't rely on the `is_admin()` in-body check alone.

Design system tokens live in `uygulamalar/mobil/CLAUDE.md` (Flutter) and `uygulamalar/web/CLAUDE.md` (Web). RPC naming, error codes, the new-RPC template, route handler response shapes, and the deprecated-RPC list live in the `rpc-and-route-handler-standards` skill.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
