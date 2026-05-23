-- seed.sql
-- NOTE: Replace owner_id with a real auth.users id for full owner dashboard testing.

insert into public.businesses (
  id,
  owner_id,
  name,
  slug,
  public_slug,
  city,
  district,
  address,
  phone,
  currency,
  is_active
)
values (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000000',
  'Demo Bistro',
  'demo-slug',
  'demo-slug',
  'Istanbul',
  'Kadikoy',
  'Demo street 10',
  '+90 555 000 00 00',
  'TRY',
  true
)
on conflict (id) do nothing;

insert into public.menu_settings (
  business_id,
  theme_id,
  show_prices,
  default_locale,
  supported_locales
)
values (
  '11111111-1111-1111-1111-111111111111',
  'minimal',
  true,
  'tr',
  array['tr','en']
)
on conflict (business_id) do nothing;

insert into public.menu_categories (id, business_id, sort, is_active)
values
  ('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', 0, true),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 1, true)
on conflict (id) do nothing;

insert into public.menu_items (id, business_id, category_id, price_cents, is_available, tags, sort)
values
  ('33333333-3333-3333-3333-333333333331', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 18000, true, '["cold"]'::jsonb, 0),
  ('33333333-3333-3333-3333-333333333332', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 42000, true, '["spicy"]'::jsonb, 0)
on conflict (id) do nothing;

insert into public.menu_translations (entity_type, entity_id, locale, name, description)
values
  ('business', '11111111-1111-1111-1111-111111111111', 'tr', 'Demo Bistro', 'Dijital QR menü demo işletmesi'),
  ('business', '11111111-1111-1111-1111-111111111111', 'en', 'Demo Bistro', 'Digital QR menu demo business'),
  ('category', '22222222-2222-2222-2222-222222222221', 'tr', 'Baslangiclar', null),
  ('category', '22222222-2222-2222-2222-222222222221', 'en', 'Starters', null),
  ('category', '22222222-2222-2222-2222-222222222222', 'tr', 'Ana Yemekler', null),
  ('category', '22222222-2222-2222-2222-222222222222', 'en', 'Main Dishes', null),
  ('item', '33333333-3333-3333-3333-333333333331', 'tr', 'Humus', 'Zeytinyagli nohut ezmesi'),
  ('item', '33333333-3333-3333-3333-333333333331', 'en', 'Hummus', 'Chickpea dip with olive oil'),
  ('item', '33333333-3333-3333-3333-333333333332', 'tr', 'Adana Kebap', 'Acili izgara kebap'),
  ('item', '33333333-3333-3333-3333-333333333332', 'en', 'Adana Kebab', 'Spicy grilled kebab')
on conflict (entity_type, entity_id, locale) do update set
  name = excluded.name,
  description = excluded.description;

insert into public.qr_links (code, business_id, locale)
values ('demoqr01', '11111111-1111-1111-1111-111111111111', 'tr')
on conflict (code) do nothing;
