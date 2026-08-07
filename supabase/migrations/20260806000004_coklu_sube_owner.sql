-- Çoklu Şube Yönetimi (Owner) — chain_sort_order kolonu + owner-facing chain RPC'leri.
-- Admin tarafı (chains, admin_create_chain_v1 vb., 20260709000001) değişmiyor.
-- chain_memberships tablosu bilerek KULLANILMIYOR — kod tabanında hiç referansı
-- yok, gerçek "hangi işletme hangi zincirde" mekanizması businesses.chain_id.

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS chain_sort_order integer;

CREATE INDEX IF NOT EXISTS idx_businesses_chain_id
  ON public.businesses (chain_id)
  WHERE chain_id IS NOT NULL;

-- ── _is_approved_owner_of_business ───────────────────────────────────────────
-- is_owner_of_business(uuid) (bkz. base_schema) has_business_permission_v1 üzerinden
-- 'menu_write' iznine kadar iner (rank >= 300 → editor dahil). Bu migration'daki
-- 6 fonksiyon ise spesifikasyona göre sadece gerçek onaylı hak sahibine (owner_claims,
-- status='approved') açık olmalı — delegeli ekip üyelerine değil. Bu yüzden burada
-- ayrı, daha katı bir helper kullanılıyor.
CREATE OR REPLACE FUNCTION public._is_approved_owner_of_business(p_business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.owner_claims
    WHERE business_id = p_business_id AND user_id = auth.uid() AND status = 'approved'
  );
$$;

REVOKE ALL ON FUNCTION public._is_approved_owner_of_business(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._is_approved_owner_of_business(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._is_approved_owner_of_business(uuid) FROM anon;
COMMENT ON FUNCTION public._is_approved_owner_of_business IS
  'Internal: çağıranın işletmenin literal onaylı (approved) owner_claims sahibi olup olmadığını kontrol eder (is_owner_of_business''in aksine ekip/delege yetkilerini saymaz). Called by: bu dosyadaki owner_*_chain_v1 fonksiyonları.';

-- ── owner_create_chain_v1 ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_create_chain_v1(
  p_business_id uuid,
  p_chain_name  text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  IF p_chain_name IS NULL OR trim(p_chain_name) = '' THEN
    RAISE EXCEPTION 'validation_error: zincir adı boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.chains (name) VALUES (trim(p_chain_name)) RETURNING id INTO v_chain_id;

  UPDATE public.businesses
  SET chain_id = v_chain_id, chain_sort_order = 0
  WHERE id = p_business_id;

  RETURN v_chain_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_create_chain_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_create_chain_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_create_chain_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.owner_create_chain_v1 IS
  'Owner: kendi işletmesi için yeni bir zincir oluşturur, işletmeyi Ana Şube (chain_sort_order=0) yapar. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_add_business_to_chain_v1 ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_add_business_to_chain_v1(
  p_chain_id     uuid,
  p_business_id  uuid,
  p_branch_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_sort integer;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: eklenecek işletme size ait değil' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.chain_id = p_chain_id AND public._is_approved_owner_of_business(b.id)
  ) THEN
    RAISE EXCEPTION 'unauthorized: bu zincir üzerinde yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT COALESCE(MAX(chain_sort_order), -1) + 1 INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  UPDATE public.businesses
  SET chain_id = p_chain_id,
      branch_label = NULLIF(trim(coalesce(p_branch_label, '')), ''),
      chain_sort_order = v_next_sort
  WHERE id = p_business_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.owner_add_business_to_chain_v1 IS
  'Owner: kendi zincirine, kendine ait ve henüz zincirsiz bir işletme ekler. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_remove_business_from_chain_v1 ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_remove_business_from_chain_v1(p_business_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id  uuid;
  v_remaining integer;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;
  IF v_chain_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: işletme bir zincirde değil' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.businesses
  SET chain_id = NULL, branch_label = NULL, chain_sort_order = NULL
  WHERE id = p_business_id;

  SELECT count(*) INTO v_remaining FROM public.businesses WHERE chain_id = v_chain_id;
  IF v_remaining = 0 THEN
    IF EXISTS (SELECT 1 FROM public.business_team_memberships WHERE chain_id = v_chain_id) THEN
      RAISE EXCEPTION 'validation_error: zincire bağlı ekip üyeliği kayıtları var, zincir silinemez' USING ERRCODE = 'P0003';
    END IF;
    DELETE FROM public.chains WHERE id = v_chain_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.owner_remove_business_from_chain_v1 IS
  'Owner: kendi işletmesini zincirden çıkarır. Zincirde başka işletme kalmazsa chains satırı da silinir. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_reorder_chain_branch_v1 ────────────────────────────────────────────
-- Raw iki-değer swap DEĞİL: eski/yeni pozisyon arasındaki tüm kardeşleri bir
-- kaydırır, böylece zincir her zaman 0..N-1 aralığında boşluksuz/tekrarsız bir
-- permütasyon olarak kalır. owner_get_chain_overview_v1 "Ana Şube" rozetini
-- chain_sort_order = 0 üzerinden türetiyor (ayrı bir stored flag yok) — raw swap
-- kullanılırsa hiçbir şube 0'da kalmayabilir ve rozet UI'dan geri getirilemeyecek
-- şekilde kalıcı olarak kaybolur.
CREATE OR REPLACE FUNCTION public.owner_reorder_chain_branch_v1(
  p_business_id     uuid,
  p_new_sort_order  integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id           uuid;
  v_old_sort_order     integer;
  v_branch_count       integer;
  v_target_sort_order  integer;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id, chain_sort_order INTO v_chain_id, v_old_sort_order
  FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: işletme bir zincirde değil' USING ERRCODE = 'P0003';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.chain_id = v_chain_id AND (NOT public._is_approved_owner_of_business(b.id) OR b.chain_sort_order IS NULL)
  ) THEN
    RAISE EXCEPTION 'validation_error: zincir tutarsız durumda, sıralama desteklenmiyor' USING ERRCODE = 'P0003';
  END IF;

  SELECT count(*) INTO v_branch_count FROM public.businesses WHERE chain_id = v_chain_id;
  v_target_sort_order := LEAST(GREATEST(p_new_sort_order, 0), v_branch_count - 1);

  IF v_target_sort_order = v_old_sort_order THEN
    RETURN;
  END IF;

  IF v_target_sort_order > v_old_sort_order THEN
    UPDATE public.businesses
    SET chain_sort_order = chain_sort_order - 1
    WHERE chain_id = v_chain_id AND chain_sort_order > v_old_sort_order AND chain_sort_order <= v_target_sort_order;
  ELSE
    UPDATE public.businesses
    SET chain_sort_order = chain_sort_order + 1
    WHERE chain_id = v_chain_id AND chain_sort_order >= v_target_sort_order AND chain_sort_order < v_old_sort_order;
  END IF;

  UPDATE public.businesses
  SET chain_sort_order = v_target_sort_order
  WHERE id = p_business_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) FROM anon;
COMMENT ON FUNCTION public.owner_reorder_chain_branch_v1 IS
  'Owner: kendi şubesinin zincir içi sıralamasını günceller (sürükle-bırak). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_get_chain_overview_v1 ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_get_chain_overview_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
  v_result   jsonb;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RETURN jsonb_build_object(
      'chain_id', null, 'chain_name', null, 'branches', '[]'::jsonb,
      'total_views', 0, 'total_reservations', 0
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.chain_id = v_chain_id AND NOT public._is_approved_owner_of_business(b.id)
  ) THEN
    RAISE EXCEPTION 'validation_error: zincir birden fazla sahibe ait işletme içeriyor, bu görünüm desteklenmiyor' USING ERRCODE = 'P0003';
  END IF;

  SELECT jsonb_build_object(
    'chain_id', c.id,
    'chain_name', c.name,
    'branches', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'business_id', b.id,
        'name', b.name,
        'branch_label', b.branch_label,
        'city', b.city,
        'district', b.district,
        'is_active', b.is_active,
        'logo_url', b.logo_url,
        'chain_sort_order', b.chain_sort_order,
        'is_main_branch', (b.chain_sort_order = 0),
        'views', (
          SELECT count(*) FROM public.analytics_events e
          WHERE e.business_id = b.id AND e.event_name IN ('business_page_view', 'menu_view')
        ),
        'reservations', (
          SELECT count(*) FROM public.reservations r WHERE r.business_id = b.id
        )
      ) ORDER BY b.chain_sort_order), '[]'::jsonb)
      FROM public.businesses b WHERE b.chain_id = c.id
    ),
    'total_views', (
      SELECT count(*) FROM public.analytics_events e
      WHERE e.business_id IN (SELECT id FROM public.businesses WHERE chain_id = c.id)
        AND e.event_name IN ('business_page_view', 'menu_view')
    ),
    'total_reservations', (
      SELECT count(*) FROM public.reservations r
      WHERE r.business_id IN (SELECT id FROM public.businesses WHERE chain_id = c.id)
    )
  ) INTO v_result
  FROM public.chains c WHERE c.id = v_chain_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_get_chain_overview_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_get_chain_overview_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_get_chain_overview_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.owner_get_chain_overview_v1 IS
  'Owner: işletmesinin bağlı olduğu zincirin tüm şubelerini + görüntülenme/rezervasyon istatistiklerini döner. Zincirsizse boş sonuç döner (hata değil). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts, app/sunucu/sahip/coklu-sube-rapor-csv/route.ts.';

