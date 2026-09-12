-- P2: legal_documents (yasal/gizlilik/kullanım metinleri) değişiklikleri hiç
-- audit log'a yazılmıyordu — "hangi admin, hangi belgeyi ne zaman değiştirdi/
-- yayına aldı" sorusu cevapsızdı. insert_audit_log_v1 ile before/after
-- snapshot'lı gerçek denetim kaydı ekleniyor.

CREATE OR REPLACE FUNCTION public.admin_upsert_legal_document_v1(
  p_id uuid, p_slug text, p_title text, p_description text, p_content text,
  p_is_published boolean, p_sort_order integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_id uuid;
  v_before jsonb;
  v_after jsonb;
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized: KVKK / GDPR izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF btrim(coalesce(p_slug, '')) = '' OR btrim(coalesce(p_title, '')) = '' OR btrim(coalesce(p_content, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: slug, başlık ve içerik zorunlu' USING ERRCODE = 'P0003';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.legal_documents (slug, title, description, content, is_published, sort_order, updated_by)
    VALUES (btrim(p_slug), btrim(p_title), nullif(btrim(coalesce(p_description, '')), ''), p_content, p_is_published, coalesce(p_sort_order, 0), auth.uid())
    RETURNING id INTO v_id;

    SELECT to_jsonb(l) - 'content' INTO v_after FROM public.legal_documents l WHERE l.id = v_id;
    PERFORM public.insert_audit_log_v1('legal_document_create', 'legal_documents', v_id, NULL, v_after);
  ELSE
    SELECT to_jsonb(l) - 'content' INTO v_before FROM public.legal_documents l WHERE l.id = p_id;

    UPDATE public.legal_documents
    SET slug = btrim(p_slug), title = btrim(p_title), description = nullif(btrim(coalesce(p_description, '')), ''),
        content = p_content, is_published = p_is_published, sort_order = coalesce(p_sort_order, 0), updated_by = auth.uid()
    WHERE id = p_id
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found: Belge bulunamadı' USING ERRCODE = 'P0001';
    END IF;

    SELECT to_jsonb(l) - 'content' INTO v_after FROM public.legal_documents l WHERE l.id = v_id;
    PERFORM public.insert_audit_log_v1('legal_document_update', 'legal_documents', v_id, v_before, v_after);
  END IF;

  RETURN v_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_delete_legal_document_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_before jsonb;
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized: KVKK / GDPR izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT to_jsonb(l) - 'content' INTO v_before FROM public.legal_documents l WHERE l.id = p_id;

  DELETE FROM public.legal_documents WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Belge bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public.insert_audit_log_v1('legal_document_delete', 'legal_documents', p_id, v_before, NULL);
END;
$function$;

-- content sütunu (uzun metin, PII değil ama gereksiz büyük) before/after
-- snapshot'larından bilerek çıkarıldı; sadece metadata (slug/title/is_published/
-- sort_order/updated_by/timestamps) denetim kaydına yazılıyor.
