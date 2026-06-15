# Business Detail Page Redesign — Phase 1 — Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement the plan derived from this spec.

**Goal:** Redesign the top of the mobile Business Detail page (`lib/features/business/ui/business_page.dart` and its `part` files) to match the `işletmedetay.png` mockup — hero with overlay action buttons, title/rating/category/status row, real-data badge chip row, description, a `Genel`/`Menü`/`Yorumlar` tab bar, and a fixed bottom action bar — while preserving all existing sections (relocated into the new tabs) and adding zero invented data.

**Architecture:** Pure UI/composition + small data-model extension inside the existing `feature-first` `business` feature. No new Supabase tables/RPCs. Reuses all existing providers (`_businessProvider`, `_businessHoursProvider`, `_businessTrustProvider`, `businessTrendingItemsProvider`, `businessAmenitiesProvider`, `businessDetailProvider`, `isFavoritedProvider`) plus one extension to `Business`/`fetchBusiness` to expose `description`.

**Tech Stack:** Flutter, Riverpod, go_router, existing design system (`AppColors`/`AppTokens`/`AppTypography`), ARB l10n (TR+EN).

---

## 1. Scope

### In scope
- Extend `Business` model + `fetchBusiness` query to expose `description` (already present in `businesses_with_stats` view, just not read).
- Restyle `_BusinessHeroTrustHeader`: hero overlay back/share/favorite buttons, rating badge, `_OpenNowHeroBadge` l10n fix.
- New real-data badge chip row (Menü Onaylı / Popüler).
- New description block (`business.description`).
- New `Genel` / `Menü` / `Yorumlar` `TabBar` + `TabBarView` skeleton, header fixed above tabs.
- New `Genel` tab sections: Öne çıkanlar (dynamic cards), Popüler lezzetler (summary), Konum ve saatler (2-card row), Son yorumlar (1-card summary) — placed above the preserved existing sections.
- Relocate existing menu-related sections into `Menü` tab; relocate review-related sections into `Yorumlar` tab.
- New fixed bottom action bar: Yol Tarifi / Menüyü Gör / Favori toggle. Remove `ContributeFab`.
- New ARB keys (TR+EN) for all new copy.

