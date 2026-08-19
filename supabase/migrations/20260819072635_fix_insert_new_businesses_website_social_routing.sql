create or replace function public.insert_new_businesses_from_google_catalog_v1()
returns table(new_businesses int, linked_existing int)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_new int := 0;
  v_linked int := 0;
begin
  set local statement_timeout = '0';

  create temp table _gm_candidates on commit drop as
  select
    cat.source_key, cat.provider, cat.place_id, cat.cid, cat.data_id,
    cat.source_url, cat.menu_url, cat.plus_code, cat.first_seen_at, cat.last_seen_at,
    trim(cat.name) as name,
    private._map_google_category_to_business_category(cat.category) as category,
    nullif(trim(cat.description),'') as description,
    nullif(trim(cat.phone),'') as phone,
    -- instagram/facebook linkleri website_url'e konmaz; route_google_business_links_v1() sonradan
    -- instagram_url/facebook_url'a yönlendirir. Burada yalnız gerçek harici site set edilir.
    case
      when nullif(trim(cat.website_url),'') !~ 'instagram\.com|facebook\.com' then nullif(trim(cat.website_url),'')
      else null
    end as website_url,
    nullif(trim(cat.address),'') as address,
    cat.city_hint as city,
    cat.district_hint as district,
    nullif(trim(cat.complete_address->>'borough'),'') as neighborhood,
    cat.lat, cat.lng,
    nullif(trim(cat.reservation_url),'') as reservation_url,
    gen_random_uuid() as new_id
  from private.google_maps_places_catalog cat
  where not exists (
    select 1 from public.business_external_sources es
    where es.provider = 'google_maps' and es.source_key = cat.source_key
  )
  and private._map_google_category_to_business_category(cat.category) is not null
  and cat.name is not null and trim(cat.name) <> ''
  and cat.lat is not null and cat.lng is not null;

  with ins as (
    insert into public.businesses (
      id, name, category, description, phone, address, city, district, neighborhood,
      lat, lng, website_url, reservation_url, is_active, is_verified, source, source_id, fingerprint
    )
    select
      new_id, name, category, description, phone, address, city, district, neighborhood,
      lat, lng, website_url, reservation_url, true, false, 'google_maps', source_key,
      encode(digest(
        lower(regexp_replace(name, '\s+', ' ', 'g')) || '|' ||
        coalesce(category,'') || '|' ||
        lower(trim(city)) || '|' ||
        lower(trim(district)) || '|' ||
        round(lat::numeric,4)::text || '|' ||
        round(lng::numeric,4)::text,
      'sha1'), 'hex')
    from _gm_candidates
    on conflict (fingerprint) do nothing
    returning id, source_id
  )
  insert into public.business_external_sources (
    business_id, provider, source_key, place_id, cid, data_id,
    source_url, menu_url, plus_code, first_seen_at, last_seen_at
  )
  select ins.id, c.provider, c.source_key, c.place_id, c.cid, c.data_id,
         c.source_url, c.menu_url, c.plus_code, c.first_seen_at, c.last_seen_at
  from ins join _gm_candidates c on c.source_key = ins.source_id
  on conflict (provider, source_key) do update set
    last_seen_at = excluded.last_seen_at, updated_at = now();

  get diagnostics v_new = row_count;

  with conflicted as (
    select c.*,
      encode(digest(
        lower(regexp_replace(c.name, '\s+', ' ', 'g')) || '|' ||
        coalesce(c.category,'') || '|' ||
        lower(trim(c.city)) || '|' ||
        lower(trim(c.district)) || '|' ||
        round(c.lat::numeric,4)::text || '|' ||
        round(c.lng::numeric,4)::text,
      'sha1'), 'hex') as fp
    from _gm_candidates c
    where not exists (
      select 1 from public.businesses b
      where b.source = 'google_maps' and b.source_id = c.source_key
    )
  ),
  matched_conflicts as (
    select c.*, b.id as business_id
    from conflicted c
    join public.businesses b on b.fingerprint = c.fp
  )
  insert into public.business_external_sources (
    business_id, provider, source_key, place_id, cid, data_id,
    source_url, menu_url, plus_code, first_seen_at, last_seen_at
  )
  select business_id, provider, source_key, place_id, cid, data_id,
         source_url, menu_url, plus_code, first_seen_at, last_seen_at
  from matched_conflicts
  on conflict (provider, source_key) do update set
    last_seen_at = excluded.last_seen_at, updated_at = now();

  get diagnostics v_linked = row_count;

  return query select v_new, v_linked;
