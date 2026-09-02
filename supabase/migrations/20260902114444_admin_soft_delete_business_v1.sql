CREATE OR REPLACE FUNCTION public.admin_soft_delete_business_v1(p_business_id uuid, p_admin_note text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.businesses
  SET is_active = false,
      source = 'admin_removed'
  WHERE id = p_business_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public.log_admin_action_v1(
    'business.soft_delete',
    'businesses',
    p_business_id,
    jsonb_build_object('note', p_admin_note)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.admin_soft_delete_business_v1 IS
  'Admin: işletmeyi güvenli şekilde kaldırır (is_active=false, source=admin_removed) — geri alınabilir (is_active geri açılabilir), denetim kaydı log_admin_action_v1 üzerinden düşer. Merge''den farkı: hedef bir "birincil" işletme gerektirmez, tek başına kullanılabilir. Called by: app/yonetici/isletmeler/isletme-duzenle-modal.tsx.';
