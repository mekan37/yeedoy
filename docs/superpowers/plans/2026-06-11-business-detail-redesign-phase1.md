# Business Detail Page Redesign — Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the mobile Business Detail page (`uygulamalar/mobil/lib/features/business/ui/business_page.dart` + its `part` files) to match the `işletmedetay.png` mockup — hero overlay buttons, rating badge, badge chip row, description, a `Genel`/`Menü`/`Yorumlar` tab bar, new "Genel" tab sections (Öne çıkanlar, Popüler lezzetler, Konum ve saatler, Son yorumlar), and a fixed bottom action bar — while preserving all existing sections (relocated into the new tabs) using only real provider data.

**Architecture:** Pure UI/composition + a one-field extension to the `Business` model. No new Supabase tables/RPCs/SQL. All five `part` files of `business_page.dart` are compiled as a single library, so new private widgets defined in one part file are directly callable from any other part file with no imports. New ARB keys are added first so later tasks can reference the generated getters immediately.

**Tech Stack:** Flutter, Riverpod, go_router, existing design system (`AppColors`/`AppTokens`/`AppTypography`), ARB l10n (TR+EN).

**Spec:** `docs/superpowers/specs/2026-06-11-business-detail-redesign-design.md` (`_DistanceRow` / mesafe satırı excluded from this phase per user decision).

---

## Task 1: New ARB keys (TR + EN) + regenerate l10n

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb` (end of file, lines 5147-5149)
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb` (end of file, lines 5180-5182)

- [ ] **Step 1: Add new TR keys**

In `uygulamalar/mobil/lib/l10n/app_tr.arb`, the file currently ends with:

```json
  "goToMyLists": "Listelerime Git",
  "@goToMyLists": {"description": "Navigate to collab lists page"}
}
```

Replace with:

```json
  "goToMyLists": "Listelerime Git",
  "@goToMyLists": {"description": "Navigate to collab lists page"},
  "businessTabGeneral": "Genel",
  "@businessTabGeneral": {"description": "Business detail page tab: general"},
  "businessTabMenu": "Menü",
  "@businessTabMenu": {"description": "Business detail page tab: menu"},
  "businessTabReviews": "Yorumlar",
  "@businessTabReviews": {"description": "Business detail page tab: reviews"},
  "businessBadgeMenuVerified": "Menü Onaylı",
  "@businessBadgeMenuVerified": {"description": "Badge shown when the menu source is owner-verified"},
  "businessBadgePopular": "Popüler",
  "@businessBadgePopular": {"description": "Badge shown when the business has trending items"},
  "featuredSectionTitle": "Öne çıkanlar",
  "@featuredSectionTitle": {"description": "Business detail Genel tab featured section title"},
  "featuredRatingLabel": "Puan",
  "@featuredRatingLabel": {"description": "Label under the rating value in the featured section"},
  "featuredMenuVerifiedSubtitle": "Sahibi tarafından güncellendi",
  "@featuredMenuVerifiedSubtitle": {"description": "Subtitle for the verified-menu featured card"},
  "popularDishesTitle": "Popüler lezzetler",
  "@popularDishesTitle": {"description": "Business detail Genel tab popular dishes section title"},
  "locationHoursTitle": "Konum ve saatler",
  "@locationHoursTitle": {"description": "Business detail Genel tab location and hours section title"},
  "directions": "Yol Tarifi",
  "@directions": {"description": "Bottom action bar directions button"},
  "viewMenu": "Menüyü Gör",
  "@viewMenu": {"description": "Bottom action bar view menu button"}
}
```

- [ ] **Step 2: Add new EN keys**

In `uygulamalar/mobil/lib/l10n/app_en.arb`, the file currently ends with:

```json
  "goToMyLists": "Go to My Lists",
  "@goToMyLists": {"description": "Navigate to collab lists page"}
}
```

Replace with:

