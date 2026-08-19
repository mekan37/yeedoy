UPDATE public.admin_roles
SET permissions = enum_range(NULL::public.admin_permission_key)
WHERE is_system = true;
