-- Tüm Google pipeline RPC'lerine p_batch_size eklenir: her çağrı yalnız o kadar satır işler,
-- kendi transaction'ında biter (client autocommit bağlantısında ayrı bir SELECT çağrısı = ayrı commit).
-- Script yarıda kesilirse, zaten NOT EXISTS/ON CONFLICT filtreleri sayesinde kaldığı yerden
-- güvenle devam eder; hiçbir satır iki kez businesses'a yazılamaz (fingerprint + (provider,source_key) UNIQUE'leri).

drop function if exists public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric);
drop function if exists public.insert_new_businesses_from_google_catalog_v1();
drop function if exists public.route_google_business_links_v1();
drop function if exists public.insert_business_hours_from_google_catalog_v1();
drop function if exists public.find_google_maps_unresolved_candidates_v1(numeric,numeric);
drop function if exists public.flag_google_maps_category_unmapped_v1();

create function public.match_google_catalog_to_businesses_v1(
  p_tight_radius_m numeric default 20,
  p_tight_min_sim numeric default 0.35,
  p_loose_radius_m numeric default 75,
  p_loose_min_sim numeric default 0.55,
  p_batch_size int default 1000
)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with batch_keys as (
    select cat.source_key
    from private.google_maps_places_catalog cat
    where not exists (
      select 1 from public.business_external_sources es
      where es.provider = 'google_maps' and es.source_key = cat.source_key
    )
    order by cat.source_key
    limit p_batch_size
  ),
  candidates as (
    select
      cat.source_key, cat.provider, cat.place_id, cat.cid, cat.data_id,
      cat.source_url, cat.menu_url, cat.plus_code, cat.first_seen_at, cat.last_seen_at,
      b.id as business_id,
      similarity(lower(cat.name), lower(b.name)) as name_sim,
      ST_Distance(cat.geog, b.geog) as dist_m
    from private.google_maps_places_catalog cat
    join batch_keys bk on bk.source_key = cat.source_key
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

revoke execute on function public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric,int) from public, anon, authenticated;
grant execute on function public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric,int) to service_role;

comment on function public.match_google_catalog_to_businesses_v1(numeric,numeric,numeric,numeric,int) is
  'Google Maps catalog kayıtlarını mevcut public.businesses ile geo+isim benzerliğiyle eşleştirir, business_external_sources''a provenance ekler. businesses.source/source_id''a asla dokunmaz. p_batch_size: her çağrı en fazla bu kadar İŞLENMEMİŞ catalog satırını ele alır (kaynak_key sırasıyla, deterministik) — büyük catalog''u tek transaction''da işlemek yerine döngüyle (0 dönene kadar) tekrar tekrar çağırın. Idempotent: unique(provider,source_key) + ON CONFLICT DO UPDATE (business_id değişmez).';

create function public.insert_new_businesses_from_google_catalog_v1(
  p_batch_size int default 1000
)
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
  and cat.lat is not null and cat.lng is not null
  order by cat.source_key
  limit p_batch_size;

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

revoke execute on function public.insert_new_businesses_from_google_catalog_v1(int) from public, anon, authenticated;
grant execute on function public.insert_new_businesses_from_google_catalog_v1(int) to service_role;

comment on function public.insert_new_businesses_from_google_catalog_v1(int) is
  'Hiçbir mevcut işletmeyle eşleşmemiş, kategorisi bilinen taksonomiye net eşlenen Google catalog kayıtlarını yeni businesses satırı olarak ekler. p_batch_size: her çağrı en fazla bu kadar İŞLENMEMİŞ satırı ele alır (source_key sırasıyla) — 0,0 dönene kadar döngüyle tekrar çağırın; her çağrı kendi transaction''ında biter, yarıda kesilse bile zaten commit olmuş batch''ler kalıcıdır. source=google_maps, source_id=catalog.source_key, is_verified=false, is_active=true. fingerprint UNIQUE + (provider,source_key) UNIQUE sayesinde aynı Google kaydı asla iki businesses oluşturamaz.';

