-- Çöp Kutusu sayfası yeniden tasarlanırken kalıcı silme özelliği eklendi —
-- önceden sadece geri yükleme (owner_restore_*_v1) vardı, gerçek bir "kalıcı
-- sil" yolu hiç yoktu. Aynı yetki deseni (has_business_permission_v1 'menu_write'
-- veya is_admin) ve aynı business_id çözümlemesi owner_restore_*_v1 ile birebir
-- aynı tutuldu.

CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_v1(p_menu_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menus WHERE id = p_menu_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  DELETE FROM public.menus WHERE id = p_menu_id AND status = 'archived';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_archived');
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_menu_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_item_v1(p_item_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menu_items WHERE id = p_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  DELETE FROM public.menu_items WHERE id = p_item_id AND is_available = false;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_archived');
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_item_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_item_photo_v1(p_photo_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menu_item_photos WHERE id = p_photo_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  DELETE FROM public.menu_item_photos WHERE id = p_photo_id AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_deleted');
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_photo_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.owner_empty_trash_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_menus   int;
  v_items   int;
  v_photos  int;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(p_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  WITH deleted AS (
    DELETE FROM public.menus WHERE business_id = p_business_id AND status = 'archived' RETURNING id
  )
  SELECT count(*) INTO v_menus FROM deleted;

  WITH deleted AS (
    DELETE FROM public.menu_items WHERE business_id = p_business_id AND is_available = false RETURNING id
  )
  SELECT count(*) INTO v_items FROM deleted;

  WITH deleted AS (
    DELETE FROM public.menu_item_photos WHERE business_id = p_business_id AND deleted_at IS NOT NULL RETURNING id
  )
  SELECT count(*) INTO v_photos FROM deleted;

  RETURN jsonb_build_object('ok', true, 'menus', v_menus, 'items', v_items, 'photos', v_photos);
END;
$function$;

REVOKE ALL ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owner_empty_trash_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_empty_trash_v1(uuid) TO authenticated;

COMMENT ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) IS
  'Arşivlenmiş (çöp kutusundaki) bir menüyü kalıcı olarak siler (bölüm/ürünleri cascade ile). Called by: app/sahip/cop-kutusu.';
COMMENT ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) IS
  'Pasif (çöp kutusundaki) bir menü ürününü kalıcı olarak siler. Called by: app/sahip/cop-kutusu.';
COMMENT ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) IS
  'Silinmiş bir ürün fotoğrafını kalıcı olarak siler. Called by: app/sahip/cop-kutusu.';
COMMENT ON FUNCTION public.owner_empty_trash_v1(uuid) IS
  'İşletmenin çöp kutusundaki tüm menü/ürün/fotoğrafları kalıcı olarak siler ("Çöp Kutusunu Boşalt"). Called by: app/sahip/cop-kutusu.';
