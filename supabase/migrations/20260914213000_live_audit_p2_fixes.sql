-- Canlı Supabase Güvenlik & Bütünlük Denetimi P2 grubu (kapsamlı/riskli 3
-- kalem — #1 150+ tablo sıfır savunma derinliği, #6 temp bucket public→
-- private (çoklu call-site signed-URL geçişi gerektiriyor), #9 is_owner()
-- vs get_business_role_v1() (RBAC mimari kararının parçası) — bilinçli
-- ertelendi, ayrı bir turda ele alınmalı).

-- ── #2) user_profiles: shadow_banned/referral_code kullanıcı kendi UPDATE
-- politikasıyla (kolon kısıtı yok) değiştirebiliyordu — self-unban +
-- referans kodu ele geçirme. SELECT zaten önceki turda kolon bazlı
-- kilitlenmişti (lock_down_user_profiles_sensitive_columns); UPDATE için
-- aynısı eksikti.
revoke update (shadow_banned, referral_code) on public.user_profiles from anon, authenticated;

-- ── #3) get_business_checkin_user_ids_v1: anon-çağrılabilir, yetki kontrolü
-- yok — konum/davranış PII sızıntısı.
create or replace function public.get_business_checkin_user_ids_v1(p_business_id uuid)
returns uuid[]
language plpgsql
stable security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'analytics_view')) then
    raise exception 'forbidden' using errcode = 'P0002';
  end if;

  return (
    select case when count(distinct user_id) >= 5
      then coalesce(array_agg(distinct user_id), array[]::uuid[])
      else array[]::uuid[]
    end
    from public.business_checkins
    where business_id = p_business_id and user_id is not null
  );
end;
$function$;
revoke execute on function public.get_business_checkin_user_ids_v1(uuid) from anon, public;

-- ── #7) import_osm_boundaries_batch_v1: anon-çağrılabilir toplu yazma —
-- coğrafi referans verisi kirletme + DoS. tools/osm-geojson-sinir-ice-aktar.mjs
-- SUPABASE_SERVICE_ROLE_KEY ile çağırıyor — service_role da izinli olmalı.
create or replace function public.import_osm_boundaries_batch_v1(p_rows jsonb)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_row     JSONB;
  v_count   INT := 0;
  v_geog    public.geography;
  v_centroid public.geography;
