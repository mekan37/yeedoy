alter table public.achievements
  add column if not exists xp int not null default 20;

update public.achievements
set xp = case id
  when 'first_review' then 20
  when 'first_rating' then 20
  when 'first_discovery' then 20
  when 'traveler_10' then 40
  when 'price_hunter_5' then 40
  when 'observer_3' then 40
  when 'district_gourmet_top10' then 80
  when 'detective_10' then 80
  when 'trusted_contributor' then 80
  else xp
end;

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

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp
      )
    );
  end if;

  return true;
end;
$$;

create or replace function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;
