-- ============================================================
-- business_location_review_queue
-- Düşük güvenli veya belirsiz city/district kayıtlarını silmeden takip eder.
-- Admin panel üzerinden manuel düzeltmeye temel oluşturur.
-- Oluşturulma: 2026-06-09
-- ============================================================

CREATE TABLE IF NOT EXISTS public.business_location_review_queue (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id        uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  old_city           text,
  old_district       text,
  reason             text        NOT NULL,
  suggested_city     text,
  suggested_district text,
  confidence         numeric     CHECK (confidence >= 0 AND confidence <= 1),
  source             text        NOT NULL DEFAULT 'location_normalization_20260609',
  review_status      text        NOT NULL DEFAULT 'pending'
                                 CHECK (review_status IN ('pending', 'approved', 'rejected', 'skipped')),
  reviewed_by        uuid        NULL REFERENCES auth.users(id),
  reviewed_at        timestamptz NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT uq_review_queue_business_source_reason
    UNIQUE (business_id, source, reason)
);

-- ── İndeksler ───────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_review_queue_status
  ON public.business_location_review_queue(review_status);

CREATE INDEX IF NOT EXISTS idx_review_queue_business_id
  ON public.business_location_review_queue(business_id);

CREATE INDEX IF NOT EXISTS idx_review_queue_source_status
  ON public.business_location_review_queue(source, review_status);

-- ── RLS ─────────────────────────────────────────────────────
ALTER TABLE public.business_location_review_queue ENABLE ROW LEVEL SECURITY;

-- Sadece admin erişimi (public.is_admin() projede standart pattern)
DROP POLICY IF EXISTS "review_queue_admin_all" ON public.business_location_review_queue;
CREATE POLICY "review_queue_admin_all"
  ON public.business_location_review_queue
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING  (public.is_admin())
  WITH CHECK (public.is_admin());

-- anon ve authenticated (non-admin) doğrudan erişimi tamamen engelle
DROP POLICY IF EXISTS "review_queue_no_public_access" ON public.business_location_review_queue;
CREATE POLICY "review_queue_no_public_access"
  ON public.business_location_review_queue
  AS PERMISSIVE
  FOR ALL
  TO anon
  USING (false)
  WITH CHECK (false);

-- ── Grant ────────────────────────────────────────────────────
-- Yalnızca authenticated role'e; is_admin() RLS politikası filtreleyecek
GRANT SELECT, INSERT, UPDATE ON public.business_location_review_queue TO authenticated;

COMMENT ON TABLE public.business_location_review_queue IS
  'Manuel gözden geçirme kuyruğu: normalize edilemeyen veya düşük güvenli city/district kayıtları. '
  'Kaynak migration: 20260609000003_normalize_businesses_location. '
  'Admin panelinden review_status güncellenerek işlenir.';
