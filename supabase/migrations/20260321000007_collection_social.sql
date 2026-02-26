create table if not exists public.collection_social_stats (
  collection_key text primary key,
  followers_count integer not null default 0,
  engagement_count integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_collection_follows (
  user_id uuid not null references auth.users(id) on delete cascade,
  collection_key text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, collection_key)
);

alter table public.collection_social_stats enable row level security;
alter table public.user_collection_follows enable row level security;

drop policy if exists "collection_social_stats_read"
on public.collection_social_stats;

create policy "collection_social_stats_read"
on public.collection_social_stats
for select
using (true);

drop policy if exists "user_collection_follows_select_own"
on public.user_collection_follows;

create policy "user_collection_follows_select_own"
on public.user_collection_follows
for select
using (auth.uid() = user_id);

drop policy if exists "user_collection_follows_insert_own"
on public.user_collection_follows;

create policy "user_collection_follows_insert_own"
on public.user_collection_follows
for insert
with check (auth.uid() = user_id);

drop policy if exists "user_collection_follows_delete_own"
on public.user_collection_follows;

create policy "user_collection_follows_delete_own"
on public.user_collection_follows
for delete
using (auth.uid() = user_id);

create or replace function public.get_collection_social_batch_v1(
  p_keys text[]
)
returns table (
  collection_key text,
  followers_count integer,
  engagement_count integer,
  is_following boolean
)
language sql
security definer
as $$
  select
    k.key as collection_key,
    coalesce(s.followers_count, 0) as followers_count,
    coalesce(s.engagement_count, 0) as engagement_count,
    (f.user_id is not null) as is_following
  from unnest(p_keys) as k(key)
  left join public.collection_social_stats s
    on s.collection_key = k.key
  left join public.user_collection_follows f
    on f.collection_key = k.key
   and f.user_id = auth.uid();
$$;

create or replace function public.toggle_collection_follow_v1(
  p_collection_key text
)
returns table (
  is_following boolean,
  followers_count integer
)
language plpgsql
security definer
as $$
declare
  v_exists boolean;
begin
  select exists(
    select 1
    from public.user_collection_follows
    where user_id = auth.uid()
      and collection_key = p_collection_key
  ) into v_exists;

  if v_exists then
    delete from public.user_collection_follows
    where user_id = auth.uid()
      and collection_key = p_collection_key;

    insert into public.collection_social_stats(collection_key)
    values (p_collection_key)
    on conflict (collection_key) do nothing;

    update public.collection_social_stats
      set followers_count = greatest(followers_count - 1, 0),
          updated_at = now()
    where collection_key = p_collection_key;

    return query
      select false, followers_count
      from public.collection_social_stats
      where collection_key = p_collection_key;
  else
    insert into public.user_collection_follows(user_id, collection_key)
    values (auth.uid(), p_collection_key)
    on conflict do nothing;

    insert into public.collection_social_stats(collection_key)
    values (p_collection_key)
    on conflict (collection_key) do nothing;

    update public.collection_social_stats
      set followers_count = followers_count + 1,
          updated_at = now()
    where collection_key = p_collection_key;

    return query
      select true, followers_count
      from public.collection_social_stats
      where collection_key = p_collection_key;
  end if;
end;
$$;

create or replace function public.bump_collection_engagement_v1(
  p_collection_key text,
  p_delta integer default 1
)
returns table (
  engagement_count integer
)
language plpgsql
security definer
as $$
begin
  insert into public.collection_social_stats(collection_key)
  values (p_collection_key)
  on conflict (collection_key) do nothing;

  update public.collection_social_stats
    set engagement_count = greatest(engagement_count + p_delta, 0),
        updated_at = now()
  where collection_key = p_collection_key;

  return query
    select engagement_count
    from public.collection_social_stats
    where collection_key = p_collection_key;
end;
$$;
