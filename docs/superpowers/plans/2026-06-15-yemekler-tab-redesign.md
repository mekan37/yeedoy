# Yemekler Tab Redesign + Örnek Yeedoy Seed Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seed a fully-populated demo business ("Örnek Yeedoy") into the production Supabase database (menu, today's-special item, campaign story, review), then redesign the mobile "Yemekler" tab (`MenuItemsTab`) to match the approved mockup — greeting header, pill search bar, category chips, "Günün lezzeti" banner, and redesigned food cards with images.

**Architecture:** Part A is pure data — one SQL migration applied directly to production via `mcp__supabase__apply_migration`, inserting one business with full menu/sections/items/story/review, verified afterwards with SELECT queries and `get_advisors`. Part B adds an additive `search_menu_items_v2` RPC (same params as v1 + `image_url`/`is_today_special`/`special_note`/`item_description`), updates the Flutter model/repository to consume it, adds new ARB strings, and rewrites `menu_items_tab.dart`'s UI on top of the existing `MenuItemSearchController`/`MenuItemSearchState` (unchanged).

**Tech Stack:** Supabase Postgres (SQL migration, PL/pgSQL `DO` block), Flutter/Riverpod (existing `menu_item_search_controller.dart` unchanged), `packages/shared_ui_components` (`AppFilterChip`), ARB l10n (`app_tr.arb`/`app_en.arb` + `flutter gen-l10n`).

---

## Part A — "Örnek Yeedoy" Seed Data

### Task 1: Write and apply the seed migration

**Files:**
- Create: `supabase/migrations/20260615000001_ornek_yeedoy_seed.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- Seed a fully-populated demo business ("Örnek Yeedoy") with menu, today's
-- special, a promo story and a review, for the redesigned Yemekler tab.
do $$
declare
  v_business_id uuid;
  v_menu_id uuid;
  v_section_kebap uuid;
  v_section_pide uuid;
  v_section_corba uuid;
  v_section_tatli uuid;
  v_admin_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_reviewer_id uuid := 'b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0';
begin
  insert into public.businesses (
    name, category, description, city, district, neighborhood,
    lat, lng, is_active, source, slug, public_slug, cover_url, logo_url
  ) values (
    'Örnek Yeedoy', 'Restoran',
    'Yeedoy''in örnek menü, kampanya ve yorum verileriyle hazırlanmış tanıtım işletmesi.',
    'Ankara', 'Yenimahalle', 'Uğur Mumcu Mahallesi',
    40.012933, 32.740723, true, 'manual', 'ornek-yeedoy', 'ornek-yeedoy',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80'
  )
  returning id into v_business_id;

  insert into public.menus (business_id, title, status, source)
  values (v_business_id, 'Ana Menü', 'published', 'manual')
  returning id into v_menu_id;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Kebaplar', 1)
  returning id into v_section_kebap;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Pideler', 2)
  returning id into v_section_pide;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Çorbalar', 3)
  returning id into v_section_corba;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Tatlılar', 4)
  returning id into v_section_tatli;

  insert into public.menu_items (
    section_id, business_id, name, description, price_cents, currency,
    image_url, is_today_special, special_note
  ) values
    (v_section_kebap, v_business_id, 'Adana Kebap', 'Köz biber, bulgur pilavı ile',
     26000, 'TRY',
     'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800&q=80',
     true, 'Köz biber, bulgur pilavı ile'),
    (v_section_pide, v_business_id, 'Kuşbaşılı Pide', 'Kaşar ve tereyağlı',
     24000, 'TRY',
     'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=800&q=80',
     false, null),
    (v_section_corba, v_business_id, 'Mercimek Çorbası', 'Limon ve kıtır ekmek ile',
     9000, 'TRY',
     'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
     false, null),
    (v_section_tatli, v_business_id, 'Fıstıklı Baklava', 'Günlük taze üretim',
     18000, 'TRY',
     'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
     false, null);

  insert into public.business_stories (
    business_id, type, caption, media_url, media_type, created_by, expires_at
  ) values (
    v_business_id, 'promo',
    'Örnek Yeedoy''a özel kampanya: Bu hafta Adana Kebap''ta %15 indirim!',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
    'image', v_admin_id, now() + interval '30 days'
  );

  insert into public.reviews (
    business_id, user_id, rating, content, status,
    overall_rating, taste_rating, service_speed_rating,
    price_performance_rating, cleanliness_rating, atmosphere_rating
  ) values (
    v_business_id, v_reviewer_id, 5,
    'Adana kebabı gerçekten köz lezzetinde, pidesi de taze ve sıcak geldi. Servis hızlıydı, kesinlikle tekrar geleceğim!',
    'approved', 5, 5, 5, 4, 5, 5
  );
end $$;
```