create function public.route_google_business_links_v1(
  p_batch_size int default 1000
)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int := 0;
begin
  set local statement_timeout = '0';

  update public.business_external_sources es
  set order_online_url = nullif(trim(cat.order_online_url), '')
  from private.google_maps_places_catalog cat
  where es.provider = 'google_maps'
    and cat.provider = es.provider and cat.source_key = es.source_key
    and es.order_online_url is distinct from nullif(trim(cat.order_online_url), '');

  update public.businesses b set
    instagram_url = case when nullif(trim(b.instagram_url),'') is null and b.website_url ~ 'instagram\.com' then b.website_url else b.instagram_url end,
    facebook_url  = case when nullif(trim(b.facebook_url),'')  is null and b.website_url ~ 'facebook\.com'  then b.website_url else b.facebook_url  end,
    website_url   = case when b.website_url ~ 'instagram\.com|facebook\.com' then null else b.website_url end
  where b.website_url ~ 'instagram\.com|facebook\.com';

  get diagnostics v_count = row_count;

  with batch_businesses as (
    select business_id from public.business_external_sources
    where provider = 'google_maps'
    order by business_id
    limit p_batch_size
  ),
  matches as (
    select es.business_id, cat.website_url as g_website, cat.order_online_url as g_order,
           row_number() over (partition by es.business_id order by cat.last_seen_at desc) as rn
    from public.business_external_sources es
    join batch_businesses bb on bb.business_id = es.business_id
    join private.google_maps_places_catalog cat
      on cat.provider = es.provider and cat.source_key = es.source_key
    where es.provider = 'google_maps'
  ),
  best as (select * from matches where rn = 1)
  update public.businesses b set
    instagram_url = case
      when nullif(trim(b.instagram_url),'') is null and best.g_website ~ 'instagram\.com' then best.g_website
      else b.instagram_url end,
    facebook_url = case
      when nullif(trim(b.facebook_url),'') is null and best.g_website ~ 'facebook\.com' then best.g_website
      else b.facebook_url end,
    website_url = case
      when nullif(trim(b.website_url),'') is null and best.g_website is not null
        and best.g_website !~ 'instagram\.com|facebook\.com' then best.g_website
      else b.website_url end,
    order_yemeksepeti_url = case
      when nullif(trim(b.order_yemeksepeti_url),'') is null and best.g_order ~ 'yemeksepeti\.com' then best.g_order
      else b.order_yemeksepeti_url end,
    order_trendyolgo_url = case
      when nullif(trim(b.order_trendyolgo_url),'') is null and best.g_order ~ 'tgoyemek\.com|trendyolgo\.com' then best.g_order
      else b.order_trendyolgo_url end,
    order_getir_url = case
      when nullif(trim(b.order_getir_url),'') is null and best.g_order ~ 'getir\.com' then best.g_order
      else b.order_getir_url end
  from best
  where b.id = best.business_id
    and (
      (nullif(trim(b.instagram_url),'') is null and best.g_website ~ 'instagram\.com') or
      (nullif(trim(b.facebook_url),'') is null and best.g_website ~ 'facebook\.com') or
      (nullif(trim(b.website_url),'') is null and best.g_website is not null and best.g_website !~ 'instagram\.com|facebook\.com') or
      (nullif(trim(b.order_yemeksepeti_url),'') is null and best.g_order ~ 'yemeksepeti\.com') or
      (nullif(trim(b.order_trendyolgo_url),'') is null and best.g_order ~ 'tgoyemek\.com|trendyolgo\.com') or
      (nullif(trim(b.order_getir_url),'') is null and best.g_order ~ 'getir\.com')
    );

  return v_count;
end;
$$;

revoke execute on function public.route_google_business_links_v1(int) from public, anon, authenticated;
grant execute on function public.route_google_business_links_v1(int) to service_role;

comment on function public.route_google_business_links_v1(int) is
  'Google catalog website_url/order_online_url alanlarını domain''e göre doğru businesses kolonuna yönlendirir. p_batch_size: adım 2''deki (taze doldurma) iş business_id sırasıyla batch''lenir; adım 0-1 (provenance tazeleme + geçmiş hata düzeltmesi) her zaman tam kapsamda çalışır çünkü ucuz ve tekil-satır bazlı idempotent. Idempotent, tekrar tekrar çağrılabilir.';

create function public.insert_business_hours_from_google_catalog_v1(
  p_batch_size int default 1000
)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with batch_businesses as (
    select distinct es.business_id
    from public.business_external_sources es
    where es.provider = 'google_maps'
      and not exists (select 1 from public.business_weekly_hours wh where wh.business_id = es.business_id)
    order by es.business_id
    limit p_batch_size
  ),
  matches as (
    select es.business_id, cat.opening_hours,
           row_number() over (partition by es.business_id order by cat.last_seen_at desc) as rn
    from public.business_external_sources es
    join batch_businesses bb on bb.business_id = es.business_id
    join private.google_maps_places_catalog cat
      on cat.provider = es.provider and cat.source_key = es.source_key
    where es.provider = 'google_maps' and cat.opening_hours is not null
  ),
  best as (select business_id, opening_hours from matches where rn = 1),
  day_map(day_name, dow) as (
    values ('Pazar',0),('Pazartesi',1),('Salı',2),('Çarşamba',3),('Perşembe',4),('Cuma',5),('Cumartesi',6)
  ),
  day_entries as (
    select b.business_id, dm.dow, b.opening_hours->dm.day_name as periods
    from best b
    cross join day_map dm
    where b.opening_hours ? dm.day_name
  ),
  parsed as (
    select
      business_id, dow,
      jsonb_array_length(periods) as period_count,
      case when jsonb_array_length(periods) = 1 and periods->>0 = 'Kapalı' then true else false end as is_closed,
      case
        when jsonb_array_length(periods) = 1 and periods->>0 = '24 saat açık' then '00:00'::time
        when jsonb_array_length(periods) = 1 and (periods->>0) ~ '^[0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2}$'
          then split_part(periods->>0, '–', 1)::time
        else null
      end as open_time,
      case
        when jsonb_array_length(periods) = 1 and periods->>0 = '24 saat açık' then '23:59'::time
        when jsonb_array_length(periods) = 1 and (periods->>0) ~ '^[0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2}$'
          then split_part(periods->>0, '–', 2)::time
        else null
      end as close_time
    from day_entries
  ),
  insertable as (
    select business_id, dow,
           coalesce(open_time, '09:00'::time) as open_time,
           coalesce(close_time, '22:00'::time) as close_time,
           is_closed
    from parsed
    where is_closed = true
       or (period_count = 1 and open_time is not null and close_time is not null)
  )
  insert into public.business_weekly_hours (business_id, day_of_week, open_time, close_time, is_closed)
  select business_id, dow, open_time, close_time, is_closed
  from insertable
  on conflict (business_id, day_of_week) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.insert_business_hours_from_google_catalog_v1(int) from public, anon, authenticated;
