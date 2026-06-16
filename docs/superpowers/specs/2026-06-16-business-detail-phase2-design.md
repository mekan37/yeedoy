# Business Detail Page — Phase 2 Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement the plan derived from this spec.

**Goal:** Extend the Phase 1 business detail page redesign with four missing elements from the `işletmedetay.png` mockup: (A) distance + walking-time info row, (B) price-level badge, (C) Paket Servis / Yerinde Yeme amenity chips, (D) horizontal popular-dishes layout.

**Architecture:** Pure UI/data-model additions on top of Phase 1. No new Supabase tables or RPCs. One new field on `Business` (`priceLevel`), two new widgets (`_BusinessInfoRow`, updated `_BusinessBadgeChipRow`), one layout change in `_BusinessPopularDishesSection`. Hero collapse animation and 3-tab structure are unchanged.

**Tech Stack:** Flutter, Riverpod, existing design system (`AppColors`/`AppTokens`), ARB l10n (TR+EN).

---

## 1. Scope

### In scope
- Add `priceLevel` field to `Business` model and `fetchBusiness` select query.
- New `_BusinessInfoRow` widget (distance · walking time · price level) rendered between the rating line and the badge chip row in `_BusinessHeroTrustHeader`.
- Update `_BusinessBadgeChipRow` to also show "Paket Servis" and "Yerinde Yeme" chips sourced from `businessAmenitiesProvider`.
- Update `_BusinessPopularDishesSection` (Genel tab) to use a horizontal 2-item `Row` instead of `GridView`.

### Out of scope
- Hero collapse animation behavior (unchanged from Phase 1).
- Tab structure, bottom action bar, existing sections (unchanged).
- Delivery time or ETA (no data source) — only walking time from distance shown.
- "Gel Al" (takeaway pickup) chip — not in mockup.
- Weekly hours bottom sheet (Phase 1 decision, unchanged).

---

## 2. Data Model Change

### 2.1 `Business` model (`lib/features/business/domain/business.dart`)

Add `priceLevel` field:
```dart
final String? priceLevel;  // 'budget' | 'mid' | 'premium' | null
```

Constructor: `this.priceLevel,`

`fromMap`: `priceLevel: m['price_level'] as String?,`

`toMap`: `'price_level': priceLevel,`

### 2.2 `fetchBusiness` query (`lib/features/discovery/data/discovery_repository.dart`)

Locate the `fetchBusiness` method. If it uses `*` (wildcard select), no change needed — `price_level` is already in `businesses_with_stats`. If it uses an explicit column list, add `price_level` to the list.

---

## 3. New: `_BusinessInfoRow` Widget

**Location:** `business_header.dart` (same `part of` file as other header widgets).

**Placement:** Inserted in `_BusinessHeroTrustHeader`'s white-card content area immediately after the rating/category/status row and before `_BusinessBadgeChipRow`.

**Logic:**
```dart
// Distance computation
final distanceKm = (business.lat != null && business.lng != null &&
    userLat != null && userLng != null)
    ? _haversineKm(userLat, userLng, business.lat!, business.lng!)
    : null;

final walkMinutes = distanceKm != null
    ? (distanceKm / 4.5 * 60).round().clamp(1, 99)
    : null;
```

