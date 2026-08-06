-- Owner destek talebi oluşturma — ticket + ilk mesaj tek transaction'da (atomik).
-- destekTalebiOlustur (app/sahip/destek/destek-islemleri.ts) artık iki ayrı
-- INSERT yerine bu RPC'yi çağırıyor; ikinci INSERT başarısız olursa mesajsız
-- bir ticket kalması riski ortadan kalkıyor.
--
-- E-posta: auth.jwt() ->> 'email' yerine auth.users tablosundan okunuyor —
-- bu repoda kurulu tek emsal (claim_pending_team_invites_v1,
-- 20260722000001) aynı deseni kullanıyor; JWT claim'ine güvenmek yerine
-- her zaman güncel DB değerini okumak daha güvenilir.

CREATE OR REPLACE FUNCTION public.create_support_ticket_v1(
  p_business_id uuid,
  p_category text,
  p_subject text,
  p_message text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ticket_id uuid;
  v_display_name text;
  v_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_id IS NOT NULL AND NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: bu işletme için yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF trim(coalesce(p_subject, '')) = '' OR trim(coalesce(p_message, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: konu ve mesaj boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  SELECT display_name INTO v_display_name FROM public.user_profiles WHERE user_id = auth.uid();
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();

  INSERT INTO public.support_tickets (user_id, business_id, requester_name, requester_email, subject, category)
  VALUES (auth.uid(), p_business_id, v_display_name, v_email, trim(p_subject), p_category)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.support_ticket_messages (ticket_id, sender, message, created_by)
  VALUES (v_ticket_id, 'user', trim(p_message), auth.uid());

  RETURN v_ticket_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_support_ticket_v1(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_support_ticket_v1(uuid, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.create_support_ticket_v1(uuid, text, text, text) FROM anon;
COMMENT ON FUNCTION public.create_support_ticket_v1 IS
  'Owner: destek talebi + ilk mesajı tek transaction''da (atomik) oluşturur. Called by: app/sahip/destek/destek-islemleri.ts:destekTalebiOlustur.';
