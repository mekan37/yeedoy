-- P0: admin_users tablosunun "admin_users_admin_all" policy'si FOR ALL idi
-- (USING/WITH CHECK: is_admin()) — bu, herhangi bir admin_users üyesinin
-- (page:roller izni olmasa bile) kendi role_id'sini doğrudan
-- PATCH /rest/v1/admin_users ile Süper Admin rolüne değiştirebilmesi
-- anlamına geliyordu. has_permission_v1('page:roller') guard'ı yalnızca
-- admin_assign_user_role_v1 RPC'sini korur, PostgREST'in doğrudan tablo
-- erişimini korumaz.
--
-- admin_assign_user_role_v1 (20260819140000) zaten var olan bir admin_users
-- üyesinin rolünü page:roller iznini kontrol ederek değiştiriyor — uygulamanın
-- tek yazma yolu bu RPC. Uygulama kodunda admin_users'a doğrudan yazan
-- hiçbir çağrı yeri yok (yalnızca roller/page.tsx'te SELECT var), bu yüzden
-- policy'yi SELECT-only'ye indirmek hiçbir işlevi kırmıyor.

DROP POLICY IF EXISTS "admin_users_admin_all" ON "public"."admin_users";

CREATE POLICY "admin_users_admin_read" ON "public"."admin_users"
  FOR SELECT TO "authenticated"
  USING ("public"."is_admin"());

REVOKE INSERT, UPDATE, DELETE ON TABLE "public"."admin_users" FROM "authenticated", "anon";
REVOKE ALL ON TABLE "public"."admin_users" FROM "anon";
GRANT SELECT ON TABLE "public"."admin_users" TO "authenticated";
