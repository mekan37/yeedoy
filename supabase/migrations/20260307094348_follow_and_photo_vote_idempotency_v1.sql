begin;

create or replace function public.set_follow_v2(
  p_followee_id uuid,
  p_following boolean,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_following boolean := coalesce(p_following, false);
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_current boolean;
  v_legacy jsonb;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_followee_id is null then
    return jsonb_build_object('ok', false, 'error', 'followee_required');
  end if;

  if p_followee_id = v_user_id then
    return jsonb_build_object('ok', false, 'error', 'cannot_follow_self');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('set_follow_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'set_follow_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  select exists(
    select 1
    from public.user_follows
    where follower_id = v_user_id
      and followee_id = p_followee_id
  )
  into v_current;

  if v_current = v_following then
    v_response := jsonb_build_object(
      'ok', true,
      'following', v_following,
      'mode', 'noop'
    );
  else
    v_legacy := public.toggle_follow_v1(p_followee_id);
    if coalesce((v_legacy ->> 'ok')::boolean, false) is false then
      return v_legacy;
    end if;
    v_response := jsonb_build_object(
      'ok', true,
      'following', coalesce((v_legacy ->> 'following')::boolean, v_following),
      'mode', case when v_following then 'insert' else 'remove' end
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
      'set_follow_v2',
      v_idempotency_key,
      v_response,
      'user_follow',
      p_followee_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.set_follow_v2(
  uuid,
  boolean,
  text
) to anon;

grant all on function public.set_follow_v2(
  uuid,
  boolean,
  text
) to authenticated;

grant all on function public.set_follow_v2(
  uuid,
  boolean,
  text
) to service_role;

create or replace function public.set_menu_item_photo_vote_v2(
  p_photo_id uuid,
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
  v_legacy jsonb;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'photo_required');
  end if;

  if p_vote not in (-1, 0, 1) then
    return jsonb_build_object('ok', false, 'error', 'bad_vote');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('set_menu_item_photo_vote_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'set_menu_item_photo_vote_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  select vote
    into v_prev
  from public.menu_item_photo_votes
  where photo_id = p_photo_id
    and user_id = v_user_id;

  if p_vote = 0 then
    if v_prev is null then
      v_response := jsonb_build_object('ok', true, 'mode', 'noop', 'vote', 0);
    else
      v_legacy := public.vote_menu_item_photo_v1(p_photo_id, v_prev);
      if coalesce((v_legacy ->> 'ok')::boolean, false) is false then
        return v_legacy;
      end if;
      v_response := jsonb_build_object('ok', true, 'mode', 'remove', 'vote', 0);
    end if;
  elsif v_prev = p_vote then
    v_response := jsonb_build_object('ok', true, 'mode', 'noop', 'vote', p_vote);
  else
    v_legacy := public.vote_menu_item_photo_v1(p_photo_id, p_vote);
    if coalesce((v_legacy ->> 'ok')::boolean, false) is false then
      return v_legacy;
    end if;
    v_response := jsonb_build_object(
      'ok', true,
      'mode', case when v_prev is null then 'insert' else 'switch' end,
      'vote', p_vote
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
      'set_menu_item_photo_vote_v2',
      v_idempotency_key,
      v_response,
      'menu_item_photo_vote',
      p_photo_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.set_menu_item_photo_vote_v2(
  uuid,
  smallint,
  text
) to anon;

grant all on function public.set_menu_item_photo_vote_v2(
  uuid,
  smallint,
  text
) to authenticated;

grant all on function public.set_menu_item_photo_vote_v2(
  uuid,
  smallint,
  text
) to service_role;

commit;;
