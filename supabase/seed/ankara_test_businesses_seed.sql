-- Ankara test seed (safe to rerun)
-- Tag: source='manual_test_seed' and source_id LIKE 'ANKARA_TEST_%'
-- Created: 2026-02-16

begin;

-- Idempotent cleanup for previous runs
delete from public.businesses
where source = 'manual_test_seed'
  and source_id like 'ANKARA_TEST_%';

-- Temporary workaround:
-- These legacy triggers expect old columns on menus/menu_items.
alter table public.menus disable trigger trg_audit_menus_cud_v1;
alter table public.menu_items disable trigger trg_audit_menu_items_cud_v1;
alter table public.menu_items disable trigger menu_items_activity_log_trg;
alter table public.menu_items disable trigger trg_menu_items_new_feed;

with seed_businesses as (
  select *
  from (
    values
      (
        'ANKARA_TEST_YENIMAHALLE_01',
        'Test İşletme - Yenimahalle Döner Evi',
        'Döner',
        'Demo test verisi. Güvenle silinebilir. Seed: ANKARA_TEST_2026_02_16',
        '+90 312 200 10 01',
        'Ragıp Tüzün Cd. No:101, Yenimahalle/Ankara',
        'Ankara',
        'Yenimahalle',
        'Yeni Batı',
        39.9683,
        32.7774
      ),
      (
        'ANKARA_TEST_YENIMAHALLE_02',
        'Test İşletme - Yenimahalle Çorbacı',
        'Çorba',
        'Demo test verisi. Güvenle silinebilir. Seed: ANKARA_TEST_2026_02_16',
        '+90 312 200 10 02',
        'İvedik Cd. No:55, Yenimahalle/Ankara',
        'Ankara',
        'Yenimahalle',
        'Demetevler',
        39.9782,
        32.8007
      ),
      (
        'ANKARA_TEST_ETLIK_01',
        'Test İşletme - Etlik Izgara',
        'Izgara',
        'Demo test verisi. Güvenle silinebilir. Seed: ANKARA_TEST_2026_02_16',
        '+90 312 200 10 03',
        'Etlik Cd. No:75, Keçiören/Ankara',
        'Ankara',
        'Keçiören',
        'Etlik',
        39.9946,
        32.8397
      ),
      (
        'ANKARA_TEST_KECIOREN_01',
        'Test İşletme - Keçiören Kebap',
        'Kebap',
        'Demo test verisi. Güvenle silinebilir. Seed: ANKARA_TEST_2026_02_16',
        '+90 312 200 10 04',
        'Atatürk Cd. No:210, Keçiören/Ankara',
        'Ankara',
        'Keçiören',
        'Kalaba',
        40.0212,
        32.8571
      )
  ) as t(
    source_id,
    name,
    category,
    description,
    phone,
    address,
    city,
    district,
    neighborhood,
    lat,
    lng
  )
),
ins_businesses as (
  insert into public.businesses (
    name,
    category,
    description,
    phone,
    address,
    city,
    district,
    neighborhood,
    lat,
    lng,
    is_active,
    source,
    source_id,
    is_verified
  )
  select
    name,
    category,
    description,
    phone,
    address,
    city,
    district,
    neighborhood,
    lat,
    lng,
    true,
    'manual_test_seed',
    source_id,
    false
  from seed_businesses
  returning id, source_id
),
ins_hours as (
  insert into public.business_hours (
    business_id,
    mon_open, mon_close,
    tue_open, tue_close,
    wed_open, wed_close,
    thu_open, thu_close,
    fri_open, fri_close,
    sat_open, sat_close,
    sun_open, sun_close
  )
  select
    b.id,
    '09:00'::time, '23:00'::time,
    '09:00'::time, '23:00'::time,
    '09:00'::time, '23:00'::time,
    '09:00'::time, '23:00'::time,
    '09:00'::time, '23:59'::time,
    '10:00'::time, '23:59'::time,
    '10:00'::time, '22:30'::time
  from ins_businesses b
  returning business_id
),
ins_menus as (
  insert into public.menus (business_id, title, status, kind, active_from, active_to)
  select
    b.id,
    'Test Menü',
    'published'::public.menu_status,
    'all_day',
    '09:00'::time,
    '23:30'::time
  from ins_businesses b
  returning id, business_id
),
ins_sections as (
  insert into public.menu_sections (menu_id, title, sort_order)
  select m.id, s.title, s.sort_order
  from ins_menus m
  cross join (
    values
      ('Ana Yemekler', 1),
      ('İçecekler', 2)
  ) as s(title, sort_order)
  returning id, menu_id, title
),
section_with_business as (
  select s.id as section_id, s.title as section_title, m.business_id
  from ins_sections s
  join ins_menus m on m.id = s.menu_id
),
ins_items as (
  insert into public.menu_items (
    section_id,
    business_id,
    name,
    description,
    price_cents,
    currency,
    is_vegan,
    is_vegetarian,
    is_gluten_free,
    is_lactose_free,
    is_halal,
    status
  )
  select
    sb.section_id,
    sb.business_id,
    i.name,
    i.description,
    i.price_cents,
    'TRY',
    false,
    false,
    false,
    false,
    true,
    'published'::public.menu_status
  from section_with_business sb
  join (
    values
      ('Ana Yemekler', 'Yarım Ekmek Döner', 'Günlük hazırlanan döner.', 22000),
      ('Ana Yemekler', 'Et Dürüm', 'Lavaşta et döner, domates, soğan.', 28000),
      ('Ana Yemekler', 'Mercimek Çorbası', 'Sıcak servis.', 12000),
      ('Ana Yemekler', 'Adana Kebap Porsiyon', 'Lavaş ve garnitür ile.', 36000),
      ('İçecekler', 'Ayran 300 ml', 'Soğuk servis.', 5000),
      ('İçecekler', 'Kola 330 ml', 'Soğuk servis.', 7000),
      ('İçecekler', 'Şalgam 300 ml', 'Acılı/Acısız.', 7000)
  ) as i(section_title, name, description, price_cents)
    on i.section_title = sb.section_title
  returning id
)
select
  (select count(*) from ins_businesses) as inserted_businesses,
  (select count(*) from ins_hours) as inserted_hours,
  (select count(*) from ins_menus) as inserted_menus,
  (select count(*) from ins_sections) as inserted_sections,
  (select count(*) from ins_items) as inserted_items;

alter table public.menu_items enable trigger trg_menu_items_new_feed;
alter table public.menu_items enable trigger menu_items_activity_log_trg;
alter table public.menu_items enable trigger trg_audit_menu_items_cud_v1;
alter table public.menus enable trigger trg_audit_menus_cud_v1;

commit;