```json
  "goToMyLists": "Go to My Lists",
  "@goToMyLists": {"description": "Navigate to collab lists page"},
  "businessTabGeneral": "General",
  "@businessTabGeneral": {"description": "Business detail page tab: general"},
  "businessTabMenu": "Menu",
  "@businessTabMenu": {"description": "Business detail page tab: menu"},
  "businessTabReviews": "Reviews",
  "@businessTabReviews": {"description": "Business detail page tab: reviews"},
  "businessBadgeMenuVerified": "Verified Menu",
  "@businessBadgeMenuVerified": {"description": "Badge shown when the menu source is owner-verified"},
  "businessBadgePopular": "Popular",
  "@businessBadgePopular": {"description": "Badge shown when the business has trending items"},
  "featuredSectionTitle": "Featured",
  "@featuredSectionTitle": {"description": "Business detail Genel tab featured section title"},
  "featuredRatingLabel": "Rating",
  "@featuredRatingLabel": {"description": "Label under the rating value in the featured section"},
  "featuredMenuVerifiedSubtitle": "Updated by the owner",
  "@featuredMenuVerifiedSubtitle": {"description": "Subtitle for the verified-menu featured card"},
  "popularDishesTitle": "Popular dishes",
  "@popularDishesTitle": {"description": "Business detail Genel tab popular dishes section title"},
  "locationHoursTitle": "Location & hours",
  "@locationHoursTitle": {"description": "Business detail Genel tab location and hours section title"},
  "directions": "Directions",
  "@directions": {"description": "Bottom action bar directions button"},
  "viewMenu": "View Menu",
  "@viewMenu": {"description": "Bottom action bar view menu button"}
}
```

- [ ] **Step 3: Regenerate l10n**

Run from `uygulamalar/mobil/`:

```bash
flutter gen-l10n
```

Expected: completes without errors; `lib/l10n/app_localizations_tr.dart` and `lib/l10n/app_localizations_en.dart` now contain `businessTabGeneral`, `businessTabMenu`, `businessTabReviews`, `businessBadgeMenuVerified`, `businessBadgePopular`, `featuredSectionTitle`, `featuredRatingLabel`, `featuredMenuVerifiedSubtitle`, `popularDishesTitle`, `locationHoursTitle`, `directions`, `viewMenu` getters.

- [ ] **Step 4: Run l10n audit**

Run from repo root:

```bash
node tools/ceviri-denetimi.mjs
```

Expected: passes (no missing/unused key errors).

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/l10n/app_tr.arb uygulamalar/mobil/lib/l10n/app_en.arb uygulamalar/mobil/lib/l10n/app_localizations.dart uygulamalar/mobil/lib/l10n/app_localizations_tr.dart uygulamalar/mobil/lib/l10n/app_localizations_en.dart
git commit -m "feat(mobile): add ARB keys for business detail redesign"
```

---

## Task 2: `Business.description` field

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/domain/business.dart`

- [ ] **Step 1: Add `description` field to constructor, field list, `fromMap`, `toMap`**

Current file (90 lines). Apply these four edits:

Edit 1 — constructor (after `this.avgRating = 0,`):

```dart
    this.reviewsCount = 0,
    this.avgRating = 0,
    this.description,
  });
```

Edit 2 — field declarations (after `final double avgRating;`):

```dart
  final int reviewsCount;
  final double avgRating;
  final String? description;
```

Edit 3 — `fromMap` (after `avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,`):

```dart
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
    description: m['description'] as String?,
  );
```

Edit 4 — `toMap` (after `'avg_rating': avgRating,`):

```dart
    'reviews_count': reviewsCount,
    'avg_rating': avgRating,
    'description': description,
  };
```

- [ ] **Step 2: Confirm `fetchBusiness` already returns `description`**

`uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart:191-195` calls:

```dart
final res = await client
    .from('businesses_with_stats')
    .select()
    .eq('id', id)
    .single();
return Business.fromMap(res);
```

`select()` with no arguments selects all columns (`select('*')`), and `description` is already a column on the `businesses_with_stats` view. **No change needed to this file** — `Business.fromMap` (Step 1, Edit 3) now reads it.

- [ ] **Step 3: Verify**

Run from `uygulamalar/mobil/`:

```bash
flutter analyze lib/features/business/domain/business.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/domain/business.dart
git commit -m "feat(mobile): expose business.description from businesses_with_stats"
```

---

## Task 3: Header restyle — `business_header.dart`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart`

This file is `part of '../business_page.dart'` — all imports from `business_page.dart` (including `AppColors`, `AppTokens`, `AppLocalizations`, `Hero`, `userProvider`, `isFavoritedProvider`, `favoritesControllerProvider`, `showQuickLoginSheet`, `AppErrorMapper`, `HapticFeedback`, `unawaited`, `_shareBusiness`) are already in scope.

- [ ] **Step 1: Fix `_OpenNowHeroBadge` hardcoded strings (line 148)**

Current:

