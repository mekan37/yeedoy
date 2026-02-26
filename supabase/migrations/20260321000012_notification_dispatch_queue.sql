create table if not exists public.notification_dispatch_jobs (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  status text not null default 'pending',
  attempts int not null default 0,
  last_error text,
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (notification_id)
);

create index if not exists notification_dispatch_jobs_status_idx
  on public.notification_dispatch_jobs(status, created_at asc);

create or replace function public.touch_updated_at_v1()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_notification_dispatch_jobs_touch_v1
on public.notification_dispatch_jobs;
create trigger trg_notification_dispatch_jobs_touch_v1
before update on public.notification_dispatch_jobs
for each row
execute function public.touch_updated_at_v1();

create or replace function public.enqueue_notification_dispatch_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.notification_dispatch_jobs(notification_id, status)
  values (new.id, 'pending')
  on conflict (notification_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_enqueue_notification_dispatch_v1
on public.notifications;
create trigger trg_enqueue_notification_dispatch_v1
after insert on public.notifications
for each row
execute function public.enqueue_notification_dispatch_v1();

create or replace function public.dequeue_notification_dispatch_jobs_v1(
  p_limit int default 20
)
returns table(
  job_id uuid,
  notification_id uuid,
  user_id uuid,
  type text,
  title text,
  body text,
  data jsonb
)
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if p_limit <= 0 then
    p_limit := 20;
  end if;

  return query
  with picked as (
    select j.id
    from public.notification_dispatch_jobs j
    where j.status in ('pending', 'retry')
      and coalesce(j.attempts, 0) < 8
      and (j.locked_at is null or j.locked_at < now() - interval '5 minutes')
    order by j.created_at asc
    limit p_limit
    for update skip locked
  ),
  locked as (
    update public.notification_dispatch_jobs j
    set
      status = 'processing',
      locked_at = now(),
      attempts = coalesce(j.attempts, 0) + 1
    where j.id in (select id from picked)
    returning j.id, j.notification_id
  )
  select
    l.id as job_id,
    n.id as notification_id,
    n.user_id,
    n.type,
    n.title,
    n.body,
    n.data
  from locked l
  join public.notifications n on n.id = l.notification_id;
end;
$$;

create or replace function public.complete_notification_dispatch_job_v1(
  p_job_id uuid,
  p_success boolean,
  p_error text default null
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.notification_dispatch_jobs
  set
    status = case when p_success then 'sent' else 'retry' end,
    locked_at = null,
    last_error = case when p_success then null else left(coalesce(p_error, 'dispatch_failed'), 800) end
  where id = p_job_id;

  return found;
end;
$$;
