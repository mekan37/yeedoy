-- Alerjen tespiti yeniden tasarımı: LLM artık alerjen konusunda son karar
-- veren sistem DEĞİL — sadece malzemeleri normalize eder. Gerçek alerjen
-- kararı deterministik bir kural motoruna (allergen_ingredient_aliases)
-- dayanır. LLM'in kendi mutfak bilgisiyle işaret ettiği (malzeme listesinde
-- açıkça geçmeyen) riskler ayrı bir "possible" statüsünde tutulur.
--
-- Ayrıca canlıda bulunan gerçek bir kod uyuşmazlığı düzeltiliyor: mevcut
-- ai-allergen-detect edge fonksiyonunun VALID_ALLERGENS seti ('egg',
-- 'crustaceans', 'sulfur_dioxide') ile owner panelinin gerçekte kullandığı
-- kodlar (src/ui/bolumler/menu-sayfasi/menu-duzen.tsx ALLERGEN_LABEL:
-- 'eggs', 'shellfish', 'sulphites') hiç eşleşmiyordu — AI tespiti hiç
-- çalışmamış olsaydı bile üretseydi, owner panelinde 3 kod hiç
-- görüntülenmeyecekti. allergens tablosu artık PANELİN GERÇEKTEN KULLANDIĞI
-- 14 kodla dolduruluyor; edge fonksiyonu bunlarla hizalanacak (ayrı görev).

CREATE TABLE public.allergens (
  code     text PRIMARY KEY CHECK (code ~ '^[a-z]+$'),
  label_tr text NOT NULL,
  emoji    text
);

INSERT INTO public.allergens (code, label_tr, emoji) VALUES
  ('gluten',    'Gluten',       '🌾'),
  ('milk',      'Süt',          '🥛'),
  ('eggs',      'Yumurta',      '🥚'),
  ('fish',      'Balık',        '🐟'),
  ('shellfish', 'Kabuklu',      '🦐'),
  ('peanuts',   'Yer Fıstığı',  '🥜'),
  ('treenuts',  'Kuruyemiş',    '🌰'),
  ('soy',       'Soya',         '🫘'),
  ('celery',    'Kereviz',      '🌿'),
  ('mustard',   'Hardal',       '🌼'),
  ('sesame',    'Susam',        '🫚'),
  ('sulphites', 'Sülfitler',    '🍷'),
  ('lupin',     'Acı Bakla',    '🌸'),
  ('molluscs',  'Yumuşakça',    '🐚');

-- Normalize edilmiş Türkçe malzeme → alerjen kodu eşlemesi. Bir malzeme
-- birden fazla alerjene işaret edebilir (composite PK bunu destekler).
CREATE TABLE public.allergen_ingredient_aliases (
  ingredient    text NOT NULL,
  allergen_code text NOT NULL REFERENCES public.allergens(code),
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (ingredient, allergen_code)
);

CREATE INDEX idx_allergen_aliases_ingredient ON public.allergen_ingredient_aliases (ingredient);

