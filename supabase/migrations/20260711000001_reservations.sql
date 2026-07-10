-- ============================================================
-- Part A: Add reservation columns to businesses table
-- ============================================================

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS accepts_reservations    BOOLEAN  NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS reservation_phone        TEXT,
  ADD COLUMN IF NOT EXISTS reservation_min_party    INT      NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS reservation_max_party    INT      NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS reservation_advance_hours INT     NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS reservation_window_days  INT      NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS reservation_note         TEXT;

-- ============================================================
-- Part B: Create reservations table
-- ============================================================

-- Fix 1B: Sequence for race-condition-safe reservation_no generation
CREATE SEQUENCE IF NOT EXISTS public.reservation_no_seq;

CREATE TABLE IF NOT EXISTS public.reservations (
  id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id        UUID         NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id            UUID         REFERENCES auth.users(id),
  guest_name         TEXT         NOT NULL,
  guest_phone        TEXT         NOT NULL,
  guest_email        TEXT,
  party_size         INT          NOT NULL,
  reservation_date   DATE         NOT NULL,
  reservation_time   TIME         NOT NULL,
  status             TEXT         NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('pending','confirmed','cancelled','completed')),
  channel            TEXT         NOT NULL DEFAULT 'web'
                                  CHECK (channel IN ('web','mobile','phone','yeedoy_app')),
  table_preference   TEXT,
  special_request    TEXT,
  owner_note         TEXT,
  reservation_no     TEXT         NOT NULL,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
  -- Fix 1A: UNIQUE constraint to enforce no duplicate reservation numbers
  CONSTRAINT reservations_reservation_no_unique UNIQUE (reservation_no)
);

-- Indexes
CREATE INDEX IF NOT EXISTS reservations_business_id_idx
  ON public.reservations (business_id);

CREATE INDEX IF NOT EXISTS reservations_business_date_idx
  ON public.reservations (business_id, reservation_date);

CREATE INDEX IF NOT EXISTS reservations_business_status_idx
  ON public.reservations (business_id, status);

-- Fix 6: Partial index on user_id for user-facing reservation queries
CREATE INDEX IF NOT EXISTS reservations_user_id_idx
  ON public.reservations (user_id) WHERE user_id IS NOT NULL;

-- Row Level Security
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

-- Policy 1: Authenticated users can SELECT their own reservations
--            OR reservations for businesses they own
-- Fix 4: DROP before CREATE for idempotency
DROP POLICY IF EXISTS "reservations_select_policy" ON public.reservations;
CREATE POLICY "reservations_select_policy"
  ON public.reservations
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id     = auth.uid()
        AND oc.status      = 'approved'
    )
  );

-- Policy 2: Owners can do ALL operations on their businesses' reservations
-- Fix 4: DROP before CREATE for idempotency
DROP POLICY IF EXISTS "reservations_owner_all_policy" ON public.reservations;
CREATE POLICY "reservations_owner_all_policy"
  ON public.reservations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id     = auth.uid()
        AND oc.status      = 'approved'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id     = auth.uid()
        AND oc.status      = 'approved'
    )
  );

-- Trigger: keep updated_at current
CREATE OR REPLACE FUNCTION public.tg_reservations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Fix 5: DROP before CREATE for idempotency
DROP TRIGGER IF EXISTS tg_reservations_updated_at ON public.reservations;
CREATE TRIGGER tg_reservations_updated_at
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW EXECUTE FUNCTION public.tg_reservations_updated_at();