- [ ] **Step 2: Apply the migration to production**

Use `mcp__supabase__apply_migration` with `name: "ornek_yeedoy_seed"` and the SQL above as `query`.

- [ ] **Step 3: Verify the inserted data**

Run via `mcp__supabase__execute_sql`:

```sql
select b.id, b.name, b.slug, b.public_slug, b.city, b.district, b.neighborhood,
       b.lat, b.lng, b.cover_url, b.logo_url,
       m.id as menu_id, m.title as menu_title, m.status
from public.businesses b
join public.menus m on m.business_id = b.id
where b.name = 'Örnek Yeedoy';
```

```sql
select mi.name, mi.price_cents, mi.is_today_special, mi.special_note, mi.image_url, ms.title as section
from public.menu_items mi
join public.menu_sections ms on ms.id = mi.section_id
join public.businesses b on b.id = mi.business_id
where b.name = 'Örnek Yeedoy'
order by ms.sort_order;
```

```sql
select s.type, s.caption, s.media_url, s.expires_at
from public.business_stories s
join public.businesses b on b.id = s.business_id
where b.name = 'Örnek Yeedoy';
```

```sql
select r.rating, r.content, r.status
from public.reviews r
join public.businesses b on b.id = r.business_id
where b.name = 'Örnek Yeedoy';
```

Expected: 1 business row, 4 menu_items rows (Adana Kebap with `is_today_special=true`), 1 business_stories row (`type='promo'`), 1 reviews row (`rating=5`, `status='approved'`).

- [ ] **Step 4: Check for new advisories**

Run `mcp__supabase__get_advisors` with `type: "security"` and `type: "performance"`. Confirm no new errors/warnings reference `businesses`, `menus`, `menu_items`, `business_stories`, or `reviews` beyond what existed before this migration.

---

## Part B — Yemekler Tab Redesign

### Task 2: Add `search_menu_items_v2` RPC

**Files:**
- Create: `supabase/migrations/20260615000002_search_menu_items_v2.sql`

- [ ] **Step 1: Write the migration**

This is additive — `search_menu_items_v1` is left untouched (still used by `pick_one_menu_item_v1`). `search_menu_items_v2` has the same parameters and adds `item_description`, `image_url`, `is_today_special`, `special_note` to the return columns.

