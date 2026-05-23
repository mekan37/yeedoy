-- M3: Scheduled menu auto-activation via pg_cron
-- Runs every 15 minutes: activates menus whose activeFrom has passed,
-- archives menus whose activeTo has passed.

-- ── Helper function ─────────────────────────────────────────────────────────

create or replace function public.scheduled_menu_activation()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _now timestamptz := now();
begin
  -- draft → published: activeFrom has passed, activeTo not yet reached (or null)
  update public.menus
  set
    status     = 'published',
    updated_at = _now
  where
    status      = 'draft'
    and active_from is not null
    and active_from <= _now
    and (active_to is null or active_to > _now);

  -- published → archived: activeTo has passed
  update public.menus
  set
    status     = 'archived',
    updated_at = _now
  where
    status    = 'published'
    and active_to is not null
    and active_to <= _now;
end;
$$;

-- ── pg_cron job (requires pg_cron extension to be enabled in Supabase) ──────
-- Enable extension if not already enabled:
create extension if not exists pg_cron with schema extensions;

-- Remove old job if exists, then re-create
select cron.unschedule('scheduled-menu-activation')
where exists (
  select 1 from cron.job where jobname = 'scheduled-menu-activation'
);

select cron.schedule(
  'scheduled-menu-activation',
  '*/15 * * * *',                 -- every 15 minutes
  $cron$select public.scheduled_menu_activation();$cron$
);