grant execute on function public.insert_business_hours_from_google_catalog_v1(int) to service_role;

comment on function public.insert_business_hours_from_google_catalog_v1(int) is
  'business_external_sources(provider=google_maps) ile ilişkili işletmeler için Google opening_hours JSONB''ını public.business_weekly_hours''a normalize eder. p_batch_size: her çağrı, henüz hiç weekly_hours satırı olmayan en fazla bu kadar işletmeyi işler (business_id sırasıyla) — 0 dönene kadar döngüyle tekrar çağırın. ON CONFLICT(business_id,day_of_week) DO NOTHING: mevcut bir gün satırı asla overwrite edilmez. Çoklu periyot içeren günler atlanır, tahmin yapılmaz.';

create function public.find_google_maps_unresolved_candidates_v1(
  p_radius_m numeric default 75,
  p_min_sim numeric default 0.25,
  p_batch_size int default 1000
)
returns int
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with batch_keys as (
    select cat.source_key
    from private.google_maps_places_catalog cat
    where not exists (
      select 1 from public.business_external_sources es
      where es.provider='google_maps' and es.source_key=cat.source_key
    )
    and not exists (
      select 1 from private.google_maps_unresolved_candidates uc
      where uc.provider='google_maps' and uc.source_key=cat.source_key
    )
    order by cat.source_key
    limit p_batch_size
  ),
  candidates as (
    select
      cat.source_key, cat.provider, cat.name, cat.category, cat.phone, cat.website_url,
      cat.address, cat.city_hint as city, cat.district_hint as district,
      cat.lat, cat.lng, cat.source_url,
      b.id as business_id,
      similarity(lower(cat.name), lower(b.name)) as name_sim,
      ST_Distance(cat.geog, b.geog) as dist_m
    from private.google_maps_places_catalog cat
    join batch_keys bk on bk.source_key = cat.source_key
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

revoke execute on function public.find_google_maps_unresolved_candidates_v1(numeric,numeric,int) from public, anon, authenticated;
grant execute on function public.find_google_maps_unresolved_candidates_v1(numeric,numeric,int) to service_role;

comment on function public.find_google_maps_unresolved_candidates_v1(numeric,numeric,int) is
  'match_google_catalog_to_businesses_v1''in tier eşiklerini geçemeyen ama p_min_sim üzerinde kalan en-iyi-aday eşleşmeleri private.google_maps_unresolved_candidates''a yazar. p_batch_size: her çağrı en fazla bu kadar İŞLENMEMİŞ ve henüz unresolved''a da düşmemiş satırı ele alır. Idempotent (unique constraint + ON CONFLICT DO NOTHING).';

create function public.flag_google_maps_category_unmapped_v1(
  p_batch_size int default 1000
)
returns int
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  insert into private.google_maps_unresolved_candidates (
    provider, source_key, name, category, phone, website, address, city, district,
    lat, lng, source_url, reason, candidate_business_id, match_score
  )
  select
    cat.provider, cat.source_key, cat.name, cat.category, cat.phone, cat.website_url,
    cat.address, cat.city_hint, cat.district_hint, cat.lat, cat.lng, cat.source_url,
    'category_unmapped: Yeedoy taksonomisine (Restoran/Kafe/Kahvaltı/Balık ve Et/Tatlıcı/Mekan) deterministik eşlenemedi',
    null, null
  from private.google_maps_places_catalog cat
  where private._map_google_category_to_business_category(cat.category) is null
    and not exists (
      select 1 from public.business_external_sources es
      where es.provider = 'google_maps' and es.source_key = cat.source_key
    )
    and not exists (
      select 1 from private.google_maps_unresolved_candidates uc
      where uc.provider = 'google_maps' and uc.source_key = cat.source_key
    )
  order by cat.source_key
  limit p_batch_size
  on conflict (provider, source_key, candidate_business_id) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.flag_google_maps_category_unmapped_v1(int) from public, anon, authenticated;
grant execute on function public.flag_google_maps_category_unmapped_v1(int) to service_role;

comment on function public.flag_google_maps_category_unmapped_v1(int) is
  'Kategorisi eşlenemediği için ne eşleştirilebilen ne yeni işletme olabilen ne de yakın-ıskala adayı olan catalog satırlarını candidate_business_id=NULL ile unresolved_candidates''a taşır. p_batch_size: her çağrı en fazla bu kadarını işler. Idempotent.';
