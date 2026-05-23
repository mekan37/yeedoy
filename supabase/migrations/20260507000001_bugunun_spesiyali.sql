-- Bugünün Spesiyali — owner bir menü ürününü günlük öne çıkarır.
-- special_date = CURRENT_DATE kontrolü ile sadece o gün görünür; ertesi gün otomatik sona erer.
ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS is_today_special  BOOLEAN      NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS special_note      TEXT,
  ADD COLUMN IF NOT EXISTS special_date      DATE;

-- Index: aktif spesiyalleri hızlı çek
CREATE INDEX IF NOT EXISTS idx_menu_items_today_special
  ON menu_items (is_today_special, special_date)
  WHERE is_today_special = TRUE;

-- Owner bir ürünü spesiyel işaretler / kaldırır
CREATE OR REPLACE FUNCTION set_today_special_v1(
  p_menu_item_id UUID,
  p_is_special   BOOLEAN,
  p_note         TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_owner_id    UUID;
BEGIN
  -- Ürünün sahibi doğrulama
  SELECT b.id, b.owner_id
  INTO v_business_id, v_owner_id
  FROM menu_items mi
  JOIN businesses b ON b.id = mi.business_id
  WHERE mi.id = p_menu_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF v_owner_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  UPDATE menu_items
  SET
    is_today_special = p_is_special,
    special_date     = CASE WHEN p_is_special THEN CURRENT_DATE ELSE NULL END,
    special_note     = CASE WHEN p_is_special THEN p_note       ELSE NULL END
  WHERE id = p_menu_item_id;

  RETURN jsonb_build_object('ok', true, 'business_id', v_business_id);
END;
$$;

-- Notification trigger: spesiyel işaretlenince takipçilere bildir
CREATE OR REPLACE FUNCTION notify_today_special_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec           RECORD;
  business_id_v UUID;
  business_name_v TEXT;
BEGIN
  -- Yalnızca false → true geçişinde
  IF NOT NEW.is_today_special OR OLD.is_today_special THEN RETURN NEW; END IF;

  SELECT b.id, b.name INTO business_id_v, business_name_v
  FROM businesses b
  WHERE b.id = NEW.business_id
  LIMIT 1;

  IF business_id_v IS NULL THEN RETURN NEW; END IF;

  FOR rec IN
    SELECT f.user_id
    FROM favorites f
    WHERE f.business_id = business_id_v
  LOOP
    INSERT INTO notifications (user_id, type, title, message, target_path, meta)
    VALUES (
      rec.user_id,
      'today_special',
      business_name_v || ''' da bugünün spesiyali!',
      NEW.name || COALESCE(': ' || NEW.special_note, ''),
      '/isletme/' || business_id_v::text,
      jsonb_build_object(
        'business_id', business_id_v,
        'menu_item_id', NEW.id
      )
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS today_special_notify ON menu_items;
CREATE TRIGGER today_special_notify
  AFTER UPDATE OF is_today_special ON menu_items
  FOR EACH ROW EXECUTE FUNCTION notify_today_special_trigger();

-- Bugünün spesiyallerini döndüren public RPC
-- Konum bazlı veya şehir bazlı çağrılabilir
CREATE OR REPLACE FUNCTION get_today_specials_v1(
  p_city     TEXT    DEFAULT NULL,
  p_lat      FLOAT8  DEFAULT NULL,
  p_lng      FLOAT8  DEFAULT NULL,
  p_radius_km FLOAT8 DEFAULT 10,
  p_limit    INT     DEFAULT 20
)
RETURNS TABLE (
  menu_item_id  UUID,
  item_name     TEXT,
  special_note  TEXT,
  price_cents   INT,
  currency      TEXT,
  business_id   UUID,
  business_name TEXT,
  business_slug TEXT,
  city          TEXT,
  distance_km   FLOAT8
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    mi.id                     AS menu_item_id,
    mi.name                   AS item_name,
    mi.special_note,
    mi.price_cents,
    COALESCE(mi.currency, 'TRY') AS currency,
    b.id                      AS business_id,
    b.name                    AS business_name,
    b.slug                    AS business_slug,
    b.city,
    CASE
      WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND b.lat IS NOT NULL AND b.lng IS NOT NULL
      THEN extensions.earth_distance(
        extensions.ll_to_earth(p_lat, p_lng),
        extensions.ll_to_earth(b.lat, b.lng)
      ) / 1000.0
      ELSE NULL
    END AS distance_km
  FROM menu_items mi
  JOIN menu_sections ms ON ms.id = mi.section_id
  JOIN menus m          ON m.id = ms.menu_id AND m.status = 'published'
  JOIN businesses b     ON b.id = m.business_id AND b.is_active = TRUE
  WHERE mi.is_today_special = TRUE
    AND mi.special_date = CURRENT_DATE
    AND mi.is_available = TRUE
    AND (p_city IS NULL OR b.city = p_city)
    AND (
      p_lat IS NULL OR p_lng IS NULL OR b.lat IS NULL OR b.lng IS NULL
      OR extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lng), extensions.ll_to_earth(b.lat, b.lng)) / 1000.0 <= p_radius_km
    )
  ORDER BY distance_km NULLS LAST, mi.name
  LIMIT p_limit;
$$;
