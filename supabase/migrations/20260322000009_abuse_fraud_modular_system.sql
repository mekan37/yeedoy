begin;

create table if not exists public.user_risk_signals (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  signal_key text not null,
  signal_weight integer not null default 0,
  ip_hash text null,
  signal_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_risk_signals_user_created
  on public.user_risk_signals (user_id, created_at desc);

create index if not exists idx_user_risk_signals_signal_created
  on public.user_risk_signals (signal_key, created_at desc);

create table if not exists public.user_safety_actions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  risk_score integer not null default 0,
  soft_limited_until timestamptz null,
  auto_pending_until timestamptz null,
  shadow_banned_until timestamptz null,
  last_signal_at timestamptz null,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_device_fingerprints (
  user_id uuid not null references auth.users(id) on delete cascade,
  fingerprint text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  seen_count integer not null default 1,
  primary key (user_id, fingerprint)
);

create index if not exists idx_user_device_fingerprints_user_seen
  on public.user_device_fingerprints (user_id, last_seen_at desc);

alter table public.user_risk_signals enable row level security;
alter table public.user_safety_actions enable row level security;
alter table public.user_device_fingerprints enable row level security;

drop policy if exists user_risk_signals_admin_all on public.user_risk_signals;
create policy user_risk_signals_admin_all
  on public.user_risk_signals
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists user_safety_actions_admin_all on public.user_safety_actions;
create policy user_safety_actions_admin_all
  on public.user_safety_actions
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists user_device_fingerprints_admin_all on public.user_device_fingerprints;
create policy user_device_fingerprints_admin_all
  on public.user_device_fingerprints
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create or replace function public.is_user_shadowed_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce((select up.shadow_banned from public.user_profiles up where up.user_id = p_user_id), false)
    or coalesce((select usa.shadow_banned_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id), false);
$$;

create or replace function public.is_user_auto_pending_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select usa.auto_pending_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id),
    false
  );
$$;

create or replace function public.is_user_soft_limited_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select usa.soft_limited_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id),
    false
  );
$$;

create or replace function public.is_shadow_banned_v1()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.is_user_shadowed_v1(auth.uid());
$$;

create or replace function public.record_user_risk_signal_v1(
  p_user_id uuid,
  p_signal_key text,
  p_signal_weight integer default 5,
  p_ip_hash text default null,
  p_signal_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_inserted boolean := false;
  v_score integer := 0;
  v_now timestamptz := now();
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if coalesce(trim(p_signal_key), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'missing_signal_key');
  end if;

  if auth.role() <> 'service_role' and not public.is_admin() and v_actor is distinct from p_user_id then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if exists (
    select 1
    from public.user_risk_signals rs
    where rs.user_id = p_user_id
      and rs.signal_key = p_signal_key
      and rs.created_at >= case
        when p_signal_key in ('new_account', 'device_change') then v_now - interval '24 hours'
        when p_signal_key = 'same_ip_burst' then v_now - interval '30 minutes'
        when p_signal_key = 'duplicate_text' then v_now - interval '12 hours'
        else v_now - interval '10 minutes'
      end
  ) then
    v_inserted := false;
  else
    insert into public.user_risk_signals(
      user_id,
      signal_key,
      signal_weight,
      ip_hash,
      signal_meta
    ) values (
      p_user_id,
      p_signal_key,
      greatest(0, p_signal_weight),
      nullif(trim(coalesce(p_ip_hash, '')), ''),
      coalesce(p_signal_meta, '{}'::jsonb)
    );
    v_inserted := true;
  end if;

  select coalesce(sum(rs.signal_weight), 0)::integer
    into v_score
  from public.user_risk_signals rs
  where rs.user_id = p_user_id
    and rs.created_at >= v_now - interval '14 days';

  insert into public.user_safety_actions(
    user_id,
    risk_score,
    last_signal_at,
    updated_at
  ) values (
    p_user_id,
    v_score,
    case when v_inserted then v_now else null end,
    v_now
  )
  on conflict (user_id) do update
    set risk_score = excluded.risk_score,
        last_signal_at = coalesce(excluded.last_signal_at, public.user_safety_actions.last_signal_at),
        updated_at = v_now;

  if v_score >= 80 then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, v_now), v_now + interval '72 hours'),
          auto_pending_until = greatest(coalesce(auto_pending_until, v_now), v_now + interval '72 hours'),
          updated_at = v_now
    where user_id = p_user_id;
  elsif v_score >= 50 then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, v_now), v_now + interval '24 hours'),
          updated_at = v_now
    where user_id = p_user_id;
  elsif v_score >= 30 then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, v_now), v_now + interval '30 minutes'),
          updated_at = v_now
    where user_id = p_user_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'inserted', v_inserted,
    'risk_score', v_score
  );
end;
$$;

