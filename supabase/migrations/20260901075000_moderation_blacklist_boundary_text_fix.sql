CREATE OR REPLACE FUNCTION public.contains_obfuscated_profanity_v1(p_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
  -- Kısa terim kelime-sınırı kontrolü için: normalize_for_moderation_v1'in leetspeak
  -- dönüşümünü (!,$,rakamlar -> harf) UYGULAMAYAN ayrı bir metin. Amaç: "bok!" gibi
  -- girdilerde "!" harfe dönüşüp sınırı yok etmesin (v_norm'da "boki" olurdu, sınır kaybolurdu).
  v_boundary_text text := regexp_replace(
    translate(lower(coalesce(p_text, '')), 'çğıöşü', 'cgiosu'),
    '[^a-z0-9]+', ' ', 'g'
  );
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
      and length(public.normalize_for_moderation_v1(t.term)) >= 4
      and v_compact like '%' || replace(public.normalize_for_moderation_v1(t.term), ' ', '') || '%'
  ) then
    return true;
  end if;

  if exists (
    select 1
    from public.moderation_blacklist_terms t
    where t.is_active
      and length(public.normalize_for_moderation_v1(t.term)) between 1 and 3
      and v_boundary_text ~ ('(^|[^a-z0-9])' || public.normalize_for_moderation_v1(t.term) || '($|[^a-z0-9])')
  ) then
    return true;
  end if;

  return false;
end;
$function$;

COMMENT ON FUNCTION public.contains_obfuscated_profanity_v1 IS
  'Küfür/argo tespiti: hardcoded regex kalıpları + moderation_blacklist_terms tablosu. '
  'STABLE (tablo okuyor, IMMUTABLE değil). Uzun terimler (>=4 char) substring, '
  'kısa terimler (<=3 char) kelime-sınırı eşleşmesi kullanır — sınır kontrolü, '
  'leetspeak dönüşümü UYGULANMAMIŞ ayrı bir metin (v_boundary_text) üzerinde çalışır, '
  'böylece "bok!" gibi noktalama-bitişik girdilerde "!" harfe dönüşüp sınırı yutmaz '
  '(20260901075000). Called by: submit_review_v1/v2/v3, submit_menu_item_price_suggestion_v2.';