-- ============================================================
-- Part C: RPC create_reservation_v1
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_reservation_v1(
  p_business_id        UUID,
  p_guest_name         TEXT,
  p_guest_phone        TEXT,
  p_guest_email        TEXT    DEFAULT NULL,
  p_party_size         INT     DEFAULT 2,
  p_date               DATE    DEFAULT CURRENT_DATE,
  p_time               TIME    DEFAULT '19:00',
  p_channel            TEXT    DEFAULT 'web',
  p_table_preference   TEXT    DEFAULT NULL,
  p_special_request    TEXT    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_accepts        BOOLEAN;
  v_min_party      INT;
  v_max_party      INT;
  -- Fix 2: advance hours and window days variables
  v_advance_hours  INT;
  v_window_days    INT;
  v_reservation_no TEXT;
  v_new_id         UUID;
BEGIN
  -- 1. Look up business
  -- Fix 2: also fetch reservation_advance_hours and reservation_window_days
  SELECT accepts_reservations, reservation_min_party, reservation_max_party,
         reservation_advance_hours, reservation_window_days
    INTO v_accepts, v_min_party, v_max_party, v_advance_hours, v_window_days
    FROM public.businesses
   WHERE id = p_business_id AND is_active = true;

  -- 2. Not found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: İşletme bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  -- 3. Reservations not accepted
  IF v_accepts = false THEN
    RAISE EXCEPTION 'validation_error: Bu işletme rezervasyon kabul etmiyor' USING ERRCODE = 'P0003';
  END IF;

  -- 4. Validate party size
  IF p_party_size < v_min_party OR p_party_size > v_max_party THEN
    RAISE EXCEPTION 'validation_error: Kişi sayısı % ile % arasında olmalıdır', v_min_party, v_max_party
      USING ERRCODE = 'P0003';
  END IF;

  -- Fix 2: Validate minimum advance booking hours
  IF (p_date::timestamp + p_time) < (now() + (v_advance_hours || ' hours')::interval) THEN
    RAISE EXCEPTION 'validation_error: En az % saat önceden rezervasyon yapılmalıdır', v_advance_hours
      USING ERRCODE = 'P0003';
  END IF;

  -- Fix 3: Past-date guard
  IF p_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'validation_error: Geçmiş bir tarih için rezervasyon yapılamaz'
      USING ERRCODE = 'P0003';
  END IF;

  -- Fix 2: Validate maximum booking window days
  IF p_date > (CURRENT_DATE + v_window_days) THEN
    RAISE EXCEPTION 'validation_error: Rezervasyon en fazla % gün ileriye alınabilir', v_window_days
      USING ERRCODE = 'P0003';
  END IF;

  -- 5. Validate guest_name and guest_phone
  IF length(trim(p_guest_name)) < 2 THEN
    RAISE EXCEPTION 'validation_error: Misafir adı en az 2 karakter olmalıdır' USING ERRCODE = 'P0003';
  END IF;

  IF length(trim(p_guest_phone)) < 10 THEN
    RAISE EXCEPTION 'validation_error: Telefon numarası en az 10 karakter olmalıdır' USING ERRCODE = 'P0003';
  END IF;

  -- Fix 1C: Generate reservation_no via sequence (race-condition-safe, replaces COUNT approach)
  v_reservation_no := 'RZV-' || to_char(now(), 'YYYY') || '-'
                      || lpad(nextval('public.reservation_no_seq')::text, 4, '0');

  -- 6. Insert and return
  INSERT INTO public.reservations (
    business_id,
    user_id,
    guest_name,
    guest_phone,
    guest_email,
    party_size,
    reservation_date,
    reservation_time,
    channel,
    table_preference,
    special_request,
    reservation_no
  ) VALUES (
    p_business_id,
    auth.uid(),
    trim(p_guest_name),
    trim(p_guest_phone),
    p_guest_email,
    p_party_size,
    p_date,
    p_time,
    p_channel,
    p_table_preference,
    p_special_request,
    v_reservation_no
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object('id', v_new_id, 'reservation_no', v_reservation_no);
END;
$$;

REVOKE ALL ON FUNCTION public.create_reservation_v1(
  UUID, TEXT, TEXT, TEXT, INT, DATE, TIME, TEXT, TEXT, TEXT
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_reservation_v1(
  UUID, TEXT, TEXT, TEXT, INT, DATE, TIME, TEXT, TEXT, TEXT
) TO anon, authenticated;

COMMENT ON FUNCTION public.create_reservation_v1(
  UUID, TEXT, TEXT, TEXT, INT, DATE, TIME, TEXT, TEXT, TEXT
) IS 'Creates a new reservation for a business. Validates party size, guest info, and business reservation settings. Returns {id, reservation_no}. Called by: web/api/reservations/route.ts, mobile reservation flow.';

-- ============================================================
-- Part D: RPC owner_list_reservations_v1
-- ============================================================

CREATE OR REPLACE FUNCTION public.owner_list_reservations_v1(
  p_business_id  UUID,
  p_status       TEXT   DEFAULT NULL,
  p_date_from    DATE   DEFAULT NULL,
  p_date_to      DATE   DEFAULT NULL,
  p_limit        INT    DEFAULT 50,
  p_offset       INT    DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total   INT;
  v_rows    JSONB;
  -- Fix 7: clamped limit variable
  v_limit   INT;
BEGIN
  -- 1. Auth check
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  -- 2. Owner check
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims
     WHERE business_id = p_business_id
       AND user_id     = auth.uid()
       AND status      = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized: Bu işletmenin sahibi değilsiniz' USING ERRCODE = 'P0002';
  END IF;

  -- Fix 7: Clamp p_limit to [1, 200]
  v_limit := LEAST(GREATEST(p_limit, 1), 200);

  -- 3. Count total matching rows
  SELECT COUNT(*)
    INTO v_total
    FROM public.reservations r
   WHERE r.business_id = p_business_id
     AND (p_status    IS NULL OR r.status           = p_status)
     AND (p_date_from IS NULL OR r.reservation_date >= p_date_from)
     AND (p_date_to   IS NULL OR r.reservation_date <= p_date_to);

  -- 4. Fetch rows with pagination
  SELECT COALESCE(jsonb_agg(row_data ORDER BY row_data->>'reservation_date', row_data->>'reservation_time'), '[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT jsonb_build_object(
        'id',               r.id,
        'guest_name',       r.guest_name,
        'guest_phone',      r.guest_phone,
        'guest_email',      r.guest_email,
        'party_size',       r.party_size,
        'reservation_date', r.reservation_date,
        'reservation_time', r.reservation_time,
        'status',           r.status,
        'channel',          r.channel,
        'table_preference', r.table_preference,
        'special_request',  r.special_request,
        'owner_note',       r.owner_note,
        'reservation_no',   r.reservation_no,
        'created_at',       r.created_at,
        'updated_at',       r.updated_at
      ) AS row_data
      FROM public.reservations r
     WHERE r.business_id = p_business_id
       AND (p_status    IS NULL OR r.status           = p_status)
       AND (p_date_from IS NULL OR r.reservation_date >= p_date_from)
       AND (p_date_to   IS NULL OR r.reservation_date <= p_date_to)
     ORDER BY r.reservation_date, r.reservation_time
     LIMIT v_limit OFFSET p_offset
    ) sub;

  RETURN jsonb_build_object('rows', v_rows, 'total', v_total);
END;
$$;

REVOKE ALL ON FUNCTION public.owner_list_reservations_v1(
  UUID, TEXT, DATE, DATE, INT, INT
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.owner_list_reservations_v1(
  UUID, TEXT, DATE, DATE, INT, INT
) TO authenticated;

COMMENT ON FUNCTION public.owner_list_reservations_v1(
  UUID, TEXT, DATE, DATE, INT, INT
) IS 'Returns paginated reservations for an owner-managed business. Filters: status, date range. Returns {rows, total}. Called by: owner panel reservations page.';

-- ============================================================
-- Part E: RPC owner_update_reservation_status_v1
-- ============================================================

CREATE OR REPLACE FUNCTION public.owner_update_reservation_status_v1(
  p_id           UUID,
  p_business_id  UUID,
  p_status       TEXT,
  p_owner_note   TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Auth check
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  -- 2. Validate status value
  IF p_status NOT IN ('pending','confirmed','cancelled','completed') THEN
    RAISE EXCEPTION 'validation_error: Geçersiz rezervasyon durumu: %', p_status USING ERRCODE = 'P0003';
  END IF;

  -- 3. Owner check
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims
     WHERE business_id = p_business_id
       AND user_id     = auth.uid()
       AND status      = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized: Bu işletmenin sahibi değilsiniz' USING ERRCODE = 'P0002';
  END IF;

  -- 4. Update
  -- Fix 8: Use p_owner_note directly (not COALESCE) so explicit NULL clears the note
  UPDATE public.reservations
     SET status     = p_status,
         owner_note = p_owner_note
   WHERE id          = p_id
     AND business_id = p_business_id;

  -- 5. Not found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Rezervasyon bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_update_reservation_status_v1(
  UUID, UUID, TEXT, TEXT
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.owner_update_reservation_status_v1(
  UUID, UUID, TEXT, TEXT
) TO authenticated;

COMMENT ON FUNCTION public.owner_update_reservation_status_v1(
  UUID, UUID, TEXT, TEXT
) IS 'Allows an approved business owner to update the status and optional note of a reservation. Called by: owner panel reservation detail actions.';
