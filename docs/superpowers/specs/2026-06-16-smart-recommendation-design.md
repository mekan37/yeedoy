# Akıllı Öneri (Smart Recommendation) — Design Spec

**Date:** 2026-06-16  
**Status:** Approved  
**Replaces:** `features/budget_combos/` (full replacement, not migration)

---

## Overview

Replace the two-screen `budget_combos` flow (entry form → results page) with a single, self-contained `SmartRecommendationPage` that lives at `/budget-combos`. The page lets the user pick a party size and a price-range preset, then shows enriched business cards with image, discount badge, rating, distance, and price with strikethrough. A "Şansını Dene!" shuffle tile rerandomises results.

---

## Architecture

### Feature folder

```
features/smart_recommendation/
  data/
    smart_reco_repository.dart
  domain/
    smart_reco_models.dart
    smart_reco_provider.dart
  ui/
    smart_recommendation_page.dart   ← single file, private part-classes inside
```

Single page file; private widgets (`_InputCard`, `_SmartBusinessCard`, `_ShuffleTile`, `_ResultsSection`) live as `part of` or as private classes at the bottom of the same file. No `part of` split needed — file should stay under ~300 lines.

### Route

The route stays `/budget-combos`. The route is already listed in `router.dart`'s `hideAppBar` guard (line 152), so the shell AppBar is already hidden for this route — no change needed in `app_shell.dart`.

---

## Data Layer

### Model — `smart_reco_models.dart`

```dart
enum _PriceRange {
  under200,   // ≤ ₺200  → budgetMaxCents: 20_000
  r200_400,   // ₺200–400 → 40_000
  r400_600,   // ₺400–600 → 60_000  ← default
  r600_1000,  // ₺600–1000 → 100_000
  over1000,   // ₺1000+  → 200_000 (generous cap)
}
```

`_PriceRange` is private to the UI file (no need to export it).

```dart
class SmartRecoQuery {
  final String city;
  final String district;
  final int partySize;          // 1–8
  final int budgetMaxCents;     // derived from _PriceRange
  final int limit;              // default 10
}

class SmartRecommendation {
  final String businessId;
  final String businessName;
  final String? imageUrl;       // Supabase storage path
  final String? cuisine;
  final double? rating;
  final int? reviewCount;
  final double? distanceKm;
  final int? estimatedMinutes;
  final int totalCents;         // recommended spend
  final int? originalTotalCents; // if discounted
  final int? discountPct;       // 0–100, null if no discount
}
```

### Repository — `smart_reco_repository.dart`

Identical cache pattern to `BudgetCombosRepository` (uses `RequestCache`, `_cacheScope = 'smart_reco'`, TTL 2 minutes). Calls `get_smart_recommendations_v1`.

```dart
Future<List<SmartRecommendation>> fetchRecommendations(
  SmartRecoQuery query, {bool force = false}
)
```

### Provider — `smart_reco_provider.dart`

```dart
final smartRecoRepositoryProvider = Provider<SmartRecoRepository>(...);

final smartRecoProvider = FutureProvider.autoDispose.family<
  List<SmartRecommendation>, SmartRecoQuery
>((ref, query) => ref.watch(smartRecoRepositoryProvider).fetchRecommendations(query));
```

The page holds `_partySize` and `_selectedRange` as local `ConsumerStatefulWidget` state. Query is constructed in `build()` from those two values plus location from `userLocationProvider`.

---

## Supabase RPC

### Migration: `20260616000001_get_smart_recommendations_v1.sql`

```sql
CREATE OR REPLACE FUNCTION public.get_smart_recommendations_v1(
  p_city       text,
  p_district   text,
  p_party_size int DEFAULT 2,
  p_budget_max_cents int DEFAULT 60000,
  p_limit      int DEFAULT 10
)
RETURNS TABLE (
  business_id          uuid,
  business_name        text,
  image_url            text,
  cuisine              text,
  rating               numeric,
  review_count         int,
  distance_km          numeric,
  estimated_minutes    int,
  total_cents          int,
  original_total_cents int,
  discount_pct         int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id                                           AS business_id,
    b.name                                         AS business_name,
    b.image_url,
    b.cuisine,
    b.rating,
    b.review_count,
    b.distance_km,
    NULL::int                                      AS estimated_minutes,
    -- cheapest item sum as proxy for per-person cost × party size
    LEAST(p_budget_max_cents,
          COALESCE(b.median_price_cents, 15000) * p_party_size)
                                                   AS total_cents,
    NULL::int                                      AS original_total_cents,
    NULL::int                                      AS discount_pct
  FROM search_nearby_businesses_v3(
    p_city      := p_city,
    p_district  := p_district,
    p_limit     := p_limit * 3  -- fetch extra, filter below
  ) b
  WHERE
    COALESCE(b.median_price_cents, 15000) * p_party_size <= p_budget_max_cents
  ORDER BY b.rating DESC NULLS LAST, random()
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_smart_recommendations_v1(text,text,int,int,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_smart_recommendations_v1(text,text,int,int,int) TO anon, authenticated;
COMMENT ON FUNCTION public.get_smart_recommendations_v1 IS
  'Smart budget recommendations filtered by party size × price range. Called by: smart_reco_repository.dart';
```

> Note: `search_nearby_businesses_v3` already returns `rating`, `review_count`, `distance_km`, `image_url`, `cuisine`, `median_price_cents`. The RPC wraps it, applies the budget filter, and randomises within the rating tier.