- `userLat`/`userLng` come from `ref.watch(discoverySearchProvider.select((s) => (s.userLat, s.userLng)))` — same provider used by `topBusinessesListProvider`.
- `_haversineKm` is a private top-level function (copy the exact formula from `top_businesses_page_controller.dart`'s pattern, or use the one in `TopBusinessRankedTile.walkingMinutes`):
```dart
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
      sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}
double _deg2rad(double deg) => deg * (pi / 180);
```
Add `import 'dart:math';` at top of `business_header.dart`.

**Visibility rule:** If `distanceKm == null && business.priceLevel == null`, the entire `_BusinessInfoRow` is `SizedBox.shrink()`.

**Display format:**
```
📍 {distance}  ·  🕐 ~{walkMinutes} dk yürüme  ·  ₺₺ Orta
```
Where:
- Distance: `distanceKm! < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm!.toStringAsFixed(1)} km'`
- Walking time: only shown if `distanceKm != null`
- Price level: only shown if `business.priceLevel != null`

**Price level mapping:**
| DB value | Symbol | Label (TR) | Label (EN) |
|---|---|---|---|
| `'budget'` | `₺` | Ekonomik | Budget |
| `'mid'` | `₺₺` | Orta | Mid-range |
| `'premium'` | `₺₺₺` | Üst Düzey | Premium |

Price symbol rendered as a small `Container` with `AppColors.warningBackground` fill + `AppColors.warning` text (same amber tone as rating badge). Label text in `AppColors.muted`, 11sp.

**Separator:** `Text(' · ', style: TextStyle(color: AppColors.muted))` between items (only rendered between present items).

**L10n:** Two new ARB keys:
- `walkingMinutes` (TR: `"~{n} dk yürüme"`, EN: `"~{n} min walk"`) — `String Function(int n)` getter
- `priceLevelBudget`, `priceLevelMid`, `priceLevelPremium` (TR: Ekonomik/Orta/Üst Düzey; EN: Budget/Mid-range/Premium)

---

## 4. Updated: `_BusinessBadgeChipRow`

**Location:** `business_header.dart`.

**Current:** Watches `_businessTrustProvider` (Menü Onaylı) and `businessTrendingItemsProvider` (Popüler).

**Addition:** Also watch `businessAmenitiesProvider(business.id)`:
```dart
final amenitiesAsync = ref.watch(businessAmenitiesProvider(business.id));
final amenities = amenitiesAsync.asData?.value ?? const [];
final hasDelivery = amenities.any((a) => a.key == 'delivery');
final hasDineIn   = amenities.any((a) => a.key == 'dine_in' || a.key == 'takeaway');
```

**Chip order (left to right):** Menü Onaylı → Paket Servis → Yerinde Yeme → Popüler

**New chips:**
- **Paket Servis** (`Icons.delivery_dining_outlined`, muted tint) — shown if `hasDelivery`
- **Yerinde Yeme** (`Icons.restaurant_outlined`, muted tint) — shown if `hasDineIn`

**New ARB keys:**
- `businessBadgeDelivery`: `"Paket Servis"` / `"Delivery"`
- `businessBadgeDineIn`: `"Yerinde Yeme"` / `"Dine In"`

**No change** to existing Menü Onaylı and Popüler chip conditions.

---

## 5. Updated: `_BusinessPopularDishesSection`

**Location:** `business_sections_scroll.dart`.

**Current:** `GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics())` with up to 4 items.

**New:** Horizontal `Row` with exactly 2 items (first 2 of `trendingItems`), each in an `Expanded` card. If only 1 item, show it left-aligned in a `ConstrainedBox(maxWidth: (screenWidth - 48) / 2)`.

**Card layout (each item):**
```
┌─────────────────────┐
│ [64x64 image]       │
│ itemName (w700,13sp)│
│ description (muted) │
│ ₺260 (primary,w900) │
└─────────────────────┘
```
- Image: `AppNetworkImage(url: item.imageUrl, variant: ImageVariant.thumb)`, fallback to `Image.asset(CategoryAssets.resolve(item.category ?? ''))` if null.
- Price: `_formatPriceWithCurrency(context, item.priceCents, item.currency)` — existing private helper already in `business_sections_scroll.dart`.
- Card container: `AppCard` with `padding: tokens.space12`, `borderRadius: tokens.radius16`.

**Max 2 items** (previously up to 4 in grid). "Tümünü gör" link still navigates to Menü tab (`DefaultTabController.of(context).animateTo(1)`).

---

## 6. Files Touched

| File | Change |
|---|---|
| `lib/features/business/domain/business.dart` | Add `priceLevel` field (Section 2.1) |
| `lib/features/discovery/data/discovery_repository.dart` | Confirm/add `price_level` to select (Section 2.2) |
| `lib/features/business/ui/parts/business_header.dart` | New `_BusinessInfoRow` + `_haversineKm`/`_deg2rad` helpers; update `_BusinessBadgeChipRow` (Sections 3, 4) |
| `lib/features/business/ui/parts/business_sections_scroll.dart` | Update `_BusinessPopularDishesSection` (Section 5) |
| `lib/l10n/app_tr.arb` + `lib/l10n/app_en.arb` | New keys (Sections 3, 4); regenerate via `flutter gen-l10n` |

---

## 7. New ARB Keys

| Key | TR | EN |
|---|---|---|
| `walkingMinutes` | `~{n} dk yürüme` | `~{n} min walk` |
| `priceLevelBudget` | `Ekonomik` | `Budget` |
| `priceLevelMid` | `Orta` | `Mid-range` |
| `priceLevelPremium` | `Üst Düzey` | `Premium` |
| `businessBadgeDelivery` | `Paket Servis` | `Delivery` |
| `businessBadgeDineIn` | `Yerinde Yeme` | `Dine In` |

Check before adding: `walkingMinutes` might already exist from `TopBusinessRankedTile` work — reuse if so.

---

## 8. Validation

- `flutter analyze` → "No issues found!"
- `flutter test` → full suite passes (baseline: 323 passing)
- Manual: business detail page renders info row with real distance when location available; info row hidden when location denied; price level shown correctly per DB value; "Paket Servis"/"Yerinde Yeme" chips appear for businesses with those amenities; "Popüler lezzetler" shows 2 items side by side.
