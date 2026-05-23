-- ── P4: Otomatik Tetikleyici Kampanyalar ─────────────────────────────────────

-- Business automation settings table
create table if not exists public.business_automations (
  id                     uuid primary key default gen_random_uuid(),
  business_id            uuid not null references public.businesses(id) on delete cascade,
  type                   text not null, -- 'missed_you' | 'birthday' | 'reward_threshold'
  is_active              boolean not null default true,
  custom_message         text,          -- overrides default message when set
  last_run_at            timestamptz,
  last_run_count         int not null default 0,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  unique (business_id, type)
);

alter table public.business_automations enable row level security;

create policy "owner_manage_automations"
  on public.business_automations for all
  using (
    exists (
      select 1 from public.business_claims bc
      where bc.business_id = business_automations.business_id
        and bc.user_id = auth.uid()
        and bc.status = 'approved'
    )
  )
  with check (
    exists (
      select 1 from public.business_claims bc
      where bc.business_id = business_automations.business_id
        and bc.user_id = auth.uid()
        and bc.status = 'approved'
    )
  );

-- Get automations for a business
create or replace function public.get_business_automations_v1(p_business_id uuid)
returns jsonb
language sql stable security definer
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id',               id,
      'type',             type,
      'is_active',        is_active,
      'custom_message',   custom_message,
      'last_run_at',      last_run_at,
      'last_run_count',   last_run_count
    )
    order by type
  ), '[]'::jsonb)
  from public.business_automations
  where business_id = p_business_id
$$;

grant execute on function public.get_business_automations_v1 to authenticated;

-- Upsert automation toggle
create or replace function public.upsert_business_automation_v1(
  p_business_id    uuid,
  p_type           text,
  p_is_active      boolean,
  p_custom_message text default null
)
returns void
language plpgsql security definer
as $$
begin
  if not exists (
    select 1 from public.business_claims
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'approved'
  ) then
    raise exception 'not_authorized';
  end if;

  insert into public.business_automations (business_id, type, is_active, custom_message, updated_at)
  values (p_business_id, p_type, p_is_active, p_custom_message, now())
  on conflict (business_id, type) do update set
    is_active      = excluded.is_active,
    custom_message = excluded.custom_message,
    updated_at     = now();
end;
$$;

grant execute on function public.upsert_business_automation_v1 to authenticated;

-- ── Core automation runner (called by pg_cron) ───────────────────────────────

create or replace function public.run_loyalty_automations_v1()
returns void
language plpgsql security definer
as $$
declare
  v_biz        record;
  v_auto       record;
  v_count      int;
  v_cutoff     timestamptz;
