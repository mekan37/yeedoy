-- Auto moderation rules: low-risk auto decisions, queueing, and repeat offender strikes.

create table if not exists public.user_moderation_strikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  reason text,
  source text,
  created_at timestamptz not null default now()
);
create index if not exists idx_user_moderation_strikes_user
  on public.user_moderation_strikes(user_id, created_at desc);
create or replace function public.add_moderation_strike_v1(
  p_user_id uuid,
  p_reason text default null,
  p_source text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent int := 0;
  v_shadow boolean := false;
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user');
  end if;

  insert into public.user_moderation_strikes(user_id, reason, source)
  values (p_user_id, nullif(trim(p_reason), ''), nullif(trim(p_source), ''));

  select count(*) into v_recent
  from public.user_moderation_strikes s
  where s.user_id = p_user_id
    and s.created_at >= now() - interval '30 days';

  if v_recent >= 3 then
    update public.user_profiles
    set shadow_banned = true
    where user_id = p_user_id;
    v_shadow := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'recent_strikes_30d', v_recent,
    'shadow_banned', v_shadow
  );
end;
$$;
create or replace function public.auto_close_duplicate_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_exists boolean;
begin
  select * into v_r
  from public.reports
  where id = p_report_id;

  if v_r.id is null then return false; end if;

  select exists(
    select 1
    from public.reports
    where user_id = v_r.user_id
      and target_type = v_r.target_type
      and target_id = v_r.target_id
      and id <> v_r.id
      and created_at >= now() - interval '24 hours'
  ) into v_exists;

  if v_exists then
    update public.reports
    set
      durum = 'kapandi',
      admin_note = 'Otomatik: 24 saat içinde mükerrer bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_close_duplicate',
      'reports',
      p_report_id,
      jsonb_build_object()
    );

    return true;
  end if;

  return false;
end;
$$;
create or replace function public.auto_reject_low_quality_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_len int;
  v_uid uuid;
begin
  select length(coalesce(details,'')), user_id into v_len, v_uid
  from public.reports
  where id = p_report_id;

  if v_len < 15 then
    update public.reports
    set
      durum = 'reddedildi',
      admin_note = 'Otomatik: çok kısa / düşük kaliteli bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_reject_low_quality',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len)
    );

    perform public.add_moderation_strike_v1(
      v_uid,
      'low_quality_report',
      'report'
    );

    return true;
  end if;

  return false;
end;
$$;
create or replace function public.auto_queue_grey_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_len int;
begin
  select * into v_r
  from public.reports
  where id = p_report_id;
  v_len := length(coalesce(v_r.details, ''));

  if v_r.id is null then return false; end if;

  if v_r.durum in ('kapandi','reddedildi') then
    return false;
  end if;

  if v_len >= 15 and v_len <= 200 and v_r.reason not in ('spam','duplicate') then
    update public.reports
    set
      durum = 'inceleniyor',
      admin_note = 'Otomatik: gri alan, kuyruğa alındı',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_queue_grey',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len, 'reason', v_r.reason)
    );

    return true;
  end if;

  return false;
end;
$$;
create or replace function public.apply_auto_moderation_rules_v1(p_target text, p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_applied boolean := false;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_target = 'report' then
    v_applied := public.auto_close_duplicate_report_v1(p_id)
                 or public.auto_reject_low_quality_report_v1(p_id)
                 or public.auto_queue_grey_report_v1(p_id);
  elsif p_target = 'claim' then
    v_applied := public.auto_approve_trusted_owner_claim_v1(p_id);
  end if;

  return jsonb_build_object('ok', true, 'applied', v_applied);
end;
$$;
create or replace function public.trg_auto_moderate_report_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.auto_close_duplicate_report_v1(new.id);
  perform public.auto_reject_low_quality_report_v1(new.id);
  perform public.auto_queue_grey_report_v1(new.id);
  return new;
end;
$$;
drop trigger if exists trg_auto_moderate_report on public.reports;
create trigger trg_auto_moderate_report
after insert on public.reports
for each row
execute function public.trg_auto_moderate_report_v1();
