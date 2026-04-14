create table if not exists public.user_profile_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_xp int not null default 0 check (total_xp >= 0),
  level int not null default 1 check (level >= 1),
  unlocked_count int not null default 0 check (unlocked_count >= 0),
  updated_at timestamptz not null default now()
);
alter table public.user_profile_progress enable row level security;
drop policy if exists user_profile_progress_read_own on public.user_profile_progress;
create policy user_profile_progress_read_own
on public.user_profile_progress
for select
to authenticated
using (user_id = auth.uid());
create or replace function public.profile_level_from_xp_v1(p_total_xp int)
returns int
language sql
immutable
as $$
  select greatest(1, (greatest(coalesce(p_total_xp, 0), 0) / 100) + 1)::int;
$$;
create or replace function public.apply_profile_xp_v1(
  p_user_id uuid,
  p_xp int
)
returns table(
  total_xp int,
  level int,
  unlocked_count int,
  leveled_up boolean
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_prev_level int;
begin
  if p_user_id is null then
    return;
  end if;

  insert into public.user_profile_progress(user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select upp.level
    into v_prev_level
  from public.user_profile_progress upp
  where upp.user_id = p_user_id
  for update;

  update public.user_profile_progress upp
  set
    total_xp = greatest(0, upp.total_xp + greatest(coalesce(p_xp, 0), 0)),
    unlocked_count = (
      select count(*)
      from public.user_achievements ua
      where ua.user_id = p_user_id
    ),
    updated_at = now()
  where upp.user_id = p_user_id;

  update public.user_profile_progress upp
  set level = public.profile_level_from_xp_v1(upp.total_xp)
  where upp.user_id = p_user_id;

  return query
  select
    upp.total_xp,
    upp.level,
    upp.unlocked_count,
    (upp.level > coalesce(v_prev_level, 1)) as leveled_up
  from public.user_profile_progress upp
  where upp.user_id = p_user_id;
end;
$$;
create or replace function public.recompute_profile_progress_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_total_xp int := 0;
  v_unlocked_count int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  select
    coalesce(sum(coalesce(a.xp, 20)), 0)::int,
    count(*)::int
  into v_total_xp, v_unlocked_count
  from public.user_achievements ua
  join public.achievements a on a.id = ua.achievement_id
  where ua.user_id = p_user_id;

  insert into public.user_profile_progress(user_id, total_xp, level, unlocked_count, updated_at)
  values (
    p_user_id,
    v_total_xp,
    public.profile_level_from_xp_v1(v_total_xp),
    v_unlocked_count,
    now()
  )
  on conflict (user_id) do update
  set
    total_xp = excluded.total_xp,
    level = excluded.level,
    unlocked_count = excluded.unlocked_count,
    updated_at = excluded.updated_at;
end;
$$;
create or replace function public.get_my_profile_progress_v1()
returns table(
  total_xp int,
  level int,
  xp_in_level int,
  next_level_xp int,
  unlocked_count int
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_total_xp int := 0;
  v_level int := 1;
  v_unlocked_count int := 0;
begin
  if v_uid is null then
    return;
  end if;

  perform public.recompute_profile_progress_v1(v_uid);

  select
    upp.total_xp,
    upp.level,
    upp.unlocked_count
  into v_total_xp, v_level, v_unlocked_count
  from public.user_profile_progress upp
  where upp.user_id = v_uid;

  return query
  select
    coalesce(v_total_xp, 0),
    coalesce(v_level, 1),
    (coalesce(v_total_xp, 0) % 100),
    100,
    coalesce(v_unlocked_count, 0);
end;
$$;
create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted int := 0;
  v_title text;
  v_xp int := 20;
  v_progress record;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false;
  end if;

  select a.title, coalesce(a.xp, 20)
    into v_title, v_xp
  from public.achievements a
  where a.id = trim(p_achievement_id);

  select *
    into v_progress
  from public.apply_profile_xp_v1(p_user_id, v_xp);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp,
        'level', coalesce(v_progress.level, 1),
        'total_xp', coalesce(v_progress.total_xp, v_xp),
        'leveled_up', coalesce(v_progress.leveled_up, false)
      )
    );
  end if;

  return true;
end;
$$;
grant execute on function public.get_my_profile_progress_v1() to authenticated;
do $$
begin
  if exists (select 1 from auth.users limit 1) then
    update public.user_profile_progress upp
    set
      total_xp = sub.total_xp,
      level = public.profile_level_from_xp_v1(sub.total_xp),
      unlocked_count = sub.unlocked_count,
      updated_at = now()
    from (
      select
        ua.user_id,
        coalesce(sum(coalesce(a.xp, 20)), 0)::int as total_xp,
        count(*)::int as unlocked_count
      from public.user_achievements ua
      join public.achievements a on a.id = ua.achievement_id
      group by ua.user_id
    ) sub
    where upp.user_id = sub.user_id;

    insert into public.user_profile_progress(user_id, total_xp, level, unlocked_count, updated_at)
    select
      sub.user_id,
      sub.total_xp,
      public.profile_level_from_xp_v1(sub.total_xp),
      sub.unlocked_count,
      now()
    from (
      select
        ua.user_id,
        coalesce(sum(coalesce(a.xp, 20)), 0)::int as total_xp,
        count(*)::int as unlocked_count
      from public.user_achievements ua
      join public.achievements a on a.id = ua.achievement_id
      group by ua.user_id
    ) sub
    on conflict (user_id) do nothing;
  end if;
end
$$;
