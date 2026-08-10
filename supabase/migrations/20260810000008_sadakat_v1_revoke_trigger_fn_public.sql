-- Sadakat v1 — 20260810000007'de anon/authenticated'dan REVOKE edildi ama
-- trg_award_loyalty_on_review PUBLIC'ten hiç REVOKE edilmemişti (migration
-- 20260810000004'te bu fonksiyona hiç REVOKE/GRANT eklenmemiş, Postgres
-- varsayılanı: yeni fonksiyon PUBLIC'e açık). PUBLIC grant'i her role'e
-- (anon/authenticated dahil) miras kaldığından, tek tek anon/authenticated'dan
-- REVOKE etmek PUBLIC grant'i geçersiz kılmıyor — pg_proc.proacl'da hâlâ
-- "=X" (PUBLIC execute) görüldüğü doğrulandı (execute_sql ile kontrol edildi).

REVOKE ALL ON FUNCTION public.trg_award_loyalty_on_review() FROM PUBLIC;
