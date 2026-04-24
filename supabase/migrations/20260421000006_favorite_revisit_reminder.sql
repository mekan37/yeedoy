-- ─────────────────────────────────────────────────────────────────────────────
-- Favorite revisit reminder
-- Sends "Hâlâ gitmek ister misin?" push 21 days after a user favorites a business.
-- Skips users who already checked in to that business in the last 21 days.
-- Skips users who already received this reminder for this (user, business) pair.
-- Designed to be called by pg_cron once per day.
-- ─────────────────────────────────────────────────────────────────────────────

-- Dedup table: one reminder per user+business, ever.
CREATE TABLE IF NOT EXISTS public.favorite_revisit_reminders_sent (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL,
  business_id uuid NOT NULL,
  sent_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fav_revisit_reminder_user_business_key UNIQUE (user_id, business_id)
);

CREATE INDEX IF NOT EXISTS idx_fav_revisit_reminder_user
  ON public.favorite_revisit_reminders_sent (user_id);

ALTER TABLE public.favorite_revisit_reminders_sent ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_favorite_revisit_reminders_v1(
  p_batch_size int DEFAULT 200
)
RETURNS integer   -- returns count of notifications created
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count  integer := 0;
  v_rec    record;
  v_bname  text;
BEGIN
  FOR v_rec IN
    SELECT f.user_id, f.business_id, b.name AS business_name
    FROM   public.favorites f
    JOIN   public.businesses b ON b.id = f.business_id
    WHERE  f.created_at BETWEEN now() - interval '22 days' AND now() - interval '20 days'
      -- Not already checked in within the last 21 days
      AND NOT EXISTS (
        SELECT 1 FROM public.business_checkins c
        WHERE  c.user_id     = f.user_id
          AND  c.business_id = f.business_id
          AND  c.created_at  >= now() - interval '21 days'
      )
      -- Not already sent this reminder
      AND NOT EXISTS (
        SELECT 1 FROM public.favorite_revisit_reminders_sent s
        WHERE  s.user_id     = f.user_id
          AND  s.business_id = f.business_id
      )
    LIMIT p_batch_size
  LOOP
    v_bname := coalesce(v_rec.business_name, 'İşletme');

    PERFORM public.notify_user_v1(
      v_rec.user_id,
      'favorite_revisit_reminder',
      '📍 Hâlâ gitmek ister misin?',
      v_bname || ' favorilerinizde. Ziyaret etmek ister misiniz?',
      jsonb_build_object(
        'business_id', v_rec.business_id
      )
    );

    -- Mark as sent (dedup)
    INSERT INTO public.favorite_revisit_reminders_sent (user_id, business_id)
    VALUES (v_rec.user_id, v_rec.business_id)
    ON CONFLICT (user_id, business_id) DO NOTHING;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.notify_favorite_revisit_reminders_v1(int)
  TO service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- pg_cron: run daily at 10:00 UTC.
-- Only installs if pg_cron extension is available (no-op otherwise).
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    PERFORM cron.schedule(
      'favorite_revisit_reminder_daily',
      '0 10 * * *',
      $$SELECT public.notify_favorite_revisit_reminders_v1(200)$$
    );
  END IF;
END;
$$;
