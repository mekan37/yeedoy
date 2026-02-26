begin;

create table if not exists public.runtime_release_controls (
  id boolean primary key default true check (id = true),
  global_kill_switch boolean not null default false,
  updated_by uuid null,
  updated_at timestamptz not null default now()
);

insert into public.runtime_release_controls (id, global_kill_switch)
values (true, false)
on conflict (id) do nothing;

create table if not exists public.runtime_feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent int not null default 100 check (rollout_percent between 0 and 100),
  allowed_regions text[] not null default '{}',
  blocked_regions text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  updated_by uuid null,
  updated_at timestamptz not null default now()
);

alter table public.runtime_release_controls enable row level security;
alter table public.runtime_feature_flags enable row level security;

drop policy if exists runtime_release_controls_select_all on public.runtime_release_controls;
create policy runtime_release_controls_select_all
on public.runtime_release_controls
for select
to authenticated, anon
using (true);

drop policy if exists runtime_release_controls_admin_write on public.runtime_release_controls;
create policy runtime_release_controls_admin_write
on public.runtime_release_controls
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

drop policy if exists runtime_feature_flags_select_all on public.runtime_feature_flags;
create policy runtime_feature_flags_select_all
on public.runtime_feature_flags
for select
to authenticated, anon
using (true);

drop policy if exists runtime_feature_flags_admin_write on public.runtime_feature_flags;
create policy runtime_feature_flags_admin_write
on public.runtime_feature_flags
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

create or replace function public.get_runtime_feature_flags_v1(
  p_user_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_global_kill boolean := false;
  v_flags jsonb := '{}'::jsonb;
begin
  select coalesce(rc.global_kill_switch, false)
    into v_global_kill
  from public.runtime_release_controls rc
  where rc.id = true
  limit 1;

  select coalesce(
    jsonb_object_agg(
      rf.key,
      jsonb_build_object(
        'enabled', rf.enabled,
        'rollout_percent', rf.rollout_percent,
        'allowed_regions', rf.allowed_regions,
        'blocked_regions', rf.blocked_regions
      )
    ),
    '{}'::jsonb
  )
  into v_flags
  from public.runtime_feature_flags rf;

  return jsonb_build_object(
    'global_kill_switch', v_global_kill,
    'flags', v_flags
  );
end;
$$;

grant execute on function public.get_runtime_feature_flags_v1(uuid) to anon, authenticated;

commit;
