-- Sadakat v1 — iki eksik kapatılıyor:
--
-- 1) Personel (staff, rank 200) erişimi: scan_loyalty_qr_v1/redeem_loyalty_reward_v1
--    'menu_write' (editor+, rank>=300) üzerinden is_owner_of_business ile
--    korunuyordu — kasada duran "Personel" rolü QR okutamıyordu, halbuki bu
--    işlemin asıl kullanıcısı odur. Var olan ama hiçbir yerde kullanılmayan
--    'qr_manage' izni (business_role_has_permission_v1) staff eşiğine (200)
--    çekilip bu iki fonksiyonda kullanılıyor. Program oluşturma/aktivasyon/
--    üye listesi hâlâ 'menu_write' (editor+) — bunlar yapılandırma, sayaç
--    işlemi değil.
--
-- 2) Program düzenle/sil: create_loyalty_program_v1 tek seferlik (unique
--    index business_id/chain_id üzerinde), owner ad/ödül açıklaması/eşiği
--    değiştiremiyor, hatalı kurulumdan geri dönemiyordu. update (menu_write,
--    editor+) ve delete (business_write, manager+ — geri dönüşsüz, tüm
--    üye/tarama geçmişini siler) RPC'leri eklendi.

CREATE OR REPLACE FUNCTION public.business_role_has_permission_v1(p_role text, p_permission text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  select case lower(coalesce(p_permission, ''))
    when 'business_read' then public.business_role_rank_v1(p_role) >= 100
    when 'analytics_view' then public.business_role_rank_v1(p_role) >= 100
    when 'media_upload' then public.business_role_rank_v1(p_role) >= 200
    when 'qr_manage' then public.business_role_rank_v1(p_role) >= 200
    when 'menu_write' then public.business_role_rank_v1(p_role) >= 300
    when 'business_write' then public.business_role_rank_v1(p_role) >= 400
    when 'team_manage' then public.business_role_rank_v1(p_role) >= 400
    else false
  end;
$$;

-- ── scan_loyalty_qr_v1: menu_write → qr_manage ──────────────────────────────
CREATE OR REPLACE FUNCTION public.scan_loyalty_qr_v1(
  p_business_id uuid,
  p_user_id     uuid,
  p_amount      int DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id       uuid;
  v_member_id        uuid;
  v_progress         int;
  v_threshold        int;
  v_mode             text;
  v_last_scan        timestamptz;
  v_effective_amount int;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'qr_manage') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'not_found: sadakat programı yok' USING ERRCODE = 'P0001';
  END IF;

  SELECT reward_threshold, mode INTO v_threshold, v_mode
  FROM public.loyalty_programs WHERE id = v_program_id AND is_active = true;

  IF v_threshold IS NULL THEN
    RAISE EXCEPTION 'not_found: program pasif' USING ERRCODE = 'P0001';
  END IF;

  IF v_mode = 'stamp' THEN
    v_effective_amount := 1;
  ELSE
    IF p_amount IS NULL OR p_amount < 1 OR p_amount > 1000 THEN
      RAISE EXCEPTION 'validation_error: puan miktarı 1-1000 arasında olmalı' USING ERRCODE = 'P0003';
    END IF;
    v_effective_amount := p_amount;
  END IF;

  INSERT INTO public.loyalty_members (program_id, user_id, progress)
  VALUES (v_program_id, p_user_id, 0)
  ON CONFLICT (program_id, user_id) DO NOTHING;

  SELECT id INTO v_member_id
  FROM public.loyalty_members WHERE program_id = v_program_id AND user_id = p_user_id;

  SELECT max(created_at) INTO v_last_scan
  FROM public.loyalty_events
  WHERE member_id = v_member_id AND source = 'qr_scan';

  IF v_last_scan IS NOT NULL AND v_last_scan > now() - interval '60 seconds' THEN
    RAISE EXCEPTION 'validation_error: çok hızlı tekrar tarama' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.loyalty_members SET progress = progress + v_effective_amount, updated_at = now()
  WHERE id = v_member_id
  RETURNING progress INTO v_progress;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (v_member_id, 'qr_scan', v_effective_amount, auth.uid());

  RETURN jsonb_build_object(
    'member_id', v_member_id,
    'progress', v_progress,
    'reward_threshold', v_threshold,
    'reward_ready', v_progress >= v_threshold
  );
END;
$$;

REVOKE ALL ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid, int) FROM anon;
COMMENT ON FUNCTION public.scan_loyalty_qr_v1 IS
  'Owner/personel (qr_manage, rank>=200): kasada müşteri QR''sini okutup damga (+1 sabit) veya puan (p_amount, 1-1000) ekler. Rate limit: aynı üyede 60sn içinde tekrar tarama engellenir. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı).';

