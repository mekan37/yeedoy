begin;

create or replace function public.submit_menu_item_suggestion_v2(
  p_business_id uuid,
  p_menu_item_id uuid,
  p_action text,
  p_payload jsonb,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

grant all on function public.submit_menu_item_suggestion_v2(
  uuid,
  uuid,
  text,
  jsonb,
  text
) to anon;

grant all on function public.submit_menu_item_suggestion_v2(
  uuid,
  uuid,
  text,
  jsonb,
  text
) to authenticated;

grant all on function public.submit_menu_item_suggestion_v2(
  uuid,
  uuid,
  text,
  jsonb,
  text
) to service_role;

create or replace function public.submit_menu_item_price_suggestion_v5(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now(),
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_suggestion_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_menu_item_price_suggestion_v5'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_menu_item_price_suggestion_v5'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  v_response := public.submit_menu_item_price_suggestion_v4(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url,
    p_client_id,
    p_captured_at
  );

  if coalesce((v_response->>'ok')::boolean, false) is false then
    return v_response;
  end if;

  v_suggestion_id := case
    when nullif(v_response->>'suggestion_id', '') is null then null
    else (v_response->>'suggestion_id')::uuid
  end;

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
      'submit_menu_item_price_suggestion_v5',
      v_idempotency_key,
      v_response,
      'menu_price_suggestion',
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

grant all on function public.submit_menu_item_price_suggestion_v5(
  uuid,
  integer,
  text,
  text,
  text,
  text,
  timestamptz,
  text
) to anon;

grant all on function public.submit_menu_item_price_suggestion_v5(
  uuid,
  integer,
  text,
  text,
  text,
  text,
  timestamptz,
  text
) to authenticated;

grant all on function public.submit_menu_item_price_suggestion_v5(
  uuid,
  integer,
  text,
  text,
  text,
  text,
  timestamptz,
  text
) to service_role;

commit;;
