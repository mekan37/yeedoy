-- TTL helper view + mark function for temp uploads

create or replace view public.expired_temp_uploads_v1 as
select
  t.*
from public.temp_uploads t
where t.status in ('pending', 'rejected')
  and t.expires_at < now();
create or replace function public.mark_expired_temp_uploads_v1(
  p_limit int default 500
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
begin
  with target as (
    select t.id
    from public.temp_uploads t
    where t.status in ('pending', 'rejected')
      and t.expires_at < now()
    order by t.expires_at asc
    limit greatest(coalesce(p_limit, 500), 1)
  )
  update public.temp_uploads t
  set
    status = 'expired',
    reviewed_at = coalesce(t.reviewed_at, now())
  where t.id in (select id from target);

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
grant select on public.expired_temp_uploads_v1 to authenticated, service_role;
grant execute on function public.mark_expired_temp_uploads_v1(int) to service_role;
