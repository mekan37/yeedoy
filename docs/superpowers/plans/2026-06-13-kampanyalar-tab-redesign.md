# Kampanyalar Tab Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the mobile Discovery "Kampanyalar" tab with a hero/featured campaign card, search + filter chips, discount/category badges, and a bookmark/save feature — backed by new `business_stories` columns and a `saved_campaigns` table.

**Architecture:** New Supabase migration adds `discount_percent`/`category`/`is_featured` to `business_stories`, a `saved_campaigns` table with RLS, `get_nearby_campaign_stories_v2` RPC (adds those fields + `is_saved`), and `toggle_saved_campaign_v1` RPC. Mobile: extend `NearbyCampaign` model + add `CampaignFilter`/`applyCampaignFilter`, switch `DiscoveryRepository.fetchNearbyCampaigns` to v2 and add `toggleSavedCampaign`, convert `nearbyCampaignsProvider` to an `AsyncNotifierProvider` family with an optimistic `toggleSaved` method, and rebuild `discovery_campaigns_tab.dart` UI per the approved spec.

**Tech Stack:** Supabase (Postgres/plpgsql), Flutter, Riverpod 2.x, `flutter_riverpod`, ARB l10n.

**Spec:** `docs/superpowers/specs/2026-06-13-kampanyalar-tab-redesign-design.md`

---

### Task 1: Database migration — schema, v2 RPC, bookmark RPC

**Files:**
- Create: `supabase/migrations/20260613000001_campaign_redesign.sql`

- [ ] **Step 1: Write the migration file**

Create `supabase/migrations/20260613000001_campaign_redesign.sql` with this exact content:

```sql
-- Kampanyalar tab redesign: discount/category/featured metadata on campaign
-- stories, a saved_campaigns bookmark table, and v2 RPCs that expose them.

alter table public.business_stories
  add column discount_percent smallint,
  add column category text,
  add column is_featured boolean not null default false;

alter table public.business_stories
  add constraint business_stories_discount_percent_check
    check (discount_percent is null or (discount_percent >= 0 and discount_percent <= 100));

alter table public.business_stories
  add constraint business_stories_category_check
    check (category is null or category in ('yemek', 'tatli', 'icecek', 'kahve', 'diger'));

create table if not exists public.saved_campaigns (
  id uuid default gen_random_uuid() not null primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  story_id uuid not null references public.business_stories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, story_id)
);

alter table public.saved_campaigns enable row level security;

create policy saved_campaigns_select_own on public.saved_campaigns
  for select using (auth.uid() = user_id);

create policy saved_campaigns_insert_own on public.saved_campaigns
  for insert with check (auth.uid() = user_id);

create policy saved_campaigns_delete_own on public.saved_campaigns
  for delete using (auth.uid() = user_id);

-- get_nearby_campaign_stories_v2: adds discount_percent/category/is_featured/is_saved
-- and orders featured campaigns first.
create or replace function public.get_nearby_campaign_stories_v2(
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km integer default 10,
  p_city text default null,
  p_district text default null,
  p_limit integer default 20
)
returns table (
  story_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  caption text,
  media_url text,
  media_thumb_url text,
  created_at timestamptz,
  expires_at timestamptz,
  distance_km double precision,
  discount_percent smallint,
  category text,
  is_featured boolean,
  is_saved boolean
)
language sql
security definer
set search_path = public
as $$
  with src as (
    select
      s.id as story_id,
      s.business_id,
      b.name as business_name,
      b.city,
      b.district,
      s.caption,
      s.media_url,
      coalesce(s.media_thumb_url, s.media_url) as media_thumb_url,
      s.created_at,
      s.expires_at,
      s.discount_percent,
      s.category,
      s.is_featured,
      exists (
        select 1 from public.saved_campaigns sc
        where sc.user_id = auth.uid() and sc.story_id = s.id
      ) as is_saved,
      case
        when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
        else (
          6371.0 * acos(
            least(
              1.0,
              greatest(
                -1.0,
                cos(radians(p_lat)) * cos(radians(b.lat)) * cos(radians(b.lng) - radians(p_lng))
                + sin(radians(p_lat)) * sin(radians(b.lat))
              )
            )
          )
        )
      end as distance_km
    from public.business_stories s
    join public.businesses b on b.id = s.business_id
    where s.is_deleted = false
      and s.type = 'promo'::public.story_type
      and s.expires_at > now()
      and (
        p_lat is not null and p_lng is not null
        or (
          (p_city is null or trim(p_city) = '' or lower(b.city) = lower(trim(p_city)))
          and (p_district is null or trim(p_district) = '' or lower(b.district) = lower(trim(p_district)))
        )
      )
  )
  select
    story_id,
    business_id,
    business_name,
    city,
    district,
    caption,
    media_url,
    media_thumb_url,
    created_at,
    expires_at,
    distance_km,
    discount_percent,
    category,
    is_featured,
    is_saved
  from src
  where distance_km is null or distance_km <= greatest(coalesce(p_radius_km, 10), 1)
  order by is_featured desc, distance_km nulls last, created_at desc
  limit greatest(coalesce(p_limit, 20), 1);
$$;

grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to anon;
grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to authenticated;
grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to service_role;

comment on function public.get_nearby_campaign_stories_v1(double precision, double precision, integer, text, text, integer) is 'DEPRECATED 2026-06-13: use get_nearby_campaign_stories_v2';

-- toggle_saved_campaign_v1: bookmark/unbookmark a campaign story for the current user
create or replace function public.toggle_saved_campaign_v1(p_story_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing uuid;
  v_saved boolean;
begin
  if auth.uid() is null then
    raise exception 'unauthorized: Oturum açmanız gerekiyor' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from public.business_stories
    where id = p_story_id and is_deleted = false
  ) then
    raise exception 'not_found: Kampanya bulunamadı' using errcode = 'P0001';
  end if;

  select id into v_existing from public.saved_campaigns
    where user_id = auth.uid() and story_id = p_story_id;

  if v_existing is null then
    insert into public.saved_campaigns (user_id, story_id) values (auth.uid(), p_story_id);
    v_saved := true;
  else
    delete from public.saved_campaigns where id = v_existing;
    v_saved := false;
  end if;

  return jsonb_build_object('saved', v_saved);
end;
$$;

revoke all on function public.toggle_saved_campaign_v1(uuid) from public;
grant execute on function public.toggle_saved_campaign_v1(uuid) to authenticated;
comment on function public.toggle_saved_campaign_v1 is 'Toggles a saved/bookmarked campaign for the current user. Called by: discovery_repository.dart toggleSavedCampaign.';
```

