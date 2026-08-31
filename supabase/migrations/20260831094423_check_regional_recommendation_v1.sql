-- ensure_my_profile_v1'e p_city eklendi — DEFAULT'lu yeni parametre, breaking change değil.
CREATE OR REPLACE FUNCTION public.ensure_my_profile_v1(
  p_display_name text DEFAULT NULL,
  p_avatar_url text DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  v_name := nullif(trim(coalesce(p_display_name,'')), '');
  IF v_name IS NULL THEN
    v_name := 'Kullanıcı';
  END IF;

  INSERT INTO public.user_profiles(user_id, display_name, avatar_url, city)
  VALUES (auth.uid(), v_name, p_avatar_url, nullif(trim(coalesce(p_city, '')), ''))
  ON CONFLICT (user_id) DO UPDATE
    SET display_name = COALESCE(excluded.display_name, public.user_profiles.display_name),
        avatar_url = COALESCE(excluded.avatar_url, public.user_profiles.avatar_url),
        city = COALESCE(nullif(trim(coalesce(p_city, '')), ''), public.user_profiles.city),
        updated_at = now();

  RETURN jsonb_build_object('ok', true);
END;
$$;
-- Mevcut GRANT/REVOKE zaten yerinde (CREATE OR REPLACE imzayı korur, yeniden vermeye gerek yok).

-- ── Çekirdek RPC: konum uyuşmazlığını tespit eder, tekilleştirir, bildirim satırı düşer ──
-- Şehir karşılaştırması public.normalize_tr_location_text() üzerinden yapılır (Task 1 code
-- review'ında bulundu) — bu proje Türkçe İ/ı/ş/ğ/ü/ö/ç harfleri için ham metin karşılaştırmasının
-- en az 3 kez production bug'ına yol açtığı bir geçmişe sahip (bkz. 20260609000004_fix_normalize_tr_location_combining_dot.sql).
-- businesses.city_norm zaten bu fonksiyonla önceden hesaplanmış ve index'li (businesses_city_district_norm_idx)
-- — b.city yerine b.city_norm üzerinden karşılaştırma hem doğruluk hem performans için doğru.
CREATE OR REPLACE FUNCTION public.check_regional_recommendation_v1(p_current_city text)
RETURNS TABLE (
  business_id uuid,
  business_name text,
  business_slug text,
  logo_url text,
  tag_label text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_home_city text;
  v_current_city_raw text := nullif(trim(coalesce(p_current_city, '')), '');
  v_current_city_norm text;
  v_already_sent boolean;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF v_current_city_raw IS NULL THEN
    RETURN;
  END IF;
  v_current_city_norm := public.normalize_tr_location_text(v_current_city_raw);

  SELECT up.city INTO v_home_city FROM public.user_profiles up WHERE up.user_id = v_user_id;

  -- Ev şehri boşsa veya zaten o şehirdeyse — öneri yok.
  IF v_home_city IS NULL OR public.normalize_tr_location_text(v_home_city) = v_current_city_norm THEN
    RETURN;
  END IF;

  -- O şehirde etiketli işletme yoksa — öneri yok.
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.city_norm = v_current_city_norm AND b.regional_tag_id IS NOT NULL AND b.is_active = true
  ) THEN
    RETURN;
  END IF;

  -- Push tekilleştirme: son 14 günde bu user+city için event var mı? (normalize edilmiş şehir üzerinden)
  SELECT EXISTS (
    SELECT 1 FROM public.regional_recommendation_events e
    WHERE e.user_id = v_user_id AND e.city = v_current_city_norm AND e.sent_at > now() - interval '14 days'
  ) INTO v_already_sent;

  IF NOT v_already_sent THEN
    INSERT INTO public.regional_recommendation_events (user_id, city) VALUES (v_user_id, v_current_city_norm);
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      v_user_id,
      'regional_recommendation',
      v_current_city_raw || '''desin! İşte yöresel lezzetler',
      v_current_city_raw || '''nin yöresel mutfağını keşfetmeye ne dersin?',
      jsonb_build_object('city', v_current_city_raw)
    );
  END IF;

  RETURN QUERY
    SELECT b.id, b.name, b.slug, b.logo_url, t.label
    FROM public.businesses b
    JOIN public.regional_cuisine_tags t ON t.id = b.regional_tag_id
    WHERE b.city_norm = v_current_city_norm AND b.is_active = true
    ORDER BY b.name
    LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.check_regional_recommendation_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_regional_recommendation_v1(text) TO authenticated;
COMMENT ON FUNCTION public.check_regional_recommendation_v1 IS
  'Kullanıcının ev şehri dışında bir ilde olup olmadığını kontrol eder, o ildeki yöresel işletmeleri döner, 14 günde bir bildirim satırı düşer. Şehir karşılaştırması normalize_tr_location_text() üzerinden yapılır (case/diacritic-insensitive) — çağıran taraf ham reverse-geocode metnini gönderebilir. Called by: user_location_controller.dart.';
