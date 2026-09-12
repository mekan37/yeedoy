-- P0: Admin panelindeki üç yıkıcı işlem (kullanıcı ban/temizle, fotoğraf
-- moderasyonu, DSAR durum güncelleme) doğrudan tablo UPDATE'i ile yapılıyordu.
-- user_profiles/business_media/privacy_requests tablolarının hiçbirinde admin
-- için bir UPDATE RLS policy'si yok (yalnızca *_own policy'leri var) — bu
-- yüzden PostgREST 0 satır güncelliyor, error null dönüyor, route handler'lar
-- "ok:true" ile başarı bildiriyordu ama DB'de hiçbir şey değişmiyordu.
--
-- Bu üç RPC, is_admin() kontrolü yapıp GET DIAGNOSTICS ile GERÇEK etkilenen
-- satır sayısını döndürüyor — route handler'lar artık bu sayıyı istenen
-- sayıyla karşılaştırıp gerçek başarı/kısmi başarı ayrımı yapabiliyor.

CREATE OR REPLACE FUNCTION public.admin_set_shadow_banned_v1(
  p_user_ids uuid[],
  p_banned boolean
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_admin' USING ERRCODE = '42501';
  END IF;

  UPDATE public.user_profiles
  SET shadow_banned = p_banned
  WHERE user_id = ANY(p_user_ids);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.admin_set_shadow_banned_v1(uuid[], boolean) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_shadow_banned_v1(uuid[], boolean) FROM anon;


CREATE OR REPLACE FUNCTION public.admin_moderate_business_media_v1(
  p_photo_id uuid,
  p_status text,
  p_is_hidden boolean,
  p_moderation_note text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_admin' USING ERRCODE = '42501';
  END IF;

  UPDATE public.business_media
  SET status = p_status,
      is_hidden = p_is_hidden,
      moderation_note = p_moderation_note
  WHERE id = p_photo_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.admin_moderate_business_media_v1(uuid, text, boolean, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_moderate_business_media_v1(uuid, text, boolean, text) FROM anon;


CREATE OR REPLACE FUNCTION public.admin_update_privacy_request_status_v1(
  p_id uuid,
  p_status text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_admin' USING ERRCODE = '42501';
  END IF;

  IF p_status NOT IN ('in_review', 'resolved', 'rejected') THEN
    RAISE EXCEPTION 'invalid_status' USING ERRCODE = '22023';
  END IF;

  UPDATE public.privacy_requests
  SET status = p_status,
      resolved_at = CASE WHEN p_status IN ('resolved', 'rejected') THEN now() ELSE NULL END
  WHERE id = p_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.admin_update_privacy_request_status_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_update_privacy_request_status_v1(uuid, text) FROM anon;
