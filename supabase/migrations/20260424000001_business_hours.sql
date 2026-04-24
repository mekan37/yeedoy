-- Business Hours v2: normalized weekly schedule + special (holiday/event) days
-- NOTE: The legacy `business_hours` table (wide format with mon_open, mon_close …)
--       is kept intact for backward-compat with the mobile app.
--       This migration adds business_weekly_hours (normalized) + business_special_hours.

-- ─── Weekly schedule (normalized per-day rows) ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_weekly_hours (
  id            uuid        PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  business_id   uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  day_of_week   smallint    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  -- 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  open_time     time        NOT NULL DEFAULT '09:00',
  close_time    time        NOT NULL DEFAULT '22:00',
  is_closed     bool        NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, day_of_week)
);

-- ─── Special / holiday days ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_special_hours (
  id            uuid        PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  business_id   uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  special_date  date        NOT NULL,
  open_time     time,                          -- null means closed all day
  close_time    time,
  is_closed     bool        NOT NULL DEFAULT true,
  note          text,                          -- e.g. "Ulusal Bayram", "Tadilat"
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, special_date)
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS business_weekly_hours_business_id_idx
  ON public.business_weekly_hours (business_id);

CREATE INDEX IF NOT EXISTS business_special_hours_business_date_idx
  ON public.business_special_hours (business_id, special_date);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.business_weekly_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_special_hours ENABLE ROW LEVEL SECURITY;

-- Public read (anyone can see hours)
CREATE POLICY "business_weekly_hours_public_read"
  ON public.business_weekly_hours FOR SELECT USING (true);

CREATE POLICY "business_special_hours_public_read"
  ON public.business_special_hours FOR SELECT USING (true);

-- Owner write (owns the business)
CREATE POLICY "business_weekly_hours_owner_write"
  ON public.business_weekly_hours FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.business_claims bc
      WHERE bc.business_id = business_weekly_hours.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );

CREATE POLICY "business_special_hours_owner_write"
  ON public.business_special_hours FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.business_claims bc
      WHERE bc.business_id = business_special_hours.business_id
        AND bc.user_id = auth.uid()
        AND bc.status = 'approved'
    )
  );

-- ─── RPC: upsert weekly hours (bulk, all 7 days at once) ─────────────────────
CREATE OR REPLACE FUNCTION public.upsert_business_hours_v1(
  p_business_id uuid,
  p_hours       jsonb   -- array of {day_of_week, open_time, close_time, is_closed}
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _row jsonb;
BEGIN
  -- Ownership check
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  FOR _row IN SELECT * FROM jsonb_array_elements(p_hours)
  LOOP
    INSERT INTO public.business_weekly_hours
      (business_id, day_of_week, open_time, close_time, is_closed, updated_at)
    VALUES (
      p_business_id,
      (_row->>'day_of_week')::smallint,
      (_row->>'open_time')::time,
      (_row->>'close_time')::time,
      (_row->>'is_closed')::bool,
      now()
    )
    ON CONFLICT (business_id, day_of_week) DO UPDATE SET
      open_time  = EXCLUDED.open_time,
      close_time = EXCLUDED.close_time,
      is_closed  = EXCLUDED.is_closed,
      updated_at = now();
  END LOOP;
END;
$$;

-- ─── RPC: upsert single special day ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_business_special_hour_v1(
  p_business_id uuid,
  p_date        date,
  p_open_time   time    DEFAULT NULL,
  p_close_time  time    DEFAULT NULL,
  p_is_closed   bool    DEFAULT true,
  p_note        text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  INSERT INTO public.business_special_hours
    (business_id, special_date, open_time, close_time, is_closed, note)
  VALUES (p_business_id, p_date, p_open_time, p_close_time, p_is_closed, p_note)
  ON CONFLICT (business_id, special_date) DO UPDATE SET
    open_time  = EXCLUDED.open_time,
    close_time = EXCLUDED.close_time,
    is_closed  = EXCLUDED.is_closed,
    note       = EXCLUDED.note;
END;
$$;

-- ─── RPC: delete special day ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.delete_business_special_hour_v1(
  p_business_id uuid,
  p_date        date
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  DELETE FROM public.business_special_hours
  WHERE business_id = p_business_id AND special_date = p_date;
END;
$$;

-- ─── Public read function: get hours for a business ───────────────────────────
CREATE OR REPLACE FUNCTION public.get_business_hours_v1(
  p_business_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'weekly',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'day_of_week', day_of_week,
            'open_time',   to_char(open_time, 'HH24:MI'),
            'close_time',  to_char(close_time, 'HH24:MI'),
            'is_closed',   is_closed
          ) ORDER BY day_of_week
        )
        FROM public.business_weekly_hours
        WHERE business_id = p_business_id
      ),
      '[]'::jsonb
    ),
    'special',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'date',       special_date,
            'open_time',  to_char(open_time, 'HH24:MI'),
            'close_time', to_char(close_time, 'HH24:MI'),
            'is_closed',  is_closed,
            'note',       note
          ) ORDER BY special_date
        )
        FROM public.business_special_hours
        WHERE business_id = p_business_id
          AND special_date >= current_date
      ),
      '[]'::jsonb
    ),
    'is_open_now',
    (
      SELECT
        CASE
          -- Check special hours for today first
          WHEN EXISTS (
            SELECT 1 FROM public.business_special_hours sh
            WHERE sh.business_id = p_business_id
              AND sh.special_date = current_date
          ) THEN (
            SELECT NOT sh.is_closed
              AND sh.open_time IS NOT NULL
              AND current_time BETWEEN sh.open_time AND sh.close_time
            FROM public.business_special_hours sh
            WHERE sh.business_id = p_business_id
              AND sh.special_date = current_date
          )
          -- Fall back to weekly schedule
          WHEN EXISTS (
            SELECT 1 FROM public.business_weekly_hours bh
            WHERE bh.business_id = p_business_id
              AND bh.day_of_week = EXTRACT(DOW FROM current_timestamp AT TIME ZONE 'Europe/Istanbul')::smallint
          ) THEN (
            SELECT NOT bh.is_closed
              AND (current_timestamp AT TIME ZONE 'Europe/Istanbul')::time
                  BETWEEN bh.open_time AND bh.close_time
            FROM public.business_weekly_hours bh
            WHERE bh.business_id = p_business_id
              AND bh.day_of_week = EXTRACT(DOW FROM current_timestamp AT TIME ZONE 'Europe/Istanbul')::smallint
          )
          ELSE NULL   -- hours not configured
        END
    )
  );
$$;

GRANT EXECUTE ON FUNCTION public.upsert_business_hours_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_business_special_hour_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_business_special_hour_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_business_hours_v1 TO anon, authenticated;
