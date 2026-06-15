# Kampanyalar Tab Redesign — Design Spec

Date: 2026-06-13
Status: Approved

## Context

The mobile Discovery page's "Kampanyalar" tab (`discovery_campaigns_tab.dart`) currently shows a
simple `AppCard` header + flat list of `_CampaignCard` rows built from `get_nearby_campaign_stories_v1`
(`business_stories` with `type='promo'`). A new mockup calls for a richer layout: greeting + bell,
search bar, category/time/discount filter chips, a featured "hero" campaign card, and list cards with
discount badges, distance, time-remaining urgency color, and a bookmark/save action.

The current `business_stories` schema has no `discount_percent`, `category`, or `is_featured` fields,
and there is no saved/bookmarked-campaigns persistence. No client app currently has a campaign
creation/edit form (the `create_business_story_v1` RPC exists but is unused by any client).

## Scope

In scope:
- Migration adding `discount_percent`, `category`, `is_featured` to `business_stories`
- New `saved_campaigns` table + RLS
- `get_nearby_campaign_stories_v2` RPC + `toggle_saved_campaign_v1` RPC
- Mobile `NearbyCampaign` model, repository, providers
- Mobile Kampanyalar tab UI redesign (header, search, filter chips, hero card, list cards, bookmark)
- l10n keys (TR/EN) for new UI strings

Out of scope (explicitly deferred):
- Owner/Personel campaign creation or editing form (including setting `discount_percent`, `category`,
  `is_featured`). New columns default to `NULL`/`false` and the UI degrades gracefully (no badge, no
  hero) until that form exists as a separate piece of work.

## 1. Data model / migration

New migration file: `supabase/migrations/20260613000001_campaign_redesign.sql`

### `business_stories` additions (only meaningful for `type = 'promo'`)

```sql
ALTER TABLE public.business_stories
  ADD COLUMN discount_percent smallint,
  ADD COLUMN category text,
  ADD COLUMN is_featured boolean NOT NULL DEFAULT false;

ALTER TABLE public.business_stories
  ADD CONSTRAINT business_stories_discount_percent_check
    CHECK (discount_percent IS NULL OR (discount_percent >= 0 AND discount_percent <= 100));

ALTER TABLE public.business_stories
  ADD CONSTRAINT business_stories_category_check
    CHECK (category IS NULL OR category IN ('yemek', 'tatli', 'icecek', 'kahve', 'diger'));
```

Category taxonomy (`yemek`, `tatli`, `icecek`, `kahve`, `diger`) maps directly to the mobile filter
chips (Yemek/Tatlı/...). `diger` is the fallback for campaigns that don't fit a specific food category.

### New table: `saved_campaigns`

```sql
CREATE TABLE IF NOT EXISTS public.saved_campaigns (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES public.business_stories(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, story_id)
);

ALTER TABLE public.saved_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY saved_campaigns_select_own ON public.saved_campaigns
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY saved_campaigns_insert_own ON public.saved_campaigns
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY saved_campaigns_delete_own ON public.saved_campaigns
  FOR DELETE USING (auth.uid() = user_id);
```

No UPDATE policy — toggling is insert-or-delete only.

## 2. RPC changes

### `get_nearby_campaign_stories_v2`

Same input params as v1: `p_lat`, `p_lng`, `p_radius_km DEFAULT 10`, `p_city`, `p_district`,
`p_limit DEFAULT 20`.