BEGIN
  IF NOT (public.is_admin() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = 'P0002';
  END IF;

  FOR v_row IN SELECT jsonb_array_elements(p_rows)
  LOOP
    IF v_row->>'geojson' IS NOT NULL AND v_row->>'geojson' <> 'null' THEN
      BEGIN
        v_geog := ST_GeogFromGeoJSON(v_row->>'geojson');
        v_centroid := ST_Centroid(v_geog::geometry)::public.geography;
      EXCEPTION WHEN OTHERS THEN
        v_geog := NULL;
        v_centroid := NULL;
      END;
    ELSE
      v_geog := NULL;
      v_centroid := NULL;
    END IF;

    INSERT INTO public.osm_admin_boundaries (
      osm_id, admin_level, name, name_en, boundary, centroid, properties
    ) VALUES (
      (v_row->>'osm_id')::BIGINT,
      (v_row->>'admin_level')::SMALLINT,
      v_row->>'name',
      NULLIF(v_row->>'name_en', ''),
      v_geog,
      v_centroid,
      COALESCE(v_row->'properties', '{}')
    )
    ON CONFLICT (osm_id) DO UPDATE SET
      name       = EXCLUDED.name,
      name_en    = EXCLUDED.name_en,
      boundary   = COALESCE(EXCLUDED.boundary, osm_admin_boundaries.boundary),
      centroid   = COALESCE(EXCLUDED.centroid, osm_admin_boundaries.centroid),
      properties = osm_admin_boundaries.properties || EXCLUDED.properties;

    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$function$;
revoke execute on function public.import_osm_boundaries_batch_v1(jsonb) from anon, authenticated, public;

-- ── #10) review_replies_owner_update: WITH CHECK yoktu — sahip kendi yanıt
-- satırını rakip işletmenin yorumuna taşıyabiliyordu (kimlik sahteciliği).
alter policy review_replies_owner_update on public.review_replies
  using ((select auth.uid()) = owner_user_id)
  with check (
    (select auth.uid()) = owner_user_id
    and exists (
      select 1 from public.reviews r
      where r.id = review_replies.review_id
        and r.business_id = review_replies.business_id
    )
  );

-- ── #11) get_dashboard_stats_today_v1 / get_business_daily_stats_v1 /
-- get_staff_performance_today_v1: yalnızca varlık kontrolü var, yetki
-- kontrolü yok — cross-tenant ciro/personel istatistiği sızıntısı.
create or replace function public.get_dashboard_stats_today_v1(p_business_id uuid)
returns json
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_today_start timestamptz := date_trunc('day', NOW() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul';
  v_result json;
BEGIN
  IF NOT (public.is_admin() OR public.has_business_permission_v1(p_business_id, 'analytics_view')) THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = 'P0002';
  END IF;

  SELECT json_build_object(
    'bugun_bekleyen',       (
      SELECT COUNT(*) FROM table_orders
      WHERE business_id = p_business_id AND status = 'pending' AND created_at >= v_today_start
    ),
    'bugun_hazirlaniyor',   (
      SELECT COUNT(*) FROM table_orders
      WHERE business_id = p_business_id AND status = 'seen' AND created_at >= v_today_start
    ),
    'bugun_tamamlanan',     (
      SELECT COUNT(*) FROM table_orders
      WHERE business_id = p_business_id AND status = 'done' AND created_at >= v_today_start
    ),
    'toplam_bugun',         (
      SELECT COUNT(*) FROM table_orders
      WHERE business_id = p_business_id AND created_at >= v_today_start
    ),
    'personel_performans',  (
      SELECT COALESCE(json_agg(
        json_build_object(
          'staff_id',    perf.processed_by,
          'siparis_sayisi', perf.siparis_sayisi,
          'tamamlanan',     perf.tamamlanan
        )
        ORDER BY perf.siparis_sayisi DESC
      ), '[]'::json)
      FROM (
        SELECT o.processed_by, COUNT(*) AS siparis_sayisi, COUNT(*) FILTER (WHERE o.status = 'done') AS tamamlanan
        FROM table_orders o
        WHERE o.business_id = p_business_id AND o.updated_at >= v_today_start AND o.processed_by IS NOT NULL
        GROUP BY o.processed_by
        LIMIT 10
      ) perf
    )
  ) INTO v_result;

  RETURN v_result;
END;
$function$;
revoke execute on function public.get_dashboard_stats_today_v1(uuid) from anon, public;

create or replace function public.get_business_daily_stats_v1(p_business_id uuid, p_date date default current_date)
returns jsonb
language plpgsql
stable security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'analytics_view')) then
    raise exception 'forbidden' using errcode = 'P0002';
  end if;

  return (
    SELECT jsonb_build_object(
      'total_orders',    COUNT(*),
      'pending',         COUNT(*) FILTER (WHERE status = 'pending'),
      'seen',            COUNT(*) FILTER (WHERE status = 'seen'),
      'done',            COUNT(*) FILTER (WHERE status = 'done'),
      'active_items',    (SELECT COUNT(*) FROM menu_items WHERE business_id = p_business_id AND is_available = true),
      'inactive_items',  (SELECT COUNT(*) FROM menu_items WHERE business_id = p_business_id AND is_available = false)
    )
    FROM table_orders
    WHERE business_id = p_business_id AND created_at::date = p_date
  );
end;
$function$;
revoke execute on function public.get_business_daily_stats_v1(uuid, date) from anon, public;

create or replace function public.get_staff_performance_today_v1(p_business_id uuid)
returns table(staff_id uuid, siparis_sayisi bigint, tamamlanan bigint)
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_today TIMESTAMPTZ := date_trunc('day', NOW() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul';
BEGIN
  IF NOT (public.is_admin() OR public.has_business_permission_v1(p_business_id, 'analytics_view')) THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT o.processed_by AS staff_id, COUNT(*) AS siparis_sayisi, COUNT(*) FILTER (WHERE o.status = 'done') AS tamamlanan
  FROM public.table_orders o
  WHERE o.business_id = p_business_id AND o.updated_at >= v_today AND o.processed_by IS NOT NULL
  GROUP BY o.processed_by
  ORDER BY siparis_sayisi DESC;
END;
$function$;
revoke execute on function public.get_staff_performance_today_v1(uuid) from anon, public;

-- ── #12) log_menu_activity_v1: anon yazabiliyor; business_activity_read_all
-- (USING true) herkes okuyabiliyor — audit-trail bütünlüğü + tüm
-- işletmelerin aktivite geçmişi sızıntısı.
create or replace function public.log_menu_activity_v1(p_business_id uuid, p_event text, p_meta jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'menu_write')) then
    raise exception 'forbidden' using errcode = 'P0002';
  end if;

  insert into public.business_activity_log (business_id, type, meta)
  values (p_business_id, 'menu_update', jsonb_build_object('event', p_event) || coalesce(p_meta, '{}'::jsonb));
