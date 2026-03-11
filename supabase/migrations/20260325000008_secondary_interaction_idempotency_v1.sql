begin;

create or replace function public.set_favorite_v2(
  p_business_id uuid,
  p_is_favorited boolean,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_favorited boolean := coalesce(p_is_favorited, false);
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_mode text;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('set_favorite_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'set_favorite_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if v_is_favorited then
    if exists (
      select 1
      from public.favorites
      where user_id = v_user_id
        and business_id = p_business_id
    ) then
      v_mode := 'noop';
    else
      insert into public.favorites(user_id, business_id, created_at)
      values (v_user_id, p_business_id, now())
      on conflict (user_id, business_id) do nothing;
      v_mode := 'insert';
    end if;
  else
    if exists (
      select 1
      from public.favorites
      where user_id = v_user_id
        and business_id = p_business_id
    ) then
      delete from public.favorites
      where user_id = v_user_id
        and business_id = p_business_id;
      v_mode := 'remove';
    else
      v_mode := 'noop';
    end if;
  end if;

  v_response := jsonb_build_object(
    'ok', true,
    'is_favorited', v_is_favorited,
    'mode', v_mode
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
      'set_favorite_v2',
      v_idempotency_key,
      v_response,
      'favorite',
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

grant all on function public.set_favorite_v2(
  uuid,
  boolean,
  text
) to anon;

grant all on function public.set_favorite_v2(
  uuid,
  boolean,
  text
) to authenticated;

grant all on function public.set_favorite_v2(
  uuid,
  boolean,
  text
) to service_role;

create or replace function public.set_menu_item_price_vote_v2(
  p_menu_item_id uuid,
  p_vote smallint,
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
  v_prev smallint;
  v_mode text;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_vote not in (-1, 0, 1) then
    return jsonb_build_object('ok', false, 'error', 'bad_vote');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('set_menu_item_price_vote_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'set_menu_item_price_vote_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  select vote into v_prev
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id
    and user_id = v_user_id;

  if p_vote = 0 then
    if v_prev is null then
      v_mode := 'noop';
    else
      delete from public.menu_item_price_votes
      where menu_item_id = p_menu_item_id
        and user_id = v_user_id;
      v_mode := 'remove';
    end if;
  elsif v_prev is null then
    insert into public.menu_item_price_votes(menu_item_id, user_id, vote)
    values (p_menu_item_id, v_user_id, p_vote);
    v_mode := 'insert';
  elsif v_prev = p_vote then
    v_mode := 'noop';
  else
    update public.menu_item_price_votes
    set vote = p_vote,
        created_at = now()
    where menu_item_id = p_menu_item_id
      and user_id = v_user_id;
    v_mode := 'switch';
  end if;

  v_response := jsonb_build_object(
    'ok', true,
    'vote', p_vote,
    'mode', v_mode
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
      'set_menu_item_price_vote_v2',
      v_idempotency_key,
      v_response,
      'menu_item_price_vote',
      p_menu_item_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.set_menu_item_price_vote_v2(
  uuid,
  smallint,
  text
) to anon;

grant all on function public.set_menu_item_price_vote_v2(
  uuid,
  smallint,
  text
) to authenticated;

grant all on function public.set_menu_item_price_vote_v2(
  uuid,
  smallint,
  text
) to service_role;

commit;
