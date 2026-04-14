begin;

create table if not exists public.client_mutation_idempotency_keys (
  user_id uuid not null,
  action text not null,
  idempotency_key text not null,
  response jsonb not null,
  resource_type text null,
  resource_id uuid null,
  created_at timestamptz not null default now(),
  primary key (user_id, action, idempotency_key)
);

create index if not exists client_mutation_idempotency_keys_created_idx
  on public.client_mutation_idempotency_keys (created_at desc);

create index if not exists client_mutation_idempotency_keys_action_created_idx
  on public.client_mutation_idempotency_keys (action, created_at desc);

revoke all on public.client_mutation_idempotency_keys from anon, authenticated;
grant select, insert, update, delete on public.client_mutation_idempotency_keys to service_role;

create or replace function public.submit_review_v2(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null,
  p_idempotency_key text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := public.sanitize_plain_text_v1(p_content);
  v_title text := nullif(public.sanitize_plain_text_v1(p_title), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
  v_has_contact boolean := false;
  v_has_profanity boolean := false;
  v_status text := 'approved';
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_review_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_review_v2'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_review_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_has_contact := public.contains_contact_or_url_v1(coalesce(p_content, ''))
    or public.contains_contact_or_url_v1(v_content);

  v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
    or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

  if v_has_contact then
    v_content := public.mask_contact_tokens_v1(v_content);
    v_title := nullif(public.mask_contact_tokens_v1(coalesce(v_title, '')), '');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();
  v_status := case
    when v_shadow or v_has_contact or v_has_profanity then 'pending'
    else 'approved'
  end;

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content, v_status
  )
  returning id into v_review_id;

  v_response := jsonb_build_object(
    'ok', true,
    'review_id', v_review_id,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity
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
      'submit_review_v2',
      v_idempotency_key,
      v_response,
      'review',
      v_review_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.submit_review_v2(uuid, integer, text, text, text) to anon;
grant all on function public.submit_review_v2(uuid, integer, text, text, text) to authenticated;
grant all on function public.submit_review_v2(uuid, integer, text, text, text) to service_role;

create or replace function public.submit_report_v2(
  p_business_id uuid default null,
  p_review_id uuid default null,
  p_menu_item_photo_id uuid default null,
  p_reason text default 'other',
  p_details text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
  v_target_type text;
  v_target_id uuid;
  v_business_id uuid;
  v_review_id uuid;
  v_photo_id uuid;
  v_reason text := coalesce(nullif(public.sanitize_plain_text_v1(p_reason), ''), 'other');
  v_details text := nullif(public.sanitize_plain_text_v1(p_details), '');
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_report_v2'),
      hashtext(v_uid::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_uid
      and k.action = 'submit_report_v2'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if p_business_id is null and p_review_id is null and p_menu_item_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  if p_menu_item_photo_id is not null then
    v_target_type := 'menu_item_photo';
    v_target_id := p_menu_item_photo_id;
    v_photo_id := p_menu_item_photo_id;
    select business_id into v_business_id
    from public.menu_item_photos
    where id = p_menu_item_photo_id;
    if v_business_id is null then
      return jsonb_build_object('ok', false, 'error', 'photo_not_found');
    end if;
  elsif p_review_id is not null then
    v_target_type := 'review';
    v_target_id := p_review_id;
    v_review_id := p_review_id;
  else
    v_target_type := 'business';
    v_target_id := p_business_id;
    v_business_id := p_business_id;
  end if;

  if v_target_type = 'business' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = v_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  elsif v_target_type = 'review' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = v_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and menu_item_photo_id = v_photo_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    reason,
    details
  )
  values (
    v_uid,
    v_business_id,
    v_review_id,
    v_photo_id,
    v_target_type,
    v_target_id,
    v_reason,
    v_details
  )
  returning id into v_report_id;

  v_response := jsonb_build_object('ok', true, 'report_id', v_report_id);

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
      v_uid,
      'submit_report_v2',
      v_idempotency_key,
      v_response,
      'report',
      v_report_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.submit_report_v2(uuid, uuid, uuid, text, text, text) to anon;
grant all on function public.submit_report_v2(uuid, uuid, uuid, text, text, text) to authenticated;
grant all on function public.submit_report_v2(uuid, uuid, uuid, text, text, text) to service_role;

commit;
