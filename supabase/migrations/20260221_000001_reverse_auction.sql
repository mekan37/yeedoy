-- Reverse auction: group requests & offers

create table if not exists public.group_requests (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null,
  city text not null,
  districts text[] null,
  category text null,
  date_time timestamptz not null,
  party_size int not null,
  budget_total_cents int not null,
  currency text not null default 'TRY',
  notes text null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  constraint group_requests_party_size_check
    check (party_size between 2 and 200),
  constraint group_requests_status_check
    check (status in ('open','closed','awarded','cancelled'))
);

create index if not exists group_requests_city_date_idx
  on public.group_requests (city, date_time);
create index if not exists group_requests_status_created_idx
  on public.group_requests (status, created_at desc);

create table if not exists public.group_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.group_requests(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  offered_total_cents int not null,
  includes jsonb not null default '{}'::jsonb,
  message text null,
  status text not null default 'submitted',
  created_by uuid not null,
  created_at timestamptz not null default now(),
  constraint group_offers_status_check
    check (status in ('submitted','withdrawn','accepted','rejected'))
);

create unique index if not exists group_offers_unique_active
  on public.group_offers (request_id, business_id)
  where status in ('submitted','accepted');

create index if not exists group_offers_request_created_idx
  on public.group_offers (request_id, created_at desc);
create index if not exists group_offers_business_created_idx
  on public.group_offers (business_id, created_at desc);

create table if not exists public.offer_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.group_requests(id) on delete cascade,
  offer_id uuid null references public.group_offers(id) on delete set null,
  sender_type text not null,
  sender_user_id uuid null,
  business_id uuid null references public.businesses(id) on delete set null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint offer_messages_sender_type_check
    check (sender_type in ('user','business','admin'))
);

create index if not exists offer_messages_request_created_idx
  on public.offer_messages (request_id, created_at desc);

-- RLS
alter table public.group_requests enable row level security;
alter table public.group_offers enable row level security;
alter table public.offer_messages enable row level security;

-- group_requests
drop policy if exists group_requests_owner_select on public.group_requests;
create policy group_requests_owner_select on public.group_requests
  for select using (created_by = auth.uid() or public.is_admin());

drop policy if exists group_requests_owner_insert on public.group_requests;
create policy group_requests_owner_insert on public.group_requests
  for insert with check (created_by = auth.uid() or public.is_admin());

drop policy if exists group_requests_owner_update on public.group_requests;
create policy group_requests_owner_update on public.group_requests
  for update using (created_by = auth.uid() or public.is_admin())
  with check (created_by = auth.uid() or public.is_admin());

-- group_offers
drop policy if exists group_offers_business_select on public.group_offers;
create policy group_offers_business_select on public.group_offers
  for select using (
    public.is_admin()
    or public.is_owner_of_business(business_id)
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
  );

drop policy if exists group_offers_business_insert on public.group_offers;
create policy group_offers_business_insert on public.group_offers
  for insert with check (public.is_admin() or public.is_owner_of_business(business_id));

drop policy if exists group_offers_business_update on public.group_offers;
create policy group_offers_business_update on public.group_offers
  for update using (public.is_admin() or public.is_owner_of_business(business_id))
  with check (public.is_admin() or public.is_owner_of_business(business_id));

-- offer_messages
drop policy if exists offer_messages_read on public.offer_messages;
create policy offer_messages_read on public.offer_messages
  for select using (
    public.is_admin()
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
    or (business_id is not null and public.is_owner_of_business(business_id))
  );

drop policy if exists offer_messages_insert on public.offer_messages;
create policy offer_messages_insert on public.offer_messages
  for insert with check (
    public.is_admin()
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
    or (business_id is not null and public.is_owner_of_business(business_id))
  );

