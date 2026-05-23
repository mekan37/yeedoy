-- P1: Loyalty / Points Program

-- Program definition per business
create table if not exists public.loyalty_programs (
  business_id          uuid primary key references public.businesses(id) on delete cascade,
  is_active            boolean default false not null,
  checkin_points       int default 10 not null,
  review_points        int default 25 not null,
  photo_points         int default 15 not null,
  reward_threshold_pts int default 500 not null,
  reward_type          text default 'discount_pct' not null check (reward_type in ('discount_pct', 'free_item')),
  reward_value         int default 10 not null,   -- pct for discount_pct, 0 for free_item
  birthday_bonus_pts   int default 50 not null,
  created_at           timestamptz default now()
);

-- Per-user account per business
create table if not exists public.loyalty_accounts (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid not null references public.businesses(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  points           int default 0 not null,
  lifetime_points  int default 0 not null,
  redeemed_points  int default 0 not null,
  updated_at       timestamptz default now(),
  unique (business_id, user_id)
);

create index if not exists idx_loyalty_accounts_user on public.loyalty_accounts(user_id);
create index if not exists idx_loyalty_accounts_biz  on public.loyalty_accounts(business_id);

alter table public.loyalty_programs enable row level security;
alter table public.loyalty_accounts  enable row level security;

-- Owner and admins can read/write programs
create policy "loyalty_programs_owner_all"
  on public.loyalty_programs for all
  using (
    public.is_admin() or public.is_owner_of_business(business_id)
  );

-- Anon/user read program config
create policy "loyalty_programs_public_read"
  on public.loyalty_programs for select
  using (true);

-- Users can read their own accounts
create policy "loyalty_accounts_self_read"
  on public.loyalty_accounts for select
  using (auth.uid() = user_id);

-- Only service-role / definer functions can write accounts
create policy "loyalty_accounts_definer_write"
  on public.loyalty_accounts for all
  using (auth.uid() = user_id);

-- Award points function (called from triggers or owner events)
create or replace function public.award_loyalty_points_v1(
  p_business_id uuid,
  p_user_id     uuid,
  p_points      int
)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_active boolean;
begin
  -- Only award if program is active
  select is_active into v_active
  from public.loyalty_programs
  where business_id = p_business_id;

  if not found or not coalesce(v_active, false) then
    return;
  end if;

  if p_points <= 0 then return; end if;

  insert into public.loyalty_accounts (business_id, user_id, points, lifetime_points, updated_at)
  values (p_business_id, p_user_id, p_points, p_points, now())
  on conflict (business_id, user_id) do update set
    points          = loyalty_accounts.points + excluded.points,
    lifetime_points = loyalty_accounts.lifetime_points + excluded.lifetime_points,
    updated_at      = now();
end;
$$;

-- Trigger: award review points
create or replace function public.trg_award_loyalty_on_review()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_pts int;
begin
  if NEW.status = 'approved' and (OLD.status is null or OLD.status <> 'approved') then
    select review_points into v_pts
    from public.loyalty_programs
    where business_id = NEW.business_id;

    if found and v_pts > 0 then
      perform public.award_loyalty_points_v1(NEW.business_id, NEW.user_id, v_pts);
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_loyalty_review on public.reviews;
create trigger trg_loyalty_review
  after insert or update of status on public.reviews
  for each row execute procedure public.trg_award_loyalty_on_review();

-- Trigger: award check-in points
create or replace function public.trg_award_loyalty_on_checkin()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_pts int;
begin
  select checkin_points into v_pts
  from public.loyalty_programs
  where business_id = NEW.business_id;

  if found and v_pts > 0 then
    perform public.award_loyalty_points_v1(NEW.business_id, NEW.user_id, v_pts);
  end if;
  return NEW;
end;
$$;

-- Note: requires business_checkins table to exist
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema='public' and table_name='business_checkins') then
    drop trigger if exists trg_loyalty_checkin on public.business_checkins;
    create trigger trg_loyalty_checkin
      after insert on public.business_checkins
      for each row execute procedure public.trg_award_loyalty_on_checkin();
  end if;
end $$;

