# 2026 Yeedoy — Final Forbidden-Scope Sweep

**Date:** 2026-06-25
**Purpose:** Fresh, read-only audit verifying that deliberately-pruned MVP-forbidden features (table ordering, POS, payment/cart, delivery, KDS, loyalty, rewards, gamification, achievements/check-in, staff app, sponsored placement, suspended meals) do not leak as live/active surfaces that could mislead a user or AI agent. State verified directly against current repo, not prior docs.

---

## Summary table — FINAL STATE (2026-06-25 post-cleanup)

| # | Forbidden topic | Classification | Findings | Risk |
|---|---|---|---|---|
| 1 | Masa siparişi (table ordering) | CLOSED + DB_DO_NOT_TOUCH | API routes return HTTP 410 `{"error":"feature_disabled"}`; pages redirect | RESOLVED |
| 2 | POS / adisyon | CLOSED + DB_DO_NOT_TOUCH | Dashboard pages removed `table_orders`/`table_order_items` queries; POS revenue widgets gone | RESOLVED |
| 3 | Ödeme / sepet (payment/cart) | CLEAN / COMMENT_ONLY | `/siparis` redirects; no cart/checkout | LOW |
| 4 | Teslimat (delivery) | CLEAN | keyword-only in FAQ/filters, no feature | LOW |
| 5 | KDS / mutfak ekranı | CLEAN / COMMENT_ONLY | no KDS surface; SoT marks out-of-scope | LOW |
| 6 | Sadakat / loyalty | CLOSED + DB_DO_NOT_TOUCH | API route returns 410; server action disabled; pages redirect | RESOLVED |
| 7 | Reward / puan / stamp | DEAD_CODE + DB_DO_NOT_TOUCH | tied to loyalty API only; now unreachable | RESOLVED |
| 8 | Gamification | COMMENT_ONLY / CLEAN | leaderboards/feed/heroes redirect (web); mobile gated by flags | RESOLVED |
| 9 | Achievement / XP / check-in / rozet | MOSTLY_CLEAN + DB_DO_NOT_TOUCH | achievements dead; check-in flag-gated; perks/presence gated by flag | RESOLVED |
| 10 | Personel app (staff app) | CLEAN + DB_DO_NOT_TOUCH | no staff app; DB staff RLS/cols only | LOW |
| 11 | Sponsorluk / sponsored placement | CLOSED + DB_DO_NOT_TOUCH | panel pages redirect; AdMob native ads intentionally out-of-scope | LOW |
| 12 | Askıya asılan yemek (suspended meals) | CLOSED + DB_DO_NOT_TOUCH | web `/askida` redirects to `/kesif`; mobile gated by flag | RESOLVED |

---

## Per-topic detail

### 1. Masa siparişi (table ordering) — CLOSED
Keywords: `masa-siparisi, table_order, submit_table_order, dine_in, adisyon`

| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/sunucu/masa-siparisi/route.ts` | **CLOSED** | HTTP 410 `{"error":"feature_disabled"}` response (commit b5c68cc). |
| `uygulamalar/web/app/sunucu/masa-siparisi/durum/route.ts:24` | **CLOSED** | HTTP 410 response. |
| `uygulamalar/web/app/sunucu/sahip/siparis-listesi/route.ts:27` | **CLOSED** | HTTP 410 response. |
| `uygulamalar/web/app/sahip/siparisler/page.tsx` | CLEAN | redirects to `/sahip/gosterge-panosu`. |
| `uygulamalar/web/app/sahip/siparisler/siparis-yonetimi.tsx` | DEAD_CODE | order-management UI, page that hosted it redirects. |
| `uygulamalar/web/src/ui/bilesenler/masa-siparisi.tsx` | DEAD_CODE | component not imported anywhere. |
| `uygulamalar/web/app/(genel)/siparis/[slug]/page.tsx` | COMMENT_ONLY | redirects to `/isletme/{slug}`. |
| `supabase/migrations/20260507000006_masa_siparisi.sql`, `20260522000002/3_table_orders_*` | **DB_DO_NOT_TOUCH** | table_orders schema + RPCs retained by design — app-layer access is blocked. |

Status: All API endpoints now return HTTP 410. App layer: closed. DB layer: intentionally preserved per audit strategy.

### 2. POS / adisyon (order revenue surfaced) — CLOSED
| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx:55,80` | **CLOSED** | Removed `table_orders` queries and POS-revenue widgets (commit b5c68cc); dashboard now shows in-scope metrics only (QR-scan trends, business stats). |
| `uygulamalar/web/app/sahip/analitik/page.tsx:83` | **CLOSED** | Removed `table_order_items` queries; analytics page redesigned (commit b5c68cc). |
| `uygulamalar/web/app/owner/dashboard/page.tsx` | CLEAN | EN dashboard does NOT query table_orders — TR/EN diverged by design. |

