-- Kişisel Yemek Günlüğü
-- visits tablosunu genişletir: tutar, harcama notu, derecelendirme
ALTER TABLE visits
  ADD COLUMN IF NOT EXISTS amount_cents    INT,       -- ne kadar harcandı (kullanıcı giriyor)
  ADD COLUMN IF NOT EXISTS currency        VARCHAR(3) DEFAULT 'TRY',
  ADD COLUMN IF NOT EXISTS personal_note   TEXT,      -- kişisel not
  ADD COLUMN IF NOT EXISTS personal_rating SMALLINT   CHECK (personal_rating BETWEEN 1 AND 5);

-- Kullanıcı check-in'ine harcama ekler / düzenler
CREATE OR REPLACE FUNCTION update_visit_details_v1(
  p_visit_id       UUID,
  p_amount_cents   INT     DEFAULT NULL,
  p_note           TEXT    DEFAULT NULL,
  p_rating         INT     DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE visits
  SET
    amount_cents    = COALESCE(p_amount_cents, amount_cents),
    personal_note   = COALESCE(p_note, personal_note),
    personal_rating = COALESCE(p_rating, personal_rating)
  WHERE id = p_visit_id
    AND user_id = auth.uid();

  RETURN jsonb_build_object('ok', TRUE);
END;
$$;

-- Kullanıcının yemek günlüğünü döndürür
CREATE OR REPLACE FUNCTION get_my_food_journal_v1(
  p_limit  INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  visit_id      UUID,
  business_id   UUID,
  business_name TEXT,
  business_slug TEXT,
  city          TEXT,
  category      TEXT,
  checked_in_at TIMESTAMPTZ,
  amount_cents  INT,
  currency      TEXT,
  personal_note TEXT,
  personal_rating SMALLINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    v.id,
    b.id, b.name, b.slug, b.city, b.category,
    v.checked_in_at,
    v.amount_cents,
    COALESCE(v.currency, 'TRY'),
    v.personal_note,
    v.personal_rating
  FROM visits v
  JOIN businesses b ON b.id = v.business_id
  WHERE v.user_id = auth.uid()
  ORDER BY v.checked_in_at DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- Aylık harcama özeti
CREATE OR REPLACE FUNCTION get_my_spending_summary_v1(
  p_months INT DEFAULT 3
)
RETURNS TABLE (
  month_label     TEXT,
  total_cents     BIGINT,
  visit_count     INT,
  unique_places   INT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    to_char(date_trunc('month', checked_in_at), 'YYYY-MM') AS month_label,
    COALESCE(SUM(amount_cents), 0)::BIGINT AS total_cents,
    COUNT(*)::INT AS visit_count,
    COUNT(DISTINCT business_id)::INT AS unique_places
  FROM visits
  WHERE user_id = auth.uid()
    AND checked_in_at >= NOW() - make_interval(months => p_months)
  GROUP BY date_trunc('month', checked_in_at)
  ORDER BY date_trunc('month', checked_in_at) DESC;
$$;
