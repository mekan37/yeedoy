-- ─── Migrate test businesses and link to admin@yeedoy.com ───────────────────
-- admin@yeedoy.com user_id: 95d14dba-7d57-413c-9939-8bddf80d494f

-- 1) businesses
INSERT INTO public.businesses (
  id, name, category, description, phone, address, city, district,
  lat, lng, is_active, created_at, source, is_verified
) VALUES
(
  '76d43498-86f1-4c34-8b47-7a5f2b409f5b',
  'Usta Döner & Izgara', 'Restoran', 'Döner, ızgara ve ev yemekleri.',
  '0555 222 22 22', 'Bahariye Sk. No:45', 'İstanbul', 'Kadıköy',
  40.9896, 29.0284, true, '2026-01-20 13:11:06.623006+00', NULL, false
),
(
  '2c948dec-9038-4d93-939e-bf6293c0ab60',
  'Güven Oto Servis', 'Oto Servis', 'Periyodik bakım ve arıza tespiti.',
  '0555 333 33 33', 'Sanayi Mh. 3. Cd. No:9', 'İstanbul', 'Ataşehir',
  40.987, 29.128, true, '2026-01-20 13:11:06.623006+00', NULL, false
),
(
  'ff22af0c-11ee-45a6-8d77-e21e053fd6fb',
  'Ankara Diş Kliniği', 'Klinik', 'Diş hekimliği ve estetik uygulamalar.',
  '0555 555 55 55', 'Kızılay Mh. Atatürk Blv. No:100', 'Ankara', 'Çankaya',
  39.9208, 32.8541, true, '2026-01-20 13:11:06.623006+00', NULL, false
),
(
  '9c8bfdde-cb37-49f5-8726-5a694f703aca',
  'Ege Balık Lokantası', 'Balık', 'Günlük taze deniz ürünleri.',
  '0555 444 44 44', 'Sahil Yolu No:5', 'İzmir', 'Konak',
  38.4189, 27.1287, true, '2026-01-20 13:11:06.623006+00', NULL, false
),
(
  '170ac4b3-f588-4c97-b965-27789e7a9092',
  'Sage Coffee Roasters', 'Kafe', 'Özel kavrum kahve ve tatlılar.',
  '0555 111 11 11', 'Moda Cd. No:12', 'İstanbul', 'Kadıköy',
  40.9869, 29.0251, true, '2026-01-20 13:11:06.623006+00', NULL, false
),
(
  'd40c3d0b-c5b6-437c-8e0e-e60acc80b859',
  'Test Isletme - Kecioren Izgara', 'restaurant', NULL,
  NULL, NULL, 'Ankara', 'Kecioren',
  39.9904088866248, 32.8028245463133, true, '2026-02-16 15:51:26.953048+00', 'seed_test', true
),
(
  'd4890234-40bf-459a-83df-2b8c320aa29b',
  'Test Isletme - Etlik Ev Yemekleri', 'restaurant', NULL,
  NULL, NULL, 'Ankara', 'Kecioren',
  39.9754088866248, 32.8238245463133, true, '2026-02-16 15:51:26.953048+00', 'seed_test', true
),
(
  'fcaaf8b9-9de3-48f6-ad6e-c8cf8b28adb4',
  'NAR RESTAURANT', 'Restoran', NULL,
  NULL, 'Batı Bulvarı 1/66, Macun Mahallesi', 'Ankara', 'Yenimahalle',
  39.9489945, 32.7686646, true, '2026-01-21 11:48:12.751472+00', 'osm', false
)
ON CONFLICT (id) DO NOTHING;

