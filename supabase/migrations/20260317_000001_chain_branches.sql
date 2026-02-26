-- Chain / branch model

create table if not exists public.chains (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text null,
  description text null,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_chains_name_unique
  on public.chains(lower(name));

alter table public.businesses
  add column if not exists chain_id uuid references public.chains(id) on delete set null;

alter table public.businesses
  add column if not exists branch_label text;

create table if not exists public.chain_memberships (
  chain_id uuid not null references public.chains(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'manager' check (role in ('owner', 'manager')),
  created_at timestamptz not null default now(),
  primary key (chain_id, user_id)
);

alter table public.chains enable row level security;
alter table public.chain_memberships enable row level security;

drop policy if exists chains_read_all on public.chains;
create policy chains_read_all on public.chains
for select to authenticated using (true);

drop policy if exists chain_memberships_owner_read on public.chain_memberships;
create policy chain_memberships_owner_read on public.chain_memberships
for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists chain_memberships_admin_all on public.chain_memberships;
create policy chain_memberships_admin_all on public.chain_memberships
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create or replace function public.owner_list_my_businesses_v2(
  p_status text default 'approved',
  p_limit integer default 50,
  p_offset integer default 0
) returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz,
  chain_id uuid,
  chain_name text,
  branch_label text,
  owner_role text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.id as business_id,
    b.name as business_name,
    coalesce(b.city, '') as city,
    coalesce(b.district, '') as district,
    c.status as claim_status,
    c.created_at as claimed_at,
    b.chain_id,
    ch.name as chain_name,
    coalesce(b.branch_label, '') as branch_label,
    coalesce(cm.role, 'owner') as owner_role
  from public.owner_claims c
  join public.businesses b on b.id = c.business_id
  left join public.chains ch on ch.id = b.chain_id
  left join public.chain_memberships cm on cm.chain_id = b.chain_id and cm.user_id = auth.uid()
  where c.user_id = auth.uid()
    and (p_status is null or c.status = p_status)
  order by c.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.get_chain_overview_v1(
  p_chain_id uuid,
  p_lat double precision default null,
  p_lng double precision default null,
  p_limit integer default 20
) returns table(
  chain_id uuid,
  chain_name text,
  chain_description text,
  business_id uuid,
  business_name text,
  branch_label text,
  city text,
  district text,
  address text,
  is_open_now boolean,
  distance_km double precision
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ch.id as chain_id,
    ch.name as chain_name,
    ch.description as chain_description,
    b.id as business_id,
    b.name as business_name,
    coalesce(b.branch_label, '') as branch_label,
    b.city,
    b.district,
    b.address,
    null::boolean as is_open_now,
    case
      when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
      else round((st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      ) / 1000.0)::numeric, 2)::double precision
    end as distance_km
  from public.businesses b
  join public.chains ch on ch.id = b.chain_id
  where b.chain_id = p_chain_id
    and b.is_active = true
  order by
    case when p_lat is null or p_lng is null then null else
      st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      )
    end asc nulls last,
    b.name asc
  limit greatest(p_limit, 1);
$$;

grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to anon;
grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to authenticated;
grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to service_role;

grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to anon;
grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to authenticated;
grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to service_role;