-- ── redeem_loyalty_reward_v1: menu_write → qr_manage ────────────────────────
CREATE OR REPLACE FUNCTION public.redeem_loyalty_reward_v1(p_member_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_threshold   int;
  v_progress    int;
BEGIN
  SELECT lp.business_id, lp.chain_id, lp.reward_threshold, lm.progress
  INTO v_business_id, v_chain_id, v_threshold, v_progress
  FROM public.loyalty_members lm
  JOIN public.loyalty_programs lp ON lp.id = lm.program_id
  WHERE lm.id = p_member_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: üye bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    IF NOT public.has_business_permission_v1(v_business_id, 'qr_manage') THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.has_business_permission_v1(b.id, 'qr_manage')
    ) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
  END IF;

  IF v_progress < v_threshold THEN
    RAISE EXCEPTION 'validation_error: eşiğe ulaşılmadı' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.loyalty_members
  SET progress = progress - v_threshold, redeemed_count = redeemed_count + 1, updated_at = now()
  WHERE id = p_member_id
  RETURNING progress INTO v_progress;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (p_member_id, 'redeem', v_threshold, auth.uid());

  RETURN jsonb_build_object('member_id', p_member_id, 'progress', v_progress);
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_loyalty_reward_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_reward_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.redeem_loyalty_reward_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.redeem_loyalty_reward_v1 IS
  'Owner/personel (qr_manage, rank>=200): eşiğe ulaşmış üyenin ödülünü düşürür. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı, Ödülü Kullan butonu).';

-- ── update_loyalty_program_v1 (yeni) ─────────────────────────────────────────
CREATE FUNCTION public.update_loyalty_program_v1(
  p_program_id       uuid,
  p_name             text,
  p_reward_desc      text,
  p_reward_threshold int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_owner_biz   uuid;
BEGIN
  SELECT business_id, chain_id INTO v_business_id, v_chain_id
  FROM public.loyalty_programs WHERE id = p_program_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: program bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    v_owner_biz := v_business_id;
  ELSE
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
  END IF;

  IF NOT public.is_owner_of_business(v_owner_biz) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF trim(p_name) = '' OR trim(p_reward_desc) = '' THEN
    RAISE EXCEPTION 'validation_error: ad ve ödül açıklaması boş olamaz' USING ERRCODE = 'P0003';
  END IF;
  IF p_reward_threshold <= 0 THEN
    RAISE EXCEPTION 'validation_error: reward_threshold pozitif olmalı' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.loyalty_programs
  SET name = trim(p_name), reward_desc = trim(p_reward_desc), reward_threshold = p_reward_threshold
  WHERE id = p_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_loyalty_program_v1(uuid, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_loyalty_program_v1(uuid, text, text, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_loyalty_program_v1(uuid, text, text, int) FROM anon;
COMMENT ON FUNCTION public.update_loyalty_program_v1 IS
  'Owner (menu_write, editor+): program adı/ödül açıklaması/eşiğini günceller. mode değiştirilemez (mevcut üye ilerlemesinin anlamını bozar) — mode değişimi gerekiyorsa delete_loyalty_program_v1 + yeniden oluşturma gerekir. Called by: app/sahip/pazarlama/sadakat.';

-- ── delete_loyalty_program_v1 (yeni) ─────────────────────────────────────────
CREATE FUNCTION public.delete_loyalty_program_v1(p_program_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_owner_biz   uuid;
BEGIN
  SELECT business_id, chain_id INTO v_business_id, v_chain_id
  FROM public.loyalty_programs WHERE id = p_program_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: program bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    v_owner_biz := v_business_id;
  ELSE
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
  END IF;

  IF NOT public.has_business_permission_v1(v_owner_biz, 'business_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.loyalty_programs WHERE id = p_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_loyalty_program_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_loyalty_program_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_loyalty_program_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.delete_loyalty_program_v1 IS
  'Owner/yönetici (business_write, manager+): programı ve tüm üye/tarama geçmişini (CASCADE) geri dönüşsüz siler. Called by: app/sahip/pazarlama/sadakat ("Programı Sil" butonu).';
