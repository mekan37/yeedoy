-- Wire profanity detection into the moderation strike system.
-- submit_review_v3 and submit_menu_item_price_suggestion_v2 already detect
-- profanity via contains_obfuscated_profanity_v1; this migration adds a call
-- to the already-existing add_moderation_strike_v1 at the point profanity is
-- detected, so repeated offenders get shadow-banned after 3 strikes in 30 days.
-- No other behavior changes: submit_review_v3 still stores the review as
-- status='pending' and returns ok:true; submit_menu_item_price_suggestion_v2
-- still rejects with 'contains_profanity'.

CREATE OR REPLACE FUNCTION public.submit_review_v3(p_business_id uuid, p_overall_rating integer, p_title text DEFAULT NULL::text, p_content text DEFAULT NULL::text, p_taste_rating integer DEFAULT NULL::integer, p_service_speed_rating integer DEFAULT NULL::integer, p_price_performance_rating integer DEFAULT NULL::integer, p_cleanliness_rating integer DEFAULT NULL::integer, p_atmosphere_rating integer DEFAULT NULL::integer, p_idempotency_key text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      hashtext('submit_review_v3'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_review_v3'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_overall_rating < 1 or p_overall_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if p_taste_rating is not null and (p_taste_rating < 1 or p_taste_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_taste_rating');
  end if;

  if p_service_speed_rating is not null and (p_service_speed_rating < 1 or p_service_speed_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_service_speed_rating');
  end if;

  if p_price_performance_rating is not null and (p_price_performance_rating < 1 or p_price_performance_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_price_performance_rating');
  end if;

  if p_cleanliness_rating is not null and (p_cleanliness_rating < 1 or p_cleanliness_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_cleanliness_rating');
  end if;

  if p_atmosphere_rating is not null and (p_atmosphere_rating < 1 or p_atmosphere_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_atmosphere_rating');
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

  if v_has_profanity then
    perform public.add_moderation_strike_v1(v_user_id, 'profanity', 'submit_review_v3');
  end if;

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
    business_id,
    user_id,
    rating,
    overall_rating,
    taste_rating,
    service_speed_rating,
    price_performance_rating,
    cleanliness_rating,
    atmosphere_rating,
    title,
    content,
    status
  ) values (
    p_business_id,
    v_user_id,
    p_overall_rating,
    p_overall_rating,
    p_taste_rating,
    p_service_speed_rating,
    p_price_performance_rating,
    p_cleanliness_rating,
    p_atmosphere_rating,
    v_title,
    v_content,
    v_status
  )
  returning id into v_review_id;

  v_response := jsonb_build_object(
    'ok', true,
    'review_id', v_review_id,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity,
    'has_detailed_ratings',
      (p_taste_rating is not null
        or p_service_speed_rating is not null
        or p_price_performance_rating is not null
        or p_cleanliness_rating is not null
        or p_atmosphere_rating is not null)
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
      'submit_review_v3',
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
$function$;

CREATE OR REPLACE FUNCTION public.submit_menu_item_price_suggestion_v2(p_menu_item_id uuid, p_suggested_price_cents integer, p_currency text DEFAULT 'TRY'::text, p_note text DEFAULT NULL::text, p_evidence_url text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(public.sanitize_plain_text_v1(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and public.contains_contact_or_url_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null and public.contains_obfuscated_profanity_v1(v_note) then
    perform public.add_moderation_strike_v1(auth.uid(), 'profanity', 'submit_menu_item_price_suggestion_v2');
    return jsonb_build_object('ok', false, 'error', 'contains_profanity');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$function$;
