-- P-16: Personel performansı — siparişi kimin işlediği

ALTER TABLE public.table_orders
  ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update the status function to capture who processed
CREATE OR REPLACE FUNCTION public.update_table_order_status_v1(
  p_order_id UUID,
  p_status   TEXT,
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_status NOT IN ('pending', 'seen', 'waiting', 'done') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_status');
  END IF;

  UPDATE table_orders
  SET
    status       = p_status,
    processed_by = auth.uid(),
    seen_at      = CASE WHEN p_status = 'seen'  THEN NOW() ELSE seen_at  END,
    done_at      = CASE WHEN p_status = 'done'  THEN NOW() ELSE done_at  END,
    updated_at   = NOW()
  WHERE id = p_order_id
    AND business_id = p_business_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- P-16: Personel performansı — bugün kim kaç sipariş işledi
CREATE OR REPLACE FUNCTION public.get_staff_performance_today_v1(
  p_business_id UUID
)
RETURNS TABLE(
  staff_id UUID,
  siparis_sayisi BIGINT,
  tamamlanan BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today TIMESTAMPTZ := date_trunc('day', NOW() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul';
BEGIN
  RETURN QUERY
  SELECT
    o.processed_by AS staff_id,
    COUNT(*) AS siparis_sayisi,
    COUNT(*) FILTER (WHERE o.status = 'done') AS tamamlanan
  FROM public.table_orders o
  WHERE o.business_id = p_business_id
    AND o.updated_at >= v_today
    AND o.processed_by IS NOT NULL
  GROUP BY o.processed_by
  ORDER BY siparis_sayisi DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_staff_performance_today_v1(UUID) TO authenticated;

COMMENT ON COLUMN public.table_orders.processed_by IS 'P-16: Siparişi işleyen personel (auth.uid() kaydedilir)';
