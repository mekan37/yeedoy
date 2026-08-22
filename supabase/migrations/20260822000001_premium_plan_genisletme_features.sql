-- Premium plan genişletmesi: ekip üyesi, CRM kampanyası, çoklu şube, analitik derinliği.
-- Şema değişikliği yok — plan_features zaten genel amaçlı (plan_tier, feature_key, limit_value, enabled).

INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'team_seat_count',           1,    true),
  ('starter',  'team_seat_count',           3,    true),
  ('standard', 'team_seat_count',           10,   true),
  ('pro',      'team_seat_count',           NULL, true),

  ('free',     'campaign_count_per_month',  0,    true),
  ('starter',  'campaign_count_per_month',  1,    true),
  ('standard', 'campaign_count_per_month',  5,    true),
  ('pro',      'campaign_count_per_month',  NULL, true),

  ('free',     'branch_count',              1,    true),
  ('starter',  'branch_count',              1,    true),
  ('standard', 'branch_count',              3,    true),
  ('pro',      'branch_count',              NULL, true),

  ('free',     'analytics_range_days',      7,    true),
  ('starter',  'analytics_range_days',      30,   true),
  ('standard', 'analytics_range_days',      90,   true),
  ('pro',      'analytics_range_days',      90,   true)
ON CONFLICT (plan_tier, feature_key) DO NOTHING;
