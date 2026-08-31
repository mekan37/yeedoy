-- Bu iki kolon önceden şemaya eklenmiş ama hiç doldurulmamış/tetiklenmemişti —
-- check_regional_recommendation_v1 bu yüzden hiçbir işletmeyle eşleşmiyordu (49.156 satırın hepsi NULL).
-- Mevcut tüm satırları normalize_tr_location_text() ile geriye dönük doldur:
UPDATE public.businesses
SET city_norm = public.normalize_tr_location_text(city),
    district_norm = public.normalize_tr_location_text(district)
WHERE city_norm IS DISTINCT FROM public.normalize_tr_location_text(city)
   OR district_norm IS DISTINCT FROM public.normalize_tr_location_text(district);

-- Bundan sonra city/district her değiştiğinde otomatik güncel kalsın diye bir trigger ekle.
CREATE OR REPLACE FUNCTION public.tg_businesses_sync_location_norm()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.city_norm := public.normalize_tr_location_text(NEW.city);
  NEW.district_norm := public.normalize_tr_location_text(NEW.district);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS businesses_sync_location_norm ON public.businesses;
CREATE TRIGGER businesses_sync_location_norm
  BEFORE INSERT OR UPDATE OF city, district ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.tg_businesses_sync_location_norm();

-- CREATE OR REPLACE FUNCTION için parametre eklemek, Postgres'te fonksiyonu DEĞİL yeni bir
-- overload'ı oluşturuyor (fonksiyonlar isim+argüman-tipi listesiyle tanımlanır) — 2 parametreli
-- eski sürüm artık ölü/gölgelenen kod. Doğrulandı: hiçbir SQL fonksiyonu/trigger 2 argümanla
-- çağırmıyor, mobil taste_twin_repository.dart named-param (p_display_name, p_avatar_url) ile
-- çağırıyor ve bu, 3 parametreli sürüme (p_city DEFAULT NULL) sorunsuz çözümlenir. Kaldırılıyor,
-- tek bir 3 parametreli sürüm kalıyor.
DROP FUNCTION IF EXISTS public.ensure_my_profile_v1(text, text);
