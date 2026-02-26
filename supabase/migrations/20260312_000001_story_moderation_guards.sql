-- Server-side moderation guards for business stories.
-- Adds duplicate and spam checks without changing client-facing contracts.

CREATE OR REPLACE FUNCTION public.create_business_story_v1(
  p_business_id uuid,
  p_type text,
  p_caption text,
  p_media_url text,
  p_media_thumb_url text DEFAULT NULL,
  p_duration_sec integer DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today date := (now() at time zone 'utc')::date;
  v_count int;
  v_caption text := nullif(lower(trim(coalesce(p_caption, ''))), '');
  v_media_url text := nullif(trim(coalesce(p_media_url, '')), '');
  v_media_thumb_url text := nullif(trim(coalesce(p_media_thumb_url, '')), '');
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  IF NOT (public.is_admin() OR public.is_owner_of_business(p_business_id)) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_owner');
  END IF;

  IF p_type NOT IN ('menu', 'crowd', 'promo', 'update') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'bad_type');
  END IF;

  IF v_media_url IS NULL OR length(v_media_url) < 10 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'media_required');
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.business_stories
  WHERE business_id = p_business_id
    AND created_by = auth.uid()
    AND created_at >= (v_today::timestamptz)
    AND is_deleted = false;

  IF v_count >= 5 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'rate_limited_daily');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.is_deleted = false
      AND s.created_at >= now() - interval '30 days'
      AND (
        s.media_url = v_media_url
        OR (v_media_thumb_url IS NOT NULL AND s.media_thumb_url = v_media_thumb_url)
      )
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'duplicate_media');
  END IF;

  IF v_caption IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.created_by = auth.uid()
      AND s.is_deleted = false
      AND s.type = p_type::public.story_type
      AND lower(trim(coalesce(s.caption, ''))) = v_caption
      AND s.created_at >= now() - interval '24 hours'
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'spam_suspected');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.created_by = auth.uid()
      AND s.is_deleted = false
      AND s.type = p_type::public.story_type
      AND s.created_at >= now() - interval '2 minutes'
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'spam_suspected');
  END IF;

  INSERT INTO public.business_stories(
    business_id,
    type,
    caption,
    media_url,
    media_thumb_url,
    media_type,
    duration_sec,
    created_by
  )
  VALUES (
    p_business_id,
    p_type::public.story_type,
    p_caption,
    v_media_url,
    v_media_thumb_url,
    CASE WHEN p_duration_sec IS NULL THEN 'image' ELSE 'video' END,
    p_duration_sec,
    auth.uid()
  );

  RETURN jsonb_build_object('ok', true);
END;
$$;
