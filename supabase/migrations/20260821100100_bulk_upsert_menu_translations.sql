-- Otomatik çeviri route'unun kullandığı toplu upsert RPC'si. Route'un mevcut
-- hali doğrudan menu_translations'a INSERT atıyordu: yanlış entity_type enum
-- değerleri ('menu_item'/'section' yerine 'item'/'category' olmalı), hiç plan
-- dil-limiti kontrolü ve hiç per-entity sahiplik kontrolü yoktu (business_id
-- sahiplik kontrolü var ama gönderilen entity_id'lerin GERÇEKTEN o business'a
-- ait olduğu hiç doğrulanmıyordu — cross-business IDOR riski).

CREATE OR REPLACE FUNCTION public.bulk_upsert_menu_translations_v1(
  p_business_id   uuid,
  p_translations  jsonb  -- [{entity_type: 'item'|'category', entity_id: uuid, locale: text, name: text, description: text|null}]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _owned boolean;
  _item jsonb;
  _locale text;
  _allowed_locales text[] := ARRAY[]::text[];
  _skipped_locales text[] := ARRAY[]::text[];
  _inserted int := 0;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM business_claims bc
    WHERE bc.business_id = p_business_id
      AND bc.user_id = auth.uid()
      AND bc.status = 'approved'
  ) INTO _owned;

  IF NOT _owned AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  -- Her hedef dili işletme genelinde SADECE BİR KEZ değerlendir (item bazında
  -- tekrar tekrar kontrol etmek "1 + kullanılan dil sayısı" mantığını bozar).
  FOR _locale IN SELECT DISTINCT (t->>'locale') FROM jsonb_array_elements(p_translations) t
  LOOP
    IF public._check_translation_language_limit_v1(p_business_id, _locale) THEN
      _allowed_locales := array_append(_allowed_locales, _locale);
    ELSE
      _skipped_locales := array_append(_skipped_locales, _locale);
    END IF;
  END LOOP;

  FOR _item IN SELECT * FROM jsonb_array_elements(p_translations)
  LOOP
    CONTINUE WHEN NOT (_item->>'locale' = ANY(_allowed_locales));
    CONTINUE WHEN (_item->>'entity_type') NOT IN ('item', 'category');

    -- entity_id gerçekten p_business_id'ye mi ait? (IDOR koruması)
    IF (_item->>'entity_type') = 'item' THEN
      CONTINUE WHEN NOT EXISTS (
        SELECT 1 FROM menu_items mi
        WHERE mi.id = (_item->>'entity_id')::uuid AND mi.business_id = p_business_id
      );
    ELSE
      CONTINUE WHEN NOT EXISTS (
        SELECT 1 FROM menu_sections ms
        JOIN menus m ON m.id = ms.menu_id
        WHERE ms.id = (_item->>'entity_id')::uuid AND m.business_id = p_business_id
      );
    END IF;

    INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
    VALUES (
      (_item->>'entity_type')::translation_entity_type,
      (_item->>'entity_id')::uuid,
      _item->>'locale',
      _item->>'name',
      _item->>'description'
    )
    ON CONFLICT (entity_type, entity_id, locale)
    DO UPDATE SET name = excluded.name, description = excluded.description;

    _inserted := _inserted + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'inserted', _inserted,
    'skipped_locales', to_jsonb(_skipped_locales)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) FROM anon;
COMMENT ON FUNCTION public.bulk_upsert_menu_translations_v1 IS
  'Otomatik çeviri route''unun kullandığı toplu upsert. Sahiplik business_claims üzerinden, her entity_id''nin p_business_id''ye ait olduğu ayrıca doğrulanır (IDOR koruması), dil-limiti _check_translation_language_limit_v1 üzerinden kontrol edilir; limit aşan diller sessizce atlanıp skipped_locales''te raporlanır. Called by: app/sunucu/sahip/ceviriler-otomatik/route.ts.';
