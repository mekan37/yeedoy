# Keşfet (Discovery) Sayfası Üst Bölüm Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the top section of the mobile Discovery page's premium layout (`_buildPremiumDiscoveryLayout`) to match the approved mockup: personalized greeting header, hybrid circular category chips with a "Featured" entry, a horizontal "Discover for you" business card, and a promo banner that opens the existing "What should I eat?" sheet.

**Architecture:** Pure Flutter UI work inside `uygulamalar/mobil/lib/features/discovery/`. One small shared-widget extraction (open/price badges) to avoid duplicating logic that already exists in `BusinessTile`. No backend/RPC/data-model changes — all data comes from existing providers (`BusinessCardModel`, `discoveryHomeCategories`, `userProvider` + `publicProfileProvider`).

**Tech Stack:** Flutter, Riverpod, `font_awesome_flutter` (already a dependency), existing `AppColors`/`AppTokens`/`AppTypography` design system, ARB-based l10n with `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-06-10-discovery-redesign-design.md`

---

## Task 1: Add new l10n keys

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb`
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb`

- [ ] **Step 1: Add 5 new keys to `app_tr.arb`**

In `uygulamalar/mobil/lib/l10n/app_tr.arb`, find this existing block (around line 444):

```json
  "nearbyVerifiedSpots": "Yakınındaki Mekanlar",
  "@nearbyVerifiedSpots": {
    "description": "Auto metadata for nearbyVerifiedSpots"
  },
```

Insert the following block immediately **after** it (before `"noNearbyVerifiedSpots"`):

```json
  "discoverForYou": "Senin için keşfet",
  "@discoverForYou": {
    "description": "Auto metadata for discoverForYou"
  },
  "discoveryGreetingHello": "Merhaba {name} 👋",
  "@discoveryGreetingHello": {
    "description": "Auto metadata for discoveryGreetingHello",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  },
  "discoveryGreetingHelloAnon": "Merhaba 👋",
  "@discoveryGreetingHelloAnon": {
    "description": "Auto metadata for discoveryGreetingHelloAnon"
  },
  "discoveryGreetingSubtitle": "Bugün ne yemek istersin?",
  "@discoveryGreetingSubtitle": {
    "description": "Auto metadata for discoveryGreetingSubtitle"
  },
  "discoveryFeaturedCategory": "Öne Çıkanlar",
  "@discoveryFeaturedCategory": {
    "description": "Auto metadata for discoveryFeaturedCategory"
  },
```

- [ ] **Step 2: Add the same 5 keys (English values) to `app_en.arb`**

In `uygulamalar/mobil/lib/l10n/app_en.arb`, find the matching block (around line 444):

```json
  "nearbyVerifiedSpots": "Nearby Verified Spots",
  "@nearbyVerifiedSpots": {
    "description": "Auto metadata for nearbyVerifiedSpots"
  },
```

Insert immediately after it:

```json
  "discoverForYou": "Discover for you",
  "@discoverForYou": {
    "description": "Auto metadata for discoverForYou"
  },
  "discoveryGreetingHello": "Hi {name} 👋",
  "@discoveryGreetingHello": {
    "description": "Auto metadata for discoveryGreetingHello",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  },
  "discoveryGreetingHelloAnon": "Hi 👋",
  "@discoveryGreetingHelloAnon": {
    "description": "Auto metadata for discoveryGreetingHelloAnon"
  },
  "discoveryGreetingSubtitle": "What do you feel like eating today?",
  "@discoveryGreetingSubtitle": {
    "description": "Auto metadata for discoveryGreetingSubtitle"
  },
  "discoveryFeaturedCategory": "Featured",
  "@discoveryFeaturedCategory": {
    "description": "Auto metadata for discoveryFeaturedCategory"
  },
```

- [ ] **Step 3: Regenerate generated localization files**

Run from `uygulamalar/mobil`:

```bash
flutter gen-l10n
```

Expected: regenerates `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart` with new getters `discoverForYou`, `discoveryGreetingHello(name)`, `discoveryGreetingHelloAnon`, `discoveryGreetingSubtitle`, `discoveryFeaturedCategory`. Command exits 0 with no errors.

