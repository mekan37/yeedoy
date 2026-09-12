-- P2: LIMIT yoktu — su an dusuk hacim ama olcek buyudukce risk.
DROP FUNCTION IF EXISTS public.admin_list_stock_dish_images_v1();

CREATE OR REPLACE FUNCTION public.admin_list_stock_dish_images_v1(p_limit integer DEFAULT 500)
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
    ORDER BY s.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 2000);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_stock_dish_images_v1(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_stock_dish_images_v1(integer) TO authenticated;
COMMENT ON FUNCTION public.admin_list_stock_dish_images_v1(integer) IS
  'Admin: pasif dahil tüm stok görselleri listeler (varsayılan limit 500). Called by: app/yonetici/gorsel-kutuphanesi.';
