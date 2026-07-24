-- businesses tablosunda tekli INSERT ortalama 2 saniye, uçlarda ~4.7 saniye sürüyordu
-- (pg_stat_statements ile ölçüldü, toplu import RPC'lerinin dışında — owner/admin
-- panelinden gelen INSERT'ler). Kök neden iki ayrı trigger sorunuydu:

-- 1) İki AYRI trigger aynı işi (lat/lng'den geog kolonu hesaplama) yapıyordu:
--    trg_businesses_sync_geog (tg_businesses_sync_geog) ve trg_sync_business_geog
--    (_fn_sync_business_geog) — ikisi de "BEFORE INSERT OR UPDATE OF lat, lng"
--    üzerinde tetikleniyor, ikisi de aynı ST_SetSRID(ST_MakePoint(...)) hesabını
--    yapıyor. trg_businesses_sync_geog daha eksiksiz (lat/lng null olduğunda geog'u
--    da null'a çekiyor), o tutuluyor; diğeri (ve tek kullanıcısı olan fonksiyonu)
--    siliniyor.
DROP TRIGGER IF EXISTS trg_sync_business_geog ON public.businesses;
DROP FUNCTION IF EXISTS public._fn_sync_business_geog();

-- 2) notify_new_business_trigger() her yeni (is_active=true, city dolu) işletme
--    INSERT'inde, o şehirde favorisi olan kullanıcıları PL/pgSQL FOR döngüsüyle
--    tek tek dolaşıp (en fazla 500 kullanıcı) HER BİRİ İÇİN AYRI bir INSERT
--    çalıştırıyordu — INSERT transaction'ı içinde senkron olarak. Kullanıcı/favori
--    sayısı arttıkça bu maliyet büyüyecekti. Aynı sonucu üreten TEK bir set-tabanlı
--    INSERT...SELECT'e çevrildi (davranış birebir aynı: aynı filtre, aynı LIMIT,
--    aynı ON CONFLICT DO NOTHING) — artık tek statement, döngü yok.
CREATE OR REPLACE FUNCTION public.notify_new_business_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  city_val TEXT;
BEGIN
  IF NOT NEW.is_active THEN RETURN NEW; END IF;
  city_val := NEW.city;
  IF city_val IS NULL OR city_val = '' THEN RETURN NEW; END IF;

  INSERT INTO notifications (user_id, type, title, body, data, is_read)
  SELECT DISTINCT
    f.user_id,
    'new_business',
    city_val || '''da yeni bir yer açıldı!',
    NEW.name || ' — keşfetmek ister misin?',
    jsonb_build_object('business_id', NEW.id, 'city', city_val, 'target_path', '/isletme/' || NEW.id::text),
    false
  FROM favorites f
  JOIN businesses b ON b.id = f.business_id AND b.city = city_val
  WHERE NOT EXISTS (
    SELECT 1 FROM notifications n
    WHERE n.user_id = f.user_id
      AND n.type = 'new_business'
      AND n.created_at > NOW() - INTERVAL '24 hours'
  )
  LIMIT 500
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$function$;
