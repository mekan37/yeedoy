-- Task 4 (bölüm 2/2): Admin CRUD RPC'leri + izin kaydı (paylaşımlı moderasyon kara liste planı)
-- admin_list_blacklist_terms_v1 / admin_add_blacklist_term_v1 / admin_remove_blacklist_term_v1
-- RPC'lerini oluşturur. Ayrıca sistem admin rollerinin permissions dizisini
-- enum_range ile tazeleyerek page:kara-liste dahil tüm değerlerin gerçekten
-- erişilebilir olmasını sağlar.
-- Önkoşul: 20260901080900_moderation_blacklist_admin_permission_enum.sql
-- (page:kara-liste enum değerini ayrı transaction'da ekleyip commit eder;
-- "unsafe use of new value" hatasını önlemek için bölündü).

CREATE OR REPLACE FUNCTION public.admin_list_blacklist_terms_v1(p_query text DEFAULT NULL, p_limit int DEFAULT 50, p_offset int DEFAULT 0)
RETURNS TABLE (id bigint, term text, is_active boolean, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT t.id, t.term, t.is_active, t.created_at
    FROM public.moderation_blacklist_terms t
    WHERE p_query IS NULL OR trim(p_query) = '' OR t.term ILIKE '%' || trim(p_query) || '%'
    ORDER BY t.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) FROM anon;
COMMENT ON FUNCTION public.admin_list_blacklist_terms_v1 IS
  'Admin: kara liste terimlerini arama+sayfalama ile listeler. Called by: app/yonetici/kara-liste.';

CREATE OR REPLACE FUNCTION public.admin_add_blacklist_term_v1(p_term text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id bigint;
  v_term text := lower(trim(coalesce(p_term, '')));
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF v_term = '' THEN
    RAISE EXCEPTION 'validation_error: term zorunlu' USING ERRCODE = 'P0003';
  END IF;
  INSERT INTO public.moderation_blacklist_terms (term, created_by)
  VALUES (v_term, auth.uid())
  ON CONFLICT (term) DO UPDATE SET is_active = true
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_add_blacklist_term_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_add_blacklist_term_v1(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_add_blacklist_term_v1(text) FROM anon;
COMMENT ON FUNCTION public.admin_add_blacklist_term_v1 IS
  'Admin: yeni kara liste terimi ekler (varsa ve pasifse yeniden aktifleştirir). Called by: app/yonetici/kara-liste.';

CREATE OR REPLACE FUNCTION public.admin_remove_blacklist_term_v1(p_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.moderation_blacklist_terms SET is_active = false WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) FROM anon;
COMMENT ON FUNCTION public.admin_remove_blacklist_term_v1 IS
  'Admin: kara liste terimini pasifleştirir (soft delete — geçmiş için satır kalır). Called by: app/yonetici/kara-liste.';

UPDATE public.admin_roles
SET permissions = enum_range(NULL::public.admin_permission_key)
WHERE is_system = true;
