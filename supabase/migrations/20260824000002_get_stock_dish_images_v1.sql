CREATE OR REPLACE FUNCTION public.get_stock_dish_images_v1()
RETURNS TABLE (id uuid, image_url text, keywords text[])
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, image_url, keywords
  FROM public.stock_dish_images
  WHERE is_active = true
  ORDER BY created_at;
$$;

REVOKE ALL ON FUNCTION public.get_stock_dish_images_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_stock_dish_images_v1() TO authenticated, anon;
COMMENT ON FUNCTION public.get_stock_dish_images_v1 IS
  'Aktif stok yemek görsellerini döner (id, image_url, keywords). Public okuma — anonim menü ziyaretçileri dahil. Called by: web varsayilan-yemek-gorseli fetch, mobil menu_page fetch, sahip Sistemden Seç.';