```dart
          Text(
            isOpen ? 'Açık' : 'Kapalı',
            style: TextStyle(
```

Replace with:

```dart
          Text(
            isOpen ? AppLocalizations.of(context).openNow : AppLocalizations.of(context).closedNow,
            style: TextStyle(
```

- [ ] **Step 2: Add hero overlay buttons (back / share / favorite)**

In `_BusinessHeroTrustHeader.build`, the `Stack`'s `children` currently are:

```dart
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
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: tokens.space16,
```

Insert two new `Positioned` overlay widgets between the gradient `DecoratedBox` and the existing bottom `Positioned`:

```dart
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
                    Colors.black.withValues(alpha: 0.65),
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
                    onPressed: () => unawaited(_shareBusiness(context, business)),
                  ),
                  SizedBox(width: tokens.space8),
                  _FavoriteToggleButton(businessId: business.id, overlay: true),
                ],
              ),
            ),
            Positioned(
              left: tokens.space16,
```

- [ ] **Step 3: Add rating badge to the title row**

In `_BusinessHeroTrustHeader.build`, the title `Row` currently is:

```dart
                  Row(
                    children: [
                      StatusBadge(
                        type: StatusBadgeType.verified,
                        label: AppLocalizations.of(context).verified,
                      ),
                      if (isOpenNow != null) ...[
                        const SizedBox(width: 8),
                        _OpenNowHeroBadge(isOpen: isOpenNow!),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
```

Replace with (adds `_RatingBadge` before the spacer/category text, only when `business.reviewsCount > 0`):

```dart
                  Row(
                    children: [
                      StatusBadge(
                        type: StatusBadgeType.verified,
                        label: AppLocalizations.of(context).verified,
                      ),
                      if (isOpenNow != null) ...[
                        const SizedBox(width: 8),
                        _OpenNowHeroBadge(isOpen: isOpenNow!),
                      ],
                      if (business.reviewsCount > 0) ...[
                        const SizedBox(width: 8),
                        _RatingBadge(rating: business.avgRating),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
```

- [ ] **Step 4: Append new private widgets at end of file**

Add after the closing brace of `_CommunityVerifiedCard` (end of file):

```dart

class _HeroOverlayButton extends StatelessWidget {
  const _HeroOverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _FavoriteToggleButton extends ConsumerWidget {
  const _FavoriteToggleButton({required this.businessId, this.overlay = false});

  final String businessId;
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(businessId));
    final tooltip = isFavorited ? t.favoriteAdded : t.addToFavorites;
    final icon = isFavorited ? Icons.favorite : Icons.favorite_border;

    Future<void> handleToggle() async {
      if (!isLoggedIn) {
        await showQuickLoginSheet(context, redirectPath: '/b/$businessId');
        return;
      }
      try {
        HapticFeedback.lightImpact();
        await ref.read(favoritesControllerProvider.notifier).toggleFavorite(businessId);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMapper.message(error))),
        );
      }
    }

    if (overlay) {
      return _HeroOverlayButton(
        icon: icon,
        tooltip: tooltip,
        iconColor: isFavorited ? AppColors.danger : Colors.white,
        onPressed: () => unawaited(handleToggle()),
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: () => unawaited(handleToggle()),
      icon: Icon(icon, color: isFavorited ? AppColors.primary : AppColors.text),
    );
  }
}

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

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _BusinessBadgeChipRow extends ConsumerWidget {
  const _BusinessBadgeChipRow({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(business.id));
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));

    final showMenuVerified = trustAsync.value?.menuSource == 'owner';
    final showPopular = trendingAsync.value?.isNotEmpty ?? false;

    if (!showMenuVerified && !showPopular) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: tokens.space12),
      child: Wrap(
        spacing: tokens.space8,
        runSpacing: tokens.space8,
        children: [
          if (showMenuVerified)
            _BadgeChip(
              icon: Icons.verified_outlined,
              label: t.businessBadgeMenuVerified,
              color: AppColors.success,
            ),
          if (showPopular)
            _BadgeChip(
              icon: Icons.local_fire_department_outlined,
              label: t.businessBadgePopular,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}

class _BusinessDescription extends StatelessWidget {
  const _BusinessDescription({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.space12),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.4),
      ),
    );
  }
}
```

- [ ] **Step 5: `dart format`**

