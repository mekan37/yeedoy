-- Admin işletme düzenleme modalı: admin_update_business_v1'i genel bilgi
-- alanlarıyla genişletir, işletme detayını ve haftalık çalışma saatlerini
-- okuma/yazma için iki yeni admin RPC'si ekler.
-- Called by: uygulamalar/web/app/yonetici/isletmeler (isletme-duzenle-modal.tsx,
-- isletme-duzenle-islemleri.ts).

-- ─── 1) admin_update_business_v1 — 7 yeni OPSİYONEL parametre eklendi ─────────
-- Mevcut 10 parametre (isim/sıra/tip) değişmedi; yeni parametreler sona
-- DEFAULT NULL ile eklendi. Breaking change değil, _v2'ye gerek yok.
-- Not: Postgres'te fonksiyon kimliği tüm parametre listesini (DEFAULT'lu olsa
-- bile) kapsar, bu yüzden CREATE OR REPLACE eski 10 parametreli imzayı YERİNDE
-- değiştirmez, ayrı bir overload oluşturur. Eski imzayı önce DROP ediyoruz.
DROP FUNCTION IF EXISTS public.admin_update_business_v1(uuid, text, text, text, text, text, double precision, double precision, text, text);

CREATE OR REPLACE FUNCTION public.admin_update_business_v1(
  p_business_id uuid,
  p_name text,
  p_category text,
  p_address text,
  p_city text,
  p_district text,
  p_lat double precision,
  p_lng double precision,
  p_logo_url text,
  p_cover_url text,
  p_description text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_website_url text DEFAULT NULL,
  p_instagram_url text DEFAULT NULL,
  p_facebook_url text DEFAULT NULL,
  p_twitter_url text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.businesses
  set
    name = p_name,
    category = p_category,
    address = p_address,
    city = p_city,
    district = p_district,
    lat = p_lat,
    lng = p_lng,
    logo_url = p_logo_url,
    cover_url = p_cover_url,
    description = p_description,
    phone = p_phone,
    email = p_email,
    website_url = p_website_url,
    instagram_url = p_instagram_url,
    facebook_url = p_facebook_url,
    twitter_url = p_twitter_url
  where id = p_business_id;

  perform public.log_admin_action_v1(
    'business.update',
    'businesses',
    p_business_id,
    jsonb_build_object('name', p_name, 'city', p_city, 'district', p_district)
  );

  return jsonb_build_object('ok', true);
end;
$function$;

REVOKE ALL ON FUNCTION public.admin_update_business_v1(uuid, text, text, text, text, text, double precision, double precision, text, text, text, text, text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_business_v1(uuid, text, text, text, text, text, double precision, double precision, text, text, text, text, text, text, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_update_business_v1(uuid, text, text, text, text, text, double precision, double precision, text, text, text, text, text, text, text, text, text) FROM anon;

COMMENT ON FUNCTION public.admin_update_business_v1 IS
  'Admin: bir işletmenin genel bilgilerini (temel alanlar + açıklama/iletişim/sosyal linkler) günceller. Called by: app/yonetici/isletmeler.';


-- ─── 2) admin_get_business_detail_v1 — düzenleme modalını doldurmak için ──────

CREATE OR REPLACE FUNCTION public.admin_get_business_detail_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT to_jsonb(b) INTO v_result
  FROM public.businesses b
  WHERE b.id = p_business_id;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_business_detail_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_business_detail_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_get_business_detail_v1(uuid) FROM anon;

COMMENT ON FUNCTION public.admin_get_business_detail_v1 IS
  'Admin: bir işletmenin tüm sütunlarını döner (düzenleme modalı için). Called by: app/yonetici/isletmeler.';


-- ─── 3) admin_upsert_business_hours_v1 — admin'in haftalık saatleri yazması ───
-- Owner tarafındaki upsert_business_hours_v1 ile aynı tabloyu (business_weekly_hours)
-- kullanır, sadece sahiplik kontrolü yerine is_admin() uygular.

CREATE OR REPLACE FUNCTION public.admin_upsert_business_hours_v1(p_business_id uuid, p_hours jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  _row jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  FOR _row IN SELECT * FROM jsonb_array_elements(p_hours)
  LOOP
    INSERT INTO public.business_weekly_hours
      (business_id, day_of_week, open_time, close_time, is_closed, updated_at)
    VALUES (
      p_business_id,
      (_row->>'day_of_week')::smallint,
      (_row->>'open_time')::time,
      (_row->>'close_time')::time,
      (_row->>'is_closed')::bool,
      now()
    )
    ON CONFLICT (business_id, day_of_week) DO UPDATE SET
      open_time  = EXCLUDED.open_time,
      close_time = EXCLUDED.close_time,
      is_closed  = EXCLUDED.is_closed,
      updated_at = now();
  END LOOP;

  PERFORM public.log_admin_action_v1(
    'business.update_hours',
    'businesses',
    p_business_id,
    jsonb_build_object('hours_count', jsonb_array_length(p_hours))
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_business_hours_v1(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_business_hours_v1(uuid, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_business_hours_v1(uuid, jsonb) FROM anon;

COMMENT ON FUNCTION public.admin_upsert_business_hours_v1 IS
  'Admin: bir işletmenin haftalık çalışma saatlerini toplu upsert eder (business_weekly_hours). p_hours: [{day_of_week, open_time, close_time, is_closed}, ...]. Called by: app/yonetici/isletmeler.';
