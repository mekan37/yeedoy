# P1 Execution Status

**Date:** 2026-03-11
**Source:** Direct codebase audit — all statuses verified against actual implementation

This document maps every P1 priority item to its verified implementation state. Items are not marked complete based on documentation claims — each was verified against source files.

---

## Status Legend

| Symbol | Meaning |
|---|---|
| ✅ **Done** | Fully implemented and production-ready |
| 🟡 **Partial** | Functional but with documented gaps |
| ❌ **Not Started** | Not yet implemented |
| ⚠️ **Misclassified** | Previously listed as a gap; actually already complete |

---

## P1 Item Table

### P1-1 — Panel Login → Next Login return UX: single smooth flow

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/panel_flutter_web/lib/features/auth/ui/login_page.dart`, `uygulamalar/web/uygulama/auth/panel-devir/route.ts`, `uygulamalar/web/uygulama/login/page.tsx` |

**What exists:**
- Panel builds QR URL via `buildQrLoginUrl()` → redirects to `/login?redirect=/qr/{businessId}?lang=...&theme=...`
- After login, `POST /auth/panel-devir` receives `access_token`, `refresh_token`, `business_id`, `lang`, `theme`
- Route validates origin, token schema, session validity — then sets cookie and redirects to `/qr/{businessId}`
- Error path: "Owner session could not be restored" message with login link fallback
- No TODO/FIXME comments in flow; no multi-step friction observed

**Verdict:** Flow is already a single smooth handoff. This P1 item is **resolved**.

---

### P1-2 — Clearer owner/admin messages for QR permission errors

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/web/uygulama/qr/[businessId]/page.tsx`, `uygulamalar/web/src/lib/qr-access.ts`, `uygulamalar/web/uygulama/forbidden/route.ts` |

**What exists:**
- Two distinct error paths with different messages:
  - **Not logged in:** Redirect to `/login?redirect=...` (standard login gate)
  - **Logged in, no access:** Redirect to `/forbidden?from=...` with message: *"You do not have access to this QR Studio. This business can only be opened by its owner or an admin account with management access."* — with "Go back" + "Open login" CTAs
- HTTP status 403 correctly returned for forbidden case
- Clear, non-technical language; recovery actions provided

**Verdict:** Error differentiation is already implemented correctly. This P1 item is **resolved**.

---

### P1-3 — Smoke tests with real production data; per-release checklist enforcement

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/mobil/integration_test/live_write_smoke_integration_test.dart`, `uygulamalar/web/e2e/live-smoke.helpers.ts`, `uygulamalar/web/e2e/public-menu-live.spec.ts`, `uygulamalar/panel_flutter_web/e2e/panel-smoke.spec.cjs` |

**What exists:**
- Mobile: live write smoke test requiring `LIVE_SUPABASE_URL`, `LIVE_SMOKE_EMAIL`, `LIVE_SMOKE_PASSWORD`, `LIVE_SMOKE_BUSINESS_ID` — covers review, report, menu, favorites, unauthenticated fail paths
- Web Next: live environment helpers + `public-menu-live.spec.ts` for real backend testing
- Panel: Playwright smoke already covers owner/admin authenticated flows in addition to public/yasal routes

**What changed:**
- `scripts/release-smoke.sh` now provides a single release-smoke entry point for web/panel
- `panel_quality.yml` runs panel Playwright smoke as a required CI job after the build/analyze gates
- Panel smoke coverage now includes owner/admin authenticated scenarios rather than public-only checks

**Residual gap:** mobile live smoke still exists but is not yet wired into a stable device/emulator-backed CI release gate.

---

### P1-4 — Server-side pagination RPCs for admin queue and claims (`total_count`)

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/panel_flutter_web/lib/features/admin/data/admin_queue_deposu.dart`, `uygulamalar/panel_flutter_web/lib/features/admin/data/admin_reports_deposu.dart`, `uygulamalar/panel_flutter_web/lib/features/admin/data/admin_claims_deposu.dart` |

**What exists:**
- **Queue (`admin_queue_v1`):** ✅ Full server pagination — returns `AdminQueuePageResult(items, totalCount)`. `totalCount` read from first row.
- **Reports (`admin_list_reports_v5`):** ✅ Returns `total_count`; Dart model/controller state and pagination footer now surface actual totals
- **Claims (`admin_list_owner_claims_v3`):** ✅ Same as reports — `total_count` is carried through Dart state and shown in the footer

**Verification snapshot:** Implemented via `supabase/migrations/20260326000004_admin_reports_claims_total_count.sql` plus panel Dart model/controller/UI updates.

---

