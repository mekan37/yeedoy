-- notification_preferences tablosu eksikti — src/lib ve app tarafında hem
-- tüketici (bildirim-ayarlari) hem sahip panelindeki bildirim tercihi
-- toggle'ları bu tabloya upsert atıyordu ama tablo hiç var olmamıştı
-- (her toggle sessizce "Tercih kaydedilemedi" ile başarısız oluyordu).

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  enabled           boolean NOT NULL DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, notification_type)
);

CREATE INDEX IF NOT EXISTS notification_preferences_user_idx ON public.notification_preferences (user_id);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY notification_preferences_select_own ON public.notification_preferences
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY notification_preferences_insert_own ON public.notification_preferences
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY notification_preferences_update_own ON public.notification_preferences
  FOR UPDATE TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.notification_preferences TO authenticated;

COMMENT ON TABLE public.notification_preferences IS
  'Kullanıcı bazlı olay-türü bildirim tercihleri (user_id, notification_type) çifti başına bir satır. '
  'Tüketici tarafı türleri: review_replies, price_alerts, new_businesses. '
  'Sahip paneli türleri: owner_new_review, owner_reservation_request, owner_price_suggestion, owner_weekly_summary. '
  'Çağıranlar: app/(kimlik)/bildirim-ayarlari/bildirim-tercihleri.tsx, app/sahip/ayarlar/sekmeler/bildirim-ayarlari-sekmesi.tsx.';
