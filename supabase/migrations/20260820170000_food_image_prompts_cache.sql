-- Görsel üretim pipeline'ı yeniden tasarlandı: her seferinde AI'a prompt
-- yazdırmak yerine (a) statik bir food-photography şablonu VARSAYILAN yol,
-- (b) sadece açıklaması olan (yani şablonun yetersiz kalacağı) ürünlerde
-- Gemini Flash-Lite prompt üretiyor, (c) üretilen prompt kalıcı olarak
-- cache'leniyor ki aynı ürün adı bir daha hiç AI'a gitmesin.
--
-- Bu tablo yalnızca edge fonksiyonu tarafından SERVICE ROLE ile okunup
-- yazılıyor (anon/authenticated'a hiç açık değil, kasıtlı — internal cache).

CREATE TABLE public.food_image_prompts (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  normalized_food_name text NOT NULL,
  language            text NOT NULL DEFAULT 'tr',
  prompt               text NOT NULL,
  model                text NOT NULL,  -- 'template' | 'gemini-2.5-flash-lite'
  created_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (normalized_food_name, language)
);

ALTER TABLE public.food_image_prompts ENABLE ROW LEVEL SECURITY;
-- Kasıtlı olarak hiç policy yok — sadece service role (RLS'i bypass eder)
-- erişir. anon/authenticated bu tabloya hiç dokunmamalı.
