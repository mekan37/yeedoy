-- P2: "Storage objects (avatars, review photos, menu images) orphaned on
-- permanent deletion" — storage_deletion_queue tablosu 2026-03'ten beri
-- var (bkz. _archive/20260322000018) ama HİÇBİR consumer'ı yok: hiçbir
-- cron/edge function/route bu kuyruğu okuyup gerçek Storage silmesi
-- yapmıyordu. mark_expired_temp_uploads_v1 de hiç scheduled değildi.
-- Bu migration: (1) kuyruğa gerçekten işleyen bir consumer ekliyor
-- (pg_net ile Storage REST API'sine DELETE, push_trigger_service_role_key
-- vault secret'ı ile — trg_notify_push_v1 ile aynı desen), (2) owner'ın
-- kalıcı menü/ürün/fotoğraf silme RPC'lerine gerçek enqueue çağrısı
-- ekliyor, (3) mark_expired_temp_uploads_v1'i cron'a bağlıyor.

-- ── 1. Kuyruk şeması: async pg_net request/response eşleştirmesi için ────────
ALTER TABLE public.storage_deletion_queue ADD COLUMN IF NOT EXISTS requested_at timestamptz;
ALTER TABLE public.storage_deletion_queue ADD COLUMN IF NOT EXISTS net_request_id bigint;
CREATE INDEX IF NOT EXISTS storage_deletion_queue_net_request_idx
  ON public.storage_deletion_queue (net_request_id)
  WHERE net_request_id IS NOT NULL;

-- ── 2. URL → bucket/path çözümleyici + kuyruğa ekleyici (internal helper) ────
-- Sadece kendi Supabase Storage public URL'lerimizi tanır (unsplash/AI/stock
-- gibi harici URL'ler regex eşleşmediği için sessizce atlanır — bunlar zaten
-- bizim bucket'ımızda değil, silinmemeli).
CREATE OR REPLACE FUNCTION public.enqueue_storage_deletion_v1(p_url text, p_reason text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_match text[];
BEGIN
  IF coalesce(p_url, '') = '' THEN
    RETURN false;
  END IF;

  v_match := regexp_match(p_url, '/storage/v1/object/(?:public|sign|authenticated)/([^/]+)/([^?]+)');
  IF v_match IS NULL THEN
    RETURN false;
  END IF;

  INSERT INTO public.storage_deletion_queue (bucket, path, reason)
  VALUES (v_match[1], v_match[2], p_reason)
  ON CONFLICT DO NOTHING;

  RETURN true;
END;
$$;
REVOKE ALL ON FUNCTION public.enqueue_storage_deletion_v1(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enqueue_storage_deletion_v1(text, text) FROM anon;
REVOKE ALL ON FUNCTION public.enqueue_storage_deletion_v1(text, text) FROM authenticated;
COMMENT ON FUNCTION public.enqueue_storage_deletion_v1(text, text) IS
  'Internal: yalnızca SECURITY DEFINER fonksiyonlardan çağrılır, PostgREST üzerinden hiçbir role açık değil.';

-- ── 3. Consumer: kuyruktan iste (async) ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.request_storage_deletion_batch_v1(p_limit integer DEFAULT 100)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_service_role_key text;
  v_count integer := 0;
  v_row record;
  v_request_id bigint;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'push_trigger_service_role_key'
  LIMIT 1;

  IF v_service_role_key IS NULL THEN
    RAISE WARNING 'request_storage_deletion_batch_v1: service role key vault''ta bulunamadı';
    RETURN 0;
  END IF;

  FOR v_row IN
    SELECT id, bucket, path
    FROM public.storage_deletion_queue
    WHERE processed_at IS NULL
      AND attempts < 5
      AND (requested_at IS NULL OR requested_at < now() - interval '10 minutes')
    ORDER BY scheduled_at ASC
    LIMIT greatest(coalesce(p_limit, 100), 1)
  LOOP
    BEGIN
      SELECT net.http_delete(
        url := 'https://wvofyimbjndxtxitsjpd.supabase.co/storage/v1/object/' || v_row.bucket || '/' || v_row.path,
        headers := jsonb_build_object('Authorization', 'Bearer ' || v_service_role_key),
        timeout_milliseconds := 8000
      ) INTO v_request_id;

      UPDATE public.storage_deletion_queue
      SET requested_at = now(), net_request_id = v_request_id
      WHERE id = v_row.id;

      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN
      UPDATE public.storage_deletion_queue
      SET attempts = attempts + 1, last_error = SQLERRM
      WHERE id = v_row.id;
    END;
  END LOOP;

  RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.request_storage_deletion_batch_v1(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.request_storage_deletion_batch_v1(integer) FROM anon;
REVOKE ALL ON FUNCTION public.request_storage_deletion_batch_v1(integer) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.request_storage_deletion_batch_v1(integer) TO service_role;

-- ── 4. Consumer: pg_net yanıtlarını uzlaştır (reconcile) ─────────────────────
-- 200-299 veya 404 (dosya zaten yoksa) → başarılı sayılır. Diğer her şey
-- attempts++ + requested_at=NULL ile bir sonraki request turunda yeniden
-- denenir; 5 denemeden sonra kuyrukta kalır (admin_only SELECT policy ile
-- görünür, manuel inceleme için).
CREATE OR REPLACE FUNCTION public.reconcile_storage_deletion_queue_v1(p_limit integer DEFAULT 200)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_count integer := 0;
BEGIN
  WITH resolved AS (
    SELECT q.id, r.status_code, r.error_msg
    FROM public.storage_deletion_queue q
    JOIN net._http_response r ON r.id = q.net_request_id
    WHERE q.processed_at IS NULL
      AND q.requested_at IS NOT NULL
    ORDER BY q.requested_at ASC
    LIMIT greatest(coalesce(p_limit, 200), 1)
  ),
  success AS (
    UPDATE public.storage_deletion_queue q
    SET processed_at = now()
    FROM resolved
    WHERE q.id = resolved.id
      AND (resolved.status_code BETWEEN 200 AND 299 OR resolved.status_code = 404)
    RETURNING q.id
  ),
  failure AS (
    UPDATE public.storage_deletion_queue q
    SET attempts = q.attempts + 1,
        last_error = coalesce(resolved.error_msg, 'http_' || coalesce(resolved.status_code, 0)::text),
        requested_at = NULL
    FROM resolved
    WHERE q.id = resolved.id
      AND NOT (resolved.status_code BETWEEN 200 AND 299 OR resolved.status_code = 404)
    RETURNING q.id
  )
  SELECT count(*) INTO v_count FROM success;

  RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.reconcile_storage_deletion_queue_v1(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_storage_deletion_queue_v1(integer) FROM anon;
REVOKE ALL ON FUNCTION public.reconcile_storage_deletion_queue_v1(integer) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.reconcile_storage_deletion_queue_v1(integer) TO service_role;

-- ── 5. Cron: her 10 dakikada iste + uzlaştır, günde bir expired temp upload ──
SELECT cron.schedule(
  'storage-deletion-request',
  '*/10 * * * *',
  $$SELECT public.request_storage_deletion_batch_v1(200);$$
);
SELECT cron.schedule(
  'storage-deletion-reconcile',
  '*/10 * * * *',
  $$SELECT public.reconcile_storage_deletion_queue_v1(500);$$
);
-- mark_expired_temp_uploads_v1 zaten vardı (2026-03) ama hiç scheduled
-- değildi — süresi dolan temp upload'lar storage'da sonsuza kadar kalıyordu.
SELECT cron.schedule(
  'temp-uploads-expire-daily',
  '30 3 * * *',
  $$SELECT public.mark_expired_temp_uploads_v1(1000);$$
);

-- ── 6. Owner'ın kalıcı silme RPC'lerine gerçek enqueue çağrısı ───────────────
CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_v1(p_menu_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
  v_urls text[];
  v_url text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menus WHERE id = p_menu_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  -- menus silinince menu_sections->menu_items->menu_item_photos CASCADE ile
  -- siliniyor, Storage'daki dosyalar hiç temizlenmiyordu — DELETE
  -- başarılıysa aşağıda kuyruklanacak.
  SELECT array_agg(DISTINCT u) INTO v_urls
  FROM (
    SELECT p.url AS u FROM public.menu_item_photos p
      JOIN public.menu_items i ON i.id = p.menu_item_id
      JOIN public.menu_sections s ON s.id = i.section_id
      WHERE s.menu_id = p_menu_id AND p.url IS NOT NULL
    UNION ALL
    SELECT p.url_large FROM public.menu_item_photos p
      JOIN public.menu_items i ON i.id = p.menu_item_id
      JOIN public.menu_sections s ON s.id = i.section_id
      WHERE s.menu_id = p_menu_id AND p.url_large IS NOT NULL
    UNION ALL
    SELECT p.url_thumb FROM public.menu_item_photos p
      JOIN public.menu_items i ON i.id = p.menu_item_id
      JOIN public.menu_sections s ON s.id = i.section_id
      WHERE s.menu_id = p_menu_id AND p.url_thumb IS NOT NULL
  ) urls;

  DELETE FROM public.menus WHERE id = p_menu_id AND status = 'archived';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_archived');
  END IF;

  IF v_urls IS NOT NULL THEN
    FOREACH v_url IN ARRAY v_urls LOOP
      PERFORM public.enqueue_storage_deletion_v1(v_url, 'menu_permanently_deleted');
    END LOOP;
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_menu_id);
END;
$function$;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_v1(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_item_v1(p_item_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
  v_urls text[];
  v_url text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menu_items WHERE id = p_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  SELECT array_agg(DISTINCT u) INTO v_urls
  FROM (
    SELECT url AS u FROM public.menu_item_photos WHERE menu_item_id = p_item_id AND url IS NOT NULL
    UNION ALL
    SELECT url_large FROM public.menu_item_photos WHERE menu_item_id = p_item_id AND url_large IS NOT NULL
    UNION ALL
    SELECT url_thumb FROM public.menu_item_photos WHERE menu_item_id = p_item_id AND url_thumb IS NOT NULL
  ) urls;

  DELETE FROM public.menu_items WHERE id = p_item_id AND is_available = false;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_archived');
  END IF;

  IF v_urls IS NOT NULL THEN
    FOREACH v_url IN ARRAY v_urls LOOP
      PERFORM public.enqueue_storage_deletion_v1(v_url, 'menu_item_permanently_deleted');
    END LOOP;
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_item_id);
END;
$function$;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_v1(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.owner_permanently_delete_menu_item_photo_v1(p_photo_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_business_id uuid;
  v_url text;
  v_url_large text;
  v_url_thumb text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id, url, url_large, url_thumb
    INTO v_business_id, v_url, v_url_large, v_url_thumb
  FROM public.menu_item_photos WHERE id = p_photo_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  DELETE FROM public.menu_item_photos WHERE id = p_photo_id AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_deleted');
  END IF;

  PERFORM public.enqueue_storage_deletion_v1(v_url, 'menu_item_photo_permanently_deleted');
  PERFORM public.enqueue_storage_deletion_v1(v_url_large, 'menu_item_photo_permanently_deleted');
  PERFORM public.enqueue_storage_deletion_v1(v_url_thumb, 'menu_item_photo_permanently_deleted');

  RETURN jsonb_build_object('ok', true, 'id', p_photo_id);
END;
$function$;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_permanently_delete_menu_item_photo_v1(uuid) TO authenticated;
