-- Bug: ensure_my_profile_v1'de UPDATE dalı, "display_name gönderilmemişse mevcut
-- ismi koru" niyetiyle COALESCE(excluded.display_name, ...) kullanıyordu. Ancak
-- excluded.display_name asla NULL olmuyordu (v_name p_display_name NULL ise
-- 'Kullanıcı' fallback'ine düşüyordu) — bu yüzden COALESCE her zaman
-- excluded.display_name'i seçiyor, p_display_name gönderilmeyen her çağrı
-- (örn. mobil updateCity()) mevcut kullanıcının gerçek adını sessizce
-- "Kullanıcı" ile eziyordu.
--
-- Fix: UPDATE dalında v_name yerine doğrudan p_display_name'in normalize
-- edilmiş halini kullan — bu gerçekten NULL olabilir, avatar_url/city
-- kolonlarındaki "gönderilmemişse mevcut değeri koru" davranışıyla tutarlı hale gelir.
CREATE OR REPLACE FUNCTION public.ensure_my_profile_v1(p_display_name text DEFAULT NULL::text, p_avatar_url text DEFAULT NULL::text, p_city text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  v_name := nullif(trim(coalesce(p_display_name,'')), '');
  IF v_name IS NULL THEN
    v_name := 'Kullanıcı';
  END IF;

  INSERT INTO public.user_profiles(user_id, display_name, avatar_url, city)
  VALUES (auth.uid(), v_name, p_avatar_url, nullif(trim(coalesce(p_city, '')), ''))
  ON CONFLICT (user_id) DO UPDATE
    SET display_name = COALESCE(nullif(trim(coalesce(p_display_name, '')), ''), public.user_profiles.display_name),
        avatar_url = COALESCE(excluded.avatar_url, public.user_profiles.avatar_url),
        city = COALESCE(nullif(trim(coalesce(p_city, '')), ''), public.user_profiles.city),
        updated_at = now();

  RETURN jsonb_build_object('ok', true);
END;
$function$
;
