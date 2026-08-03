-- Premium plan/gating altyapısı — temel şema.
-- business_premium.tier zaten var (verified/premium rozetleri için) — yeni bir
-- "bu işletme premium mi" kaynağı açmak yerine CHECK'i genişletip aynı tabloyu
-- SaaS plan kademeleri için de kullanıyoruz.

ALTER TABLE public.business_premium
  DROP CONSTRAINT business_premium_tier_check;

ALTER TABLE public.business_premium
  ADD CONSTRAINT business_premium_tier_check
  CHECK (tier = ANY (ARRAY['verified','premium','starter','standard','pro']::text[]));

-- Bir işletmede aynı anda yalnızca TEK bir plan kademesi (starter/standard/pro)
-- aktif olabilir. verified/premium rozetleri bundan bağımsız, birlikte var olabilir
-- (mevcut business_premium_active_unique (business_id, tier) bunu zaten koruyor,
-- ama o farklı tier değerlerinin AYNI ANDA aktif olmasını engellemiyor — bu yeni
-- index sadece plan kademeleri arasında karşılıklı dışlama sağlıyor).
CREATE UNIQUE INDEX business_premium_active_plan_unique
  ON public.business_premium (business_id)
  WHERE status = 'active' AND tier IN ('starter','standard','pro');

-- Kademe → özellik/limit eşlemesi. Veri, kod değil — SQL satırıyla değiştirilebilir.
CREATE TABLE public.plan_features (
  plan_tier   text NOT NULL CHECK (plan_tier IN ('free','starter','standard','pro')),
  feature_key text NOT NULL,
  limit_value int NULL,
  enabled     boolean NOT NULL DEFAULT true,
  PRIMARY KEY (plan_tier, feature_key)
);

ALTER TABLE public.plan_features ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plan_features_public_read" ON public.plan_features
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "plan_features_admin_write" ON public.plan_features
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Sayaçlı özellikler için aylık kullanım takibi (ör. "bu ay kaç OCR taraması").
CREATE TABLE public.plan_feature_usage (
  business_id  uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  feature_key  text NOT NULL,
  period_start date NOT NULL,
  usage_count  int NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, feature_key, period_start)
);

ALTER TABLE public.plan_feature_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plan_feature_usage_owner_read" ON public.plan_feature_usage
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = plan_feature_usage.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
  );

-- Seed: kademe → özellik eşlemesi (spec'teki Bölüm 1 tablosu)
INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'menu_item_count',     30,   true),
  ('starter',  'menu_item_count',     NULL, true),
  ('standard', 'menu_item_count',     NULL, true),
  ('pro',      'menu_item_count',     NULL, true),

  ('free',     'ocr_scans_per_month', 1,    true),
  ('starter',  'ocr_scans_per_month', 5,    true),
  ('standard', 'ocr_scans_per_month', NULL, true),
  ('pro',      'ocr_scans_per_month', NULL, true),

  ('free',     'allergen_ai',         NULL, false),
  ('starter',  'allergen_ai',         NULL, false),
  ('standard', 'allergen_ai',         NULL, true),
  ('pro',      'allergen_ai',         NULL, true),

  ('free',     'language_count',      1,    true),
  ('starter',  'language_count',      1,    true),
  ('standard', 'language_count',      2,    true),
  ('pro',      'language_count',      NULL, true),

  ('free',     'ai_image_gen',        NULL, false),
  ('starter',  'ai_image_gen',        NULL, false),
  ('standard', 'ai_image_gen',        NULL, false),
  ('pro',      'ai_image_gen',        NULL, true),

  ('free',     'qr_watermark',        NULL, true),
  ('starter',  'qr_watermark',        NULL, false),
  ('standard', 'qr_watermark',        NULL, false),
  ('pro',      'qr_watermark',        NULL, false),

  ('free',     'map_boost',           NULL, false),
  ('starter',  'map_boost',           NULL, false),
  ('standard', 'map_boost',           NULL, true),
  ('pro',      'map_boost',           NULL, true);

COMMENT ON TABLE public.plan_features IS
  'Plan kademesi -> özellik/limit eşlemesi. limit_value NULL = sınırsız (sayısal) veya sadece enabled bakılır (boolean özellik).';
COMMENT ON TABLE public.plan_feature_usage IS
  'Aylık sayaçlı plan özellikleri için kullanım takibi (ör. ocr_scans_per_month).';
