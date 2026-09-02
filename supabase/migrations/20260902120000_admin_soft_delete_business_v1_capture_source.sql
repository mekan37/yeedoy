-- admin_soft_delete_business_v1: eski source değerini denetim kaydına ekle.
-- Önceki sürüm source'u sessizce 'admin_removed' ile eziyordu; is_active geri açılsa bile
-- işletmenin önceki source değeri (ör. google_maps/owner/manual) hiçbir yerde kalmıyordu.
-- Bu sürüm UPDATE'ten önce source'u okuyup log_admin_action_v1 meta'sına previous_source olarak yazar.

CREATE OR REPLACE FUNCTION public.admin_soft_delete_business_v1(p_business_id uuid, p_admin_note text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_source text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT source INTO v_old_source FROM public.businesses WHERE id = p_business_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.businesses
  SET is_active = false,
      source = 'admin_removed'
  WHERE id = p_business_id;

  PERFORM public.log_admin_action_v1(
    'business.soft_delete',
    'businesses',
    p_business_id,
    jsonb_build_object('note', p_admin_note, 'previous_source', v_old_source)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_business_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.admin_soft_delete_business_v1 IS
  'Admin: işletmeyi güvenli şekilde kaldırır (is_active=false, source=admin_removed) — geri alınabilir (is_active geri açılabilir), denetim kaydı log_admin_action_v1 üzerinden düşer ve eski source değeri previous_source olarak meta''ya yazılır. Merge''den farkı: hedef bir "birincil" işletme gerektirmez, tek başına kullanılabilir. Called by: app/yonetici/isletmeler/isletme-duzenle-modal.tsx.';