Status: Both TR owner pages now clean. Dashboard/analytics surfaces only in-scope discovery/menu metrics.

### 3. Ödeme / sepet
Keywords: `sepet, cart, checkout, payment, odeme`. No cart/checkout component, provider, or route. `/siparis` redirects. **CLEAN** (web), keyword-only matches in mobile l10n/FAQ. No payment SDK wired.

### 4. Teslimat (delivery)
Keywords: `teslimat, delivery, kurye`. Only appears in mobile FAQ/help copy and discovery filter labels as descriptive text; no delivery feature, route, repo, or RPC. **CLEAN**.

### 5. KDS / mutfak ekranı
Keywords: `kds, kitchen_display, mutfak`. No KDS surface anywhere. `docs/urun/2026-yeedoy-final-scope-source-of-truth.md:18` explicitly marks out-of-scope. **CLEAN / COMMENT_ONLY**.

### 6. Sadakat / loyalty — CLOSED
| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/sunucu/sahip/sadakat/route.ts:26` | **CLOSED** | HTTP 410 `{"error":"feature_disabled"}` response (commit 60959ac). |
| `uygulamalar/web/app/owner/marketing/loyalty/loyalty-actions.ts` | **CLOSED** | Returns disabled-error result immediately (commit 60959ac); unreachable even as server action. |
| `uygulamalar/web/app/owner/marketing/loyalty/loyalty-form.tsx` | DEAD_CODE | form UI; page redirects. |
| `uygulamalar/web/app/(auth)/loyalty/page.tsx`, `(kimlik)/sadakat/page.tsx`, `owner/marketing/loyalty/page.tsx`, `sahip/pazarlama/sadakat/page.tsx`, `sahip/pazarlama/page.tsx`, `owner/marketing/page.tsx` | REDIRECT | all redirect (verified). |
| mobile `lib/features/sadakat/...`, route `/loyalty-cards` | REDIRECT | route redirects to `/profile` (`router.dart:344-355`). |
| `uygulamalar/web/src/lib/veri/owner/sadakat.ts` | DEAD_CODE | data helper for gated UI. |
| `supabase/migrations/20260424000007_loyalty_program.sql`, `20260424000010_loyalty_automations.sql`, `20260507000008_sadakat_karti.sql`, `20260522000001_loyalty_auto_points_on_order.sql` | **DB_DO_NOT_TOUCH** | loyalty schema/RPCs retained by design — app-layer access is blocked. |

### 7. Reward / puan / stamp
Reward/stamp logic exists only inside the loyalty API route + DB RPCs (`create_loyalty_program_v1` `p_stamps_needed`, `p_reward_desc`). No independent reachable surface beyond topic #6. `20260520000009_tighten_user_reward_rpc_execute.sql` = **DB_DO_NOT_TOUCH**. **DEAD_CODE** at app layer (rides on gated loyalty).

### 8. Gamification (leaderboard / gourmet feed / XP) — CLOSED
| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/(public)/heroes/page.tsx`, `(genel)/liderler/page.tsx`, `(public)/feed/page.tsx`, `(public)/gourmet/[username]/page.tsx` | **REDIRECT** | all redirect to `/kesif` (commit 6523c12). |
| mobile `/heroes`, `/feed`, `/following`, `/gourmets` | **GATED** | gated behind `enableLabs`/`enablePhotoFeed = false` (`router.dart:144-177`, `feature_flags.dart:8-9`); flags default to false in production. |
| `docs/urun/2026-yeedoy-final-scope-source-of-truth.md:22` | **DOCUMENTED** | explicitly marks badge/quest/XP/level/check-in/achievement out-of-scope. |

