CREATE OR REPLACE FUNCTION public.contains_obfuscated_profanity_v1(p_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
  -- Kısa terim kelime-sınırı kontrolü için: normalize_for_moderation_v1 ile AYNI
  -- rakam/sembol leetspeak dönüşümünü uygular (0->o, 1->i, 4->a, 5->s, 3->e, @->a)
  -- — "b0k", "s1k", "an4" gibi obfuscation'ı hâlâ yakalasın diye — AMA "!" ve "$"
  -- karakterlerini harfe ÇEVİRMEZ (normalize_for_moderation_v1 bunları i/s yapar),
  -- onun yerine gerçek kelime sınırı olarak bırakır — "bok!" içindeki "!" harfe
  -- dönüşüp sınırı yutmasın diye. "." ve "_" ise normalize_for_moderation_v1 ile
  -- aynı şekilde (boşluğa değil, boşuna) siliniyor — terimlerle tutarlılık için.
  v_boundary_text text := regexp_replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    translate(lower(coalesce(p_text, '')), 'çğıöşü', 'cgiosu'),
                    '@', 'a'
                  ),
                  '4', 'a'
                ),
                '0', 'o'
              ),
              '1', 'i'
            ),
            '5', 's'
          ),
          '3', 'e'
        ),
        '.', ''
      ),
      '_', ''
    ),
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
  'kısa terimler (<=3 char) kelime-sınırı eşleşmesi kullanır — sınır kontrolü, rakam '
  'leetspeak''ini (0/1/4/5/3/@) uygulayan ama "!" ve "$"''i harfe çevirmeyen ayrı bir '
  'metin (v_boundary_text) üzerinde çalışır, böylece "b0k"/"s1k" hâlâ yakalanır ve '
  '"bok!" gibi noktalama-bitişik girdilerde sınır kaybolmaz (20260901075500). '
  'Called by: submit_review_v1/v2/v3, submit_menu_item_price_suggestion_v2.';
