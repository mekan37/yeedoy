begin;

alter table if exists public.menu_item_price_suggestions
  add column if not exists quality_confidence numeric not null default 0,
  add column if not exists quality_user_weight numeric not null default 1,
  add column if not exists quality_evidence_weight numeric not null default 1,
  add column if not exists quality_time_weight numeric not null default 1,
  add column if not exists anomaly_flags jsonb not null default '[]'::jsonb,
  add column if not exists anomaly_score numeric not null default 0,
  add column if not exists conflict_state text not null default 'none',
  add column if not exists conflict_variants_24h integer not null default 0;

create index if not exists idx_menu_price_suggestion_quality_conflict_v1
  on public.menu_item_price_suggestions(menu_item_id, conflict_state, created_at desc);

create index if not exists idx_menu_price_suggestion_quality_anomaly_v1
  on public.menu_item_price_suggestions(menu_item_id, anomaly_score desc, created_at desc);

create or replace function public.compute_price_suggestion_quality_v1(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_evidence_url text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_current_price integer := null;
  v_user_reputation integer := 0;
  v_user_weight numeric := 1.0;
  v_evidence_weight numeric := 1.0;
  v_time_weight numeric := 1.0;
  v_base_confidence numeric := 0.6;
  v_quality_confidence numeric := 0.6;
  v_anomaly_score numeric := 0;
  v_delta_ratio numeric := 0;
  v_recent_distinct integer := 0;
  v_conflict_state text := 'none';
  v_flags text[] := array[]::text[];
  v_flags_json jsonb := '[]'::jsonb;
begin
  if v_uid is not null and to_regprocedure('public.get_user_reputation_score_v2(uuid)') is not null then
    begin
      execute 'select coalesce(public.get_user_reputation_score_v2($1), 0)::int'
      into v_user_reputation
      using v_uid;
    exception
      when others then
        v_user_reputation := 0;
    end;
  end if;

  v_user_weight := greatest(0.35, least(1.5, 0.6 + (v_user_reputation::numeric / 120.0)));
  v_evidence_weight := case when nullif(trim(coalesce(p_evidence_url, '')), '') is null then 1.0 else 1.18 end;
  v_time_weight := case
    when p_captured_at >= now() - interval '2 hours' then 1.25
    when p_captured_at >= now() - interval '24 hours' then 1.05
    when p_captured_at >= now() - interval '72 hours' then 0.9
    else 0.75
  end;

  select mi.price_cents
    into v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  if v_current_price is not null and v_current_price > 0 then
    v_delta_ratio := abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric;
    if p_suggested_price_cents >= ceil(v_current_price * 1.40) then
      v_flags := array_append(v_flags, 'high_increase');
      v_anomaly_score := v_anomaly_score + 0.55;
    end if;
    if p_suggested_price_cents <= floor(v_current_price * 0.55) then
      v_flags := array_append(v_flags, 'extreme_drop');
      v_anomaly_score := v_anomaly_score + 0.55;
    end if;
    if v_delta_ratio >= 0.75 then
      v_flags := array_append(v_flags, 'suspicious_jump');
      v_anomaly_score := v_anomaly_score + 0.35;
    end if;
  end if;

  select count(distinct s.suggested_price_cents)
    into v_recent_distinct
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.created_at >= now() - interval '24 hours'
    and s.status::text = any(array['pending', 'approved', 'accepted', 'handled', 'verified']);

  if v_recent_distinct >= 2 then
    v_conflict_state := 'queued';
    v_flags := array_append(v_flags, 'price_conflict');
  end if;

  if coalesce(array_length(v_flags, 1), 0) > 0 then
    v_flags_json := to_jsonb(v_flags);
  end if;

  v_quality_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (v_base_confidence * v_user_weight * v_evidence_weight * v_time_weight)
        - least(0.65::numeric, v_anomaly_score * 0.45)
      )
    );

  return jsonb_build_object(
    'user_weight', v_user_weight,
    'evidence_weight', v_evidence_weight,
    'time_weight', v_time_weight,
    'quality_confidence', v_quality_confidence,
    'anomaly_score', v_anomaly_score,
    'anomaly_flags', v_flags_json,
    'conflict_state', v_conflict_state,
    'conflict_variants_24h', v_recent_distinct
  );
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v4(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_suggestion_id uuid;
  v_quality jsonb := '{}'::jsonb;
  v_force_pending boolean := false;
  v_prev_price integer := null;
  v_conflict_state text := 'none';
  v_anomaly_score numeric := 0;
  v_quality_confidence numeric := 0;
  v_pending_count integer := 0;
begin
  select mi.price_cents
    into v_prev_price
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  v_result := public.submit_menu_item_price_suggestion_v2(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url,
    p_client_id,
    p_captured_at
  );

  if coalesce((v_result->>'ok')::boolean, false) is false then
    return v_result;
  end if;

  select s.id
    into v_suggestion_id
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.created_by = auth.uid()
  order by s.created_at desc
  limit 1;

  if v_suggestion_id is null then
    return v_result;
  end if;

  v_quality := public.compute_price_suggestion_quality_v1(
    p_menu_item_id,
    p_suggested_price_cents,
    p_evidence_url,
    coalesce(p_captured_at, now())
  );
  v_conflict_state := coalesce(v_quality->>'conflict_state', 'none');
  v_anomaly_score := coalesce((v_quality->>'anomaly_score')::numeric, 0);
  v_quality_confidence := coalesce((v_quality->>'quality_confidence')::numeric, 0);
  v_force_pending := (v_conflict_state = 'queued') or (v_anomaly_score >= 0.50);

  update public.menu_item_price_suggestions s
  set quality_user_weight = coalesce((v_quality->>'user_weight')::numeric, 1),
      quality_evidence_weight = coalesce((v_quality->>'evidence_weight')::numeric, 1),
      quality_time_weight = coalesce((v_quality->>'time_weight')::numeric, 1),
      quality_confidence = v_quality_confidence,
      anomaly_score = v_anomaly_score,
      anomaly_flags = coalesce(v_quality->'anomaly_flags', '[]'::jsonb),
      conflict_state = v_conflict_state,
      conflict_variants_24h = coalesce((v_quality->>'conflict_variants_24h')::int, 0),
      status = case
        when v_force_pending then 'pending'::public.menu_price_suggestion_status
        else s.status
      end,
      handled_by = case when v_force_pending then null else s.handled_by end,
      handled_at = case when v_force_pending then null else s.handled_at end,
      approved_by = case when v_force_pending then null else s.approved_by end,
      approved_at = case when v_force_pending then null else s.approved_at end,
      onsite_signal = case
        when v_force_pending and v_conflict_state = 'queued' then 'conflict_queue'
        when v_force_pending and v_anomaly_score >= 0.50 then 'anomaly_queue'
        else s.onsite_signal
      end
  where s.id = v_suggestion_id;

  if v_force_pending and coalesce((v_result->>'auto_approved')::boolean, false) then
    if v_prev_price is not null then
      update public.menu_items mi
      set price_cents = v_prev_price,
          updated_at = now()
      where mi.id = p_menu_item_id;
    end if;
  end if;

  select count(*)
    into v_pending_count
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.status = 'pending'::public.menu_price_suggestion_status;

  return v_result
    || jsonb_build_object(
      'suggestion_id', v_suggestion_id,
      'auto_approved', case when v_force_pending then false else coalesce((v_result->>'auto_approved')::boolean, false) end,
      'pending_count', v_pending_count,
      'quality_confidence', v_quality_confidence,
      'anomaly_score', v_anomaly_score,
      'anomaly_flags', coalesce(v_quality->'anomaly_flags', '[]'::jsonb),
      'conflict_state', v_conflict_state,
      'conflict_variants_24h', coalesce((v_quality->>'conflict_variants_24h')::int, 0),
      'queued_for_review', v_force_pending
    );
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v3(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.submit_menu_item_price_suggestion_v4(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url,
    p_client_id,
    p_captured_at
  );
$$;

create or replace function public.owner_override_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text,
  p_force_price_cents integer default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_s public.menu_item_price_suggestions%rowtype;
  v_price integer;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;
  if v_reason is null or length(v_reason) < 3 then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  select *
    into v_s
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id
  for update;

  if v_s.id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;
  if not public.is_admin() and not public.is_owner_of_business(v_s.business_id) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  v_price := coalesce(p_force_price_cents, v_s.suggested_price_cents);
  if v_price is null or v_price < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  update public.menu_items mi
  set price_cents = v_price,
      currency = coalesce(nullif(trim(v_s.currency), ''), mi.currency),
      updated_at = now()
  where mi.id = v_s.menu_item_id;

  insert into public.menu_item_price_history(
    menu_item_id, price_cents, currency, source, created_by
  )
  values (
    v_s.menu_item_id,
    v_price,
    coalesce(nullif(trim(v_s.currency), ''), 'TRY'),
    'owner_override',
    v_uid
  );

  update public.menu_item_price_suggestions s
  set status = 'approved'::public.menu_price_suggestion_status,
      handled_by = v_uid,
      handled_at = now(),
      approved_by = v_uid,
      approved_at = now(),
      quality_confidence = greatest(s.quality_confidence, 0.90),
      conflict_state = case
        when s.conflict_state = 'queued' then 'owner_overridden'
        else s.conflict_state
      end,
      note = coalesce(nullif(s.note, ''), '') || E'\n[owner_override] ' || v_reason
  where s.id = v_s.id;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.price_suggestion.override',
    'menu_item_price_suggestions',
    v_s.id,
    jsonb_build_object(
      'actor_id', v_uid,
      'business_id', v_s.business_id,
      'menu_item_id', v_s.menu_item_id,
      'suggested_price_cents', v_s.suggested_price_cents,
      'applied_price_cents', v_price,
      'reason', v_reason,
      'conflict_state_before', v_s.conflict_state,
      'anomaly_score_before', v_s.anomaly_score
    )
  );

  return jsonb_build_object(
    'ok', true,
    'suggestion_id', v_s.id,
    'applied_price_cents', v_price
  );
end;
$$;

create or replace function public.owner_approve_price_suggestion_v1(p_suggestion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_override_price_suggestion_v1(
    p_suggestion_id,
    'owner_override_approved',
    null
  );
end;
$function$;

drop function if exists public.owner_list_price_suggestions_v1(uuid, text, integer, integer);
create or replace function public.owner_list_price_suggestions_v1(
  p_business_id uuid,
  p_status text,
  p_limit integer,
  p_offset integer
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  quality_confidence numeric,
  anomaly_score numeric,
  anomaly_flags jsonb,
  conflict_state text,
  conflict_variants_24h integer
)
language sql
security definer
set search_path to 'public'
as $function$
  with owner_businesses as (
    select c.business_id
    from public.owner_claims c
    where c.user_id = auth.uid()
      and c.status = 'approved'
  ),
  target_businesses as (
    select business_id
    from owner_businesses
    where p_business_id is null
    union all
    select p_business_id
    where p_business_id is not null
  )
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    s.business_id,
    b.name as business_name,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.quality_confidence,
    s.anomaly_score,
    s.anomaly_flags,
    s.conflict_state,
    s.conflict_variants_24h
  from public.menu_item_price_suggestions s
  join target_businesses tb on tb.business_id = s.business_id
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or p_status = '' or s.status::text = p_status)
  order by
    (s.conflict_state = 'queued') desc,
    (coalesce(s.anomaly_score, 0) >= 0.5) desc,
    (s.status = 'pending') desc,
    s.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

drop function if exists public.admin_list_menu_price_suggestions_v2(text, integer, integer, boolean, text);
create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone,
  quality_confidence numeric,
  anomaly_score numeric,
  anomaly_flags jsonb,
  conflict_state text,
  conflict_variants_24h integer
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status = 'pending' and s.created_at < now() - interval '48 hours') as sla_breached,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at,
    s.quality_confidence,
    s.anomaly_score,
    s.anomaly_flags,
    s.conflict_state,
    s.conflict_variants_24h
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and s.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and s.handled_by is null)
      or s.handled_by::text = p_assigned
    )
    and (not p_sla_only or (s.status = 'pending' and s.created_at < now() - interval '48 hours'))
  order by
    (s.conflict_state = 'queued') desc,
    (coalesce(s.anomaly_score, 0) >= 0.5) desc,
    (s.status = 'pending') desc,
    s.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

grant all on function public.compute_price_suggestion_quality_v1(uuid, integer, text, timestamptz) to authenticated;
grant all on function public.compute_price_suggestion_quality_v1(uuid, integer, text, timestamptz) to service_role;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to anon;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to service_role;
grant all on function public.owner_override_price_suggestion_v1(uuid, text, integer) to authenticated;
grant all on function public.owner_override_price_suggestion_v1(uuid, text, integer) to service_role;

commit;
