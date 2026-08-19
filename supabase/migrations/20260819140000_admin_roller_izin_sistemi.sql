-- Admin panel: sayfa bazlı rol/izin sistemi.
-- Bugüne kadar public.is_admin() ikili bir kontroldü (admin_users üyeliği = tam erişim).
-- Bu migration admin_users üyelerine rol atayıp, rolün hangi admin sayfalarını
-- görebileceğini admin_roles.permissions dizisiyle tanımlanabilir hale getirir.
-- Route/page seviyesinde fiili kısıtlama (Plan B) ayrı bir migration/PR'da gelecek;
-- bu migration yalnızca veri modelini ve RPC'leri kurar.

CREATE TYPE public.admin_permission_key AS ENUM (
  'page:isletmeler', 'page:zincirler', 'page:kuyruklar', 'page:isletme-basvurulari',
  'page:raporlar', 'page:kullanicilar', 'page:yorumlar', 'page:itirazlar',
  'page:fis-basvurulari', 'page:cop-kutusu', 'page:olaylar', 'page:konumlar',
  'page:analitik', 'page:musteri-destek', 'page:oneriler', 'page:fiyat-onerileri',
  'page:fraud-tespiti', 'page:fotograf-moderasyon', 'page:feature-flags',
  'page:api-anahtarlari', 'page:roller', 'page:gozlemlenebilirlik',
  'page:gelistirme-araclari', 'page:kvkk-gdpr', 'page:gecici-yuklemeler'
);

CREATE TABLE public.admin_roles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  description  text CHECK (description IS NULL OR char_length(description) <= 200),
  is_system    boolean NOT NULL DEFAULT false,
  is_active    boolean NOT NULL DEFAULT true,
  permissions  public.admin_permission_key[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX admin_roles_name_key ON public.admin_roles (lower(name));

ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;

-- Yalnızca SELECT policy + GRANT: tüm yazmalar aşağıdaki SECURITY DEFINER RPC'ler
-- üzerinden. Böylece bir admin, page:roller izni olmasa bile PostgREST ile
-- doğrudan admin_roles'a yazıp izin sistemini bypass edemez (RPC'ler kendi
-- has_permission_v1('page:roller') guard'ını taşır, GRANT INSERT/UPDATE/DELETE
-- authenticated'a hiç verilmez).
CREATE POLICY "admin_roles_admin_select"
  ON public.admin_roles
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

GRANT SELECT ON public.admin_roles TO authenticated;

-- ── admin_users: rol ata ──────────────────────────────────────────────────────
ALTER TABLE public.admin_users ADD COLUMN role_id uuid REFERENCES public.admin_roles(id);

-- Seed: tek sistem rolü — Süper Admin, tüm izinler, silinemez/düzenlenemez/pasife alınamaz.
INSERT INTO public.admin_roles (name, description, is_system, is_active, permissions)
VALUES (
  'Süper Admin',
  'Sistemin tüm yetkilerine sahiptir.',
  true,
  true,
  enum_range(NULL::public.admin_permission_key)
);

-- Mevcut tüm admin_users üyelerini Süper Admin'e bağla (kimse rolsüz kalmaz, kilitlenme riski yok).
UPDATE public.admin_users
SET role_id = (SELECT id FROM public.admin_roles WHERE is_system = true LIMIT 1)
WHERE role_id IS NULL;

ALTER TABLE public.admin_users ALTER COLUMN role_id SET NOT NULL;

CREATE INDEX idx_admin_users_role_id ON public.admin_users (role_id);

-- ── updated_at otomasyonu ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION private.tg_admin_roles_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_roles_set_updated_at
  BEFORE UPDATE ON public.admin_roles
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_admin_roles_set_updated_at();

-- ── RPC'ler ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.has_permission_v1(p_permission public.admin_permission_key)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users au
    JOIN public.admin_roles r ON r.id = au.role_id
    WHERE au.user_id = auth.uid()
      AND r.is_active
      AND p_permission = ANY(r.permissions)
  );
$$;

REVOKE ALL ON FUNCTION public.has_permission_v1(public.admin_permission_key) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_permission_v1(public.admin_permission_key) TO authenticated;
COMMENT ON FUNCTION public.has_permission_v1 IS 'Çağıranın admin_roles.permissions dizisinde p_permission olup olmadığını döner. Rol pasifse (is_active=false) her zaman false. Called by: src/lib/yetki-kontrol.ts, admin_*_role_v1 RPC guard''ları.';


