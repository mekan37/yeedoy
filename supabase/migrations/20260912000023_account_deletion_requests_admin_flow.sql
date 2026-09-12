-- P2: "account_deletion_requests tablosu admin panelinde hiç kullanılmıyor"
-- Mobil uygulama submit_account_deletion_request_v1 ile resmi bir KVKK hesap
-- silme talebi oluşturuyor (kullanıcı kendi durumunu görebiliyor) ama bu
-- talebi işleyecek/tamamlayacak hiçbir admin aracı yoktu — talepler
-- sonsuza dek 'requested' kalıyordu. (Not: web'in /sunucu/hesap/sil'i ayrı,
-- anlık bir self-servis akışı — bu tabloyu hiç kullanmıyor, dokunulmadı.)

CREATE OR REPLACE FUNCTION public.admin_list_account_deletion_requests_v1(p_limit integer DEFAULT 200)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  email text,
  display_name text,
  reason text,
  status text,
  requested_at timestamptz,
  completed_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT
      r.id, r.user_id, u.email::text, p.display_name, r.reason, r.status, r.requested_at, r.completed_at
    FROM public.account_deletion_requests r
    LEFT JOIN auth.users u ON u.id = r.user_id
    LEFT JOIN public.user_profiles p ON p.user_id = r.user_id
    ORDER BY r.requested_at DESC
    LIMIT LEAST(GREATEST(coalesce(p_limit, 200), 1), 500);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_list_account_deletion_requests_v1(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_list_account_deletion_requests_v1(integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_list_account_deletion_requests_v1(integer) TO authenticated;

-- Yalnızca yorum/karar durumları — gerçek silme (completed) sadece
-- admin_execute_account_deletion_v1 üzerinden, çünkü o geri alınamaz.
CREATE OR REPLACE FUNCTION public.admin_review_account_deletion_request_v1(p_id uuid, p_status text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_status NOT IN ('in_review', 'rejected', 'cancelled') THEN
    RAISE EXCEPTION 'invalid_status' USING ERRCODE = '22023';
  END IF;

  UPDATE public.account_deletion_requests
  SET status = p_status
  WHERE id = p_id AND status IN ('requested', 'in_review');

  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count > 0 THEN
    PERFORM public.insert_audit_log_v1(
      'account_deletion_request_review', 'account_deletion_requests', p_id,
      NULL, jsonb_build_object('status', p_status)
    );
  END IF;

  RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_review_account_deletion_request_v1(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_review_account_deletion_request_v1(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_review_account_deletion_request_v1(uuid, text) TO authenticated;

-- delete_user_account_v1()'in admin-tetiklemeli hali (auth.uid() yerine
-- hedef kullanıcı v_uid) — mobilden gelen resmi talebi gerçekten işler.
-- auth.users satırının silinmesi service_role gerektirdiği için çağıran
-- route'ta yapılır; auth.users silinince account_deletion_requests satırı
-- CASCADE ile gidecek, o yüzden kalıcı kanıt burada (ayrı tabloya)
-- insert_audit_log_v1 ile bırakılıyor.
CREATE OR REPLACE FUNCTION public.admin_execute_account_deletion_v1(p_request_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_status text;
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT user_id, status INTO v_uid, v_status
  FROM public.account_deletion_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF v_status NOT IN ('requested', 'in_review') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_pending');
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

  UPDATE public.menu_item_price_suggestions SET user_id = NULL WHERE user_id = v_uid;
  UPDATE public.reviews SET user_id = NULL WHERE user_id = v_uid;
  DELETE FROM public.favorites WHERE user_id = v_uid;
  DELETE FROM public.price_alerts WHERE user_id = v_uid;
  DELETE FROM public.notifications WHERE user_id = v_uid;
  DELETE FROM public.review_votes WHERE user_id = v_uid;
  DELETE FROM public.user_profiles WHERE user_id = v_uid;

  UPDATE public.account_deletion_requests
  SET status = 'completed', completed_at = now()
  WHERE id = p_request_id;

  PERFORM public.insert_audit_log_v1(
    'account_deletion_executed', 'account_deletion_requests', p_request_id,
    NULL, jsonb_build_object('user_id', v_uid, 'email', v_email, 'completed_at', now())
  );

  RETURN jsonb_build_object('ok', true, 'user_id', v_uid);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_execute_account_deletion_v1(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_execute_account_deletion_v1(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_execute_account_deletion_v1(uuid) TO authenticated;
