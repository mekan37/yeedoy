-- AI Menu Analysis v1
-- Tables: allergen_definitions, menu_ocr_jobs, menu_item_ai_analysis
-- RPCs: create_menu_ocr_job_v1, update_menu_ocr_job_v1, list_menu_ocr_jobs_v1,
--        list_menu_ai_analysis_v1, approve_menu_ai_analysis_v1, reject_menu_ai_analysis_v1

-- ─────────────────────────────────────────
-- allergen_definitions (seed data, admin-only write)
-- ─────────────────────────────────────────
create table if not exists public.allergen_definitions (
  code        text primary key,
  display_tr  text not null,
  display_en  text not null,
  icon_name   text not null default 'warning_amber_outlined',
  created_at  timestamptz not null default now()
);

insert into public.allergen_definitions (code, display_tr, display_en, icon_name) values
  ('gluten',       'Gluten',                   'Gluten',            'grain'),
  ('crustaceans',  'Kabuklu deniz ürünleri',   'Crustaceans',       'set_meal'),
  ('eggs',         'Yumurta',                  'Eggs',              'egg_alt_outlined'),
  ('fish',         'Balık',                    'Fish',              'set_meal'),
  ('peanuts',      'Yer fıstığı',              'Peanuts',           'eco_outlined'),
  ('soybeans',     'Soya',                     'Soybeans',          'eco_outlined'),
  ('milk',         'Süt',                      'Milk / Dairy',      'local_drink_outlined'),
  ('nuts',         'Sert kabuklu yemişler',    'Tree Nuts',         'eco_outlined'),
  ('celery',       'Kereviz',                  'Celery',            'eco_outlined'),
  ('mustard',      'Hardal',                   'Mustard',           'eco_outlined'),
  ('sesame',       'Susam',                    'Sesame',            'eco_outlined'),
  ('sulphites',    'Kükürt dioksit',           'Sulphur Dioxide',   'science_outlined'),
  ('lupin',        'Acı bakla',                'Lupin',             'eco_outlined'),
  ('molluscs',     'Yumuşakçalar',             'Molluscs',          'set_meal')
on conflict (code) do nothing;

-- RLS: public read, no writes (seed only)
alter table public.allergen_definitions enable row level security;

create policy "allergen_definitions_public_read" on public.allergen_definitions
  for select to authenticated, anon using (true);

