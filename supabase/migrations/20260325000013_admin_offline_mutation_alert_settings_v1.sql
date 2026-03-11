begin;

create table if not exists public.admin_runtime_settings (
  key text primary key,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

alter table public.admin_runtime_settings enable row level security;

drop policy if exists admin_runtime_settings_admin_all
on public.admin_runtime_settings;
create policy admin_runtime_settings_admin_all
on public.admin_runtime_settings
for all
using (public.is_admin())
with check (public.is_admin());

create or replace function public.admin_get_offline_mutation_alert_settings_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_settings jsonb;
  v_defaults jsonb := jsonb_build_object(
    'min_signal_count', 8,
    'retry_rate_warning_threshold', 0.15,
    'retry_rate_alarm_threshold', 0.35,
    'drop_rate_warning_threshold', 0.08,
    'drop_rate_alarm_threshold', 0.15,
    'attention_warning_count', 4,
    'auth_alarm_count', 3,
    'server_alarm_count', 3,
    'rate_limit_warning_count', 4,
    'warning_escalation_windows', 2,
    'alarm_escalation_windows', 2
  );
begin
  if not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select settings
    into v_settings
  from public.admin_runtime_settings
  where key = 'offline_mutation_alerts_v1';

  return coalesce(v_settings, v_defaults);
end;
$$;

create or replace function public.admin_set_offline_mutation_alert_settings_v1(
  p_settings jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_raw jsonb := coalesce(p_settings, '{}'::jsonb);
  v_retry_warning numeric := least(greatest(coalesce((v_raw ->> 'retry_rate_warning_threshold')::numeric, 0.15), 0), 1);
  v_retry_alarm numeric := least(greatest(coalesce((v_raw ->> 'retry_rate_alarm_threshold')::numeric, 0.35), v_retry_warning), 1);
  v_drop_warning numeric := least(greatest(coalesce((v_raw ->> 'drop_rate_warning_threshold')::numeric, 0.08), 0), 1);
  v_drop_alarm numeric := least(greatest(coalesce((v_raw ->> 'drop_rate_alarm_threshold')::numeric, 0.15), v_drop_warning), 1);
  v_settings jsonb;
begin
  if not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  v_settings := jsonb_build_object(
    'min_signal_count', greatest(coalesce((v_raw ->> 'min_signal_count')::integer, 8), 1),
    'retry_rate_warning_threshold', v_retry_warning,
    'retry_rate_alarm_threshold', v_retry_alarm,
    'drop_rate_warning_threshold', v_drop_warning,
    'drop_rate_alarm_threshold', v_drop_alarm,
    'attention_warning_count', greatest(coalesce((v_raw ->> 'attention_warning_count')::integer, 4), 1),
    'auth_alarm_count', greatest(coalesce((v_raw ->> 'auth_alarm_count')::integer, 3), 1),
    'server_alarm_count', greatest(coalesce((v_raw ->> 'server_alarm_count')::integer, 3), 1),
    'rate_limit_warning_count', greatest(coalesce((v_raw ->> 'rate_limit_warning_count')::integer, 4), 1),
    'warning_escalation_windows', greatest(coalesce((v_raw ->> 'warning_escalation_windows')::integer, 2), 1),
    'alarm_escalation_windows', greatest(coalesce((v_raw ->> 'alarm_escalation_windows')::integer, 2), 1)
  );

  insert into public.admin_runtime_settings (
    key,
    settings,
    updated_at,
    updated_by
  )
  values (
    'offline_mutation_alerts_v1',
    v_settings,
    now(),
    auth.uid()
  )
  on conflict (key)
  do update set
    settings = excluded.settings,
    updated_at = excluded.updated_at,
    updated_by = excluded.updated_by;

  return v_settings;
end;
$$;

grant all on table public.admin_runtime_settings to authenticated;
grant all on table public.admin_runtime_settings to service_role;

grant all on function public.admin_get_offline_mutation_alert_settings_v1()
to authenticated;
grant all on function public.admin_get_offline_mutation_alert_settings_v1()
to service_role;

grant all on function public.admin_set_offline_mutation_alert_settings_v1(jsonb)
to authenticated;
grant all on function public.admin_set_offline_mutation_alert_settings_v1(jsonb)
to service_role;

commit;
