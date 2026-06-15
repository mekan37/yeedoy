# Business Detail — Hero/Info Panel Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the business detail page (`uygulamalar/mobil/lib/features/business/ui/business_page.dart` and its parts) so the hero image holds only the overlay buttons (back/share/favorite), all business metadata moves into a new white, rounded-top `_BusinessInfoPanel` that overlaps the bottom of the hero image, the top red AppBar is removed, and the tab bar becomes a gray segmented control with a red underline on the active tab — matching the `işletmedetay.png` mockup using only real provider data already wired up in this branch.

**Architecture:** This is a delta on top of the already-shipped Phase 1 redesign (commits `cfbc153`..`ac418df`). `_BusinessHeroTrustHeader` is stripped down to image + gradient + overlay buttons (no text). A new `_BusinessInfoPanel` widget (in `business_header.dart`) renders the business name, report-flag icon, verified/rating/open-closed chips, category/location line, the existing `_BusinessBadgeChipRow`, and `_BusinessDescription` — fed by the same `Business`/`isOpenNow` data already available in `_BusinessFixedHeader`. `_BusinessFixedHeader` (in `business_sections_scroll.dart`) wires hero + panel together with a small negative top margin so the panel overlaps the image. `business_page.dart` drops `AppAppBar`, wraps the tab content in `SafeArea(bottom: false)`, and swaps the stock `TabBar` for a new `_BusinessSegmentedTabBar`. No bottom action bar is added (explicitly out of scope). No new data sources — only fields already on `Business` (`name`, `avgRating`, `reviewsCount`, `category`, `district`, `city`, `description`, `id`) and the existing `isOpenNow` bool.

**Tech Stack:** Flutter (mobile app), Riverpod, existing `AppColors`/`AppTokens`/`AppLocalizations`, `go_router`.

---

### Task 1: Strip `_BusinessHeroTrustHeader` down to image + overlay buttons

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart:1-190`

- [ ] **Step 1: Remove the title block and `isOpenNow` param from `_BusinessHeroTrustHeader`, and delete the now-unused `_OpenNowHeroBadge`**

Replace lines 1-190 of `business_header.dart` (from `part of '../business_page.dart';` through the end of the `_OpenNowHeroBadge` class) with:

```dart
part of '../business_page.dart';

