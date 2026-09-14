-- Sahip Paneli Güvenlik Denetimi P2 performans: analitik/page.tsx, 100.000
-- satıra kadar ham analytics_events çekip Node.js'te 4 ayrı agregasyon
-- (günlük görüntülenme, trafik kaynağı, ısı haritası, günlük/saatlik
-- dağılım) yapıyordu — limit aşımında sessiz veri kaybı riski + gereksiz
-- veri transferi. Tek bir RPC'ye taşındı; ham satır sayısı ne olursa
-- olsun yalnızca ÖNCEDEN AGREGELENMIŞ sonuçlar (en fazla birkaç yüz
-- satır) transfer ediliyor. Sayfadaki mevcut saf JS yardımcı
-- fonksiyonları (buildHourBucketHeatmap, findBestDay, vb.) korunuyor —
-- yalnızca girdileri "ham event satırları" yerine "önceden agregelenmiş
-- sayaçlar" oluyor, davranış eşdeğerliği daha kolay doğrulanabiliyor.
--
-- Dizideki HER business_id için çağıranın has_business_permission_v1
-- ('analytics_view') sahibi olması zorunlu (bu RPC'nin ilk taslağında bu
-- kontrol eksikti, hemen düzeltildi — bu turda defalarca bulunan
-- "business_id parametresi alıp sahiplik doğrulamayan RPC" hatasını
-- burada da tekrarlamamak için).
create or replace function public.owner_analytics_pipeline_v1(
  p_business_ids uuid[],
  p_since_prev timestamptz,
  p_since timestamptz,
  p_view_events text[]
)
returns jsonb
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_unauthorized_count int;
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = 'P0002';
  end if;

  if p_business_ids is null or array_length(p_business_ids, 1) is null then
    return jsonb_build_object(
      'daily_views_current', '[]'::jsonb, 'daily_views_previous', '[]'::jsonb,
      'source_breakdown', '[]'::jsonb, 'heatmap_counts', '[]'::jsonb,
      'daily_local_trend', '[]'::jsonb, 'hourly_distribution', '[]'::jsonb,
      'has_current_events', false
    );
  end if;

  select count(*) into v_unauthorized_count
  from unnest(p_business_ids) bid
  where not (is_admin() or has_business_permission_v1(bid, 'analytics_view'));

  if v_unauthorized_count > 0 then
    raise exception 'unauthorized' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'daily_views_current', (
      select coalesce(jsonb_agg(jsonb_build_object('day', d, 'count', c)), '[]'::jsonb)
      from (
        select (date_trunc('day', created_at) at time zone 'UTC')::date as d, count(*) as c
        from analytics_events
        where business_id = any(p_business_ids)
          and event_name = any(p_view_events)
          and created_at >= p_since
        group by 1
      ) t
    ),
    'daily_views_previous', (
      select coalesce(jsonb_agg(jsonb_build_object('day', d, 'count', c)), '[]'::jsonb)
      from (
        select (date_trunc('day', created_at) at time zone 'UTC')::date as d, count(*) as c
        from analytics_events
        where business_id = any(p_business_ids)
          and event_name = any(p_view_events)
          and created_at >= p_since_prev and created_at < p_since
        group by 1
      ) t
    ),
    'source_breakdown', (
      select coalesce(jsonb_agg(jsonb_build_object('source', source, 'count', c)), '[]'::jsonb)
      from (
        select source, count(*) as c
        from analytics_events
        where business_id = any(p_business_ids)
          and created_at >= p_since
        group by 1
      ) t
    ),
    'heatmap_counts', (
      select coalesce(jsonb_agg(jsonb_build_object('hour', h, 'weekday', wd, 'count', c)), '[]'::jsonb)
      from (
        select
          extract(hour from (created_at at time zone 'Europe/Istanbul'))::int as h,
          extract(dow from (created_at at time zone 'Europe/Istanbul'))::int as wd,
          count(*) as c
        from analytics_events
        where business_id = any(p_business_ids)
          and event_name = any(p_view_events)
          and created_at >= p_since
        group by 1, 2
      ) t
    ),
    'daily_local_trend', (
      select coalesce(jsonb_agg(jsonb_build_object('day', d, 'menu_views', menu_views, 'qr_scans', qr_scans)), '[]'::jsonb)
      from (
        select
          (date_trunc('day', created_at) at time zone 'UTC')::date as d,
          count(*) filter (where event_name = 'menu_view') as menu_views,
          count(*) filter (where event_name = 'qr_scanned') as qr_scans
        from analytics_events
        where business_id = any(p_business_ids)
          and created_at >= p_since
          and event_name in ('menu_view', 'qr_scanned')
        group by 1
      ) t
    ),
    'hourly_distribution', (
      select coalesce(jsonb_agg(jsonb_build_object('hour', h, 'count', c)), '[]'::jsonb)
      from (
        select extract(hour from (created_at at time zone 'UTC'))::int as h, count(*) as c
        from analytics_events
        where business_id = any(p_business_ids)
          and created_at >= p_since
        group by 1
      ) t
    ),
    'has_current_events', exists(
      select 1 from analytics_events
      where business_id = any(p_business_ids) and created_at >= p_since
    )
  );
end;
$function$;

revoke all on function public.owner_analytics_pipeline_v1(uuid[], timestamptz, timestamptz, text[]) from public;
grant execute on function public.owner_analytics_pipeline_v1(uuid[], timestamptz, timestamptz, text[]) to authenticated;
revoke execute on function public.owner_analytics_pipeline_v1(uuid[], timestamptz, timestamptz, text[]) from anon;
