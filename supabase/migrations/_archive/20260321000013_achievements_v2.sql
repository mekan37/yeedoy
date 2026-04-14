create table if not exists public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  icon text not null default 'trophy',
  color text not null default '#9CA3AF',
  condition jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb,
  primary key (user_id, achievement_id)
);
create index if not exists user_achievements_user_idx
  on public.user_achievements(user_id, unlocked_at desc);
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
drop policy if exists achievements_public_read on public.achievements;
create policy achievements_public_read
on public.achievements
for select
to authenticated
using (true);
drop policy if exists user_achievements_read_own on public.user_achievements;
create policy user_achievements_read_own
on public.user_achievements
for select
to authenticated
using (user_id = auth.uid());
insert into public.achievements(id, title, description, icon, color, condition)
values
  ('first_review', 'Ilk Yorum', 'Ilk yorumunu yaz', 'comment', '#4CAF50', '{"type":"review_count","value":1}'),
  ('first_rating', 'Ilk Puan', 'Ilk mekan puanini ver', 'star', '#3B82F6', '{"type":"rating_count","value":1}'),
  ('first_discovery', 'Ilk Kesif', 'Ilk isletme goruntulemesini yap', 'place', '#F59E0B', '{"type":"business_view_count","value":1}'),
  ('traveler_10', 'Gezgin', '10 farkli mekani puanla', 'travel', '#06B6D4', '{"type":"unique_rated_business_count","value":10}'),
  ('price_hunter_5', 'Fiyat Avcisi', '5 fiyat dogrulama katkisi yap', 'price', '#10B981', '{"type":"price_verified_count","value":5}'),
  ('observer_3', 'Gozlemci', '3 menu fotografi ekle', 'photo', '#A855F7', '{"type":"menu_photo_count","value":3}'),
  ('district_gourmet_top10', 'Ilce Gurmesi', 'Ilcede ilk %10 katkiciya gir', 'crown', '#7C3AED', '{"type":"district_top_percent","value":10}'),
  ('detective_10', 'Dedektif', '10 yanlis bilgi bildirimi yap', 'detective', '#EF4444', '{"type":"wrong_info_reports_count","value":10}'),
  ('trusted_contributor', 'Guvenilir Katkici', 'Guven skoru 80 ve ustu', 'shield', '#059669', '{"type":"reputation_score","value":80}')
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  condition = excluded.condition;
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
  v_inserted boolean := false;
  v_title text;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if not v_inserted then
    return false;
  end if;

  select a.title into v_title
  from public.achievements a
  where a.id = trim(p_achievement_id);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin.',
      jsonb_build_object('achievement_id', trim(p_achievement_id))
    );
  end if;

  return true;
end;
$$;
create or replace function public.get_user_reputation_score_v2(
  p_user_id uuid
)
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_score int := 50;
  v_approved int := 0;
  v_rejected int := 0;
begin
  if p_user_id is null then
    return 0;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','accepted','handled','verified'];
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 3) - (v_rejected * 5);
  end if;

  if to_regclass('public.business_suggestions') is not null then
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','accepted'];
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 4) - (v_rejected * 6);
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','published'];
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 1) - (v_rejected * 3);
  end if;

  if v_score < 0 then v_score := 0; end if;
  if v_score > 100 then v_score := 100; end if;
  return v_score;
end;
$$;
create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews where user_id = $1'
      into v_review_count using p_user_id;
    execute
      'select count(*) from public.reviews where user_id = $1 and rating is not null'
      into v_rating_count using p_user_id;
    execute
      'select count(distinct business_id) from public.reviews where user_id = $1 and rating is not null and business_id is not null'
      into v_unique_rated_count using p_user_id;
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view'];
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos where created_by = $1'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1'
      into v_wrong_info_reports_count using p_user_id;
  end if;

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id;
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
end;
$$;
create or replace function public.get_my_achievements_v1()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
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
create or replace function public.trg_recompute_achievements_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.recompute_user_achievements_v1(new.user_id);
  return new;
end;
$$;
drop trigger if exists trg_recompute_achievements_reviews_v1 on public.reviews;
create trigger trg_recompute_achievements_reviews_v1
after insert on public.reviews
for each row
execute function public.trg_recompute_achievements_reviews_v1();
create or replace function public.trg_recompute_achievements_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.recompute_user_achievements_v1(new.created_by);
  return new;
end;
$$;
drop trigger if exists trg_recompute_achievements_price_suggestions_v1 on public.menu_item_price_suggestions;
create trigger trg_recompute_achievements_price_suggestions_v1
after insert or update of status on public.menu_item_price_suggestions
for each row
execute function public.trg_recompute_achievements_price_suggestions_v1();
do $$
begin
  if to_regclass('public.menu_item_photos') is not null then
    execute 'create or replace function public.trg_recompute_achievements_menu_photos_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        perform public.recompute_user_achievements_v1(new.created_by);
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_menu_photos_v1 on public.menu_item_photos';
    execute 'create trigger trg_recompute_achievements_menu_photos_v1
      after insert on public.menu_item_photos
      for each row
      execute function public.trg_recompute_achievements_menu_photos_v1()';
  end if;
end;
$$;
do $$
begin
  if to_regclass('public.analytics_events') is not null then
    execute 'create or replace function public.trg_recompute_achievements_analytics_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        if new.user_id is not null then
          perform public.recompute_user_achievements_v1(new.user_id);
        end if;
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_analytics_v1 on public.analytics_events';
    execute 'create trigger trg_recompute_achievements_analytics_v1
      after insert on public.analytics_events
      for each row
      execute function public.trg_recompute_achievements_analytics_v1()';
  end if;
end;
$$;
do $$
begin
  if to_regclass('public.reports') is not null then
    execute 'create or replace function public.trg_recompute_achievements_reports_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        perform public.recompute_user_achievements_v1(coalesce(new.user_id, new.reporter_user_id));
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_reports_v1 on public.reports';
    execute 'create trigger trg_recompute_achievements_reports_v1
      after insert on public.reports
      for each row
      execute function public.trg_recompute_achievements_reports_v1()';
  end if;
end;
$$;
grant execute on function public.get_my_achievements_v1() to authenticated;
