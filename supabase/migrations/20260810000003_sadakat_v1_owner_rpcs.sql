-- Sadakat v1 — owner RPC yüzeyi. bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

-- ── Yardımcı: verilen business_id için doğru program scope'unu bul ──────────
CREATE OR REPLACE FUNCTION public._resolve_loyalty_program_v1(p_business_id uuid)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id   uuid;
  v_program_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NOT NULL THEN
    SELECT id INTO v_program_id FROM public.loyalty_programs WHERE chain_id = v_chain_id;
  ELSE
    SELECT id INTO v_program_id FROM public.loyalty_programs WHERE business_id = p_business_id;
  END IF;

  RETURN v_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public._resolve_loyalty_program_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._resolve_loyalty_program_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._resolve_loyalty_program_v1(uuid) FROM authenticated;
COMMENT ON FUNCTION public._resolve_loyalty_program_v1 IS
  'Internal: verilen business_id için doğru sadakat programını bulur (zincirdeyse chain_id üzerinden, değilse kendi business_id üzerinden). Called by: create_loyalty_program_v1, scan_loyalty_qr_v1, get_business_loyalty_members_v1, get_my_loyalty_cards_v1, _award_loyalty_progress.';

-- ── create_loyalty_program_v1 ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_loyalty_program_v1(
  p_business_id      uuid,
  p_mode             text,
  p_name             text,
  p_reward_desc      text,
  p_reward_threshold int
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id   uuid;
  v_owner_biz  uuid;
  v_program_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NOT NULL THEN
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
  ELSE
    v_owner_biz := p_business_id;
  END IF;

  PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');

  IF p_mode NOT IN ('stamp','points') THEN
    RAISE EXCEPTION 'validation_error: geçersiz mode' USING ERRCODE = 'P0003';
  END IF;
  IF p_reward_threshold <= 0 THEN
    RAISE EXCEPTION 'validation_error: reward_threshold pozitif olmalı' USING ERRCODE = 'P0003';
  END IF;

  IF v_chain_id IS NOT NULL THEN
    INSERT INTO public.loyalty_programs (chain_id, mode, name, reward_desc, reward_threshold)
    VALUES (v_chain_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  ELSE
    INSERT INTO public.loyalty_programs (business_id, mode, name, reward_desc, reward_threshold)
    VALUES (p_business_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  END IF;

  RETURN v_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) TO authenticated;
COMMENT ON FUNCTION public.create_loyalty_program_v1 IS
  'Owner: sadakat programı oluşturur (is_active=false başlar). Premium plan kontrolü _check_plan_limit_v1 üzerinden. Called by: app/sahip/pazarlama/sadakat (Faz 2).';

-- ── set_loyalty_program_active_v1 ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_loyalty_program_active_v1(
  p_program_id uuid,
  p_is_active  boolean
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
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.is_owner_of_business(b.id)
    ) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  END IF;

  UPDATE public.loyalty_programs SET is_active = p_is_active WHERE id = p_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) TO authenticated;
COMMENT ON FUNCTION public.set_loyalty_program_active_v1 IS
  'Owner: programı aktif/pasif yapar (eski tasarımda eksik olan adım). Called by: app/sahip/pazarlama/sadakat (Faz 2).';

-- ── scan_loyalty_qr_v1 ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.scan_loyalty_qr_v1(
  p_business_id uuid,
  p_user_id     uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_member_id  uuid;
  v_progress   int;
  v_threshold  int;
  v_last_scan  timestamptz;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'not_found: sadakat programı yok' USING ERRCODE = 'P0001';
  END IF;

  SELECT reward_threshold INTO v_threshold
  FROM public.loyalty_programs WHERE id = v_program_id AND is_active = true;

  IF v_threshold IS NULL THEN
    RAISE EXCEPTION 'not_found: program pasif' USING ERRCODE = 'P0001';
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

  UPDATE public.loyalty_members SET progress = progress + 1, updated_at = now()
  WHERE id = v_member_id
  RETURNING progress INTO v_progress;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (v_member_id, 'qr_scan', 1, auth.uid());

  RETURN jsonb_build_object(
    'member_id', v_member_id,
    'progress', v_progress,
    'reward_threshold', v_threshold,
    'reward_ready', v_progress >= v_threshold
  );
END;
$$;

REVOKE ALL ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.scan_loyalty_qr_v1 IS
  'Owner/personel: kasada müşteri QR''sini okutup damga/puan ekler. Rate limit: aynı üyede 60sn içinde tekrar tarama engellenir. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı, Faz 2).';

-- ── redeem_loyalty_reward_v1 ─────────────────────────────────────────────────
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
    IF NOT public.is_owner_of_business(v_business_id) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.is_owner_of_business(b.id)
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
COMMENT ON FUNCTION public.redeem_loyalty_reward_v1 IS
  'Owner/personel: eşiğe ulaşmış üyenin ödülünü düşürür. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı, Ödülü Kullan butonu, Faz 2).';

-- ── get_business_loyalty_members_v1 ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_business_loyalty_members_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'member_id', lm.id,
          'user_id', lm.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'progress', lm.progress,
          'redeemed_count', lm.redeemed_count
        )
        ORDER BY lm.progress DESC
      )
      FROM public.loyalty_members lm
      LEFT JOIN public.user_profiles up ON up.user_id = lm.user_id
      WHERE lm.program_id = v_program_id
    ),
    '[]'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_loyalty_members_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_loyalty_members_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_business_loyalty_members_v1 IS
  'Owner/personel: sadakat programının üye/CRM listesi. Called by: app/sahip/pazarlama/sadakat (Faz 2).';