-- 2) owner_claims — link all businesses to admin@yeedoy.com (approved)
INSERT INTO public.owner_claims (id, business_id, user_id, status, created_at) VALUES
-- originally from remote seed (d40c3d0b + d4890234)
(
  '14b9e69e-c193-4290-a2c5-f387adde5e4c',
  'd40c3d0b-c5b6-437c-8e0e-e60acc80b859',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  '71964294-3cae-4c88-9dc7-b9369282ba08',
  'd4890234-40bf-459a-83df-2b8c320aa29b',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
-- additional claims for remaining businesses
(
  gen_random_uuid(),
  '76d43498-86f1-4c34-8b47-7a5f2b409f5b',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  gen_random_uuid(),
  '2c948dec-9038-4d93-939e-bf6293c0ab60',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  gen_random_uuid(),
  'ff22af0c-11ee-45a6-8d77-e21e053fd6fb',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  gen_random_uuid(),
  '9c8bfdde-cb37-49f5-8726-5a694f703aca',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  gen_random_uuid(),
  '170ac4b3-f588-4c97-b965-27789e7a9092',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
),
(
  gen_random_uuid(),
  'fcaaf8b9-9de3-48f6-ad6e-c8cf8b28adb4',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'approved',
  '2026-02-19 09:39:03.274751+00'
)
ON CONFLICT (id) DO NOTHING;

-- also keep original pending claims from other users
INSERT INTO public.owner_claims (id, business_id, user_id, status, created_at) VALUES
(
  '0623a73c-13d2-43a3-bb87-32d280d88983',
  '76d43498-86f1-4c34-8b47-7a5f2b409f5b',
  'edc2b1b1-2905-4bf4-95c8-e7956ab85d73',
  'pending',
  '2026-01-29 14:51:33.261218+00'
),
(
  'fd99aa9a-cbc2-472a-b9d3-1cfa64ea718c',
  '76d43498-86f1-4c34-8b47-7a5f2b409f5b',
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  'pending',
  '2026-01-29 15:13:51.498285+00'
),
(
  '4e726539-3f17-459b-a4e3-1911c1dc504c',
  'fcaaf8b9-9de3-48f6-ad6e-c8cf8b28adb4',
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  'pending',
  '2026-01-29 15:43:27.24207+00'
)
ON CONFLICT (id) DO NOTHING;

-- 3) menus (for the two seed_test businesses)
INSERT INTO public.menus (id, business_id, title, status, created_at, kind, version) VALUES
(
  '334cae3b-44a3-40b0-a8e8-c12a65db5f34',
  'd40c3d0b-c5b6-437c-8e0e-e60acc80b859',
  'Test Menu', 'published', '2026-02-16 15:51:26.953048+00', 'main', 1
),
(
  'ef5de9fc-a3ed-4d3b-985d-dfbcc785ca81',
  'd4890234-40bf-459a-83df-2b8c320aa29b',
  'Test Menu', 'published', '2026-02-16 15:51:26.953048+00', 'main', 1
)
ON CONFLICT (id) DO NOTHING;

-- 4) menu_sections
INSERT INTO public.menu_sections (id, menu_id, title, sort_order, created_at) VALUES
('4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', '334cae3b-44a3-40b0-a8e8-c12a65db5f34', 'Ana Yemekler', 1, '2026-02-16 15:51:26.953048+00'),
('776dcd24-f01c-480a-a9f2-30f096a82bf2', '334cae3b-44a3-40b0-a8e8-c12a65db5f34', 'Icecekler',   2, '2026-02-16 15:51:26.953048+00'),
('144a7f58-8421-490e-a800-e82c6771b039', 'ef5de9fc-a3ed-4d3b-985d-dfbcc785ca81', 'Ana Yemekler', 1, '2026-02-16 15:51:26.953048+00'),
('b9be3e45-7771-49f8-956b-69494c9f7ea2', 'ef5de9fc-a3ed-4d3b-985d-dfbcc785ca81', 'Icecekler',   2, '2026-02-16 15:51:26.953048+00')
ON CONFLICT (id) DO NOTHING;

