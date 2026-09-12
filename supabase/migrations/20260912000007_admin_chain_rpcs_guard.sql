-- P1: admin_list_chains_v1 / admin_get_chain_detail_v1 hiçbir yetki kontrolü
-- içermeden herhangi bir authenticated kullanıcıya (admin olması şart değil)
-- açıktı — ücretsiz hesap açan biri tam zincir/şube grafiğini çekebiliyordu.
-- REVOKE ALL FROM PUBLIC zaten vardı ama gövdede is_admin() kontrolü yoktu.

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
  WHERE public.is_admin()
    AND (p_q IS NULL OR c.name ILIKE '%' || p_q || '%')
  GROUP BY c.id, c.name, c.slug, c.category, c.logo_url, c.is_verified,
           c.template_business_id, tb.name, c.created_at
  ORDER BY c.name ASC
  LIMIT  LEAST(GREATEST(p_limit,  1), 200)
  OFFSET GREATEST(p_offset, 0);
$$;

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
    AND public.is_admin()
  ORDER BY is_template DESC, b.name ASC;
$$;
