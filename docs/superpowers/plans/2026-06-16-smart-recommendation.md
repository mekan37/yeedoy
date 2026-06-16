# Akıllı Öneri (Smart Recommendation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two-screen `budget_combos` feature with a single `SmartRecommendationPage` at `/budget-combos` that shows enriched business cards filtered by party size and preset price range.

**Architecture:** New `features/smart_recommendation/` folder with `data/domain/ui` layers. Supabase RPC `get_smart_recommendations_v1` wraps `search_nearby_businesses_v3` and applies a budget-per-person filter. The page is self-contained: reads location from `userLocationProvider`, holds party size and price range in local `ConsumerStatefulWidget` state, watches `FutureProvider.autoDispose.family` keyed on the query.

**Tech Stack:** Flutter, Riverpod 3.x, GoRouter 17.x, Supabase Flutter 2.x, `AppNetworkImage`, `RequestCache`

---

## File Structure

**Create:**
- `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_models.dart`
- `uygulamalar/mobil/lib/features/smart_recommendation/data/smart_reco_repository.dart`
- `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_provider.dart`
- `uygulamalar/mobil/lib/features/smart_recommendation/ui/smart_recommendation_page.dart`
- `supabase/migrations/20260616000001_get_smart_recommendations_v1.sql`
- `uygulamalar/mobil/test/features/smart_recommendation/domain/smart_reco_models_test.dart`

**Modify:**
- `uygulamalar/mobil/lib/l10n/app_tr.arb` — add 6 `smartReco*` keys
- `uygulamalar/mobil/lib/l10n/app_en.arb` — add 6 `smartReco*` keys
- `uygulamalar/mobil/lib/app/app_shell.dart` — add `/budget-combos` to `hideAppBar`
- `uygulamalar/mobil/lib/app/router.dart` — simplify `/budget-combos` route, swap import
- `uygulamalar/mobil/lib/core/analytics/app_events.dart` — add `smartReco*` events, remove `budgetCombo*`
- `uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart` — swap `BudgetComboEntryCard` → `_SmartRecoPromoBanner`
- `uygulamalar/mobil/lib/features/shared/ui/labs_page.dart` — update title ARB key

**Delete:**
- `uygulamalar/mobil/lib/features/budget_combos/` (entire folder, 5 files)

---

### Task 1: ARB keys

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb`
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb`

- [ ] **Step 1: Add 6 TR keys to `app_tr.arb`**

Open `uygulamalar/mobil/lib/l10n/app_tr.arb`. Find `"budgetComboResultsTitle"` and add the 6 new keys immediately before it (so they are easy to find later):

```json
  "smartRecoTitle": "Akıllı Öneri",
  "@smartRecoTitle": {
    "description": "Auto metadata for smartRecoTitle"
  },
  "smartRecoSubtitle": "Bütçene ve kişi sayısına göre en iyi seçenekler",
  "@smartRecoSubtitle": {
    "description": "Auto metadata for smartRecoSubtitle"
  },
  "smartRecoEmptyTitle": "Uygun işletme bulunamadı",
  "@smartRecoEmptyTitle": {
    "description": "Auto metadata for smartRecoEmptyTitle"
  },
  "smartRecoEmptyDesc": "Bütçeni artırarak veya kişi sayısını azaltarak tekrar dene",
  "@smartRecoEmptyDesc": {
    "description": "Auto metadata for smartRecoEmptyDesc"
  },
  "smartRecoShuffleLabel": "Şansını Dene!",
  "@smartRecoShuffleLabel": {
    "description": "Auto metadata for smartRecoShuffleLabel"
  },
  "smartRecoShuffleDesc": "Farklı öneriler göster",
  "@smartRecoShuffleDesc": {
    "description": "Auto metadata for smartRecoShuffleDesc"
  },
```

- [ ] **Step 2: Add 6 EN keys to `app_en.arb`**

Open `uygulamalar/mobil/lib/l10n/app_en.arb`. Find `"budgetComboResultsTitle"` and add immediately before it:

