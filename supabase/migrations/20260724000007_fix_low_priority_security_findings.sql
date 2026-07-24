-- Düşük öncelikli, risksiz düzeltmeler.

-- NOT: spatial_ref_sys (PostGIS sistem tablosu) için RLS açma denendi ama
-- "must be owner of table" hatası alındı — bu tablo postgis extension'ına ait,
-- Supabase projelerinde uygulama rolünün sahiplik yetkisi yok. Bilinen bir
-- Supabase/PostGIS kısıtlaması, atlandı. Gerçek risk zaten düşüktü (tablo
-- sadece herkese açık SRID/koordinat referans metadata'sı içeriyor).

-- 3 fonksiyonda search_path ayarlanmamıştı (hiçbiri SECURITY DEFINER değil,
--    gerçek enjeksiyon riski düşük — ama ücretsiz düzeltilebilir).
CREATE OR REPLACE FUNCTION public.tg_campaigns_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$function$;

CREATE OR REPLACE FUNCTION public.tg_qr_codes_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_extract_review_tags_v1()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
DECLARE
  v_body  text;
  v_tag   text;
  v_tags  text[];
BEGIN
  IF tg_op <> 'INSERT' THEN RETURN new; END IF;

  IF new.status IS NOT NULL AND new.status <> 'approved' THEN RETURN new; END IF;
  v_body := lower(coalesce(new.content, ''));
  IF char_length(v_body) < 5 THEN RETURN new; END IF;

  v_tags := ARRAY[]::text[];

  IF v_body ILIKE ANY(ARRAY['%bol porsiyon%','%porsiyon büyük%','%porsiyon bol%','%çok geldi%','%fazla geldi%'])
  THEN v_tags := array_append(v_tags, 'Bol Porsiyon'); END IF;

  IF v_body ILIKE ANY(ARRAY['%porsiyon küçük%','%az geldi%','%az porsiyon%','%küçük porsiyon%','%yetersiz miktar%'])
  THEN v_tags := array_append(v_tags, 'Küçük Porsiyon'); END IF;

  IF v_body ILIKE ANY(ARRAY['%personel ilgili%','%garson ilgili%','%nazik%','%güler yüzlü%','%yardımcı%','%güler yüz%','%samimi%'])
  THEN v_tags := array_append(v_tags, 'İlgili Personel'); END IF;

  IF v_body ILIKE ANY(ARRAY['%personel kaba%','%garson kötü%','%ilgisiz%','%umursamaz%','%kötü davrand%'])
  THEN v_tags := array_append(v_tags, 'İlgisiz Personel'); END IF;

  IF v_body ILIKE ANY(ARRAY['%hızlı servis%','%hızlı geldi%','%çabuk geldi%','%hızlıydı%','%beklemedim%','%anında geldi%'])
  THEN v_tags := array_append(v_tags, 'Hızlı Servis'); END IF;

  IF v_body ILIKE ANY(ARRAY['%yavaş%','%çok beklettiler%','%uzun sürdü%','%bekledik%','%gecikti%','%geç geldi%'])
  THEN v_tags := array_append(v_tags, 'Yavaş Servis'); END IF;

  IF v_body ILIKE ANY(ARRAY['%çok temiz%','%temiz mekan%','%hijyenik%','%bakımlı%','%pırıl pırıl%'])
  THEN v_tags := array_append(v_tags, 'Temiz Mekan'); END IF;

  IF v_body ILIKE ANY(ARRAY['%kirli%','%bakımsız%','%hijyenik değil%','%pis%'])
  THEN v_tags := array_append(v_tags, 'Kirli Mekan'); END IF;

  IF v_body ILIKE ANY(ARRAY['%fiyatı uygun%','%hesaplı%','%ekonomik%','%ucuz%','%fiyat performans%','%fiyat/performans%'])
  THEN v_tags := array_append(v_tags, 'Uygun Fiyat'); END IF;

  IF v_body ILIKE ANY(ARRAY['%çok pahalı%','%pahalı%','%fiyat yüksek%','%fahiş%'])
  THEN v_tags := array_append(v_tags, 'Pahalı'); END IF;

  IF v_body ILIKE ANY(ARRAY['%lezzetli%','%muhteşem%','%enfes%','%harika lezzet%','%çok güzeldi%','%nefis%','%harika tat%'])
  THEN v_tags := array_append(v_tags, 'Lezzetli'); END IF;

  IF v_body ILIKE ANY(ARRAY['%lezzetsiz%','%tatsız%','%kötü lezzet%','%berbat%','%iğrenç%'])
  THEN v_tags := array_append(v_tags, 'Lezzetsiz'); END IF;

  IF v_body ILIKE ANY(ARRAY['%ortam güzel%','%güzel ortam%','%ambiyans%','%dekor güzel%','%atmosfer%','%şık%','%keyifli ortam%'])
  THEN v_tags := array_append(v_tags, 'Güzel Ortam'); END IF;

  IF v_body ILIKE ANY(ARRAY['%gürültülü%','%çok ses%','%rahatsız edici%','%kötü ortam%'])
  THEN v_tags := array_append(v_tags, 'Gürültülü'); END IF;

  IF v_body ILIKE ANY(ARRAY['%tekrar geleceğim%','%kesinlikle öneririm%','%tavsiye ederim%','%herkese öneririm%','%mutlaka gelin%'])
  THEN v_tags := array_append(v_tags, 'Tavsiye Ederim'); END IF;

  IF v_body ILIKE ANY(ARRAY['%bir daha gitmem%','%gelmeyeceğim%','%önermiyorum%','%tavsiye etmiyorum%'])
  THEN v_tags := array_append(v_tags, 'Önermiyorum'); END IF;

  FOREACH v_tag IN ARRAY v_tags LOOP
    INSERT INTO public.review_tags (business_id, tag, mention_count, last_seen_at)
    VALUES (new.business_id, v_tag, 1, now())
    ON CONFLICT (business_id, tag) DO UPDATE
      SET mention_count = review_tags.mention_count + 1,
          last_seen_at  = now();
  END LOOP;

  RETURN new;
END;
$function$;
