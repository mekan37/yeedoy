-- Sadakat Kartı Sistemi: "10 kahvaltı al, 1 bedava"
-- Sahip program oluşturur → Müşteri check-in veya satın alımla damga biriktirir

CREATE TABLE IF NOT EXISTS loyalty_programs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name          TEXT        NOT NULL,              -- "Kahve Sadakat"
  stamps_needed INT         NOT NULL DEFAULT 10,   -- 10 damga → ödül
  reward_desc   TEXT        NOT NULL,              -- "1 bedava filtre kahve"
  is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2026-07-23 fix: 20260424000007_loyalty_program.sql bu tablodan bir "yalın"
-- versiyon (business_id PRIMARY KEY, id kolonu yok) daha önce oluşturmuş
-- olabilir — CREATE TABLE IF NOT EXISTS o durumda no-op olur ve id kolonu
-- hiç eklenmez. loyalty (sadakat) özelliği MVP kapsamı dışı bırakıldığı için
-- iki tasarımı tam uzlaştırmak yerine, loyalty_cards'ın FK'sinin çalışması
-- için gereken minimum garanti ekleniyor.
ALTER TABLE loyalty_programs ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
UPDATE loyalty_programs SET id = gen_random_uuid() WHERE id IS NULL;
ALTER TABLE loyalty_programs ALTER COLUMN id SET NOT NULL;
ALTER TABLE loyalty_programs ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT 'Sadakat Programı';
ALTER TABLE loyalty_programs ADD COLUMN IF NOT EXISTS stamps_needed INT NOT NULL DEFAULT 10;
ALTER TABLE loyalty_programs ADD COLUMN IF NOT EXISTS reward_desc TEXT NOT NULL DEFAULT '';
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'loyalty_programs'::regclass
      AND contype = 'u'
      AND conkey = ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid = 'loyalty_programs'::regclass AND attname = 'id')]
  ) THEN
    ALTER TABLE loyalty_programs ADD CONSTRAINT loyalty_programs_id_key UNIQUE (id);
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS loyalty_cards (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   UUID        NOT NULL REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stamp_count  INT         NOT NULL DEFAULT 0,
  redeemed_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (program_id, user_id)
);

-- Sahip program oluşturur
CREATE OR REPLACE FUNCTION create_loyalty_program_v1(
  p_business_id  UUID,
  p_name         TEXT,
  p_stamps_needed INT,
  p_reward_desc  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner UUID;
  v_prog_id UUID;
BEGIN
  SELECT owner_id INTO v_owner FROM businesses WHERE id = p_business_id;
  IF v_owner IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  INSERT INTO loyalty_programs (business_id, name, stamps_needed, reward_desc)
  VALUES (p_business_id, trim(p_name), p_stamps_needed, trim(p_reward_desc))
  RETURNING id INTO v_prog_id;

  RETURN jsonb_build_object('ok', true, 'program_id', v_prog_id);
END;
$$;

-- Sahip müşteriye damga ekler (QR okutma sonrası)
CREATE OR REPLACE FUNCTION add_loyalty_stamp_v1(
  p_program_id UUID,
  p_user_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner     UUID;
  v_biz_id    UUID;
  v_stamps    INT;
  v_needed    INT;
BEGIN
  SELECT b.owner_id, b.id, lp.stamps_needed
  INTO v_owner, v_biz_id, v_needed
  FROM loyalty_programs lp
  JOIN businesses b ON b.id = lp.business_id
  WHERE lp.id = p_program_id AND lp.is_active = TRUE;

  IF v_owner IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  INSERT INTO loyalty_cards (program_id, user_id, stamp_count)
  VALUES (p_program_id, p_user_id, 1)
  ON CONFLICT (program_id, user_id)
  DO UPDATE SET stamp_count = loyalty_cards.stamp_count + 1
  RETURNING stamp_count INTO v_stamps;

  RETURN jsonb_build_object(
    'ok', true,
    'stamp_count', v_stamps,
    'stamps_needed', v_needed,
    'reward_ready', v_stamps >= v_needed
  );
END;
$$;

-- Kullanıcı kartlarını görür
-- 2026-07-23 fix: 20260424000007_loyalty_program.sql aynı isimle jsonb
-- dönen farklı bir versiyon tanımlamıştı (rekabetçi/çakışan sadakat
-- tasarımı, özellik MVP kapsamı dışı) — CREATE OR REPLACE dönüş tipi
-- değiştiremediği için önce DROP gerekiyor.
DROP FUNCTION IF EXISTS public.get_my_loyalty_cards_v1();
CREATE OR REPLACE FUNCTION get_my_loyalty_cards_v1()
RETURNS TABLE (
  card_id      UUID,
  program_id   UUID,
  program_name TEXT,
  reward_desc  TEXT,
  stamp_count  INT,
  stamps_needed INT,
  business_id  UUID,
  business_name TEXT,
  redeemed_at  TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    lc.id, lc.program_id,
    lp.name, lp.reward_desc,
    lc.stamp_count, lp.stamps_needed,
    b.id, b.name,
    lc.redeemed_at
  FROM loyalty_cards lc
  JOIN loyalty_programs lp ON lp.id = lc.program_id
  JOIN businesses b ON b.id = lp.business_id
  WHERE lc.user_id = auth.uid()
    AND lp.is_active = TRUE
  ORDER BY lc.created_at DESC;
$$;

CREATE INDEX IF NOT EXISTS idx_loyalty_cards_user ON loyalty_cards (user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_programs_biz ON loyalty_programs (business_id) WHERE is_active = TRUE;
