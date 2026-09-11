-- P1: add_business_media_v1 yalnızca "giriş yapmış mı" kontrol ediyordu,
-- p_business_id sahipliğini/yetkisini hiç doğrulamıyordu. Silme route'u
-- (app/sunucu/sahip/fotograflar/route.ts) canManageBusiness() ile business_id
-- yetkisini kontrol ediyor ama silinecek Storage nesnesini kaydın kendi
-- url'inden türetiyor — bu ikisi birleşince, kendi işletmesine sahip bir
-- saldırgan kendi business_id'si + kurbanın public logo/kapak URL'siyle sahte
-- bir business_media satırı ekleyip ardından "kendi" kaydını silerek kurbanın
-- gerçek Storage nesnesini service-role yetkisiyle sildirebiliyordu.
-- Delete route'unun kullandığı aynı yetki seviyesiyle (menu_write /
-- can_manage_business_v1) kilitleniyor.
CREATE OR REPLACE FUNCTION "public"."add_business_media_v1"("p_business_id" "uuid", "p_url" "text", "p_url_large" "text" DEFAULT NULL::"text", "p_url_thumb" "text" DEFAULT NULL::"text", "p_provider" "text" DEFAULT 'wp'::"text", "p_kind" "text" DEFAULT 'venue'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  if not (public.is_admin() or public.can_manage_business_v1(p_business_id)) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  v_rate := public.consume_rate_limit_v1('business_media', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'business_media_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.business_media(
    business_id, kind, url, url_large, url_thumb, provider, created_by, is_shadow
  ) values (
    p_business_id, coalesce(p_kind, 'venue'), p_url, p_url_large, p_url_thumb, p_provider, auth.uid(), v_shadow
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$$;
