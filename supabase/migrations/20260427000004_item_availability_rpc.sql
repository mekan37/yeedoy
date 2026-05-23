-- M5: Inline item aktif/pasif toggle for panel editor
-- Lightweight RPC to toggle menu item availability without a full item update.

create or replace function public.owner_set_item_available_v1(
  p_item_id    uuid,
  p_available  boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  -- Verify ownership
  if not exists (
    select 1
    from public.business_claims
    where business_id = v_business_id
      and user_id = auth.uid()
      and is_active = true
  ) then
    return jsonb_build_object('ok', false, 'code', 'unauthorized');
  end if;

  update public.menu_items
  set is_available = p_available
  where id = p_item_id;

  return jsonb_build_object('ok', true, 'is_available', p_available);
end;
$$;

grant execute on function public.owner_set_item_available_v1 to authenticated;
