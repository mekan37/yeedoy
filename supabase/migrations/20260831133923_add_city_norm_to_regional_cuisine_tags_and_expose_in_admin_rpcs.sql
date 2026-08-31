-- Bug (final code review, Faz 1): admin panelinin "işletmeye etiket ata" ekranı
-- işletme ile etiketi ham businesses.city metniyle eşleştiriyordu (t.city ===
-- selectedBusiness.city), oysa check_regional_recommendation_v1 zaten
-- normalize_tr_location_text()/city_norm kullanıyor. Ham city yazımındaki en
-- ufak fark (büyük/küçük harf, boşluk, eski import varyantı) admin'e "bu şehir
-- için etiket yok" gösterip gerçekte eşleşecek bir etiketi gizleyebiliyordu.
-- Fix: regional_cuisine_tags'e de aynı normalize deseni eklenip her iki admin
-- RPC'si city_norm döndürüyor; client artık city_norm ile eşleştiriyor.

ALTER TABLE public.regional_cuisine_tags
  ADD COLUMN city_norm text GENERATED ALWAYS AS (public.normalize_tr_location_text(city)) STORED;

CREATE INDEX regional_cuisine_tags_city_norm_idx ON public.regional_cuisine_tags (city_norm);

DROP FUNCTION public.admin_list_regional_cuisine_tags_v1();

CREATE FUNCTION public.admin_list_regional_cuisine_tags_v1()
 RETURNS TABLE(id uuid, city text, city_norm text, label text, business_count bigint, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT t.id, t.city, t.city_norm, t.label,
           (SELECT count(*) FROM public.businesses b WHERE b.regional_tag_id = t.id),
           t.created_at
    FROM public.regional_cuisine_tags t
    ORDER BY t.city, t.label;
END;
$function$
;

DROP FUNCTION public.admin_search_businesses_for_tagging_v1(text);

CREATE FUNCTION public.admin_search_businesses_for_tagging_v1(p_query text)
 RETURNS TABLE(id uuid, name text, city text, city_norm text, current_tag_label text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_query IS NULL OR trim(p_query) = '' THEN
    RETURN;
  END IF;
  RETURN QUERY
    SELECT b.id, b.name, b.city, b.city_norm, t.label
    FROM public.businesses b
    LEFT JOIN public.regional_cuisine_tags t ON t.id = b.regional_tag_id
    WHERE b.name ILIKE '%' || trim(p_query) || '%'
    ORDER BY b.name
    LIMIT 20;
END;
$function$
;

REVOKE ALL ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM anon;

REVOKE ALL ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM anon;