```sql
CREATE OR REPLACE FUNCTION "public"."search_menu_items_v2"(
  "p_user_lat" double precision,
  "p_user_lng" double precision,
  "p_radius_km" double precision DEFAULT 5,
  "p_q" "text" DEFAULT NULL::"text",
  "p_is_vegan" boolean DEFAULT false,
  "p_is_vegetarian" boolean DEFAULT false,
  "p_is_gluten_free" boolean DEFAULT false,
  "p_is_lactose_free" boolean DEFAULT false,
  "p_is_halal" boolean DEFAULT false,
  "p_max_calories" integer DEFAULT NULL::integer,
  "p_verified_price_only" boolean DEFAULT false,
  "p_limit" integer DEFAULT 20,
  "p_offset" integer DEFAULT 0
) RETURNS TABLE(
  "menu_item_id" "uuid",
  "item_name" "text",
  "item_description" "text",
  "price_cents" integer,
  "currency" "text",
  "calories" integer,
  "is_vegan" boolean,
  "is_vegetarian" boolean,
  "is_gluten_free" boolean,
  "is_lactose_free" boolean,
  "is_halal" boolean,
  "business_id" "uuid",
  "business_name" "text",
  "address" "text",
  "city" "text",
  "district" "text",
  "distance_km" double precision,
  "price_status" "text",
  "ok_30d" integer,
  "bad_30d" integer,
  "image_url" "text",
  "is_today_special" boolean,
  "special_note" "text"
)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  with items as (
    select
      mi.id as menu_item_id,
      mi.name as item_name,
      mi.description as item_description,
      mi.price_cents,
      mi.currency,
      null::integer as calories,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'vegan'
      ) as is_vegan,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('vegetarian','vejetaryen')
      ) as is_vegetarian,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('gluten_free','glutensiz')
      ) as is_gluten_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('lactose_free','laktozsuz')
      ) as is_lactose_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'halal'
      ) as is_halal,
      mi.business_id,
      mi.image_url,
      mi.is_today_special,
      mi.special_note
    from public.menu_items mi
    where mi.is_available = true
      and (not p_is_vegan or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'vegan'
      ))
      and (not p_is_vegetarian or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('vegetarian','vejetaryen')
      ))
      and (not p_is_gluten_free or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('gluten_free','glutensiz')
      ))
      and (not p_is_lactose_free or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('lactose_free','laktozsuz')
      ))
      and (not p_is_halal or exists (
        select 1 from jsonb_array_elements_text(coalesce(mi.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'halal'
      ))
      and (
        p_q is null
        or lower(mi.name) ilike ('%'||lower(p_q)||'%')
        or lower(coalesce(mi.description,'')) ilike ('%'||lower(p_q)||'%')
      )
  ),
  price as (
    select
      v.menu_item_id,
      count(*) filter (where v.created_at >= now() - interval '30 days') as total_30d,
      count(*) filter (where v.vote=1 and v.created_at >= now() - interval '30 days') as ok_30d,
      count(*) filter (where v.vote=-1 and v.created_at >= now() - interval '30 days') as bad_30d
    from public.menu_item_price_votes v
    group by v.menu_item_id
  ),
  joined as (
    select
      i.*,
      b.name as business_name,
      b.address,
      b.city,
      b.district,
      (
        6371.0 * acos(
          cos(radians(p_user_lat)) * cos(radians(b.lat)) *
          cos(radians(b.lng) - radians(p_user_lng)) +
          sin(radians(p_user_lat)) * sin(radians(b.lat))
        )
      ) as distance_km,
      coalesce(p.ok_30d,0) as ok_30d,
      coalesce(p.bad_30d,0) as bad_30d,
      coalesce(p.total_30d,0) as total_30d,
      case
        when coalesce(p.total_30d,0) = 0 then 'unknown'
        when coalesce(p.ok_30d,0) >= 3 and coalesce(p.ok_30d,0) >= coalesce(p.bad_30d,0)*2 then 'verified'
        when coalesce(p.bad_30d,0) >= 3 and coalesce(p.bad_30d,0) > coalesce(p.ok_30d,0) then 'outdated'
        else 'mixed'
      end as price_status
    from items i
    join public.businesses b on b.id = i.business_id
    left join price p on p.menu_item_id = i.menu_item_id
    where b.lat is not null and b.lng is not null
  )
  select
    menu_item_id,
    item_name,
    item_description,
    price_cents,
    currency,
    calories,
    is_vegan,
    is_vegetarian,
    is_gluten_free,
    is_lactose_free,
    is_halal,
    business_id,
    business_name,
    address,
    city,
    district,
    distance_km,
    price_status,
    ok_30d,
    bad_30d,
    image_url,
    is_today_special,
    special_note
  from joined
  where distance_km <= p_radius_km
    and (not p_verified_price_only or price_status = 'verified')
  order by distance_km asc, price_status desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

ALTER FUNCTION "public"."search_menu_items_v2"(
  double precision, double precision, double precision, "text", boolean, boolean,
  boolean, boolean, boolean, integer, boolean, integer, integer
) OWNER TO "postgres";

REVOKE ALL ON FUNCTION "public"."search_menu_items_v2"(
  double precision, double precision, double precision, "text", boolean, boolean,
  boolean, boolean, boolean, integer, boolean, integer, integer
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."search_menu_items_v2"(
  double precision, double precision, double precision, "text", boolean, boolean,
  boolean, boolean, boolean, integer, boolean, integer, integer
) TO authenticated, anon;

COMMENT ON FUNCTION "public"."search_menu_items_v2" IS
  'Search menu items with image/today-special fields. Called by: uygulamalar/mobil/lib/features/menus/data/menu_item_search_repository.dart.';
```

