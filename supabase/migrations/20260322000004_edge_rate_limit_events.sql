begin;
create table if not exists public.edge_rate_limit_events (
  id bigserial primary key,
  action text not null,
  user_id uuid null,
  ip_hash text not null,
  scope text null,
  created_at timestamptz not null default now()
);
create index if not exists idx_edge_rate_limit_events_action_user_created
  on public.edge_rate_limit_events (action, user_id, created_at desc);
create index if not exists idx_edge_rate_limit_events_action_ip_created
  on public.edge_rate_limit_events (action, ip_hash, created_at desc);
create index if not exists idx_edge_rate_limit_events_action_user_scope_created
  on public.edge_rate_limit_events (action, user_id, scope, created_at desc)
  where scope is not null;
alter table public.edge_rate_limit_events enable row level security;
drop policy if exists edge_rate_limit_events_admin_all on public.edge_rate_limit_events;
create policy edge_rate_limit_events_admin_all
  on public.edge_rate_limit_events
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
commit;
