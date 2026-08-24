CREATE OR REPLACE FUNCTION public.create_support_ticket_v1(
  p_business_id uuid, p_category text, p_subject text, p_message text
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
  v_priority text := 'medium';
  v_tier text;
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

  IF p_business_id IS NOT NULL THEN
    v_tier := public._get_business_plan_tier_v1(p_business_id);
    v_priority := CASE v_tier
      WHEN 'pro' THEN 'urgent'
      WHEN 'standard' THEN 'high'
      ELSE 'medium'
    END;
  END IF;

  SELECT display_name INTO v_display_name FROM public.user_profiles WHERE user_id = auth.uid();
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();

  INSERT INTO public.support_tickets (user_id, business_id, requester_name, requester_email, subject, category, priority)
  VALUES (auth.uid(), p_business_id, v_display_name, v_email, trim(p_subject), p_category, v_priority)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.support_ticket_messages (ticket_id, sender, message, created_by)
  VALUES (v_ticket_id, 'user', trim(p_message), auth.uid());

  RETURN v_ticket_id;
END;
$$;

COMMENT ON FUNCTION public.create_support_ticket_v1 IS
  'Destek talebi oluşturur. İşletme bazlı taleplerde priority, işletmenin plan kademesine göre otomatik atanır (pro=urgent, standard=high, free/starter=medium). Kullanıcı girdisi değil.';
