create or replace function public.submit_menu_item_price_suggestion_v1(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  v_note := nullif(trim(p_note), '');

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id and status='published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: aynı kullanıcı aynı itemâ€™e 24 saatte 1
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, p_currency, v_note, auth.uid()
  );

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.owner_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_note := nullif(trim(p_note), '');

  select business_id into v_business_id
  from public.menu_item_price_suggestions
  where id = p_suggestion_id and status='pending';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  update public.menu_item_price_suggestions
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_suggestion_id
    and status='pending';

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  v_note := nullif(trim(p_note), '');

  update public.menu_item_price_suggestions
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_suggestion_id
    and status='pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_reject_suspended_claim_v1(
  p_claim_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  v_note := nullif(trim(p_note), '');

  update public.suspended_meal_claims
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_claim_id
    and status='pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_decide_owner_claim_v1(
  p_claim_id uuid,
  p_decision text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = v_note
  where id = p_claim_id;

  perform public.log_admin_action_v1(
    case
      when p_decision = 'approved' then 'claim.approve'
      else 'claim.reject'
    end,
    'owner_claims',
    p_claim_id,
    jsonb_build_object(
      'decision', p_decision,
      'admin_note', v_note
    )
  );
end;
$function$;

create or replace function public.admin_bulk_decide_owner_claims_v1(
  p_claim_ids uuid[],
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_count int;
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = v_note
  where id = any(p_claim_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'claim.bulk_decide',
    'owner_claims',
    null,
    jsonb_build_object('decision', p_decision, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$;

create or replace function public.submit_owner_claim_v1(
  p_business_id uuid,
  p_full_name text,
  p_phone text,
  p_evidence_url text default null,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_claim_id uuid;
  v_note text;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  v_note := nullif(trim(p_note), '');

  -- 7 gün rate limit (aynı business için)
  select exists(
    select 1
    from public.owner_claims
    where user_id = v_uid
      and business_id = p_business_id
      and created_at >= now() - interval '7 days'
  ) into v_recent_exists;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_7d');
  end if;

  insert into public.owner_claims(
    user_id, business_id, full_name, phone, evidence_url, note, status
  ) values (
    v_uid, p_business_id,
    nullif(trim(p_full_name),''),
    nullif(trim(p_phone),''),
    nullif(trim(p_evidence_url),''),
    v_note,
    'pending'
  )
  returning id into v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'already_submitted');
end;
$function$;


