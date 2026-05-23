-- Check-in sistemi: kullanıcı bir işletmeyi ziyaret ettiğini işaretler.
-- visits tablosu zaten var — bu migration üstüne submit RPC ekler.

-- Kullanıcı check-in yapar (günde max 1 kez aynı işletme)
CREATE OR REPLACE FUNCTION submit_checkin_v1(
  p_business_id UUID,
  p_note        TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_exists  BOOLEAN;
  v_visit_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  -- İşletme var mı?
  IF NOT EXISTS (SELECT 1 FROM businesses WHERE id = p_business_id AND is_active = TRUE) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'business_not_found');
  END IF;

  -- Günde 1 check-in limiti (aynı işletme, aynı gün UTC)
  SELECT TRUE INTO v_exists
  FROM visits
  WHERE user_id = v_uid
    AND business_id = p_business_id
    AND checked_in_at::DATE = CURRENT_DATE;

  IF v_exists THEN
    RETURN jsonb_build_object('ok', false, 'error', 'already_checked_in_today');
  END IF;

  -- Check-in kaydet
  INSERT INTO visits (user_id, business_id, note, checked_in_at)
  VALUES (v_uid, p_business_id, p_note, NOW())
  RETURNING id INTO v_visit_id;

  RETURN jsonb_build_object('ok', true, 'visit_id', v_visit_id);
END;
$$;

-- Bugün check-in yaptı mı kontrolü
CREATE OR REPLACE FUNCTION get_my_checkin_today_v1(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('checked_in', false);
  END IF;

  RETURN jsonb_build_object(
    'checked_in',
    EXISTS (
      SELECT 1 FROM visits
      WHERE user_id = v_uid
        AND business_id = p_business_id
        AND checked_in_at::DATE = CURRENT_DATE
    )
  );
END;
$$;

-- visits tablosu yoksa oluştur (migration güvenliği)
CREATE TABLE IF NOT EXISTS visits (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_id    UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  note           TEXT,
  checked_in_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_visits_user_business_date
  ON visits (user_id, business_id, checked_in_at);

-- get_business_recent_checkins_v1 yoksa oluştur
CREATE OR REPLACE FUNCTION get_business_recent_checkins_v1(
  p_business_id UUID,
  p_hours       INT DEFAULT 2
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'count', COUNT(*)
  )
  FROM visits
  WHERE business_id = p_business_id
    AND checked_in_at >= NOW() - (p_hours || ' hours')::INTERVAL;
$$;
