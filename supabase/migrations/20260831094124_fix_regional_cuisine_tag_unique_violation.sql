-- Code review bulgusu: admin_upsert_regional_cuisine_tag_v1, unique(city, label)
-- ihlalini yakalamıyordu; ham 23505 (unique_violation) admin panele sızıyordu.
-- Diğer validasyon hatalarıyla aynı örüntüye (validation_error / P0003) çekildi.
CREATE OR REPLACE FUNCTION public.admin_upsert_regional_cuisine_tag_v1(
  p_id uuid DEFAULT NULL::uuid,
  p_city text DEFAULT NULL::text,
  p_label text DEFAULT NULL::text
)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    IF p_city IS NULL OR trim(p_city) = '' THEN
      RAISE EXCEPTION 'validation_error: city zorunlu' USING ERRCODE = 'P0003';
    END IF;
    IF p_label IS NULL OR trim(p_label) = '' THEN
      RAISE EXCEPTION 'validation_error: label zorunlu' USING ERRCODE = 'P0003';
    END IF;
    BEGIN
      INSERT INTO public.regional_cuisine_tags (city, label)
      VALUES (trim(p_city), trim(p_label))
      RETURNING id INTO v_id;
    EXCEPTION
      WHEN unique_violation THEN
        RAISE EXCEPTION 'validation_error: bu şehir ve etiket kombinasyonu zaten var' USING ERRCODE = 'P0003';
    END;
  ELSE
    BEGIN
      UPDATE public.regional_cuisine_tags
      SET
        city = COALESCE(NULLIF(trim(p_city), ''), city),
        label = COALESCE(NULLIF(trim(p_label), ''), label)
      WHERE id = p_id
      RETURNING id INTO v_id;
    EXCEPTION
      WHEN unique_violation THEN
        RAISE EXCEPTION 'validation_error: bu şehir ve etiket kombinasyonu zaten var' USING ERRCODE = 'P0003';
    END;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$function$;
