-- P3: admin_bulk_replace_url_prefix_v1, p_from_prefix'i doğrudan regexp_replace
-- pattern'i olarak kullanıyordu — niyet düz bir "prefix değiştir" işlemiyken,
-- admin girdisi aslında keyfi bir regex olarak yorumlanıyordu (ReDoS riski,
-- ayrıca beklenmedik regex meta-karakter davranışı). substring/concat ile
-- gerçek prefix-replace semantiğine çevrildi — artık regex motoru hiç devreye
-- girmiyor.
CREATE OR REPLACE FUNCTION public.admin_bulk_replace_url_prefix_v1(p_field text, p_from_prefix text, p_to_prefix text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_count int;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  if p_field not in ('logo_url','cover_url') then
    return jsonb_build_object('ok', false, 'error', 'bad_field');
  end if;
  if coalesce(p_from_prefix, '') = '' then
    return jsonb_build_object('ok', false, 'error', 'empty_prefix');
  end if;

  execute format(
    'update public.businesses set %I = $2 || substring(%I from (length($1) + 1)) where %I like ($1 || ''%%'')',
    p_field, p_field, p_field
  )
  using p_from_prefix, p_to_prefix;

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'business.bulk_replace_url_prefix',
    'businesses',
    null,
    jsonb_build_object('field', p_field, 'from', p_from_prefix, 'to', p_to_prefix, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$;
