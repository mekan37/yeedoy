-- B17 (mobil production-readiness denetimi): menü ekranı, bir menüdeki HER
-- bölüm için ayrı get_menu_items_v2 çağrısını Future.wait ile sınırsız
-- paralellikte tetikliyordu (30 bölümlü bir menüde 30 eşzamanlı istek); ayrıca
-- Future.wait'in varsayılan eagerError:false davranışı, ikinci bir RPC hata
-- verdiğinde yakalanmayan bir zone hatasına (Crashlytics'e sahte "fatal")
-- yol açabiliyordu.
--
-- Fix: section id listesini tek bir RPC çağrısında kabul eden yeni bir
-- fonksiyon. Bölüm başına limit/offset semantiği window function
-- (row_number() partition by section_id) ile korunuyor — get_menu_items_v2
-- ile aynı davranış, tek round-trip'te.
CREATE OR REPLACE FUNCTION "public"."get_menu_items_by_sections_v1"(
  "p_section_ids" "uuid"[],
  "p_limit" integer DEFAULT 200,
  "p_offset" integer DEFAULT 0
) RETURNS TABLE(
  "id" "uuid", "section_id" "uuid", "business_id" "uuid", "name" "text",
  "description" "text", "price_cents" integer, "currency" "text",
  "calories" integer, "is_vegan" boolean, "is_vegetarian" boolean,
  "is_gluten_free" boolean, "is_lactose_free" boolean, "is_halal" boolean,
  "status" "text", "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone, "catalog_item_id" bigint,
  "price_status" "text", "total_30d" integer
)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  with ranked as (
    select
      i.id,
      i.section_id,
      i.business_id,
      i.name,
      i.description,
      i.price_cents,
      i.currency,
      null::integer as calories,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(i.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'vegan'
      ) as is_vegan,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(i.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('vegetarian','vejetaryen')
      ) as is_vegetarian,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(i.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('gluten_free','glutensiz')
      ) as is_gluten_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(i.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) in ('lactose_free','laktozsuz')
      ) as is_lactose_free,
      exists (
        select 1 from jsonb_array_elements_text(coalesce(i.tags, '[]'::jsonb)) t(tag)
        where lower(t.tag) = 'halal'
      ) as is_halal,
      case when i.is_available then 'published' else 'archived' end::text as status,
      i.created_at,
      i.updated_at,
      null::bigint as catalog_item_id,
      coalesce(ps.price_status, 'unverified')::text as price_status,
      coalesce(ps.total_30d, 0)::int as total_30d,
      row_number() over (
        partition by i.section_id
        order by i.sort_order asc, i.created_at desc
      ) as rn
    from public.menu_items i
    left join public.menu_item_price_status_v1 ps on ps.menu_item_id = i.id
    where i.section_id = any(p_section_ids)
      and i.is_available = true
  )
  select
    id, section_id, business_id, name, description, price_cents, currency,
    calories, is_vegan, is_vegetarian, is_gluten_free, is_lactose_free,
    is_halal, status, created_at, updated_at, catalog_item_id, price_status,
    total_30d
  from ranked
  where rn > greatest(p_offset, 0)
    and rn <= greatest(p_offset, 0) + greatest(p_limit, 0)
  order by section_id, rn;
$$;

ALTER FUNCTION "public"."get_menu_items_by_sections_v1"("p_section_ids" "uuid"[], "p_limit" integer, "p_offset" integer) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."get_menu_items_by_sections_v1"("p_section_ids" "uuid"[], "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_menu_items_by_sections_v1"("p_section_ids" "uuid"[], "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_menu_items_by_sections_v1"("p_section_ids" "uuid"[], "p_limit" integer, "p_offset" integer) TO "service_role";