-- 5) menu_items
INSERT INTO public.menu_items (id, section_id, business_id, name, description, price_cents, currency, sort_order, is_available, created_at) VALUES
-- section: 4aba66c5 (d40c3d0b / Ana Yemekler)
('5385cafa-0445-48de-9e9d-a03a9a088424', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Et Doner Porsiyon',  'Pilav ve salata ile',                    27500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('88b2be13-2d61-49a2-a292-46271d3fce37', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Tavuk Sis Dürüm',    'Taze lavas ile',                         22000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('3fddef28-b177-4ef2-936d-a0eb09d2b478', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Mercimek Corbasi',   'Gunun corbasi',                           9500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('aded4c54-1404-42a3-92a0-e843f3abaaab', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Karisik Izgara',     '2 kisilik servis',                       56000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('c7621258-5e9b-498f-902e-576018a00b28', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Mercimek Çorbası',   'tereyağlı',                              15000, 'TRY', 0, true, '2026-02-19 13:46:46.716493+00'),
('5d1a6b50-aa47-47dc-9b2f-b4d6fc6aaac1', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Mercimek Çorbası',   'Günlük mercimek çorbası.',                8500, 'TRY', 0, true, '2026-02-19 14:24:50.441416+00'),
('752d60a0-13f1-4ea6-b172-dae209aac598', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Sigara Böreği',      'Peynirli sigara böreği (6 adet).',        9500, 'TRY', 1, true, '2026-02-19 14:24:50.868408+00'),
('c8f19eb6-bc58-4367-9ca6-8eea57d66db6', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Izgara Köfte',       'Pilav ve köz sebze ile servis edilir.',  18900, 'TRY', 0, true, '2026-02-19 14:24:51.530976+00'),
('5542a151-39c8-4dd4-bff3-1dff263ea131', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Tavuk Şiş',          'Marine tavuk şiş, pilav ve salata ile.', 17500, 'TRY', 1, true, '2026-02-19 14:24:51.855069+00'),
('bc3ca2c3-1ad4-4725-98e7-d82548ee83fa', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Ayran',              'Günlük taze ayran.',                      4000, 'TRY', 0, true, '2026-02-19 14:24:52.523649+00'),
('766894eb-46c0-4fda-a4a2-0eb1941973f1', '4aba66c5-6732-48e1-a0e6-6a66fa9dbe76', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Türk Kahvesi',       'Geleneksel Türk kahvesi.',                 7000, 'TRY', 1, true, '2026-02-19 14:24:52.850014+00'),
-- section: 776dcd24 (d40c3d0b / Icecekler)
('ab234ced-b3f4-4635-a186-5d3f696166ab', '776dcd24-f01c-480a-a9f2-30f096a82bf2', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Cay',                'Ince belli bardak',                       2000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('623d0a0b-86c1-4cc9-aef0-deffdce8c115', '776dcd24-f01c-480a-a9f2-30f096a82bf2', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Ayran',              '300 ml',                                  3500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('7720311c-06e1-485a-b6e7-611e73432464', '776dcd24-f01c-480a-a9f2-30f096a82bf2', 'd40c3d0b-c5b6-437c-8e0e-e60acc80b859', 'Salgam',             'Acili/Acisiz',                            4000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
-- section: 144a7f58 (d4890234 / Ana Yemekler)
('0c245f99-32ff-4f98-a237-70d45351391b', '144a7f58-8421-490e-a800-e82c6771b039', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Karisik Izgara',     '2 kisilik servis',                       56000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('a55e5d69-5005-4ed0-a31f-1425d331bc32', '144a7f58-8421-490e-a800-e82c6771b039', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Tavuk Sis Dürüm',    'Taze lavas ile',                         22000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('0179a8d8-1af8-43f9-9dff-1d1585147288', '144a7f58-8421-490e-a800-e82c6771b039', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Mercimek Corbasi',   'Gunun corbasi',                           9500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('a2760aa6-c507-42f0-82eb-39c8d11b1d46', '144a7f58-8421-490e-a800-e82c6771b039', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Et Doner Porsiyon',  'Pilav ve salata ile',                    27500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
-- section: b9be3e45 (d4890234 / Icecekler)
('42e64177-7c13-4bc6-a861-0172ee6c501f', 'b9be3e45-7771-49f8-956b-69494c9f7ea2', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Salgam',             'Acili/Acisiz',                            4000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('3d57a839-da07-4f5b-9ec7-21f49e344d91', 'b9be3e45-7771-49f8-956b-69494c9f7ea2', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Cay',                'Ince belli bardak',                       2000, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00'),
('d5c7da7e-626a-4e39-acac-40c2faff0fe3', 'b9be3e45-7771-49f8-956b-69494c9f7ea2', 'd4890234-40bf-459a-83df-2b8c320aa29b', 'Ayran',              '300 ml',                                  3500, 'TRY', 0, true, '2026-02-16 15:51:26.953048+00')
ON CONFLICT (id) DO NOTHING;
