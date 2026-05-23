# Documentation Index

**Last Updated:** 2026-03-11
**Scope:** All documents in `docs/`

This is the master navigation file for the Yeedoy deposu documentation. Use it to find the right document quickly. For Turkish-language navigation, see `docs/index.md`.

---

## Executive & Architecture (English)

| Document | Purpose |
|---|---|
| [`docs/SYSTEM_OVERVIEW.md`](SYSTEM_OVERVIEW.md) | What Yeedoy is, three-app architecture, end-to-end flows, application boundary contract |
| [`docs/ARCHITECTURE_AUDIT.md`](ARCHITECTURE_AUDIT.md) | Strengths, risks, module boundary assessment, recommended actions |
| [`docs/DATABASE_REVIEW.md`](DATABASE_REVIEW.md) | Supabase table groups, RPC inventory, RLS, security assessment, migration health |
| [`docs/ADMIN_OWNER_GAP_ANALYSIS.md`](ADMIN_OWNER_GAP_ANALYSIS.md) | Feature status matrix for every admin and owner panel screen |
| [`docs/SCALING_ROADMAP.md`](SCALING_ROADMAP.md) | Three-phase scaling plan: stability → growth → scale |

---

## System Architecture & Product

| Question | Document |
|---|---|
| What is Yeedoy? Three-app structure? | [`docs/SYSTEM_OVERVIEW.md`](SYSTEM_OVERVIEW.md) |
| How do routes, auth, QR, and public menu work? | [`docs/architecture.md`](architecture.md) |
| What is each app responsible for? | [`docs/apps.md`](apps.md) |
| What is the product? User/owner/admin impact? | [`docs/product.md`](product.md) |
| What is the current system status? | [`docs/vision_status.md`](vision_status.md) |
| What is the open backlog? | [`docs/yol-haritasi.md`](yol-haritasi.md) |

---

## Data & Backend

| Question | Document |
|---|---|
| Full table and RPC inventory? | [`docs/veri-modeli.md`](veri-modeli.md) |
| Supabase security, RLS, migration health? | [`docs/DATABASE_REVIEW.md`](DATABASE_REVIEW.md) |
| RBAC roles, permissions, team model? | [`docs/rol-yetki-matrisi.md`](rol-yetki-matrisi.md) |
| Data safety, trash, restore, versioning? | [`docs/veri-guvenligi.md`](veri-guvenligi.md) |
| Audit log and visibility surface? | [`docs/audit.md`](audit.md) |
| QR system end-to-end? | [`docs/qr-sistemi.md`](qr-sistemi.md) |

---

## Mobile

| Question | Document |
|---|---|
| Mobile architecture and module structure? | [`docs/mobile_architecture.md`](mobile_architecture.md) |
| Mobile feature scope (what is built)? | [`docs/mobile_features_matrix.md`](mobile_features_matrix.md) |
| Mobile Supabase table/RPC contracts? | [`docs/mobil-supabase-kontratlari.md`](mobil-supabase-kontratlari.md) |
| Mobile release checklist? | [`docs/mobil-release-kontrol-listesi.md`](mobil-release-kontrol-listesi.md) |
| Mobile CI/iOS readiness? | [`docs/mobil-ci-ios-hazirlik.md`](mobil-ci-ios-hazirlik.md) |
| Mobile test strategy? | [`docs/mobil-test-stratejisi.md`](mobil-test-stratejisi.md) |
| Mobile discovery and telemetry contract? | [`docs/mobil-kesif-telemetri-kontrati.md`](mobil-kesif-telemetri-kontrati.md) |
| Mobile offline/local DB plan? | [`docs/mobil-yerel-db-offline-plani.md`](mobil-yerel-db-offline-plani.md) |

---

## Panel Operations

