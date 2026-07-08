-- Giriş yapmadan işletme öneri yapılabilsin (anon + authenticated)
DROP POLICY IF EXISTS "business_suggestions_insert_access" ON public.business_suggestions;

CREATE POLICY "business_suggestions_insert_access"
  ON public.business_suggestions
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

COMMENT ON POLICY "business_suggestions_insert_access" ON public.business_suggestions
  IS 'Herkes (giriş yapmadan da) işletme önerisi gönderebilir.';