> Note: grant `anon` too — `search_menu_items_v1` is used unauthenticated in the discovery Yemekler tab (no login required to browse).

- [ ] **Step 2: Apply the migration**

Use `mcp__supabase__apply_migration` with `name: "search_menu_items_v2"` and the SQL above as `query`.

- [ ] **Step 3: Smoke-test the RPC**

```sql
select item_name, image_url, is_today_special, special_note, price_cents, business_name, distance_km
from public.search_menu_items_v2(40.012933, 32.740723, 5, null, false, false, false, false, false, null, false, 20, 0)
order by item_name;
```

Expected: 4 rows for Örnek Yeedoy's items, with `image_url` populated and `Adana Kebap` having `is_today_special = true`.

---

### Task 3: Update `MenuItemSearchResult` model

**Files:**
- Modify: `uygulamalar/mobil/lib/features/menus/domain/menu_item_search_model.dart`

The v1/v2 RPC returns `item_name`/`item_description`, but `fromMap`'s key lists only checked `name`/`title` (never `item_name`) and had no `description` field at all — meaning real rows would have fallen back to the placeholder `'Ürün'` string. Fix this while adding the new v2 fields.

- [ ] **Step 1: Edit the class**

Replace the constructor and field list (lines 1–36):

```dart
class MenuItemSearchResult {
  MenuItemSearchResult({
    required this.menuItemId,
    required this.menuId,
    required this.businessId,
    required this.name,
    required this.businessName,
    this.description,
    this.distanceKm,
    this.priceCents,
    this.priceStatus = 'unknown',
    this.total30d,
    this.calories,
    this.district,
    this.city,
    this.isVegan = false,
    this.isVegetarian = false,
    this.isGlutenFree = false,
    this.isLactoseFree = false,
    this.imageUrl,
    this.isTodaySpecial = false,
    this.specialNote,
  });

  final String menuItemId;
  final String menuId;
  final String businessId;
  final String name;
  final String businessName;
  final String? description;
  final double? distanceKm;
  final int? priceCents;
  final String priceStatus;
  final int? total30d;
  final int? calories;
  final String? district;
  final String? city;
  final bool isVegan;
  final bool isVegetarian;
  final bool isGlutenFree;
  final bool isLactoseFree;
  final String? imageUrl;
  final bool isTodaySpecial;
  final String? specialNote;
```

- [ ] **Step 2: Update `fromMap`**

Replace the `fromMap` factory body (lines 38-57):

```dart
  factory MenuItemSearchResult.fromMap(Map<String, dynamic> map) {
    return MenuItemSearchResult(
      menuItemId: _asString(map, ['menu_item_id', 'item_id', 'id']) ?? '',
      menuId: _asString(map, ['menu_id', 'menuId']) ?? '',
      businessId: _asString(map, ['business_id', 'businessId']) ?? '',
      name: _asString(map, ['item_name', 'name', 'title']) ?? 'Ürün',
      businessName: _asString(map, ['business_name', 'place_name', 'business']) ?? 'İşletme',
      description: _asString(map, ['item_description', 'description']),
      distanceKm: _asDouble(map, ['distance_km', 'distanceKm', 'distance']),
      priceCents: _asInt(map, ['price_cents', 'priceCents', 'price']),
      priceStatus: _asString(map, ['price_status', 'status']) ?? 'unknown',
      total30d: _asInt(map, ['total_30d', 'total30d', 'votes_30d']),
      calories: _asInt(map, ['calories', 'kcal']),
      district: _asString(map, ['district', 'business_district']),
      city: _asString(map, ['city', 'business_city']),
      isVegan: _asBool(map, ['is_vegan', 'vegan']) ?? false,
      isVegetarian: _asBool(map, ['is_vegetarian', 'vegetarian']) ?? false,
      isGlutenFree: _asBool(map, ['is_gluten_free', 'gluten_free']) ?? false,
      isLactoseFree: _asBool(map, ['is_lactose_free', 'lactose_free']) ?? false,
      imageUrl: _asString(map, ['image_url', 'imageUrl']),
      isTodaySpecial: _asBool(map, ['is_today_special', 'isTodaySpecial']) ?? false,
      specialNote: _asString(map, ['special_note', 'specialNote']),
    );
  }
```

