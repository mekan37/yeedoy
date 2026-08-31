-- etiketKaydet server action'ının optimistic UI güncellemesi için city_norm'a
-- ihtiyacı var (bkz. add_city_norm_to_regional_cuisine_tags_and_expose_in_admin_rpcs).
-- Client'ta normalize_tr_location_text'i tekrar implemente etmek yerine (bu
-- projenin daha önce defalarca yaşadığı Türkçe normalize bug sınıfını
-- tekrarlama riski), RPC artık {id, city_norm} jsonb döndürüyor — tek doğru
-- kaynak veritabanındaki generated column.
DROP FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text);

CREATE FUNCTION public.admin_upsert_regional_cuisine_tag_v1(p_id uuid DEFAULT NULL::uuid, p_city text DEFAULT NULL::text, p_label text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_id uuid;
  v_city_norm text;
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
      RETURNING id, city_norm INTO v_id, v_city_norm;
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
      RETURNING id, city_norm INTO v_id, v_city_norm;
    EXCEPTION
      WHEN unique_violation THEN
        RAISE EXCEPTION 'validation_error: bu şehir ve etiket kombinasyonu zaten var' USING ERRCODE = 'P0003';
    END;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN jsonb_build_object('id', v_id, 'city_norm', v_city_norm);
END;
$function$
;

REVOKE ALL ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM anon;
