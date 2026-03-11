-- Hidden fees flags (crowd verified)
create table if not exists public.business_fee_flags (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  has_cover_charge boolean null,
  cover_charge_cents int null,
  has_service_fee boolean null,
  service_fee_pct int null,
  bottled_water_paid boolean null,
  updated_at timestamptz default now()
);
create table if not exists public.business_fee_votes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null,
  field text not null check (field in ('cover','service','water')),
  value boolean not null,
  note text null,
  created_at timestamptz default now(),
  created_day date generated always as ((created_at at time zone 'utc')::date) stored
);
create unique index if not exists business_fee_votes_unique_day
  on public.business_fee_votes (business_id, user_id, field, created_day);
create index if not exists business_fee_votes_business_time_idx
  on public.business_fee_votes (business_id, created_at desc);
alter table public.business_fee_flags enable row level security;
alter table public.business_fee_votes enable row level security;
-- RLS: read for all, write for authed users (votes), admin full
drop policy if exists "business_fee_flags_read_all" on public.business_fee_flags;
create policy "business_fee_flags_read_all"
  on public.business_fee_flags
  for select using (true);
drop policy if exists "business_fee_votes_read_all" on public.business_fee_votes;
create policy "business_fee_votes_read_all"
  on public.business_fee_votes
  for select using (true);
drop policy if exists "business_fee_votes_insert_authed" on public.business_fee_votes;
create policy "business_fee_votes_insert_authed"
  on public.business_fee_votes
  for insert
  with check (auth.uid() is not null and user_id = auth.uid());
drop policy if exists "business_fee_flags_admin_all" on public.business_fee_flags;
create policy "business_fee_flags_admin_all"
  on public.business_fee_flags
  for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "business_fee_votes_admin_all" on public.business_fee_votes;
create policy "business_fee_votes_admin_all"
  on public.business_fee_votes
  for all using (public.is_admin()) with check (public.is_admin());
create or replace function public.vote_business_fee_v1(
  p_business_id uuid,
  p_field text,
  p_value boolean,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_limit jsonb;
  v_day date := (now() at time zone 'utc')::date;
  v_key text := 'business_fee_vote:' || auth.uid()::text || ':' || p_field || ':' || v_day::text;
  v_row public.user_rate_limits%rowtype;
  v_yes int;
  v_no int;
  v_total int;
  v_majority boolean;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_field not in ('cover','service','water') then
    return jsonb_build_object('ok', false, 'error', 'invalid_field');
  end if;

  -- rate limit (daily 10 per user)
  v_limit := public.consume_rate_limit_v1('business_fee_vote', 10);
  if (v_limit->>'ok')::boolean is false then
    return v_limit;
  end if;

  insert into public.business_fee_votes(business_id, user_id, field, value, note)
  values (p_business_id, auth.uid(), p_field, p_value, p_note);

  select
    count(*) filter (where value = true),
    count(*) filter (where value = false),
    count(*)
  into v_yes, v_no, v_total
  from public.business_fee_votes
  where business_id = p_business_id
    and field = p_field
    and created_at >= now() - interval '30 days';

  v_majority := case
    when v_total = 0 then null
    when v_yes >= v_no then true
    else false
  end;

  insert into public.business_fee_flags(business_id, updated_at)
  values (p_business_id, now())
  on conflict (business_id) do update
  set updated_at = excluded.updated_at;

  if p_field = 'cover' then
    update public.business_fee_flags
    set has_cover_charge = v_majority, updated_at = now()
    where business_id = p_business_id;
  elsif p_field = 'service' then
    update public.business_fee_flags
    set has_service_fee = v_majority, updated_at = now()
    where business_id = p_business_id;
  else
    update public.business_fee_flags
    set bottled_water_paid = v_majority, updated_at = now()
    where business_id = p_business_id;
  end if;

  return jsonb_build_object('ok', true);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'rate_limited');
end;
$$;
create or replace function public.get_business_fee_summary_v1(
  p_business_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  with votes as (
    select
      field,
      count(*) filter (where value = true) as yes_count,
      count(*) filter (where value = false) as no_count,
      count(*) as total_count,
      max(created_at) as last_vote_at
    from public.business_fee_votes
    where business_id = p_business_id
      and created_at >= now() - interval '30 days'
    group by field
  ),
  scored as (
    select
      field,
      yes_count,
      no_count,
      total_count,
      last_vote_at,
      case
        when total_count = 0 then null
        when yes_count >= no_count then true
        else false
      end as value,
      case
        when total_count = 0 then 0
        else least(1.0,
          (abs(yes_count - no_count)::float / total_count) * 0.7 +
          (1 - least(extract(epoch from (now() - last_vote_at)) / (30*86400.0), 1)) * 0.3
        )
      end as confidence
    from votes
  )
  select jsonb_build_object(
    'cover', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'cover'
    ),
    'service', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'service'
    ),
    'water', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'water'
    )
  );
$$;
