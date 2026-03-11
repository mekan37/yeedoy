create table if not exists public.business_submissions (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null,
  name text not null,
  city text not null,
  district text not null,
  category text not null,
  address text not null,
  phone text null,
  website text null,
  status text not null default 'new' check (status in ('new','approved','rejected')),
  admin_note text null,
  created_at timestamptz not null default now()
);
create index if not exists business_submissions_status_created_idx
  on public.business_submissions (status, created_at desc);
alter table public.business_submissions enable row level security;
drop policy if exists business_submissions_owner_select on public.business_submissions;
create policy business_submissions_owner_select on public.business_submissions
  for select using (submitted_by = auth.uid());
drop policy if exists business_submissions_owner_insert on public.business_submissions;
create policy business_submissions_owner_insert on public.business_submissions
  for insert with check (submitted_by = auth.uid());
drop policy if exists business_submissions_admin_all on public.business_submissions;
create policy business_submissions_admin_all on public.business_submissions
  for all using (public.is_admin()) with check (public.is_admin());
create or replace function public.owner_list_my_businesses_v1(
  p_status text default 'approved',
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    c.status::text as claim_status,
    c.created_at as claimed_at
  from public.owner_claims c
  join public.businesses b on b.id = c.business_id
  where c.user_id = auth.uid()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
  order by c.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;
create or replace function public.owner_list_my_business_submissions_v1(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  id uuid,
  name text,
  city text,
  district text,
  category text,
  address text,
  phone text,
  website text,
  status text,
  admin_note text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    s.id,
    s.name,
    s.city,
    s.district,
    s.category,
    s.address,
    s.phone,
    s.website,
    s.status::text,
    s.admin_note,
    s.created_at
  from public.business_submissions s
  where s.submitted_by = auth.uid()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;
create or replace function public.owner_submit_new_business_v1(
  p_name text,
  p_city text,
  p_district text,
  p_category text,
  p_address text,
  p_phone text default null,
  p_website text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.business_submissions(
    submitted_by, name, city, district, category, address, phone, website
  )
  values (
    auth.uid(), p_name, p_city, p_district, p_category, p_address, p_phone, p_website
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'request_id', v_id);
end;
$$;
create or replace function public.admin_list_business_submissions_v1(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  id uuid,
  submitted_by uuid,
  name text,
  city text,
  district text,
  category text,
  address text,
  phone text,
  website text,
  status text,
  admin_note text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    s.id,
    s.submitted_by,
    s.name,
    s.city,
    s.district,
    s.category,
    s.address,
    s.phone,
    s.website,
    s.status::text,
    s.admin_note,
    s.created_at
  from public.business_submissions s
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;
create or replace function public.admin_approve_business_submission_v1(
  p_submission_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_sub record;
  v_business_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  select *
    into v_sub
  from public.business_submissions
  where id = p_submission_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_sub.status <> 'new' then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  insert into public.businesses(
    name, category, address, city, district, phone, source, source_id
  )
  values (
    v_sub.name, v_sub.category, v_sub.address, v_sub.city, v_sub.district, v_sub.phone,
    'submission', v_sub.id::text
  )
  returning id into v_business_id;

  insert into public.owner_claims(
    business_id, user_id, status, created_at
  )
  values (
    v_business_id, v_sub.submitted_by, 'approved', now()
  )
  on conflict do nothing;

  update public.business_submissions
  set status = 'approved'
  where id = v_sub.id;

  return jsonb_build_object('ok', true, 'business_id', v_business_id);
end;
$$;
create or replace function public.admin_reject_business_submission_v1(
  p_submission_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  update public.business_submissions
  set status = 'rejected',
      admin_note = p_note
  where id = p_submission_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;
