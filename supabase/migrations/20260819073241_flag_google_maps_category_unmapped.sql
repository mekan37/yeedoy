create or replace function public.flag_google_maps_category_unmapped_v1()
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
  on conflict (provider, source_key, candidate_business_id) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.flag_google_maps_category_unmapped_v1() from public, anon, authenticated;
grant execute on function public.flag_google_maps_category_unmapped_v1() to service_role;

comment on function public.flag_google_maps_category_unmapped_v1 is
  'Kategorisi Yeedoy taksonomisine eşlenemediği için ne eşleştirilebilen ne yeni işletme olarak eklenebilen ve ne de yakın-ıskala adayı olan (yakınında incelenecek işletme yok) catalog satırlarını candidate_business_id=NULL ile google_maps_unresolved_candidates''a taşır. Reconciliation''ın (processed+unresolved=total) tam kapanması için gerekli. Idempotent.';