-- ─────────────────────────────────────────
-- menu_ocr_jobs
-- ─────────────────────────────────────────
create table if not exists public.menu_ocr_jobs (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references public.businesses(id) on delete cascade,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  file_url        text not null,
  file_name       text,
  status          text not null default 'queued'
                    check (status in ('queued', 'processing', 'completed', 'failed')),
  raw_text        text,
  parsed_output   jsonb,
  error_message   text,
  item_count      int,
  ocr_engine      text default 'none'
                    check (ocr_engine in ('none', 'paddleocr', 'manual')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists menu_ocr_jobs_business_id_idx
  on public.menu_ocr_jobs(business_id, created_at desc);

create index if not exists menu_ocr_jobs_owner_id_idx
  on public.menu_ocr_jobs(owner_id, created_at desc);

create index if not exists menu_ocr_jobs_status_idx
  on public.menu_ocr_jobs(status, created_at desc);

alter table public.menu_ocr_jobs enable row level security;

-- Owner can see own jobs; admin sees all
create policy "menu_ocr_jobs_owner_read" on public.menu_ocr_jobs
  for select to authenticated
  using (
    owner_id = auth.uid()
    or exists (
      select 1 from auth.users u
      where u.id = auth.uid()
        and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
    )
  );

-- Owner can insert own jobs
create policy "menu_ocr_jobs_owner_insert" on public.menu_ocr_jobs
  for insert to authenticated
  with check (owner_id = auth.uid());

-- Only service role updates (edge function)
-- (no policy = only service role can update via admin client)

-- ─────────────────────────────────────────
-- menu_item_ai_analysis
-- ─────────────────────────────────────────
create table if not exists public.menu_item_ai_analysis (
  id                uuid primary key default gen_random_uuid(),
  ocr_job_id        uuid references public.menu_ocr_jobs(id) on delete set null,
  business_id       uuid not null references public.businesses(id) on delete cascade,
  menu_item_id      uuid references public.menu_items(id) on delete set null,
  source_text       text not null,
  normalized_text   text,
  ingredients_json  jsonb default '[]'::jsonb,
  allergens_json    jsonb default '[]'::jsonb,
  calorie_min       int,
  calorie_max       int,
  confidence        numeric(4,3) not null default 0 check (confidence >= 0 and confidence <= 1),
  requires_review   boolean not null default true,
  status            text not null default 'pending_review'
                      check (status in ('pending_review', 'approved', 'rejected')),
  reviewed_by       uuid references auth.users(id) on delete set null,
  reviewed_at       timestamptz,
  ai_model          text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists menu_item_ai_analysis_business_id_idx
  on public.menu_item_ai_analysis(business_id, created_at desc);

create index if not exists menu_item_ai_analysis_ocr_job_id_idx
  on public.menu_item_ai_analysis(ocr_job_id);

create index if not exists menu_item_ai_analysis_status_idx
  on public.menu_item_ai_analysis(business_id, status, created_at desc);

alter table public.menu_item_ai_analysis enable row level security;

create policy "menu_item_ai_analysis_owner_read" on public.menu_item_ai_analysis
  for select to authenticated
  using (
    exists (
      select 1 from public.businesses b
      where b.id = business_id
        and b.owner_id = auth.uid()
    )
    or exists (
      select 1 from auth.users u
      where u.id = auth.uid()
        and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
    )
  );

-- ─────────────────────────────────────────
-- ai_analysis_corrections (learning loop)
-- ─────────────────────────────────────────
create table if not exists public.ai_analysis_corrections (
  id           uuid primary key default gen_random_uuid(),
  analysis_id  uuid not null references public.menu_item_ai_analysis(id) on delete cascade,
  business_id  uuid not null references public.businesses(id) on delete cascade,
  field        text not null,
  ai_value     jsonb,
  human_value  jsonb,
  corrected_by uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now()
);

create index if not exists ai_analysis_corrections_analysis_id_idx
  on public.ai_analysis_corrections(analysis_id);

alter table public.ai_analysis_corrections enable row level security;

create policy "ai_analysis_corrections_owner_insert" on public.ai_analysis_corrections
  for insert to authenticated
  with check (
    exists (
      select 1 from public.businesses b
      where b.id = business_id and b.owner_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────
-- updated_at trigger helper
-- ─────────────────────────────────────────
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger menu_ocr_jobs_updated_at
  before update on public.menu_ocr_jobs
  for each row execute function public.touch_updated_at();

create trigger menu_item_ai_analysis_updated_at
  before update on public.menu_item_ai_analysis
  for each row execute function public.touch_updated_at();

-- ─────────────────────────────────────────
-- RPC: create_menu_ocr_job_v1
-- Creates a job record; edge function processes it separately
-- ─────────────────────────────────────────
create or replace function public.create_menu_ocr_job_v1(
  p_business_id  uuid,
  p_file_url     text,
  p_file_name    text default null
)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_job_id uuid;
begin
  -- Verify caller owns the business
  if not exists (
    select 1 from public.businesses
    where id = p_business_id and owner_id = auth.uid()
  ) then
    raise exception 'forbidden';
  end if;

  insert into public.menu_ocr_jobs (business_id, owner_id, file_url, file_name)
  values (p_business_id, auth.uid(), p_file_url, p_file_name)
  returning id into v_job_id;

  return v_job_id;
end;
$$;

-- ─────────────────────────────────────────
-- RPC: list_menu_ocr_jobs_v1
-- ─────────────────────────────────────────
create or replace function public.list_menu_ocr_jobs_v1(
  p_business_id uuid,
  p_limit       int default 20,
  p_offset      int default 0
)
returns table (
  id            uuid,
  file_url      text,
  file_name     text,
  status        text,
  item_count    int,
  error_message text,
  created_at    timestamptz,
  updated_at    timestamptz
)
language plpgsql security definer
set search_path = public
as $$
begin
  -- Verify access
  if not exists (
    select 1 from public.businesses
    where id = p_business_id
      and (
        owner_id = auth.uid()
        or exists (
          select 1 from auth.users u
          where u.id = auth.uid()
            and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
        )
      )
  ) then
    raise exception 'forbidden';
  end if;

  return query
    select j.id, j.file_url, j.file_name, j.status,
           j.item_count, j.error_message, j.created_at, j.updated_at
    from public.menu_ocr_jobs j
    where j.business_id = p_business_id
    order by j.created_at desc
    limit p_limit offset p_offset;
end;
$$;

-- ─────────────────────────────────────────
-- RPC: list_menu_ai_analysis_v1
-- ─────────────────────────────────────────
create or replace function public.list_menu_ai_analysis_v1(
  p_business_id  uuid,
  p_status       text default null,
  p_ocr_job_id   uuid default null,
  p_limit        int default 50,
  p_offset       int default 0
)
returns table (
  id               uuid,
  ocr_job_id       uuid,
  source_text      text,
  normalized_text  text,
  ingredients_json jsonb,
  allergens_json   jsonb,
  calorie_min      int,
  calorie_max      int,
  confidence       numeric,
  requires_review  boolean,
  status           text,
  created_at       timestamptz
)
language plpgsql security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.businesses
    where id = p_business_id
      and (
        owner_id = auth.uid()
        or exists (
          select 1 from auth.users u
          where u.id = auth.uid()
            and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
        )
      )
  ) then
    raise exception 'forbidden';
  end if;

  return query
    select a.id, a.ocr_job_id, a.source_text, a.normalized_text,
           a.ingredients_json, a.allergens_json,
           a.calorie_min, a.calorie_max,
           a.confidence, a.requires_review, a.status, a.created_at
    from public.menu_item_ai_analysis a
    where a.business_id = p_business_id
      and (p_status is null or a.status = p_status)
      and (p_ocr_job_id is null or a.ocr_job_id = p_ocr_job_id)
    order by a.created_at desc
    limit p_limit offset p_offset;
end;
$$;

-- ─────────────────────────────────────────
-- RPC: approve_menu_ai_analysis_v1
-- ─────────────────────────────────────────
create or replace function public.approve_menu_ai_analysis_v1(
  p_analysis_id uuid
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  update public.menu_item_ai_analysis
  set status = 'approved',
      requires_review = false,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_analysis_id
    and exists (
      select 1 from public.businesses b
      where b.id = business_id
        and (
          b.owner_id = auth.uid()
          or exists (
            select 1 from auth.users u
            where u.id = auth.uid()
              and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
          )
        )
    );

  if not found then
    raise exception 'not_found_or_forbidden';
  end if;
end;
$$;

-- ─────────────────────────────────────────
-- RPC: reject_menu_ai_analysis_v1
-- ─────────────────────────────────────────
create or replace function public.reject_menu_ai_analysis_v1(
  p_analysis_id uuid
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  update public.menu_item_ai_analysis
  set status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_analysis_id
    and exists (
      select 1 from public.businesses b
      where b.id = business_id
        and (
          b.owner_id = auth.uid()
          or exists (
            select 1 from auth.users u
            where u.id = auth.uid()
              and (u.app_metadata->>'role' = 'admin' or u.user_metadata->>'role' = 'admin')
          )
        )
    );

  if not found then
    raise exception 'not_found_or_forbidden';
  end if;
end;
$$;
