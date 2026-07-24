-- Savunma katmanı: 9 admin_* fonksiyonu (hepsi içeride is_admin() kontrolü yapıyor,
-- doğrulandı) anon (kimliksiz) role'üne EXECUTE yetkisiyle açıktı. Şu an doğrudan
-- istismar edilebilir değiller (fonksiyon içi kontrol var) ama tek savunma katmanı
-- buydu — update_team_member_v1 IDOR'u tam olarak "içeride kontrol var" güvencesinin
-- tek başına yeterli olmadığını gösterdi. GRANT seviyesinde ikinci bir katman ekleniyor.

REVOKE EXECUTE ON FUNCTION public.admin_assign_business_to_chain_v1(uuid, uuid, text, boolean) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_create_chain_v1(text, text, text, text, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_get_chain_detail_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_get_overview_stats_v1() FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_kpi_summary_v1(integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_chains_v1(text, integer, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_remove_business_from_chain_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_update_chain_v1(uuid, text, text, text, text, text, text, text, boolean, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_chain_override_v1(uuid, uuid, integer, text, text) FROM anon;
