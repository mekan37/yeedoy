-- B18 (mobil production-readiness denetimi): Heroes ve haftalık liderlik
-- tablosu listelerinde satır başına ayrı bir get_user_public_profile_v1
-- çağrısı (publicProfileProvider) tetikleniyordu — klasik N+1. display_name/
-- avatar_url zaten get_user_public_profile_v1 üzerinden herkese açık
-- (public.user_profiles, "public profile" alanları) — bu yüzden burada da
-- doğrudan join ile döndürmek yeni bir PII sızıntısı değil.
-- RETURNS TABLE kolon listesi değişiyor — CREATE OR REPLACE bunu kabul etmez.
DROP FUNCTION IF EXISTS "public"."get_heroes_v1"(integer);
DROP FUNCTION IF EXISTS "public"."get_weekly_contributor_leaderboard_v1"(integer);

CREATE OR REPLACE FUNCTION "public"."get_heroes_v1"("p_limit" integer DEFAULT 20)
RETURNS TABLE(
  "user_id" "uuid",
  "donated_count" integer,
  "donated_amount_cents" integer,
  "display_name" text,
  "avatar_url" text
)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    s.donor_user_id as user_id,
    count(*)::int as donated_count,
    sum(s.amount_cents)::int as donated_amount_cents,
    coalesce(p.display_name, '') as display_name,
    coalesce(p.avatar_url, '') as avatar_url
  from public.suspended_meals s
  left join public.user_profiles p on p.user_id = s.donor_user_id
  where s.status in ('active','claimed')
  group by s.donor_user_id, p.display_name, p.avatar_url
  order by donated_amount_cents desc
  limit greatest(p_limit,0);
$$;

CREATE OR REPLACE FUNCTION public.get_weekly_contributor_leaderboard_v1(
  p_limit  integer DEFAULT 20
)
RETURNS TABLE (
  user_id          uuid,
  verify_count     integer,
  review_count     integer,
  photo_count      integer,
  weekly_score     integer,
  display_name     text,
  avatar_url       text
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
    c.weekly_score,
    coalesce(up.display_name, '') as display_name,
    coalesce(up.avatar_url, '') as avatar_url
  FROM combined c
  LEFT JOIN public.user_profiles up ON up.user_id = c.user_id
  WHERE c.weekly_score > 0
  ORDER BY c.weekly_score DESC, c.review_count DESC
  LIMIT greatest(p_limit, 1);
$$;

COMMENT ON FUNCTION public.get_weekly_contributor_leaderboard_v1(integer) IS
  'Rolling 7-day contributor leaderboard: price verifications (2 pts), reviews (3 pts),
   review photos (2 pts). Capped at p_limit rows (default 20). display_name/avatar_url
   are public profile fields (same as get_user_public_profile_v1) joined in to avoid
   N+1 profile lookups on the client (B18).';

-- DROP FUNCTION grant'leri siler — yeniden veriliyor.
GRANT ALL ON FUNCTION "public"."get_heroes_v1"("p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_heroes_v1"("p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_heroes_v1"("p_limit" integer) TO "service_role";

GRANT EXECUTE ON FUNCTION public.get_weekly_contributor_leaderboard_v1(integer)
  TO anon, authenticated, service_role;