```bash
dart format uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
```

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/parts/business_header.dart
git commit -m "feat(mobile): restyle business hero header with overlay buttons, rating badge, badge chips, description"
```

> Note: `_BusinessBadgeChipRow`, `_BusinessDescription`, `_RatingBadge` are not yet referenced anywhere after this task — `flutter analyze` may report `unused_element` warnings (not errors) until Task 4 wires them into `_BusinessFixedHeader`. This is expected and resolved by Task 7's final analyze.

---

## Task 4: Restructure `business_sections_scroll.dart` — tabs, fixed header, new sections, bottom bar

**Files:**
- Rewrite: `uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart` (currently 149 lines)
- Modify: `uygulamalar/mobil/lib/features/business/ui/business_page.dart` — add one import (Step 2)

- [ ] **Step 1: Add `BusinessTrendingItem` import to `business_page.dart`**

`business_sections_scroll.dart` will declare a field of type `BusinessTrendingItem`. That type is defined in `lib/features/business/domain/business_trending_item.dart` but only `business_trending_provider.dart` (which doesn't export it) is currently imported by `business_page.dart`. Add the import.

In `uygulamalar/mobil/lib/features/business/ui/business_page.dart`, current line 43:

```dart
import '../domain/business_trending_provider.dart';
```

Replace with:

```dart
import '../domain/business_trending_provider.dart';
import '../domain/business_trending_item.dart';
```

- [ ] **Step 2: Rewrite `business_sections_scroll.dart`**

Replace the entire file content with:

```dart
part of '../business_page.dart';

/// Constrains content to the same max-width breakpoints used across the
/// fixed header and all three tabs (1040px wide / 720px medium / full narrow).
class _ConstrainedContent extends StatelessWidget {
  const _ConstrainedContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1040
            ? 1040.0
            : (constraints.maxWidth >= 720 ? 720.0 : constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

class _BusinessFixedHeader extends StatelessWidget {
  const _BusinessFixedHeader({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _ConstrainedContent(
      child: Padding(
        padding: EdgeInsets.fromLTRB(tokens.space16, tokens.space12, tokens.space16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BusinessHeroTrustHeader(business: business, isOpenNow: isOpenNow),
            _BusinessBadgeChipRow(business: business),
            _BusinessDescription(description: business.description),
          ],
        ),
      ),
    );
  }
}

class _BusinessGeneralTab extends ConsumerWidget {
  const _BusinessGeneralTab({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    final trustAsync = ref.watch(_businessTrustProvider(business.id));

    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          _BusinessFeaturedSection(business: business),
          _BusinessPopularDishesSection(business: business),
          _BusinessLocationHoursSection(business: business, isOpenNow: isOpenNow),
          _BusinessRecentReviewsSection(businessId: business.id),
          _BusinessPresenceBadge(businessId: business.id),
          const WeatherHintBar(compact: true),
          SizedBox(height: tokens.space16),
          trustAsync.when(
            loading: () => const AppSkeletonCard(),
            error: (error, _) => AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.trustDataUnavailable,
              description:
                  '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
              ctaLabel: AppLocalizations.of(context).retry,
              onCta: () => ref.invalidate(_businessTrustProvider(business.id)),
            ),
            data: (trust) {
              final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));
              final topPriceCents = trendingAsync.maybeWhen(
                data: (items) => items.isEmpty ? null : items.first.priceCents,
                orElse: () => null,
              );
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TopStatCard(
                          title: t.communityScoreDataTrustLabel,
                          value: '${trust.trustScore}',
                          subtitle: '%',
                          icon: Icons.shield_rounded,
                          circleValue: trust.trustScore / 100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TopStatCard(
                          title: t.lastUpdated,
                          value: _relativeTimeLabel(context, trust.menuUpdatedAt),
                          subtitle: '',
                          icon: Icons.history_toggle_off_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TopStatCard(
                          title: t.avgCost,
                          value: _formatPriceWithCurrency(context, topPriceCents, '?'),
                          subtitle: '',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.space16),
                  const CommunityScoreGuideCard(
                    kind: CommunityScoreKind.dataTrust,
                    margin: EdgeInsets.zero,
                  ),
                  SizedBox(height: tokens.space16),
                  _CommunityVerifiedCard(
                    usersToday: trust.lastPriceVerifiedPeople <= 0
                        ? 12
                        : trust.lastPriceVerifiedPeople,
                  ),
                  SizedBox(height: tokens.space16),
                  _PriceHistorySection(points: trust.priceChanges3m),
                ],
              );
            },
          ),
          SizedBox(height: tokens.space16),
          BusinessPerksSection(
            businessId: business.id,
            businessName: business.name,
          ),
        ],
      ),
    );
  }
}