end;
$$;

comment on function public.insert_new_businesses_from_google_catalog_v1 is
  'Hiçbir mevcut işletmeyle eşleşmemiş, kategorisi bilinen taksonomiye net eşlenen Google catalog kayıtlarını yeni businesses satırı olarak ekler. source=google_maps, source_id=catalog.source_key, is_verified=false, is_active=true. slug/geog/search_tsv mevcut trigger''larla otomatik. website_url instagram/facebook ise set edilmez (route_google_business_links_v1() sonradan instagram_url/facebook_url''a yönlendirir). fingerprint çakışırsa mevcut işletmeye sessizce bağlanır, yeni satır açılmaz. Resume-safe: business_external_sources''ta zaten var olan source_key bir daha işlenmez.';

create or replace function public.enrich_businesses_from_google_catalog_v1()
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with matches as (
    select es.business_id, cat.phone as g_phone,
           cat.description as g_description, cat.address as g_address,
           cat.city_hint as g_city, cat.district_hint as g_district,
           cat.complete_address->>'borough' as g_neighborhood,
           cat.reservation_url as g_reservation_url,
           row_number() over (partition by es.business_id order by cat.last_seen_at desc) as rn
    from public.business_external_sources es
    join private.google_maps_places_catalog cat
      on cat.provider = es.provider and cat.source_key = es.source_key
    where es.provider = 'google_maps'
  ),
  best as (select * from matches where rn = 1)
  update public.businesses b set
    phone = case when nullif(trim(b.phone),'') is null then nullif(trim(best.g_phone),'') else b.phone end,
    description = case when nullif(trim(b.description),'') is null and length(trim(coalesce(best.g_description,''))) >= 10
                        then trim(best.g_description) else b.description end,
    address = case when nullif(trim(b.address),'') is null then nullif(trim(best.g_address),'') else b.address end,
    city = case when nullif(trim(b.city),'') is null then nullif(trim(best.g_city),'') else b.city end,
    district = case when nullif(trim(b.district),'') is null then nullif(trim(best.g_district),'') else b.district end,
    neighborhood = case when nullif(trim(b.neighborhood),'') is null then nullif(trim(best.g_neighborhood),'') else b.neighborhood end,
    reservation_url = case when nullif(trim(b.reservation_url),'') is null then nullif(trim(best.g_reservation_url),'') else b.reservation_url end
  from best
  where b.id = best.business_id
    and (
      (nullif(trim(b.phone),'') is null and nullif(trim(best.g_phone),'') is not null) or
      (nullif(trim(b.description),'') is null and length(trim(coalesce(best.g_description,''))) >= 10) or
      (nullif(trim(b.address),'') is null and nullif(trim(best.g_address),'') is not null) or
      (nullif(trim(b.city),'') is null and nullif(trim(best.g_city),'') is not null) or
      (nullif(trim(b.district),'') is null and nullif(trim(best.g_district),'') is not null) or
      (nullif(trim(b.neighborhood),'') is null and nullif(trim(best.g_neighborhood),'') is not null) or
      (nullif(trim(b.reservation_url),'') is null and nullif(trim(best.g_reservation_url),'') is not null)
    );

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

comment on function public.enrich_businesses_from_google_catalog_v1 is
  'business_external_sources(provider=google_maps) ile eşleşmiş işletmelerin YALNIZ boş alanlarını Google katalogdan doldurur (website/sosyal/sipariş linkleri hariç — bkz. route_google_business_links_v1). name/lat/lng/is_verified/price_level''a asla dokunmaz. Idempotent: zaten dolu alanlar bir daha güncellenmez.';