begin
  -- Iterate all active businesses that have loyalty programs
  for v_biz in
    select lp.business_id, lp.points_per_review, lp.birthday_bonus_pts, lp.reward_threshold_pts
    from public.loyalty_programs lp
    where lp.is_active = true
  loop
    -- ── "Sizi özledik" (missed_you) ─────────────────────────────────────────
    select * into v_auto
    from public.business_automations
    where business_id = v_biz.business_id and type = 'missed_you' and is_active = true;

    if found then
      v_cutoff := now() - interval '30 days';
      v_count := 0;

      -- Queue push notifications for followers inactive 30+ days
      with inactive_followers as (
        select bf.follower_id
        from public.business_follows bf
        where bf.business_id = v_biz.business_id
          and not exists (
            select 1 from public.reviews r
            where r.user_id = bf.follower_id
              and r.business_id = v_biz.business_id
              and r.created_at >= v_cutoff
          )
          and not exists (
            select 1 from public.push_notifications pn
            where pn.user_id = bf.follower_id
              and pn.type = 'missed_you_automation'
              and pn.business_id = v_biz.business_id
              and pn.created_at >= now() - interval '30 days'
          )
        limit 500
      )
      insert into public.push_notifications (user_id, business_id, type, title, body)
      select
        f.follower_id,
        v_biz.business_id,
        'missed_you_automation',
        coalesce(
          (select b.name from public.businesses b where b.id = v_biz.business_id),
          'Yeedoy'
        ),
        coalesce(
          v_auto.custom_message,
          'Sizi özledik! Bizi ziyaret edin.'
        )
      from inactive_followers f;

      get diagnostics v_count = row_count;

      update public.business_automations set
        last_run_at = now(), last_run_count = v_count
      where business_id = v_biz.business_id and type = 'missed_you';
    end if;

    -- ── "Doğum günü" bonus points ────────────────────────────────────────────
    select * into v_auto
    from public.business_automations
    where business_id = v_biz.business_id and type = 'birthday' and is_active = true;

    if found and v_biz.birthday_bonus_pts > 0 then
      v_count := 0;

      with birthday_followers as (
        select la.user_id, la.id as account_id
        from public.loyalty_accounts la
        join public.profiles p on p.id = la.user_id
        where la.business_id = v_biz.business_id
          and p.birth_date is not null
          and extract(month from p.birth_date) = extract(month from now())
          and extract(day   from p.birth_date) = extract(day   from now())
          and not exists (
            select 1 from public.push_notifications pn
            where pn.user_id = la.user_id
              and pn.business_id = v_biz.business_id
              and pn.type = 'birthday_bonus'
              and date_trunc('day', pn.created_at) = date_trunc('day', now())
          )
      )
      update public.loyalty_accounts la set
        points = la.points + v_biz.birthday_bonus_pts
      from birthday_followers bf
      where la.id = bf.account_id;

      get diagnostics v_count = row_count;

      -- Queue birthday push
      insert into public.push_notifications (user_id, business_id, type, title, body)
      select
        la.user_id,
        v_biz.business_id,
        'birthday_bonus',
        coalesce(
          (select b.name from public.businesses b where b.id = v_biz.business_id),
          'Yeedoy'
        ),
        coalesce(
          v_auto.custom_message,
          format('İyi doğum günleri! %s puan hediye edildi.', v_biz.birthday_bonus_pts)
        )
      from public.loyalty_accounts la
      join public.profiles p on p.id = la.user_id
      where la.business_id = v_biz.business_id
        and p.birth_date is not null
        and extract(month from p.birth_date) = extract(month from now())
        and extract(day   from p.birth_date) = extract(day   from now())
        and not exists (
          select 1 from public.push_notifications pn
          where pn.user_id = la.user_id
            and pn.business_id = v_biz.business_id
            and pn.type = 'birthday_bonus'
            and date_trunc('day', pn.created_at) = date_trunc('day', now())
        );

      update public.business_automations set
        last_run_at = now(), last_run_count = v_count
      where business_id = v_biz.business_id and type = 'birthday';
    end if;

    -- ── "Ödül eşiği yaklaşıyor" (%80) ────────────────────────────────────────
    select * into v_auto
    from public.business_automations
    where business_id = v_biz.business_id and type = 'reward_threshold' and is_active = true;

    if found and v_biz.reward_threshold_pts > 0 then
      v_count := 0;

      insert into public.push_notifications (user_id, business_id, type, title, body)
      select
        la.user_id,
        v_biz.business_id,
        'reward_threshold_reminder',
        coalesce(
          (select b.name from public.businesses b where b.id = v_biz.business_id),
          'Yeedoy'
        ),
        coalesce(
          v_auto.custom_message,
          format(
            'Ödülünüze yaklaştınız! %s / %s puan.',
            la.points,
            v_biz.reward_threshold_pts
          )
        )
      from public.loyalty_accounts la
      where la.business_id = v_biz.business_id
        and la.points >= (v_biz.reward_threshold_pts * 0.8)
        and la.points < v_biz.reward_threshold_pts
        and not exists (
          select 1 from public.push_notifications pn
          where pn.user_id = la.user_id
            and pn.business_id = v_biz.business_id
            and pn.type = 'reward_threshold_reminder'
            and pn.created_at >= now() - interval '7 days'
        );

      get diagnostics v_count = row_count;

      update public.business_automations set
        last_run_at = now(), last_run_count = v_count
      where business_id = v_biz.business_id and type = 'reward_threshold';
    end if;
  end loop;
end;
$$;

-- Schedule: every night at 09:00 UTC
select cron.schedule(
  'loyalty-automations-daily',
  '0 9 * * *',
  $$select public.run_loyalty_automations_v1()$$
);
