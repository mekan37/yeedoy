-- Admin SECURITY DEFINER RPCs must not be executable by anonymous clients.

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proname like 'admin\_%' escape '\'
  loop
    execute format('revoke execute on function %s from anon', fn.signature);
  end loop;
end $$;
