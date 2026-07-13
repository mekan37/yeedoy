-- Seed: yemek kartı sağlayıcıları
-- Türkiye'de yaygın kullanılan 7 yemek kartı. key değerleri
-- public asset yollarıyla eşleşir: /meal-cards/meal_card_{key}.png

INSERT INTO public.meal_card_providers (id, key, name, asset_name, is_active, sort_order)
VALUES
  (gen_random_uuid(), 'multinet',   'Multinet',   'meal_card_multinet',   true, 1),
  (gen_random_uuid(), 'edenred',    'Edenred',    'meal_card_edenred',    true, 2),
  (gen_random_uuid(), 'tokenflex',  'TokenFlex',  'meal_card_tokenflex',  true, 3),
  (gen_random_uuid(), 'setcard',    'Setcard',    'meal_card_setcard',    true, 4),
  (gen_random_uuid(), 'pluxee',     'Pluxee',     'meal_card_pluxee',     true, 5),
  (gen_random_uuid(), 'metropol',   'Metropol',   'meal_card_metropol',   true, 6),
  (gen_random_uuid(), 'yemekmatik', 'Yemekmatik', 'meal_card_yemekmatik', true, 7)
ON CONFLICT (key) DO NOTHING;