create or replace function public.record_user_device_fingerprint_v1(
  p_user_id uuid,
  p_fingerprint text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fingerprint text := trim(coalesce(p_fingerprint, ''));
  v_exists boolean := false;
  v_device_count integer := 0;
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if v_fingerprint = '' then
    return jsonb_build_object('ok', false, 'error', 'missing_fingerprint');
  end if;

  select exists(
    select 1
    from public.user_device_fingerprints d
    where d.user_id = p_user_id
      and d.fingerprint = v_fingerprint
  ) into v_exists;

  if v_exists then
    update public.user_device_fingerprints
      set last_seen_at = now(),
          seen_count = seen_count + 1
    where user_id = p_user_id
      and fingerprint = v_fingerprint;
  else
    insert into public.user_device_fingerprints(
      user_id,
      fingerprint
    ) values (
      p_user_id,
      v_fingerprint
    );
  end if;

  select count(*)
    into v_device_count
  from public.user_device_fingerprints d
  where d.user_id = p_user_id
    and d.last_seen_at >= now() - interval '30 days';

  if not v_exists and v_device_count > 1 then
    perform public.record_user_risk_signal_v1(
      p_user_id,
      'device_change',
      12,
      null,
      jsonb_build_object('device_count', v_device_count)
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'is_new_device', not v_exists,
    'device_count', v_device_count
  );
end;
$$;

create or replace function public.admin_list_risky_users_v1(
  p_limit integer default 50,
  p_offset integer default 0,
  p_min_score integer default 20
)
returns table(
  user_id uuid,
  risk_score integer,
  signal_count integer,
  last_signal_at timestamptz,
  new_account_hits integer,
  device_change_hits integer,
  same_ip_hits integer,
  duplicate_text_hits integer,
  soft_limited_until timestamptz,
  auto_pending_until timestamptz,
  shadow_banned_until timestamptz,
  recommended_action text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    return;
  end if;

  return query
  with recent as (
    select
      rs.user_id,
      coalesce(sum(rs.signal_weight), 0)::integer as score_14d,
      count(*)::integer as cnt,
      max(rs.created_at) as last_at,
      count(*) filter (where rs.signal_key = 'new_account')::integer as new_account_hits,
      count(*) filter (where rs.signal_key = 'device_change')::integer as device_change_hits,
      count(*) filter (where rs.signal_key = 'same_ip_burst')::integer as same_ip_hits,
      count(*) filter (where rs.signal_key = 'duplicate_text')::integer as duplicate_text_hits
    from public.user_risk_signals rs
    where rs.created_at >= now() - interval '14 days'
    group by rs.user_id
  )
  select
    r.user_id,
    greatest(r.score_14d, coalesce(usa.risk_score, 0)) as risk_score,
    r.cnt as signal_count,
    coalesce(usa.last_signal_at, r.last_at) as last_signal_at,
    r.new_account_hits,
    r.device_change_hits,
    r.same_ip_hits,
    r.duplicate_text_hits,
    usa.soft_limited_until,
    usa.auto_pending_until,
    usa.shadow_banned_until,
    case
      when coalesce(usa.shadow_banned_until > now(), false) then 'shadow_ban'
      when coalesce(usa.auto_pending_until > now(), false) then 'auto_pending'
      when coalesce(usa.soft_limited_until > now(), false) then 'soft_limit'
      when greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= 80 then 'shadow_ban'
      when greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= 50 then 'auto_pending'
      else 'soft_limit'
    end as recommended_action
  from recent r
  left join public.user_safety_actions usa on usa.user_id = r.user_id
  where greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= greatest(p_min_score, 1)
  order by greatest(r.score_14d, coalesce(usa.risk_score, 0)) desc, coalesce(usa.last_signal_at, r.last_at) desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
end;
$$;

create or replace function public.admin_apply_user_safety_action_v1(
  p_user_id uuid,
  p_action text,
  p_minutes integer default 60,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(trim(coalesce(p_action, '')));
  v_until timestamptz := now() + make_interval(mins => greatest(p_minutes, 1));
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  insert into public.user_safety_actions(user_id, updated_at)
  values (p_user_id, now())
  on conflict (user_id) do nothing;

  if v_action = 'soft_limit' then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'auto_pending' then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'shadow_ban' then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, now()), v_until),
          auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = true
    where user_id = p_user_id;
  elsif v_action = 'clear' then
    update public.user_safety_actions
      set soft_limited_until = null,
          auto_pending_until = null,
          shadow_banned_until = null,
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = false
    where user_id = p_user_id;
  else
    return jsonb_build_object('ok', false, 'error', 'bad_action');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'user.safety_action',
    'user_profiles',
    p_user_id::text,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'action', v_action,
      'minutes', greatest(p_minutes, 1),
      'reason', nullif(trim(coalesce(p_reason, '')), '')
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.enforce_abuse_controls_on_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
begin
  if new.user_id is null then
    return new;
  end if;

  if public.is_user_soft_limited_v1(new.user_id) then
    select count(*)
      into v_count
    from public.reviews r
    where r.user_id = new.user_id
      and r.created_at >= now() - interval '24 hours';
    if v_count >= 3 then
      raise exception 'soft_rate_limited';
    end if;
  end if;

  if public.is_user_shadowed_v1(new.user_id) or public.is_user_auto_pending_v1(new.user_id) then
    new.status := 'pending';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_abuse_controls_v1 on public.reviews;
create trigger trg_reviews_abuse_controls_v1
before insert on public.reviews
for each row execute function public.enforce_abuse_controls_on_reviews_v1();

create or replace function public.enforce_abuse_controls_on_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
  v_count integer := 0;
begin
  if v_uid is null then
    return new;
  end if;

  if public.is_user_soft_limited_v1(v_uid) then
    select count(*)
      into v_count
    from public.menu_item_price_suggestions s
    where s.created_by = v_uid
      and s.created_at >= now() - interval '24 hours';
    if v_count >= 6 then
      raise exception 'soft_rate_limited';
    end if;
  end if;

  if public.is_user_shadowed_v1(v_uid) or public.is_user_auto_pending_v1(v_uid) then
    new.status := 'pending'::public.menu_price_suggestion_status;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_abuse_controls_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_abuse_controls_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_abuse_controls_on_price_suggestions_v1();

create or replace function public.enforce_abuse_controls_on_menu_photos_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
begin
  if v_uid is null then
    return new;
  end if;

  if public.is_user_shadowed_v1(v_uid) or public.is_user_auto_pending_v1(v_uid) then
    new.status := 'pending';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_item_photos_abuse_controls_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_abuse_controls_v1
before insert on public.menu_item_photos
for each row execute function public.enforce_abuse_controls_on_menu_photos_v1();

create or replace function public.collect_risk_signals_on_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_created_at timestamptz;
  v_norm text := '';
  v_dup integer := 0;
begin
  if new.user_id is null then
    return new;
  end if;

  select up.created_at
    into v_created_at
  from public.user_profiles up
  where up.user_id = new.user_id;

  if v_created_at is not null and v_created_at >= now() - interval '3 days' then
    perform public.record_user_risk_signal_v1(
      new.user_id,
      'new_account',
      8,
      null,
      jsonb_build_object('source', 'reviews')
    );
  end if;

  v_norm := trim(public.normalize_for_moderation_v1(coalesce(new.content, '')));
  if length(v_norm) >= 8 then
    select count(*)
      into v_dup
    from public.reviews r
    where r.user_id <> new.user_id
      and r.created_at >= now() - interval '24 hours'
      and trim(public.normalize_for_moderation_v1(coalesce(r.content, ''))) = v_norm;

    if v_dup >= 2 then
      perform public.record_user_risk_signal_v1(
        new.user_id,
        'duplicate_text',
        18,
        null,
        jsonb_build_object('source', 'reviews', 'duplicate_count', v_dup)
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_collect_risk_signals_v1 on public.reviews;
create trigger trg_reviews_collect_risk_signals_v1
before insert on public.reviews
for each row execute function public.collect_risk_signals_on_reviews_v1();

create or replace function public.collect_risk_signals_on_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
  v_created_at timestamptz;
  v_norm text := '';
  v_dup integer := 0;
begin
  if v_uid is null then
    return new;
  end if;

  select up.created_at
    into v_created_at
  from public.user_profiles up
  where up.user_id = v_uid;

  if v_created_at is not null and v_created_at >= now() - interval '3 days' then
    perform public.record_user_risk_signal_v1(
      v_uid,
      'new_account',
      8,
      null,
      jsonb_build_object('source', 'price_suggestion')
    );
  end if;

  v_norm := trim(public.normalize_for_moderation_v1(coalesce(new.note, '')));
  if length(v_norm) >= 6 then
    select count(*)
      into v_dup
    from public.menu_item_price_suggestions s
    where s.created_by <> v_uid
      and s.created_at >= now() - interval '24 hours'
      and trim(public.normalize_for_moderation_v1(coalesce(s.note, ''))) = v_norm;

    if v_dup >= 2 then
      perform public.record_user_risk_signal_v1(
        v_uid,
        'duplicate_text',
        14,
        null,
        jsonb_build_object('source', 'price_suggestion', 'duplicate_count', v_dup)
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_collect_risk_signals_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_collect_risk_signals_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.collect_risk_signals_on_price_suggestions_v1();

grant all on function public.record_user_risk_signal_v1(uuid, text, integer, text, jsonb) to authenticated;
grant all on function public.record_user_risk_signal_v1(uuid, text, integer, text, jsonb) to service_role;
grant all on function public.record_user_device_fingerprint_v1(uuid, text) to authenticated;
grant all on function public.record_user_device_fingerprint_v1(uuid, text) to service_role;
grant all on function public.admin_list_risky_users_v1(integer, integer, integer) to authenticated;
grant all on function public.admin_apply_user_safety_action_v1(uuid, text, integer, text) to authenticated;

commit;