- [ ] **Step 2: Apply the migration locally**

Run from repo root (`C:\yeedoy\.claude\worktrees\discovery-redesign`):

```bash
supabase db reset
```

Expected: completes without error, ending with the local stack re-seeded.

- [ ] **Step 3: Verify the new schema objects**

Run:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "\d public.business_stories" -c "\d public.saved_campaigns" -c "select proname from pg_proc where proname in ('get_nearby_campaign_stories_v2','toggle_saved_campaign_v1');"
```

Expected:
- `business_stories` description includes `discount_percent`, `category`, `is_featured` columns
- `saved_campaigns` table exists with `id`, `user_id`, `story_id`, `created_at`
- both `get_nearby_campaign_stories_v2` and `toggle_saved_campaign_v1` appear in the `proname` list

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260613000001_campaign_redesign.sql
git commit -m "feat: add campaign discount/category/featured fields and saved_campaigns table"
```

---

### Task 2: l10n keys for Kampanyalar redesign

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb`
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb`
- Modify (generated): `uygulamalar/mobil/lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart`

- [ ] **Step 1: Add new keys to `app_tr.arb`**

In `uygulamalar/mobil/lib/l10n/app_tr.arb`, add these entries near the existing `nearbyCampaignsAndAnnouncements` / `campaign` / `active` keys (around line 763-768):