| Question | Document |
|---|---|
| Which panel features exist vs. missing? | [`docs/ADMIN_OWNER_GAP_ANALYSIS.md`](ADMIN_OWNER_GAP_ANALYSIS.md) |
| Admin business operation? | [`docs/admin_businesses.md`](admin_businesses.md) |
| Admin submissions operation? | [`docs/admin_business_submissions.md`](admin_business_submissions.md) |
| Moderation queue operation? | [`docs/moderation_queue.md`](moderation_queue.md) |
| Receipt workbench? | [`docs/admin_receipt_workbench.md`](admin_receipt_workbench.md) |
| Admin search? | [`docs/admin_search.md`](admin_search.md) |
| Owner analytics dashboard? | [`docs/analytics_owner.md`](analytics_owner.md) |
| Media upload adapter contract? | [`docs/media_upload.md`](media_upload.md) |
| B2B data exports? | [`docs/b2b_exports.md`](b2b_exports.md) |
| Panel placeholders (brand assets, privacy)? | [`docs/panel_placeholders.md`](panel_placeholders.md) |

---

## Performance & Scaling

| Question | Document |
|---|---|
| How to scale to 100k+ businesses? | [`docs/SCALING_ROADMAP.md`](SCALING_ROADMAP.md) |
| Current panel scaling decisions? | [`docs/panel_scale.md`](panel_scale.md) |
| Panel performance budget? | [`docs/panel_perf.md`](panel_perf.md) |
| Web Next performance snapshot? | [`docs/web_next_perf.md`](web_next_perf.md) |

---

## Design & Style

| Question | Document |
|---|---|
| UI tokens, design system, branding? | [`docs/ui-style.md`](ui-style.md) |
| Module visibility and feature flags? | [`docs/module_visibility_matrix.md`](module_visibility_matrix.md) |

---

## Deployment & Operations

| Question | Document |
|---|---|
| Environment variables and deploy model? | [`docs/dagitim.md`](dagitim.md) |
| Smoke tests and incident runbook? | [`docs/operasyon-kilavuzu.md`](operasyon-kilavuzu.md) |
| Dev tools and admin panel tools? | [`docs/devtools.md`](devtools.md) |
| Test strategy (panel + web + mobile)? | [`docs/test_strategy.md`](test_strategy.md) |

---

## Historical Records

| Document | Purpose |
|---|---|
| [`docs/arsiv/gecmis/surum-indeksi.md`](surum-indeksi.md) | Index of all historical release snapshots |
| [`docs/release/`](release/) | Individual release snapshot files |
| [`docs/rollback/`](rollback/) | Rollback procedure snapshots |
| [`docs/arsiv/gecmis/temizlik-kaydi.md`](temizlik-kaydi.md) | Record of removed or cleaned-up code/docs |
| [`docs/arsiv/gecmis/kullanilmayanlar-kaldirildi.md`](kullanilmayanlar-kaldirildi.md) | Inventory of deleted unused files |
| [`docs/arsiv/gecmis/kayma-raporu.md`](kayma-raporu.md) | Docs-vs-code drift tracking |

---

## Document Health

| Category | Count | Health |
|---|---|---|
| Executive/Architecture (English) | 5 | ✅ New — 2026-03-11 |
| System architecture & product | 5 | ✅ Current |
| Data & backend | 6 | ✅ Current |
| Mobile | 8 | ✅ Current |
| Panel operations | 9 | ✅ Current |
| Performance & scaling | 4 | ✅ Current |
| Deployment & ops | 4 | ✅ Current |
| Historical records | 6 | 🟡 May drift from live code (acceptable) |

**Drift status:** No HIGH-severity docs-vs-code mismatches as of 2026-03-04. See [`docs/arsiv/gecmis/kayma-raporu.md`](kayma-raporu.md) for details.

---

## Writing Standards

All documents in this repo follow these conventions:

1. **Source-of-truth boundary** — each doc declares what it covers and explicitly delegates related topics to other docs
2. **Code evidence** — all claims backed by file paths as proof
3. **No duplication** — information lives in one place; others link to it
4. **Date stamped** — all docs include last-updated date at the top
5. **Action-oriented** — gaps and risks have recommended actions, not just observations
