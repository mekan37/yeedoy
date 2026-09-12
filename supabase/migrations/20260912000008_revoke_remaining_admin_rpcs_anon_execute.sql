-- P1: get_advisors + has_function_privilege ile tespit edilen, hala anon'a
-- EXECUTE ile acik kalan 4 admin_* fonksiyon. 3'u govdede zaten is_admin()/
-- is_admin_or_community_mod_v1() kontrolu yapiyor (su an istismar edilemez
-- ama savunma-derinligi eksikti); admin_kpi_summary_v1 hicbir kontrol
-- icermiyordu (SECURITY INVOKER, RLS'e guveniyor). CLAUDE.md kuralina uyum:
-- her admin_* RPC anon'dan hem dogrudan hem PUBLIC uzerinden revoke edilmeli.

REVOKE EXECUTE ON FUNCTION public.admin_kpi_summary_v1(integer) FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_list_user_profiles_private_v1(uuid[]) FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_set_appeal_review_v1(uuid, boolean) FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_set_submission_review_v1(uuid, boolean) FROM anon, PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_kpi_summary_v1(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_user_profiles_private_v1(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_appeal_review_v1(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_submission_review_v1(uuid, boolean) TO authenticated;
