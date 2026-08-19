-- get_advisors(security) bulguları: yeni RPC'lere varsayılan anon-execute yetkisi
-- (bu projede tekrarlayan bir desen, bkz. project_db_guvenlik_denetimi_2026_07) +
-- trigger fonksiyonunda eksik search_path.

REVOKE EXECUTE ON FUNCTION public.has_permission_v1(public.admin_permission_key) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_admin_role_v1() FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_create_role_v1(text, text, public.admin_permission_key[]) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_update_role_v1(uuid, text, text, public.admin_permission_key[], boolean) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_delete_role_v1(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_assign_user_role_v1(uuid, uuid) FROM anon;

ALTER FUNCTION private.tg_admin_roles_set_updated_at() SET search_path = public;
