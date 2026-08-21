-- upsert_menu_item_translation_v1 içindeki dil-limiti mantığını ortak bir
-- internal helper'a çıkarır (Task 2'deki bulk RPC ve section RPC de
-- kullanacak). Section RPC'sinde bu kontrol hiç yoktu — kapatılıyor.
-- Ayrıca route.ts'in API çağrısı yapmadan ÖNCE hangi dillerin plan limitine
-- takılacağını öğrenebilmesi için client-çağrılabilir bir wrapper eklenir
-- (proje konvansiyonu: `_` prefixli fonksiyonlar sadece diğer RPC'lerden
-- çağrılır, authenticated'a hiç grant edilmez — bkz. _get_business_plan_tier_v1).

CREATE OR REPLACE FUNCTION public._check_translation_language_limit_v1(
  p_business_id uuid,
  p_locale      text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _locale_exists boolean;
  _used_locales  int;
  _limit         int;
  _tier          text;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM menu_translations mt
    JOIN menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
    WHERE mi.business_id = p_business_id
      AND mt.locale = p_locale
  ) INTO _locale_exists;

  IF _locale_exists THEN
    RETURN true;
  END IF;

  _tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT limit_value INTO _limit
  FROM public.plan_features
  WHERE plan_tier = _tier AND feature_key = 'language_count';

  IF _limit IS NULL THEN
    RETURN true; -- sınırsız (pro) ya da satır yoksa kısıtlama uygulama
  END IF;

  SELECT 1 + count(DISTINCT mt.locale) INTO _used_locales
  FROM menu_translations mt
  JOIN menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
  WHERE mi.business_id = p_business_id;

  RETURN _used_locales < _limit;
END;
$$;

REVOKE ALL ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM authenticated;
COMMENT ON FUNCTION public._check_translation_language_limit_v1 IS
  'İşletmenin bu dilde çeviri eklemesine plan kademesi izin veriyor mu (dil zaten kullanılıyorsa her zaman true). Sadece diğer SECURITY DEFINER RPC''lerden çağrılır. Called by: upsert_menu_item_translation_v1, upsert_menu_section_translation_v1, bulk_upsert_menu_translations_v1, check_translation_language_limit_v1.';

-- Client tarafından ön-kontrol için (route API çağrısı yapmadan önce hangi
-- dillerin limite takılacağını öğrenmek üzere) — sahiplik kontrolü kendi içinde.
CREATE OR REPLACE FUNCTION public.check_translation_language_limit_v1(
  p_business_id uuid,
  p_locale      text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM business_claims bc
    WHERE bc.business_id = p_business_id AND bc.user_id = auth.uid() AND bc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN public._check_translation_language_limit_v1(p_business_id, p_locale);
END;
$$;

REVOKE ALL ON FUNCTION public.check_translation_language_limit_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_translation_language_limit_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.check_translation_language_limit_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.check_translation_language_limit_v1 IS
  'Client tarafından dil-limiti ön-kontrolü (auto-translate route API çağrısı yapmadan önce). Called by: app/sunucu/sahip/ceviriler-otomatik/route.ts.';

-- upsert_menu_item_translation_v1: inline mantığı ortak helper'a devret (davranış aynı kalır)
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

  IF NOT public._check_translation_language_limit_v1(_business_id, p_locale) THEN
    RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
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

-- upsert_menu_section_translation_v1: dil-limiti kontrolü hiç yoktu, ekleniyor.
-- ON CONFLICT hedefi item RPC'sindeki gerçek unique constraint ile aynı
-- hizaya getirildi (menu_translations_entity_id_locale_unique (entity_type, entity_id, locale)).
CREATE OR REPLACE FUNCTION public.upsert_menu_section_translation_v1(
  p_section_id uuid,
  p_locale     text,
  p_name       text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _business_id uuid;
  _row menu_translations%rowtype;
BEGIN
  SELECT b.id INTO _business_id
  FROM business_claims bc
  JOIN businesses b  ON b.id = bc.business_id
  JOIN menus       m  ON m.business_id = b.id
  JOIN menu_sections ms ON ms.menu_id = m.id
  WHERE ms.id = p_section_id
    AND bc.user_id = auth.uid()
    AND bc.status = 'approved'
  LIMIT 1;

  IF _business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF NOT public._check_translation_language_limit_v1(_business_id, p_locale) THEN
    RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
  VALUES ('category', p_section_id, p_locale, p_name, null)
  ON CONFLICT (entity_type, entity_id, locale)
  DO UPDATE SET name = excluded.name;

  SELECT * INTO _row
  FROM menu_translations
  WHERE entity_type = 'category'
    AND entity_id = p_section_id
    AND locale = p_locale;

  RETURN jsonb_build_object(
    'id',     _row.id,
    'locale', _row.locale,
    'name',   _row.name
  );
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) FROM anon;
