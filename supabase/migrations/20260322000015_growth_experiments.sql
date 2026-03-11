begin;
create table if not exists public.runtime_experiments (
  key text primary key,
  enabled boolean not null default false,
  variants jsonb not null default '{}'::jsonb,
  allowed_regions text[] not null default '{}',
  blocked_regions text[] not null default '{}',
  updated_by uuid null,
  updated_at timestamptz not null default now()
);
alter table public.runtime_experiments enable row level security;
drop policy if exists runtime_experiments_select_all on public.runtime_experiments;
create policy runtime_experiments_select_all
on public.runtime_experiments
for select
to authenticated, anon
using (true);
drop policy if exists runtime_experiments_admin_write on public.runtime_experiments;
create policy runtime_experiments_admin_write
on public.runtime_experiments
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));
insert into public.runtime_experiments (key, enabled, variants)
values
  ('home_category_layout', true, '{"horizontal":50,"grid2x4":50}'::jsonb),
  ('verify_price_cta_placement', true, '{"bottom":50,"top":50}'::jsonb)
on conflict (key) do nothing;
create or replace function public.get_runtime_experiments_v1(
  p_user_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_payload jsonb := '{}'::jsonb;
begin
  select coalesce(
    jsonb_object_agg(
      e.key,
      jsonb_build_object(
        'enabled', e.enabled,
        'variants', e.variants,
        'allowed_regions', e.allowed_regions,
        'blocked_regions', e.blocked_regions
      )
    ),
    '{}'::jsonb
  )
  into v_payload
  from public.runtime_experiments e;
  return v_payload;
end;
$$;
grant execute on function public.get_runtime_experiments_v1(uuid) to anon, authenticated;
commit;
