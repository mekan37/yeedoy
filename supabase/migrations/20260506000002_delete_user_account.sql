-- Kullanıcı hesabı silme (KVKK/GDPR talep üzerine)
-- Cascade: favorites, reviews, price_suggestions, notifications, alerts
-- Auth kaydı ayrıca silinmeli — bu RPC yalnızca uygulama verilerini temizler.
-- Supabase Auth kaydı için auth.admin.deleteUser() servis rolüyle çağrılır.
CREATE OR REPLACE FUNCTION delete_user_account_v1()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  -- Katkı verileri anonim bırak (fiyat doğruluğu korunur), user_id kaldırılır
  UPDATE menu_item_price_suggestions
  SET user_id = NULL
  WHERE user_id = v_uid;

  UPDATE business_reviews
  SET user_id = NULL
  WHERE user_id = v_uid;

  -- Kişisel etkileşimler silinir
  DELETE FROM favorites        WHERE user_id = v_uid;
  DELETE FROM price_alerts     WHERE user_id = v_uid;
  DELETE FROM notifications    WHERE user_id = v_uid;
  DELETE FROM review_votes     WHERE user_id = v_uid;

  -- Profil verisi silinir
  DELETE FROM user_profiles WHERE user_id = v_uid;

  RETURN jsonb_build_object('ok', true, 'uid', v_uid);
END;
$$;