class _BusinessHeroTrustHeader extends StatelessWidget {
  const _BusinessHeroTrustHeader({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radius20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              top: tokens.space12,
              left: tokens.space12,
              child: _HeroOverlayButton(
                icon: Icons.arrow_back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
              ),
            ),
            Positioned(
              top: tokens.space12,
              right: tokens.space12,
              child: Row(
                children: [
                  _HeroOverlayButton(
                    icon: Icons.share_outlined,
                    tooltip: AppLocalizations.of(context).share,
                    onPressed: () =>
                        unawaited(_shareBusiness(context, business)),
                  ),
                  SizedBox(width: tokens.space8),
                  _FavoriteToggleButton(businessId: business.id, overlay: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final remote =
        _normalizeImageUrl(
          business.heroImageUrl ??
              business.coverImageUrl ??
              business.imageUrl ??
              business.logoUrl,
        ) ??
        '';
    // Deterministic Hero tag: 'business-image-<id>'
    // Matching tag must be applied on any source widget (list card, smart feed)
    // that shows the same business image to enable the shared-element transition.
    final heroTag = 'business-image-${business.id}';
    if (remote.isNotEmpty) {
      return Hero(
        tag: heroTag,
        child: AppNetworkImage(
          url: remote,
          fit: BoxFit.cover,
          variant: AppImageVariant.medium,
        ),
      );
    }
    return Hero(
      tag: heroTag,
      child: Image.asset(
        CategoryAssets.resolve(business.category),
        fit: BoxFit.cover,
      ),
    );
  }
}
```

What changed vs. the current file:
- `_BusinessHeroTrustHeader` constructor drops `isOpenNow` (no longer used inside the hero).
- The bottom `Positioned` title block (business name, `StatusBadge`, `_OpenNowHeroBadge`, `_RatingBadge`, category/location text) is removed entirely — this content moves to `_BusinessInfoPanel` in Task 2.
- The gradient's bottom alpha is reduced from `0.65` to `0.35` since there's no text to contrast against anymore — just the top overlay buttons.
- `_OpenNowHeroBadge` class (previously lines 145-190) is deleted — its only call site was the removed title block, and its dark-overlay styling (white/green text) doesn't fit the white info panel. The open/closed state is re-rendered in `_BusinessInfoPanel` using the existing `_BadgeChip` widget instead.
- `_HeroOverlayButton`, `_FavoriteToggleButton`, `_RatingBadge`, `_BadgeChip`, `_BusinessBadgeChipRow`, `_BusinessDescription`, `_TopStatCard`, `_CommunityVerifiedCard` (previously lines 192-516) are **unchanged** — keep them as-is below the class above.

- [ ] **Step 2: Run analyzer to confirm no dangling references yet**

Run: `cd uygulamalar/mobil && flutter analyze`
Expected: New errors about `_BusinessFixedHeader` still calling `_BusinessHeroTrustHeader(business: business, isOpenNow: isOpenNow)` with an unknown named parameter `isOpenNow`, and about `_BusinessHeroTrustHeader`'s removed title block referencing `business.name`/`business.reviewsCount`/etc. being gone (these disappear in Task 3). This is expected — Task 3 fixes the call site.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
git commit -m "refactor(mobile): strip business hero header to image and overlay buttons"
```

---

### Task 2: Add `_BusinessInfoPanel`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart` (insert new class)

- [ ] **Step 1: Insert `_BusinessInfoPanel` immediately after the `_BusinessHeroTrustHeader` class (i.e. right before `_HeroOverlayButton`)**

```dart
class _BusinessInfoPanel extends StatelessWidget {
  const _BusinessInfoPanel({required this.business, this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: -tokens.radius24),
      padding: EdgeInsets.fromLTRB(
        tokens.space16,
        tokens.space16,
        tokens.space16,
        tokens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tokens.radius24),
          topRight: Radius.circular(tokens.radius24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.report,
                onPressed: () => _openReportSheet(context, business.id),
                icon: const Icon(Icons.flag_outlined, color: AppColors.muted),
              ),
            ],
          ),
          SizedBox(height: tokens.space8),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                type: StatusBadgeType.verified,
                label: t.verified,
              ),
              if (business.reviewsCount > 0)
                _BadgeChip(
                  icon: Icons.star_rounded,
                  label:
                      '${business.avgRating.toStringAsFixed(1)} (${business.reviewsCount})',
                  color: AppColors.warning,
                ),
              if (isOpenNow != null)
                _BadgeChip(
                  icon: Icons.schedule,
                  label: isOpenNow! ? t.openNow : t.closedNow,
                  color: isOpenNow! ? AppColors.success : AppColors.danger,
                ),
            ],
          ),
          SizedBox(height: tokens.space8),
          Text(
            '${business.category} · ${_locText(context, business.district, business.city)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _BusinessBadgeChipRow(business: business),
          _BusinessDescription(description: business.description),
        ],
      ),
    );
  }
}
```

Notes:
- `StatusBadge`, `StatusBadgeType`, `_BadgeChip`, `_BusinessBadgeChipRow`, `_BusinessDescription`, `_openReportSheet`, `_locText` are all pre-existing — no new imports needed (same `part of` library as the rest of `business_header.dart`).
- The rating chip reuses `_BadgeChip` (already used for "Menü Onaylı"/"Popüler") with `AppColors.warning` so the gold star has sufficient contrast against its `0.12`-alpha background (the hero's `_RatingBadge`, which renders white text for a dark overlay, is intentionally NOT reused here).
- `business.reviewsCount` and `business.avgRating` are real fields from `businesses_with_stats` (already used by the existing `_RatingBadge`/`_BusinessFeaturedSection`) — no invented data.
- The `margin: EdgeInsets.only(top: -tokens.radius24)` is what produces the "panel overlaps the bottom of the hero image with rounded top corners" effect from the mockup, without rewriting the existing `_ConstrainedContent`/padding layout that the rest of the page (and tablet/desktop breakpoints) rely on.

- [ ] **Step 2: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
git commit -m "feat(mobile): add business info panel overlapping hero image"
```

---

### Task 3: Wire `_BusinessInfoPanel` into `_BusinessFixedHeader`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart:29-57`

- [ ] **Step 1: Replace the `_BusinessFixedHeader` class**

Replace lines 29-57 (the entire `_BusinessFixedHeader` class) with:

```dart
class _BusinessFixedHeader extends StatelessWidget {
  const _BusinessFixedHeader({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _ConstrainedContent(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space16,
          tokens.space12,
          tokens.space16,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BusinessHeroTrustHeader(business: business),
            _BusinessInfoPanel(business: business, isOpenNow: isOpenNow),
          ],
        ),
      ),
    );
  }
}
```

What changed: `_BusinessHeroTrustHeader` is called without `isOpenNow` (per Task 1), and the previous direct calls to `_BusinessBadgeChipRow(business: business)` and `_BusinessDescription(description: business.description)` are removed from here — they now live inside `_BusinessInfoPanel` (Task 2), called once, not twice.

- [ ] **Step 2: Delete the now-unused `_RatingBadge` class**

`_RatingBadge` (in `business_header.dart`, immediately after `_FavoriteToggleButton` and before `_BadgeChip`) was only called from the hero title block removed in Task 1. `_BusinessInfoPanel` (Task 2) renders the rating using `_BadgeChip` instead, so `_RatingBadge` is now dead code. Delete the entire class:

```dart
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
```

Remove it entirely (including the blank line before/after, leaving exactly one blank line between `_FavoriteToggleButton` and `_BadgeChip`).

- [ ] **Step 3: Run analyzer**

Run: `cd uygulamalar/mobil && flutter analyze`
Expected: 0 issues (Tasks 1-3 together resolve the dangling references from Task 1, Step 2, and Step 2 above removes the new `_RatingBadge` unused-element warning).

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart
git commit -m "refactor(mobile): wire business info panel into fixed header"
```

---

### Task 4: Add `_BusinessSegmentedTabBar`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart` (insert new class)

- [ ] **Step 1: Insert `_BusinessSegmentedTabBar` immediately after the `_BusinessFixedHeader` class (before `_BusinessGeneralTab`)**

```dart
class _BusinessSegmentedTabBar extends StatelessWidget {
  const _BusinessSegmentedTabBar({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final controller = DefaultTabController.of(context);
    return _ConstrainedContent(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space16,
          tokens.space12,
          tokens.space16,
          tokens.space8,
        ),
        child: Container(
          padding: EdgeInsets.all(tokens.space4),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(tokens.radius12),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.animateTo(i),
                        child: AnimatedContainer(
                          duration: tokens.fast,
                          padding: EdgeInsets.symmetric(
                            vertical: tokens.space8,
                          ),
                          decoration: BoxDecoration(
                            color: controller.index == i
                                ? AppColors.card
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(tokens.radius12),
                            border: Border(
                              bottom: BorderSide(
                                color: controller.index == i
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: controller.index == i
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

Notes:
- `DefaultTabController.of(context)` returns the same non-nullable `TabController` already used elsewhere in this file (`DefaultTabController.of(context).animateTo(1)` in `_BusinessPopularDishesSection`/`_BusinessRecentReviewsSection`) — no new provider/controller wiring needed.
- `AnimatedBuilder(animation: controller, ...)` rebuilds the segmented row on every tab-index change (tap or swipe), so the active segment follows swipes too.
- Active segment = `AppColors.card` (white) background + `AppColors.primary` bottom border (2px) + `AppColors.primary` text, on a `AppColors.bg` (light gray) track — matches "gri segmented container, aktif Genel beyaz/soft yüzey + kırmızı underline, tam genişlik kırmızı pill olmayacak".

- [ ] **Step 2: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart
git commit -m "feat(mobile): add segmented tab bar for business detail tabs"
```

---

### Task 5: Remove the AppBar and swap in the segmented tab bar in `business_page.dart`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/business_page.dart`

- [ ] **Step 1: Remove the `AppAppBar` import**

In the import block near the top of the file, delete this line:

```dart
import '../../../features/shared/ui/components/app_appbar.dart';
```

(Confirmed via grep: `AppAppBar` is only referenced at the `appBar:` call site being removed in Step 2 below — no other usage in this file.)

- [ ] **Step 2: Replace the `build` method's return statement**

The current `build` method (around line 372 onward) returns:

```dart
    return AppScaffold(
      appBar: AppAppBar(
        title: Text(t.businessLabel),
        actions: [
          IconButton(
            tooltip: t.report,
            onPressed: () => _openReportSheet(context, widget.businessId),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: businessAsync.when(
        loading: () => const _BusinessLoadingView(),
        error: (error, _) => _BusinessErrorView(
          message: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(_businessProvider(widget.businessId)),
        ),
        data: (business) {
          final isOpenNow = ref.watch(
            _businessHoursProvider(business.id).select(
              (async) => async.maybeWhen(
                data: (today) => today == null
                    ? null
                    : _isOpenNow(today.open, today.close, DateTime.now()),
                orElse: () => null,
              ),
            ),
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref
                  .read(discoveryRepositoryProvider)
                  .invalidateBusiness(widget.businessId);
              ref.read(menuRepositoryProvider).clearReadCache();
              ref.invalidate(_businessProvider(widget.businessId));
              ref.invalidate(_businessHoursProvider(widget.businessId));
              ref.invalidate(businessMenusProvider(widget.businessId));
              ref.invalidate(businessCrowdProvider(widget.businessId));
              ref.invalidate(businessDetailProvider(widget.businessId));
              ref.invalidate(businessPerksProvider(widget.businessId));
              ref.invalidate(businessTrendingItemsProvider(widget.businessId));
              ref.invalidate(businessNewItemsProvider(widget.businessId));
              ref.invalidate(businessAmenitiesProvider(widget.businessId));
              ref.invalidate(
                businessMealCardProvidersProvider(widget.businessId),
              );
              ref.invalidate(businessRecentCheckinsProvider(widget.businessId));
            },
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _BusinessFixedHeader(
                    business: business,
                    isOpenNow: isOpenNow,
                  ),
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
                        _BusinessGeneralTab(
                          business: business,
                          isOpenNow: isOpenNow,
                        ),
                        _BusinessMenuTab(
                          businessId: business.id,
                          fallbackCategory: business.category,
                        ),
                        _BusinessReviewsTab(businessId: business.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
```

Replace it with:

```dart
    return AppScaffold(
      body: businessAsync.when(
        loading: () => const _BusinessLoadingView(),
        error: (error, _) => _BusinessErrorView(
          message: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(_businessProvider(widget.businessId)),
        ),
        data: (business) {
          final isOpenNow = ref.watch(
            _businessHoursProvider(business.id).select(
              (async) => async.maybeWhen(
                data: (today) => today == null
                    ? null
                    : _isOpenNow(today.open, today.close, DateTime.now()),
                orElse: () => null,
              ),
            ),
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref
                  .read(discoveryRepositoryProvider)
                  .invalidateBusiness(widget.businessId);
              ref.read(menuRepositoryProvider).clearReadCache();
              ref.invalidate(_businessProvider(widget.businessId));
              ref.invalidate(_businessHoursProvider(widget.businessId));
              ref.invalidate(businessMenusProvider(widget.businessId));
              ref.invalidate(businessCrowdProvider(widget.businessId));
              ref.invalidate(businessDetailProvider(widget.businessId));
              ref.invalidate(businessPerksProvider(widget.businessId));
              ref.invalidate(businessTrendingItemsProvider(widget.businessId));
              ref.invalidate(businessNewItemsProvider(widget.businessId));
              ref.invalidate(businessAmenitiesProvider(widget.businessId));
              ref.invalidate(
                businessMealCardProvidersProvider(widget.businessId),
              );
              ref.invalidate(businessRecentCheckinsProvider(widget.businessId));
            },
            child: SafeArea(
              bottom: false,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    _BusinessFixedHeader(
                      business: business,
                      isOpenNow: isOpenNow,
                    ),
                    _BusinessSegmentedTabBar(
                      labels: [
                        t.businessTabGeneral,
                        t.businessTabMenu,
                        t.businessTabReviews,
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _BusinessGeneralTab(
                            business: business,
                            isOpenNow: isOpenNow,
                          ),
                          _BusinessMenuTab(
                            businessId: business.id,
                            fallbackCategory: business.category,
                          ),
                          _BusinessReviewsTab(businessId: business.id),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
```

What changed:
- `appBar: AppAppBar(...)` is removed — the red top app bar is gone for this page. Back navigation is still available via the hero's `_HeroOverlayButton` (back arrow), and the report action moved into `_BusinessInfoPanel` (Task 2).
- The whole tab content is wrapped in `SafeArea(bottom: false, ...)` so the hero's overlay buttons and the info panel clear the status bar / notch now that there's no AppBar reserving that space. `bottom: false` because `AppScaffold` already renders `AppBottomNav` below `body`, which handles the bottom safe area itself.
- `TabBar(...)` is replaced with `_BusinessSegmentedTabBar(labels: [...])` from Task 4.
- `t` (`AppLocalizations.of(context)`) is still used for the three tab labels, so its declaration earlier in `build` stays as-is.

- [ ] **Step 3: Run analyzer**

Run: `cd uygulamalar/mobil && flutter analyze`
Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/business_page.dart
git commit -m "feat(mobile): remove business detail app bar and use safe-area hero layout"
```

---

### Task 6: Full validation

**Files:** none (validation only)

- [ ] **Step 1: Run Flutter analyzer**

Run: `cd uygulamalar/mobil && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run Flutter tests**

Run: `cd uygulamalar/mobil && flutter test`
Expected: all existing tests pass (no test in `uygulamalar/mobil/test` references `_BusinessHeroTrustHeader`, `_OpenNowHeroBadge`, `_BusinessFixedHeader`, `TabBar`, `BusinessPage`, or `businessLabel`, so none should need updating).

- [ ] **Step 3: Run the i18n key audit**

Run from repo root: `node tools/ceviri-denetimi.mjs`
Expected: no new missing/unused-key errors. (No ARB keys were added or removed — `businessLabel`, `report`, `verified`, `openNow`, `closedNow`, `businessTabGeneral/Menu/Reviews` etc. are all pre-existing and still referenced elsewhere.)

- [ ] **Step 4: Manual smoke check**

Run: `cd uygulamalar/mobil && flutter run -d <device>`
Navigate to any business detail page and verify:
- No red app bar at the top; hero image starts under the status bar with back/share/favorite buttons visible and tappable.
- White rounded-top panel overlaps the bottom of the hero image, showing: business name + flag (report) icon, "Doğrulanmış" badge, rating chip (if the business has reviews), open/closed chip, category · location line, menu-verified/popular chips (if applicable), description (if any).
- Tab bar below the panel is a gray rounded bar; "Genel" is active by default with a white background and red bottom border; tapping/swiping switches tabs and updates the active segment.
- "Genel" tab content (Öne çıkanlar, Popüler lezzetler, Konum ve saatler, Son yorumlar, ...) starts immediately below the tab bar with no empty gap.
- Tapping the flag icon opens the report sheet (same as before).
- Pull-to-refresh still works.

- [ ] **Step 5: Final commit (if Step 4 required fixes)**

```bash
git add -A
git commit -m "fix(mobile): address business detail redesign review feedback"
```

---

## Self-Review

**Spec coverage** (against the user's 7-point proposal):
1. ✅ Task 5 removes the AppBar — back/share/favorite stay on the hero (Task 1).
2. ✅ Task 1 strips `_BusinessHeroTrustHeader` to image + overlay buttons only.
3. ✅ Task 2 creates `_BusinessInfoPanel` inside `_BusinessFixedHeader` (Task 3).
4. ✅ Task 2's panel uses real fields: `business.name`, `business.avgRating`, `business.reviewsCount`, `business.category`, `business.district`/`business.city` (via `_locText`), `business.description`, plus the existing `isOpenNow` bool and `_businessTrustProvider`/`businessTrendingItemsProvider`-backed `_BusinessBadgeChipRow`.
5. ✅ Task 4 replaces `TabBar` with a custom gray segmented `_BusinessSegmentedTabBar`, active segment = white + red underline (not a full pill).
6. ✅ No change needed to `_BusinessGeneralTab`'s section order — Öne çıkanlar / Popüler lezzetler / Konum ve saatler / Son yorumlar already render first, immediately below the tab bar.
7. ✅ No `_BusinessBottomActionBar` exists in the current codebase and none is added — explicitly out of scope per the user.
8. ✅ Task 6 covers `flutter analyze`, `flutter test`, `node tools/ceviri-denetimi.mjs`, plus a manual smoke pass.

Report-button placement (the one open decision from the prior turn): placed as a `flag_outlined` `IconButton` in the top-right of `_BusinessInfoPanel`'s title row, reusing the existing `_openReportSheet(context, business.id)` — same function used previously by the AppBar action and by `_BusinessLocationHoursSection`/`_BusinessMenuTab`.

**Placeholder scan:** No "TBD"/"TODO"/"add appropriate ..." phrases. All steps contain complete code.

**Type consistency:** `_BusinessHeroTrustHeader({required this.business})` (Task 1) ↔ called as `_BusinessHeroTrustHeader(business: business)` (Task 3) — no `isOpenNow`. `_BusinessInfoPanel({required this.business, this.isOpenNow})` (Task 2) ↔ called as `_BusinessInfoPanel(business: business, isOpenNow: isOpenNow)` (Task 3), where `isOpenNow` is `bool?` in both `_BusinessFixedHeader` and `_BusinessInfoPanel`. `_BusinessSegmentedTabBar({required this.labels})` where `labels: List<String>` (Task 4) ↔ called with `labels: [t.businessTabGeneral, t.businessTabMenu, t.businessTabReviews]` (`List<String>`, Task 5). `_BadgeChip({required icon, required label, required color})` signature (pre-existing, unchanged) matches both new call sites in Task 2.