> The previously-corrupted literals `'?or?n'` and `'I?Yletme'` in the original file are mojibake for `'Ürün'`/`'İşletme'` — the replacements above use correct UTF-8 Turkish characters.

---

### Task 4: Update `MenuItemSearchRepository` to call v2

**Files:**
- Modify: `uygulamalar/mobil/lib/features/menus/data/menu_item_search_repository.dart:33`

- [ ] **Step 1: Change the RPC name**

In `searchMenuItems`, change:

```dart
      final res = await client.rpc('search_menu_items_v1', params: {
```

to:

```dart
      final res = await client.rpc('search_menu_items_v2', params: {
```

Leave `pickOneMenuItem` (calls `pick_one_menu_item_v1`) unchanged — it internally wraps `search_menu_items_v1`, which stays as-is per Task 2.

---

### Task 5: Add new ARB l10n keys

**Files:**
- Modify: `uygulamalar/mobil/lib/l10n/app_tr.arb:660`
- Modify: `uygulamalar/mobil/lib/l10n/app_en.arb:988`

- [ ] **Step 1: Add keys to `app_tr.arb`**

After line 660 (`"tabFoods": "Yemekler",`), insert:

```json
  "tabFoods": "Yemekler",
  "discoveryFoodsGreeting": "Merhaba! 👋",
  "discoveryFoodsSearchHint": "Yemek veya kategori ara...",
  "discoveryAllCategory": "Tümü",
  "todaysPickTitle": "Günün lezzeti",
```

(i.e. replace the single line `"tabFoods": "Yemekler",` with the 5 lines above)

- [ ] **Step 2: Add keys to `app_en.arb`**

Replace lines 988-991:

```json
  "tabFoods": "Foods",
  "@tabFoods": {
    "description": "Auto metadata for tabFoods"
  },
```

with:

```json
  "tabFoods": "Foods",
  "@tabFoods": {
    "description": "Auto metadata for tabFoods"
  },
  "discoveryFoodsGreeting": "Hello! 👋",
  "@discoveryFoodsGreeting": {
    "description": "Greeting shown atop the Foods tab"
  },
  "discoveryFoodsSearchHint": "Search food or category...",
  "@discoveryFoodsSearchHint": {
    "description": "Placeholder for the Foods tab search field"
  },
  "discoveryAllCategory": "All",
  "@discoveryAllCategory": {
    "description": "Label for the 'all categories' chip on the Foods tab"
  },
  "todaysPickTitle": "Today's pick",
  "@todaysPickTitle": {
    "description": "Title for the featured today's-special banner on the Foods tab"
  },
```

- [ ] **Step 3: Regenerate localization files**

Run from `uygulamalar/mobil/`:

```bash
flutter gen-l10n
```

Expected: regenerates `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart` with the new getters (`discoveryFoodsGreeting`, `discoveryFoodsSearchHint`, `discoveryAllCategory`, `todaysPickTitle`) and no errors.

---

### Task 6: Redesign `MenuItemsTab` UI

**Files:**
- Modify: `uygulamalar/mobil/lib/features/menus/ui/menu_items_tab.dart`

This task replaces the top of the `build` method (search row + filter chips) with: greeting header, pill search bar + tune icon, category chip row, and a "Günün lezzeti" banner above the list. The existing diet `FilterChip`/profile-badge row, error/loading/empty states, filter sheet, and `_MenuItemCard` internals (status badge, diet chips) are preserved — only `_MenuItemCard` gains a leading image and the layout is adjusted to match the mockup (image left, content middle, price + alert button right).

