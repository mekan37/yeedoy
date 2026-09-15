-- B28 (mobil production-readiness denetimi): submit_menu_item_suggestion_v2
-- p_menu_item_id'nin gerçekten p_business_id'ye ait olduğunu hiç
-- doğrulamıyordu — kimliği doğrulanmış herhangi bir kullanıcı, kendi
-- işletmesinden alakasız bir menu_item_id ile başka bir işletmenin
-- öneri/moderasyon kuyruğuna karışık/sahte kayıt enjekte edebiliyordu
-- (cross-tenant öneri enjeksiyonu).
CREATE OR REPLACE FUNCTION "public"."submit_menu_item_suggestion_v2"("p_business_id" "uuid", "p_menu_item_id" "uuid", "p_action" "text", "p_payload" "jsonb", "p_idempotency_key" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid := auth.uid();
  v_action text := nullif(trim(public.sanitize_plain_text_v1(p_action)), '');
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_suggestion_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_action is null then
    return jsonb_build_object('ok', false, 'error', 'action_required');
  end if;

  if p_menu_item_id is not null and not exists (
    select 1
    from public.menu_items mi
    join public.menu_sections ms on ms.id = mi.section_id
    join public.menus m on m.id = ms.menu_id
    where mi.id = p_menu_item_id
      and m.business_id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'error', 'menu_item_business_mismatch');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_menu_item_suggestion_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_menu_item_suggestion_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  insert into public.menu_item_suggestions(
    business_id,
    menu_item_id,
    action,
    payload,
    created_by
  )
  values (
    p_business_id,
    p_menu_item_id,
    v_action,
    v_payload,
    v_user_id
  )
  returning id into v_suggestion_id;

  v_response := jsonb_build_object(
    'ok', true,
    'suggestion_id', v_suggestion_id
  );

  if v_idempotency_key is not null then
    insert into public.client_mutation_idempotency_keys(
      user_id,
      action,
      idempotency_key,
      response,
      resource_type,
      resource_id
    )
    values (
      v_user_id,
      'submit_menu_item_suggestion_v2',
      v_idempotency_key,
      v_response,
      'menu_item_suggestion',
      v_suggestion_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;
