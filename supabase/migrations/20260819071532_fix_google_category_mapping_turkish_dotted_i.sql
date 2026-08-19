drop function if exists private._map_google_category_to_business_category_v2(text);

create or replace function private._map_google_category_to_business_category(p_category text)
returns text
language sql
immutable
set search_path = public, pg_catalog
as $$
  select case
    when p_category is null then null
    when public.normalize_tr_location_text(p_category) ~ 'bar|pub|meyhane|birahane|nargile|kokteyl|gece kul[üu]b|lounge' then 'Mekan'
    when public.normalize_tr_location_text(p_category) ~ 'pastane|tatli|dondurma|cikolata|firin|borek|kek dukkan|sekerleme' then 'Tatlıcı'
    when public.normalize_tr_location_text(p_category) ~ 'kahvalti|brunch' then 'Kahvaltı'
    when public.normalize_tr_location_text(p_category) ~ 'balik|deniz mahsul|et lokantasi|et yemek|kebap|donerci|mangal|barbeku|izgara|kofte|biftek|sakatat|tavuk|kelle paca' then 'Balık / Et'
    when public.normalize_tr_location_text(p_category) ~ 'kafe|kahve|kafeterya|cay bahcesi|cay evi' then 'Kafe'
    when public.normalize_tr_location_text(p_category) ~ 'restoran|restaurant|lokanta|pideci|pizza|hamburger|corba|manti|durum|fast food|asevi|vagon restoran|bufe|tostcu|simitci|yemek uretic|yemek pazari|bistro|sandvic|yeme.{0,4}icme|yiyecek ve icecek' then 'Restoran'
    else null
  end;
$$;

comment on function private._map_google_category_to_business_category(text) is
  'Google Maps kategori string''ini public.businesses.category''nin kapalı taksonomisine (Restoran/Kafe/Kahvaltı/Balık ve Et/Tatlıcı/Mekan) eşler. public.normalize_tr_location_text() ile Türkçe diyakritik/İ-noktalı-büyük-harf sorunlarından arındırılmış metin üzerinde eşleşir (bkz. 20260609000004_fix_normalize_tr_location_combining_dot.sql''deki aynı sınıf bug). Eşlenemeyen kategori NULL döner (tahmin yapılmaz).';