- [ ] **Step 1: Add the categories import**

At the top of the file, add:

```dart
import '../../discovery/ui/categories_config.dart';
```

- [ ] **Step 2: Replace the search row + spacing with the new header block**

Replace lines 58-100 (from the opening `Row(` for the search field through its closing `const SizedBox(height: 12),`) with:

```dart
          Text(
            t.discoveryFoodsGreeting,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.tabFoods,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => ref
                      .read(menuItemSearchProvider.notifier)
                      .setQuery(qCtrl.text.trim()),
                  onSubmitted: (_) =>
                      ref.read(menuItemSearchProvider.notifier).refresh(),
                  decoration: InputDecoration(
                    hintText: t.discoveryFoodsSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: qCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: t.kapat,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              qCtrl.clear();
                              ref
                                  .read(menuItemSearchProvider.notifier)
                                  .setQuery('');
                              ref
                                  .read(menuItemSearchProvider.notifier)
                                  .refresh();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: t.filters,
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilters(context, st),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppFilterChip(
                  label: t.discoveryAllCategory,
                  selected: st.query.isEmpty,
                  onTap: () {
                    qCtrl.clear();
                    ref.read(menuItemSearchProvider.notifier).setQuery('');
                  },
                ),
                const SizedBox(width: 8),
                for (final category in discoveryHomeCategories) ...[
                  AppFilterChip(
                    label: _categoryLabel(t, category.titleKey),
                    selected: st.query == category.searchTerm,
                    onTap: () {
                      qCtrl.text = category.searchTerm;
                      ref
                          .read(menuItemSearchProvider.notifier)
                          .setQuery(category.searchTerm);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
```

- [ ] **Step 3: Add the "Günün lezzeti" banner before the item list**

Just before the `return RefreshIndicator(...)` statement (i.e. right after the `final user = ref.watch(userProvider);` line), add:

```dart
    MenuItemSearchResult? todaysPick;
    for (final candidate in st.items) {
      if (candidate.isTodaySpecial) {
        todaysPick = candidate;
        break;
      }
    }
```

The list loop currently starts with:

```dart
          if (st.loading && st.items.isEmpty) ...[
            const _MenuItemsSkeleton(),
          ] else ...[
            for (final item in st.items) ...[
```

Insert the banner immediately before this `if` block:

```dart
          if (todaysPick != null) ...[
            _TodaysPickBanner(
              item: todaysPick,
              onTap: () => _openMenuItem(context, todaysPick),
            ),
            const SizedBox(height: 14),
          ],

```

- [ ] **Step 4: Add the `_categoryLabel` helper and `_TodaysPickBanner` widget**

Add this top-level helper function near the bottom of the file (alongside `_redirectToLogin`/`_formatPrice`):

```dart
String _categoryLabel(AppLocalizations t, String titleKey) {
  switch (titleKey) {
    case 'discoveryHomeCategoryDoner':
      return t.discoveryHomeCategoryDoner;
    case 'discoveryHomeCategoryPide':
      return t.discoveryHomeCategoryPide;
    case 'discoveryHomeCategoryLahmacun':
      return t.discoveryHomeCategoryLahmacun;
    case 'discoveryHomeCategoryBurger':
      return t.discoveryHomeCategoryBurger;
    case 'discoveryHomeCategoryPizza':
      return t.discoveryHomeCategoryPizza;
    case 'discoveryHomeCategoryKebap':
      return t.discoveryHomeCategoryKebap;
    case 'discoveryHomeCategoryCorba':
      return t.discoveryHomeCategoryCorba;
    case 'discoveryHomeCategoryKahvalti':
      return t.discoveryHomeCategoryKahvalti;
    case 'discoveryHomeCategoryManti':
      return t.discoveryHomeCategoryManti;
    case 'discoveryHomeCategoryTatli':
      return t.discoveryHomeCategoryTatli;
    default:
      return titleKey;
  }
}
```

