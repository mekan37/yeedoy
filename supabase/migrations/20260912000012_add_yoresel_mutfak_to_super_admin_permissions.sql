-- Enum'a eklemek tek başına yetmez — Süper Admin rolünün permissions
-- dizisi statik, yeni enum değerini otomatik almıyor.
UPDATE public.admin_roles
SET permissions = array_append(permissions, 'page:yoresel-mutfak'::admin_permission_key)
WHERE name = 'Süper Admin'
  AND NOT ('page:yoresel-mutfak' = ANY(permissions));