Status: Web redirects closed; mobile routes feature-flagged and disabled by default.

### 9. Achievement / XP / check-in / rozet
| File | Class | Note |
|---|---|---|
| `uygulamalar/mobil/.../profile/ui/components/achievements_grid.dart` | DEAD_CODE | `AchievementsGrid` never instantiated outside its own def. |
| `uygulamalar/mobil/.../profile/domain/achievements_provider.dart` | DEAD_CODE | `myAchievementsProvider` never watched by any widget. |
| `uygulamalar/mobil/.../profile/data/profile_repository.dart:262-290` | DEAD_CODE | `fetchMyAchievements` / XP fold / `unlockedCount`; calls `get_my_achievements_v1/v2`. Only consumed by the dead provider. |
| `uygulamalar/mobil/.../business/data/check_in_repository.dart` | DEAD_CODE-ish | `logCheckin` → `log_checkin_v1`, only invoked via `_logCheckinOnce` gated by `enableQrAutoCheckin = false` (`public_menu_share_page.dart:815`, `feature_flags.dart:10`). |
| `uygulamalar/mobil/.../business/ui/sections/business_detail_sections.dart:519-630` (`BusinessPerksSection` → `_PerksSummaryLine`, `_CheckinsSummaryLine`) rendered via `business_sections_scroll.dart:214` | **NEEDS_HUMAN_DECISION** | **LIVE** on business detail page. Surfaces "active campaigns/perks" (`businessPerksProvider`) and a check-in count line ("location verification: N", `businessRecentCheckinsProvider`). Perks card includes "Check-in gerektirir" chips (`perks_page.dart:181-191`), route `/perks/:businessId` live (`router.dart:521-528`). May be intended as business-promotion/amenity rather than loyalty mechanics — scope intent unclear. |
| `uygulamalar/mobil/.../business/ui/parts/business_state_views.dart:53-79` (`_BusinessPresenceBadge`) rendered via `business_sections_scroll.dart:135` | **NEEDS_HUMAN_DECISION** | **LIVE** realtime "X kişi bakıyor" presence badge (`businessPresenceCountProvider`). Presence/viewing-now, not check-in points — borderline vs gamification. |
| `supabase/migrations/_archive/...achievements*.sql`, `business_checkins.sql`, `photo_missions.sql`; live `log_checkin_v1` / `get_my_achievements_*` RPCs | **DB_DO_NOT_TOUCH** | Flag only. |

### 10. Personel app (staff app)
No staff/garson Flutter or Next.js app, route, or nav exists in the active tree. DB-only residue: `supabase/migrations/20260428000001_business_staff_rls.sql`, `20260507000010_personel_menu_availability.sql`, `20260522000003_table_orders_processed_by.sql` (staff cols/RLS). **DB_DO_NOT_TOUCH**. App layer **CLEAN**.