> All ten `titleKey` values come from `discoveryHomeCategories` in `categories_config.dart` (verified) and all ten getters already exist in `AppLocalizations` (used elsewhere in discovery).

Add the `_TodaysPickBanner` widget as a new top-level class (e.g. after `_MenuItemCard`):

```dart
class _TodaysPickBanner extends StatelessWidget {
  const _TodaysPickBanner({required this.item, required this.onTap});

  final MenuItemSearchResult item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 84,
                height: 84,
                child: item.imageUrl == null
                    ? Container(
                        color: AppColors.card,
                        child: const Icon(Icons.restaurant_menu_outlined),
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.card,
                          child: const Icon(Icons.restaurant_menu_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.todaysPickTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  if ((item.specialNote ?? item.description) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.specialNote ?? item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Redesign `_MenuItemCard` to add the leading image**

Replace the `_MenuItemCard.build` method's `Card` content (the `Row` containing the name + price, lines ~331-345) — keep everything else (status badges, diet chips, alert button) but wrap the whole `Column` in a `Row` with a leading image. Replace the full body of `_MenuItemCard.build`:

```dart
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item.imageUrl == null
                      ? Container(
                          color: AppColors.card,
                          child: const Icon(Icons.restaurant_menu_outlined),
                        )
                      : Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.card,
                            child: const Icon(Icons.restaurant_menu_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(item.priceCents, locale: t.localeName),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              visualDensity: VisualDensity.compact,
                              tooltip: t.setPriceAlert,
                              icon: const Icon(Icons.notifications_active_outlined, size: 18),
                              onPressed: onAlertTap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        if (item.distanceKm != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            t.distanceKm(item.distanceKm!),
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusBadge(config: _statusBadge(item.priceStatus, t)),
                        if (item.isVegan) _DietChip(label: t.vegan),
                        if (item.isGlutenFree) _DietChip(label: t.glutenFree),
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
```

> This drops the old large `OutlinedButton.icon` "set price alert" button in favor of a compact icon button next to the price (per design — no separate favorite/heart feature is built; the existing price-alert action occupies that corner). The `votes`/`calories`/`ok_30d` detail row from the old design is dropped from the compact card to match the mockup; that data remains available via `item.total30d`/`item.calories` if a future detail view needs it.

---

### Task 7: Validate

**Files:** none (validation only)

- [ ] **Step 1: Run static analysis**

From `uygulamalar/mobil/`:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run the test suite**

From `uygulamalar/mobil/`:

```bash
flutter test
```

Expected: all existing tests pass (no new tests added — this is a UI redesign of an existing, untested-at-widget-level tab; existing discovery/menu domain tests must remain green).

- [ ] **Step 3: Manual check**

Run the app, open Discovery → Yemekler tab, allow location near `40.012933, 32.740723` (or search "Örnek Yeedoy" / "Adana Kebap"). Confirm:
- Greeting + "Yemekler" header shown
- Pill search bar with placeholder "Yemek veya kategori ara..."
- Category chip row scrolls horizontally; tapping "Kebap" filters to kebap items
- "Günün lezzeti" banner shows "Adana Kebap" with image
- Food cards show images, business name, distance, price, and a small price-alert icon button

---

## Self-Review Notes

- **Spec coverage:** Part A (business/menu/sections/items/story/review + verification) → Task 1. Part B backend (`search_menu_items_v2`) → Task 2. Model/repo → Tasks 3-4. L10n → Task 5. UI (greeting, search, category chips, banner, redesigned cards, unchanged filters) → Task 6. Validation → Task 7. All spec sections covered.
- **Placeholder scan:** No TBD/TODO; all SQL and Dart code is complete and copy-pasteable.
- **Type consistency:** `MenuItemSearchResult` fields (`imageUrl`, `isTodaySpecial`, `specialNote`, `description`) used consistently across Tasks 3, 6. `discoveryHomeCategories`/`DiscoveryCategoryConfig` fields (`titleKey`, `searchTerm`) match `categories_config.dart`. `AppFilterChip(label, selected, onTap)` matches its actual constructor.
