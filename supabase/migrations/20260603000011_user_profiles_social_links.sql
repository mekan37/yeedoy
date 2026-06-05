-- Add social_links JSONB column to user_profiles.
-- Stores user-provided social profile URLs as a JSON object,
-- e.g. {"instagram": "https://instagram.com/...", "website": "https://..."}
-- Keys used by the mobile app: instagram, website, x, tiktok, youtube.
--
-- RLS: existing profiles_update_own policy (user_id = auth.uid()) covers writes.
-- No new policy required.
--
-- Rollback: ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS social_links;
-- WARNING: rollback after data is written causes data loss.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS social_links JSONB NULL
    CONSTRAINT user_profiles_social_links_is_object
      CHECK (social_links IS NULL OR jsonb_typeof(social_links) = 'object');

COMMENT ON COLUMN public.user_profiles.social_links IS
  'User social profile links. JSON object with optional keys: instagram, website, x, tiktok, youtube. Written by the mobile profile editor.';