### Out of scope (per decisions made during brainstorming)
- "Hazırlık süresi" (prep time) and "Fiyat seviyesi" (price level) from the mockup — **removed entirely**, no real data exists for `Business`.
- "Paket Servis" / "Yerinde Yeme" badge chips — no reliable real-data mapping yet (`order_*_url` not on `Business` model, amenity mapping unclear); deferred to a later phase.
- Reviewer avatar/display name in "Son yorumlar" — `ReviewPreview` has no avatar/name field; the summary card shows rating + date + content only.
- Full weekly-hours bottom sheet — Faz 1 shows today's hours only (existing `_businessHoursProvider` data); chevron navigates to the existing "report hours" flow if no detail view exists.
- Any change to `AppBottomNav`/`AppShell`/router structure beyond in-page tab navigation.
- **Distance row** (mockup's "500m") — `userLocationProvider` (`UserLocationState`) does not expose the user's `lat`/`lng` (only `city`/`district`/`neighborhood`/`mode`), so a real distance cannot be computed without a separate location-infrastructure change. Deferred to a later phase.

---

## 2. Data Model Changes

### 2.1 `Business` model (`lib/features/business/domain/business.dart`)
Add `description` field:
```dart
final String? description;
```
- Constructor: add `this.description,`
- `fromMap`: `description: m['description'] as String?,`
- `toMap`: `'description': description,`

### 2.2 `fetchBusiness` query
Locate the repository method backing `_businessProvider` (`discoveryRepositoryProvider.fetchBusiness(id)`). If it selects from `businesses_with_stats` (which already returns `description`), no SQL change is needed — only confirm the select list/`*` includes `description` and that `Business.fromMap` (now updated per 2.1) receives it. If the query explicitly lists columns and omits `description`, add it to the select list.

---

## 3. Header Section (`_BusinessHeroTrustHeader`, `business_header.dart`)

### 3.1 Hero overlay buttons
- Wrap the existing `Stack` (hero image + gradient) with `Positioned` overlay buttons:
  - Top-left: back button (circular semi-transparent dark background, `Icons.arrow_back`, `Navigator.maybePop` / `context.pop()`).
  - Top-right: `Row` with two circular buttons — share (`Icons.share_outlined`, reuses the existing share logic currently in `AppAppBar` actions) and favorite toggle (`Icons.favorite`/`Icons.favorite_border` based on `ref.watch(isFavoritedProvider(business.id))`, `onPressed` calls `ref.read(favoritesRepositoryProvider.notifier).toggleFavorite(business.id)` — same provider used by `business_detail_sections.dart:142/161`).
- `business_page.dart`'s `AppAppBar` actions: remove the share `IconButton` (moved to overlay) and the favorite-related action if any; **keep** the report-flag `IconButton`.

### 3.2 Title / rating / category / status row
- Business name (existing 34px white w900 style, unchanged).
- Rating badge: `Row` with `⭐` icon (`AppColors.warning`/amber tone) + `business.avgRating.toStringAsFixed(1)`, shown only if `business.reviewsCount > 0`. New small pill widget `_RatingBadge`.
- Category + location text (existing, unchanged).
- `StatusBadge(type: verified, label: t.verified)` — unchanged, existing condition.
- `_OpenNowHeroBadge`: replace hardcoded `'Açık'`/`'Kapalı'` strings (line 148) with `t.openNow` / `t.closedNow` (existing ARB keys, already used in `BusinessHoursSection`).

### 3.4 Badge chip row (new, below the title row, above description)
New `_BusinessBadgeChipRow` widget (`ConsumerWidget`):
- Watches `_businessTrustProvider(business.id)` and `businessTrendingItemsProvider(business.id)`.
- Chips (each only added if its condition is true):
  - **"Menü Onaylı"** (`Icons.verified_outlined`, green tint `AppColors.success`/`successSoft`) — shown if `trustAsync.value?.menuSource == 'owner'`.
  - **"Popüler"** (`Icons.local_fire_department_outlined`, orange/red tint) — shown if `trendingAsync.value` is non-empty.
- If both conditions are false, the entire row is `SizedBox.shrink()` (no empty `Wrap`).
- New ARB keys: `businessBadgeMenuVerified` ("Menü Onaylı" / "Verified Menu"), `businessBadgePopular` ("Popüler" / "Popular").

### 3.5 Description
- New `_BusinessDescription` widget: if `business.description?.trim().isNotEmpty == true`, render `Text(business.description!, style: ...)` (muted body text, max lines none — full text). Else `SizedBox.shrink()`.

---

## 4. Tab Bar Skeleton (`business_page.dart` + `business_sections_scroll.dart`)

### 4.1 Structure
`BusinessPage.build`'s `data:` branch for `RefreshIndicator` body changes from:
```dart
child: _BusinessSectionsScroll(business: business)
```
to:
```dart
child: DefaultTabController(
  length: 3,
  child: Column(
    children: [
      // existing header content (hero, badge: presence, weather hint) stays OUTSIDE the TabBarView,
      // i.e. in a fixed, non-scrolling area above the tabs.
      _BusinessFixedHeader(business: business, isOpenNow: isOpenNow),
      TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: t.businessTabGeneral),
          Tab(text: t.businessTabMenu),
          Tab(text: t.businessTabReviews),
        ],
      ),
      Expanded(
        child: TabBarView(
          children: [
            _BusinessGeneralTab(business: business, isOpenNow: isOpenNow),
            _BusinessMenuTab(businessId: business.id, fallbackCategory: business.category),
            _BusinessReviewsTab(businessId: business.id),
          ],
        ),
      ),
    ],
  ),
)
```
- `_BusinessFixedHeader` = `_BusinessHeroTrustHeader` (with all Section 3 changes) + `_BusinessBadgeChipRow` + `_BusinessDescription`, wrapped in the existing `LayoutBuilder` max-width constraint logic currently in `_BusinessSectionsScroll`. Horizontal padding `space16`, top padding `space12`.
- New ARB keys: `businessTabGeneral` ("Genel"/"General"), `businessTabMenu` ("Menü"/"Menu"), `businessTabReviews` ("Yorumlar"/"Reviews").

### 4.2 `RefreshIndicator` invalidation list
Unchanged — all ~12 invalidated providers still apply regardless of which tab is active (Riverpod providers are independent of `TabBarView` visibility).

---

## 5. "Genel" Tab (`_BusinessGeneralTab`, new widget in `business_sections_scroll.dart`)

A `ListView` (same padding as today: `EdgeInsets.fromLTRB(space16, space12, space16, space24)`), children in order:

1. **`_BusinessFeaturedSection`** ("Öne çıkanlar") — new widget, dynamic horizontal `Wrap`/`Row` of cards:
   - Rating card: shown if `business.avgRating > 0`. Icon `⭐` in pink circle (`AppColors.primarySoft`), value `business.avgRating.toStringAsFixed(1)`, label `t.featuredRatingLabel` ("Puan"/"Rating").
   - Amenity card: `ref.watch(businessAmenitiesProvider(business.id))` — if any amenity has `key == 'kids_area'`, show a card with that amenity's own `icon`/`label` from the DB (no hardcoded translation — use `amenity.label` as-is).
   - Menü Onaylı card: shown if `_businessTrustProvider(business.id).value?.menuSource == 'owner'` — icon `Icons.verified_outlined`, title `t.businessBadgeMenuVerified`, subtitle `t.featuredMenuVerifiedSubtitle` ("Sahibi tarafından güncellendi"/"Updated by owner").
   - If zero cards apply, the whole section (including its "Öne çıkanlar" title) is omitted.
   - New ARB keys: `featuredSectionTitle` ("Öne çıkanlar"/"Featured"), `featuredRatingLabel`, `featuredMenuVerifiedSubtitle`.

2. **`_BusinessPopularDishesSection`** ("Popüler lezzetler") — new widget:
   - Title row: `t.popularDishesTitle` ("Popüler lezzetler"/"Popular dishes") + trailing `TextButton(t.seeAll, onPressed: () => DefaultTabController.of(context).animateTo(1))`.
   - `ref.watch(businessTrendingItemsProvider(business.id))`, take first 4 items.
   - Each item: small card — `imageUrl` (or category placeholder asset if null, same fallback pattern as hero), `itemName`, formatted price via the existing `_formatPriceWithCurrency(context, priceCents, currency)` helper (already used in `business_sections_scroll.dart`).
   - Layout: `GridView.count(crossAxisCount: 2, ...)` inside a `SizedBox`-bounded area, or `Wrap` with fixed-width cards (`ConstrainedBox(maxWidth: 160)`) — match existing card-grid conventions used elsewhere in the app (check `discovery_cards.dart` for an existing 2-col card grid pattern to reuse/mirror).
   - If `trendingAsync.value` is empty, the whole section is omitted.
   - New ARB keys: `popularDishesTitle`, `seeAll` ("Tümünü gör"/"See all" — check ARB first; reuse if an equivalent key already exists, e.g. `discoverySeeAll`).

3. **`_BusinessLocationHoursSection`** ("Konum ve saatler") — new widget:
   - Title `t.locationHoursTitle` ("Konum ve saatler"/"Location & hours").
   - `Row` with two `Expanded` cards:
     - **Address card**: `Icons.location_on_outlined`, `business.address` (fallback to `district`/`city` if address is null), trailing chevron. `onTap` → reuse the existing `_openDirections(lat, lng, businessName, address)` helper from `business_state_views.dart` (the same one backing the bottom-bar "Yol Tarifi" button — see Section 6).
     - **Hours card**: `ref.watch(_businessHoursProvider(business.id))`. If data present: `Icons.schedule`/`schedule_outlined` (color per `isOpenNow`), text `${isOpenNow ? t.openNow : t.closedNow} · ${_hoursText(context, open, close)}` (reuse `_hoursText` helper from `business_detail_sections.dart`), trailing chevron. `onTap` → `_openReportSheet(context, businessId)` (existing helper, same as `BusinessHoursSection`'s "report hours" CTA — Faz 1 has no dedicated weekly-hours view). If `today == null` (no hours data), card shows `AppEmptyState`-style compact message (`t.hoursInfoMissing`) with the same report CTA.
   - New ARB key: `locationHoursTitle`.

4. **`_BusinessRecentReviewsSection`** ("Son yorumlar") — new widget:
   - Title row: `t.recentReviews` (existing key) + trailing `TextButton(t.seeAll, onPressed: () => DefaultTabController.of(context).animateTo(2))`.
   - `ref.watch(businessDetailProvider(business.id))`. If `latestReviews.isEmpty`, omit the whole section (no empty-state card here — the full empty state already exists in the Yorumlar tab).
   - Else show 1 card for `latestReviews.first`: `⭐ {review.rating}`, formatted relative/short date from `review.createdAt` (reuse existing date-formatting helper used elsewhere for `lastPriceVerifiedAt`), `review.content` (`maxLines: 3, overflow: ellipsis`). No avatar/name (not in `ReviewPreview`).

5. **Preserved existing sections, unchanged, in current order** (all other sections relocate to Menü/Yorumlar per Section 7):
   - `_BusinessPresenceBadge(businessId: business.id)`
   - `const WeatherHintBar(compact: true)`
   - `trustAsync.when(...)` block (3x `_TopStatCard`, `CommunityScoreGuideCard`, `_CommunityVerifiedCard`, `_PriceHistorySection`)
   - `BusinessPerksSection(businessId, businessName)`

---

## 6. Fixed Bottom Action Bar (`business_page.dart`)

New `bottomNavigationBar: _BusinessBottomActionBar(business: business)` on the `AppScaffold`. Remove `floatingActionButton: ContributeFab(...)`.

`_BusinessBottomActionBar` (`ConsumerWidget`):
- `Container` with top border (`AppColors.border`), background `AppColors.card`, padding `space12`/`space16`, `SafeArea(top: false, ...)`.
- `Row`:
  - `OutlinedButton.icon(icon: Icons.directions_outlined, label: Text(t.directions))` — `onPressed: () => _openDirections(lat: business.lat, lng: business.lng, businessName: business.name, address: business.address)` (existing helper from `business_state_views.dart`, made accessible — it's already `part of` the same library, so callable directly).
  - `Expanded(child: FilledButton(onPressed: () => DefaultTabController.of(context).animateTo(1), child: Text(t.viewMenu)))` — primary red, takes remaining width.
  - `IconButton` favorite toggle — same `isFavoritedProvider`/`toggleFavorite` pattern as Section 3.1's hero overlay favorite button (one shared private helper/widget `_FavoriteToggleButton(businessId)` used in both places to avoid duplication).
- New ARB keys: `directions` ("Yol Tarifi"/"Directions"), `viewMenu` ("Menüyü Gör"/"View Menu"). Check ARB first — `directions` or similar may already exist from another feature; reuse if so.

---

## 7. "Menü" and "Yorumlar" Tabs

### `_BusinessMenuTab` (new widget, `business_sections_scroll.dart`)
`ListView` containing, in order:
1. `_BusinessMenuPreviewSection(businessId, fallbackCategory: business.category)` (existing, unchanged — moved from Genel tab's old position)
2. `BusinessMenusSection(businessId)` (existing, currently unused/dead — now wired in)
3. `BusinessMealCardsSection(businessId)` (existing, moved from Genel tab)
4. Existing full-width `FilledButton.icon` "contribute menu photo" (`t.contributeMenuPhoto`) — moved here from the end of the old single scroll.

### `_BusinessReviewsTab` (new widget, `business_sections_scroll.dart`)
`ListView` containing, in order:
1. `BusinessReviewsSection(businessId)` (existing) — **modified** to remove the `.take(3)` limit (show all `latestReviews`), since this is now the dedicated reviews tab. Update the count text (`'${detail.latestReviews.length} ${t.reviewsCountSuffix}'`) accordingly — it already reflects the full list length, no change needed there, only the `.take(3)` on the `for` loop is removed.
2. `BusinessReviewPhotosSection(businessId)` (existing, moved from Genel tab)
3. `BusinessFrequentTagsSection(businessId)` (existing, moved from Genel tab)

---

## 8. New ARB Keys (TR / EN)

| Key | TR | EN |
|---|---|---|
| `businessTabGeneral` | "Genel" | "General" |
| `businessTabMenu` | "Menü" | "Menu" |
| `businessTabReviews` | "Yorumlar" | "Reviews" |
| `businessBadgeMenuVerified` | "Menü Onaylı" | "Verified Menu" |
| `businessBadgePopular` | "Popüler" | "Popular" |
| `featuredSectionTitle` | "Öne çıkanlar" | "Featured" |
| `featuredRatingLabel` | "Puan" | "Rating" |
| `featuredMenuVerifiedSubtitle` | "Sahibi tarafından güncellendi" | "Updated by the owner" |
| `popularDishesTitle` | "Popüler lezzetler" | "Popular dishes" |
| `locationHoursTitle` | "Konum ve saatler" | "Location & hours" |
| `directions` | "Yol Tarifi" | "Directions" |
| `viewMenu` | "Menüyü Gör" | "View Menu" |

Confirmed via `app_tr.arb`/`app_en.arb`: `seeAll` ("Tümünü Gör"/"See all") already exists and is reused for both "Popüler lezzetler" and "Son yorumlar" trailing links — **not** added as a new key. `directions`/`viewMenu` do not exist yet and are added as new keys.

Existing keys reused as-is: `openNow`, `closedNow`, `verified`, `recentReviews`, `reviewsCountSuffix`, `contributeMenuPhoto`, `hoursInfoMissing`, `addHoursHelp`, `reportHoursInfo`, `favoriteAdded`, `addToFavorites`, `seeAll`.

---

## 9. Files Touched

- `lib/features/business/domain/business.dart` — add `description` field (Section 2.1).
- Repository method backing `_businessProvider` (locate via `discoveryRepositoryProvider.fetchBusiness`) — confirm/add `description` to select (Section 2.2).
- `lib/features/business/ui/business_page.dart` — `DefaultTabController` wrap, remove `ContributeFab`, remove share action from `AppBar`, add `bottomNavigationBar`.
- `lib/features/business/ui/parts/business_header.dart` — `_BusinessHeroTrustHeader` overlay buttons, rating badge, `_OpenNowHeroBadge` l10n fix; new `_BusinessBadgeChipRow`, `_BusinessDescription`, `_RatingBadge`, `_FavoriteToggleButton`.
- `lib/features/business/ui/parts/business_sections_scroll.dart` — restructure into `_BusinessFixedHeader`, `_BusinessGeneralTab`, `_BusinessMenuTab`, `_BusinessReviewsTab`; new `_BusinessFeaturedSection`, `_BusinessPopularDishesSection`, `_BusinessLocationHoursSection`, `_BusinessRecentReviewsSection`, `_BusinessBottomActionBar`.
- `lib/features/business/ui/sections/business_detail_sections.dart` — `BusinessReviewsSection` remove `.take(3)` limit.
- `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb` — new keys (Section 8); regenerate via `flutter gen-l10n`.

---

## 10. Validation

Per `CLAUDE.md` minimum validation for Flutter code:
- `flutter analyze` → "No issues found!"
- `flutter test` → full suite passes (baseline: 318 passed / 4 skipped)
- `node tools/ceviri-denetimi.mjs` (run from repo root) → l10n audit passes
- Manual check: page renders correctly with all 3 tabs, tab switching works, "Tümünü gör"/"Menüyü Gör" links correctly switch tabs via `DefaultTabController`, favorite toggle stays in sync between hero overlay and bottom bar, sections with no data (no description, no trending items, no amenities, no reviews) gracefully collapse without empty gaps.

---

## 11. Open Implementation Notes (for the plan)

- No existing 2-column card-grid pattern was found in `discovery_cards.dart`; `_BusinessPopularDishesSection` (Section 5.2) uses a fresh `GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics())`.
- `_relativeTimeLabel(context, value)` (in `business_state_views.dart`) is the existing relative-date helper, reused for `_BusinessRecentReviewsSection`'s review date (Section 5.4).
- `_openDirections` (in `business_state_views.dart`) is `part of` the same library as `business_sections_scroll.dart` and `business_page.dart` — directly callable, no import needed.
- Favorite toggle: `ref.watch(isFavoritedProvider(business.id))` + `ref.read(favoritesControllerProvider.notifier).toggleFavorite(business.id)` (confirmed in `business_detail_sections.dart` `BusinessActionsSection`, lines 142/160-161).
- `dart format` all touched files after edits.
