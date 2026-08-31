-- Task 1 code review bulgusu: regional_tag_id üzerinde index eksikti.
CREATE INDEX businesses_regional_tag_id_idx ON public.businesses (regional_tag_id) WHERE regional_tag_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.admin_list_regional_cuisine_tags_v1()
RETURNS TABLE (id uuid, city text, label text, business_count bigint, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT t.id, t.city, t.label,
           (SELECT count(*) FROM public.businesses b WHERE b.regional_tag_id = t.id),
           t.created_at
    FROM public.regional_cuisine_tags t
    ORDER BY t.city, t.label;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM anon;
COMMENT ON FUNCTION public.admin_list_regional_cuisine_tags_v1 IS
  'Admin: tüm yöresel mutfak etiketlerini + kaç işletmede kullanıldığını listeler. Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_upsert_regional_cuisine_tag_v1(
  p_id uuid DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_label text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
    INSERT INTO public.regional_cuisine_tags (city, label)
    VALUES (trim(p_city), trim(p_label))
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.regional_cuisine_tags
    SET
      city = COALESCE(NULLIF(trim(p_city), ''), city),
      label = COALESCE(NULLIF(trim(p_label), ''), label)
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM anon;
COMMENT ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1 IS
  'Admin: yöresel mutfak etiketi oluşturur (p_id=NULL) veya günceller. Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_delete_regional_cuisine_tag_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  DELETE FROM public.regional_cuisine_tags WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_delete_regional_cuisine_tag_v1 IS
  'Admin: etiketi siler (kullanan işletmelerde regional_tag_id NULL olur). Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_search_businesses_for_tagging_v1(p_query text)
RETURNS TABLE (id uuid, name text, city text, current_tag_label text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_query IS NULL OR trim(p_query) = '' THEN
    RETURN;
  END IF;
  RETURN QUERY
    SELECT b.id, b.name, b.city, t.label
    FROM public.businesses b
    LEFT JOIN public.regional_cuisine_tags t ON t.id = b.regional_tag_id
    WHERE b.name ILIKE '%' || trim(p_query) || '%'
    ORDER BY b.name
    LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM anon;
COMMENT ON FUNCTION public.admin_search_businesses_for_tagging_v1 IS
  'Admin: isme göre işletme arar (etiket atama aracı için). Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_set_business_regional_tag_v1(p_business_id uuid, p_tag_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.businesses SET regional_tag_id = p_tag_id WHERE id = p_business_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) FROM anon;
COMMENT ON FUNCTION public.admin_set_business_regional_tag_v1 IS
  'Admin: bir işletmeye yöresel etiket atar/kaldırır (p_tag_id=NULL ile kaldırır). Called by: app/yonetici/yoresel-mutfak.';
