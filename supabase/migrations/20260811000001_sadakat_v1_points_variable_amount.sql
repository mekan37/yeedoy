-- Sadakat v1 — puan modu düzeltmesi.
--
-- scan_loyalty_qr_v1 mode'dan bağımsız her taramada sabit +1 ekliyordu.
-- Damga modunda bu doğru (her tarama = 1 damga), ama puan modunda "puan
-- sistemi" sahip için kozmetikten ibaretti — owner harcama tutarına göre
-- değişken puan ekleyemiyordu. Bu migration p_amount parametresi ekler:
-- damga modunda her zaman 1'e sabitlenir (owner girişi yok sayılır),
-- puan modunda 1-1000 aralığında owner'ın girdiği miktar kullanılır.
--
-- İmza değişikliği (2 param → 3 param, DEFAULT'lu) var olan çağrı
-- yerlerini bozmaz (CLAUDE.md: "Adding a param with DEFAULT is not a
-- breaking change"), ama Postgres fonksiyon kimliği parametre listesine
-- göre olduğundan eski 2-param fonksiyon önce DROP edilmeli — aksi halde
-- iki aşırı yüklenmiş (overload) fonksiyon yan yana kalır.

DROP FUNCTION IF EXISTS public.scan_loyalty_qr_v1(uuid, uuid);

CREATE FUNCTION public.scan_loyalty_qr_v1(
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
  IF NOT public.is_owner_of_business(p_business_id) THEN
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
  'Owner/personel: kasada müşteri QR''sini okutup damga (+1 sabit) veya puan (p_amount, 1-1000) ekler. Rate limit: aynı üyede 60sn içinde tekrar tarama engellenir. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı).';
