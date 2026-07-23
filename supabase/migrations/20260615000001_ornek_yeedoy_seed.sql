-- Seed a fully-populated demo business ("Örnek Yeedoy") with menu, today's
-- special, a promo story and a review, for the redesigned Yemekler tab.
--
-- trg_reviews_edge_guard_v1 calls consume_edge_guard_event_v1(), which raises
-- 'edge_guard_required' whenever auth.uid() is null (i.e. outside a real user
-- session). Disable it for this admin seed insert, then restore it.
--
-- trg_recompute_achievements_reviews_v1 calls award_achievement_v1('first_review'),
-- which fails with a FK violation because public.achievements is currently
-- empty in production (pre-existing data gap, out of scope here). Disable it
-- for this insert too, then restore it.
alter table public.reviews disable trigger trg_reviews_edge_guard_v1;
alter table public.reviews disable trigger trg_recompute_achievements_reviews_v1;

do $$
declare
  v_business_id uuid;
  v_menu_id uuid;
  v_section_kebap uuid;
  v_section_pide uuid;
  v_section_corba uuid;
  v_section_tatli uuid;
  v_admin_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_reviewer_id uuid := 'b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0';
begin
  -- 2026-07-23 fix: bu iki sabit UUID, remote'da elle oluşturulmuş auth.users
  -- kayıtlarını varsayıyordu (fresh reset'te yok, reviews_user_id_fkey
  -- ihlaline yol açıyordu). Idempotent placeholder kullanıcılar ekleniyor.
  insert into auth.users (
    id, instance_id, aud, role, email, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new,
    email_change_token_current, reauthentication_token
  ) values
    (v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'ornek-yeedoy-admin@seed.yeedoy.local', now(),
     '{"provider":"email","providers":["email"]}', '{"email_verified":true}', now(), now(),
     '', '', '', '', '', ''),
    (v_reviewer_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'ornek-yeedoy-reviewer@seed.yeedoy.local', now(),
     '{"provider":"email","providers":["email"]}', '{"email_verified":true}', now(), now(),
     '', '', '', '', '', '')
  on conflict (id) do nothing;

  -- 2026-07-23 fix: id sabitlendi (2e9be57b-62cd-4f5f-bb4b-0d665994765c) —
  -- daha sonraki 20260615000003_ornek_yeedoy_hours.sql ve
  -- 20260615000006_seed_top_business_demo_reviews.sql bu tam ID'yi
  -- varsayıyor; rastgele üretilen bir id'yle her fresh reset'te uyuşmazdı.
  insert into public.businesses (
    id, name, category, description, city, district, neighborhood,
    lat, lng, is_active, source, slug, public_slug, cover_url, logo_url
  ) values (
    '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
    'Örnek Yeedoy', 'Restoran',
    'Yeedoy''in örnek menü, kampanya ve yorum verileriyle hazırlanmış tanıtım işletmesi.',
    'Ankara', 'Yenimahalle', 'Uğur Mumcu Mahallesi',
    40.012933, 32.740723, true, 'manual', 'ornek-yeedoy', 'ornek-yeedoy',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80'
  )
  on conflict (id) do update set name = excluded.name
  returning id into v_business_id;

  insert into public.menus (business_id, title, status, source)
  values (v_business_id, 'Ana Menü', 'published', 'admin')
  returning id into v_menu_id;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Kebaplar', 1)
  returning id into v_section_kebap;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Pideler', 2)
  returning id into v_section_pide;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Çorbalar', 3)
  returning id into v_section_corba;

  insert into public.menu_sections (menu_id, title, sort_order)
  values (v_menu_id, 'Tatlılar', 4)
  returning id into v_section_tatli;

  insert into public.menu_items (
    section_id, business_id, name, description, price_cents, currency,
    image_url, is_today_special, special_note
  ) values
    (v_section_kebap, v_business_id, 'Adana Kebap', 'Köz biber, bulgur pilavı ile',
     26000, 'TRY',
     'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800&q=80',
     true, 'Köz biber, bulgur pilavı ile'),
    (v_section_pide, v_business_id, 'Kuşbaşılı Pide', 'Kaşar ve tereyağlı',
     24000, 'TRY',
     'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=800&q=80',
     false, null),
    (v_section_corba, v_business_id, 'Mercimek Çorbası', 'Limon ve kıtır ekmek ile',
     9000, 'TRY',
     'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
     false, null),
    (v_section_tatli, v_business_id, 'Fıstıklı Baklava', 'Günlük taze üretim',
     18000, 'TRY',
     'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
     false, null);

  insert into public.business_stories (
    business_id, type, caption, media_url, media_type, created_by, expires_at
  ) values (
    v_business_id, 'promo',
    'Örnek Yeedoy''a özel kampanya: Bu hafta Adana Kebap''ta %15 indirim!',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
    'image', v_admin_id, now() + interval '30 days'
  );

  insert into public.reviews (
    business_id, user_id, rating, content, status,
    overall_rating, taste_rating, service_speed_rating,
    price_performance_rating, cleanliness_rating, atmosphere_rating
  ) values (
    v_business_id, v_reviewer_id, 5,
    'Adana kebabı gerçekten köz lezzetinde, pidesi de taze ve sıcak geldi. Servis hızlıydı, kesinlikle tekrar geleceğim!',
    'approved', 5, 5, 5, 4, 5, 5
  );
end $$;

alter table public.reviews enable trigger trg_reviews_edge_guard_v1;
alter table public.reviews enable trigger trg_recompute_achievements_reviews_v1;