New/changed return columns (in addition to v1's `story_id, business_id, business_name, city, district,
caption, media_url, media_thumb_url, created_at, expires_at, distance_km`):
- `discount_percent smallint`
- `category text`
- `is_featured boolean`
- `is_saved boolean` — `true` if a row exists in `saved_campaigns` for `(auth.uid(), story_id)`;
  `false` when `auth.uid() IS NULL` (anonymous) or no row

Ordering: `is_featured DESC, distance_km NULLS LAST, created_at DESC`. The mobile client treats the
first row with `is_featured = true` (if any, after the `is_featured DESC` sort it would be first) as
the hero campaign; if no campaign is featured, the hero section is hidden entirely.

Same `SECURITY DEFINER`, `SET search_path = public`, haversine distance logic, and
`is_deleted = false AND type = 'promo' AND expires_at > now()` filter as v1.

`get_nearby_campaign_stories_v1` gets:
```sql
COMMENT ON FUNCTION public.get_nearby_campaign_stories_v1(...) IS 'DEPRECATED 2026-06-13: use get_nearby_campaign_stories_v2';
```
kept for 90 days (remove after 2026-09-11).

Grants: `anon`, `authenticated`, `service_role` (same as v1) — `is_saved` resolves to `false` for
`anon` since `auth.uid()` is `NULL`.

### `toggle_saved_campaign_v1(p_story_id uuid)`

```sql
CREATE OR REPLACE FUNCTION public.toggle_saved_campaign_v1(p_story_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing uuid;
  v_saved boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.business_stories WHERE id = p_story_id AND is_deleted = false) THEN
    RAISE EXCEPTION 'not_found: Kampanya bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  SELECT id INTO v_existing FROM public.saved_campaigns
    WHERE user_id = auth.uid() AND story_id = p_story_id;

  IF v_existing IS NULL THEN
    INSERT INTO public.saved_campaigns (user_id, story_id) VALUES (auth.uid(), p_story_id);
    v_saved := true;
  ELSE
    DELETE FROM public.saved_campaigns WHERE id = v_existing;
    v_saved := false;
  END IF;

  RETURN jsonb_build_object('saved', v_saved);
END;
$$;

REVOKE ALL ON FUNCTION public.toggle_saved_campaign_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.toggle_saved_campaign_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.toggle_saved_campaign_v1 IS 'Toggles a saved/bookmarked campaign for the current user. Called by: discovery_repository.dart toggleSavedCampaign.';
```

Not granted to `anon` — bookmarking requires a session. The mobile UI hides/disables the bookmark
action for anonymous users (existing pattern used elsewhere for auth-gated actions).

## 3. Mobile data/domain layer

### `NearbyCampaign` model (`lib/features/discovery/domain/nearby_campaign.dart`)

Add fields, all parsed in `fromMap`:
- `final int? discountPercent;` ← `discount_percent`
- `final String? category;` ← `category`
- `final bool isFeatured;` ← `is_featured` (default `false`)
- `final bool isSaved;` ← `is_saved` (default `false`)

### `DiscoveryRepository` (`lib/features/discovery/data/discovery_repository.dart`)

- `fetchNearbyCampaigns(...)` switches its RPC call from `get_nearby_campaign_stories_v1` to
  `get_nearby_campaign_stories_v2`; cache key gains a version suffix (e.g. `nearby_campaigns_v2`) so
  stale v1-shaped cache entries aren't reused.
- New method `toggleSavedCampaign(String storyId)` — calls `toggle_saved_campaign_v1` via
  `_telemetry.traceRpc`, returns the resulting `bool saved`. No caching (mutation).

### Providers (`lib/features/discovery/domain/nearby_campaigns_provider.dart`)

- `NearbyCampaignsParams` and `nearbyCampaignsProvider` signatures unchanged.
- New `CampaignsController extends Notifier<void>` (or a thin wrapper) exposing
  `toggleSaved(NearbyCampaignsParams params, String storyId)`: calls
  `discoveryRepository.toggleSavedCampaign(storyId)`, then optimistically updates the cached
  `AsyncValue<List<NearbyCampaign>>` for `nearbyCampaignsProvider(params)` by flipping `isSaved` on the
  matching item (via `ref.invalidateSelf` fallback if the optimistic update fails).

### Filter state

- New enum `CampaignFilter { all, soon, today, food, dessert, discount20 }` in
  `nearby_campaign.dart` (or a new small `campaign_filter.dart` in `domain/`).
- New `campaignsFilterProvider = StateProvider<CampaignFilter>((ref) => CampaignFilter.all)` —
  local UI state, not persisted.
- Filtering logic (pure function `applyCampaignFilter(List<NearbyCampaign>, CampaignFilter)`):
  - `soon`: `expiresAt` within next 24h (excluding `today`'s same-day cutoff is not required — "Yakında"
    simply means expiring soon, e.g. `expiresAt.difference(now) <= 24h`)
  - `today`: `expiresAt` is on the current calendar date
  - `food`: `category == 'yemek'`
  - `dessert`: `category == 'tatli'`
  - `discount20`: `discountPercent != null && discountPercent! >= 20`
  - `all`: no filter
- Search query (separate `campaignsSearchQueryProvider = StateProvider<String>((ref) => '')`) filters
  by case-insensitive substring match on `businessName` or `caption`.
- Both filter and search are applied client-side to the already-fetched list (≤24 items) — no new RPC
  params.

## 4. UI breakdown (`lib/features/discovery/ui/surfaces/discovery_campaigns_tab.dart`)

`_CampaignsTab` (`ConsumerWidget`) restructured as a `CustomScrollView` with these slivers, top to
bottom:

1. **Header row** — "Merhaba! 👋" (greeting, reuse the same time-of-day greeting logic as
   `_DiscoveryGreetingHeader` if present) + large "Kampanyalar" title + `NotificationsBell` (existing
   component from `discovery_page.dart` topbar, reused here).
2. **Search bar** — new `_CampaignsSearchBar` styled like `DiscoverySearchBar`, bound to
   `campaignsSearchQueryProvider`. Placeholder: "Kampanya veya işletme ara...".
3. **Filter chips row** — horizontal scroll of `CategoryChip`-style chips for each `CampaignFilter`
   value, active chip styled with `AppColors.primary` background / `AppColors.onPrimary` text. Tapping
   sets `campaignsFilterProvider`.
4. **Hero card** (`_CampaignHeroCard`) — rendered only if the (filtered) list contains an item with
   `isFeatured == true` (first such item after backend ordering). Shows:
   - "⭐ Lezzet Fırsatları" badge
   - business name
   - large `%XX indirim` text (only rendered if `discountPercent != null`; otherwise this line is
     omitted and the layout collapses gracefully)
   - time-remaining via existing `_campaignTimeLeft(context, expiresAt)`
   - `media_url`/`media_thumb_url` image
   - red circular arrow button → `context.push('/b/${businessId}')` (same navigation + analytics
     event as existing `_CampaignCard.onTap`)
5. **"Yakındaki kampanyalar" section header** — `Text` styled like existing section headers
   (`AppTypographyX.sectionTitleStyle`).
6. **List** — `_CampaignCard` (reworked) per remaining item (excluding the hero item if shown):
   - Thumbnail (`media_thumb_url`/`media_url`) with red `%XX` corner badge — badge hidden if
     `discountPercent == null`
   - Title: campaign caption or a generated title (e.g. business name + category) — caption remains
     primary per existing behavior
   - Business name row with store icon (`FontAwesomeIcons.store` or existing icon used elsewhere)
   - Distance row with location icon (existing `distanceKm` formatting, "X.X km")
   - Time-remaining row with clock icon; text color `AppColors.primary`/red when remaining time
     < 2 hours, otherwise `AppColors.muted`
   - Chevron (`Icons.chevron_right`, existing)
   - Bookmark icon button (`Icons.bookmark` filled if `isSaved`, `Icons.bookmark_border` otherwise) —
     tapping calls `CampaignsController.toggleSaved(params, storyId)`; hidden/disabled for anonymous
     users (check existing auth-gate pattern, e.g. `ref.watch(authStateProvider)`)
   - Tapping the card body (outside the bookmark icon) keeps existing navigation to
     `/b/${businessId}` + analytics event `source: 'campaign'`

Empty state (`AppEmptyState`) and loading skeleton (`_DiscoverySkeleton`) behavior unchanged, applied
to the post-filter list (so an empty filter result also shows the empty state, with existing copy —
no new "no results for this filter" copy needed for this iteration).

## 5. l10n & testing

### New ARB keys (TR + EN, `app_tr.arb` / `app_en.arb` + regenerated `app_localizations*.dart`)

- `campaignsGreeting` — "Merhaba! 👋" / "Hello! 👋"
- `campaignsSearchPlaceholder` — "Kampanya veya işletme ara..." / "Search campaigns or businesses..."
- `campaignFilterAll` — "Tümü" / "All"
- `campaignFilterSoon` — "Yakında" / "Ending soon"
- `campaignFilterToday` — "Bugün" / "Today"
- `campaignFilterFood` — "Yemek" / "Food"
- `campaignFilterDessert` — "Tatlı" / "Dessert"
- `campaignFilterDiscount20` — "%20+" / "20%+"
- `campaignsNearbyHeader` — "Yakınındaki kampanyalar" / "Campaigns near you"
- `campaignsFeaturedBadge` — "Lezzet Fırsatları" / "Tasty Deals"
- `campaignDiscountLabel` — "%{percent} indirim" / "{percent}% off" (placeholder param)

### Tests

- `discovery_repository_test.dart` (or equivalent): unit test for `NearbyCampaign.fromMap` with new
  fields present/absent, and for `toggleSavedCampaign` RPC mapping.
- New widget test for `discovery_campaigns_tab.dart`: filter chip selection narrows the rendered list;
  hero card renders only when an `isFeatured` item exists and is absent otherwise; bookmark icon
  toggles `isSaved` optimistically.
- Existing `discovery_feed_composer_test.dart` is unrelated and remains unchanged.

### Validation commands (per CLAUDE.md)

- `flutter analyze` (mobile)
- `flutter test test/features/discovery` (and new campaign tab test)
- `node tools/ceviri-denetimi.mjs` (from repo root)
