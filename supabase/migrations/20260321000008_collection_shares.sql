create extension if not exists pgcrypto;

create table if not exists public.collection_shares (
  slug text primary key,
  collection_key text not null,
  name text not null,
  business_ids text[] not null,
  created_by uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists collection_shares_unique_key
  on public.collection_shares (collection_key, created_by);

alter table public.collection_shares enable row level security;

create policy "collection_shares_read"
on public.collection_shares
for select
using (true);

create policy "collection_shares_insert_own"
on public.collection_shares
for insert
with check (auth.uid() = created_by);

create or replace function public.upsert_collection_share_v1(
  p_collection_key text,
  p_name text,
  p_business_ids text[]
)
returns table (slug text)
language plpgsql
security definer
as $$
declare
  v_slug text;
begin
  select cs.slug
    into v_slug
  from public.collection_shares cs
  where cs.collection_key = p_collection_key
    and cs.created_by = auth.uid()
  limit 1;

  if v_slug is not null then
    return query select v_slug;
  end if;

  v_slug := substr(encode(gen_random_uuid(), 'hex'), 1, 10);

  insert into public.collection_shares(
    slug,
    collection_key,
    name,
    business_ids,
    created_by
  ) values (
    v_slug,
    p_collection_key,
    p_name,
    p_business_ids,
    auth.uid()
  );

  return query select v_slug;
end;
$$;

create or replace function public.get_collection_share_by_slug_v1(
  p_slug text
)
returns table (
  slug text,
  collection_key text,
  name text,
  business_ids text[]
)
language sql
security definer
as $$
  select
    cs.slug,
    cs.collection_key,
    cs.name,
    cs.business_ids
  from public.collection_shares cs
  where cs.slug = p_slug
  limit 1;
$$;