```json
  "smartRecoTitle": "Smart Picks",
  "@smartRecoTitle": {
    "description": "Auto metadata for smartRecoTitle"
  },
  "smartRecoSubtitle": "Best picks for your budget and group size",
  "@smartRecoSubtitle": {
    "description": "Auto metadata for smartRecoSubtitle"
  },
  "smartRecoEmptyTitle": "No matching places found",
  "@smartRecoEmptyTitle": {
    "description": "Auto metadata for smartRecoEmptyTitle"
  },
  "smartRecoEmptyDesc": "Try raising your budget or reducing party size",
  "@smartRecoEmptyDesc": {
    "description": "Auto metadata for smartRecoEmptyDesc"
  },
  "smartRecoShuffleLabel": "Feeling Lucky?",
  "@smartRecoShuffleLabel": {
    "description": "Auto metadata for smartRecoShuffleLabel"
  },
  "smartRecoShuffleDesc": "Show different picks",
  "@smartRecoShuffleDesc": {
    "description": "Auto metadata for smartRecoShuffleDesc"
  },
```

- [ ] **Step 3: Analyze to confirm keys compile**

Run from `uygulamalar/mobil/`:
```
flutter analyze --no-fatal-warnings
```
Expected: 0 new errors (gen_l10n runs automatically on analyze).

- [ ] **Step 4: Commit**

```
git add uygulamalar/mobil/lib/l10n/app_tr.arb uygulamalar/mobil/lib/l10n/app_en.arb
git commit -m "feat(l10n): add smartReco ARB keys (TR + EN)"
```

---

### Task 2: Domain models + unit test

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_models.dart`
- Create: `uygulamalar/mobil/test/features/smart_recommendation/domain/smart_reco_models_test.dart`

- [ ] **Step 1: Write the failing test first**

Create `uygulamalar/mobil/test/features/smart_recommendation/domain/smart_reco_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/smart_recommendation/domain/smart_reco_models.dart';

