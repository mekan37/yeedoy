-- ─────────────────────────────────────────────────────────────────────────────
-- Performance: Fix N+1 / full sequential scan patterns in RPC functions
-- ─────────────────────────────────────────────────────────────────────────────

-- ── get_business_reviews_v3: N+1 on _review_verified_visit ───────────────────
-- The current implementation calls _review_verified_visit(user_id, business_id, date)
-- once per review row in the CTE — this is an N+1 pattern if the helper
-- executes a subquery per call. We rewrite the CTE to LEFT JOIN against visits
-- directly, eliminating the per-row function call.
--
-- The _review_verified_visit helper does:
--   EXISTS (SELECT 1 FROM visits WHERE user_id = X AND business_id = Y
--           AND checked_in_at::date = review_date)
-- We can inline this as a LEFT JOIN LATERAL or a correlated EXISTS in the WHERE,
-- but the most index-friendly approach is a LATERAL join.

DROP FUNCTION IF EXISTS public.get_business_reviews_v3(uuid, text, integer, integer);
CREATE OR REPLACE FUNCTION public.get_business_reviews_v3(
  p_business_id  uuid,
  p_sort         text    DEFAULT 'newest',
  p_limit        integer DEFAULT 20,
  p_offset       integer DEFAULT 0
)
RETURNS TABLE (
  id              uuid,
  business_id     uuid,
  user_id         uuid,
  rating          integer,
  title           text,
  content         text,
  helpful_count   integer,
  created_at      timestamptz,
  status          text,
  quality_score   numeric,
  verified_visit  boolean,
  r_taste         integer,
  r_service       integer,
  r_price_value   integer,
  r_cleanliness   integer,
  r_atmosphere    integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
  WITH base AS (
    SELECT
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      COALESCE(r.helpful_count, 0)::integer          AS helpful_count,
      r.created_at,
      COALESCE(r.status, 'published')                AS status,
      COALESCE(r.helpful_count, 0)::numeric          AS quality_score,
      -- Inline the verified_visit check as an EXISTS using the composite index
      -- idx_visits_user_business_date_cast (added in 20260523000004).
      -- This avoids a per-row SECURITY DEFINER function call.
      EXISTS (
        SELECT 1
        FROM public.visits v
        WHERE v.user_id     = r.user_id
          AND v.business_id = r.business_id
          AND v.checked_in_at >= date_trunc('day', r.created_at)
          AND v.checked_in_at <  date_trunc('day', r.created_at) + interval '1 day'
      )                                              AS verified_visit,
      rr.r_taste,
      rr.r_service,
      rr.r_price_value,
      rr.r_cleanliness,
      rr.r_atmosphere
    FROM public.reviews r
    LEFT JOIN public.review_ratings rr ON rr.review_id = r.id
    WHERE r.business_id = p_business_id
      AND COALESCE(r.status, 'published') NOT IN ('rejected', 'spam')
  )
  SELECT
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score,
    b.verified_visit,
    b.r_taste,
    b.r_service,
    b.r_price_value,
    b.r_cleanliness,
    b.r_atmosphere
  FROM base b
  ORDER BY
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'verified'
      THEN (b.verified_visit)::int ELSE NULL END DESC,
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'helpful'
      THEN b.quality_score ELSE NULL END DESC,
    CASE WHEN lower(coalesce(p_sort, 'newest')) = 'helpful'
      THEN b.helpful_count ELSE NULL END DESC,
    b.created_at DESC
  LIMIT  greatest(p_limit, 1)
  OFFSET greatest(p_offset, 0);
$$;

GRANT EXECUTE ON FUNCTION public.get_business_reviews_v3(uuid, text, integer, integer)
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.get_business_reviews_v3(uuid, text, integer, integer) IS
  'Business reviews with multi-criterion ratings and verified_visit flag.
   p_sort: newest | helpful | verified. verified puts checked-in reviews first.
   2026-05-23: Eliminated N+1 _review_verified_visit per-row call; inlined EXISTS.';

-- ── submit_table_order_v1: add search_path (performance + security) ───────────
-- Already has SET search_path, but let us also ensure the rate-limit subquery
-- benefits from the new index. The function body itself is fine; only the
-- index added in migration 00004 accelerates it.

-- ── get_business_recent_checkins_v1: add missing search_path ─────────────────
-- This function was created without search_path in 20260507000002.
create or replace function public.get_business_recent_checkins_v1(
  p_business_id uuid,
  p_hours       int default 2
)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object(
    'count', count(*)
  )
  from public.visits
  where business_id = p_business_id
    and checked_in_at >= now() - (p_hours || ' hours')::interval;
$$;

grant execute on function public.get_business_recent_checkins_v1(uuid, int)
  to anon, authenticated, service_role;

-- ── notify_favorite_revisit_reminders_v1: add missing search_path ────────────
-- The function was created in 20260421000006 without SET search_path.
-- Full replacement with search_path pinned.
create or replace function public.notify_favorite_revisit_reminders_v1(
  p_batch_size int default 200
)
returns integer
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_count  integer := 0;
  v_rec    record;
  v_bname  text;
begin
  for v_rec in
    select f.user_id, f.business_id, b.name as business_name
    from   public.favorites f
    join   public.businesses b on b.id = f.business_id
    where  f.created_at between now() - interval '22 days' and now() - interval '20 days'
      and not exists (
        select 1 from public.business_checkins c
        where  c.user_id     = f.user_id
          and  c.business_id = f.business_id
          and  c.created_at  >= now() - interval '21 days'
      )
      and not exists (
        select 1 from public.favorite_revisit_reminders_sent s
        where  s.user_id     = f.user_id
          and  s.business_id = f.business_id
      )
    limit p_batch_size
  loop
    v_bname := coalesce(v_rec.business_name, 'İşletme');

    perform public.notify_user_v1(
      v_rec.user_id,
      'favorite_revisit_reminder',
      'Hâlâ gitmek ister misin?',
      v_bname || ' favorilerinizde. Ziyaret etmek ister misiniz?',
      jsonb_build_object('business_id', v_rec.business_id)
    );

    insert into public.favorite_revisit_reminders_sent (user_id, business_id)
    values (v_rec.user_id, v_rec.business_id)
    on conflict (user_id, business_id) do nothing;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

grant execute on function public.notify_favorite_revisit_reminders_v1(int)
  to service_role;
