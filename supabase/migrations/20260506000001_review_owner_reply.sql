-- İşletme sahibinin yoruma yanıt vermesi için sütunlar
-- RLS: yalnızca o işletmenin sahibi yanıt yazabilir
ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS owner_reply        TEXT,
  ADD COLUMN IF NOT EXISTS owner_replied_at   TIMESTAMPTZ;

-- Sahibin kendi işletmesine ait yorumu yanıtlamasına izin veren RPC
CREATE OR REPLACE FUNCTION submit_owner_review_reply_v1(
  p_review_id   UUID,
  p_reply_text  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_owner_id    UUID;
BEGIN
  -- Yorumun hangi işletmeye ait olduğunu bul
  SELECT business_id INTO v_business_id
  FROM reviews
  WHERE id = p_review_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'review_not_found');
  END IF;

  -- İsteği yapan kullanıcı bu işletmenin sahibi mi?
  SELECT owner_id INTO v_owner_id
  FROM businesses
  WHERE id = v_business_id;

  IF v_owner_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  -- Yanıt metnini doğrula
  p_reply_text := TRIM(p_reply_text);
  IF LENGTH(p_reply_text) < 1 OR LENGTH(p_reply_text) > 2000 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_reply_length');
  END IF;

  -- Yanıtı kaydet
  UPDATE reviews
  SET
    owner_reply      = p_reply_text,
    owner_replied_at = NOW()
  WHERE id = p_review_id;

  RETURN jsonb_build_object('ok', true, 'replied_at', NOW());
END;
$$;

-- Sahip yanıtını silmek için RPC (geri al butonu)
CREATE OR REPLACE FUNCTION delete_owner_review_reply_v1(
  p_review_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_owner_id    UUID;
BEGIN
  SELECT business_id INTO v_business_id
  FROM reviews WHERE id = p_review_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'review_not_found');
  END IF;

  SELECT owner_id INTO v_owner_id
  FROM businesses WHERE id = v_business_id;

  IF v_owner_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  UPDATE reviews
  SET owner_reply = NULL, owner_replied_at = NULL
  WHERE id = p_review_id;

  RETURN jsonb_build_object('ok', true);
END;
$$;