class _BusinessMenuTab extends StatelessWidget {
  const _BusinessMenuTab({required this.businessId, required this.fallbackCategory});

  final String businessId;
  final String fallbackCategory;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          _BusinessMenuPreviewSection(
            businessId: businessId,
            fallbackCategory: fallbackCategory,
          ),
          SizedBox(height: tokens.space16),
          BusinessMenusSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessMealCardsSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openReportSheet(context, businessId),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(t.contributeMenuPhoto),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessReviewsTab extends StatelessWidget {
  const _BusinessReviewsTab({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          BusinessReviewsSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessReviewPhotosSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessFrequentTagsSection(businessId: businessId),
        ],
      ),
    );
  }
}

class _BusinessBottomActionBar extends StatelessWidget {
  const _BusinessBottomActionBar({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space16,
            vertical: tokens.space12,
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => unawaited(_openDirections(
                  businessName: business.name,
                  address: business.address,
                  lat: business.lat,
                  lng: business.lng,
                )),
                icon: const Icon(Icons.directions_outlined),
                label: Text(t.directions),
              ),
              SizedBox(width: tokens.space8),
              Expanded(
                child: FilledButton(
                  onPressed: () => DefaultTabController.of(context).animateTo(1),
                  child: Text(t.viewMenu),
                ),
              ),
              SizedBox(width: tokens.space8),
              _FavoriteToggleButton(businessId: business.id),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps a `business_amenities` row's `key` (plain snake_case string, e.g.
/// `'kids_area'`) to a presentational Material icon. The label shown to the
/// user is always `amenity.label` from the database — this only selects the
/// glyph.
IconData _amenityIconFor(String key) {
  switch (key) {
    case 'kids_area':
      return Icons.child_care_outlined;
    case 'parking':
      return Icons.local_parking_outlined;
    case 'wifi':
      return Icons.wifi;
    case 'pet_friendly':
      return Icons.pets_outlined;
    case 'smoking_area':
      return Icons.smoking_rooms_outlined;
    case 'outdoor_seating':
      return Icons.deck_outlined;
    case 'alcohol':
      return Icons.local_bar_outlined;
    case 'delivery':
      return Icons.delivery_dining_outlined;
    case 'takeaway':
      return Icons.takeout_dining_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.icon, required this.title, this.subtitle = ''});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
      child: Container(
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: AppColors.primary, size: 18)),
            ),
            SizedBox(height: tokens.space8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BusinessFeaturedSection extends ConsumerWidget {
  const _BusinessFeaturedSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final amenitiesAsync = ref.watch(businessAmenitiesProvider(business.id));
    final trustAsync = ref.watch(_businessTrustProvider(business.id));

    final cards = <Widget>[];

    if (business.avgRating > 0) {
      cards.add(_FeaturedCard(
        icon: Icons.star_rounded,
        title: business.avgRating.toStringAsFixed(1),
        subtitle: t.featuredRatingLabel,
      ));
    }

    final amenities = amenitiesAsync.value ?? const [];
    for (final amenity in amenities) {
      if (amenity.key == 'kids_area') {
        cards.add(_FeaturedCard(
          icon: _amenityIconFor(amenity.key),
          title: amenity.label,
        ));
        break;
      }
    }

    if (trustAsync.value?.menuSource == 'owner') {
      cards.add(_FeaturedCard(
        icon: Icons.verified_outlined,
        title: t.businessBadgeMenuVerified,
        subtitle: t.featuredMenuVerifiedSubtitle,
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.featuredSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: tokens.space8),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            children: cards,
          ),
        ],
      ),
    );
  }
}

class _PopularDishCard extends StatelessWidget {
  const _PopularDishCard({required this.item, required this.fallbackCategory});

