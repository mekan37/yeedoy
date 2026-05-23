-- T1: Owner can update their business lat/lng
create or replace function public.owner_update_business_location_v1(
  p_business_id uuid,
  p_lat         double precision,
  p_lng         double precision,
  p_address     text default null
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_authorized');
  end if;

  update public.businesses
  set
    lat      = p_lat,
    lng      = p_lng,
    geog     = st_point(p_lng, p_lat)::geography,
    address  = coalesce(nullif(trim(p_address), ''), address)
  where id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.owner_update_business_location_v1(uuid, double precision, double precision, text)
  to authenticated;