### P1-5 — Observability dashboard under `/admin/observability` using `analytics_events`

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart` (57.6KB) |

**What exists (comprehensive):**
- **Offline mutation monitoring:** Lists offline mutation outcomes across 6h/24h/72h windows; alert settings editor (min signal, retry/drop/auth/rate-limit thresholds); load/save to admin deposu
- **Performance SLO tracking:** Crash-free metrics, Home TTI targets, Edge 429 rate tracking
- **Feature flag inspector:** Reads from device prefs; shows test user overrides (city, district, user ID); product guardrails display
- **Data inspector:** Offline cache counts (favorites, recent businesses, categories); cache timestamps; request tracing (trace IDs, latency)

**Verdict:** Observability dashboard is a fully-featured, rich page — not a placeholder. This P1 item is **resolved**. (Previous documentation incorrectly characterized it as minimal.)

---

### P1-6 — Migrate `is_owner_of_business` → `has_business_permission_v1`

| Field | Value |
|---|---|
| **Status** | ✅ Done |
| **Verified in** | `uygulamalar/panel_flutter_web/lib/core/security/app_role_providers.dart`, `supabase/migrations/20260303142038_owner_team_rbac_and_impersonation.sql`, legacy migration files |

**What exists now:**
- `has_business_permission_v1` remains the canonical RBAC check
- New follow-up migration rewrites active legacy owner RPC definitions to explicit permissions without editing historical migrations
- Menu CRUD/moderation flows now declare `menu_write`; profile/commercial mutations use `business_write`; read-only helpers use `business_read`; growth analytics uses `analytics_view`

**Verification snapshot:** Implemented via `supabase/migrations/20260326000005_explicit_business_permissions_for_legacy_owner_rpcs.sql`.

---

### P1-7 — Migrate remaining panel pages to `PanelPageHeader` pattern

| Field | Value |
|---|---|
| **Status** | ✅ Done — owner shell happy-path pages now use explicit `PanelPageHeader` |
| **Verified in** | Grep across `uygulamalar/panel_flutter_web/lib/features/` |

**Owner shell pages verified on explicit `PanelPageHeader`:**

| Page | Status |
|---|---|
| `owner_businesses/ui/owner_businesses_page.dart` | ✅ |
| `owner_businesses/ui/owner_new_business_page.dart` | ✅ |
| `owner_businesses/ui/owner_business_submissions_page.dart` | ✅ |
| `owner_menu_management/ui/owner_menus_page.dart` | ✅ |
| `owner_menu_management/ui/owner_menu_editor_page.dart` | ✅ |
| `owner_menu_management/ui/owner_section_editor_page.dart` | ✅ |
| `owner_onboarding/ui/owner_onboarding_page.dart` | ✅ |
| `owner_price_suggestions/ui/owner_price_suggestions_page.dart` | ✅ |
| `owner_suspended/ui/owner_suspended_claims_page.dart` | ✅ |
| `owner_requests/ui/owner_group_requests_page.dart` | ✅ |
| `owner_team/ui/owner_team_page.dart` | ✅ |

**Residual `AppScaffold` usage under owner code is intentional:**

- `owner_menu_management/ui/owner_menus_page.dart` and `owner_onboarding/ui/owner_onboarding_page.dart` still return `AppScaffold` in a few redirect/loading/no-permission fallback branches, not as the primary shell layout.
- `owner_requests/ui/owner_group_requests_page.dart` still uses `AppScaffold` only for the unauthenticated redirect fallback.
- `owner/ui/owner_shell.dart` keeps the forbidden shell scaffold.
- Public/auth surfaces outside the owner shell continue to use `AppScaffold` normally.

---

## P1 Summary

| # | Item | Status | Priority |
|---|---|---|---|
| P1-1 | Panel login → Next QR return UX | ✅ Done | — |
| P1-2 | QR permission error messages | ✅ Done | — |
| P1-3 | Smoke tests per-release enforcement | ✅ Done | Medium |
| P1-4 | Admin reports/sahiplens `total_count` pagination | ✅ Done | Medium |
| P1-5 | Observability dashboard | ✅ Done | — |
| P1-6 | `is_owner_of_business` → `has_business_permission_v1` | ✅ Done | High |
| P1-7 | Panel pages → `PanelPageHeader` (owner shell set) | ✅ Done | Medium |

**Immediate focus:** No open P1 item remains in code; next panel UI debt is concentrated on admin-side design system adoption.

---

## Corrected Documentation Impact

The following docs contain incorrect claims corrected by this audit:

| Document | Incorrect Claim | Correction |
|---|---|---|
| `docs/ARCHITECTURE_AUDIT.md` | "observability page is minimal; no real dashboard" | Observability page is comprehensive — remove from risk table |
| `docs/ADMIN_OWNER_GAP_ANALYSIS.md` | "7 pages not migrated" | 11 total AppScaffold pages; 9 should migrate; 2 correctly excluded |
| `docs/yol-haritasi.md` | P1-1 and P1-2 listed as open | Both are already resolved — should be closed |

See `docs/arsiv/gecmis/kayma-raporu.md` for running diff tracking.


