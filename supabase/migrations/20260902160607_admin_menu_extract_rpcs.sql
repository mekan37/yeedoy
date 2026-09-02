-- admin_create_menu_extract_job_v1
CREATE OR REPLACE FUNCTION public.admin_create_menu_extract_job_v1(
  p_business_id uuid,
  p_source_type text,
  p_external_job_id text,
  p_source_url text DEFAULT NULL,
  p_source_file_name text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_source_type NOT IN ('url','upload') THEN
    RAISE EXCEPTION 'validation_error: gecersiz source_type' USING ERRCODE = 'P0003';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id) THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.admin_menu_extract_jobs (business_id, created_by, source_type, source_url, source_file_name, external_job_id, status)
  VALUES (p_business_id, auth.uid(), p_source_type, p_source_url, p_source_file_name, p_external_job_id, 'queued')
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_create_menu_extract_job_v1(uuid, text, text, text, text) FROM anon;
COMMENT ON FUNCTION public.admin_create_menu_extract_job_v1 IS
  'Admin: harici Menu Extractor servisine gönderilen bir URL/upload analiz isteğinin dahili kaydını oluşturur. Called by: app/sunucu/yonetici/menu-analiz/baslat/route.ts.';


-- admin_get_menu_extract_job_v1
CREATE OR REPLACE FUNCTION public.admin_get_menu_extract_job_v1(p_job_id uuid)
RETURNS TABLE (
  id uuid, business_id uuid, source_type text, source_url text,
  source_file_name text, external_job_id text, status text,
  error_message text, created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT j.id, j.business_id, j.source_type, j.source_url, j.source_file_name,
           j.external_job_id, j.status, j.error_message, j.created_at
    FROM public.admin_menu_extract_jobs j
    WHERE j.id = p_job_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_get_menu_extract_job_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_get_menu_extract_job_v1 IS
  'Admin: bir menü analiz işinin dahili durumunu döner (boş sonuç = bulunamadı, bu bir TABLE fonksiyonu olduğu için exception yerine boş satır seti kullanılır). Called by: app/yonetici/isletmeler/[id]/menu-analiz.';


-- admin_finish_menu_extract_job_v1
CREATE OR REPLACE FUNCTION public.admin_finish_menu_extract_job_v1(p_job_id uuid, p_result jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT business_id INTO v_business_id FROM public.admin_menu_extract_jobs WHERE id = p_job_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.admin_menu_extract_jobs
  SET status = 'finished', result = p_result, updated_at = now()
  WHERE id = p_job_id AND status <> 'finished';

  IF NOT FOUND THEN
    RETURN; -- zaten finished (tekrar polling) — items ikinci kez eklenmez, idempotent
  END IF;

  INSERT INTO public.admin_menu_extract_items (
    job_id, business_id, category_name, name, description, price_cents, currency,
    confidence, requires_review, review_reasons, warnings
  )
  SELECT
    p_job_id, v_business_id, x.category_name, x.name, x.description, x.price_cents,
    coalesce(x.currency, 'TRY'), x.confidence, coalesce(x.requires_review, false),
    coalesce(x.review_reasons, '[]'::jsonb), coalesce(x.warnings, '[]'::jsonb)
  FROM jsonb_to_recordset(p_items) AS x(
    category_name text, name text, description text, price_cents integer,
    currency text, confidence numeric, requires_review boolean,
    review_reasons jsonb, warnings jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_finish_menu_extract_job_v1(uuid, jsonb, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_finish_menu_extract_job_v1(uuid, jsonb, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_finish_menu_extract_job_v1(uuid, jsonb, jsonb) FROM anon;
COMMENT ON FUNCTION public.admin_finish_menu_extract_job_v1 IS
  'Admin: bir menü analiz işini "finished" işaretler, ham sonucu saklar, TypeScript tarafında zaten normalize edilmiş p_items dizisini admin_menu_extract_items''e ekler. İdempotent — zaten finished bir işte tekrar çağrılırsa items''ı ikinci kez eklemez. Called by: app/sunucu/yonetici/menu-analiz/durum/route.ts.';


-- admin_fail_menu_extract_job_v1
CREATE OR REPLACE FUNCTION public.admin_fail_menu_extract_job_v1(p_job_id uuid, p_error_message text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.admin_menu_extract_jobs
  SET status = 'failed', error_message = p_error_message, updated_at = now()
  WHERE id = p_job_id AND status <> 'finished';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_fail_menu_extract_job_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_fail_menu_extract_job_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_fail_menu_extract_job_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.admin_fail_menu_extract_job_v1 IS
  'Admin: bir menü analiz işini "failed" işaretler (zaten finished bir işi asla ezmez). Called by: app/sunucu/yonetici/menu-analiz/durum/route.ts.';


-- admin_list_menu_extract_items_v1
CREATE OR REPLACE FUNCTION public.admin_list_menu_extract_items_v1(p_job_id uuid)
RETURNS TABLE (
  id uuid, category_name text, name text, description text,
  price_cents integer, currency text, confidence numeric,
  requires_review boolean, review_reasons jsonb, warnings jsonb,
  excluded boolean, imported boolean, imported_menu_item_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT i.id, i.category_name, i.name, i.description, i.price_cents, i.currency,
           i.confidence, i.requires_review, i.review_reasons, i.warnings,
           i.excluded, i.imported, i.imported_menu_item_id
    FROM public.admin_menu_extract_items i
    WHERE i.job_id = p_job_id
    ORDER BY i.category_name NULLS LAST, i.name;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_menu_extract_items_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_menu_extract_items_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_menu_extract_items_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_list_menu_extract_items_v1 IS
  'Admin: bir menü analiz işinin taslak kalemlerini listeler. Called by: app/yonetici/isletmeler/[id]/menu-analiz.';


-- admin_update_menu_extract_item_v1
CREATE OR REPLACE FUNCTION public.admin_update_menu_extract_item_v1(
  p_item_id uuid,
  p_category_name text,
  p_name text,
  p_description text,
  p_price_cents integer,
  p_currency text DEFAULT 'TRY'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'validation_error: name zorunlu' USING ERRCODE = 'P0003';
  END IF;
  IF p_price_cents IS NOT NULL AND p_price_cents < 0 THEN
    RAISE EXCEPTION 'validation_error: price_cents negatif olamaz' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.admin_menu_extract_items
  SET category_name = p_category_name,
      name = trim(p_name),
      description = p_description,
      price_cents = p_price_cents,
      currency = coalesce(p_currency, 'TRY'),
      updated_at = now()
  WHERE id = p_item_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_menu_extract_item_v1(uuid, text, text, text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_menu_extract_item_v1(uuid, text, text, text, integer, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_update_menu_extract_item_v1(uuid, text, text, text, integer, text) FROM anon;
COMMENT ON FUNCTION public.admin_update_menu_extract_item_v1 IS
  'Admin: bir taslak menü analiz kalemini (aktarılmış olsa dahi, sadece taslak kaydını) düzenler — gerçek menu_items''e yansımaz, ayrı bir "Menüye Aktar" adımı gerekir. Called by: app/yonetici/isletmeler/[id]/menu-analiz.';


-- admin_set_menu_extract_item_excluded_v1
CREATE OR REPLACE FUNCTION public.admin_set_menu_extract_item_excluded_v1(p_item_id uuid, p_excluded boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.admin_menu_extract_items
  SET excluded = p_excluded, updated_at = now()
  WHERE id = p_item_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_menu_extract_item_excluded_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_menu_extract_item_excluded_v1(uuid, boolean) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_menu_extract_item_excluded_v1(uuid, boolean) FROM anon;
COMMENT ON FUNCTION public.admin_set_menu_extract_item_excluded_v1 IS
  'Admin: bir taslak menü analiz kalemini "dahil et/hariç tut" olarak işaretler (import listesinden çıkarma). Called by: app/yonetici/isletmeler/[id]/menu-analiz.';


-- admin_list_business_menu_items_v1
CREATE OR REPLACE FUNCTION public.admin_list_business_menu_items_v1(p_business_id uuid)
RETURNS TABLE (
  id uuid, name text, description text, price_cents integer,
  currency text, category_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT mi.id, mi.name, mi.description, mi.price_cents, mi.currency, mt.name AS category_name
    FROM public.menu_items mi
    LEFT JOIN public.menu_categories mc ON mc.id = mi.category_id
    LEFT JOIN public.menu_translations mt ON mt.entity_type = 'category' AND mt.entity_id = mc.id AND mt.locale = 'tr'
    WHERE mi.business_id = p_business_id AND mi.is_available = true
    ORDER BY mi.name;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_business_menu_items_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_business_menu_items_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_business_menu_items_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_list_business_menu_items_v1 IS
  'Admin: bir işletmenin mevcut (aktif) menu_items listesini döner — Menü Analiz Et akışında yeni çıkarılan kalemleri mevcut menüyle karşılaştırıp körlemesine ezmemek için kullanılır. Called by: app/yonetici/isletmeler/[id]/menu-analiz.';


-- admin_apply_menu_extract_job_v1
CREATE OR REPLACE FUNCTION public.admin_apply_menu_extract_job_v1(p_job_id uuid, p_decisions jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_menu_id uuid;
  v_section_id uuid;
  v_category_id uuid;
  v_new_item_id uuid;
  v_target_id uuid;
  v_created_count int := 0;
  v_updated_count int := 0;
  v_skipped_count int := 0;
  v_decision jsonb;
  v_item record;
  v_item_id uuid;
  v_action text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT business_id INTO v_business_id FROM public.admin_menu_extract_jobs WHERE id = p_job_id;
  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;

  -- Hedef menü: yayınlanmış bir menü varsa onu kullan, yoksa herhangi birini, o da yoksa oluştur.
  SELECT id INTO v_menu_id FROM public.menus WHERE business_id = v_business_id AND status = 'published' ORDER BY created_at LIMIT 1;
  IF v_menu_id IS NULL THEN
    SELECT id INTO v_menu_id FROM public.menus WHERE business_id = v_business_id ORDER BY created_at LIMIT 1;
  END IF;
  IF v_menu_id IS NULL THEN
    INSERT INTO public.menus (business_id, title, status, source, created_by)
    VALUES (v_business_id, 'Menü', 'published', 'admin', auth.uid())
    RETURNING id INTO v_menu_id;
  END IF;

  -- Hedef bölüm: bu menüde "İçe Aktarılan Ürünler" bölümü varsa kullan, yoksa oluştur (tekrar analiz çalıştırılırsa aynı bölüm yeniden kullanılır).
  SELECT id INTO v_section_id FROM public.menu_sections WHERE menu_id = v_menu_id AND title = 'İçe Aktarılan Ürünler' LIMIT 1;
  IF v_section_id IS NULL THEN
    INSERT INTO public.menu_sections (menu_id, title, created_by)
    VALUES (v_menu_id, 'İçe Aktarılan Ürünler', auth.uid())
    RETURNING id INTO v_section_id;
  END IF;

  FOR v_decision IN SELECT * FROM jsonb_array_elements(p_decisions)
  LOOP
    v_item_id := (v_decision->>'item_id')::uuid;
    v_action := v_decision->>'action';

    SELECT * INTO v_item FROM public.admin_menu_extract_items WHERE id = v_item_id AND job_id = p_job_id;
    IF NOT FOUND OR v_item.imported THEN
      CONTINUE; -- bu job'a ait değil, veya zaten aktarılmış — sessizce atla
    END IF;

    IF v_action = 'skip' THEN
      UPDATE public.admin_menu_extract_items SET excluded = true, updated_at = now() WHERE id = v_item_id;
      v_skipped_count := v_skipped_count + 1;

    ELSIF v_action = 'update' THEN
      v_target_id := (v_decision->>'target_menu_item_id')::uuid;
      IF v_target_id IS NOT NULL AND v_item.price_cents IS NOT NULL THEN
        UPDATE public.menu_items
        SET price_cents = v_item.price_cents, updated_at = now()
        WHERE id = v_target_id AND business_id = v_business_id;
        IF FOUND THEN
          UPDATE public.admin_menu_extract_items SET imported = true, imported_menu_item_id = v_target_id, updated_at = now() WHERE id = v_item_id;
          v_updated_count := v_updated_count + 1;
        END IF;
      END IF;
      -- target_id yoksa veya fiyat NULL ise: sessizce hiçbir şey yapılmaz (fiyat asla uydurulmaz, hatalı hedef güncellenmez).

    ELSIF v_action = 'create' THEN
      IF v_item.price_cents IS NOT NULL THEN
        v_category_id := NULL;
        IF v_item.category_name IS NOT NULL AND trim(v_item.category_name) <> '' THEN
          SELECT mc.id INTO v_category_id
          FROM public.menu_categories mc
          JOIN public.menu_translations mt ON mt.entity_type = 'category' AND mt.entity_id = mc.id AND mt.locale = 'tr'
          WHERE mc.menu_id = v_menu_id AND lower(trim(mt.name)) = lower(trim(v_item.category_name))
          LIMIT 1;

          IF v_category_id IS NULL THEN
            INSERT INTO public.menu_categories (business_id, menu_id, is_active)
            VALUES (v_business_id, v_menu_id, true)
            RETURNING id INTO v_category_id;

            INSERT INTO public.menu_translations (entity_type, entity_id, locale, name)
            VALUES ('category', v_category_id, 'tr', trim(v_item.category_name));
          END IF;
        END IF;

        INSERT INTO public.menu_items (section_id, business_id, category_id, name, description, price_cents, currency, is_available)
        VALUES (v_section_id, v_business_id, v_category_id, v_item.name, v_item.description, v_item.price_cents, coalesce(v_item.currency, 'TRY'), true)
        RETURNING id INTO v_new_item_id;

        UPDATE public.admin_menu_extract_items SET imported = true, imported_menu_item_id = v_new_item_id, updated_at = now() WHERE id = v_item_id;
        v_created_count := v_created_count + 1;
      END IF;
      -- fiyat NULL ise sessizce atlanır (fiyat asla uydurulmaz) — client tarafı zaten fiyatsız kalemler için "create" seçeneğini engellemeli, bu RPC ikinci savunma katmanı.
    END IF;
  END LOOP;

  PERFORM public.log_admin_action_v1(
    'menu.extract_import',
    'admin_menu_extract_jobs',
    p_job_id,
    jsonb_build_object('business_id', v_business_id, 'created', v_created_count, 'updated', v_updated_count, 'skipped', v_skipped_count)
  );

  RETURN jsonb_build_object('ok', true, 'created', v_created_count, 'updated', v_updated_count, 'skipped', v_skipped_count);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_apply_menu_extract_job_v1(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_apply_menu_extract_job_v1(uuid, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_apply_menu_extract_job_v1(uuid, jsonb) FROM anon;
COMMENT ON FUNCTION public.admin_apply_menu_extract_job_v1 IS
  'Admin: "Menüye Aktar" onayından sonra çağrılır. p_decisions dizisindeki her {item_id, action: create|update|skip, target_menu_item_id?} kararını uygular. create: fiyatı NULL olan kalemler için hiçbir şey yapmaz (fiyat asla uydurulmaz), gerekirse hedef menü/bölüm/kategoriyi bulur ya da oluşturur. update: sadece fiyatı günceller, var olan menu_items satırını körlemesine ezmez. Zaten aktarılmış (imported=true) kalemleri yeniden işlemez — idempotent. Called by: app/yonetici/isletmeler/[id]/menu-analiz.';