CREATE OR REPLACE FUNCTION public.get_my_admin_role_v1()
RETURNS TABLE(role_name text, permissions public.admin_permission_key[])
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.name, r.permissions
  FROM public.admin_users au
  JOIN public.admin_roles r ON r.id = au.role_id
  WHERE au.user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_admin_role_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_admin_role_v1() TO authenticated;
COMMENT ON FUNCTION public.get_my_admin_role_v1 IS 'Çağıranın admin rolü adını ve izin listesini döner. Admin değilse boş sonuç seti. Called by: src/ui/kabuk/yonetici-kabuk-istemcisi.tsx (kenar çubuğu filtrelemesi ve rozet).';


CREATE OR REPLACE FUNCTION public.admin_create_role_v1(
  p_name        text,
  p_description text,
  p_permissions public.admin_permission_key[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF btrim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: Rol adı zorunlu' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.admin_roles (name, description, permissions, created_by, updated_by)
  VALUES (btrim(p_name), nullif(btrim(coalesce(p_description, '')), ''), coalesce(p_permissions, '{}'), auth.uid(), auth.uid())
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_role_v1(text, text, public.admin_permission_key[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_role_v1(text, text, public.admin_permission_key[]) TO authenticated;
COMMENT ON FUNCTION public.admin_create_role_v1 IS 'Yeni özel admin rolü oluşturur. page:roller izni gerektirir. Called by: app/sunucu/yonetici/roller/route.ts (POST).';


CREATE OR REPLACE FUNCTION public.admin_update_role_v1(
  p_role_id     uuid,
  p_name        text,
  p_description text,
  p_permissions public.admin_permission_key[],
  p_is_active   boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_system boolean;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT is_system INTO v_is_system FROM public.admin_roles WHERE id = p_role_id;
  IF v_is_system IS NULL THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;
  IF v_is_system THEN
    RAISE EXCEPTION 'validation_error: Sistem rolü düzenlenemez' USING ERRCODE = 'P0003';
  END IF;
  IF btrim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: Rol adı zorunlu' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.admin_roles
  SET name = btrim(p_name),
      description = nullif(btrim(coalesce(p_description, '')), ''),
      permissions = coalesce(p_permissions, '{}'),
      is_active = p_is_active,
      updated_by = auth.uid()
  WHERE id = p_role_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_role_v1(uuid, text, text, public.admin_permission_key[], boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_role_v1(uuid, text, text, public.admin_permission_key[], boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_update_role_v1 IS 'Özel admin rolünü günceller. Sistem rolleri (Süper Admin) düzenlenemez. Called by: app/sunucu/yonetici/roller/route.ts (PATCH).';


CREATE OR REPLACE FUNCTION public.admin_delete_role_v1(p_role_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_system boolean;
  v_assigned  integer;
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT is_system INTO v_is_system FROM public.admin_roles WHERE id = p_role_id;
  IF v_is_system IS NULL THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;
  IF v_is_system THEN
    RAISE EXCEPTION 'validation_error: Sistem rolü silinemez' USING ERRCODE = 'P0003';
  END IF;

  SELECT count(*) INTO v_assigned FROM public.admin_users WHERE role_id = p_role_id;
  IF v_assigned > 0 THEN
    RAISE EXCEPTION 'validation_error: Bu role atanmış % kullanıcı var, önce başka role taşıyın', v_assigned
      USING ERRCODE = 'P0003';
  END IF;

  DELETE FROM public.admin_roles WHERE id = p_role_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_role_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_role_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_delete_role_v1 IS 'Özel admin rolünü siler. Sistem rolü veya hala kullanıcı atanmışsa reddeder. Called by: app/sunucu/yonetici/roller/route.ts (DELETE).';


CREATE OR REPLACE FUNCTION public.admin_assign_user_role_v1(p_user_id uuid, p_role_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_permission_v1('page:roller') THEN
    RAISE EXCEPTION 'unauthorized: Rol yönetimi izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.admin_roles WHERE id = p_role_id) THEN
    RAISE EXCEPTION 'not_found: Rol bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.admin_users SET role_id = p_role_id WHERE user_id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Kullanıcı admin_users üyesi değil' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_assign_user_role_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_assign_user_role_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_assign_user_role_v1 IS 'Var olan bir admin_users üyesinin rolünü değiştirir. Yeni admin_users üyesi EKLEMEZ. Called by: app/sunucu/yonetici/roller/kullanici-ata/route.ts (PATCH).';
