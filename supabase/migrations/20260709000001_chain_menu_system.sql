-- ─────────────────────────────────────────────────────────────────────────────
-- ZİNCİR MENÜ SİSTEMİ
-- Template-branch yaklaşımı:
--   • chains.template_business_id → tüm şubeler bu işletmenin menüsünü paylaşır
--   • chain_item_overrides        → şube bazlı fiyat istisnası (örn. havalimanı şubesi)
--   • get_chain_menu_v1           → template menüsü + override'lar birleşik döner
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. chains tablosunu genişlet
ALTER TABLE public.chains
  ADD COLUMN IF NOT EXISTS logo_url        text,
  ADD COLUMN IF NOT EXISTS cover_url       text,
  ADD COLUMN IF NOT EXISTS category        text,
  ADD COLUMN IF NOT EXISTS website         text,
  ADD COLUMN IF NOT EXISTS is_verified     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS template_business_id uuid
    REFERENCES public.businesses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_chains_template_business
  ON public.chains(template_business_id)
  WHERE template_business_id IS NOT NULL;

-- chains tablosu zaten var; anon okuma politikası ekle
DROP POLICY IF EXISTS chains_anon_read ON public.chains;
CREATE POLICY chains_anon_read ON public.chains
  FOR SELECT TO anon USING (true);

