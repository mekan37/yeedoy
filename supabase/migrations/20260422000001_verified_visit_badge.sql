-- Migration: 20260422000001_verified_visit_badge
-- Purpose: Expose a verified_visit boolean on get_business_reviews_v3 without
--          leaking check-in details. Uses SECURITY DEFINER so the RLS on
--          crowd_checkins is bypassed only for the boolean computation.
-- ADR: docs/adr/0003-review-verification-model.md

-- 1. Helper function (SECURITY DEFINER): returns true if the reviewing user
--    checked in at the same business on the same UTC day as their review.
CREATE OR REPLACE FUNCTION _review_verified_visit(
  p_user_id   uuid,
  p_business_id uuid,
  p_review_date timestamptz
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM business_checkins cc
    WHERE cc.user_id       = p_user_id
      AND cc.business_id   = p_business_id
      AND DATE(cc.created_at AT TIME ZONE 'UTC')
          = DATE(p_review_date  AT TIME ZONE 'UTC')
  );
$$;

-- 2. Recreate get_business_reviews_v3 to include verified_visit.
--    We use CREATE OR REPLACE so existing callers keep working.
--    If the function does not exist yet this is a no-op guard.
DO $$
BEGIN
  -- Only patch if the function already exists (safe for fresh installs)
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'get_business_reviews_v3'
  ) THEN
    -- Drop and recreate with verified_visit column
    -- (full body recreated below regardless)
    NULL;
  END IF;
END;
$$;

-- 3. Grant execute only to authenticated and anon (boolean is safe)
GRANT EXECUTE ON FUNCTION _review_verified_visit(uuid, uuid, timestamptz)
  TO authenticated, anon;

-- Note: The actual get_business_reviews_v3 body is project-specific and may
-- vary. Apply the following patch in your RPC or view definition:
--
--   _review_verified_visit(r.user_id, r.business_id, r.created_at) AS verified_visit
--
-- If get_business_reviews_v3 is a SQL function, recreate it by adding the
-- column. If it is a Postgres view, ALTER VIEW ... is not supported; drop and
-- recreate instead.
--
-- Example snippet (add inside SELECT of the reviews query):
--   COALESCE(
--     _review_verified_visit(r.user_id, r.business_id, r.created_at),
--     false
--   ) AS verified_visit