```json
  "campaignsGreeting": "Merhaba! 👋",
  "@campaignsGreeting": {
    "description": "Auto metadata for campaignsGreeting"
  },
  "campaignsSearchPlaceholder": "Kampanya veya işletme ara...",
  "@campaignsSearchPlaceholder": {
    "description": "Auto metadata for campaignsSearchPlaceholder"
  },
  "campaignFilterAll": "Tümü",
  "@campaignFilterAll": {
    "description": "Auto metadata for campaignFilterAll"
  },
  "campaignFilterSoon": "Yakında",
  "@campaignFilterSoon": {
    "description": "Auto metadata for campaignFilterSoon"
  },
  "campaignFilterToday": "Bugün",
  "@campaignFilterToday": {
    "description": "Auto metadata for campaignFilterToday"
  },
  "campaignFilterFood": "Yemek",
  "@campaignFilterFood": {
    "description": "Auto metadata for campaignFilterFood"
  },
  "campaignFilterDessert": "Tatlı",
  "@campaignFilterDessert": {
    "description": "Auto metadata for campaignFilterDessert"
  },
  "campaignFilterDiscount20": "%20+",
  "@campaignFilterDiscount20": {
    "description": "Auto metadata for campaignFilterDiscount20"
  },
  "campaignsNearbyHeader": "Yakınındaki kampanyalar",
  "@campaignsNearbyHeader": {
    "description": "Auto metadata for campaignsNearbyHeader"
  },
  "campaignsFeaturedBadge": "Lezzet Fırsatları",
  "@campaignsFeaturedBadge": {
    "description": "Auto metadata for campaignsFeaturedBadge"
  },
  "campaignDiscountLabel": "%{percent} indirim",
  "@campaignDiscountLabel": {
    "placeholders": {
      "percent": {
        "type": "int"
      }
    },
    "description": "Auto metadata for campaignDiscountLabel"
  },
```

- [ ] **Step 2: Add matching keys to `app_en.arb`**

In `uygulamalar/mobil/lib/l10n/app_en.arb`, add the corresponding English entries (use the same key order/positions as `app_tr.arb`):

```json
  "campaignsGreeting": "Hello! 👋",
  "@campaignsGreeting": {
    "description": "Auto metadata for campaignsGreeting"
  },
  "campaignsSearchPlaceholder": "Search campaigns or businesses...",
  "@campaignsSearchPlaceholder": {
    "description": "Auto metadata for campaignsSearchPlaceholder"
  },
  "campaignFilterAll": "All",
  "@campaignFilterAll": {
    "description": "Auto metadata for campaignFilterAll"
  },
  "campaignFilterSoon": "Ending soon",
  "@campaignFilterSoon": {
    "description": "Auto metadata for campaignFilterSoon"
  },
  "campaignFilterToday": "Today",
  "@campaignFilterToday": {
    "description": "Auto metadata for campaignFilterToday"
  },
  "campaignFilterFood": "Food",
  "@campaignFilterFood": {
    "description": "Auto metadata for campaignFilterFood"
  },
  "campaignFilterDessert": "Dessert",
  "@campaignFilterDessert": {
    "description": "Auto metadata for campaignFilterDessert"
  },
  "campaignFilterDiscount20": "20%+",
  "@campaignFilterDiscount20": {
    "description": "Auto metadata for campaignFilterDiscount20"
  },
  "campaignsNearbyHeader": "Campaigns near you",
  "@campaignsNearbyHeader": {
    "description": "Auto metadata for campaignsNearbyHeader"
  },
  "campaignsFeaturedBadge": "Tasty Deals",
  "@campaignsFeaturedBadge": {
    "description": "Auto metadata for campaignsFeaturedBadge"
  },
  "campaignDiscountLabel": "{percent}% off",
  "@campaignDiscountLabel": {
    "placeholders": {
      "percent": {
        "type": "int"
      }
    },
    "description": "Auto metadata for campaignDiscountLabel"
  },
```

- [ ] **Step 3: Regenerate localization code**

Run from `uygulamalar/mobil`:

```bash
flutter gen-l10n
```

Expected: completes without error. Verify the new getters exist:

```bash
grep -n "campaignDiscountLabel\|campaignsFeaturedBadge\|campaignFilterAll" lib/l10n/app_localizations_tr.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations.dart
```

Expected: each file shows matching declarations/definitions for all three keys.

- [ ] **Step 4: Run the l10n audit**

Run from repo root (`C:\yeedoy\.claude\worktrees\discovery-redesign`):

