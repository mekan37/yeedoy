-- Phase 2: Personel app — menü availability + dashboard stats

-- 1. is_available kolonu (yoksa ekle)
ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS is_available boolean NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_menu_items_is_available
  ON menu_items(business_id, is_available);

-- 2. Menü kalemi availability güncelleme (owner/personel yetkisi)
CREATE OR REPLACE FUNCTION update_menu_item_availability_v1(
  p_item_id   uuid,
  p_available boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE menu_items
  SET is_available = p_available,
      updated_at   = now()
  WHERE id = p_item_id
    AND business_id IN (
      SELECT business_id FROM owner_claims
       WHERE user_id = auth.uid()
         AND status  = 'approved'
    );
END;
$$;

-- 3. İşletme günlük sipariş özeti
CREATE OR REPLACE FUNCTION get_business_daily_stats_v1(
  p_business_id uuid,
  p_date        date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total_orders',    COUNT(*),
    'pending',         COUNT(*) FILTER (WHERE status = 'pending'),
    'seen',            COUNT(*) FILTER (WHERE status = 'seen'),
    'done',            COUNT(*) FILTER (WHERE status = 'done'),
    'active_items',    (
                         SELECT COUNT(*) FROM menu_items
                          WHERE business_id = p_business_id
                            AND is_available = true
                       ),
    'inactive_items',  (
                         SELECT COUNT(*) FROM menu_items
                          WHERE business_id = p_business_id
                            AND is_available = false
                       )
  )
  FROM table_orders
  WHERE business_id = p_business_id
    AND created_at::date = p_date;
$$;

GRANT EXECUTE ON FUNCTION update_menu_item_availability_v1 TO authenticated;
GRANT EXECUTE ON FUNCTION get_business_daily_stats_v1 TO authenticated;