end;
$function$;
revoke execute on function public.log_menu_activity_v1(uuid, text, jsonb) from anon, public;

drop policy if exists business_activity_read_all on public.business_activity_log;
create policy business_activity_read_business on public.business_activity_log
  for select
  to authenticated
  using (public.is_admin() or public.has_business_permission_v1(business_id, 'business_read'));

-- ── #13) submit_table_feedback_v1: rate-limit anahtarı yalnızca istemciden
-- gelen p_client_id'ye dayanıyordu (sınırsız rotasyonla aşılabilir) — aynı
-- (business,table) çiftine kaba bir üst sınır eklendi.
create or replace function public.submit_table_feedback_v1(p_business_id uuid, p_table_no text, p_rating integer, p_note text default null::text, p_client_id text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_rating int := coalesce(p_rating, 0);
  v_table text := nullif(trim(p_table_no), '');
  v_client text := nullif(trim(p_client_id), '');
  v_key text;
  v_today date := current_date;
  v_current_count int;
  v_table_count int;
  v_user_id uuid := coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if p_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_business');
  end if;

  if v_table is null then
    return jsonb_build_object('ok', false, 'code', 'table_required');
  end if;

  if v_rating < 1 or v_rating > 5 then
    return jsonb_build_object('ok', false, 'code', 'invalid_rating');
  end if;

  if v_client is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  select count(*) into v_table_count
  from public.table_feedback
  where business_id = p_business_id and table_no = v_table and created_at::date = v_today;

  if v_table_count >= 30 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  v_key := format('table_feedback:%s:%s', v_client, v_today::text);
  select count into v_current_count
  from public.user_rate_limits
  where key = v_key;

  if coalesce(v_current_count, 0) >= 10 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
  values (v_key, v_user_id, 'table_feedback', v_today, 1, now())
  on conflict (key) do update
    set count = public.user_rate_limits.count + 1,
        updated_at = now();

  insert into public.table_feedback (business_id, table_no, rating, note, created_at, client_id)
  values (p_business_id, v_table, v_rating, nullif(trim(p_note), ''), now(), v_client);

  return jsonb_build_object('ok', true);
end;
$function$;

-- ── #14) menu_feedback: doğrudan anon INSERT grant'li, gerçek rate-limit
-- yoktu ("API katmanında rate-limit'li" yorumu yanıltıcıydı) — BEFORE
-- INSERT trigger ile check_rate_limit_v1 kullanılarak gerçek bir limit
-- eklendi (internal-only fonksiyon çağrısı — trigger postgres olarak
-- çalıştığı için check_rate_limit_v1'in #17'de anon/authenticated'dan
-- revoke edilmesinden etkilenmez).
create or replace function public.enforce_menu_feedback_rate_limit_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_key text := 'menu_feedback:' || coalesce(auth.uid()::text, 'anon:' || new.business_id::text);
  v_ok boolean;
begin
  v_ok := public.check_rate_limit_v1(v_key, 10, interval '1 hour');
  if not v_ok then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_menu_feedback_rate_limit on public.menu_feedback;
create trigger trg_menu_feedback_rate_limit
  before insert on public.menu_feedback
  for each row
  execute function public.enforce_menu_feedback_rate_limit_v1();

-- ── #15) is_user_shadowed_v1: anon-çağrılabilir moderasyon-durumu oracle'ı.
revoke execute on function public.is_user_shadowed_v1(uuid) from anon, authenticated, public;

-- ── #16) record_user_device_fingerprint_v1: anon, başkası adına fingerprint
-- yazabiliyordu — anti-fraud veri kirlenmesi + cihaz-korelasyon oracle'ı.
create or replace function public.record_user_device_fingerprint_v1(p_user_id uuid, p_fingerprint text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_fingerprint text := trim(coalesce(p_fingerprint, ''));
  v_exists boolean := false;
  v_device_count integer := 0;
begin
  if p_user_id is null or auth.uid() is distinct from p_user_id then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if v_fingerprint = '' then
    return jsonb_build_object('ok', false, 'error', 'missing_fingerprint');
  end if;

  select exists(
    select 1 from public.user_device_fingerprints d
    where d.user_id = p_user_id and d.fingerprint = v_fingerprint
  ) into v_exists;

  if v_exists then
    update public.user_device_fingerprints
      set last_seen_at = now(), seen_count = seen_count + 1
    where user_id = p_user_id and fingerprint = v_fingerprint;
  else
    insert into public.user_device_fingerprints(user_id, fingerprint)
    values (p_user_id, v_fingerprint);
  end if;

  select count(*) into v_device_count
  from public.user_device_fingerprints d
  where d.user_id = p_user_id and d.last_seen_at >= now() - interval '30 days';

  if not v_exists and v_device_count > 1 then
    perform public.record_user_risk_signal_v1(p_user_id, 'device_change', 12, null, jsonb_build_object('device_count', v_device_count));
  end if;

  return jsonb_build_object('ok', true, 'is_new_device', not v_exists, 'device_count', v_device_count);
end;
$function$;
revoke execute on function public.record_user_device_fingerprint_v1(uuid, text) from anon, public;

-- ── #17) check_rate_limit_v1: keyfi anahtarla anon-çağrılabilir — hedefli
-- kotasını tüketme DoS'u. İç kullanım (trigger'lar postgres olarak
-- çalıştığı için) etkilenmez.
revoke execute on function public.check_rate_limit_v1(text, integer, interval) from anon, authenticated, public;

-- ── #18) submit_menu_item_suggestion_v1: business_id↔menu_item_id tutarlılığı
-- yoktu — cross-tenant öneri enjeksiyonu.
create or replace function public.submit_menu_item_suggestion_v1(p_business_id uuid, p_menu_item_id uuid, p_action text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if not exists (
    select 1 from public.menu_items mi where mi.id = p_menu_item_id and mi.business_id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'error', 'business_mismatch');
  end if;

  insert into public.menu_item_suggestions(business_id, menu_item_id, action, payload, created_by)
  values (p_business_id, p_menu_item_id, p_action, p_payload, auth.uid());

  return jsonb_build_object('ok', true);
end;
$function$;

-- ── #19) notify_favorite_revisit_reminders_v1: anon-çağrılabilir, batch
-- sınırsız — toplu istenmeyen push + sağlayıcı kota tüketimi. pg_cron
-- (favorite_revisit_reminder_daily) bu fonksiyonu doğrudan `postgres` olarak
-- çağırıyor (PostgREST/auth context yok) — is_admin()/auth.role() kontrolü
-- eklemek cron'u kırardı; tek güvenli/yeterli kapatma REVOKE (pg_cron
-- grant'lerden etkilenmez).
create or replace function public.notify_favorite_revisit_reminders_v1(p_batch_size integer default 200)
returns integer
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare
  v_count  integer := 0;
  v_rec    record;
  v_bname  text;
  v_batch  integer := least(greatest(coalesce(p_batch_size, 200), 1), 500);
begin
  for v_rec in
    select f.user_id, f.business_id, b.name as business_name
    from   public.favorites f
    join   public.businesses b on b.id = f.business_id
    where  f.created_at between now() - interval '22 days' and now() - interval '20 days'
      and not exists (
        select 1 from public.business_checkins c
        where  c.user_id     = f.user_id
          and  c.business_id = f.business_id
          and  c.created_at  >= now() - interval '21 days'
      )
      and not exists (
        select 1 from public.favorite_revisit_reminders_sent s
        where  s.user_id     = f.user_id
          and  s.business_id = f.business_id
      )
    limit v_batch
  loop
    v_bname := coalesce(v_rec.business_name, 'İşletme');

    perform public.notify_user_v1(
      v_rec.user_id,
      'favorite_revisit_reminder',
      'Hâlâ gitmek ister misin?',
      v_bname || ' favorilerinizde. Ziyaret etmek ister misiniz?',
      jsonb_build_object('business_id', v_rec.business_id)
    );

    insert into public.favorite_revisit_reminders_sent (user_id, business_id)
    values (v_rec.user_id, v_rec.business_id)
    on conflict (user_id, business_id) do nothing;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$function$;
revoke execute on function public.notify_favorite_revisit_reminders_v1(integer) from anon, authenticated, public;

-- ── #20) businesses.owner_id kolonu hiç yok — bu 4 fonksiyon her çağrıda
-- 500 veriyordu (fail-closed ama işlevsiz). Kod tabanında hiçbir çağrı
-- noktası yok (submit/delete_owner_review_reply_v1 yerine owner_reply_review_v1
-- kullanılıyor; send_business_campaign_v1/set_menu_item_nutrition_v1 hiç
-- referans edilmiyor) — ölü kod, business logic yeniden yazılmadı,
-- yalnızca anon-çağrılabilir artık kalıntı yüzeyi kapatıldı.
revoke execute on function public.delete_owner_review_reply_v1(uuid) from anon, authenticated, public;
revoke execute on function public.submit_owner_review_reply_v1(uuid, text) from anon, authenticated, public;
revoke execute on function public.send_business_campaign_v1(uuid, text, text) from anon, authenticated, public;
revoke execute on function public.set_menu_item_nutrition_v1(uuid, integer, integer, integer, text) from anon, authenticated, public;
