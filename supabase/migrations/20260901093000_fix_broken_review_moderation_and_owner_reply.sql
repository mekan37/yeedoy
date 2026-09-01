-- ============================================================
-- 20260901093000_fix_broken_review_moderation_and_owner_reply.sql
--
-- ACİL DÜZELTME: 20260901091000_lock_down_reviews_direct_write_access.sql
-- (REVOKE INSERT,UPDATE,DELETE ON reviews FROM anon,authenticated) canlıda iki
-- gerçek özelliği kırdı — o migration'ın "hiçbir kod yolu update/delete çağırmıyor"
-- varsayımı yanlıştı (kod quality reviewer tarafından production'da doğrulandı):
--   1) app/sunucu/yonetici/toplu-islemler/route.ts — admin'in /yonetici/yorumlar
--      sayfasındaki Onayla/Reddet aksiyonu, doğrudan .from('reviews').update(status)
--      yapıyordu, reviews_update_admin RLS policy'sine güveniyordu.
--   2) app/sunucu/sahip/yorumlar/yanit/route.ts — sahibin yoruma yanıt verme/silme
--      özelliği, doğrudan .from('reviews').update(owner_reply) yapıyordu.
--
-- Bu migration üç yeni SECURITY DEFINER RPC ekliyor; route handler değişiklikleri
-- aynı commit'te (ayrı bir web dosya değişikliği olarak) geliyor.
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_moderate_reviews_v1(p_ids uuid[], p_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_status NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'validation_error: gecersiz status' USING ERRCODE = 'P0003';
  END IF;
  UPDATE public.reviews SET status = p_status WHERE id = ANY(p_ids);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_moderate_reviews_v1(uuid[], text) FROM anon;
COMMENT ON FUNCTION public.admin_moderate_reviews_v1 IS
  'Admin: secili yorumlarin status alanini toplu gunceller (approved/rejected). Called by: app/sunucu/yonetici/toplu-islemler/route.ts.';

CREATE OR REPLACE FUNCTION public.owner_reply_review_v1(p_review_id uuid, p_reply text)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_replied_at timestamptz := now();
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT business_id INTO v_business_id FROM public.reviews WHERE id = p_review_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims
    WHERE business_id = v_business_id AND user_id = auth.uid() AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.reviews
  SET owner_reply = p_reply, owner_replied_at = v_replied_at
  WHERE id = p_review_id;

  RETURN v_replied_at;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_reply_review_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_reply_review_v1(uuid, text) TO authenticated;
COMMENT ON FUNCTION public.owner_reply_review_v1 IS
  'Owner: kendi isletmesine ait bir yoruma yanit yazar (owner_claims status=approved kontrolu). Called by: app/sunucu/sahip/yorumlar/yanit/route.ts.';

CREATE OR REPLACE FUNCTION public.owner_clear_review_reply_v1(p_review_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT business_id INTO v_business_id FROM public.reviews WHERE id = p_review_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims
    WHERE business_id = v_business_id AND user_id = auth.uid() AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.reviews SET owner_reply = NULL, owner_replied_at = NULL WHERE id = p_review_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_clear_review_reply_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_clear_review_reply_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.owner_clear_review_reply_v1 IS
  'Owner: kendi isletmesine ait bir yorumdaki yanitini kaldirir. Called by: app/sunucu/sahip/yorumlar/yanit/route.ts.';