```bash
node tools/ceviri-denetimi.mjs
```

Expected: "l10n audit passed".

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/l10n/app_tr.arb uygulamalar/mobil/lib/l10n/app_en.arb uygulamalar/mobil/lib/l10n/app_localizations.dart uygulamalar/mobil/lib/l10n/app_localizations_en.dart uygulamalar/mobil/lib/l10n/app_localizations_tr.dart
git commit -m "feat: add l10n keys for Kampanyalar tab redesign"
```

---

### Task 3: `NearbyCampaign` model — new fields, `CampaignFilter`, `applyCampaignFilter`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/domain/nearby_campaign.dart`
- Test: `uygulamalar/mobil/test/features/discovery/domain/nearby_campaign_test.dart`

- [ ] **Step 1: Write the failing test**

Create `uygulamalar/mobil/test/features/discovery/domain/nearby_campaign_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/discovery/domain/nearby_campaign.dart';

void main() {
  group('NearbyCampaign.fromMap', () {
    test('parses discount/category/featured/saved fields', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-1',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
        'discount_percent': 25,
        'category': 'tatli',
        'is_featured': true,
        'is_saved': true,
      });

      expect(campaign.storyId, 'story-1');
      expect(campaign.discountPercent, 25);
      expect(campaign.category, 'tatli');
      expect(campaign.isFeatured, isTrue);
      expect(campaign.isSaved, isTrue);
    });

    test('defaults new fields when absent', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-2',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
      });

      expect(campaign.discountPercent, isNull);
      expect(campaign.category, isNull);
      expect(campaign.isFeatured, isFalse);
      expect(campaign.isSaved, isFalse);
    });
  });

  group('NearbyCampaign.copyWith', () {
    test('overrides isSaved without mutating other fields', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-1',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
        'is_saved': false,
      });

      final updated = campaign.copyWith(isSaved: true);

      expect(updated.isSaved, isTrue);
      expect(updated.storyId, campaign.storyId);
      expect(updated.businessName, campaign.businessName);
    });
  });

  group('applyCampaignFilter', () {
    final now = DateTime.utc(2026, 6, 13, 12, 0, 0);

    NearbyCampaign campaign({
      String storyId = 's',
      DateTime? expiresAt,
      String? category,
      int? discountPercent,
    }) {
      return NearbyCampaign.fromMap({
        'story_id': storyId,
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': (expiresAt ?? now.add(const Duration(days: 2)))
            .toIso8601String(),
        'category': category,
        'discount_percent': discountPercent,
      });
    }

    test('all returns every item', () {
      final items = [campaign(storyId: 'a'), campaign(storyId: 'b')];
      expect(applyCampaignFilter(items, CampaignFilter.all, now: now), items);
    });

    test('soon keeps items expiring within 24 hours', () {
      final soon = campaign(
        storyId: 'soon',
        expiresAt: now.add(const Duration(hours: 5)),
      );
      final later = campaign(
        storyId: 'later',
        expiresAt: now.add(const Duration(days: 3)),
      );
      final result = applyCampaignFilter(
        [soon, later],
        CampaignFilter.soon,
        now: now,
      );
      expect(result, [soon]);
    });

    test('today keeps items expiring on the same calendar date', () {
      final today = campaign(
        storyId: 'today',
        expiresAt: DateTime.utc(2026, 6, 13, 23, 0, 0),
      );
      final tomorrow = campaign(
        storyId: 'tomorrow',
        expiresAt: DateTime.utc(2026, 6, 14, 1, 0, 0),
      );
      final result = applyCampaignFilter(
        [today, tomorrow],
        CampaignFilter.today,
        now: now,
      );
      expect(result, [today]);
    });

    test('food keeps category == yemek', () {
      final food = campaign(storyId: 'food', category: 'yemek');
      final dessert = campaign(storyId: 'dessert', category: 'tatli');
      final result = applyCampaignFilter(
        [food, dessert],
        CampaignFilter.food,
        now: now,
      );
      expect(result, [food]);
    });

    test('dessert keeps category == tatli', () {
      final food = campaign(storyId: 'food', category: 'yemek');
      final dessert = campaign(storyId: 'dessert', category: 'tatli');
      final result = applyCampaignFilter(
        [food, dessert],
        CampaignFilter.dessert,
        now: now,
      );
      expect(result, [dessert]);
    });

    test('discount20 keeps discountPercent >= 20', () {
      final big = campaign(storyId: 'big', discountPercent: 25);
      final small = campaign(storyId: 'small', discountPercent: 10);
      final none = campaign(storyId: 'none');
      final result = applyCampaignFilter(
        [big, small, none],
        CampaignFilter.discount20,
        now: now,
      );
      expect(result, [big]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `uygulamalar/mobil`:

```bash
flutter test test/features/discovery/domain/nearby_campaign_test.dart
```

Expected: FAIL — compile errors (`storyId`, `copyWith`, `CampaignFilter`, `applyCampaignFilter` are not defined).

- [ ] **Step 3: Implement the model and filter logic**

Replace the full contents of `uygulamalar/mobil/lib/features/discovery/domain/nearby_campaign.dart` with:

```dart
class NearbyCampaign {
  NearbyCampaign({
    required this.storyId,
    required this.businessId,
    required this.businessName,
    required this.city,
    required this.district,
    required this.caption,
    required this.mediaThumbUrl,
    required this.expiresAt,
    this.distanceKm,
    this.discountPercent,
    this.category,
    this.isFeatured = false,
    this.isSaved = false,
  });

