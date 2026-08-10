-- Sadakat v1 — müşteri RPC'si + otomatik kazanma tetikleyicisi.
-- bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

-- ── get_my_loyalty_cards_v1 ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_loyalty_cards_v1()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'program_id', lp.id,
        'mode', lp.mode,
        'business_name', b.name,
        'logo_url', b.logo_url,
        'progress', lm.progress,
        'reward_threshold', lp.reward_threshold,
        'reward_desc', lp.reward_desc
      )
      ORDER BY lm.updated_at DESC
    ),
    '[]'::jsonb
  )
  FROM public.loyalty_members lm
  JOIN public.loyalty_programs lp ON lp.id = lm.program_id AND lp.is_active = true
  LEFT JOIN public.businesses b ON b.id = COALESCE(
    lp.business_id,
    (SELECT id FROM public.businesses WHERE chain_id = lp.chain_id ORDER BY chain_sort_order NULLS LAST LIMIT 1)
  )
  WHERE lm.user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_loyalty_cards_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_loyalty_cards_v1() TO authenticated;
COMMENT ON FUNCTION public.get_my_loyalty_cards_v1 IS
  'Müşteri: tüm sadakat kartlarını döner. Called by: mobil features/sadakat (Faz 4), web app/(kimlik)/sadakat (Faz 3).';

-- ── _award_loyalty_progress (internal, client''a GRANT edilmez) ──────────────
CREATE OR REPLACE FUNCTION public._award_loyalty_progress(
  p_business_id uuid,
  p_user_id     uuid,
  p_amount      int,
  p_source      text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_member_id  uuid;
BEGIN
  IF p_source NOT IN ('review') THEN
    RAISE EXCEPTION 'validation_error: geçersiz source' USING ERRCODE = 'P0003';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.loyalty_programs WHERE id = v_program_id AND is_active = true) THEN
    RETURN;
  END IF;

  INSERT INTO public.loyalty_members (program_id, user_id, progress)
  VALUES (v_program_id, p_user_id, p_amount)
  ON CONFLICT (program_id, user_id) DO UPDATE SET
    progress = loyalty_members.progress + excluded.progress,
    updated_at = now()
  RETURNING id INTO v_member_id;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (v_member_id, p_source, p_amount, NULL);
END;
$$;

REVOKE ALL ON FUNCTION public._award_loyalty_progress(uuid, uuid, int, text) FROM PUBLIC;
COMMENT ON FUNCTION public._award_loyalty_progress IS
  'Internal: public RPC değil, client''a hiç GRANT edilmez. Called by: trg_award_loyalty_on_review.';

-- ── Yorum onaylanınca otomatik kazanma ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.trg_award_loyalty_on_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status <> 'approved') THEN
    PERFORM public._award_loyalty_progress(NEW.business_id, NEW.user_id, 1, 'review');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_loyalty_review ON public.reviews;
CREATE TRIGGER trg_loyalty_review
  AFTER INSERT OR UPDATE OF status ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_loyalty_on_review();
