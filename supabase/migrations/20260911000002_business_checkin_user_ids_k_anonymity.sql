-- P1: get_business_checkin_user_ids_v1 anon'a raw user_id listesi döndürüyordu.
-- 42K+ işletme ID'si üzerinden döngüyle çağrılınca anonim bir kullanıcı-mekan
-- ziyaret grafiği çıkarılabiliyordu (özellikle az ziyaretçili işletmelerde her
-- id neredeyse tek bir gerçek kişiye karşılık gelir — düşük k-anonimlik).
-- Fonksiyonun asıl amacı (yorumları "doğrulanmış ziyaret" filtresiyle
-- gösterme) büyük işletmeler için zaten geniş bir anonimlik kümesiyle
-- çalışıyor; küçük işletmelerde liste boş dönerek düşük-k durumunu kapatıyoruz.
CREATE OR REPLACE FUNCTION public.get_business_checkin_user_ids_v1(p_business_id uuid)
RETURNS uuid[]
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT CASE WHEN count(DISTINCT user_id) >= 5
    THEN coalesce(array_agg(DISTINCT user_id), ARRAY[]::uuid[])
    ELSE ARRAY[]::uuid[]
  END
  FROM public.business_checkins
  WHERE business_id = p_business_id AND user_id IS NOT NULL;
$$;

COMMENT ON FUNCTION public.get_business_checkin_user_ids_v1 IS 'Returns user_ids checked in at a business, for the "Doğrulanmış" review filter — only when >=5 distinct check-ins exist (k-anonymity floor). Called by: isletme-detay-tablari.tsx.';
