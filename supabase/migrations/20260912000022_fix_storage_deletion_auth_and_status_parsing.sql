-- Canlı smoke testte bulunan 2 gerçek bug (20260912000021'in ilk versiyonunda):
-- 1) push_trigger_service_role_key artık yeni Supabase key formatında
--    (sb_secret_...), JWT değil — Storage API'si Authorization: Bearer'ı
--    JWT olarak parse etmeye çalışıp "Invalid Compact JWS" ile reddediyordu.
--    Çözüm: apikey header'ı da eklemek (Supabase gateway'i böyle kabul ediyor).
-- 2) Bu Supabase sürümünde Storage API hataları HTTP 400 sarmalayıcısıyla
--    dönüyor, gerçek durum kodu JSON gövdesindeki statusCode alanında
--    (ör. {"statusCode":"404",...}) — ham status_code'a bakmak "not found"u
--    "başarısız" sayıp sonsuz retry'a düşürüyordu.
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
        headers := jsonb_build_object(
          'apikey', v_service_role_key,
          'Authorization', 'Bearer ' || v_service_role_key
        ),
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

CREATE OR REPLACE FUNCTION public.reconcile_storage_deletion_queue_v1(p_limit integer DEFAULT 200)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_count integer := 0;
  v_row record;
  v_effective_code integer;
BEGIN
  FOR v_row IN
    SELECT q.id, r.status_code, r.content, r.error_msg
    FROM public.storage_deletion_queue q
    JOIN net._http_response r ON r.id = q.net_request_id
    WHERE q.processed_at IS NULL
      AND q.requested_at IS NOT NULL
    ORDER BY q.requested_at ASC
    LIMIT greatest(coalesce(p_limit, 200), 1)
  LOOP
    v_effective_code := v_row.status_code;
    BEGIN
      IF v_row.content IS NOT NULL AND v_row.content ~ '^\s*\{' THEN
        v_effective_code := coalesce((v_row.content::jsonb ->> 'statusCode')::int, v_row.status_code);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_effective_code := v_row.status_code;
    END;

    IF v_effective_code BETWEEN 200 AND 299 OR v_effective_code = 404 THEN
      UPDATE public.storage_deletion_queue SET processed_at = now() WHERE id = v_row.id;
      v_count := v_count + 1;
    ELSE
      UPDATE public.storage_deletion_queue
      SET attempts = attempts + 1,
          last_error = coalesce(v_row.error_msg, left(v_row.content, 300), 'http_' || coalesce(v_row.status_code, 0)::text),
          requested_at = NULL
      WHERE id = v_row.id;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$;
