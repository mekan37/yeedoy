create table public.business_external_sources (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  provider text not null,
  source_key text not null,
  place_id text,
  cid text,
  data_id text,
  source_url text,
  menu_url text,
  plus_code text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, source_key)
);

create index business_external_sources_business_id_idx
  on public.business_external_sources(business_id);

alter table public.business_external_sources enable row level security;
revoke all on public.business_external_sources from public, anon, authenticated;
grant select on public.business_external_sources to service_role;

comment on table public.business_external_sources is
  'İşletmelerin harici kaynaklardaki (Google Maps vb.) karşılıklarının provenance kaydı. businesses.source/source_id''ı asla değiştirmez/overwrite etmez.';

create or replace function public.match_google_catalog_to_businesses_v1(
  p_tight_radius_m numeric default 20,
  p_tight_min_sim numeric default 0.35,
  p_loose_radius_m numeric default 75,
  p_loose_min_sim numeric default 0.55
)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_count int;
begin
  set local statement_timeout = '0';

  with candidates as (
    select
      cat.source_key, cat.provider, cat.place_id, cat.cid, cat.data_id,
      cat.source_url, cat.menu_url, cat.plus_code, cat.first_seen_at, cat.last_seen_at,
      b.id as business_id,
      similarity(lower(cat.name), lower(b.name)) as name_sim,
      ST_Distance(cat.geog, b.geog) as dist_m
    from private.google_maps_places_catalog cat
    join public.businesses b
      on b.geog is not null and cat.geog is not null
     and ST_DWithin(cat.geog, b.geog, greatest(p_tight_radius_m, p_loose_radius_m))
  ),
  qualified as (
    select * from candidates
    where (dist_m <= p_tight_radius_m and name_sim >= p_tight_min_sim)
       or (dist_m <= p_loose_radius_m and name_sim >= p_loose_min_sim)
  ),
  ranked as (
    select *, row_number() over (
      partition by source_key order by name_sim desc, dist_m asc, business_id asc
    ) as rn
    from qualified
  )
  insert into public.business_external_sources (
    business_id, provider, source_key, place_id, cid, data_id,
    source_url, menu_url, plus_code, first_seen_at, last_seen_at
  )
  select
    business_id, provider, source_key, place_id, cid, data_id,
    source_url, menu_url, plus_code, first_seen_at, last_seen_at
  from ranked
  where rn = 1
  on conflict (provider, source_key) do update set
    last_seen_at = excluded.last_seen_at,
    updated_at = now();

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric)
  from public, anon, authenticated;
grant execute on function public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric)
  to service_role;

comment on function public.match_google_catalog_to_businesses_v1 is
  'Google Maps catalog kayıtlarını mevcut public.businesses ile geo+isim benzerliğiyle eşleştirir, business_external_sources''a provenance ekler. businesses.source/source_id''a asla dokunmaz. Idempotent: unique(provider,source_key) + ON CONFLICT DO UPDATE (yalnız last_seen_at/updated_at tazelenir, business_id değişmez). Coverage taraması büyüdükçe tekrar tekrar çağrılabilir (service_role).';
