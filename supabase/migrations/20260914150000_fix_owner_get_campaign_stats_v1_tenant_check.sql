-- Sahip Paneli Güvenlik Denetimi P2: owner_get_campaign_stats_v1 yalnızca
-- auth.uid() IS NULL kontrolü yapıyordu, business_id üzerinde hiçbir
-- sahiplik/yetki kontrolü yoktu — herhangi bir kimliği doğrulanmış
-- kullanıcı herhangi bir işletmenin (rakibinin) kampanya istatistiklerini
-- okuyabiliyordu.
create or replace function public.owner_get_campaign_stats_v1(p_business_id uuid, p_period_days integer default 7)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(p_business_id, 'analytics_view')) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT jsonb_build_object(
    'total_campaigns',  count(*),
    'active_campaigns', count(*) FILTER (WHERE status = 'active'),
    'total_views',      coalesce(sum(view_count), 0),
    'total_clicks',     coalesce(sum(click_count), 0),
    'period_views',     coalesce(sum(view_count)  FILTER (WHERE updated_at >= now() - make_interval(days => p_period_days)), 0),
    'period_clicks',    coalesce(sum(click_count) FILTER (WHERE updated_at >= now() - make_interval(days => p_period_days)), 0)
  ) INTO v_result
  FROM public.campaigns
  WHERE business_id = p_business_id;

  RETURN coalesce(v_result, '{}'::jsonb);
END;
$function$;
