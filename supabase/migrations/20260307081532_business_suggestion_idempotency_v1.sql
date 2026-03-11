begin;

create or replace function public.submit_business_suggestion_v2(
  p_name text,
  p_category text,
  p_city text default null,
  p_district text default null,
  p_address text default null,
  p_phone text default null,
  p_website text default null,
  p_notes text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := nullif(trim(public.sanitize_plain_text_v1(p_name)), '');
  v_category text := nullif(trim(public.sanitize_plain_text_v1(p_category)), '');
  v_city text := nullif(trim(public.sanitize_plain_text_v1(p_city)), '');
  v_district text := nullif(trim(public.sanitize_plain_text_v1(p_district)), '');
  v_address text := nullif(trim(public.sanitize_plain_text_v1(p_address)), '');
  v_phone text := nullif(trim(public.sanitize_plain_text_v1(p_phone)), '');
  v_website text := nullif(trim(public.sanitize_plain_text_v1(p_website)), '');
  v_notes text := nullif(trim(public.sanitize_plain_text_v1(p_notes)), '');
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_suggestion_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', true, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_business_suggestion_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_business_suggestion_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if v_name is null then
    return jsonb_build_object('ok', false, 'error', 'name_required');
  end if;

  if v_category is null then
    return jsonb_build_object('ok', false, 'error', 'category_required');
  end if;

  insert into public.business_suggestions(
    user_id,
    name,
    category,
    city,
    district,
    address,
    phone,
    website,
    notes,
    status
  )
  values (
    v_user_id,
    v_name,
    v_category,
    v_city,
    v_district,
    v_address,
    v_phone,
    v_website,
    v_notes,
    'pending'
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
      'submit_business_suggestion_v2',
      v_idempotency_key,
      v_response,
      'business_suggestion',
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

grant all on function public.submit_business_suggestion_v2(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) to anon;

grant all on function public.submit_business_suggestion_v2(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) to authenticated;

grant all on function public.submit_business_suggestion_v2(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) to service_role;

commit;;
