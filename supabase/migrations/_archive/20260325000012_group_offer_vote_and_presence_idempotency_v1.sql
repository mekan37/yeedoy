begin;

create or replace function public.set_group_offer_vote_v2(
  p_offer_id uuid,
  p_voted boolean,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_voted boolean := coalesce(p_voted, false);
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_current smallint;
  v_legacy jsonb;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'unauthorized');
  end if;

  if p_offer_id is null then
    return jsonb_build_object('ok', false, 'error', 'offer_required');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('set_group_offer_vote_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'set_group_offer_vote_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  select vote
    into v_current
  from public.group_offer_votes
  where offer_id = p_offer_id
    and user_id = v_user_id;

  if ((v_current = 1) is true) = v_voted then
    v_response := jsonb_build_object(
      'ok', true,
      'vote', case when v_voted then 1 else 0 end,
      'mode', 'noop'
    );
  else
    v_legacy := public.vote_group_offer_v1(p_offer_id);
    if coalesce((v_legacy ->> 'ok')::boolean, false) is false then
      return v_legacy;
    end if;
    v_response := jsonb_build_object(
      'ok', true,
      'vote', case when v_voted then 1 else 0 end,
      'mode', case when v_voted then 'insert' else 'remove' end
    );
  end if;

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
      'set_group_offer_vote_v2',
      v_idempotency_key,
      v_response,
      'group_offer_vote',
      p_offer_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.set_group_offer_vote_v2(
  uuid,
  boolean,
  text
) to anon;

grant all on function public.set_group_offer_vote_v2(
  uuid,
  boolean,
  text
) to authenticated;

grant all on function public.set_group_offer_vote_v2(
  uuid,
  boolean,
  text
) to service_role;

create or replace function public.submit_presence_v2(
  p_business_id uuid,
  p_crowd text,
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
  v_last timestamptz;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_crowd not in ('quiet','normal','busy') then
    return jsonb_build_object('ok', false, 'error', 'bad_crowd');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_presence_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_presence_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  select max(created_at)
    into v_last
  from public.business_presence_events
  where business_id = p_business_id
    and user_id = v_user_id;

  if v_last is not null and v_last > now() - interval '15 minutes' then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_15m');
  end if;

  insert into public.business_presence_events(business_id, user_id, crowd)
  values (p_business_id, v_user_id, p_crowd::public.crowd_level);

  v_response := jsonb_build_object(
    'ok', true,
    'crowd', p_crowd,
    'mode', 'insert'
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
      'submit_presence_v2',
      v_idempotency_key,
      v_response,
      'business_presence',
      p_business_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.submit_presence_v2(
  uuid,
  text,
  text
) to anon;

grant all on function public.submit_presence_v2(
  uuid,
  text,
  text
) to authenticated;

grant all on function public.submit_presence_v2(
  uuid,
  text,
  text
) to service_role;

commit;
