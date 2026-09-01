-- IMMUTABLE -> STABLE düzeltmesi: fonksiyon artık bir tabloyu okuyor, sonucu
-- sadece girdilere bağlı değil (tablo değişirse sonuç değişebilir).
CREATE OR REPLACE FUNCTION public.contains_obfuscated_profanity_v1(p_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
begin
  if v_norm ~* '(^| )a\s*m\s*k( |$)' then
    return true;
  end if;

  if v_compact ~* '(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)' then
    return true;
  end if;

  if exists (
    select 1
    from public.moderation_blacklist_terms t
    where t.is_active
      and v_compact like '%' || replace(public.normalize_for_moderation_v1(t.term), ' ', '') || '%'
  ) then
    return true;
  end if;

  return false;
end;
$function$;

COMMENT ON FUNCTION public.contains_obfuscated_profanity_v1 IS
  'Küfür/argo tespiti: hardcoded regex kalıpları + moderation_blacklist_terms tablosu. '
  'STABLE (tablo okuyor, IMMUTABLE değil). Called by: submit_review_v1/v2/v3, '
  'submit_menu_item_price_suggestion_v2.';

CREATE OR REPLACE FUNCTION public.get_moderation_blacklist_terms_v1()
RETURNS TABLE (term text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.term FROM public.moderation_blacklist_terms t WHERE t.is_active ORDER BY t.term;
$$;

REVOKE ALL ON FUNCTION public.get_moderation_blacklist_terms_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_moderation_blacklist_terms_v1() TO anon;
GRANT EXECUTE ON FUNCTION public.get_moderation_blacklist_terms_v1() TO authenticated;
COMMENT ON FUNCTION public.get_moderation_blacklist_terms_v1 IS
  'Kara liste terimlerini döner — mobil/web istemci taraflı anlık ön-kontrol için. '
  'Anon dahil herkese açık (terimlerin kendisi zaten mobil app bundle''ında herkese açıktı). '
  'Called by: uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart, '
  'uygulamalar/web/src/lib/moderasyon/kara-liste-on-kontrol.ts.';
