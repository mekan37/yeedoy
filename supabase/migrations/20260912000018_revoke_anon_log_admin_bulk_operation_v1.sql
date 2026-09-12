-- Standing ALTER DEFAULT PRIVILEGES anon-execute leak (bkz. CLAUDE.md notu:
-- 20260810000006/20260820062028/20260824000008 ile aynı kök neden) —
-- log_admin_bulk_operation_v1 (2026-05-26'da eklenmiş, hiç çağıran yok, dead
-- code) anon'a EXECUTE ile sızmıştı. Fonksiyon içinde is_admin() guard'ı var
-- (istismar edilemez) ama proje kuralı gereği explicit revoke ekleniyor.
REVOKE EXECUTE ON FUNCTION public.log_admin_bulk_operation_v1(text, uuid[], jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.log_admin_bulk_operation_v1(text, uuid[], jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.log_admin_bulk_operation_v1(text, uuid[], jsonb) TO authenticated;
