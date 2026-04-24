-- Migration: 20260422000003_menu_item_time_windows
-- Purpose: Adds time-based pricing windows (e.g. lunch special) to menu_items
--          as a server-side JSONB column. The mobile client reads this column
--          and surfaces "Öğle daha uygun" insight chips on the item detail page.
--
-- Schema for each window element:
--   {
--     "label_tr":      "Öğle Menüsü",   -- Turkish display label
--     "label_en":      "Lunch Menu",    -- English display label
--     "start_hour":    12,              -- Inclusive, 0-23 UTC+3 local hour
--     "end_hour":      14,              -- Exclusive, 0-23 UTC+3 local hour
--     "price_cents":   2500,            -- Discounted price in cents (optional)
--     "discount_pct":  20               -- Percentage off base price (optional)
--   }
-- Either price_cents OR discount_pct should be provided (not required to have both).

ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS time_windows jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN menu_items.time_windows IS
  'Array of time-based pricing windows. Each entry has label_tr, label_en,
   start_hour (inclusive), end_hour (exclusive), and either price_cents or
   discount_pct. Displayed on the mobile item detail page as insight chips.';

-- Index to find items that have at least one time window defined.
CREATE INDEX IF NOT EXISTS idx_menu_items_has_time_windows
  ON menu_items USING gin (time_windows)
  WHERE jsonb_array_length(time_windows) > 0;