- [ ] **Step 4: Run i18n audit**

Run from repo root (`C:\yeedoy`):

```bash
node tools/ceviri-denetimi.mjs
```

Expected: passes with no missing/orphaned key errors for the 5 new keys.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/l10n/app_tr.arb uygulamalar/mobil/lib/l10n/app_en.arb uygulamalar/mobil/lib/l10n/app_localizations.dart uygulamalar/mobil/lib/l10n/app_localizations_en.dart uygulamalar/mobil/lib/l10n/app_localizations_tr.dart
git commit -m "feat(mobile): add l10n keys for discovery redesign"
```

---

## Task 2: Extract shared open/price-level badge widgets

`BusinessTile` already has private `_OpenStatusBadge`, `_PriceLevelBadge` widgets and a private static `_priceLevelBadge()` helper (`uygulamalar/mobil/lib/features/shared/ui/business_tile.dart:73-88, 313-382`). The new horizontal "Discover for you" card needs the same badges. Per CLAUDE.md ("don't write a fourth copy"), extract them to a shared file and have `BusinessTile` use the shared version.

**Files:**
- Create: `uygulamalar/mobil/lib/features/shared/ui/components/open_price_badge.dart`
- Modify: `uygulamalar/mobil/lib/features/shared/ui/business_tile.dart`
- Test: `uygulamalar/mobil/test/features/shared/ui/components/open_price_badge_test.dart`

- [ ] **Step 1: Write the failing test for `priceLevelSymbol()`**

Create `uygulamalar/mobil/test/features/shared/ui/components/open_price_badge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/shared/ui/components/open_price_badge.dart';

