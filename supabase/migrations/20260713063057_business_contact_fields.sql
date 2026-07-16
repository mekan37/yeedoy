ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS email         TEXT,
  ADD COLUMN IF NOT EXISTS website_url   TEXT,
  ADD COLUMN IF NOT EXISTS instagram_url TEXT,
  ADD COLUMN IF NOT EXISTS facebook_url  TEXT,
  ADD COLUMN IF NOT EXISTS twitter_url   TEXT;

COMMENT ON COLUMN public.businesses.email         IS 'İşletme iletişim e-postası';
COMMENT ON COLUMN public.businesses.website_url   IS 'İşletme web sitesi URL';
COMMENT ON COLUMN public.businesses.instagram_url IS 'Instagram profil URL';
COMMENT ON COLUMN public.businesses.facebook_url  IS 'Facebook profil URL';
COMMENT ON COLUMN public.businesses.twitter_url   IS 'Twitter/X profil URL';
