-- P0: admin_audit_log tablosunun "admin_audit_log_admin_all" policy'si
-- FOR ALL idi ve tablo anon+authenticated'a GRANT ALL ile açıktı. Herhangi
-- bir admin_users üyesi kendi denetim kaydını silebiliyor/değiştirebiliyor,
-- actor_id/ip gibi alanları serbestçe seçip başka bir admin'e suç
-- atabiliyordu. Bu, diğer tüm audit bulgularının kanıt değerini de
-- geçersiz kılan bir kök sorundu.
--
-- Yazma yalnızca insert_audit_log_v1 / log_admin_action_v1 (ikisi de
-- SECURITY DEFINER, postgres sahipliğinde) üzerinden yapılıyor — bu iki
-- fonksiyon RLS/GRANT'e tabi olmadığından append-only'ye indirme hiçbir
-- meşru yazma yolunu kırmıyor.

DROP POLICY IF EXISTS "admin_audit_log_admin_all" ON "public"."admin_audit_log";

CREATE POLICY "admin_audit_log_admin_read" ON "public"."admin_audit_log"
  FOR SELECT TO "authenticated"
  USING ("public"."is_admin"());

REVOKE INSERT, UPDATE, DELETE ON TABLE "public"."admin_audit_log" FROM "authenticated", "anon";
REVOKE ALL ON TABLE "public"."admin_audit_log" FROM "anon";
GRANT SELECT ON TABLE "public"."admin_audit_log" TO "authenticated";
