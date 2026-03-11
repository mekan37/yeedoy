create table if not exists public.owner_onboarding_progress (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  step_completed int not null default 0,
  updated_at timestamptz not null default now(),
  check (step_completed >= 0 and step_completed <= 5)
);
alter table public.owner_onboarding_progress enable row level security;
-- Ensure owners/admins can read/write onboarding progress
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_read'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_read ON public.owner_onboarding_progress
      FOR SELECT USING (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_write'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_write ON public.owner_onboarding_progress
      FOR INSERT WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_update'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_update ON public.owner_onboarding_progress
      FOR UPDATE USING (public.is_admin() OR public.is_owner_of_business(business_id))
      WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;
END $$;
-- Business hours RLS for owners/admins (if missing)
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_read'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_read ON public.business_hours
      FOR SELECT USING (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_write'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_write ON public.business_hours
      FOR INSERT WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_update'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_update ON public.business_hours
      FOR UPDATE USING (public.is_admin() OR public.is_owner_of_business(business_id))
      WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;
END $$;
create or replace function public.get_owner_onboarding_progress_v1(
  p_business_id uuid
)
returns table(step_completed int, updated_at timestamptz)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select p.step_completed, p.updated_at
  from public.owner_onboarding_progress p
  where p.business_id = p_business_id
    and (public.is_admin() or public.is_owner_of_business(p_business_id));
$function$;
create or replace function public.owner_set_onboarding_progress_v1(
  p_business_id uuid,
  p_step_completed int
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_step int;
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_step := least(greatest(coalesce(p_step_completed, 0), 0), 5);

  insert into public.owner_onboarding_progress(business_id, step_completed, updated_at)
  values (p_business_id, v_step, now())
  on conflict (business_id) do update
    set step_completed = greatest(owner_onboarding_progress.step_completed, excluded.step_completed),
        updated_at = now();

  return jsonb_build_object('ok', true, 'step_completed', v_step);
end;
$function$;
create or replace function public.owner_update_business_profile_v1(
  p_business_id uuid,
  p_logo_url text default null,
  p_cover_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.businesses
  set
    logo_url = nullif(trim(p_logo_url), ''),
    cover_url = nullif(trim(p_cover_url), '')
  where id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.owner_upsert_business_hours_v1(
  p_business_id uuid,
  p_open time,
  p_close time
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_open is null or p_close is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Hours required');
  end if;

  insert into public.business_hours(
    business_id,
    mon_open, mon_close,
    tue_open, tue_close,
    wed_open, wed_close,
    thu_open, thu_close,
    fri_open, fri_close,
    sat_open, sat_close,
    sun_open, sun_close,
    updated_at
  )
  values (
    p_business_id,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    now()
  )
  on conflict (business_id) do update
    set
      mon_open = excluded.mon_open,
      mon_close = excluded.mon_close,
      tue_open = excluded.tue_open,
      tue_close = excluded.tue_close,
      wed_open = excluded.wed_open,
      wed_close = excluded.wed_close,
      thu_open = excluded.thu_open,
      thu_close = excluded.thu_close,
      fri_open = excluded.fri_open,
      fri_close = excluded.fri_close,
      sat_open = excluded.sat_open,
      sat_close = excluded.sat_close,
      sun_open = excluded.sun_open,
      sun_close = excluded.sun_close,
      updated_at = now();

  return jsonb_build_object('ok', true);
end;
$function$;