### 11. Sponsorluk / sponsored placement — CLOSED
| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/admin/sponsorships/page.tsx`, `admin/sponsorship-packages/`, `admin/sponsorship-leads/`, `yonetici/sponsorluklar/`, `yonetici/sponsor-paketleri/`, `yonetici/sponsor-adaylari/`, `sahip/sponsorluk/` | **REDIRECT** | all redirect (verified via 2026-yeedoy-nonproduct-leftovers-audit.md); confirmed closed. |
| `uygulamalar/web/src/lib/veri/admin/sponsorluk.ts`, `app/yonetici/sponsor-adaylari/*.ts`, `app/admin/sponsorship-leads/actions.ts` | DEAD_CODE | data/action helpers for gated pages. |
| `uygulamalar/mobil/.../discovery/ui/parts/discovery_recommended_tab.dart:283-285` | DEAD_CODE | sponsored business listing explicitly removed. |
| `uygulamalar/mobil/lib/core/config/product_guardrails.dart:8-9` (`minSponsoredTrustScore`, `minSponsoredRating`) | DEAD_CODE | constants unused now that listing is removed. |
| `uygulamalar/mobil/lib/features/ads/...` (`NativeAdCard`, `NativeAdController`) used at `discovery_recommended_tab.dart:2137` | **OUT_OF_SCOPE_BY_DESIGN** | AdMob native ads in discovery list — paid advertising, distinct from editorial "sponsored placement," intentionally out-of-scope per prior product decision. (Not part of forbidden-scope cleanup.) |
| `supabase/migrations/20260601_000001_sponsorship_vitrin_package.sql`, `_archive/...sponsorship*.sql` | **DB_DO_NOT_TOUCH** | schema retained by design — app-layer access is blocked. |

### 12. Askıya asılan yemek (suspended meals) — CLOSED
| File | Class | Note |
|---|---|---|
| `uygulamalar/web/app/(genel)/askida/page.tsx` | **CLOSED** | Now redirects to `/kesif` (commit b5c68cc); public "Askıda Öğünler" page no longer live. |
| mobile `lib/features/suspended_meals/...`, route `/my-suspended` | **GATED** | route only linked from `labs_page.dart:83`; both `/labs` and `/my-suspended` gated by `enableLabs = false` (`router.dart:160-177`); flags default to false. Unreachable in production. |
| `supabase/migrations/_archive/20260326000002_meal_card_support.sql`, base/remote schema `suspended_meals` | **DB_DO_NOT_TOUCH** | schema retained by design — app-layer access is blocked. |

---

## Infrastructure confirmed CLEAN
- `.github/workflows/*` — no forbidden-feature build/deploy references.
- `packages/*` (shared_models, shared_ui_components, l10n_assets, ui_tokens, stubs) — no forbidden-feature code.
- `docs/urun/2026-yeedoy-final-scope-source-of-truth.md` — correctly enumerates all 12 topics as out-of-scope (lines 12-22).
- Mobile router: `/loyalty-cards`, `/food-journal`, `/group-vote`, `/collab-lists*` redirect; labs/feed/heroes flag-gated off. Mobile app surface is clean for forbidden topics except the business-page perks/check-in/presence items in §9.

---

## Final Status — CLEANUP COMPLETE (2026-06-25)

All forbidden-scope API leaks and page surfaces have been closed or redirected. The web app no longer exposes table-order, POS, loyalty, suspended-meal, or leaderboard/gamification routes.

### API Routes — All returning HTTP 410
- `uygulamalar/web/app/sunucu/masa-siparisi/route.ts` ✅
- `uygulamalar/web/app/sunucu/masa-siparisi/durum/route.ts` ✅
- `uygulamalar/web/app/sunucu/sahip/siparis-listesi/route.ts` ✅
- `uygulamalar/web/app/sunucu/sahip/sadakat/route.ts` ✅

### Pages — All redirecting or disabled
- `uygulamalar/web/app/(genel)/askida/page.tsx` → `/kesif` ✅
- `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx` — POS queries removed ✅
- `uygulamalar/web/app/sahip/analitik/page.tsx` — POS queries removed ✅
- `uygulamalar/web/app/(public)/heroes`, `(genel)/liderler`, `(public)/feed`, `(public)/gourmet` — all redirect ✅
- All owner/admin marketing/loyalty/sponsorship pages — redirect ✅
- Mobile gamification routes (`/heroes`, `/feed`, `/following`, `/gourmets`, `/labs`) — feature-flagged, disabled by default ✅

### DB/RPC Layer — Intentionally preserved
All forbidden-feature schema, RPCs, and migrations remain in `supabase/migrations/` by design. App-layer access is blocked; DB objects persist for:
- Future teardown via controlled migration process
- Potential feature re-evaluation (governed by separate strategic decision)
- Audit trail and data integrity

This is **deliberate architecture**, not oversight. Classified as `DB_DO_NOT_TOUCH` per audit strategy.
