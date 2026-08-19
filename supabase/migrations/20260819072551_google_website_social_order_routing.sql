alter table public.business_external_sources add column if not exists order_online_url text;

comment on column public.business_external_sources.order_online_url is
  'Google Maps order_online_url alanı (whatsapp/instagram/facebook/3.parti sipariş linki dahil, ham metin). businesses.order_yemeksepeti_url/order_trendyolgo_url/order_getir_url''a yalnız domaini gerçekten o sağlayıcıya aitse route edilir; diğerleri (wa.me, google reserve, vb.) yalnız burada kalır.';

create or replace function public.route_google_business_links_v1()
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int := 0;
begin
  set local statement_timeout = '0';

  -- 0) business_external_sources.order_online_url provenance'ını (tüm satırlar, 1:1) tazele
  update public.business_external_sources es
  set order_online_url = nullif(trim(cat.order_online_url), '')
  from private.google_maps_places_catalog cat
  where es.provider = 'google_maps'
    and cat.provider = es.provider and cat.source_key = es.source_key
    and es.order_online_url is distinct from nullif(trim(cat.order_online_url), '');

  -- 1) Düzeltme: daha önce website_url'e yanlışlıkla konmuş instagram/facebook linklerini doğru sosyal alana taşı
  update public.businesses b set
    instagram_url = case when nullif(trim(b.instagram_url),'') is null and b.website_url ~ 'instagram\.com' then b.website_url else b.instagram_url end,
    facebook_url  = case when nullif(trim(b.facebook_url),'')  is null and b.website_url ~ 'facebook\.com'  then b.website_url else b.facebook_url  end,
    website_url   = case when b.website_url ~ 'instagram\.com|facebook\.com' then null else b.website_url end
  where b.website_url ~ 'instagram\.com|facebook\.com';

  get diagnostics v_count = row_count;

  -- 2) Taze doldurma: eşleşmiş işletmeler için website/sosyal/sipariş alanlarını (yalnız boşsa) domain-farkındalıklı doldur
  with matches as (
    select es.business_id, cat.website_url as g_website, cat.order_online_url as g_order,
           row_number() over (partition by es.business_id order by cat.last_seen_at desc) as rn
    from public.business_external_sources es
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

revoke execute on function public.route_google_business_links_v1() from public, anon, authenticated;
grant execute on function public.route_google_business_links_v1() to service_role;

comment on function public.route_google_business_links_v1 is
  'Google catalog website_url/order_online_url alanlarını domain''e göre doğru businesses kolonuna yönlendirir: instagram.com/facebook.com→instagram_url/facebook_url, diğer domain→website_url; yemeksepeti.com→order_yemeksepeti_url, tgoyemek.com/trendyolgo.com→order_trendyolgo_url, getir.com→order_getir_url. Diğer sipariş linkleri (wa.me, google reserve, vb.) yalnız business_external_sources.order_online_url''da kalır. Yalnız boş alan doldurur; ayrıca daha önce website_url''e yanlışlıkla konmuş sosyal linkleri düzeltir. Idempotent, tekrar tekrar çağrılabilir.';
