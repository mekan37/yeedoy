-- get_advisors(security) uyarısı: allergens ve allergen_ingredient_aliases
-- RLS'i açık ama hiç policy yoktu (hiçbir role okuyamıyordu). İkisi de
-- hassas olmayan, halka açık referans verisi (alerjen kodları + malzeme
-- sözlüğü) — herkese açık SELECT ekleniyor.

CREATE POLICY "public_read_allergens"
  ON public.allergens
  FOR SELECT
  TO anon, authenticated
  USING (true);

GRANT SELECT ON public.allergens TO anon, authenticated;

CREATE POLICY "public_read_allergen_ingredient_aliases"
  ON public.allergen_ingredient_aliases
  FOR SELECT
  TO anon, authenticated
  USING (true);

GRANT SELECT ON public.allergen_ingredient_aliases TO anon, authenticated;
