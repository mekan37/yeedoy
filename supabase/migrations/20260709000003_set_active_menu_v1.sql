CREATE OR REPLACE FUNCTION public.set_active_menu_v1(
  p_menu_id     uuid,
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM owner_claims
    WHERE user_id     = auth.uid()
      AND business_id = p_business_id
      AND status      = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized: Bu işletme size ait değil' USING ERRCODE = 'P0002';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM menus WHERE id = p_menu_id AND business_id = p_business_id
  ) THEN
    RAISE EXCEPTION 'not_found: Menü bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  -- Draft all currently published menus for this business
  UPDATE menus
  SET    status = 'draft', updated_at = now()
  WHERE  business_id = p_business_id
    AND  id          != p_menu_id
    AND  status      = 'published';

  -- Activate target menu
  UPDATE menus
  SET    status = 'published', updated_at = now()
  WHERE  id = p_menu_id;

  RETURN json_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.set_active_menu_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_active_menu_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.set_active_menu_v1 IS
  'Activates a menu and drafts all others for the same business (atomic switch). Called by: app/api/owner/menus/[menuId]/activate/route.ts';
