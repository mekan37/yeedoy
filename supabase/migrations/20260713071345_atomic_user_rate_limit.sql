CREATE OR REPLACE FUNCTION public.consume_rate_limit_v1(
  p_action text,
  p_daily_limit integer DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_day date := (now() AT TIME ZONE 'utc')::date;
  v_action text := trim(p_action);
  v_key text;
  v_count integer;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  IF v_action IS NULL
    OR v_action = ''
    OR char_length(v_action) > 100
    OR v_action !~ '^[a-z0-9][a-z0-9_-]*$'
  THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_action');
  END IF;

  IF p_daily_limit IS NULL OR p_daily_limit < 1 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_daily_limit');
  END IF;

  v_key := v_action || ':' || v_user_id::text || ':' || v_day::text;

  INSERT INTO public.user_rate_limits AS rate_limit (
    key,
    user_id,
    action,
    day,
    count,
    updated_at
  )
  VALUES (
    v_key,
    v_user_id,
    v_action,
    v_day,
    1,
    now()
  )
  ON CONFLICT (key) DO UPDATE
    SET count = rate_limit.count + 1,
        updated_at = now()
    WHERE rate_limit.count < p_daily_limit
  RETURNING count INTO v_count;

  IF v_count IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'error', 'rate_limited',
      'remaining', 0
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'remaining', p_daily_limit - v_count
  );
END;
$function$;
