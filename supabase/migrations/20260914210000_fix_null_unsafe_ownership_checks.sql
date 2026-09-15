-- Canlı Supabase Güvenlik & Bütünlük Denetimi P0-4: delete_review_reply,
-- close_group_request_v1, accept_group_offer_v1 sahiplik kontrolünde
-- `<>` kullanıyordu. PL/pgSQL'de `x <> NULL` NULL döner (falsy) — auth.uid()
-- NULL olduğunda (anon çağrı) `IF v_owner <> auth.uid() THEN ...` bloğu hiç
-- girilmiyor, "not_authorized" reddi sessizce atlanıyor ve fonksiyon
-- imtiyazlı işlemi (silme/kapatma/onaylama) yürütüyor.
--
-- Üçü de SECURITY DEFINER + anon EXECUTE grant'li olduğu için canlıda
-- gerçekten istismar edilebilir doğrulandı (pg_proc.proacl'dan): kimliksiz
-- bir istek herhangi bir işletmenin review yanıtını silebiliyor, herhangi
-- bir grup talebini kapatabiliyor, herhangi bir grup teklifini kabul edip
-- talebi "awarded" yapabiliyordu. `IS DISTINCT FROM` NULL'ı güvenli
-- karşılaştırır (`x IS DISTINCT FROM NULL` = true when x is not null),
-- böylece anon/oturumsuz çağrılarda guard doğru şekilde reddediyor.
create or replace function public.delete_review_reply(p_review_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_reply_owner uuid;
begin
  select owner_user_id into v_reply_owner
  from public.review_replies
  where review_id = p_review_id;

  if v_reply_owner is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_reply_owner is distinct from auth.uid() then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  delete from public.review_replies where review_id = p_review_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.close_group_request_v1(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_owner uuid;
begin
  select created_by into v_owner from public.group_requests where id = p_request_id;
  if v_owner is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_owner is distinct from auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'closed'
    where id = p_request_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.accept_group_offer_v1(p_offer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_request_id uuid;
  v_request_owner uuid;
begin
  select o.request_id, r.created_by
  into v_request_id, v_request_owner
  from public.group_offers o
  join public.group_requests r on r.id = o.request_id
  where o.id = p_offer_id;

  if v_request_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_request_owner is distinct from auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'awarded'
    where id = v_request_id;

  update public.group_offers
    set status = case when id = p_offer_id then 'accepted' else 'rejected' end
    where request_id = v_request_id
      and status in ('submitted','accepted');

  return jsonb_build_object('ok', true);
end;
$function$;
