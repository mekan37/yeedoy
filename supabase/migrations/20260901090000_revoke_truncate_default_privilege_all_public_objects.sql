-- ============================================================
-- 20260901090000_revoke_truncate_default_privilege_all_public_objects.sql
--
-- Bulgu: Task 6 (web yorum yazma RPC geçişi) kod kalitesi incelemesi sırasında
-- reviews tablosunda anon/authenticated'ın TRUNCATE dahil geniş varsayılan
-- yetkilere sahip olduğu bulundu. Kontrol genişletilince bunun reviews'a özgü
-- olmadığı, public şemadaki ~170 tablo/view'ın TAMAMINI etkileyen sistemik bir
-- ALTER DEFAULT PRIVILEGES kaydından kaynaklandığı ortaya çıktı — CLAUDE.md'de
-- fonksiyonlar (anon EXECUTE) için belgelenen ve 3 kez production güvenlik
-- düzeltmesine yol açan aynı patern, hiç kapatılmamış haliyle tablo tarafında.
--
-- Risk değerlendirmesi: PostgREST'in standart /rest/v1/ REST API'si TRUNCATE'i
-- hiçbir HTTP verb'e eşlemiyor, bu yüzden "tek istekle tabloyu sil" şeklinde
-- doğrudan bir sömürü yolu YOK. Ama bu bir savunma-derinliği açığı — DB
-- kimlik bilgilerinin herhangi bir şekilde (RPC içindeki dinamik SQL, ileride
-- eklenecek bir entegrasyon, vb.) sızması durumunda TRUNCATE hazır bekliyor
-- olurdu. CLAUDE.md'nin "REVOKE ... FROM PUBLIC bunu geri almaz, anon/
-- authenticated gerçek rol, isim isim REVOKE gerekir" kuralına uyularak
-- kapatılıyor.
--
-- Kapsam: public şemadaki tüm base table + partitioned table (relkind 'r','p'),
-- ardından tüm view + materialized view (relkind 'v','m'). PostGIS'in kendi
-- sahipliğindeki 3 sistem view'ı (geometry_columns, geography_columns,
-- spatial_ref_sys) bu rolün sahiplik yetkisi dışında kaldığı için REVOKE
-- edilemedi — TRUNCATE zaten bir view üzerinde Postgres tarafından anlamsız/
-- reddedilen bir işlem olduğu için bu pratik bir risk oluşturmuyor.
-- ============================================================

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
  LOOP
    EXECUTE format('REVOKE TRUNCATE ON TABLE public.%I FROM anon, authenticated;', r.relname);
  END LOOP;

  FOR r IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('v', 'm')
  LOOP
    EXECUTE format('REVOKE TRUNCATE ON TABLE public.%I FROM anon, authenticated;', r.relname);
  END LOOP;
END $$;
