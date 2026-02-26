-- URL-only embeds storage for users/businesses
create table if not exists public.embeds (
  id uuid primary key default gen_random_uuid(),
  owner_type text not null check (owner_type in ('user', 'business')),
  owner_id uuid not null,
  provider text not null check (provider in ('youtube', 'instagram', 'facebook', 'unknown')),
  url_raw text not null,
  url_normalized text not null,
  title text null,
  thumbnail_url text null,
  created_at timestamptz not null default now(),
  created_by uuid null references auth.users(id) on delete set null
);

create index if not exists embeds_owner_created_idx
  on public.embeds (owner_type, owner_id, created_at desc);

create index if not exists embeds_provider_created_idx
  on public.embeds (provider, created_at desc);

create unique index if not exists embeds_owner_url_normalized_uniq
  on public.embeds (owner_type, owner_id, url_normalized);

alter table public.embeds enable row level security;

drop policy if exists embeds_select_public on public.embeds;
create policy embeds_select_public
  on public.embeds
  for select
  using (true);

drop policy if exists embeds_insert_user_self on public.embeds;
create policy embeds_insert_user_self
  on public.embeds
  for insert
  with check (
    auth.uid() is not null
    and owner_type = 'user'
    and owner_id = auth.uid()
    and created_by = auth.uid()
  );

drop policy if exists embeds_insert_business_owner_admin on public.embeds;
create policy embeds_insert_business_owner_admin
  on public.embeds
  for insert
  with check (
    auth.uid() is not null
    and owner_type = 'business'
    and created_by = auth.uid()
    and (public.is_admin() or public.is_owner_of_business(owner_id))
  );

drop policy if exists embeds_update_owner_admin on public.embeds;
create policy embeds_update_owner_admin
  on public.embeds
  for update
  using (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  )
  with check (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  );

drop policy if exists embeds_delete_owner_admin on public.embeds;
create policy embeds_delete_owner_admin
  on public.embeds
  for delete
  using (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  );

grant select on public.embeds to anon, authenticated;
grant insert, update, delete on public.embeds to authenticated;
grant all on public.embeds to service_role;
