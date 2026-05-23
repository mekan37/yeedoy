-- Phase 4: Personel app — kampanya bildirimi + yorum RPC grant

-- İşletme sahibi takipçilerine toplu bildirim gönderir
CREATE OR REPLACE FUNCTION send_business_campaign_v1(
  p_business_id UUID,
  p_title       TEXT,
  p_message     TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id     UUID;
  follower_count INT := 0;
BEGIN
  SELECT owner_id INTO v_owner_id
  FROM businesses WHERE id = p_business_id;

  IF v_owner_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  p_title   := TRIM(p_title);
  p_message := TRIM(p_message);

  IF LENGTH(p_title)   < 1 OR LENGTH(p_title)   > 100 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_title');
  END IF;
  IF LENGTH(p_message) < 1 OR LENGTH(p_message) > 500 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_message');
  END IF;

  INSERT INTO notifications (user_id, type, title, message, target_path, meta)
  SELECT
    bf.user_id,
    'business_campaign',
    p_title,
    p_message,
    '/isletme/' || p_business_id::text,
    jsonb_build_object('business_id', p_business_id)
  FROM business_follows bf
  WHERE bf.business_id = p_business_id
  LIMIT 1000
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS follower_count = ROW_COUNT;

  RETURN jsonb_build_object('ok', true, 'sent_to', follower_count);
END;
$$;

GRANT EXECUTE ON FUNCTION send_business_campaign_v1            TO authenticated;
GRANT EXECUTE ON FUNCTION submit_owner_review_reply_v1         TO authenticated;
GRANT EXECUTE ON FUNCTION delete_owner_review_reply_v1         TO authenticated;
