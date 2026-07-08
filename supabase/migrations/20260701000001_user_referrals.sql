-- Add referral_code to user_profiles (unique, derived from user_id on insert)
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS referral_code text UNIQUE;

-- Back-fill: assign referral codes to existing profiles
UPDATE public.user_profiles
SET referral_code = upper(substring(user_id::text, 1, 6))
WHERE referral_code IS NULL;

-- Auto-generate referral_code for new profiles
CREATE OR REPLACE FUNCTION public.tg_user_profiles_set_referral_code()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.referral_code IS NULL THEN
    NEW.referral_code := upper(substring(NEW.user_id::text, 1, 6));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_profiles_set_referral_code ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_set_referral_code
  BEFORE INSERT ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_user_profiles_set_referral_code();

-- Referral tracking table
CREATE TABLE IF NOT EXISTS public.user_referrals (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (inviter_id, invitee_id)
);

CREATE INDEX IF NOT EXISTS user_referrals_inviter_idx ON public.user_referrals (inviter_id);

ALTER TABLE public.user_referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_referrals_read_own ON public.user_referrals
  FOR SELECT USING (auth.uid() = inviter_id);

-- RPC: get referral code + invited count for current user
CREATE OR REPLACE FUNCTION public.get_my_referral_stats_v1()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code text;
  v_count int := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT referral_code
    INTO v_code
  FROM public.user_profiles
  WHERE user_id = auth.uid();

  -- Ensure code exists (profile might not have been created yet)
  IF v_code IS NULL THEN
    v_code := upper(substring(auth.uid()::text, 1, 6));
  END IF;

  SELECT count(*)::int
    INTO v_count
  FROM public.user_referrals
  WHERE inviter_id = auth.uid();

  RETURN jsonb_build_object(
    'referral_code', v_code,
    'invited_count', v_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_referral_stats_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_referral_stats_v1() TO authenticated;
COMMENT ON FUNCTION public.get_my_referral_stats_v1 IS 'Returns referral_code and invited_count for the authenticated user. Called by: invite_sheet.dart';
