-- achievements_extended: insert new achievement badges + backfill tier into condition JSONB
-- Safe to re-run: INSERT uses ON CONFLICT DO UPDATE; UPDATE guards with WHERE NOT (condition ? 'tier')

-- ───────────────────────────────────────────────
-- 1. INSERT new badges (idempotent via ON CONFLICT)
-- ───────────────────────────────────────────────
INSERT INTO public.achievements (id, title, description, icon, color, xp, is_hidden, condition)
VALUES
  -- Ziyaret
  ('first_visit',       'İlk Adım',           '1. işletme ziyareti',                          'location-dot',  '#78716C', 20,  false, '{"type":"visit_count","target":1,"tier":"bronze"}'),
  ('explorer_5',        'Kaşif',              '5 farklı işletme ziyareti',                    'compass',       '#0D9488', 40,  false, '{"type":"visit_count","target":5,"tier":"bronze"}'),
  ('district_15',       'Semt Turisti',       '15 farklı işletme ziyareti',                   'map',           '#0891B2', 80,  false, '{"type":"visit_count","target":15,"tier":"silver"}'),
  ('city_50',           'Şehir Gezgini',      '50 farklı işletme ziyareti',                   'city',          '#B45309', 200, false, '{"type":"visit_count","target":50,"tier":"gold"}'),
  ('night_gourmet_10',  'Gece Kuşu',          '10 ziyaret 20:00+ saatte',                     'moon',          '#6D28D9', 100, false, '{"type":"night_visit","target":10,"tier":"silver"}'),

  -- Yorum & Katkı
  ('reviewer_5',        'Anlatıcı',           '5 yorum yaz',                                  'comment',       '#16A34A', 50,  false, '{"type":"review_count","target":5,"tier":"bronze"}'),
  ('gourmet_pen_20',    'Gurme Kalemi',       '20 yorum yaz',                                 'pen-nib',       '#0284C7', 120, false, '{"type":"review_count","target":20,"tier":"silver"}'),
  ('legend_reviewer_50','Efsane Yorumcu',     '50 yorum yaz',                                 'feather',       '#B45309', 300, false, '{"type":"review_count","target":50,"tier":"gold"}'),
  ('quality_voice',     'Kaliteli Ses',       '3+ kaliteli yorum (quality_score ≥ 0.75)',     'star',          '#D97706', 150, false, '{"type":"quality_review","target":3,"tier":"gold"}'),
  ('helpful_10',        'Beğenilen',          '10 kişi yorumunu faydalı buldu',               'thumbs-up',     '#0369A1', 100, false, '{"type":"helpful_count","target":10,"tier":"silver"}'),

  -- Fiyat & Veri
  ('price_detective_5', 'Fiyat Dedektifi',   '5 fiyat katkısı',                              'tags',          '#15803D', 50,  false, '{"type":"price_count","target":5,"tier":"bronze"}'),
  ('budget_expert_20',  'Bütçe Uzmanı',      '20 onaylı fiyat katkısı',                      'coins',         '#0E7490', 120, false, '{"type":"price_count","target":20,"tier":"silver"}'),
  ('price_champion_50', 'Fiyat Şampiyonu',   '50 onaylı fiyat katkısı',                      'trophy',        '#92400E', 300, false, '{"type":"price_count","target":50,"tier":"gold"}'),
  ('accuracy_90',       'Doğrulukçu',        '%90+ onay oranı (≥10 katkı)',                  'bullseye',      '#B45309', 200, false, '{"type":"price_accuracy","target":90,"tier":"gold"}'),

  -- Fotoğraf
  ('lens_3',            'Objektif',           '3 fotoğraf yükle',                             'camera',        '#6B7280', 30,  false, '{"type":"photo_count","target":3,"tier":"bronze"}'),
  ('viewfinder_15',     'Vizör',              '15 fotoğraf yükle',                            'image',         '#0284C7', 100, false, '{"type":"photo_count","target":15,"tier":"silver"}'),
  ('photo_master_50',   'Fotoğraf Ustası',   '50 fotoğraf yükle',                            'camera-retro',  '#92400E', 280, false, '{"type":"photo_count","target":50,"tier":"gold"}'),

  -- Sosyal
  ('first_follower',    'İlk Takipçi',       'İlk koleksiyon takipçisi',                     'user-plus',     '#6D28D9', 30,  false, '{"type":"follower_count","target":1,"tier":"bronze"}'),
  ('social_5',          'Sosyal Kelebek',    '5 koleksiyon takipçisi',                        'users',         '#7C3AED', 100, false, '{"type":"follower_count","target":5,"tier":"silver"}'),
  ('community_star_20', 'Topluluk Yıldızı',  '20 koleksiyon takipçisi',                      'star',          '#5B21B6', 300, false, '{"type":"follower_count","target":20,"tier":"gold"}'),

  -- Gizli / Özel
  ('chance_hunter_3',   'Şans Avcısı',       '3 kampanya kullanımı',                         'compass',       '#F9A825', 60,  true,  '{"type":"campaign_use","target":3,"tier":"special"}'),
  ('silent_quality_10', 'Sessiz Kalite',     'Hiç reddedilmeden 10 katkı',                  'shield-halved', '#374151', 150, true,  '{"type":"silent_quality","target":10,"tier":"special"}')

ON CONFLICT (id) DO UPDATE SET
  title       = EXCLUDED.title,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  color       = EXCLUDED.color,
  xp          = EXCLUDED.xp,
  is_hidden   = EXCLUDED.is_hidden,
  condition   = EXCLUDED.condition;


-- ───────────────────────────────────────────────
-- 2. Backfill tier into existing badges (only where tier not yet set)
-- ───────────────────────────────────────────────

-- Mevcut (pre-existing) rozet satırlarına tier ekle. Yeni eklenenler zaten INSERT'te tier alıyor.
-- Bronze
update public.achievements
set condition = condition || '{"tier":"bronze"}'::jsonb
where id in (
  'first_review', 'first_rating', 'first_discovery',
  'price_hunter_5', 'observer_3', 'weekend_wanderer_8'
)
  and not (condition ? 'tier');

-- Silver
update public.achievements
set condition = condition || '{"tier":"silver"}'::jsonb
where id in (
  'traveler_10', 'district_gourmet_top10', 'detective_10'
)
  and not (condition ? 'tier');

-- Gold
update public.achievements
set condition = condition || '{"tier":"gold"}'::jsonb
where id in (
  'trusted_contributor', 'pizza_master_10', 'deep_menu_diver_30',
  'combo_price_streak_3', 'combo_district_master_5', 'combo_full_contributor'
)
  and not (condition ? 'tier');

-- Special
update public.achievements
set condition = condition || '{"tier":"special"}'::jsonb
where id in (
  'silent_follower_20', 'menu_archivist_1',
  'chance_hunter_10', 'night_gourmet_5'
)
  and not (condition ? 'tier');
