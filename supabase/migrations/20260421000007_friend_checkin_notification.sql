-- ─────────────────────────────────────────────────────────────────────────────
-- Friend check-in notification
-- When a user checks in to a business, notify all their followers.
-- Rate-limited: max 1 notification per (follower, checkin_user, business) per 24h
-- to avoid spam if the same person checks in multiple times.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.trg_notify_friend_checkin_v1()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_follower_id uuid;
  v_business_name text;
  v_checkin_user_name text;
BEGIN
  IF tg_op <> 'INSERT' THEN RETURN new; END IF;
  -- Only notify when a logged-in user checks in
  IF new.user_id IS NULL THEN RETURN new; END IF;

  SELECT b.name INTO v_business_name
  FROM public.businesses b WHERE b.id = new.business_id;

  SELECT coalesce(p.display_name, p.username, 'Bir arkadaşın')
  INTO v_checkin_user_name
  FROM public.profiles p WHERE p.id = new.user_id;

  FOR v_follower_id IN
    SELECT uf.follower_id
    FROM public.user_follows uf
    WHERE uf.followee_id = new.user_id
      AND uf.follower_id <> new.user_id
      -- Rate limit: skip if we already sent this (follower, checkin_user, business) within 24h
      AND NOT EXISTS (
        SELECT 1 FROM public.notifications n
        WHERE  n.user_id = uf.follower_id
          AND  n.type    = 'friend_checkin'
          AND  (n.data->>'business_id')::uuid = new.business_id
          AND  (n.data->>'checkin_user_id')   = new.user_id::text
          AND  n.created_at >= now() - interval '24 hours'
      )
  LOOP
    PERFORM public.notify_user_v1(
      v_follower_id,
      'friend_checkin',
      '📍 ' || v_checkin_user_name || ' bir yere gitti!',
      v_checkin_user_name || ', ' || coalesce(v_business_name, 'bir işletmeyi') || ' ziyaret etti.',
      jsonb_build_object(
        'business_id',    new.business_id,
        'checkin_user_id', new.user_id
      )
    );
  END LOOP;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_friend_checkin_v1 ON public.business_checkins;
CREATE TRIGGER trg_notify_friend_checkin_v1
  AFTER INSERT ON public.business_checkins
  FOR EACH ROW EXECUTE FUNCTION public.trg_notify_friend_checkin_v1();
