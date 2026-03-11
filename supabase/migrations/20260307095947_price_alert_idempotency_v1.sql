begin;

create or replace function public.create_price_alert_v2(
  p_query text,
  p_max_price_cents integer,
  p_city text default null,
  p_district text default null,
  p_currency text default 'TRY',
  p_category text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_query text := trim(coalesce(p_query, ''));
  v_currency text := coalesce(nullif(trim(coalesce(p_currency, '')), ''), 'TRY');
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_alert_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_query = '' then
    return jsonb_build_object('ok', false, 'error', 'query_required');
  end if;

  if coalesce(p_max_price_cents, 0) <= 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_max_price');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('create_price_alert_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'create_price_alert_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  insert into public.price_alerts(
    user_id,
    city,
    district,
    query,
    max_price_cents,
    currency,
    category,
    is_active
  )
  values (
    v_user_id,
    p_city,
    p_district,
    v_query,
    p_max_price_cents,
    v_currency,
    p_category,
    true
  )
  returning id into v_alert_id;

  v_response := jsonb_build_object('ok', true, 'id', v_alert_id);

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
      'create_price_alert_v2',
      v_idempotency_key,
      v_response,
      'price_alert',
      v_alert_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.create_price_alert_v2(
  text,
  integer,
  text,
  text,
  text,
  text,
  text
) to anon;

grant all on function public.create_price_alert_v2(
  text,
  integer,
  text,
  text,
  text,
  text,
  text
) to authenticated;

grant all on function public.create_price_alert_v2(
  text,
  integer,
  text,
  text,
  text,
  text,
  text
) to service_role;

commit;;