-- ── owner_list_addable_businesses_v1 ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_list_addable_businesses_v1()
RETURNS TABLE(business_id uuid, name text, city text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id, b.name, b.city
  FROM public.businesses b
  JOIN public.owner_claims oc ON oc.business_id = b.id
  WHERE oc.user_id = auth.uid() AND oc.status = 'approved' AND b.chain_id IS NULL
  ORDER BY b.name;
$$;

REVOKE ALL ON FUNCTION public.owner_list_addable_businesses_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_list_addable_businesses_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_list_addable_businesses_v1() FROM anon;
COMMENT ON FUNCTION public.owner_list_addable_businesses_v1 IS
  'Owner: henüz hiçbir zincire bağlı olmayan, kendi onaylı işletmelerini listeler ("Yeni Şube Ekle" modalı için). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_find_chained_business_v1 ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_find_chained_business_v1()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id
  FROM public.businesses b
  JOIN public.owner_claims oc ON oc.business_id = b.id
  WHERE oc.user_id = auth.uid() AND oc.status = 'approved' AND b.chain_id IS NOT NULL
  ORDER BY b.id
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.owner_find_chained_business_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_find_chained_business_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_find_chained_business_v1() FROM anon;
COMMENT ON FUNCTION public.owner_find_chained_business_v1 IS
  'Owner: kendi onaylı işletmelerinden zincire bağlı olan herhangi birini döner (is_active durumundan bağımsız — RLS''i bypass eder, anchor seçimi için). NULL dönerse owner''ın hiç zinciri yok demektir. Called by: app/sahip/coklu-sube/page.tsx.';
