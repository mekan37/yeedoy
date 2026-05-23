-- Bildirim Tetikleyicileri (5 kritik trigger)
-- Tüm fonksiyonlar mevcut "notifications" tablosuna kayıt ekler.
-- Edge Function (send-push-notification) bu kayıtları dinleyerek FCM'ye gönderir.

-- ─── 1. Fiyat değişti bildirimi ───────────────────────────────────────────────
-- Bir fiyat önerisi onaylandığında, o menü ürünü için alarmı olan kullanıcılara bildir.
CREATE OR REPLACE FUNCTION notify_price_alert_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  -- Yalnızca onaylanan fiyat önerilerinde çalış
  IF NEW.status IS DISTINCT FROM 'approved' OR OLD.status = 'approved' THEN
    RETURN NEW;
  END IF;

  -- O ürün için fiyat alarmı olan kullanıcılara bildirim gönder
  FOR rec IN
    SELECT pa.user_id, mi.name AS item_name, b.name AS business_name, b.id AS business_id
    FROM price_alerts pa
    JOIN menu_items mi ON mi.id = NEW.menu_item_id
    JOIN businesses b ON b.id = mi.business_id
    WHERE pa.menu_item_id = NEW.menu_item_id
      AND pa.is_active = true
  LOOP
    INSERT INTO notifications (user_id, type, title, message, target_path, meta)
    VALUES (
      rec.user_id,
      'price_alert',
      rec.item_name || ' fiyatı güncellendi',
      rec.business_name || ': ' || (NEW.price_cents::float / 100)::text || ' ₺',
      '/isletme/' || rec.business_id::text,
      jsonb_build_object(
        'business_id', rec.business_id,
        'menu_item_id', NEW.menu_item_id,
        'new_price_cents', NEW.price_cents
      )
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS price_suggestion_approved_notify ON menu_item_price_suggestions;
CREATE TRIGGER price_suggestion_approved_notify
  AFTER UPDATE OF status ON menu_item_price_suggestions
  FOR EACH ROW EXECUTE FUNCTION notify_price_alert_trigger();

-- ─── 2. Yeni işletme açıldı bildirimi ────────────────────────────────────────
-- Onaylanan yeni işletme aynı şehirdeki kullanıcılara bildirim gönderir.
-- Günlük max 1 bildirim (aynı şehir için) — spam önlemi.
CREATE OR REPLACE FUNCTION notify_new_business_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
  city_val TEXT;
BEGIN
  -- Yalnızca is_active true olduğunda veya status 'approved' olduğunda
  IF NOT NEW.is_active THEN RETURN NEW; END IF;
  city_val := NEW.city;
  IF city_val IS NULL OR city_val = '' THEN RETURN NEW; END IF;

  -- Aynı şehirde son 24 saatte yeni işletme bildirimi görmemiş kullanıcılar
  FOR rec IN
    SELECT DISTINCT f.user_id
    FROM favorites f
    JOIN businesses b ON b.id = f.business_id AND b.city = city_val
    WHERE NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.user_id = f.user_id
        AND n.type = 'new_business'
        AND n.created_at > NOW() - INTERVAL '24 hours'
    )
    LIMIT 500
  LOOP
    INSERT INTO notifications (user_id, type, title, message, target_path, meta)
    VALUES (
      rec.user_id,
      'new_business',
      city_val || ''' da yeni bir yer açıldı!',
      NEW.name || ' — keşfetmek ister misin?',
      '/isletme/' || NEW.id::text,
      jsonb_build_object('business_id', NEW.id, 'city', city_val)
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS new_business_notify ON businesses;
CREATE TRIGGER new_business_notify
  AFTER INSERT ON businesses
  FOR EACH ROW EXECUTE FUNCTION notify_new_business_trigger();

-- ─── 3. İşletme kapandı bildirimi ─────────────────────────────────────────────
-- Favori işletme is_active false olunca favorileyen kullanıcılara bildir.
CREATE OR REPLACE FUNCTION notify_business_closed_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  -- Yalnızca aktif → pasif geçişinde
  IF OLD.is_active IS NOT DISTINCT FROM NEW.is_active THEN RETURN NEW; END IF;
  IF NEW.is_active THEN RETURN NEW; END IF;

  FOR rec IN
    SELECT f.user_id
    FROM favorites f
    WHERE f.business_id = NEW.id
  LOOP
    INSERT INTO notifications (user_id, type, title, message, target_path, meta)
    VALUES (
      rec.user_id,
      'business_closed',
      NEW.name || ' artık hizmet vermiyor',
      'Favori listenizden kaldırmak isteyebilirsiniz.',
      '/isletme/' || NEW.id::text,
      jsonb_build_object('business_id', NEW.id)
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS business_closed_notify ON businesses;
CREATE TRIGGER business_closed_notify
  AFTER UPDATE OF is_active ON businesses
  FOR EACH ROW EXECUTE FUNCTION notify_business_closed_trigger();

-- ─── 4. Katkıdan puan kazanıldı bildirimi ─────────────────────────────────────
-- Fiyat önerisi onaylanınca katkıda bulunan kullanıcıya bildir.
CREATE OR REPLACE FUNCTION notify_contribution_approved_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM 'approved' OR OLD.status = 'approved' THEN
    RETURN NEW;
  END IF;
  IF NEW.user_id IS NULL THEN RETURN NEW; END IF;

  INSERT INTO notifications (user_id, type, title, message, target_path, meta)
  VALUES (
    NEW.user_id,
    'contribution_approved',
    'Katkınız onaylandı!',
    'Fiyat güncellemeniz kabul edildi. Puan kazandınız!',
    '/profil',
    jsonb_build_object('menu_item_id', NEW.menu_item_id)
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS contribution_approved_notify ON menu_item_price_suggestions;
CREATE TRIGGER contribution_approved_notify
  AFTER UPDATE OF status ON menu_item_price_suggestions
  FOR EACH ROW EXECUTE FUNCTION notify_contribution_approved_trigger();

-- ─── 5. Yorum yanıtlandı bildirimi ──────────────────────────────────────────
-- İşletme sahibi yoruma yanıt verince yorum yazan kullanıcıya bildir.
CREATE OR REPLACE FUNCTION notify_review_reply_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  business_name TEXT;
BEGIN
  -- Yalnızca owner_reply null → değer geçişinde
  IF OLD.owner_reply IS NOT NULL OR NEW.owner_reply IS NULL THEN RETURN NEW; END IF;
  IF NEW.user_id IS NULL THEN RETURN NEW; END IF;

  SELECT name INTO business_name
  FROM businesses WHERE id = NEW.business_id;

  INSERT INTO notifications (user_id, type, title, message, target_path, meta)
  VALUES (
    NEW.user_id,
    'review_reply',
    (business_name || ' yorumunuzu yanıtladı'),
    NEW.owner_reply,
    '/isletme/' || NEW.business_id::text || '/yorumlar',
    jsonb_build_object('business_id', NEW.business_id, 'review_id', NEW.id)
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS review_reply_notify ON reviews;
CREATE TRIGGER review_reply_notify
  AFTER UPDATE OF owner_reply ON reviews
  FOR EACH ROW EXECUTE FUNCTION notify_review_reply_trigger();

-- NOT: FCM push gönderimi için Supabase Edge Function (send-push-notification)
-- postgres_changes realtime hook ile notifications tablosunu dinler ve
-- ilgili kullanıcının FCM token'ına (user_push_tokens tablosunda kayıtlı)
-- Firebase Cloud Messaging API üzerinden bildirim gönderir.
-- Edge Function'ın deploy edilmesi için: supabase functions deploy send-push-notification
