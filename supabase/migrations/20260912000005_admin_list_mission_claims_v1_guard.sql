-- P0: admin_list_mission_claims_v1 hiçbir yetki kontrolü içermeden anon'a
-- GRANT ALL ile açıktı — yalnızca NEXT_PUBLIC_SUPABASE_ANON_KEY ile,
-- oturumsuz, sınırsız p_limit'le tüm foto-görev talepleri tablosu
-- (kullanıcı-işletme-konum ilişkisi dahil) çekilebiliyordu.

CREATE OR REPLACE FUNCTION "public"."admin_list_mission_claims_v1"("p_status" "text" DEFAULT 'submitted'::"text", "p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0) RETURNS TABLE("claim_id" "uuid", "status" "text", "created_at" timestamp with time zone, "mission_id" "uuid", "mission_type" "text", "business_id" "uuid", "business_name" "text", "user_id" "uuid", "photo_id" "uuid", "reward_points" integer)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    c.id as claim_id,
    c.status,
    c.created_at,
    m.id as mission_id,
    m.mission_type,
    m.business_id,
    b.name as business_name,
    c.user_id,
    c.photo_id,
    m.reward_points
  from public.user_mission_claims c
  join public.photo_missions m on m.id = c.mission_id
  join public.businesses b on b.id = m.business_id
  where public.is_admin()
    and (p_status is null or c.status = p_status)
  order by c.created_at desc
  limit least(greatest(p_limit, 0), 200)
  offset greatest(p_offset, 0);
$$;

REVOKE EXECUTE ON FUNCTION "public"."admin_list_mission_claims_v1"("p_status" "text", "p_limit" integer, "p_offset" integer) FROM "anon";
