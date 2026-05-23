-- Masa Siparişi Phase 1: "Garsona Bildir"
-- Müşteri menüden ürün seçip garsona bildiriyor — ödeme yok, sadece sipariş notu.
CREATE TABLE IF NOT EXISTS table_orders (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  table_number    TEXT        NOT NULL,
  items_json      JSONB       NOT NULL DEFAULT '[]', -- [{name, qty, note}]
  status          TEXT        NOT NULL DEFAULT 'pending', -- pending | seen | done
  customer_note   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  seen_at         TIMESTAMPTZ,
  done_at         TIMESTAMPTZ
);

-- Müşteri sipariş gönderir (anonim — session token ile)
CREATE OR REPLACE FUNCTION submit_table_order_v1(
  p_business_id  UUID,
  p_table_number TEXT,
  p_items_json   JSONB,
  p_note         TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order_id UUID;
BEGIN
  IF p_table_number IS NULL OR trim(p_table_number) = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'table_number_required');
  END IF;

  IF jsonb_array_length(p_items_json) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'empty_order');
  END IF;

  -- Basit rate limit: aynı masa numarası son 2 dakikada 3'ten fazla sipariş gönderemez
  IF (
    SELECT COUNT(*)
    FROM table_orders
    WHERE business_id = p_business_id
      AND table_number = p_table_number
      AND created_at > NOW() - INTERVAL '2 minutes'
  ) >= 3 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'rate_limited');
  END IF;

  INSERT INTO table_orders (business_id, table_number, items_json, customer_note)
  VALUES (p_business_id, trim(p_table_number), p_items_json, p_note)
  RETURNING id INTO v_order_id;

  RETURN jsonb_build_object('ok', true, 'order_id', v_order_id);
END;
$$;

-- Sahip bekleyen siparişleri görür
CREATE OR REPLACE FUNCTION get_pending_table_orders_v1(
  p_business_id UUID,
  p_limit       INT DEFAULT 20
)
RETURNS TABLE (
  id           UUID,
  table_number TEXT,
  items_json   JSONB,
  customer_note TEXT,
  status       TEXT,
  created_at   TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, table_number, items_json, customer_note, status, created_at
  FROM table_orders
  WHERE business_id = p_business_id
    AND status IN ('pending', 'seen')
  ORDER BY created_at DESC
  LIMIT p_limit;
$$;

-- Sahip sipariş durumunu günceller
CREATE OR REPLACE FUNCTION update_table_order_status_v1(
  p_order_id UUID,
  p_status   TEXT -- 'seen' | 'done'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_biz_owner UUID;
BEGIN
  SELECT b.owner_id INTO v_biz_owner
  FROM table_orders o
  JOIN businesses b ON b.id = o.business_id
  WHERE o.id = p_order_id;

  IF v_biz_owner IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  UPDATE table_orders
  SET
    status  = p_status,
    seen_at = CASE WHEN p_status = 'seen' THEN NOW() ELSE seen_at END,
    done_at = CASE WHEN p_status = 'done' THEN NOW() ELSE done_at END
  WHERE id = p_order_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- Index: sahip bekleyen siparişleri hızlı çeksin
CREATE INDEX IF NOT EXISTS idx_table_orders_business_status
  ON table_orders (business_id, status, created_at DESC);
