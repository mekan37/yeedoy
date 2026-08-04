-- upsert_menu_item_translation_v1'e plan bazlı dil sayısı limiti ekle.
-- (Önceki tanım: supabase/migrations/20260424000004_menu_item_translation_rpc.sql)

CREATE OR REPLACE FUNCTION public.upsert_menu_item_translation_v1(
  p_item_id     uuid,
  p_locale      text,
  p_name        text,
  p_description text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _business_id uuid;
  _row menu_translations%rowtype;
  _locale_exists boolean;
  _used_locales int;
  _limit int;
  _tier text;
BEGIN
  SELECT b.id INTO _business_id
  FROM business_claims bc
  JOIN businesses b ON b.id = bc.business_id
  JOIN menus m ON m.business_id = b.id
  JOIN menu_sections ms ON ms.menu_id = m.id
  JOIN menu_items mi ON mi.section_id = ms.id
  WHERE mi.id = p_item_id
    AND bc.user_id = auth.uid()
    AND bc.status = 'approved'
  LIMIT 1;

  IF _business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Bu işletmede bu locale'de (herhangi bir item için) zaten bir çeviri var mı?
  -- Varsa güncelleme/yeni item ekleme serbest (dil zaten işletme genelinde benimsenmiş).
  SELECT EXISTS (
    SELECT 1
    FROM menu_translations mt
    JOIN menu_items mi3 ON mi3.id = mt.entity_id AND mt.entity_type = 'item'
    WHERE mi3.business_id = _business_id
      AND mt.locale = p_locale
  ) INTO _locale_exists;

  IF NOT _locale_exists THEN
    _tier := public._get_business_plan_tier_v1(_business_id);

    SELECT limit_value INTO _limit
    FROM public.plan_features
    WHERE plan_tier = _tier AND feature_key = 'language_count';

    IF _limit IS NOT NULL THEN
      SELECT 1 + count(DISTINCT mt.locale) INTO _used_locales
      FROM menu_translations mt
      JOIN menu_items mi2 ON mi2.id = mt.entity_id AND mt.entity_type = 'item'
      WHERE mi2.business_id = _business_id;

      IF _used_locales >= _limit THEN
        RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
      END IF;
    END IF;
  END IF;

  INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
  VALUES ('item', p_item_id, p_locale, p_name, p_description)
  ON CONFLICT (entity_type, entity_id, locale)
  DO UPDATE SET
    name        = excluded.name,
    description = excluded.description;

  SELECT * INTO _row
  FROM menu_translations
  WHERE entity_type = 'item'
    AND entity_id = p_item_id
    AND locale = p_locale;

  RETURN jsonb_build_object(
    'id',          _row.id,
    'locale',      _row.locale,
    'name',        _row.name,
    'description', _row.description
  );
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) FROM anon;
