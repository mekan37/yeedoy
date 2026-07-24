-- Supabase Performance Advisor: auth_rls_initplan (126 policy). RLS policy'lerinde
-- auth.uid()/auth.role()/auth.jwt() sarılmadan (bare) kullanılıyordu — Postgres
-- planner bunu her SATIR için yeniden çalıştırıyor. (select auth.uid()) şeklinde
-- sarmalamak sonucu DEĞİŞTİRMEZ (fonksiyon STABLE, tüm satırlar için aynı değeri
-- döner), sadece planner'ın onu bir kez (InitPlan) hesaplamasını sağlar.
--
-- Zaten doğru şekilde sarılmış olan policy'ler (`( SELECT auth.uid() AS uid)` gibi
-- pg_get_expr çıktısı) DOKUNULMADAN bırakılıyor — aşağıdaki blok önce bunları
-- geçici bir işaretle koruyor, sonra kalan çıplak çağrıları sarıyor, sonra işareti
-- geri açıyor. Fonksiyon bazında 3 tip (uid/role/jwt) ayrı ayrı işleniyor.
--
-- Düşük trafikli tablolarda (~0-100 satır) şu an ölçülebilir bir etkisi yok;
-- trafik büyüdükçe önem kazanacak, önceden hazırlandı.

DO $$
DECLARE
  pol record;
  new_qual text;
  new_with_check text;
  alter_sql text;
  remaining int;
BEGIN
  FOR pol IN
    SELECT schemaname, tablename, policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        (qual IS NOT NULL AND regexp_replace(qual, 'SELECT\s+auth\.(uid|role|jwt)\(\)', '', 'gi') ~ 'auth\.(uid|role|jwt)\(\)')
        OR
        (with_check IS NOT NULL AND regexp_replace(with_check, 'SELECT\s+auth\.(uid|role|jwt)\(\)', '', 'gi') ~ 'auth\.(uid|role|jwt)\(\)')
      )
  LOOP
    new_qual := pol.qual;
    new_with_check := pol.with_check;

    IF new_qual IS NOT NULL THEN
      new_qual := regexp_replace(new_qual, 'SELECT\s+auth\.uid\(\)',  E'\x01UID\x02',  'gi');
      new_qual := regexp_replace(new_qual, 'SELECT\s+auth\.role\(\)', E'\x01ROLE\x02', 'gi');
      new_qual := regexp_replace(new_qual, 'SELECT\s+auth\.jwt\(\)',  E'\x01JWT\x02',  'gi');
      new_qual := regexp_replace(new_qual, 'auth\.uid\(\)',  '(select auth.uid())',  'g');
      new_qual := regexp_replace(new_qual, 'auth\.role\(\)', '(select auth.role())', 'g');
      new_qual := regexp_replace(new_qual, 'auth\.jwt\(\)',  '(select auth.jwt())',  'g');
      new_qual := replace(new_qual, E'\x01UID\x02',  'SELECT auth.uid()');
      new_qual := replace(new_qual, E'\x01ROLE\x02', 'SELECT auth.role()');
      new_qual := replace(new_qual, E'\x01JWT\x02',  'SELECT auth.jwt()');
    END IF;

    IF new_with_check IS NOT NULL THEN
      new_with_check := regexp_replace(new_with_check, 'SELECT\s+auth\.uid\(\)',  E'\x01UID\x02',  'gi');
      new_with_check := regexp_replace(new_with_check, 'SELECT\s+auth\.role\(\)', E'\x01ROLE\x02', 'gi');
      new_with_check := regexp_replace(new_with_check, 'SELECT\s+auth\.jwt\(\)',  E'\x01JWT\x02',  'gi');
      new_with_check := regexp_replace(new_with_check, 'auth\.uid\(\)',  '(select auth.uid())',  'g');
      new_with_check := regexp_replace(new_with_check, 'auth\.role\(\)', '(select auth.role())', 'g');
      new_with_check := regexp_replace(new_with_check, 'auth\.jwt\(\)',  '(select auth.jwt())',  'g');
      new_with_check := replace(new_with_check, E'\x01UID\x02',  'SELECT auth.uid()');
      new_with_check := replace(new_with_check, E'\x01ROLE\x02', 'SELECT auth.role()');
      new_with_check := replace(new_with_check, E'\x01JWT\x02',  'SELECT auth.jwt()');
    END IF;

    alter_sql := format('ALTER POLICY %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    IF new_qual IS NOT NULL THEN
      alter_sql := alter_sql || format(' USING (%s)', new_qual);
    END IF;
    IF new_with_check IS NOT NULL THEN
      alter_sql := alter_sql || format(' WITH CHECK (%s)', new_with_check);
    END IF;

    EXECUTE alter_sql;
  END LOOP;

  SELECT count(*) INTO remaining
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      (qual IS NOT NULL AND regexp_replace(qual, 'SELECT\s+auth\.(uid|role|jwt)\(\)', '', 'gi') ~ 'auth\.(uid|role|jwt)\(\)')
      OR
      (with_check IS NOT NULL AND regexp_replace(with_check, 'SELECT\s+auth\.(uid|role|jwt)\(\)', '', 'gi') ~ 'auth\.(uid|role|jwt)\(\)')
    );

  IF remaining <> 0 THEN
    RAISE EXCEPTION 'auth_rls_initplan fix incomplete: % policy still unwrapped', remaining;
  END IF;
END $$;
