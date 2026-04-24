-- Migration: 20260422000002_menu_feedback
-- Purpose: Public-facing feedback form for digital menu pages (Next.js web).
--          Stores anonymous star rating + category + optional message.
-- ADR: docs/adr/0004-business-feedback-storage.md

CREATE TABLE IF NOT EXISTS menu_feedback (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id  uuid          NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  rating       smallint      NOT NULL CHECK (rating BETWEEN 1 AND 5),
  category     text          NOT NULL DEFAULT 'other'
                             CHECK (category IN ('menu','price','service','app','other')),
  message      text          CHECK (char_length(message) <= 500),
  created_at   timestamptz   NOT NULL DEFAULT now()
);

-- Index for business-level aggregation in admin queries
CREATE INDEX idx_menu_feedback_business_id ON menu_feedback (business_id);
CREATE INDEX idx_menu_feedback_created_at  ON menu_feedback (created_at DESC);

-- RLS: anon can INSERT (rate-limited at application level), nobody can SELECT
-- directly except service_role. Owner/admin views this via Supabase Studio or
-- a future panel page.
ALTER TABLE menu_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_can_insert_menu_feedback"
  ON menu_feedback
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- No SELECT policy for anon/authenticated — admin reads via service_role only.

COMMENT ON TABLE menu_feedback IS
  'Anonymous feedback submitted via the public digital menu page (/m/[slug]).
   Rate-limited at the API layer (5 req/min per IP). No PII stored.';
