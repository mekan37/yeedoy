-- Fix auth_rsl_initplan warnings by wrapping auth/current_setting calls
-- and drop duplicate indexes reported by linter.

do $$
declare
  r record;
  new_qual text;
  new_check text;
  stmt text;
begin
  for r in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (
        (qual is not null and (qual ~ 'auth\\.' or qual ~ 'current_setting'))
        or (with_check is not null and (with_check ~ 'auth\\.' or with_check ~ 'current_setting'))
      )
  loop
    new_qual := r.qual;
    new_check := r.with_check;

    if new_qual is not null then
      new_qual := regexp_replace(new_qual, 'auth\\.([a-z_]+)\\(\\)', '(select auth.\\1())', 'g');
      new_qual := regexp_replace(new_qual, 'current_setting\\(([^\\)]*)\\)', '(select current_setting(\\1))', 'g');
    end if;

    if new_check is not null then
      new_check := regexp_replace(new_check, 'auth\\.([a-z_]+)\\(\\)', '(select auth.\\1())', 'g');
      new_check := regexp_replace(new_check, 'current_setting\\(([^\\)]*)\\)', '(select current_setting(\\1))', 'g');
    end if;

    stmt := format('alter policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);
    if new_qual is not null then
      stmt := stmt || format(' using (%s)', new_qual);
    end if;
    if new_check is not null then
      stmt := stmt || format(' with check (%s)', new_check);
    end if;

    execute stmt;
  end loop;
end $$;
-- Drop duplicate indexes reported by linter (safe if missing)
drop index if exists public.idx_businesses_city_district;
drop index if exists public.businesses_address_trgm_idx;
drop index if exists public.idx_businesses_name_trgm;
drop index if exists public.businesses_name_trgm_idx;
drop index if exists public.idx_price_history_item;
drop index if exists public.review_votes_review_idx;
