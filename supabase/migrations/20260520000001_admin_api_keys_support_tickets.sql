-- Admin API keys and support tickets used by the Next.js admin panel.

create table if not exists public.api_keys (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) > 0 and char_length(name) <= 60),
  key_hash text not null unique,
  prefix text not null,
  scope text not null default 'read',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_used_at timestamptz,
  expires_at timestamptz,
  is_active boolean not null default true
);

create index if not exists idx_api_keys_created_at on public.api_keys(created_at desc);
create index if not exists idx_api_keys_active on public.api_keys(is_active, expires_at);
create index if not exists idx_api_keys_created_by on public.api_keys(created_by);

alter table public.api_keys enable row level security;

drop policy if exists "api_keys_admin_all" on public.api_keys;
create policy "api_keys_admin_all"
  on public.api_keys
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, insert, update on public.api_keys to authenticated;

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  requester_name text,
  requester_email text,
  subject text not null check (char_length(btrim(subject)) > 0 and char_length(subject) <= 160),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high', 'urgent')),
  category text not null default 'general',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  assigned_to uuid references auth.users(id) on delete set null
);

create index if not exists idx_support_tickets_status_created on public.support_tickets(status, created_at desc);
create index if not exists idx_support_tickets_user on public.support_tickets(user_id, created_at desc);
create index if not exists idx_support_tickets_assigned_to on public.support_tickets(assigned_to);

alter table public.support_tickets enable row level security;

drop policy if exists "support_tickets_admin_all" on public.support_tickets;
create policy "support_tickets_admin_all"
  on public.support_tickets
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, update on public.support_tickets to authenticated;

create table if not exists public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  sender text not null check (sender in ('user', 'agent')),
  message text not null check (char_length(btrim(message)) > 0 and char_length(message) <= 4000),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);

create index if not exists idx_support_ticket_messages_ticket on public.support_ticket_messages(ticket_id, created_at);
create index if not exists idx_support_ticket_messages_created_by on public.support_ticket_messages(created_by);

alter table public.support_ticket_messages enable row level security;

drop policy if exists "support_ticket_messages_admin_all" on public.support_ticket_messages;
create policy "support_ticket_messages_admin_all"
  on public.support_ticket_messages
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, insert on public.support_ticket_messages to authenticated;

create table if not exists public.bulk_op_logs (
  id uuid primary key default gen_random_uuid(),
  op_type text not null check (op_type in ('businesses', 'reviews', 'users')),
  count integer not null default 0 check (count >= 0),
  action text not null,
  operator uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_bulk_op_logs_created_at on public.bulk_op_logs(created_at desc);
create index if not exists idx_bulk_op_logs_operator on public.bulk_op_logs(operator);

alter table public.bulk_op_logs enable row level security;

drop policy if exists "bulk_op_logs_admin_all" on public.bulk_op_logs;
create policy "bulk_op_logs_admin_all"
  on public.bulk_op_logs
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, insert on public.bulk_op_logs to authenticated;