INSERT INTO public.allergen_ingredient_aliases (ingredient, allergen_code) VALUES
  -- GLUTEN
  ('un', 'gluten'), ('buğday unu', 'gluten'), ('buğday', 'gluten'), ('ekmek', 'gluten'),
  ('bulgur', 'gluten'), ('irmik', 'gluten'), ('makarna', 'gluten'), ('erişte', 'gluten'),
  ('bira', 'gluten'), ('malt', 'gluten'), ('galeta unu', 'gluten'), ('galeta', 'gluten'),
  ('kraker', 'gluten'), ('kadayıf', 'gluten'), ('yufka', 'gluten'), ('tarhana', 'gluten'),
  ('arpa', 'gluten'), ('çavdar', 'gluten'), ('tel şehriye', 'gluten'), ('şehriye', 'gluten'),
  ('kuskus', 'gluten'), ('simit', 'gluten'), ('pide', 'gluten'), ('lavaş', 'gluten'),
  ('ekmek kırıntısı', 'gluten'), ('köfte harcı', 'gluten'), ('katmer', 'gluten'),
  ('börek yufkası', 'gluten'), ('erişte hamuru', 'gluten'), ('pizza hamuru', 'gluten'),
  ('kek unu', 'gluten'), ('bisküvi', 'gluten'), ('gofret', 'gluten'),

  -- MILK
  ('süt', 'milk'), ('tereyağı', 'milk'), ('krema', 'milk'), ('kaymak', 'milk'),
  ('yoğurt', 'milk'), ('peynir', 'milk'), ('kaşar', 'milk'), ('lor', 'milk'),
  ('çökelek', 'milk'), ('ayran', 'milk'), ('süt tozu', 'milk'), ('dondurma', 'milk'),
  ('beyaz peynir', 'milk'), ('mozarella', 'milk'), ('parmesan', 'milk'), ('kefir', 'milk'),
  ('labne', 'milk'), ('sütlaç sütü', 'milk'), ('muhallebi', 'milk'), ('krem şanti', 'milk'),
  ('tulum peyniri', 'milk'), ('cheddar', 'milk'), ('rikotta', 'milk'), ('mascarpone', 'milk'),
  ('süzme yoğurt', 'milk'), ('kaymaklı dondurma', 'milk'),

  -- EGGS
  ('yumurta', 'eggs'), ('mayonez', 'eggs'), ('beze', 'eggs'), ('krem karamel', 'eggs'),
  ('sufle', 'eggs'), ('omlet', 'eggs'), ('çırpılmış yumurta', 'eggs'), ('yumurta sarısı', 'eggs'),
  ('yumurta akı', 'eggs'), ('kruvasan', 'eggs'),

  -- FISH
  ('balık', 'fish'), ('hamsi', 'fish'), ('levrek', 'fish'), ('çupra', 'fish'),
  ('somon', 'fish'), ('ton balığı', 'fish'), ('uskumru', 'fish'), ('balık sosu', 'fish'),
  ('anchois', 'fish'), ('morina', 'fish'), ('palamut', 'fish'), ('lüfer', 'fish'),
  ('mezgit', 'fish'), ('balık yumurtası', 'fish'), ('havyar', 'fish'),

  -- SHELLFISH
  ('karides', 'shellfish'), ('yengeç', 'shellfish'), ('ıstakoz', 'shellfish'),
  ('langust', 'shellfish'), ('deniz kabuğu', 'shellfish'),

  -- PEANUTS
  ('yer fıstığı', 'peanuts'), ('fıstık ezmesi', 'peanuts'), ('yer fıstığı yağı', 'peanuts'),
  ('yer fıstığı sosu', 'peanuts'),

  -- TREENUTS
  ('fındık', 'treenuts'), ('ceviz', 'treenuts'), ('badem', 'treenuts'),
  ('antep fıstığı', 'treenuts'), ('kaju', 'treenuts'), ('çam fıstığı', 'treenuts'),
  ('makademya', 'treenuts'), ('pekan cevizi', 'treenuts'), ('fındık ezmesi', 'treenuts'),
  ('badem ezmesi', 'treenuts'), ('fındık kreması', 'treenuts'),

  -- SOY
  ('soya', 'soy'), ('soya sosu', 'soy'), ('tofu', 'soy'), ('soya fasulyesi', 'soy'),
  ('soya yağı', 'soy'), ('edamame', 'soy'), ('soya sütü', 'soy'),

  -- CELERY
  ('kereviz', 'celery'), ('kereviz sapı', 'celery'), ('kereviz tohumu', 'celery'),
  ('kereviz kökü', 'celery'),

  -- MUSTARD
  ('hardal', 'mustard'), ('hardal tohumu', 'mustard'), ('hardal sosu', 'mustard'),

  -- SESAME
  ('susam', 'sesame'), ('tahin', 'sesame'), ('susam yağı', 'sesame'),
  ('simit susamı', 'sesame'), ('humus', 'sesame'), ('tahin helvası', 'sesame'),

  -- SULPHITES
  ('kuru üzüm', 'sulphites'), ('kuru kayısı', 'sulphites'), ('kuru meyve', 'sulphites'),
  ('şarap', 'sulphites'), ('sirke', 'sulphites'), ('turşu', 'sulphites'),
  ('kükürt dioksit', 'sulphites'), ('elma sirkesi', 'sulphites'), ('üzüm sirkesi', 'sulphites'),

  -- LUPIN
  ('acı bakla', 'lupin'), ('lupin unu', 'lupin'),

  -- MOLLUSCS
  ('midye', 'molluscs'), ('kalamar', 'molluscs'), ('ahtapot', 'molluscs'),
  ('istiridye', 'molluscs'), ('salyangoz', 'molluscs'), ('deniz tarağı', 'molluscs');

-- ── menu_item_allergens: status/evidence ekleniyor ──────────────────────────
-- risk_level/detected_by kolonları KALDIRILMIYOR (geriye dönük uyumluluk,
-- mevcut public okuma politikaları bu kolonlara dokunmuyor). status yeni
-- kural motorunun ürettiği gerçek sinyal; risk_level status'tan türetilir.

ALTER TABLE public.menu_item_allergens
  ADD COLUMN status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'possible')),
  ADD COLUMN evidence text,
  ADD CONSTRAINT menu_item_allergens_allergen_fkey FOREIGN KEY (allergen) REFERENCES public.allergens(code);

-- owner_upsert_menu_item_allergens_v1: artık status/evidence de kabul eder.
-- p_allergens: [{"allergen": "milk", "status": "confirmed"|"possible", "evidence": "tereyağı", "detected_by": "ai"|"manual"}]
CREATE OR REPLACE FUNCTION public.owner_upsert_menu_item_allergens_v1(
  p_item_id    uuid,
  p_allergens  jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_entry       jsonb;
  v_status      text;
BEGIN
  SELECT m.business_id INTO v_business_id
  FROM menu_items mi
  JOIN menu_sections ms ON ms.id = mi.section_id
  JOIN menus m          ON m.id  = ms.menu_id
  WHERE mi.id = p_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'item_not_found');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM owner_claims
    WHERE business_id = v_business_id
      AND user_id     = auth.uid()
      AND status      = 'approved'
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authorized');
  END IF;

  DELETE FROM menu_item_allergens WHERE item_id = p_item_id;

  FOR v_entry IN SELECT * FROM jsonb_array_elements(p_allergens)
  LOOP
    v_status := coalesce(v_entry->>'status', 'confirmed');
    IF v_status NOT IN ('confirmed', 'possible') THEN
      v_status := 'confirmed';
    END IF;

    INSERT INTO menu_item_allergens (item_id, allergen, risk_level, detected_by, status, evidence, updated_at)
    VALUES (
      p_item_id,
      v_entry->>'allergen',
      CASE WHEN v_status = 'possible' THEN 'may_contain' ELSE 'contains' END,
      coalesce(v_entry->>'detected_by', 'manual'),
      v_status,
      v_entry->>'evidence',
      now()
    );
  END LOOP;

  RETURN jsonb_build_object('ok', true);
END;
$$;
