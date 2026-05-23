-- G4: Rate limit table for AI Edge Functions (per-user, sliding window)

create table if not exists public.rate_limit_buckets (
  key        text primary key,
  count      int not null default 1,
  window_end timestamptz not null default (now() + interval '1 hour')
);

alter table public.rate_limit_buckets enable row level security;
-- No RLS policies: only service role (via Edge Functions) can read/write.

-- Cleanup: remove expired buckets older than 2 hours to prevent table bloat.
create or replace function public.purge_rate_limit_buckets_v1()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.rate_limit_buckets where window_end < now() - interval '1 hour';
$$;

-- Core rate limit check: increments counter and returns whether under the limit.
create or replace function public.check_rate_limit_v1(
  p_key     text,
  p_max     int,
  p_window  interval default '1 hour'
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  -- Purge expired bucket for this key
  delete from public.rate_limit_buckets where key = p_key and window_end < now();

  insert into public.rate_limit_buckets(key, count, window_end)
  values (p_key, 1, now() + p_window)
  on conflict (key) do update
    set count = rate_limit_buckets.count + 1
  returning count into v_count;

  return v_count <= p_max;
end;
$$;

grant execute on function public.check_rate_limit_v1(text, int, interval) to service_role;
grant execute on function public.purge_rate_limit_buckets_v1() to service_role;
