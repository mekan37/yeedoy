-- trg_notify_price_alert_event_v1 (v2)
-- Enriches the push notification body with savings amount when price drops.
-- e.g. "Adana Kebap düştü! 25₺ tasarruf edebilirsin." instead of generic "fiyat değişti."

CREATE OR REPLACE FUNCTION public.trg_notify_price_alert_event_v1()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_name text;
  v_item_name     text;
  v_savings_cents bigint;
  v_title         text;
  v_body          text;
BEGIN
  IF tg_op <> 'INSERT' THEN
    RETURN new;
  END IF;

  SELECT b.name INTO v_business_name
  FROM public.businesses b
  WHERE b.id = new.business_id;

  SELECT mi.name INTO v_item_name
  FROM public.menu_items mi
  WHERE mi.id = new.menu_item_id;

  -- Calculate savings (positive = price dropped)
  v_savings_cents := COALESCE(new.previous_price_cents, 0) - COALESCE(new.matched_price_cents, 0);

  IF v_savings_cents > 0 THEN
    v_title := '📉 Fiyat düştü!';
    v_body  := coalesce(v_item_name, 'Ürün')
               || ' ' || round(v_savings_cents::numeric / 100, 0)::text || '₺ ucuzladı!'
               || ' ' || coalesce(v_business_name, 'İşletme')
               || '''de tasarruf et.';
  ELSE
    v_title := '⚠️ Fiyat değişimi';
    v_body  := coalesce(v_business_name, 'İşletme')
               || ' mekanında '
               || coalesce(v_item_name, 'ürün')
               || ' fiyatı güncellendi.';
  END IF;

  PERFORM public.notify_user_v1(
    new.user_id,
    'favorite_price_changed',
    v_title,
    v_body,
    jsonb_build_object(
      'business_id',            new.business_id,
      'menu_item_id',           new.menu_item_id,
      'alert_event_id',         new.id,
      'matched_price_cents',    new.matched_price_cents,
      'previous_price_cents',   new.previous_price_cents,
      'savings_cents',          GREATEST(v_savings_cents, 0),
      'district_avg_price_cents', new.district_avg_price_cents,
      'meaningful_change',      true,
      'verified_change',        true
    )
  );

  RETURN new;
END;
$$;