-- RPCs
create or replace function public.create_group_request_v1(
  p_city text,
  p_districts text[] default null,
  p_category text default null,
  p_date_time timestamptz default null,
  p_party_size int default null,
  p_budget_total_cents int default null,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
  v_key text;
  v_today date := current_date;
  v_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if p_date_time is null or p_party_size is null or p_budget_total_cents is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_input');
  end if;

  v_key := format('group_request:%s:%s', auth.uid()::text, v_today::text);
  select count into v_count from public.user_rate_limits where key = v_key;
  if coalesce(v_count, 0) >= 3 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
  values (v_key, auth.uid(), 'group_request', v_today, 1, now())
  on conflict (key) do update
    set count = public.user_rate_limits.count + 1,
        updated_at = now();

  insert into public.group_requests(
    created_by, city, districts, category, date_time, party_size,
    budget_total_cents, currency, notes, status
  )
  values (
    auth.uid(),
    trim(p_city),
    p_districts,
    nullif(trim(p_category), ''),
    p_date_time,
    p_party_size,
    p_budget_total_cents,
    'TRY',
    nullif(trim(p_notes), ''),
    'open'
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

create or replace function public.list_group_requests_v1(
  p_status text default null,
  p_city text default null,
  p_limit int default 30,
  p_offset int default 0,
  p_include_open boolean default false
) returns table(
  id uuid,
  created_by uuid,
  city text,
  districts text[],
  category text,
  date_time timestamptz,
  party_size int,
  budget_total_cents int,
  currency text,
  notes text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    r.id,
    r.created_by,
    r.city,
    r.districts,
    r.category,
    r.date_time,
    r.party_size,
    r.budget_total_cents,
    r.currency,
    r.notes,
    r.status,
    r.created_at
  from public.group_requests r
  where
    (public.is_admin()
      or r.created_by = auth.uid()
      or (p_include_open and r.status = 'open'))
    and (p_status is null or r.status = p_status)
    and (p_city is null or r.city = p_city)
  order by r.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.list_open_requests_for_business_v1(
  p_city text,
  p_categories text[] default null,
  p_limit int default 30,
  p_offset int default 0,
  p_business_id uuid default null
) returns table(
  id uuid,
  city text,
  districts text[],
  category text,
  date_time timestamptz,
  party_size int,
  budget_total_cents int,
  currency text,
  notes text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    r.id,
    r.city,
    r.districts,
    r.category,
    r.date_time,
    r.party_size,
    r.budget_total_cents,
    r.currency,
    r.notes,
    r.status,
    r.created_at
  from public.group_requests r
  where (public.is_admin() or (p_business_id is not null and public.is_owner_of_business(p_business_id)))
    and r.status = 'open'
    and r.date_time >= now()
    and r.city = p_city
    and (p_categories is null or r.category = any(p_categories))
  order by r.date_time asc
  limit p_limit offset p_offset;
$$;

create or replace function public.submit_group_offer_v1(
  p_request_id uuid,
  p_business_id uuid,
  p_offered_total_cents int,
  p_includes jsonb default '{}'::jsonb,
  p_message text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_req_status text;
  v_key text;
  v_today date := current_date;
  v_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  select status into v_req_status
  from public.group_requests
  where id = p_request_id;

  if v_req_status is distinct from 'open' then
    return jsonb_build_object('ok', false, 'code', 'request_closed');
  end if;

  v_key := format('group_offer:%s:%s', p_business_id::text, v_today::text);
  select count into v_count from public.user_rate_limits where key = v_key;
  if coalesce(v_count, 0) >= 20 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
  values (v_key, auth.uid(), 'group_offer', v_today, 1, now())
  on conflict (key) do update
    set count = public.user_rate_limits.count + 1,
        updated_at = now();

  insert into public.group_offers(
    request_id, business_id, offered_total_cents, includes, message, status, created_by
  )
  values (
    p_request_id, p_business_id, p_offered_total_cents,
    coalesce(p_includes, '{}'::jsonb),
    nullif(trim(p_message), ''),
    'submitted',
    auth.uid()
  )
  on conflict do nothing;

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.accept_group_offer_v1(
  p_offer_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_request_id uuid;
  v_request_owner uuid;
begin
  select o.request_id, r.created_by
  into v_request_id, v_request_owner
  from public.group_offers o
  join public.group_requests r on r.id = o.request_id
  where o.id = p_offer_id;

  if v_request_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_request_owner <> auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'awarded'
    where id = v_request_id;

  update public.group_offers
    set status = case when id = p_offer_id then 'accepted' else 'rejected' end
    where request_id = v_request_id
      and status in ('submitted','accepted');

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.close_group_request_v1(
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  select created_by into v_owner from public.group_requests where id = p_request_id;
  if v_owner is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_owner <> auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'closed'
    where id = p_request_id;

  return jsonb_build_object('ok', true);
end;
$$;
