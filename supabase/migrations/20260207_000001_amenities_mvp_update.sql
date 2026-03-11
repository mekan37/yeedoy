insert into public.business_amenities (key, label, icon)
values
  ('delivery', 'Paket Servis', 'delivery'),
  ('takeaway', 'Gel Al', 'takeaway')
on conflict (key) do nothing;
drop function if exists public.get_business_amenities_v1(uuid);
create or replace function public.get_business_amenities_v1(
  p_business_id uuid
)
returns table(
  key text,
  label text,
  icon text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.key,
    a.label,
    a.icon
  from public.business_amenity_map m
  join public.business_amenities a on a.id = m.amenity_id
  where m.business_id = p_business_id
  order by a.label asc;
$function$;
