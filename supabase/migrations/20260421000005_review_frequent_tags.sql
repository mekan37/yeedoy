-- ─────────────────────────────────────────────────────────────────────────────
-- review_tags: aggregated mention counts per (business, tag) pair.
-- Populated by trg_extract_review_tags_v1 on every approved review INSERT.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.review_tags (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id    uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  tag            text        NOT NULL CHECK (char_length(tag) BETWEEN 2 AND 60),
  mention_count  integer     NOT NULL DEFAULT 1,
  last_seen_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT review_tags_business_tag_key UNIQUE (business_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_review_tags_business_id
  ON public.review_tags (business_id);

ALTER TABLE public.review_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "review_tags_read_all"
  ON public.review_tags FOR SELECT
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- Tag extraction trigger
-- Keyword list: TR-first, lowercase ilike match against review body.
-- Tags are intentionally human-readable (shown as chips in the UI).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.trg_extract_review_tags_v1()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_body  text;
  v_tag   text;
  v_tags  text[];
BEGIN
  IF tg_op <> 'INSERT' THEN RETURN new; END IF;

  -- Only process approved reviews with non-empty body
  IF new.status IS NOT NULL AND new.status <> 'approved' THEN RETURN new; END IF;
  v_body := lower(coalesce(new.body, ''));
  IF char_length(v_body) < 5 THEN RETURN new; END IF;

  v_tags := ARRAY[]::text[];

  -- ── Portion ──
  IF v_body ILIKE ANY(ARRAY['%bol porsiyon%','%porsiyon büyük%','%porsiyon bol%','%çok geldi%','%fazla geldi%'])
  THEN v_tags := array_append(v_tags, 'Bol Porsiyon'); END IF;

  IF v_body ILIKE ANY(ARRAY['%porsiyon küçük%','%az geldi%','%az porsiyon%','%küçük porsiyon%','%yetersiz miktar%'])
  THEN v_tags := array_append(v_tags, 'Küçük Porsiyon'); END IF;

  -- ── Staff ──
  IF v_body ILIKE ANY(ARRAY['%personel ilgili%','%garson ilgili%','%nazik%','%güler yüzlü%','%yardımcı%','%güler yüz%','%samimi%'])
  THEN v_tags := array_append(v_tags, 'İlgili Personel'); END IF;

  IF v_body ILIKE ANY(ARRAY['%personel kaba%','%garson kötü%','%ilgisiz%','%umursamaz%','%kötü davrand%'])
  THEN v_tags := array_append(v_tags, 'İlgisiz Personel'); END IF;

  -- ── Service speed ──
  IF v_body ILIKE ANY(ARRAY['%hızlı servis%','%hızlı geldi%','%çabuk geldi%','%hızlıydı%','%beklemedim%','%anında geldi%'])
  THEN v_tags := array_append(v_tags, 'Hızlı Servis'); END IF;

  IF v_body ILIKE ANY(ARRAY['%yavaş%','%çok beklettiler%','%uzun sürdü%','%bekledik%','%gecikti%','%geç geldi%'])
  THEN v_tags := array_append(v_tags, 'Yavaş Servis'); END IF;

  -- ── Cleanliness ──
  IF v_body ILIKE ANY(ARRAY['%çok temiz%','%temiz mekan%','%hijyenik%','%bakımlı%','%pırıl pırıl%'])
  THEN v_tags := array_append(v_tags, 'Temiz Mekan'); END IF;

  IF v_body ILIKE ANY(ARRAY['%kirli%','%bakımsız%','%hijyenik değil%','%pis%'])
  THEN v_tags := array_append(v_tags, 'Kirli Mekan'); END IF;

  -- ── Price ──
  IF v_body ILIKE ANY(ARRAY['%fiyatı uygun%','%hesaplı%','%ekonomik%','%ucuz%','%fiyat performans%','%fiyat/performans%'])
  THEN v_tags := array_append(v_tags, 'Uygun Fiyat'); END IF;

  IF v_body ILIKE ANY(ARRAY['%çok pahalı%','%pahalı%','%fiyat yüksek%','%fahiş%'])
  THEN v_tags := array_append(v_tags, 'Pahalı'); END IF;

  -- ── Taste ──
  IF v_body ILIKE ANY(ARRAY['%lezzetli%','%muhteşem%','%enfes%','%harika lezzet%','%çok güzeldi%','%nefis%','%harika tat%'])
  THEN v_tags := array_append(v_tags, 'Lezzetli'); END IF;

  IF v_body ILIKE ANY(ARRAY['%lezzetsiz%','%tatsız%','%kötü lezzet%','%berbat%','%iğrenç%'])
  THEN v_tags := array_append(v_tags, 'Lezzetsiz'); END IF;

  -- ── Atmosphere ──
  IF v_body ILIKE ANY(ARRAY['%ortam güzel%','%güzel ortam%','%ambiyans%','%dekor güzel%','%atmosfer%','%şık%','%keyifli ortam%'])
  THEN v_tags := array_append(v_tags, 'Güzel Ortam'); END IF;

  IF v_body ILIKE ANY(ARRAY['%gürültülü%','%çok ses%','%rahatsız edici%','%kötü ortam%'])
  THEN v_tags := array_append(v_tags, 'Gürültülü'); END IF;

  -- ── Recommendation ──
  IF v_body ILIKE ANY(ARRAY['%tekrar geleceğim%','%kesinlikle öneririm%','%tavsiye ederim%','%herkese öneririm%','%mutlaka gelin%'])
  THEN v_tags := array_append(v_tags, 'Tavsiye Ederim'); END IF;

  IF v_body ILIKE ANY(ARRAY['%bir daha gitmem%','%gelmeyeceğim%','%önermiyorum%','%tavsiye etmiyorum%'])
  THEN v_tags := array_append(v_tags, 'Önermiyorum'); END IF;

  -- Upsert matched tags
  FOREACH v_tag IN ARRAY v_tags LOOP
    INSERT INTO public.review_tags (business_id, tag, mention_count, last_seen_at)
    VALUES (new.business_id, v_tag, 1, now())
    ON CONFLICT (business_id, tag) DO UPDATE
      SET mention_count = review_tags.mention_count + 1,
          last_seen_at  = now();
  END LOOP;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS trg_extract_review_tags_v1 ON public.reviews;
CREATE TRIGGER trg_extract_review_tags_v1
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.trg_extract_review_tags_v1();

-- ─────────────────────────────────────────────────────────────────────────────
-- get_business_frequent_tags_v1
-- Returns top tags for a business with at least 2 mentions, ordered by count.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_business_frequent_tags_v1(
  p_business_id uuid,
  p_limit       int DEFAULT 8
)
RETURNS TABLE(tag text, mention_count integer)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT rt.tag, rt.mention_count
  FROM   public.review_tags rt
  WHERE  rt.business_id = p_business_id
    AND  rt.mention_count >= 2
  ORDER  BY rt.mention_count DESC, rt.tag
  LIMIT  p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_business_frequent_tags_v1(uuid, int) TO anon;
GRANT EXECUTE ON FUNCTION public.get_business_frequent_tags_v1(uuid, int) TO authenticated;
