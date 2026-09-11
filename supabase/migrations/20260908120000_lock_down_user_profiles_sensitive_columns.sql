-- P0: public.user_profiles.profiles_read policy'si USING(true) ve anon+authenticated
-- tabloya blanket SELECT grant'li olduğu için hassas kolonlar (birth_date, gender,
-- phone, city, district, social_links, marketing_email_opt_in/opted_in_at,
-- shadow_banned, referral_code) kimliksiz bir anon-key isteğiyle bile toplu
-- okunabiliyordu — canlıda 2026-09-08'de doğrulandı.
--
-- RLS satır bazlı çalışıyor, kolon bazlı değil; policy'yi "sahip veya admin" olarak
-- daraltmak, display_name/avatar_url/bio/is_gourmet gibi GÜVENLİ kolonları başka
-- kullanıcılar için okuyan ~15 meşru çağrı noktasını (liderlik tablosu, yorum
-- yazarları, ekip listesi) kırardı. Bunun yerine kolon bazlı REVOKE kullanılıyor:
-- güvenli kolonlar herkese açık kalıyor, hassas kolonlar yalnızca üç yeni
-- SECURITY DEFINER RPC üzerinden (kendi profili / admin / işletme ekibi) okunabiliyor.

REVOKE SELECT (
  birth_date, gender, phone, city, district, social_links,
  marketing_email_opt_in, marketing_email_opted_in_at, shadow_banned, referral_code
) ON public.user_profiles FROM anon, authenticated;

-- Kendi profilinin hassas alanlarını okumak için (mobil profil ekranı, web
-- ayarlar/sosyal-hesaplar/bildirim-ayarları/abonelik-iptal sayfaları).
CREATE OR REPLACE FUNCTION public.get_my_profile_private_v1()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.user_profiles;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  SELECT * INTO v_row FROM public.user_profiles WHERE user_id = auth.uid();
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', true, 'profile', NULL);
  END IF;

  RETURN jsonb_build_object('ok', true, 'profile', jsonb_build_object(
    'user_id', v_row.user_id,
    'display_name', v_row.display_name,
    'avatar_url', v_row.avatar_url,
    'bio', v_row.bio,
    'is_gourmet', v_row.is_gourmet,
    'birth_date', v_row.birth_date,
    'gender', v_row.gender,
    'phone', v_row.phone,
    'city', v_row.city,
    'district', v_row.district,
    'social_links', v_row.social_links,
    'language_code', v_row.language_code,
    'marketing_email_opt_in', v_row.marketing_email_opt_in,
    'marketing_email_opted_in_at', v_row.marketing_email_opted_in_at,
    'referral_code', v_row.referral_code,
    'shadow_banned', v_row.shadow_banned,
    'owner_onboarding_redirected_at', v_row.owner_onboarding_redirected_at,
    'created_at', v_row.created_at
  ));
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_my_profile_private_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_my_profile_private_v1() FROM anon;

-- Admin panelinin birden fazla kullanıcının hassas alanlarını (telefon/şehir/
-- shadow_banned/referral_code) listelemesi için (yonetici/kullanicilar, arama).
CREATE OR REPLACE FUNCTION public.admin_list_user_profiles_private_v1(p_user_ids uuid[])
 RETURNS TABLE (user_id uuid, phone text, city text, district text, shadow_banned boolean, referral_code text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_admin' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT up.user_id, up.phone, up.city, up.district, up.shadow_banned, up.referral_code
  FROM public.user_profiles up
  WHERE up.user_id = ANY(p_user_ids);
END;
$function$;

GRANT EXECUTE ON FUNCTION public.admin_list_user_profiles_private_v1(uuid[]) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_user_profiles_private_v1(uuid[]) FROM anon;

-- İşletme sahibinin/yöneticisinin ekip sayfasında ekip üyelerinin telefonunu
-- görmesi için — yalnızca gerçekten yönetebildiği işletmenin aktif üyeleri.
CREATE OR REPLACE FUNCTION public.owner_list_team_member_contacts_v1(p_business_id uuid)
 RETURNS TABLE (user_id uuid, phone text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'team_manage') THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT up.user_id, up.phone
  FROM public.user_profiles up
  JOIN public.business_team_memberships btm ON btm.user_id = up.user_id
  WHERE btm.business_id = p_business_id AND btm.revoked_at IS NULL;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.owner_list_team_member_contacts_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_list_team_member_contacts_v1(uuid) FROM anon;
