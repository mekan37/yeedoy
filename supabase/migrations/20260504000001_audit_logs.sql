-- Migration: 20260504000001_audit_logs
-- Purpose: Create audit_logs table for tracking sensitive operations.
--          Who did what, when, on which resource.
--          Only admins can read logs; rows are inserted via service role from API.

create table if not exists public.audit_logs (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  user_id       uuid references auth.users(id) on delete set null,
  action        text not null,          -- 'media_upload', 'business_update', 'moderation_action', etc.
  resource_type text,                   -- 'business', 'menu', 'review', 'user'
  resource_id   uuid,
  old_data      jsonb,
  new_data      jsonb,
  ip_address    inet,
  user_agent    text,
  metadata      jsonb
);

alter table public.audit_logs enable row level security;

-- Only admins can read audit logs
create policy "admin_read_audit_logs"
  on public.audit_logs
  for select
  to authenticated
  using (public.is_admin());

-- No direct inserts from clients — service role only (via API)
-- (no insert policy = blocked for all JWT-authenticated clients)

-- Index for common queries
create index "idx_audit_logs_user_id"       on public.audit_logs(user_id, created_at desc);
create index "idx_audit_logs_resource"      on public.audit_logs(resource_type, resource_id, created_at desc);
create index "idx_audit_logs_created_at"    on public.audit_logs(created_at desc);
create index "idx_audit_logs_action"        on public.audit_logs(action, created_at desc);

comment on table public.audit_logs is
  'Audit trail for sensitive operations. Insert via service role only (API layer). Read by admins only.';
