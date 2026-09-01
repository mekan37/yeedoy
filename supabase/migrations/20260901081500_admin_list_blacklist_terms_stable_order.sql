-- Task 4 (düzeltme): admin_list_blacklist_terms_v1 sayfalama sıralamasına tiebreaker ekler.
-- Task 1'in 695 terimlik seed'i tek bir çok-satırlı INSERT idi, bu yüzden Postgres
-- now() ifadesini tüm ifade için bir kez değerlendirdi — tüm seed satırları AYNI
-- created_at değerine sahip. LIMIT/OFFSET ile benzersiz olmayan bir sıralama anahtarı
-- üzerinden sayfalama Postgres'te tanımsız sıradır; bu yüzden bir admin listede
-- gezinirken aynı terimi iki kez görebilir ya da bir terimi atlayabilir.
-- Çözüm: ORDER BY'a t.id DESC tiebreaker'ı eklendi.

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
    ORDER BY t.created_at DESC, t.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.admin_list_blacklist_terms_v1 IS
  'Admin: kara liste terimlerini arama+sayfalama ile listeler. Called by: app/yonetici/kara-liste.';
