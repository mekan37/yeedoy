CREATE OR REPLACE FUNCTION public.admin_list_stock_dish_images_v1()
RETURNS TABLE (id uuid, image_url text, keywords text[], is_active boolean, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT s.id, s.image_url, s.keywords, s.is_active, s.created_at
    FROM public.stock_dish_images s
    ORDER BY s.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_stock_dish_images_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1() TO authenticated;
COMMENT ON FUNCTION public.admin_list_stock_dish_images_v1 IS
  'Admin: pasif dahil tüm stok görselleri listeler. Called by: app/yonetici/gorsel-kutuphanesi.';

CREATE OR REPLACE FUNCTION public.admin_upsert_stock_dish_image_v1(
  p_id uuid DEFAULT NULL,
  p_image_url text DEFAULT NULL,
  p_keywords text[] DEFAULT NULL,
  p_is_active boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    IF p_image_url IS NULL OR trim(p_image_url) = '' THEN
      RAISE EXCEPTION 'validation_error: image_url zorunlu' USING ERRCODE = 'P0003';
    END IF;
    INSERT INTO public.stock_dish_images (image_url, keywords, is_active, created_by)
    VALUES (trim(p_image_url), COALESCE(p_keywords, '{}'), COALESCE(p_is_active, true), auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.stock_dish_images
    SET
      image_url = COALESCE(NULLIF(trim(p_image_url), ''), image_url),
      keywords = COALESCE(p_keywords, keywords),
      is_active = COALESCE(p_is_active, is_active),
      updated_at = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_stock_dish_image_v1(uuid, text, text[], boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_stock_dish_image_v1(uuid, text, text[], boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_upsert_stock_dish_image_v1 IS
  'Admin: stok görsel oluşturur (p_id=NULL) veya günceller. Called by: app/yonetici/gorsel-kutuphanesi.';

CREATE OR REPLACE FUNCTION public.admin_delete_stock_dish_image_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  DELETE FROM public.stock_dish_images WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_stock_dish_image_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_stock_dish_image_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_delete_stock_dish_image_v1 IS
  'Admin: kütüphane satırını kalıcı siler (yalnızca DB satırı — Storage dosyası v1 kapsamında silinmez). Called by: app/yonetici/gorsel-kutuphanesi.';
