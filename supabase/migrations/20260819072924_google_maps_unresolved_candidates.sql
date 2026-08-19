create table private.google_maps_unresolved_candidates (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  source_key text not null,
  name text,
  category text,
  phone text,
  website text,
  address text,
  city text,
  district text,
  lat double precision,
  lng double precision,
  source_url text,
  reason text not null,
  candidate_business_id uuid references public.businesses(id) on delete set null,
  match_score numeric,
  created_at timestamptz not null default now(),
  unique (provider, source_key, candidate_business_id)
);

create index google_maps_unresolved_candidates_business_idx
  on private.google_maps_unresolved_candidates(candidate_business_id);
create index google_maps_unresolved_candidates_source_key_idx
  on private.google_maps_unresolved_candidates(source_key);

alter table private.google_maps_unresolved_candidates enable row level security;
revoke all on private.google_maps_unresolved_candidates from public, anon, authenticated;
grant select on private.google_maps_unresolved_candidates to service_role;

comment on table private.google_maps_unresolved_candidates is
  'Google catalog kaydı ile mevcut bir işletme arasında match_google_catalog_to_businesses_v1''in eşiklerini geçemeyen ama gerçek bir aday olabilecek yakın-ıskalar. Yanlış merge yapmamak için otomatik karar verilmez, admin review''a bırakılır. Büyük JSONB (categories/complete_address/opening_hours/raw) taşınmaz.';

create or replace function public.find_google_maps_unresolved_candidates_v1(
  p_radius_m numeric default 75,
  p_min_sim numeric default 0.25
)
returns int
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with candidates as (
    select
      cat.source_key, cat.provider, cat.name, cat.category, cat.phone, cat.website_url,
      cat.address, cat.city_hint as city, cat.district_hint as district,
      cat.lat, cat.lng, cat.source_url,
      b.id as business_id,
      similarity(lower(cat.name), lower(b.name)) as name_sim,
      ST_Distance(cat.geog, b.geog) as dist_m
    from private.google_maps_places_catalog cat
    join public.businesses b
      on b.geog is not null and cat.geog is not null
     and b.source <> 'google_maps'
     and ST_DWithin(cat.geog, b.geog, p_radius_m)
  ),
  near_miss as (
    select *,
      row_number() over (partition by source_key order by name_sim desc, dist_m asc) as rn
    from candidates
    where not ((dist_m <= 20 and name_sim >= 0.35) or (dist_m <= 75 and name_sim >= 0.55))
      and name_sim >= p_min_sim
  )
  insert into private.google_maps_unresolved_candidates (
    provider, source_key, name, category, phone, website, address, city, district,
    lat, lng, source_url, reason, candidate_business_id, match_score
  )
  select
    provider, source_key, name, category, phone, website_url, address, city, district,
    lat, lng, source_url,
    format('near_miss: dist=%sm sim=%s (eşik altı)', round(dist_m::numeric,1), round(name_sim::numeric,2)),
    business_id, round(name_sim::numeric,4)
  from near_miss
  where rn = 1
  on conflict (provider, source_key, candidate_business_id) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.find_google_maps_unresolved_candidates_v1(numeric,numeric) from public, anon, authenticated;
grant execute on function public.find_google_maps_unresolved_candidates_v1(numeric,numeric) to service_role;

comment on function public.find_google_maps_unresolved_candidates_v1 is
  'match_google_catalog_to_businesses_v1''in tier eşiklerini (dist<=20&sim>=0.35 veya dist<=75&sim>=0.55) geçemeyen ama p_min_sim üzerinde kalan en-iyi-aday eşleşmeleri private.google_maps_unresolved_candidates''a yazar. Hiçbir business/catalog satırını değiştirmez, yalnız admin-review kaydı ekler. Idempotent (unique constraint + ON CONFLICT DO NOTHING).';