  final BusinessTrendingItem item;
  final String fallbackCategory;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final remoteUrl = _normalizeImageUrl(item.imageUrl);
    return Container(
      padding: EdgeInsets.all(tokens.space8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(tokens.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: remoteUrl != null
                  ? AppNetworkImage(
                      url: remoteUrl,
                      fit: BoxFit.cover,
                      variant: AppImageVariant.thumb,
                    )
                  : Image.asset(CategoryAssets.resolve(fallbackCategory), fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: tokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPriceWithCurrency(context, item.priceCents, item.currency),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPopularDishesSection extends ConsumerWidget {
  const _BusinessPopularDishesSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));
    final items = trendingAsync.value ?? const <BusinessTrendingItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final shown = items.take(4).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.popularDishesTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                child: Text(t.seeAll),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: tokens.space8,
            crossAxisSpacing: tokens.space8,
            childAspectRatio: 2.4,
            children: [
              for (final item in shown)
                _PopularDishCard(item: item, fallbackCategory: business.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationHoursCard extends StatelessWidget {
  const _LocationHoursCard({
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radius16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            SizedBox(width: tokens.space8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BusinessLocationHoursSection extends ConsumerWidget {
  const _BusinessLocationHoursSection({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final hoursAsync = ref.watch(_businessHoursProvider(business.id));

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.locationHoursTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: tokens.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LocationHoursCard(
                  icon: Icons.location_on_outlined,
                  text: business.address?.trim().isNotEmpty == true
                      ? business.address!
                      : _locText(context, business.district, business.city),
                  onTap: () => unawaited(_openDirections(
                    businessName: business.name,
                    address: business.address,
                    lat: business.lat,
                    lng: business.lng,
                  )),
                ),
              ),
              SizedBox(width: tokens.space8),
              Expanded(
                child: hoursAsync.when(
                  loading: () => _LocationHoursCard(
                    icon: Icons.schedule_outlined,
                    text: t.noHoursInfo,
                    onTap: null,
                  ),
                  error: (_, __) => _LocationHoursCard(
                    icon: Icons.schedule_outlined,
                    text: t.hoursInfoMissing,
                    onTap: () => _openReportSheet(context, business.id),
                  ),
                  data: (today) {
                    if (today == null) {
                      return _LocationHoursCard(
                        icon: Icons.schedule_outlined,
                        text: t.hoursInfoMissing,
                        onTap: () => _openReportSheet(context, business.id),
                      );
                    }
                    final statusLabel = isOpenNow == true ? t.openNow : t.closedNow;
                    return _LocationHoursCard(
                      icon: Icons.schedule,
                      iconColor: isOpenNow == true ? AppColors.success : AppColors.danger,
                      text: '$statusLabel · ${_hoursText(context, today.open, today.close)}',
                      onTap: () => _openReportSheet(context, business.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessRecentReviewsSection extends ConsumerWidget {
  const _BusinessRecentReviewsSection({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final detailAsync = ref.watch(businessDetailProvider(businessId));
    final reviews = detailAsync.value?.latestReviews ?? const [];
    if (reviews.isEmpty) return const SizedBox.shrink();
    final review = reviews.first;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.recentReviews,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                child: Text(t.seeAll),
              ),
            ],
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                    const SizedBox(width: 4),
                    Text('${review.rating}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTimeLabel(context, review.createdAt),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space8),
                Text(review.content, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: `ReviewPreview.createdAt` (`lib/features/business/domain/business_detail.dart:102`) is non-nullable `DateTime`, and `_relativeTimeLabel(context, value)` (`business_state_views.dart:296`) accepts `DateTime?` — passing a non-null `DateTime` is valid.

- [ ] **Step 3: `dart format`**

```bash
dart format uygulamalar/mobil/lib/features/business/ui/business_page.dart uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart
```

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/business_page.dart uygulamalar/mobil/lib/features/business/ui/parts/business_sections_scroll.dart
git commit -m "feat(mobile): restructure business detail into Genel/Menu/Reviews tabs with new sections"
```

> Note: `_BusinessFixedHeader`, `_BusinessGeneralTab`, `_BusinessMenuTab`, `_BusinessReviewsTab`, `_BusinessBottomActionBar` are not yet referenced by `BusinessPage` until Task 5. `flutter analyze` may report `unused_element` warnings until then — resolved in Task 7.

---

## Task 5: `business_page.dart` — tab controller wrap, bottom bar, remove FAB/share action

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/business_page.dart`

- [ ] **Step 1: Remove `ContributeFab` import**

Current line 48:

```dart
import '../../contribute/ui/contribute_entry.dart';
```

Delete this line entirely.

- [ ] **Step 2: Replace `_BusinessPageState.build`**

Current (lines 371-427):

```dart
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final businessAsync = ref.watch(_businessProvider(widget.businessId));

    return AppScaffold(
      floatingActionButton: ContributeFab(businessId: widget.businessId),
      appBar: AppAppBar(
        title: Text(t.businessLabel),
        actions: [
          businessAsync.maybeWhen(
            data: (business) => IconButton(
              tooltip: t.share,
              onPressed: () => _shareBusiness(context, business),
              icon: const Icon(Icons.share_outlined),
            ),
            orElse: SizedBox.shrink,
          ),
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
        data: (business) => RefreshIndicator(
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
          child: _BusinessSectionsScroll(business: business),
        ),
      ),
    );
  }
}
```

Replace with:

```dart
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final businessAsync = ref.watch(_businessProvider(widget.businessId));

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
      bottomNavigationBar: businessAsync.maybeWhen(
        data: (business) => _BusinessBottomActionBar(business: business),
        orElse: () => null,
      ),
      body: businessAsync.when(
        loading: () => const _BusinessLoadingView(),
        error: (error, _) => _BusinessErrorView(
          message: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(_businessProvider(widget.businessId)),
        ),
        data: (business) {
          final isOpenNow = ref.watch(
            _businessHoursProvider(business.id).select((async) => async.maybeWhen(
                  data: (today) => today == null
                      ? null
                      : _isOpenNow(today.open, today.close, DateTime.now()),
                  orElse: () => null,
                )),
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
  }
}
```

`_shareBusiness` remains used (called from the hero overlay share button added in Task 3, Step 2).

- [ ] **Step 3: `dart format`**

```bash
dart format uygulamalar/mobil/lib/features/business/ui/business_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/business_page.dart
git commit -m "feat(mobile): wrap business detail in tab controller, add bottom action bar, remove contribute FAB"
```

---

## Task 6: Remove `.take(3)` limit in `BusinessReviewsSection`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart:520`

- [ ] **Step 1: Edit**

Current (line 520):

```dart
              for (final review in detail.latestReviews.take(3))
```

Replace with:

```dart
              for (final review in detail.latestReviews)
```

The count text on line 516 (`'${detail.latestReviews.length} ${t.reviewsCountSuffix}'`) already reflects the full list length — no further change needed.

- [ ] **Step 2: `dart format`**

```bash
dart format uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart
```

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/business/ui/sections/business_detail_sections.dart
git commit -m "feat(mobile): show all reviews in business Yorumlar tab"
```

---

## Task 7: Final validation

**Files:** none (verification only)

- [ ] **Step 1: `flutter analyze`**

Run from `uygulamalar/mobil/`:

```bash
flutter analyze
```

Expected: `No issues found!` — no `unused_element` warnings remain (all new private widgets from Tasks 3-4 are now wired into `BusinessPage` via Task 5).

- [ ] **Step 2: `flutter test`**

Run from `uygulamalar/mobil/`:

```bash
flutter test
```

Expected: same pass count as baseline (318 passed / 4 skipped) or higher — no new failures. If any business-detail-related widget test references removed widgets (`_BusinessSectionsScroll`, `ContributeFab` on this page) or the old single-scroll layout, fix the test to match the new tab structure.

- [ ] **Step 3: l10n audit**

Run from repo root:

```bash
node tools/ceviri-denetimi.mjs
```

Expected: passes.

- [ ] **Step 4: Manual check (per spec Section 10)**

Run the app (`flutter run -d <device>`) and open any business detail page (`/b/<id>`):
- Hero shows back/share/favorite overlay buttons; favorite toggle stays in sync between hero overlay and bottom bar.
- Rating badge shows only when `reviewsCount > 0`.
- "Açık"/"Kapalı" badge renders via l10n (not hardcoded).
- Badge chip row shows "Menü Onaylı"/"Popüler" only when applicable, collapses to nothing otherwise.
- Description renders only when `business.description` is non-empty.
- `Genel`/`Menü`/`Yorumlar` tabs render and switch correctly.
- "Tümünü gör" links in Popüler lezzetler / Son yorumlar switch to Menü / Yorumlar tabs respectively.
- "Menüyü Gör" bottom button switches to Menü tab; "Yol Tarifi" opens maps.
- Sections with no data (no description, no trending items, no kids_area amenity, no reviews) collapse without empty gaps.
- Yorumlar tab shows all reviews (not capped at 3).

- [ ] **Step 5: Final commit (if Step 2 required test fixes)**

```bash
git add -A
git commit -m "test(mobile): update business detail tests for tab redesign"
```

(Skip if no test changes were needed.)