-- 2. Şube bazlı fiyat istisnası tablosu
CREATE TABLE IF NOT EXISTS public.chain_item_overrides (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id    uuid        NOT NULL REFERENCES public.businesses(id)  ON DELETE CASCADE,
  menu_item_id   uuid        NOT NULL REFERENCES public.menu_items(id)  ON DELETE CASCADE,
  price_cents    integer     NOT NULL CHECK (price_cents >= 0),
  currency       text        NOT NULL DEFAULT 'TRY',
  note           text,
  created_by     uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chain_item_overrides_unique UNIQUE (business_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS idx_chain_overrides_business  ON public.chain_item_overrides(business_id);
CREATE INDEX IF NOT EXISTS idx_chain_overrides_item      ON public.chain_item_overrides(menu_item_id);

ALTER TABLE public.chain_item_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY chain_overrides_public_read ON public.chain_item_overrides
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY chain_overrides_admin_write ON public.chain_item_overrides
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── Admin RPCs ──────────────────────────────────────────────────────────────

-- 3. Zincir oluştur
CREATE OR REPLACE FUNCTION public.admin_create_chain_v1(
  p_name        text,
  p_slug        text        DEFAULT NULL,
  p_category    text        DEFAULT NULL,
  p_description text        DEFAULT NULL,
  p_logo_url    text        DEFAULT NULL,
  p_cover_url   text        DEFAULT NULL,
  p_website     text        DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'validation_error: name is required' USING ERRCODE = 'P0003';
  END IF;
  INSERT INTO public.chains (name, slug, category, description, logo_url, cover_url, website)
  VALUES (trim(p_name), trim(coalesce(p_slug,'')), p_category, p_description, p_logo_url, p_cover_url, p_website)
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('ok', true, 'chain_id', v_id);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_create_chain_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_chain_v1 TO authenticated;
COMMENT ON FUNCTION public.admin_create_chain_v1 IS 'Admin: yeni zincir markası oluştur.';

-- 4. Zincir güncelle
CREATE OR REPLACE FUNCTION public.admin_update_chain_v1(
  p_chain_id              uuid,
  p_name                  text    DEFAULT NULL,
  p_slug                  text    DEFAULT NULL,
  p_category              text    DEFAULT NULL,
  p_description           text    DEFAULT NULL,
  p_logo_url              text    DEFAULT NULL,
  p_cover_url             text    DEFAULT NULL,
  p_website               text    DEFAULT NULL,
  p_is_verified           boolean DEFAULT NULL,
  p_template_business_id  uuid    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.chains SET
    name                  = COALESCE(p_name,                 name),
    slug                  = COALESCE(p_slug,                 slug),
    category              = COALESCE(p_category,             category),
    description           = COALESCE(p_description,          description),
    logo_url              = COALESCE(p_logo_url,             logo_url),
    cover_url             = COALESCE(p_cover_url,            cover_url),
    website               = COALESCE(p_website,              website),
    is_verified           = COALESCE(p_is_verified,          is_verified),
    template_business_id  = COALESCE(p_template_business_id, template_business_id)
  WHERE id = p_chain_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: chain not found' USING ERRCODE = 'P0001';
  END IF;
  RETURN jsonb_build_object('ok', true);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_update_chain_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_chain_v1 TO authenticated;
COMMENT ON FUNCTION public.admin_update_chain_v1 IS 'Admin: zincir bilgilerini güncelle.';

-- 5. Zincirleri listele
CREATE OR REPLACE FUNCTION public.admin_list_chains_v1(
  p_q      text    DEFAULT NULL,
  p_limit  integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  id                     uuid,
  name                   text,
  slug                   text,
  category               text,
  logo_url               text,
  is_verified            boolean,
  template_business_id   uuid,
  template_business_name text,
  branch_count           bigint,
  created_at             timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id,
    c.name,
    c.slug,
    c.category,
    c.logo_url,
    c.is_verified,
    c.template_business_id,
    tb.name            AS template_business_name,
    COUNT(b.id)        AS branch_count,
    c.created_at
  FROM public.chains c
  LEFT JOIN public.businesses tb ON tb.id = c.template_business_id
  LEFT JOIN public.businesses b  ON b.chain_id = c.id AND b.is_active = true
  WHERE (p_q IS NULL OR c.name ILIKE '%' || p_q || '%')
  GROUP BY c.id, c.name, c.slug, c.category, c.logo_url, c.is_verified,
           c.template_business_id, tb.name, c.created_at
  ORDER BY c.name ASC
  LIMIT  GREATEST(p_limit,  1)
  OFFSET GREATEST(p_offset, 0);
$$;
REVOKE ALL ON FUNCTION public.admin_list_chains_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_chains_v1 TO authenticated;
COMMENT ON FUNCTION public.admin_list_chains_v1 IS 'Admin: zincir listesi (şube sayısı ve template dahil).';

-- 6. Zincir detayı (şubeler)
CREATE OR REPLACE FUNCTION public.admin_get_chain_detail_v1(p_chain_id uuid)
RETURNS TABLE(
  chain_id               uuid,
  chain_name             text,
  chain_slug             text,
  chain_category         text,
  chain_description      text,
  chain_logo_url         text,
  chain_cover_url        text,
  chain_website          text,
  chain_is_verified      boolean,
  template_business_id   uuid,
  business_id            uuid,
  business_name          text,
  branch_label           text,
  city                   text,
  district               text,
  is_template            boolean,
  is_active              boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id,  c.name, c.slug, c.category, c.description, c.logo_url, c.cover_url, c.website, c.is_verified,
    c.template_business_id,
    b.id,  b.name, b.branch_label, b.city, b.district,
    (b.id = c.template_business_id) AS is_template,
    b.is_active
  FROM public.chains c
  JOIN public.businesses b ON b.chain_id = c.id
  WHERE c.id = p_chain_id
  ORDER BY is_template DESC, b.name ASC;
$$;
REVOKE ALL ON FUNCTION public.admin_get_chain_detail_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_chain_detail_v1 TO authenticated;

-- 7. İşletmeyi zincire ata
CREATE OR REPLACE FUNCTION public.admin_assign_business_to_chain_v1(
  p_business_id    uuid,
  p_chain_id       uuid,
  p_branch_label   text    DEFAULT NULL,
  p_set_as_template boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.businesses SET
    chain_id     = p_chain_id,
    branch_label = COALESCE(p_branch_label, branch_label)
  WHERE id = p_business_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: business not found' USING ERRCODE = 'P0001';
  END IF;
  IF p_set_as_template THEN
    UPDATE public.chains SET template_business_id = p_business_id WHERE id = p_chain_id;
  END IF;
  RETURN jsonb_build_object('ok', true);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_assign_business_to_chain_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_assign_business_to_chain_v1 TO authenticated;
COMMENT ON FUNCTION public.admin_assign_business_to_chain_v1 IS 'Admin: işletmeyi zincire ata, isteğe bağlı template yap.';

-- 8. İşletmeyi zincirden çıkar
CREATE OR REPLACE FUNCTION public.admin_remove_business_from_chain_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.chains SET template_business_id = NULL
    WHERE template_business_id = p_business_id;
  UPDATE public.businesses SET chain_id = NULL, branch_label = NULL
    WHERE id = p_business_id;
  RETURN jsonb_build_object('ok', true);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_remove_business_from_chain_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_remove_business_from_chain_v1 TO authenticated;

-- 9. Şube fiyat istisnası kaydet
CREATE OR REPLACE FUNCTION public.admin_upsert_chain_override_v1(
  p_business_id   uuid,
  p_menu_item_id  uuid,
  p_price_cents   integer,
  p_currency      text    DEFAULT 'TRY',
  p_note          text    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  INSERT INTO public.chain_item_overrides
    (business_id, menu_item_id, price_cents, currency, note, created_by, updated_at)
  VALUES
    (p_business_id, p_menu_item_id, p_price_cents, p_currency, p_note, auth.uid(), now())
  ON CONFLICT (business_id, menu_item_id) DO UPDATE SET
    price_cents = EXCLUDED.price_cents,
    currency    = EXCLUDED.currency,
    note        = EXCLUDED.note,
    updated_at  = now();
  RETURN jsonb_build_object('ok', true);
END;
$$;
REVOKE ALL ON FUNCTION public.admin_upsert_chain_override_v1 FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_chain_override_v1 TO authenticated;

-- ─── Public RPCs ─────────────────────────────────────────────────────────────

-- 10. Zincir menüsünü getir (template menüsü + şube override'ları)
CREATE OR REPLACE FUNCTION public.get_chain_menu_v1(p_business_id uuid)
RETURNS TABLE(
  section_id         uuid,
  section_title      text,
  section_sort       integer,
  item_id            uuid,
  item_name          text,
  item_description   text,
  price_cents        integer,
  currency           text,
  image_url          text,
  is_available       boolean,
  item_sort          integer,
  has_branch_override boolean,
  branch_price_cents integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH chain_info AS (
    SELECT ch.template_business_id
    FROM public.businesses b
    JOIN public.chains ch ON ch.id = b.chain_id
    WHERE b.id = p_business_id
      AND ch.template_business_id IS NOT NULL
    LIMIT 1
  )
  SELECT
    ms.id                                        AS section_id,
    ms.title                                     AS section_title,
    ms.sort_order                                AS section_sort,
    mi.id                                        AS item_id,
    mi.name                                      AS item_name,
    mi.description                               AS item_description,
    COALESCE(ov.price_cents, mi.price_cents)     AS price_cents,
    COALESCE(ov.currency,    mi.currency)        AS currency,
    mi.image_url,
    mi.is_available,
    mi.sort_order                                AS item_sort,
    (ov.id IS NOT NULL)                          AS has_branch_override,
    ov.price_cents                               AS branch_price_cents
  FROM chain_info ci
  JOIN public.menus        m  ON m.business_id = ci.template_business_id
                              AND m.status = 'published'
  JOIN public.menu_sections ms ON ms.menu_id = m.id
  JOIN public.menu_items   mi ON mi.section_id = ms.id
  LEFT JOIN public.chain_item_overrides ov
         ON ov.menu_item_id = mi.id AND ov.business_id = p_business_id
  ORDER BY ms.sort_order, mi.sort_order;
$$;
REVOKE ALL ON FUNCTION public.get_chain_menu_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_chain_menu_v1(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_chain_menu_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_chain_menu_v1 IS
  'Zincir template menüsünü şube override fiyatlarıyla döner. chain_id NULL değilse kullanılır.';

-- 11. get_business_chain_info_v1 güncelle (daha fazla alan)
CREATE OR REPLACE FUNCTION public.get_business_chain_info_v1(p_business_id uuid)
RETURNS TABLE(
  chain_id           uuid,
  chain_name         text,
  chain_slug         text,
  chain_logo_url     text,
  chain_category     text,
  chain_is_verified  boolean,
  branch_label       text,
  is_template_branch boolean,
  branch_count       bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id              AS chain_id,
    c.name            AS chain_name,
    c.slug            AS chain_slug,
    c.logo_url        AS chain_logo_url,
    c.category        AS chain_category,
    c.is_verified     AS chain_is_verified,
    b.branch_label,
    (c.template_business_id = p_business_id) AS is_template_branch,
    (SELECT COUNT(*) FROM public.businesses b2
       WHERE b2.chain_id = c.id AND b2.is_active = true) AS branch_count
  FROM public.businesses b
  JOIN public.chains c ON c.id = b.chain_id
  WHERE b.id = p_business_id
    AND b.chain_id IS NOT NULL
  LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.get_business_chain_info_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_chain_info_v1(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_business_chain_info_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_business_chain_info_v1 IS
  'İşletmenin zincir bilgisini döner (logo, şube sayısı dahil). İşletme detay sayfası kullanır.';