---

## UI

### `SmartRecommendationPage` — layout

```
SafeArea(bottom: false)
  AppTopBar()

Padding(h:20) Column:
  Text('Akıllı Öneri', style: w900/24)
  Text('Bütçene ve kişi sayısına göre en iyi seçenekler', style: muted/13)
  SizedBox(h:16)
  _InputCard (party stepper + price range dropdown)
  SizedBox(h:16)
  _ResultsSection (async, keyed on query)
```

The whole thing lives in a `CustomScrollView` with `SliverToBoxAdapter` wrappers.

### `_InputCard`

`AppCard` wrapping two rows:
- **Kişi sayısı row**: label + `_PartyStepper` (minus icon button → Text → plus icon button). Range 1–8. Default 2.
- **Bütçe aralığı row**: label + `DropdownButton<_PriceRange>` with items:  
  `'200 ₺ altı'`, `'₺200–400'`, `'₺400–600'`, `'₺600–1.000'`, `'₺1.000 üzeri'`

### `_ResultsSection`

Watches `smartRecoProvider(query)`:
- Loading: `AppSkeleton` list (3 skeleton tiles of 88px height)
- Error: inline error Text (red, `AppColors.danger`)
- Empty: `AppEmptyState` with savings icon and "Bölgende uygun işletme bulunamadı" text
- Data: `Column` of `_SmartBusinessCard` widgets + `_ShuffleTile` at the bottom

### `_SmartBusinessCard`

`AppCard` → `InkWell(onTap: context.go('/business/${item.businessId}'))` →  
```
Row(crossAxis: start):
  Stack(100×80 rounded image):
    CachedNetworkImage / placeholder grey box
    if discountPct != null: Positioned(top:6,left:6) → Container '%X indirim' red badge
  SizedBox(w:12)
  Expanded Column:
    Text(businessName, w800, 14, textStrong)
    if cuisine != null: Text(cuisine, muted, 12)
    SizedBox(h:4)
    Row:
      Icon(star, 14, warning) + Text(rating 1dp, 12)
      SizedBox(w:8)
      Icon(place, 14, muted) + Text(distanceKm, 12)
    Spacer
    Row(mainAxis: end):
      if originalTotalCents != null:
        Text('₺X', muted, 12, strikethrough) + SizedBox(w:4)
      Container(rounded, primarySoft bg):
        Text('₺Y', primary, 13, w800)
```

### `_ShuffleTile`

`AppCard` with dashed border and center content:
```
Column(center):
  Icon(Icons.shuffle_rounded, primary, 28)
  SizedBox(h:6)
  Text('Şansını Dene!', w800, 14, textStrong)
  Text('Farklı öneriler göster', muted, 12)
```

`onTap`: calls `ref.refresh(smartRecoProvider(query))` (forces a new fetch with `random()` in SQL).

---

## Files to change outside the new feature

| File | Change |
|---|---|
| `app/router.dart` | Import `SmartRecommendationPage`, replace `BudgetComboResultsPage` usage; remove query-param parsing (no longer needed — page is self-contained) |
| `features/smart_feed/ui/smart_feed_page.dart` | Replace `BudgetComboEntryCard` with a simple `_SmartRecoPromoBanner` that `context.go('/budget-combos')` |
| `features/shared/ui/labs_page.dart` | Update title ARB key from `budgetComboResultsTitle` to `smartRecoTitle` |
| `features/discovery/ui/parts/discovery_sheets.dart` | No change needed (already navigates to `/budget-combos`) |
| `core/analytics/app_events.dart` | Replace `budgetComboSearch` / `budgetComboBusinessOpen` with `smartRecoSearch` / `smartRecoBusinessOpen` |
| `l10n/app_tr.arb` + `app_en.arb` | Add `smartRecoTitle` / `smartRecoSubtitle` / `smartRecoEmptyTitle`; remove `budgetComboResultsTitle` |

---

## Deletion

Delete the entire `features/budget_combos/` folder after migration:
- `data/budget_combos_repository.dart`
- `domain/budget_combo_models.dart`
- `domain/budget_combo_provider.dart`
- `ui/budget_combo_entry_card.dart`
- `ui/budget_combo_results_page.dart`

---

## Analytics events

```dart
// app_events.dart — replace budget_combo events:
static const smartRecoSearch        = 'smart_reco_search';
static const smartRecoBusinessOpen  = 'smart_reco_business_open';
static const smartRecoShuffle       = 'smart_reco_shuffle';
```

---

## ARB keys (new)

| Key | TR | EN |
|---|---|---|
| `smartRecoTitle` | Akıllı Öneri | Smart Picks |
| `smartRecoSubtitle` | Bütçene ve kişi sayısına göre en iyi seçenekler | Best picks for your budget and group size |
| `smartRecoEmptyTitle` | Uygun işletme bulunamadı | No matching places found |
| `smartRecoEmptyDesc` | Bütçeni artırarak veya kişi sayısını azaltarak tekrar dene | Try raising your budget or reducing party size |
| `smartRecoShuffleLabel` | Şansını Dene! | Feeling Lucky? |
| `smartRecoShuffleDesc` | Farklı öneriler göster | Show different picks |

---

## Out of scope

- Real discount data integration (discount_pct always null for now; field reserved for future campaign data)
- Filter by cuisine (removed from budget_combos design, not in new spec)
- Deep-link query params (old `/budget-combos?city=&budget=` pattern removed; page reads location from `userLocationProvider`)
