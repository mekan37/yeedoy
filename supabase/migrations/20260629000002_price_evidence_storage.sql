-- Migration: price-evidence storage bucket and policies
-- Purpose: Mobile app receipt / price-proof uploads for community price verification.
-- Notes:
--   - Bucket is public: price/receipt images are public transparency data,
--     analogous to menu photos in the temp bucket.
--   - Path structure: receipts/{auth.uid()}/{businessId_or_general}/{timestamp}.{ext}
--   - Insert policy: first segment must be "receipts", second must match auth.uid().
--   - Public read: anyone can select (required for public URL access).
--   - Users cannot delete their own evidence. Admins may delete for moderation.
--   - File size limit: 8 MB. Allowed types: JPEG, PNG, WebP.

BEGIN;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'price-evidence',
  'price-evidence',
  true,
  8388608,
  ARRAY['image/jpeg','image/jpg','image/png','image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET name               = 'price-evidence',
      public             = true,
      file_size_limit    = 8388608,
      allowed_mime_types = ARRAY['image/jpeg','image/jpg','image/png','image/webp'];

-- Drop previous versions so the migration is idempotent.
DROP POLICY IF EXISTS "price_evidence_insert_own_prefix" ON storage.objects;
DROP POLICY IF EXISTS "price_evidence_select_public"     ON storage.objects;
DROP POLICY IF EXISTS "price_evidence_delete_admin_only" ON storage.objects;

-- Authenticated users may upload only under receipts/{their_uid}/...
CREATE POLICY "price_evidence_insert_own_prefix"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'price-evidence'
    AND split_part(name, '/', 1) = 'receipts'
    AND split_part(name, '/', 2) = auth.uid()::text
    AND (
      lower(name) LIKE '%.jpg'
      OR lower(name) LIKE '%.jpeg'
      OR lower(name) LIKE '%.png'
      OR lower(name) LIKE '%.webp'
    )
  );

-- Public bucket: anyone can select objects (needed for public URL access).
CREATE POLICY "price_evidence_select_public"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'price-evidence');

-- Only admins can delete evidence for moderation purposes.
CREATE POLICY "price_evidence_delete_admin_only"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'price-evidence'
    AND public.is_admin()
  );

COMMIT;
