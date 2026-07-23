-- ─────────────────────────────────────────────────────────────────────────────
-- Description: Data consistency indexes — foreign key support and
--              high-frequency query path indexes not covered by earlier
--              migrations (20260523000004_perf_missing_indexes already added
--              many; this adds the remaining gaps).
--
-- All indexes use IF NOT EXISTS — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── owner_claims ──────────────────────────────────────────────────────────────
-- FK side: user_id (no automatic index in PostgreSQL)
CREATE INDEX IF NOT EXISTS idx_owner_claims_user_id
  ON public.owner_claims (user_id, created_at DESC);

-- FK side: business_id
CREATE INDEX IF NOT EXISTS idx_owner_claims_business_id
  ON public.owner_claims (business_id, created_at DESC);

-- Pending queue scan (admin moderation)
CREATE INDEX IF NOT EXISTS idx_owner_claims_status_pending
  ON public.owner_claims (status, created_at DESC)
  WHERE status = 'pending';

-- Assigned admin workload
CREATE INDEX IF NOT EXISTS idx_owner_claims_assigned_to
  ON public.owner_claims (assigned_to, status)
  WHERE assigned_to IS NOT NULL;

-- ── businesses ────────────────────────────────────────────────────────────────
-- Partial index for active businesses already in 20260523000004 as
-- idx_businesses_is_active_partial and idx_businesses_active_city_category.
-- Add slug lookup (used in public web routes):
CREATE INDEX IF NOT EXISTS idx_businesses_slug
  ON public.businesses (slug)
  WHERE is_active = true;

-- ── audit_logs ────────────────────────────────────────────────────────────────
-- Existing indexes from 20260504000001:
--   idx_audit_logs_user_id, idx_audit_logs_resource, idx_audit_logs_created_at,
--   idx_audit_logs_action
-- Add action + created_at composite for time-range queries on action type:
CREATE INDEX IF NOT EXISTS idx_audit_logs_action_created
  ON public.audit_logs (action, created_at DESC);

-- ── reports ───────────────────────────────────────────────────────────────────
-- Added in 20260526000006_moderation_queue.sql:
--   idx_reports_status_created, idx_reports_target,
--   idx_reports_reporter_user_id, idx_reports_assigned_to
-- (no additional indexes needed here)

-- ── table_orders ──────────────────────────────────────────────────────────────
-- Composite for rate-limit check already in 20260523000004:
--   idx_table_orders_biz_table_time
-- Add business_id + status for active-order dashboard queries:
CREATE INDEX IF NOT EXISTS idx_table_orders_business_active
  ON public.table_orders (business_id, created_at DESC)
  WHERE status NOT IN ('completed', 'cancelled');

-- ── business_follows ─────────────────────────────────────────────────────────
-- Already in 20260523000004: idx_business_follows_user_id
-- Add business_id side for follower count queries:
CREATE INDEX IF NOT EXISTS idx_business_follows_business_id
  ON public.business_follows (business_id, created_at DESC);

-- ── notifications ─────────────────────────────────────────────────────────────
-- Already in 20260523000004: idx_notifications_user_type_created
-- Add is_read partial for unread notification badge:
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, created_at DESC)
  WHERE is_read = false;

-- ── menu_feedback ─────────────────────────────────────────────────────────────
-- 2026-07-23 fix: menu_feedback (bkz. 20260422000002) hiçbir zaman
-- menu_item_id kolonuna sahip olmadı — sadece id/business_id/rating/
-- category/message/created_at. Bu yorumun iddiası yanlıştı, o index kaldırıldı.
-- business_id index'i zaten 20260422000002'de var (idx_menu_feedback_business_id,
-- tek kolonlu); burada aynı isimle composite versiyon denenirse IF NOT EXISTS
-- sessizce atlar, zararsız.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'menu_feedback'
  ) THEN
    EXECUTE $idx$
      CREATE INDEX IF NOT EXISTS idx_menu_feedback_business_id
        ON public.menu_feedback (business_id, created_at DESC)
    $idx$;
  END IF;
END $$;

-- ── collab_lists ──────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'collab_lists'
  ) THEN
    EXECUTE $idx$
      CREATE INDEX IF NOT EXISTS idx_collab_lists_owner_id
        ON public.collab_lists (owner_id, created_at DESC)
    $idx$;
  END IF;
END $$;

-- ── loyalty_cards ─────────────────────────────────────────────────────────────
-- user_id lookup for "my loyalty cards" feature:
CREATE INDEX IF NOT EXISTS idx_loyalty_cards_user_id
  ON public.loyalty_cards (user_id, created_at DESC);

-- ── food diary ───────────────────────────────────────────────────────────────
-- yemek_gunlugu created in 20260507000009:
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'yemek_gunlugu'
  ) THEN
    EXECUTE $idx$
      CREATE INDEX IF NOT EXISTS idx_yemek_gunlugu_user_id
        ON public.yemek_gunlugu (user_id, logged_at DESC)
    $idx$;
  END IF;
END $$;