void main() {
  group('SmartRecoQuery equality', () {
    test('two queries with same values are equal', () {
      const a = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 3,
        budgetMaxCents: 60000,
      );
      const b = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 3,
        budgetMaxCents: 60000,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('queries with different partySize are not equal', () {
      const a = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 2,
        budgetMaxCents: 60000,
      );
      const b = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 4,
        budgetMaxCents: 60000,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('SmartRecommendation.fromMap', () {
    test('parses all fields when present', () {
      final map = <String, dynamic>{
        'business_id': 'abc-123',
        'business_name': 'Test Lokanta',
        'image_url': 'bucket/img.jpg',
        'cuisine': 'Türk',
        'rating': 4.5,
        'review_count': 120,
        'distance_km': 1.2,
        'estimated_minutes': 15,
        'total_cents': 45000,
        'original_total_cents': 50000,
        'discount_pct': 10,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.businessId, 'abc-123');
      expect(r.businessName, 'Test Lokanta');
      expect(r.imageUrl, 'bucket/img.jpg');
      expect(r.cuisine, 'Türk');
      expect(r.rating, 4.5);
      expect(r.reviewCount, 120);
      expect(r.distanceKm, 1.2);
      expect(r.estimatedMinutes, 15);
      expect(r.totalCents, 45000);
      expect(r.originalTotalCents, 50000);
      expect(r.discountPct, 10);
    });

    test('handles null optional fields gracefully', () {
      final map = <String, dynamic>{
        'business_id': 'abc-456',
        'business_name': 'Minimal',
        'total_cents': 30000,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.imageUrl, isNull);
      expect(r.cuisine, isNull);
      expect(r.rating, isNull);
      expect(r.reviewCount, isNull);
      expect(r.distanceKm, isNull);
      expect(r.estimatedMinutes, isNull);
      expect(r.originalTotalCents, isNull);
      expect(r.discountPct, isNull);
    });

    test('coerces int rating to double', () {
      final map = <String, dynamic>{
        'business_id': 'x',
        'business_name': 'y',
        'total_cents': 10000,
        'rating': 4,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.rating, 4.0);
    });

    test('coerces int distance_km to double', () {
      final map = <String, dynamic>{
        'business_id': 'x',
        'business_name': 'y',
        'total_cents': 10000,
        'distance_km': 2,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.distanceKm, 2.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/features/smart_recommendation/domain/smart_reco_models_test.dart
```
Expected: compilation error — `package:yeedoy/features/smart_recommendation/domain/smart_reco_models.dart` not found.

- [ ] **Step 3: Create `smart_reco_models.dart`**

Create `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_models.dart`:

```dart
class SmartRecoQuery {
  const SmartRecoQuery({
    required this.city,
    required this.district,
    required this.partySize,
    required this.budgetMaxCents,
    this.limit = 10,
  });

  final String city;
  final String district;
  final int partySize;
  final int budgetMaxCents;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRecoQuery &&
          city == other.city &&
          district == other.district &&
          partySize == other.partySize &&
          budgetMaxCents == other.budgetMaxCents &&
          limit == other.limit;

  @override
  int get hashCode =>
      Object.hash(city, district, partySize, budgetMaxCents, limit);
}

class SmartRecommendation {
  const SmartRecommendation({
    required this.businessId,
    required this.businessName,
    required this.totalCents,
    this.imageUrl,
    this.cuisine,
    this.rating,
    this.reviewCount,
    this.distanceKm,
    this.estimatedMinutes,
    this.originalTotalCents,
    this.discountPct,
  });

  final String businessId;
  final String businessName;
  final String? imageUrl;
  final String? cuisine;
  final double? rating;
  final int? reviewCount;
  final double? distanceKm;
  final int? estimatedMinutes;
  final int totalCents;
  final int? originalTotalCents;
  final int? discountPct;

  factory SmartRecommendation.fromMap(Map<String, dynamic> map) {
    return SmartRecommendation(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      imageUrl: map['image_url'] as String?,
      cuisine: map['cuisine'] as String?,
      rating: _toDouble(map['rating']),
      reviewCount: (map['review_count'] as num?)?.toInt(),
      distanceKm: _toDouble(map['distance_km']),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt(),
      totalCents: (map['total_cents'] as num?)?.toInt() ?? 0,
      originalTotalCents: (map['original_total_cents'] as num?)?.toInt(),
      discountPct: (map['discount_pct'] as num?)?.toInt(),
    );
  }
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/features/smart_recommendation/domain/smart_reco_models_test.dart
```
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```
git add uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_models.dart uygulamalar/mobil/test/features/smart_recommendation/domain/smart_reco_models_test.dart
git commit -m "feat(smart-reco): domain models + unit tests"
```

---

### Task 3: Repository

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_recommendation/data/smart_reco_repository.dart`

No separate test — RPC wrapper uses the same cache pattern as `BudgetCombosRepository`, which has no unit test either.

- [ ] **Step 1: Create `smart_reco_repository.dart`**

Create `uygulamalar/mobil/lib/features/smart_recommendation/data/smart_reco_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../domain/smart_reco_models.dart';

class SmartRecoRepository {
  SmartRecoRepository(this._client, RequestCache requestCache)
      : _cache = requestCache.scope(_cacheScope);

  final SupabaseClient _client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'smart_reco';
  static const Duration _ttl = Duration(minutes: 2);

  Future<List<SmartRecommendation>> fetchRecommendations(
    SmartRecoQuery query, {
    bool force = false,
  }) async {
    final cacheKey = stableRequestCacheKey('smart_reco', {
      'city': query.city.trim(),
      'district': query.district.trim(),
      'party_size': query.partySize,
      'budget_max_cents': query.budgetMaxCents,
      'limit': query.limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<SmartRecommendation>>(
        cacheKey,
        ttl: _ttl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final data = await _client.rpc('get_smart_recommendations_v1', params: {
        'p_city': query.city,
        'p_district': query.district,
        'p_party_size': query.partySize,
        'p_budget_max_cents': query.budgetMaxCents,
        'p_limit': query.limit,
      });
      final list = (data as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final items = list.map(SmartRecommendation.fromMap).toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<SmartRecommendation>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
```

- [ ] **Step 2: Run analyze**

```
flutter analyze --no-fatal-warnings
```
Expected: 0 new errors.

- [ ] **Step 3: Commit**

```
git add uygulamalar/mobil/lib/features/smart_recommendation/data/smart_reco_repository.dart
git commit -m "feat(smart-reco): SmartRecoRepository with cache"
```

---

### Task 4: Riverpod providers

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_provider.dart`

- [ ] **Step 1: Create `smart_reco_provider.dart`**

Create `uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/network/supabase_provider.dart';
import '../data/smart_reco_repository.dart';
import 'smart_reco_models.dart';

final smartRecoRepositoryProvider = Provider<SmartRecoRepository>((ref) {
  return SmartRecoRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider),
  );
});

final smartRecoProvider = FutureProvider.autoDispose
    .family<List<SmartRecommendation>, SmartRecoQuery>((ref, query) async {
  return ref.read(smartRecoRepositoryProvider).fetchRecommendations(query);
});
```

- [ ] **Step 2: Run analyze**

```
flutter analyze --no-fatal-warnings
```
Expected: 0 new errors.

- [ ] **Step 3: Commit**

```
git add uygulamalar/mobil/lib/features/smart_recommendation/domain/smart_reco_provider.dart
git commit -m "feat(smart-reco): Riverpod providers"
```

---

### Task 5: Supabase migration

**Files:**
- Create: `supabase/migrations/20260616000001_get_smart_recommendations_v1.sql`

- [ ] **Step 1: Create the migration file**

Create `supabase/migrations/20260616000001_get_smart_recommendations_v1.sql`:

```sql
CREATE OR REPLACE FUNCTION public.get_smart_recommendations_v1(
  p_city             text,
  p_district         text,
  p_party_size       int  DEFAULT 2,
  p_budget_max_cents int  DEFAULT 60000,
  p_limit            int  DEFAULT 10
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
  IF p_party_size < 1 OR p_party_size > 20 THEN
    RAISE EXCEPTION 'validation_error: p_party_size must be between 1 and 20'
      USING ERRCODE = 'P0003';
  END IF;

  RETURN QUERY
  SELECT
    b.id                                                          AS business_id,
    b.name                                                        AS business_name,
    b.image_url,
    b.cuisine,
    b.rating,
    b.review_count,
    b.distance_km,
    NULL::int                                                     AS estimated_minutes,
    LEAST(
      p_budget_max_cents,
      COALESCE(b.median_price_cents, 15000) * p_party_size
    )::int                                                        AS total_cents,
    NULL::int                                                     AS original_total_cents,
    NULL::int                                                     AS discount_pct
  FROM search_nearby_businesses_v3(
    p_city      := p_city,
    p_district  := p_district,
    p_limit     := p_limit * 3
  ) b
  WHERE
    COALESCE(b.median_price_cents, 15000) * p_party_size <= p_budget_max_cents
  ORDER BY b.rating DESC NULLS LAST, random()
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_smart_recommendations_v1(text, text, int, int, int)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_smart_recommendations_v1(text, text, int, int, int)
  TO anon, authenticated;
COMMENT ON FUNCTION public.get_smart_recommendations_v1 IS
  'Smart budget recommendations filtered by party size × price range. Called by: smart_reco_repository.dart';
```

- [ ] **Step 2: Apply migration locally**

```
supabase db reset
```
Expected: Migration runs without error. If `search_nearby_businesses_v3` doesn't exist in your local seed, you will see a SQL error — that's expected in local dev without the full seed; the function definition itself is valid.

- [ ] **Step 3: Commit**

```
git add supabase/migrations/20260616000001_get_smart_recommendations_v1.sql
git commit -m "feat(db): get_smart_recommendations_v1 RPC"
```

---

### Task 6: SmartRecommendationPage UI

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_recommendation/ui/smart_recommendation_page.dart`
- Modify: `uygulamalar/mobil/lib/core/analytics/app_events.dart` — add smartReco events (new ones only; old budgetCombo events removed in Task 9)

- [ ] **Step 1: Add smartReco analytics events to `app_events.dart` (prerequisite for the page)**

File: `uygulamalar/mobil/lib/core/analytics/app_events.dart`

Find:
```dart
  static const budgetComboSearch = 'budget_combo_search';
  static const budgetComboBusinessOpen = 'budget_combo_business_open';
```
Replace with:
```dart
  static const budgetComboSearch = 'budget_combo_search';
  static const budgetComboBusinessOpen = 'budget_combo_business_open';
  static const smartRecoSearch = 'smart_reco_search';
  static const smartRecoBusinessOpen = 'smart_reco_business_open';
  static const smartRecoShuffle = 'smart_reco_shuffle';
```

(The old `budgetCombo*` constants are left in place for now — they will be removed in Task 9 when the whole `budget_combos` folder is deleted.)

- [ ] **Step 2: Create `smart_recommendation_page.dart`**

Create `uygulamalar/mobil/lib/features/smart_recommendation/ui/smart_recommendation_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../core/media/app_network_image.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/smart_reco_models.dart';
import '../domain/smart_reco_provider.dart';

enum _PriceRange {
  under200,
  r200_400,
  r400_600,
  r600_1000,
  over1000;

  int get maxCents => switch (this) {
        _PriceRange.under200 => 20000,
        _PriceRange.r200_400 => 40000,
        _PriceRange.r400_600 => 60000,
        _PriceRange.r600_1000 => 100000,
        _PriceRange.over1000 => 200000,
      };

  String get label => switch (this) {
        _PriceRange.under200 => '₺200 altı',
        _PriceRange.r200_400 => '₺200–400',
        _PriceRange.r400_600 => '₺400–600',
        _PriceRange.r600_1000 => '₺600–1.000',
        _PriceRange.over1000 => '₺1.000 üzeri',
      };
}

class SmartRecommendationPage extends ConsumerStatefulWidget {
  const SmartRecommendationPage({super.key});

  @override
  ConsumerState<SmartRecommendationPage> createState() =>
      _SmartRecommendationPageState();
}

class _SmartRecommendationPageState
    extends ConsumerState<SmartRecommendationPage> {
  int _partySize = 2;
  _PriceRange _selectedRange = _PriceRange.r400_600;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loc = ref.watch(userLocationProvider);
    final query = SmartRecoQuery(
      city: loc.city ?? '',
      district: loc.district ?? '',
      partySize: _partySize,
      budgetMaxCents: _selectedRange.maxCents,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SafeArea(bottom: false, child: AppTopBar()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.smartRecoTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.smartRecoSubtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InputCard(
            partySize: _partySize,
            selectedRange: _selectedRange,
            onPartySizeChanged: (v) => setState(() => _partySize = v),
            onRangeChanged: (v) => setState(() => _selectedRange = v),
          ),
        ),
        const SizedBox(height: 16),
        _ResultsSection(query: query),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.partySize,
    required this.selectedRange,
    required this.onPartySizeChanged,
    required this.onRangeChanged,
  });

  final int partySize;
  final _PriceRange selectedRange;
  final ValueChanged<int> onPartySizeChanged;
  final ValueChanged<_PriceRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Kişi sayısı',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: partySize > 1
                    ? () => onPartySizeChanged(partySize - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                iconSize: 28,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$partySize',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              IconButton(
                onPressed: partySize < 8
                    ? () => onPartySizeChanged(partySize + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                iconSize: 28,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Bütçe aralığı',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              DropdownButton<_PriceRange>(
                value: selectedRange,
                underline: const SizedBox.shrink(),
                items: _PriceRange.values
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRangeChanged(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.query});

  final SmartRecoQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(smartRecoProvider(query));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: async.when(
        loading: () => Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: AppSkeletonCard(),
            ),
          ),
        ),
        error: (e, _) => Text(
          AppErrorMapper.message(e),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off_outlined,
              title: t.smartRecoEmptyTitle,
              description: t.smartRecoEmptyDesc,
            );
          }
          return Column(
            children: [
              for (final item in items) ...[
                RepaintBoundary(
                  child: _SmartBusinessCard(item: item),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              _ShuffleTile(query: query),
            ],
          );
        },
      ),
    );
  }
}

class _SmartBusinessCard extends ConsumerWidget {
  const _SmartBusinessCard({required this.item});

  final SmartRecommendation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: InkWell(
        onTap: () {
          ref.read(analyticsRepositoryProvider).logEvent(
            eventName: AppEvents.smartRecoBusinessOpen,
            businessId: item.businessId,
            source: 'smart_reco',
          );
          context.go('/b/${item.businessId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 80,
                      child: item.imageUrl != null
                          ? AppNetworkImage(
                              url: item.imageUrl!,
                              variant: AppImageVariant.thumb,
                              width: 100,
                              height: 80,
                            )
                          : Container(color: AppColors.cardAlt),
                    ),
                    if (item.discountPct != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '%${item.discountPct} indirim',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.cuisine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.cuisine!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.distanceKm != null) ...[
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.originalTotalCents != null) ...[
                          Text(
                            _formatCents(item.originalTotalCents!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatCents(item.totalCents),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleTile extends ConsumerWidget {
  const _ShuffleTile({required this.query});

  final SmartRecoQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: InkWell(
        onTap: () {
          ref.read(analyticsRepositoryProvider).logEvent(
            eventName: AppEvents.smartRecoShuffle,
            source: 'smart_reco',
          );
          ref.refresh(smartRecoProvider(query));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(
                Icons.shuffle_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                t.smartRecoShuffleLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.smartRecoShuffleDesc,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCents(int cents) {
  final tl = cents ~/ 100;
  final kr = cents % 100;
  if (kr == 0) return '₺$tl';
  return '₺$tl,${kr.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 2: Run analyze**

```
flutter analyze --no-fatal-warnings
```
Expected: 0 new errors.

- [ ] **Step 3: Commit**

```
git add uygulamalar/mobil/lib/features/smart_recommendation/
git commit -m "feat(smart-reco): SmartRecommendationPage UI"
```

---

### Task 7: Wire router + app_shell

**Files:**
- Modify: `uygulamalar/mobil/lib/app/app_shell.dart` — add `/budget-combos` to hideAppBar
- Modify: `uygulamalar/mobil/lib/app/router.dart` — simplify route, swap import

- [ ] **Step 1: Update `app_shell.dart` — add `/budget-combos` to hideAppBar**

File: `uygulamalar/mobil/lib/app/app_shell.dart`

Find (around line 39):
```dart
    final hideAppBar = widget.location.startsWith('/discover') ||
        widget.location.startsWith('/favorites') ||
        widget.location.startsWith('/inbox');
```

Replace with:
```dart
    final hideAppBar = widget.location.startsWith('/discover') ||
        widget.location.startsWith('/favorites') ||
        widget.location.startsWith('/inbox') ||
        widget.location.startsWith('/budget-combos');
```

- [ ] **Step 2: Update `router.dart` — swap import and simplify route**

File: `uygulamalar/mobil/lib/app/router.dart`

Find:
```dart
import '../features/budget_combos/ui/budget_combo_results_page.dart';
```
Replace with:
```dart
import '../features/smart_recommendation/ui/smart_recommendation_page.dart';
```

Find (the entire `/budget-combos` GoRoute block):
```dart
      GoRoute(
        path: '/budget-combos',
        pageBuilder: (c, s) {
          final qp = s.uri.queryParameters;
          final city = sanitizeFreeText(qp['city']);
          final district = sanitizeFreeText(qp['district']);
          final party = int.tryParse(qp['party'] ?? '') ?? 2;
          final budget = int.tryParse(qp['budget'] ?? '') ?? 0;
          final categoryRaw = sanitizeFreeText(qp['category']);
          final category = categoryRaw.isEmpty ? null : categoryRaw;
          final radius = double.tryParse(qp['radius'] ?? '');
          return buildFadeSlidePage(
            state: s,
            child: BudgetComboResultsPage(
              city: city,
              district: district,
              partySize: party,
              budgetTotalCents: budget,
              category: category,
              radiusKm: radius,
            ),
          );
        },
      ),
```
Replace with:
```dart
      GoRoute(
        path: '/budget-combos',
        pageBuilder: (c, s) => buildFadeSlidePage(
          state: s,
          child: const SmartRecommendationPage(),
        ),
      ),
```

- [ ] **Step 3: Run analyze**

```
flutter analyze --no-fatal-warnings
```
Expected: Errors pointing at `smart_feed_page.dart` (import of `BudgetComboEntryCard`). These will be resolved in the next task.

- [ ] **Step 4: Commit**

```
git add uygulamalar/mobil/lib/app/app_shell.dart uygulamalar/mobil/lib/app/router.dart
git commit -m "feat(smart-reco): wire router + app_shell hideAppBar"
```

---

### Task 8: Update smart_feed + labs_page

**Files:**
- Modify: `uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart`
- Modify: `uygulamalar/mobil/lib/features/shared/ui/labs_page.dart`

- [ ] **Step 1: Replace `BudgetComboEntryCard` in `smart_feed_page.dart`**

File: `uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart`

Remove this import:
```dart
import '../../budget_combos/ui/budget_combo_entry_card.dart';
```

Find (around line 85):
```dart
                  const BudgetComboEntryCard(),
```
Replace with:
```dart
                  const _SmartRecoPromoBanner(),
```

At the bottom of `smart_feed_page.dart` (before the last closing brace of the file), add:

```dart
class _SmartRecoPromoBanner extends StatelessWidget {
  const _SmartRecoPromoBanner();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.smartRecoTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.smartRecoSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => context.go('/budget-combos'),
            child: const Text('Keşfet'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update `labs_page.dart` title key**

File: `uygulamalar/mobil/lib/features/shared/ui/labs_page.dart`

Find:
```dart
          title: t.budgetComboResultsTitle,
```
Replace with:
```dart
          title: t.smartRecoTitle,
```

- [ ] **Step 3: Run analyze**

```
flutter analyze --no-fatal-warnings
```
Expected: Remaining errors only in `features/budget_combos/` — those will be removed in the next task.

- [ ] **Step 4: Commit**

```
git add uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart uygulamalar/mobil/lib/features/shared/ui/labs_page.dart
git commit -m "feat(smart-reco): replace BudgetComboEntryCard, update labs title"
```

---

### Task 9: Delete budget_combos + clean up old analytics events

**Files:**
- Delete: `uygulamalar/mobil/lib/features/budget_combos/` (5 files)
- Modify: `uygulamalar/mobil/lib/core/analytics/app_events.dart` — remove old `budgetCombo*` constants

- [ ] **Step 1: Remove old analytics constants from `app_events.dart`**

File: `uygulamalar/mobil/lib/core/analytics/app_events.dart`

Find and remove these two lines:
```dart
  static const budgetComboSearch = 'budget_combo_search';
  static const budgetComboBusinessOpen = 'budget_combo_business_open';
```

- [ ] **Step 2: Delete the entire budget_combos folder**

```
cd uygulamalar/mobil
Remove-Item -Recurse -Force lib/features/budget_combos
```

Or using bash:
```bash
rm -rf uygulamalar/mobil/lib/features/budget_combos
```

- [ ] **Step 3: Run analyze — must be clean**

```
flutter analyze --no-fatal-warnings
```
Expected: 0 errors. If any errors remain, they are references to old budget_combo symbols — fix them before continuing.

- [ ] **Step 4: Run all tests**

```
flutter test
```
Expected: All tests pass (6 new smart_reco model tests + existing tests).

- [ ] **Step 5: Final commit**

```
git add -A
git commit -m "feat(smart-reco): delete budget_combos feature (replaced by smart_recommendation)"
```

---

## Post-implementation check

After all tasks complete, verify the app works end-to-end:

1. Navigate to `/budget-combos` (via Labs or discovery sheet)
2. Confirm: shell AppBar is hidden, `AppTopBar` (hamburger + bell) appears at top
3. Change party size with +/- buttons
4. Change price range with dropdown
5. Cards appear with image, rating, distance, price chip
6. Tap "Şansını Dene!" — results reload with different ordering
7. Tap a business card — navigates to `/b/:id`
