-- Kalori ve porsiyon alanları
-- Kalori aralık olarak saklanır (min-max) — AI tahmini için
ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS calories_min  SMALLINT,   -- kcal alt sınır
  ADD COLUMN IF NOT EXISTS calories_max  SMALLINT,   -- kcal üst sınır
  ADD COLUMN IF NOT EXISTS portion_size  SMALLINT,   -- porsiyon miktarı (örn: 350)
  ADD COLUMN IF NOT EXISTS portion_unit  VARCHAR(20); -- 'g' | 'ml' | 'adet' | 'dilim'

-- AI doldurulan alanların güvenilirliği
ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS calorie_source VARCHAR(20) DEFAULT 'unknown';
-- Değerler: 'owner' | 'ai_estimated' | 'community' | 'unknown'

-- Owner kendi ürününe kalori/porsiyon girer
CREATE OR REPLACE FUNCTION set_menu_item_nutrition_v1(
  p_menu_item_id  UUID,
  p_calories_min  INT     DEFAULT NULL,
  p_calories_max  INT     DEFAULT NULL,
  p_portion_size  INT     DEFAULT NULL,
  p_portion_unit  TEXT    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  SELECT b.owner_id INTO v_owner_id
  FROM menu_items mi
  JOIN menus m ON m.id = mi.menu_id
  JOIN businesses b ON b.id = m.business_id
  WHERE mi.id = p_menu_item_id;

  IF v_owner_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  UPDATE menu_items
  SET
    calories_min   = p_calories_min,
    calories_max   = p_calories_max,
    portion_size   = p_portion_size,
    portion_unit   = COALESCE(p_portion_unit, portion_unit),
    calorie_source = 'owner'
  WHERE id = p_menu_item_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- get_menu_items_v1 view'ını güncelle (eğer view ise) ya da RPC alanlarını genişlet.
-- Not: get_menu_items_v1 migration'ları yoksa tablo sorgularına bakılmalı.
-- Aşağıdaki index aranabilirliği kolaylaştırır
CREATE INDEX IF NOT EXISTS idx_menu_items_has_calories
  ON menu_items (calories_min)
  WHERE calories_min IS NOT NULL;
