-- Dedicated table for review photos. menu_item_photos was not reusable here since
-- its menu_item_id column is NOT NULL (photos are always tied to a dish, not a review).
CREATE TABLE public.review_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id uuid NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  url text NOT NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX review_photos_review_id_idx ON public.review_photos(review_id);
CREATE INDEX review_photos_business_id_idx ON public.review_photos(business_id);

ALTER TABLE public.review_photos ENABLE ROW LEVEL SECURITY;

-- Mirrors reviews_select_access: a photo is visible whenever its parent review is.
CREATE POLICY review_photos_select_access ON public.review_photos
  FOR SELECT TO public
  USING (
    EXISTS (
      SELECT 1 FROM public.reviews r
      WHERE r.id = review_photos.review_id
        AND (r.status = 'approved' OR r.user_id = auth.uid() OR is_admin())
    )
  );

-- Only the review's own author can attach a photo to it (mirrors reviews_insert/update_own).
CREATE POLICY review_photos_insert_own ON public.review_photos
  FOR INSERT TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (SELECT 1 FROM public.reviews r WHERE r.id = review_id AND r.user_id = auth.uid())
  );

CREATE POLICY review_photos_delete_own ON public.review_photos
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

CREATE POLICY review_photos_delete_admin ON public.review_photos
  FOR DELETE TO authenticated
  USING (is_admin());

REVOKE ALL ON public.review_photos FROM PUBLIC;
GRANT SELECT ON public.review_photos TO anon, authenticated;
GRANT INSERT, DELETE ON public.review_photos TO authenticated;

COMMENT ON TABLE public.review_photos IS 'Photos attached to a business_reviews/reviews row by its author. Called by: isletme-detay-tablari.tsx, /sunucu/yorumlar/fotograf-yukle.';