void main() {
  group('priceLevelSymbol', () {
    test('returns ₺ for budget priceLevel regardless of cents', () {
      expect(priceLevelSymbol('budget', 99999), '₺');
    });

    test('returns ₺₺ for mid priceLevel', () {
      expect(priceLevelSymbol('mid', null), '₺₺');
    });

    test('returns ₺₺₺ for premium priceLevel', () {
      expect(priceLevelSymbol('premium', 1000), '₺₺₺');
    });

    test('falls back to cents thresholds when priceLevel is null', () {
      expect(priceLevelSymbol(null, 15000), '₺');
      expect(priceLevelSymbol(null, 30000), '₺₺');
      expect(priceLevelSymbol(null, 50000), '₺₺₺');
    });

    test('returns null when priceLevel and cents are both absent', () {
      expect(priceLevelSymbol(null, null), isNull);
      expect(priceLevelSymbol(null, 0), isNull);
    });

    test('falls back to cents when priceLevel is unrecognised', () {
      expect(priceLevelSymbol('unknown', 15000), '₺');
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `uygulamalar/mobil`:

```bash
flutter test test/features/shared/ui/components/open_price_badge_test.dart
```

Expected: FAIL — `Error: Couldn't resolve the package 'yeedoy/features/shared/ui/components/open_price_badge.dart'` (file does not exist yet).

- [ ] **Step 3: Create the shared badge file**

Create `uygulamalar/mobil/lib/features/shared/ui/components/open_price_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';

/// Returns a ₺ symbol string for the price badge.
///
/// [priceLevel] (DB column) is checked first:
///   'budget' → ₺, 'mid' → ₺₺, 'premium' → ₺₺₺
///
/// Falls back to threshold-based mapping from [cents] (kurus, 1/100 TL)
/// when [priceLevel] is null or unrecognised:
///   < 20 000 → ₺ (< 200 TL), < 45 000 → ₺₺ (200–450 TL), else → ₺₺₺
///
/// Returns null when both inputs are absent/zero — badge is hidden.
String? priceLevelSymbol(String? priceLevel, int? cents) {
  switch (priceLevel) {
    case 'budget':
      return '₺';
    case 'mid':
      return '₺₺';
    case 'premium':
      return '₺₺₺';
    default:
      break;
  }
  if (cents == null || cents <= 0) return null;
  if (cents < 20000) return '₺';
  if (cents < 45000) return '₺₺';
  return '₺₺₺';
}

/// Shows "Açık" (green dot) or "Kapalı" (grey dot).
/// Rendered only when [isOpen] is known — caller guards with a null check
/// on the source `isOpenNow` field.
class OpenStatusBadge extends StatelessWidget {
  const OpenStatusBadge({super.key, required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = isOpen ? AppColors.success : AppColors.muted;
    final label = isOpen ? t.openNow : t.closedNow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows ₺ / ₺₺ / ₺₺₺ price level symbol.
class PriceLevelBadge extends StatelessWidget {
  const PriceLevelBadge({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A compact horizontal row that shows open/closed status and price level
/// badges side by side. Each badge is independently nullable — if both are
/// absent the row renders nothing (caller guards before placing this widget).
class OpenPriceBadgeRow extends StatelessWidget {
  const OpenPriceBadgeRow({
    super.key,
    required this.isOpenNow,
    required this.priceLevelSymbol,
  });

  final bool? isOpenNow;
  final String? priceLevelSymbol;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isOpenNow != null) OpenStatusBadge(isOpen: isOpenNow!),
        if (priceLevelSymbol != null) PriceLevelBadge(symbol: priceLevelSymbol!),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/features/shared/ui/components/open_price_badge_test.dart
```

Expected: PASS (6 tests).

- [ ] **Step 5: Refactor `business_tile.dart` to use the shared widgets**

In `uygulamalar/mobil/lib/features/shared/ui/business_tile.dart`:

1. Add import near the top (after the existing relative imports, e.g. after the `colors.dart` import on line 3):

```dart
import 'components/open_price_badge.dart';
```

2. Delete the private static method `_priceLevelBadge` (lines 63-88, the doc comment + method body).

3. Replace the two call sites that reference `_priceLevelBadge(priceLevel, medianPriceCents)` (lines 214, 217) with `priceLevelSymbol(priceLevel, medianPriceCents)`:

```dart
                if (isOpenNow != null || priceLevelSymbol(priceLevel, medianPriceCents) != null) ...[
                  _OpenPriceBadgeRow(
                    isOpenNow: isOpenNow,
                    priceLevelSymbol: priceLevelSymbol(priceLevel, medianPriceCents),
                  ),
                  const SizedBox(height: 6),
                ],
```

4. Delete the entire private `_OpenPriceBadgeRow` class (lines 285-309 in the original file — the class with doc comment "A compact horizontal row...").

5. Replace the reference to `_OpenPriceBadgeRow` used in step 3 with `OpenPriceBadgeRow` (the shared one) — i.e. the snippet above already uses `_OpenPriceBadgeRow`; change it to `OpenPriceBadgeRow`:

```dart
                if (isOpenNow != null || priceLevelSymbol(priceLevel, medianPriceCents) != null) ...[
                  OpenPriceBadgeRow(
                    isOpenNow: isOpenNow,
                    priceLevelSymbol: priceLevelSymbol(priceLevel, medianPriceCents),
                  ),
                  const SizedBox(height: 6),
                ],
```

6. Delete the entire private `_OpenStatusBadge` class (the original lines 313-354, doc comment "Shows 'Acik'...").

7. Delete the entire private `_PriceLevelBadge` class (the original lines 357-382, doc comment "Shows ₺ / ₺₺ / ₺₺₺...").

After this refactor, `business_tile.dart` should contain: the `BusinessTile` class (using `priceLevelSymbol` and `OpenPriceBadgeRow` from the new import) and nothing else below it — all three private badge classes and the private helper are gone.

- [ ] **Step 6: Verify no regressions**

Run from `uygulamalar/mobil`:

```bash
flutter analyze
flutter test test/features/shared/ui/components/open_price_badge_test.dart
```

Expected: `flutter analyze` reports no new issues; the badge test still passes.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/mobil/lib/features/shared/ui/components/open_price_badge.dart uygulamalar/mobil/lib/features/shared/ui/business_tile.dart uygulamalar/mobil/test/features/shared/ui/components/open_price_badge_test.dart
git commit -m "refactor(mobile): extract open/price badges into shared component"
```

---

## Task 3: Add hybrid circular category chip variant

Add a new `roundedRow` layout to the existing `CategoryQuickFilters` widget for the 52×52 circular category chips, including a "Featured" (icon-based, no photo) entry style.

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/ui/components/category_quick_filters.dart`

- [ ] **Step 1: Add `font_awesome_flutter` import and extend `CategoryQuickFilterItem`**

In `uygulamalar/mobil/lib/features/discovery/ui/components/category_quick_filters.dart`, add the import at the top:

```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
```

Replace the `CategoryQuickFilterItem` class:

```dart
class CategoryQuickFilterItem {
  const CategoryQuickFilterItem({
    required this.id,
    required this.title,
    required this.imageAsset,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String imageAsset;

  /// When true, renders as the highlighted "Featured" chip (star icon,
  /// primary-colored border) instead of a category photo.
  final bool isFeatured;
}
```

- [ ] **Step 2: Add `roundedRow` to the layout enum**

```dart
enum CategoryQuickFiltersLayout { horizontal, grid2x4, roundedRow }
```

- [ ] **Step 3: Add `showHeader` parameter to `CategoryQuickFilters`**

Replace the constructor and fields:

```dart
class CategoryQuickFilters extends StatelessWidget {
  const CategoryQuickFilters({
    super.key,
    required this.items,
    required this.onTap,
    this.layout = CategoryQuickFiltersLayout.horizontal,
    this.title,
    this.showHeader = true,
  });

  final List<CategoryQuickFilterItem> items;
  final ValueChanged<CategoryQuickFilterItem> onTap;
  final CategoryQuickFiltersLayout layout;
  final String? title;

  /// When false, the `AppSectionHeader` title row is omitted — used for the
  /// compact "roundedRow" chips placed directly under the search box, which
  /// have no section title in the mockup.
  final bool showHeader;
```

- [ ] **Step 4: Update `build()` to skip the header and add the `roundedRow` branch**

Replace the `build` method body:

```dart
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = items.take(12).toList();
    final resolvedTitle = title ?? AppLocalizations.of(context).quickShortcuts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          AppSectionHeader(title: resolvedTitle),
          const SizedBox(height: 8),
        ],
        if (layout == CategoryQuickFiltersLayout.grid2x4)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.take(8).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final item = visible[index];
              return _CategoryCard(item: item, onTap: () => onTap(item));
            },
          )
        else if (layout == CategoryQuickFiltersLayout.roundedRow)
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = visible[index];
                return _RoundedCategoryChip(item: item, onTap: () => onTap(item));
              },
            ),
          )
        else
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = visible[index];
                return SizedBox(
                  width: 116,
                  child: _CategoryCard(item: item, onTap: () => onTap(item)),
                );
              },
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Add the `_RoundedCategoryChip` widget**

Append this new private widget to the end of the file (after `_CategoryCard`):

```dart
class _RoundedCategoryChip extends StatelessWidget {
  const _RoundedCategoryChip({required this.item, required this.onTap});

  final CategoryQuickFilterItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circle = item.isFeatured
        ? Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.star,
              size: 20,
              color: AppColors.primary,
            ),
          )
        : ClipOval(
            child: Image.asset(
              item.imageAsset,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              cacheWidth: 104,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: AppColors.cardAlt,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_menu_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: item.isFeatured ? FontWeight.w800 : FontWeight.w700,
                color: item.isFeatured ? AppColors.primary : AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify**

Run from `uygulamalar/mobil`:

```bash
flutter analyze
```

Expected: no new issues. (The existing two call sites of `CategoryQuickFilters` still pass `isFeatured: false` implicitly via the default, so they keep working unchanged.)

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/ui/components/category_quick_filters.dart
git commit -m "feat(mobile): add rounded hybrid category chip layout"
```

---

## Task 4: Greeting header, "Discover for you" card, and promo banner widgets

Add three new private widgets to `discovery_cards.dart` (a `part of '../discovery_page.dart'` file): `_DiscoveryGreetingHeader`, `_ForYouBusinessCard`, `_DiscoveryPromoBanner`.

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/ui/discovery_page.dart` (imports only)
- Modify: `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_cards.dart`

- [ ] **Step 1: Add new imports to `discovery_page.dart`**

In `uygulamalar/mobil/lib/features/discovery/ui/discovery_page.dart`, add these two imports (near the other relative imports, e.g. after line 31 `import '../../auth/domain/auth_providers.dart';`):

```dart
import '../../taste_twin/domain/taste_twin_controllers.dart';
import '../../shared/ui/components/open_price_badge.dart';
```

And add the design-tokens import (after line 18 `import '../../../app/theme/colors.dart';`):

```dart
import '../../../app/theme/app_tokens.dart';
```

- [ ] **Step 2: Add `_DiscoveryGreetingHeader`**

Open `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_cards.dart`. After the `part of '../discovery_page.dart';` line (line 1) and before the first class (`_FreshLinkCard` or whatever is first), add:

```dart
class _DiscoveryGreetingHeader extends ConsumerWidget {
  const _DiscoveryGreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);

    String? displayName;
    if (user != null) {
      final profileAsync = ref.watch(publicProfileProvider(user.id));
      final name = profileAsync.asData?.value.displayName.trim() ?? '';
      if (name.isNotEmpty) displayName = name;
    }

    final greeting = displayName != null
        ? t.discoveryGreetingHello(displayName)
        : t.discoveryGreetingHelloAnon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t.discoveryGreetingSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Add `_ForYouBusinessCard`**

In the same file (`discovery_cards.dart`), add this widget after `_DiscoveryGreetingHeader`:

```dart
class _ForYouBusinessCard extends StatelessWidget {
  const _ForYouBusinessCard({
    required this.item,
    required this.imageAsset,
    required this.ratingLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String ratingLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final distance = t.distanceKm(
      double.parse((item.distanceKm ?? 0.4).toStringAsFixed(1)),
    );
    final priceSymbol = priceLevelSymbol(item.priceLevel, item.medianPriceCents);

    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} • $distance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                if (item.isOpenNow != null || priceSymbol != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.isOpenNow != null)
                        OpenStatusBadge(isOpen: item.isOpenNow!)
                      else
                        const SizedBox.shrink(),
                      if (priceSymbol != null) PriceLevelBadge(symbol: priceSymbol),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    imageAsset,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.star,
                          size: 10,
                          color: AppColors.star,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFavoriteTap,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.primary : AppColors.muted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_DiscoveryPromoBanner`**

In the same file, add this widget after `_ForYouBusinessCard`:

```dart
class _DiscoveryPromoBanner extends StatelessWidget {
  const _DiscoveryPromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(tokens.radius20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radius20),
        child: Padding(
          padding: EdgeInsets.all(tokens.space16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.whatToEatTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.whatToEatDescription,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.arrowRight,
                  color: AppColors.onPrimary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify**

Run from `uygulamalar/mobil`:

```bash
flutter analyze
```

Expected: no new issues. (These three widgets are not yet used anywhere — `flutter analyze` may warn "unused element" for each; that's expected and resolved in Task 5.)

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/ui/discovery_page.dart uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_cards.dart
git commit -m "feat(mobile): add discovery greeting header, for-you card, promo banner widgets"
```

---

## Task 5: Wire the new widgets into `_buildPremiumDiscoveryLayout`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart`

- [ ] **Step 1: Add the greeting header at the top of the premium layout**

In `uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart`, find the start of the `SliverList.list` children inside `_buildPremiumDiscoveryLayout` (around line 1776):

```dart
            sliver: SliverList.list(
              children: [
                const WeatherHintBar(compact: true),
```

Replace with:

```dart
            sliver: SliverList.list(
              children: [
                const _DiscoveryGreetingHeader(),
                const WeatherHintBar(compact: true),
```

- [ ] **Step 2: Insert the rounded category chips row after the search box**

Find the end of the search-box `Container`/`TextField` block and the `SizedBox(height: 12)` that follows it (around lines 1817-1818):

```dart
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PremiumFilterChip(
```

Replace with (inserting the new chips row + spacing before the existing filter-chips `SingleChildScrollView`):

```dart
                ),
                const SizedBox(height: 12),
                CategoryQuickFilters(
                  items: [
                    CategoryQuickFilterItem(
                      id: 'featured',
                      title: AppLocalizations.of(context).discoveryFeaturedCategory,
                      imageAsset: '',
                      isFeatured: true,
                    ),
                    ..._homeCategories.take(8).map(
                          (item) => CategoryQuickFilterItem(
                            id: item.id,
                            title: _homeCategoryTitle(context, item.titleKey),
                            imageAsset:
                                _selectedCategoryImage[item.id] ?? item.imagePool.first,
                          ),
                        ),
                  ],
                  layout: CategoryQuickFiltersLayout.roundedRow,
                  showHeader: false,
                  onTap: (item) {
                    if (item.isFeatured) {
                      qCtrl.clear();
                      ref
                          .read(discoverySearchProvider.notifier)
                          .setQuery('', withDebounce: false);
                      if (mounted) setState(() {});
                      return;
                    }
                    final selected = _homeCategories.firstWhere((e) => e.id == item.id);
                    qCtrl.text = selected.searchTerm;
                    ref
                        .read(discoverySearchProvider.notifier)
                        .setQuery(selected.searchTerm, withDebounce: false);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PremiumFilterChip(
```

- [ ] **Step 3: Rename the "Senin için keşfet" section title**

Find (around line 1916-1919):

```dart
                Text(
                  AppLocalizations.of(context).nearbyVerifiedSpots,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
```

Replace with:

```dart
                Text(
                  AppLocalizations.of(context).discoverForYou,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
```

- [ ] **Step 4: Insert the promo banner after the "Discover for you" card list**

Find the end of the `_buildPremiumDiscoveryLayout` children list (around lines 1929-1937):

```dart
                if (nearbyItems.isEmpty)
                  AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: AppLocalizations.of(context).noNearbyVerifiedSpots,
                    description: AppLocalizations.of(
                      context,
                    ).changeFiltersTryAgain,
                  )
                else
                  ..._buildNearbyCardsWithAds(
                    context: context,
                    ref: ref,
                    nearbyItems: nearbyItems,
                    favCache: favCache,
                    favIds: favIds,
                    isLoggedIn: isLoggedIn,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
```

Replace with:

```dart
                if (nearbyItems.isEmpty)
                  AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: AppLocalizations.of(context).noNearbyVerifiedSpots,
                    description: AppLocalizations.of(
                      context,
                    ).changeFiltersTryAgain,
                  )
                else ...[
                  ..._buildNearbyCardsWithAds(
                    context: context,
                    ref: ref,
                    nearbyItems: nearbyItems,
                    favCache: favCache,
                    favIds: favIds,
                    isLoggedIn: isLoggedIn,
                  ),
                  _DiscoveryPromoBanner(onTap: () => _openWhatToEat(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 5: Replace `_NearbyVerifiedSpotCard` with `_ForYouBusinessCard` in `_buildNearbyCardsWithAds`**

Find (around lines 1971-2003):

```dart
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _NearbyVerifiedSpotCard(
            item: item,
            imageAsset: _categoryImageFor(item.category, index + 2),
            ratingLabel: _ratingLabel(item),
            averageSpend: _avgSpendLabel(context, item),
            updatedLabel: _updatedLabel(context, index),
            statusType: hasVerified
                ? StatusBadgeType.verified
                : StatusBadgeType.outdated,
            isFavorite: isFav,
            onTap: () => _openBusiness(item.id, source: 'nearby_verified'),
            onFavoriteTap: () async {
```

Replace with:

```dart
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ForYouBusinessCard(
            item: item,
            imageAsset: _categoryImageFor(item.category, index + 2),
            ratingLabel: _ratingLabel(item),
            isFavorite: isFav,
            onTap: () => _openBusiness(item.id, source: 'nearby_verified'),
            onFavoriteTap: () async {
```

> Note: `hasVerified` is computed just above this block (`final hasVerified = (item.recentPriceVerifiedCount ?? 0) > 0;`) and is no longer used after this change. Remove that now-unused line too — find:
>
> ```dart
>       final isFav = favCache[item.id] ?? favIds.contains(item.id);
>       final hasVerified = (item.recentPriceVerifiedCount ?? 0) > 0;
>       widgets.add(
> ```
>
> Replace with:
>
> ```dart
>       final isFav = favCache[item.id] ?? favIds.contains(item.id);
>       widgets.add(
> ```

- [ ] **Step 6: Remove the now-unused `_NearbyVerifiedSpotCard`, `_avgSpendLabel`, `_updatedLabel` if no longer referenced**

Run from `uygulamalar/mobil`:

```bash
flutter analyze
```

Check the output for `unused_element` warnings on `_NearbyVerifiedSpotCard` (in `discovery_cards.dart`), `_avgSpendLabel`, and `_updatedLabel` (in `discovery_recommended_tab.dart`).

- If `_NearbyVerifiedSpotCard` is reported unused, delete the entire class from `discovery_cards.dart` (it was previously at lines 147-325).
- If `_avgSpendLabel` is reported unused, delete its method definition (`discovery_recommended_tab.dart`, around line 2026-2032).
- If `_updatedLabel` is reported unused, delete its method definition (around line 1946-1950).
- If `StatusBadgeType`/`StatusBadge` become unused as a result, leave them — they are shared types likely used elsewhere; only remove code reported as unused by `flutter analyze` itself, do not guess.

Re-run `flutter analyze` after each deletion until it reports zero new issues.

- [ ] **Step 7: Run the full analyzer and test suite**

```bash
flutter analyze
flutter test
```

Expected: `flutter analyze` — no issues. `flutter test` — all existing tests pass (including `test/features/discovery/domain/discovery_feed_composer_test.dart` and `test/features/shared/ui/components/open_price_badge_test.dart`).

- [ ] **Step 8: Manual verification**

Run the app on a device/emulator:

```bash
flutter run -d <device>
```

On the Keşfet (Discovery) tab, verify:
- "Merhaba [isim] 👋" / "Bugün ne yemek istersin?" appears at the top (and "Merhaba 👋" without a name when logged out).
- A row of circular category chips appears directly under the search box, with "Öne Çıkanlar" first (star icon, red border).
- Tapping "Öne Çıkanlar" clears the search query and returns to the default list; tapping another chip (e.g. "Pide") sets the search query to that category's search term.
- The existing filter chip row (Bütçe/Doğrulanmış/Açık Şimdi/Taste Twin) still appears below the category chips, unchanged.
- The "Senin için keşfet" section shows horizontal cards: name/category/distance on the left, "Açık"/"Kapalı" + ₺ price level badges below that, and a 96×96 image on the right with a rating badge (top-left) and favorite heart (top-right).
- Tapping the favorite heart toggles favorite state (prompts login if logged out).
- A "Ne yesek?" promo banner with a red arrow button appears after the card list; tapping it opens the existing "What should I eat?" bottom sheet.

- [ ] **Step 9: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_recommended_tab.dart uygulamalar/mobil/lib/features/discovery/ui/parts/discovery_cards.dart
git commit -m "feat(mobile): wire discovery redesign into premium layout top section"
```

---

## Self-Review Notes

- **Spec coverage:** Section 2 (page order) → Task 5 Steps 1-4. Section 3.1 (greeting) → Task 4 Step 2 + Task 5 Step 1. Section 3.2 (category chips) → Task 3 + Task 5 Step 2. Section 3.3 (for-you card) → Task 4 Step 3 + Task 5 Step 5. Section 3.4 (promo banner) → Task 4 Step 4 + Task 5 Step 4. Section 4 (ARB keys) → Task 1. Section 5 (icons) → Task 3 Step 5, Task 4 Steps 3-4 (all `FontAwesomeIcons`/`Icons`, no new assets). Section 8 risk #2 (no code duplication for price badge) → Task 2.
- **Ambiguity resolved:** spec's "{kategori} • {mutfak}" / separate distance+duration line collapsed into a single `'${item.category} • $distance'` line (Task 4 Step 3) since `BusinessCardModel` has no cuisine or duration fields — matches spec section 8's note that duration is out of scope.
- **Type consistency:** `_ForYouBusinessCard` constructor params (`item`, `imageAsset`, `ratingLabel`, `isFavorite`, `onTap`, `onFavoriteTap`) match exactly what Task 5 Step 5 passes at the call site.
