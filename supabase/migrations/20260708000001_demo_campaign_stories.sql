-- Demo kampanya hikayelerini gerçekçi verilerle doldur.
-- Örnek Yeedoy story güncellendi: is_featured=true, discount_percent, category.
-- 3 farklı kategori için 3 ek promo story eklendi.

-- Mevcut Örnek Yeedoy story'sini tam metadata ile güncelle
update public.business_stories
set
  is_featured    = true,
  discount_percent = 15,
  category       = 'yemek',
  expires_at     = now() + interval '30 days'
where business_id = (
  select id from public.businesses where slug = 'ornek-yeedoy' limit 1
)
and type = 'promo'
and is_deleted = false;

-- Örnek Yeedoy için 2 ek non-featured kampanya (list view'u doldurmak için)
do $$
declare
  v_business_id uuid;
  v_admin_id    uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
begin
  select id into v_business_id
  from public.businesses
  where slug = 'ornek-yeedoy'
  limit 1;

  if v_business_id is null then return; end if;

  -- Tatlı kampanyası
  insert into public.business_stories (
    business_id, type, caption, media_url, media_type,
    created_by, expires_at, discount_percent, category, is_featured
  )
  select
    v_business_id,
    'promo',
    'Fıstıklı Baklava''da bu hafta %20 indirim — günlük taze üretim!',
    'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
    'image',
    v_admin_id,
    now() + interval '7 days',
    20,
    'tatli',
    false
  where not exists (
    select 1 from public.business_stories
    where business_id = v_business_id
      and caption like '%Baklava%'
      and is_deleted = false
  );

  -- İçecek kampanyası
  insert into public.business_stories (
    business_id, type, caption, media_url, media_type,
    created_by, expires_at, discount_percent, category, is_featured
  )
  select
    v_business_id,
    'promo',
    'Her kebap siparişine ücretsiz çorba — hafta sonu özel!',
    'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
    'image',
    v_admin_id,
    now() + interval '3 days',
    null,
    'icecek',
    false
  where not exists (
    select 1 from public.business_stories
    where business_id = v_business_id
      and caption like '%ücretsiz çorba%'
      and is_deleted = false
  );
end;
$$;
