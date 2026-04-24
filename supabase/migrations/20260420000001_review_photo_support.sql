-- Extend temp_uploads to support review photos
-- Adds 'review_photo' kind and review_id FK

ALTER TABLE public.temp_uploads DROP CONSTRAINT IF EXISTS temp_uploads_kind_check;
ALTER TABLE public.temp_uploads
  ADD CONSTRAINT temp_uploads_kind_check
  CHECK (kind = ANY (ARRAY[
    'qr'::text,
    'menu_page'::text,
    'menu_pdf'::text,
    'other'::text,
    'review_photo'::text
  ]));

ALTER TABLE public.temp_uploads
  ADD COLUMN IF NOT EXISTS review_id uuid
  REFERENCES public.reviews(id) ON DELETE CASCADE;

-- Index for fetching photos by review
CREATE INDEX IF NOT EXISTS temp_uploads_review_id_idx
  ON public.temp_uploads (review_id)
  WHERE review_id IS NOT NULL;