-- RPC: get loyalty status for current user + business
create or replace function public.get_loyalty_status_v1(
  p_business_id uuid
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'is_active',           lp.is_active,
        'reward_threshold_pts', lp.reward_threshold_pts,
        'reward_type',          lp.reward_type,
        'reward_value',         lp.reward_value,
        'checkin_points',       lp.checkin_points,
        'review_points',        lp.review_points,
        'photo_points',         lp.photo_points,
        'points',               coalesce(la.points, 0),
        'lifetime_points',      coalesce(la.lifetime_points, 0),
        'redeemed_points',      coalesce(la.redeemed_points, 0),
        'progress_pct',
          case when lp.reward_threshold_pts > 0
               then least(100, round(coalesce(la.points, 0) * 100.0 / lp.reward_threshold_pts))
               else 0
          end
      )
      from public.loyalty_programs lp
      left join public.loyalty_accounts la
             on la.business_id = lp.business_id
            and la.user_id = auth.uid()
      where lp.business_id = p_business_id
    ),
    jsonb_build_object(
      'is_active', false,
      'points', 0,
      'lifetime_points', 0,
      'redeemed_points', 0,
      'progress_pct', 0,
      'reward_threshold_pts', 0
    )
  );
$$;

-- RPC: get all loyalty accounts for current user
drop function if exists public.get_my_loyalty_cards_v1();
create or replace function public.get_my_loyalty_cards_v1()
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'business_id',          la.business_id,
        'business_name',        b.name,
        'logo_url',             b.logo_url,
        'points',               la.points,
        'lifetime_points',      la.lifetime_points,
        'reward_threshold_pts', lp.reward_threshold_pts,
        'reward_type',          lp.reward_type,
        'reward_value',         lp.reward_value,
        'progress_pct',
          case when lp.reward_threshold_pts > 0
               then least(100, round(la.points * 100.0 / lp.reward_threshold_pts))
               else 0
          end
      )
      order by la.points desc
    ),
    '[]'::jsonb
  )
  from public.loyalty_accounts la
  join public.loyalty_programs lp  on lp.business_id = la.business_id and lp.is_active = true
  join public.businesses b          on b.id = la.business_id
  where la.user_id = auth.uid()
    and la.points > 0;
$$;

-- Owner RPC: upsert loyalty program config
create or replace function public.upsert_loyalty_program_v1(
  p_business_id          uuid,
  p_is_active            boolean,
  p_checkin_points       int default 10,
  p_review_points        int default 25,
  p_photo_points         int default 15,
  p_reward_threshold_pts int default 500,
  p_reward_type          text default 'discount_pct',
  p_reward_value         int default 10
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    raise exception 'not_authorized';
  end if;

  insert into public.loyalty_programs (
    business_id, is_active, checkin_points, review_points, photo_points,
    reward_threshold_pts, reward_type, reward_value
  ) values (
    p_business_id, p_is_active, p_checkin_points, p_review_points, p_photo_points,
    p_reward_threshold_pts, p_reward_type, p_reward_value
  )
  on conflict (business_id) do update set
    is_active            = excluded.is_active,
    checkin_points       = excluded.checkin_points,
    review_points        = excluded.review_points,
    photo_points         = excluded.photo_points,
    reward_threshold_pts = excluded.reward_threshold_pts,
    reward_type          = excluded.reward_type,
    reward_value         = excluded.reward_value;
end;
$$;

-- Owner RPC: top 10 loyal customers
create or replace function public.get_business_loyal_customers_v1(
  p_business_id uuid,
  p_limit int default 10
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id',          la.user_id,
        'display_name',     coalesce(p.display_name, 'Kullanıcı'),
        'avatar_url',       p.avatar_url,
        'points',           la.points,
        'lifetime_points',  la.lifetime_points
      )
      order by la.lifetime_points desc
    ),
    '[]'::jsonb
  )
  from public.loyalty_accounts la
  left join public.profiles p on p.id = la.user_id
  where la.business_id = p_business_id
  limit greatest(p_limit, 1);
$$;

grant execute on function public.get_loyalty_status_v1(uuid)                   to authenticated;
grant execute on function public.get_my_loyalty_cards_v1()                      to authenticated;
grant execute on function public.upsert_loyalty_program_v1(uuid, boolean, int, int, int, int, text, int) to authenticated;
grant execute on function public.get_business_loyal_customers_v1(uuid, int)     to authenticated;
grant execute on function public.award_loyalty_points_v1(uuid, uuid, int)       to service_role;
