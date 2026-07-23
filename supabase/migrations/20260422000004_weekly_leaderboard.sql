-- Migration: 20260422000004_weekly_leaderboard
-- Purpose: Weekly top-contributor leaderboard for price verifications, reviews,
--          and review photos. Powers the D4 leaderboard section in HeroesPage.
--
-- Scoring (weekly window, rolling 7 days):
--   price verification confirm/reject vote    → 2 pts each
--   review created                            → 3 pts each
--   review photo uploaded (status != rejected)→ 2 pts each
--
-- RPC is STABLE so can be cached; output capped at 20 rows.

CREATE OR REPLACE FUNCTION public.get_weekly_contributor_leaderboard_v1(
  p_limit  integer DEFAULT 20
)
RETURNS TABLE (
  user_id          uuid,
  verify_count     integer,
  review_count     integer,
  photo_count      integer,
  weekly_score     integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH window_start AS (
    SELECT now() - INTERVAL '7 days' AS ts
  ),

  verifies AS (
    SELECT
      user_id,
      count(*)::integer AS verify_count
    FROM menu_item_price_votes
    WHERE created_at >= (SELECT ts FROM window_start)
    GROUP BY user_id
  ),

  reviews AS (
    SELECT
      user_id,
      count(*)::integer AS review_count
    FROM reviews
    WHERE created_at >= (SELECT ts FROM window_start)
      AND status NOT IN ('rejected', 'spam')
    GROUP BY user_id
  ),

  photos AS (
    SELECT
      user_id,
      count(*)::integer AS photo_count
    FROM temp_uploads
    WHERE created_at >= (SELECT ts FROM window_start)
      AND kind = 'review_photo'
      AND status <> 'rejected'
    GROUP BY user_id
  ),

  combined AS (
    SELECT
      COALESCE(v.user_id, r.user_id, p.user_id)   AS user_id,
      COALESCE(v.verify_count, 0)                  AS verify_count,
      COALESCE(r.review_count, 0)                  AS review_count,
      COALESCE(p.photo_count, 0)                   AS photo_count,
      (COALESCE(v.verify_count, 0) * 2
        + COALESCE(r.review_count, 0) * 3
        + COALESCE(p.photo_count, 0) * 2)          AS weekly_score
    FROM verifies   v
    FULL OUTER JOIN reviews r USING (user_id)
    FULL OUTER JOIN photos  p USING (user_id)
  )

  SELECT
    c.user_id,
    c.verify_count,
    c.review_count,
    c.photo_count,
    c.weekly_score
  FROM combined c
  WHERE c.weekly_score > 0
  ORDER BY c.weekly_score DESC, c.review_count DESC
  LIMIT greatest(p_limit, 1);
$$;

GRANT EXECUTE ON FUNCTION public.get_weekly_contributor_leaderboard_v1(integer)
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.get_weekly_contributor_leaderboard_v1(integer) IS
  'Rolling 7-day contributor leaderboard: price verifications (2 pts), reviews (3 pts),
   review photos (2 pts). Capped at p_limit rows (default 20). No PII — user_id only.';
