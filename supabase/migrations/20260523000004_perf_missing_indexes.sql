-- ─────────────────────────────────────────────────────────────────────────────
-- Performance: Missing indexes on high-traffic query paths
-- ─────────────────────────────────────────────────────────────────────────────
-- All indexes use IF NOT EXISTS to be safe against re-runs.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── businesses.is_active ──────────────────────────────────────────────────────
-- Nearly every public-facing query filters WHERE is_active = TRUE.
-- A partial index on is_active=TRUE dramatically reduces scan cost.
create index if not exists idx_businesses_is_active_partial
  on public.businesses (id)
  where is_active = true;

-- ── businesses composite: is_active + city + category ─────────────────────────
-- search_businesses_v1 and nearby_businesses_v2 filter by is_active + optional
-- city/category. A composite supports these common combinations.
create index if not exists idx_businesses_active_city_category
  on public.businesses (city, category)
  where is_active = true;

-- ── business_follows.user_id ──────────────────────────────────────────────────
-- Only business_id is indexed. send_business_campaign_v1 and
-- notify_favorite_revisit_reminders_v1 join on user_id side.
create index if not exists idx_business_follows_user_id
  on public.business_follows (user_id, created_at desc);

-- ── visits: date-cast friendly index ─────────────────────────────────────────
-- submit_checkin_v1 queries: WHERE user_id = X AND business_id = Y AND
-- checked_in_at::DATE = CURRENT_DATE. The cast prevents index use on the
-- existing idx_visits_user_business_date. An expression index on the date
-- cast allows the planner to use an index scan.
create index if not exists idx_visits_user_business_date_cast
  on public.visits (user_id, business_id, (checked_in_at::date));

-- ── favorites.created_at for revisit reminder ──────────────────────────────────
-- notify_favorite_revisit_reminders_v1 queries:
-- WHERE f.created_at BETWEEN now()-22d AND now()-20d
-- The existing idx_favorites_user_created (user_id, created_at) helps if
-- user_id is bound, but the batch query has no user_id filter.
-- A plain created_at index enables an efficient range scan for the batch job.
create index if not exists idx_favorites_created_at
  on public.favorites (created_at desc);

-- ── table_orders: composite for rate-limit query ───────────────────────────────
-- submit_table_order_v1 counts recent orders:
-- WHERE business_id = X AND table_number = Y AND created_at > NOW()-2min
-- The existing idx_table_orders_business_status covers business_id + status
-- but not table_number. A composite on (business_id, table_number, created_at)
-- covers the rate-limit check without a seq scan on per-business orders.
create index if not exists idx_table_orders_biz_table_time
  on public.table_orders (business_id, table_number, created_at desc);

-- ── notifications: type lookup for campaign fan-out ───────────────────────────
-- send_business_campaign_v1 inserts into notifications with ON CONFLICT DO NOTHING.
-- The conflict resolution relies on a unique constraint that may not exist.
-- Adding a (user_id, type, created_at) index for efficient "recent campaign
-- notifications for user" scans used in the notification center.
create index if not exists idx_notifications_user_type_created
  on public.notifications (user_id, type, created_at desc);

-- ── review_votes: (user_id, review_id) ───────────────────────────────────────
-- vote_menu_item_photo_v1 and get_business_reviews_v3 check individual votes.
-- The existing idx_review_votes_review covers review_id alone.
-- A composite (user_id, review_id) supports the "did this user vote?" lookup.
create index if not exists idx_review_votes_user_review
  on public.review_votes (user_id, review_id);

-- ── menu_item_price_votes: (user_id, menu_item_id) ───────────────────────────
-- vote_menu_item_price_v1 does: SELECT vote FROM menu_item_price_votes WHERE
-- menu_item_id = X AND user_id = Y. The existing idx_price_votes_item_time
-- covers (menu_item_id, created_at). A composite with user_id avoids a
-- filter-on-top-of-index-scan.
create index if not exists idx_menu_item_price_votes_user_item
  on public.menu_item_price_votes (user_id, menu_item_id);

-- ── loyalty_programs: business_id (for owner dashboard queries) ───────────────
-- get_my_loyalty_cards_v1 joins: loyalty_cards → loyalty_programs → businesses.
-- The existing idx_loyalty_programs_biz is partial (WHERE is_active=TRUE).
-- Add a non-partial index so inactive program admin queries also get index support.
create index if not exists idx_loyalty_programs_business_all
  on public.loyalty_programs (business_id, created_at desc);

-- ── loyalty_cards: program_id (FK side) ──────────────────────────────────────
-- The UNIQUE constraint on (program_id, user_id) creates an index covering
-- both columns, which also serves as the FK index on program_id. No additional
-- index needed for loyalty_cards.

-- ── menu_item_allergens, menu_item_ingredients: item_id ──────────────────────
-- These tables were added in 20260414 migrations. The FK constraint creates an
-- implicit index in some PostgreSQL versions but not all. Ensure explicit indexes.
create index if not exists idx_menu_item_allergens_item_id
  on public.menu_item_allergens (item_id);

create index if not exists idx_menu_item_ingredients_item_id
  on public.menu_item_ingredients (item_id);

-- ── menu_item_variant_groups: item_id ────────────────────────────────────────
-- FK from menu_item_variant_options to menu_item_variant_groups uses group_id,
-- which has an implicit index. But queries filtering by item_id on the groups
-- table need an explicit index.
create index if not exists idx_menu_item_variant_groups_item_id
  on public.menu_item_variant_groups (item_id);

-- ── osm_admin_boundaries: osm_boundary_id lookup ──────────────────────────────
-- assign_business_to_boundary_v1 does ST_Within lookups on osm_admin_boundaries.
-- The GIST index on boundary already exists (idx_osm_admin_boundaries_boundary).
-- The admin_level filter in the WHERE clause also uses idx_osm_admin_boundaries_admin_level.
-- A composite (admin_level, id) index supports the SELECT id WHERE admin_level = X pattern.
create index if not exists idx_osm_admin_boundaries_level_id
  on public.osm_admin_boundaries (admin_level, id);

-- ── business_activity_log: type filter ───────────────────────────────────────
-- business_quality_score_v1 view queries:
-- WHERE type = 'menu_update' GROUP BY business_id
-- The existing idx_business_activity_log_business_id_idx covers (business_id, created_at).
-- A composite (type, business_id, created_at) supports the type-filtered aggregate.
create index if not exists idx_business_activity_log_type_business
  on public.business_activity_log (type, business_id, created_at desc);

-- ── menu_item_price_history: lateral subquery ─────────────────────────────────
-- business_price_index_v1 view uses a LATERAL subquery:
-- SELECT FROM menu_item_price_history WHERE menu_item_id = X ORDER BY created_at DESC LIMIT 1
-- The existing idx_price_hist_item_created covers this well. No new index needed.

-- ── menu_items: is_available filter ──────────────────────────────────────────
-- business_quality_score_v1 queries: WHERE mi.is_available = true
-- Many RPC functions filter on (business_id, is_available). The existing
-- idx_menu_items_business covers business_id. A partial index for active items:
create index if not exists idx_menu_items_business_available
  on public.menu_items (business_id, sort_order)
  where is_available = true;
