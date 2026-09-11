-- 20260504000002_revoke_anon_grants.sql'in henüz kapatmadığı bir açık:
-- o migration bu 13 get_my_* fonksiyonundan yalnızca `REVOKE ... FROM anon`
-- yaptı. Ama bu fonksiyonlar anon'a STANDING ALTER DEFAULT PRIVILEGES
-- üzerinden değil, ham Postgres CREATE FUNCTION varsayılanı olan PUBLIC
-- grant'i üzerinden erişilebiliyordu (proacl'de "anon=X" değil "=X" yani
-- boş-grantee/PUBLIC girdisi var) — anon PUBLIC'in bir üyesi olduğu için
-- `REVOKE FROM anon` bu erişimi hiç kapatmadı; `has_function_privilege`
-- ile do sağlandı: 13/14 fonksiyon hâlâ anon'a EXECUTE veriyordu.
--
-- Pratik istismar riski düşük (her fonksiyon auth.uid() eşitliğiyle filtre
-- yapıyor, anon'da auth.uid() null olduğu için sonuç boş dönüyor) ama
-- yetki-seviyesinde savunma derinliği eksikti — admin_* fonksiyonları için
-- zaten standart olan REVOKE ALL FROM PUBLIC deseni burada da uygulanıyor.
REVOKE ALL ON FUNCTION public.get_my_achievements_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_achievements_v2() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_behavior_segment_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_daily_micro_task_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_diet_profile_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_favorites_v1(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_profile_progress_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_profile_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_reputation_score_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_silent_quality_score_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_suspended_claim_badge_v1() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_suspended_claims_v1(text, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_trust_graph_v1() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_my_achievements_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_achievements_v2() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_behavior_segment_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_daily_micro_task_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_diet_profile_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_favorites_v1(integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_profile_progress_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_profile_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_reputation_score_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_silent_quality_score_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_suspended_claim_badge_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_suspended_claims_v1(text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_trust_graph_v1() TO authenticated;