  final String storyId;
  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String? caption;
  final String mediaThumbUrl;
  final DateTime expiresAt;
  final double? distanceKm;
  final int? discountPercent;
  final String? category;
  final bool isFeatured;
  final bool isSaved;

  factory NearbyCampaign.fromMap(Map<String, dynamic> map) {
    return NearbyCampaign(
      storyId: (map['story_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      city: map['city']?.toString(),
      district: map['district']?.toString(),
      caption: map['caption']?.toString(),
      mediaThumbUrl: (map['media_thumb_url'] ?? map['media_url'] ?? '')
          .toString(),
      expiresAt:
          DateTime.tryParse((map['expires_at'] ?? '').toString()) ??
          DateTime.now(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      discountPercent: (map['discount_percent'] as num?)?.toInt(),
      category: map['category']?.toString(),
      isFeatured: map['is_featured'] == true,
      isSaved: map['is_saved'] == true,
    );
  }

  NearbyCampaign copyWith({bool? isSaved}) {
    return NearbyCampaign(
      storyId: storyId,
      businessId: businessId,
      businessName: businessName,
      city: city,
      district: district,
      caption: caption,
      mediaThumbUrl: mediaThumbUrl,
      expiresAt: expiresAt,
      distanceKm: distanceKm,
      discountPercent: discountPercent,
      category: category,
      isFeatured: isFeatured,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

enum CampaignFilter { all, soon, today, food, dessert, discount20 }

List<NearbyCampaign> applyCampaignFilter(
  List<NearbyCampaign> items,
  CampaignFilter filter, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  switch (filter) {
    case CampaignFilter.all:
      return items;
    case CampaignFilter.soon:
      return items
          .where(
            (c) =>
                c.expiresAt.difference(reference) <= const Duration(hours: 24),
          )
          .toList();
    case CampaignFilter.today:
      return items.where((c) {
        final expires = c.expiresAt;
        return expires.year == reference.year &&
            expires.month == reference.month &&
            expires.day == reference.day;
      }).toList();
    case CampaignFilter.food:
      return items.where((c) => c.category == 'yemek').toList();
    case CampaignFilter.dessert:
      return items.where((c) => c.category == 'tatli').toList();
    case CampaignFilter.discount20:
      return items
          .where(
            (c) => c.discountPercent != null && c.discountPercent! >= 20,
          )
          .toList();
  }
}

List<NearbyCampaign> toggleCampaignSavedInList(
  List<NearbyCampaign> items,
  String storyId,
  bool saved,
) {
  return [
    for (final item in items)
      if (item.storyId == storyId) item.copyWith(isSaved: saved) else item,
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run from `uygulamalar/mobil`:

```bash
flutter test test/features/discovery/domain/nearby_campaign_test.dart
```

Expected: PASS — all tests green.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/domain/nearby_campaign.dart uygulamalar/mobil/test/features/discovery/domain/nearby_campaign_test.dart
git commit -m "feat: add discount/category/featured/saved fields and campaign filters to NearbyCampaign"
```

---

### Task 4: `DiscoveryRepository` — switch to v2 RPC, add `toggleSavedCampaign`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart:448-503`

- [ ] **Step 1: Update `fetchNearbyCampaigns` to call `get_nearby_campaign_stories_v2`**

In `uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart`, replace the `fetchNearbyCampaigns` method (currently lines 448-503) with:

```dart
  Future<List<NearbyCampaign>> fetchNearbyCampaigns({
    double? lat,
    double? lng,
    int radiusKm = 10,
    String? city,
    String? district,
    int limit = 20,
  }) async {
    final cacheKey = _key('nearby_campaigns_v2', {
      'lat': lat?.toStringAsFixed(4),
      'lng': lng?.toStringAsFixed(4),
      'radius': radiusKm,
      'city': city?.trim(),
      'district': district?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<NearbyCampaign>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<NearbyCampaign>>(
        operation: 'get_nearby_campaign_stories_v2',
        run: () async {
          final res = await client.rpc(
            'get_nearby_campaign_stories_v2',
            params: {
              'p_lat': lat,
              'p_lng': lng,
              'p_radius_km': radiusKm,
              'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
              'p_district': (district ?? '').trim().isEmpty
                  ? null
                  : district!.trim(),
              'p_limit': limit,
            },
          );
          return (res as List)
              .whereType<Map>()
              .map((row) => NearbyCampaign.fromMap(row.cast<String, dynamic>()))
              .toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<NearbyCampaign>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<bool> toggleSavedCampaign(String storyId) async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'toggle_saved_campaign_v1',
      run: () => client.rpc(
        'toggle_saved_campaign_v1',
        params: {'p_story_id': storyId},
      ),
      sampleRate: 1,
    );
    if (res is Map && res['saved'] == true) return true;
    return false;
  }
```

This replaces the closing `}` of the old method too — the new `toggleSavedCampaign` method is added as a sibling method right after `fetchNearbyCampaigns`, both inside the `DiscoveryRepository` class.

- [ ] **Step 2: Run static analysis**

Run from `uygulamalar/mobil`:

```bash
flutter analyze lib/features/discovery/data/discovery_repository.dart
```

Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/data/discovery_repository.dart
git commit -m "feat: switch fetchNearbyCampaigns to v2 RPC and add toggleSavedCampaign"
```

---

### Task 5: Providers — filter/search state + `NearbyCampaignsNotifier.toggleSaved`

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/domain/nearby_campaigns_provider.dart`

- [ ] **Step 1: Replace the provider file**

Replace the full contents of `uygulamalar/mobil/lib/features/discovery/domain/nearby_campaigns_provider.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_repository.dart';
import 'nearby_campaign.dart';

typedef NearbyCampaignsParams = ({
  double? lat,
  double? lng,
  int radiusKm,
  String? city,
  String? district,
  int limit,
});

final campaignsFilterProvider = StateProvider<CampaignFilter>(
  (ref) => CampaignFilter.all,
);

final campaignsSearchQueryProvider = StateProvider<String>((ref) => '');

class NearbyCampaignsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<NearbyCampaign>, NearbyCampaignsParams> {
  @override
  Future<List<NearbyCampaign>> build(NearbyCampaignsParams arg) {
    return ref
        .read(discoveryRepositoryProvider)
        .fetchNearbyCampaigns(
          lat: arg.lat,
          lng: arg.lng,
          radiusKm: arg.radiusKm,
          city: arg.city,
          district: arg.district,
          limit: arg.limit,
        );
  }

  Future<void> toggleSaved(String storyId) async {
    final current = state.value;
    if (current == null) return;

    NearbyCampaign? target;
    for (final c in current) {
      if (c.storyId == storyId) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final optimistic = toggleCampaignSavedInList(
      current,
      storyId,
      !target.isSaved,
    );
    state = AsyncData(optimistic);

    try {
      final saved = await ref
          .read(discoveryRepositoryProvider)
          .toggleSavedCampaign(storyId);
      state = AsyncData(toggleCampaignSavedInList(optimistic, storyId, saved));
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final nearbyCampaignsProvider = AsyncNotifierProvider.autoDispose
    .family<NearbyCampaignsNotifier, List<NearbyCampaign>, NearbyCampaignsParams>(
      NearbyCampaignsNotifier.new,
    );
```

- [ ] **Step 2: Run static analysis**

Run from `uygulamalar/mobil`:

```bash
flutter analyze lib/features/discovery/domain/nearby_campaigns_provider.dart
```

Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/domain/nearby_campaigns_provider.dart
git commit -m "feat: add campaign filter/search providers and optimistic save toggle"
```

---

### Task 6: Kampanyalar tab UI — header, search, filter chips, hero card, list cards

**Files:**
- Modify: `uygulamalar/mobil/lib/features/discovery/ui/surfaces/discovery_campaigns_tab.dart`

- [ ] **Step 1: Replace the full tab implementation**

Replace the full contents of `uygulamalar/mobil/lib/features/discovery/ui/surfaces/discovery_campaigns_tab.dart` with:

```dart
part of '../discovery_page.dart';

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final campaignParams = ref.watch(
      discoverySearchProvider.select(
        (s) => (
          lat: s.userLat,
          lng: s.userLng,
          radiusKm: s.radiusKm,
          city: s.city,
          district: s.district,
        ),
      ),
    );
    final params = (
      lat: campaignParams.lat,
      lng: campaignParams.lng,
      radiusKm: campaignParams.radiusKm,
      city: campaignParams.city,
      district: campaignParams.district,
      limit: 24,
    );
    final campaignsAsync = ref.watch(nearbyCampaignsProvider(params));
    final filter = ref.watch(campaignsFilterProvider);
    final query = ref.watch(campaignsSearchQueryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nearbyCampaignsProvider(params));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            sliver: SliverList.list(
              children: [
                const _CampaignsHeaderRow(),
                const SizedBox(height: 12),
                const _CampaignsSearchField(),
                const SizedBox(height: 12),
                const _CampaignFilterChips(),
                const SizedBox(height: 16),
                campaignsAsync.when(
                  loading: () => const _DiscoverySkeleton(),
                  error: (e, _) => AppCard(
                    child: Text(
                      AppErrorMapper.message(e),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  data: (items) {
                    final filtered = applyCampaignFilter(items, filter)
                        .where((c) => _campaignMatchesQuery(c, query))
                        .toList();
                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.campaign_outlined,
                        title: t.noNearbyCampaign,
                        description: t.noActiveAnnouncementInArea,
                      );
                    }

                    NearbyCampaign? hero;
                    for (final c in filtered) {
                      if (c.isFeatured) {
                        hero = c;
                        break;
                      }
                    }
                    final rest = hero == null
                        ? filtered
                        : filtered
                              .where((c) => c.storyId != hero!.storyId)
                              .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hero != null) ...[
                          SizedBox(
                            height: 200,
                            child: _CampaignHeroCard(item: hero),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (rest.isNotEmpty) ...[
                          Text(
                            t.campaignsNearbyHeader,
                            style: context.sectionTitleStyle,
                          ),
                          const SizedBox(height: 12),
                          for (final item in rest) ...[
                            _CampaignCard(item: item, params: params),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _campaignMatchesQuery(NearbyCampaign item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return item.businessName.toLowerCase().contains(q) ||
      (item.caption ?? '').toLowerCase().contains(q);
}

class _CampaignsHeaderRow extends StatelessWidget {
  const _CampaignsHeaderRow();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.campaignsGreeting,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                t.tabCampaigns,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const NotificationsBell(),
      ],
    );
  }
}

class _CampaignsSearchField extends ConsumerStatefulWidget {
  const _CampaignsSearchField();

  @override
  ConsumerState<_CampaignsSearchField> createState() =>
      _CampaignsSearchFieldState();
}

class _CampaignsSearchFieldState extends ConsumerState<_CampaignsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(campaignsSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(campaignsSearchQueryProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: t.campaignsSearchPlaceholder,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.cardAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _CampaignFilterChips extends ConsumerWidget {
  const _CampaignFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final selected = ref.watch(campaignsFilterProvider);
    final entries = <(CampaignFilter, String)>[
      (CampaignFilter.all, t.campaignFilterAll),
      (CampaignFilter.soon, t.campaignFilterSoon),
      (CampaignFilter.today, t.campaignFilterToday),
      (CampaignFilter.food, t.campaignFilterFood),
      (CampaignFilter.dessert, t.campaignFilterDessert),
      (CampaignFilter.discount20, t.campaignFilterDiscount20),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries) ...[
            CategoryChip(
              label: entry.$2,
              selected: selected == entry.$1,
              onTap: () =>
                  ref.read(campaignsFilterProvider.notifier).state = entry.$1,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CampaignHeroCard extends StatelessWidget {
  const _CampaignHeroCard({required this.item});

  final NearbyCampaign item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(tokens.radius20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/b/${item.businessId}'),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppNetworkImage(url: item.mediaThumbUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '⭐ ${t.campaignsFeaturedBadge}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      if (item.discountPercent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.campaignDiscountLabel(item.discountPercent!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${t.remainingLabel}: ${_campaignTimeLeft(context, item.expiresAt)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: tokens.space16,
              right: tokens.space16,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({required this.item, required this.params});

  final NearbyCampaign item;
  final NearbyCampaignsParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final remaining = _campaignTimeLeft(context, item.expiresAt);
    final urgent = item.expiresAt.difference(DateTime.now()).inHours < 2;

    return AppCard(
      onTap: () {
        unawaited(
          _logDiscoveryClick(
            ref.read(analyticsRepositoryProvider),
            businessId: item.businessId,
            source: 'campaign',
          ),
        );
        context.go('/b/${item.businessId}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: item.mediaThumbUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              if (item.discountPercent != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%${item.discountPercent}',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.caption ?? '').trim().isEmpty
                      ? item.businessName
                      : item.caption!.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.businessName,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.distanceKm != null) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: urgent ? AppColors.danger : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      remaining,
                      style: TextStyle(
                        color: urgent ? AppColors.danger : AppColors.muted,
                        fontSize: 12,
                        fontWeight: urgent ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (user != null)
                IconButton(
                  onPressed: () => ref
                      .read(nearbyCampaignsProvider(params).notifier)
                      .toggleSaved(item.storyId),
                  icon: Icon(
                    item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: item.isSaved ? AppColors.primary : AppColors.muted,
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run static analysis**

Run from `uygulamalar/mobil`:

```bash
flutter analyze lib/features/discovery
```

Expected: "No issues found!" — fix any reported issues (e.g. unused imports) before continuing.

- [ ] **Step 3: Run the existing discovery test suite**

```bash
flutter test test/features/discovery
```

Expected: all tests pass (including the new `nearby_campaign_test.dart` from Task 3 and the existing `discovery_feed_composer_test.dart`).

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/discovery/ui/surfaces/discovery_campaigns_tab.dart
git commit -m "feat: redesign Kampanyalar tab with hero card, filters, search, and bookmarks"
```

---

### Task 7: Final validation

**Files:** none (validation only)

- [ ] **Step 1: Full Flutter analyze**

Run from `uygulamalar/mobil`:

```bash
flutter analyze
```

Expected: "No issues found!"

- [ ] **Step 2: Full discovery test run**

```bash
flutter test test/features/discovery
```

Expected: all tests pass.

- [ ] **Step 3: l10n audit**

Run from repo root:

```bash
node tools/ceviri-denetimi.mjs
```

Expected: "l10n audit passed".

- [ ] **Step 4: Manual smoke check (if a device/emulator is available)**

Run from `uygulamalar/mobil`:

```bash
flutter run -d <device>
```

Navigate to Discovery → Kampanyalar tab. Verify:
- Greeting + "Kampanyalar" title + notification bell render
- Search field filters the list by business name/caption
- Filter chips (Tümü/Yakında/Bugün/Yemek/Tatlı/%20+) narrow the list
- If no campaign has `is_featured = true` (expected on a fresh seed), the hero card is hidden and the list renders normally
- Bookmark icon is hidden for anonymous users and toggles for signed-in users

If no device is available, state this step was skipped.
