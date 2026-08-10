-- Sadakat v1 — premium plan gating seed. map_boost ile aynı kademe eşiği.
INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'sadakat_programi', NULL, false),
  ('starter',  'sadakat_programi', NULL, false),
  ('standard', 'sadakat_programi', NULL, true),
  ('pro',      'sadakat_programi', NULL, true);
