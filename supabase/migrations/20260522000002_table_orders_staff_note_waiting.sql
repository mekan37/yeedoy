-- P-6: Personel notu + P-7: Sipariş bekletme

-- P-6: Personel dahili notu (müşteri görmez)
ALTER TABLE public.table_orders
  ADD COLUMN IF NOT EXISTS staff_note TEXT;

-- P-7: 'waiting' durumu — malzeme bekleniyor
-- Mevcut status değerleri: pending | seen | done
-- Yeni değer: waiting (mutfak bekletme durumu)
-- CHECK constraint yoksa direkt ekleyebiliriz; varsa güncelleyelim

DO $$
BEGIN
  -- Try to add a check constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'table_orders_status_check'
  ) THEN
    ALTER TABLE public.table_orders
      ADD CONSTRAINT table_orders_status_check
      CHECK (status IN ('pending', 'seen', 'waiting', 'done'));
  ELSE
    -- Drop and recreate with waiting
    ALTER TABLE public.table_orders
      DROP CONSTRAINT table_orders_status_check;
    ALTER TABLE public.table_orders
      ADD CONSTRAINT table_orders_status_check
      CHECK (status IN ('pending', 'seen', 'waiting', 'done'));
  END IF;
END
$$;

-- Update the status function to allow 'waiting'
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
    status   = p_status,
    seen_at  = CASE WHEN p_status = 'seen'    THEN NOW() ELSE seen_at  END,
    done_at  = CASE WHEN p_status = 'done'    THEN NOW() ELSE done_at  END,
    updated_at = NOW()
  WHERE id = p_order_id
    AND business_id = p_business_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- P-6: Staff note update function
CREATE OR REPLACE FUNCTION public.update_table_order_staff_note_v1(
  p_order_id    UUID,
  p_staff_note  TEXT,
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE table_orders
  SET staff_note = p_staff_note, updated_at = NOW()
  WHERE id = p_order_id AND business_id = p_business_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

COMMENT ON COLUMN public.table_orders.staff_note IS 'P-6: Personel dahili notu — müşteriye gösterilmez';
