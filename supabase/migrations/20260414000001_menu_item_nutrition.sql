-- ─── Menu item nutrition estimates ──────────────────────────────────────────
-- Yaklaşık besin değerleri (AI + USDA tahmini)
-- Her menu item için 1 satır (upsert ile güncellenir)

CREATE TABLE IF NOT EXISTS public.menu_item_nutrition (
  item_id          uuid        PRIMARY KEY
                               REFERENCES public.menu_items(id) ON DELETE CASCADE,
  calorie_min      integer,
  calorie_max      integer,
  protein_min_g    numeric(6,1),
  protein_max_g    numeric(6,1),
  fat_min_g        numeric(6,1),
  fat_max_g        numeric(6,1),
  carbs_min_g      numeric(6,1),
  carbs_max_g      numeric(6,1),
  serving_est_g    integer,
  is_approximate   boolean     NOT NULL DEFAULT true,
  source           text        NOT NULL DEFAULT 'ai_estimated',
  usda_fdc_ids     jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS menu_item_nutrition_item_idx
  ON public.menu_item_nutrition (item_id);

ALTER TABLE public.menu_item_nutrition ENABLE ROW LEVEL SECURITY;

-- İşletme sahibi kendi item'larının besin değerini okuyabilir
DROP POLICY IF EXISTS nutrition_owner_select ON public.menu_item_nutrition;
CREATE POLICY nutrition_owner_select
  ON public.menu_item_nutrition FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.menu_items mi
      JOIN public.owner_claims oc ON oc.business_id = mi.business_id
      WHERE mi.id = menu_item_nutrition.item_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
  );

-- Public okuma (menü görüntüleme için)
DROP POLICY IF EXISTS nutrition_public_select ON public.menu_item_nutrition;
CREATE POLICY nutrition_public_select
  ON public.menu_item_nutrition FOR SELECT
  USING (true);

-- ─── RPC: owner_upsert_menu_item_nutrition_v1 ────────────────────────────────

CREATE OR REPLACE FUNCTION public.owner_upsert_menu_item_nutrition_v1(
  p_item_id       uuid,
  p_calorie_min   integer,
  p_calorie_max   integer,
  p_protein_min_g numeric,
  p_protein_max_g numeric,
  p_fat_min_g     numeric,
  p_fat_max_g     numeric,
  p_carbs_min_g   numeric,
  p_carbs_max_g   numeric,
  p_serving_est_g integer   DEFAULT NULL,
  p_source        text      DEFAULT 'ai_estimated',
  p_usda_fdc_ids  jsonb     DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
BEGIN
  -- item'ın işletme sahibine ait olduğunu doğrula
  SELECT mi.business_id INTO v_business_id
  FROM public.menu_items mi
  JOIN public.owner_claims oc ON oc.business_id = mi.business_id
  WHERE mi.id = p_item_id
    AND oc.user_id = auth.uid()
    AND oc.status = 'approved'
  LIMIT 1;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_owner');
  END IF;

  INSERT INTO public.menu_item_nutrition (
    item_id, calorie_min, calorie_max,
    protein_min_g, protein_max_g,
    fat_min_g, fat_max_g,
    carbs_min_g, carbs_max_g,
    serving_est_g, source, usda_fdc_ids,
    is_approximate, updated_at
  ) VALUES (
    p_item_id, p_calorie_min, p_calorie_max,
    p_protein_min_g, p_protein_max_g,
    p_fat_min_g, p_fat_max_g,
    p_carbs_min_g, p_carbs_max_g,
    p_serving_est_g, p_source, p_usda_fdc_ids,
    true, now()
  )
  ON CONFLICT (item_id) DO UPDATE SET
    calorie_min   = EXCLUDED.calorie_min,
    calorie_max   = EXCLUDED.calorie_max,
    protein_min_g = EXCLUDED.protein_min_g,
    protein_max_g = EXCLUDED.protein_max_g,
    fat_min_g     = EXCLUDED.fat_min_g,
    fat_max_g     = EXCLUDED.fat_max_g,
    carbs_min_g   = EXCLUDED.carbs_min_g,
    carbs_max_g   = EXCLUDED.carbs_max_g,
    serving_est_g = EXCLUDED.serving_est_g,
    source        = EXCLUDED.source,
    usda_fdc_ids  = EXCLUDED.usda_fdc_ids,
    is_approximate = true,
    updated_at    = now();

  RETURN jsonb_build_object('ok', true);
END;
$$;
