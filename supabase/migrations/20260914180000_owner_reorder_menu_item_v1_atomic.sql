-- Sahip Paneli Güvenlik Denetimi P2: reorderItem sürükle-bırak reorder'ı
-- tek bir item'ın sort_order'ını hedef değere set ediyordu, diğer
-- item'ların sort_order'ını hiç kaydırmıyordu — bu da aynı sort_order'a
-- sahip iki item üretip sıralamayı kalıcı olarak bozuyordu. Ayrıca hedef
-- yalnızca bir sayı (targetItem.sort_order) olduğu için, filtre
-- uygulanmamış (tüm bölümler karışık) görünümde farklı bölümlerdeki
-- item'lar arasında sürükleme yapılırsa item'ın section_id'si hiç
-- güncellenmiyordu.
--
-- Atomik bir RPC'ye taşındı: aynı bölüm içi kaydırma VE bölümler arası
-- taşıma (gap kapatma + gap açma) tek transaction'da yapılıyor.
create or replace function public.owner_reorder_menu_item_v1(
  p_item_id uuid,
  p_target_section_id uuid,
  p_target_sort_order int
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_id uuid;
  v_old_section_id uuid;
  v_old_sort_order int;
  v_target_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if p_target_sort_order is null or p_target_sort_order < 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid_sort_order');
  end if;

  select business_id, section_id, sort_order
  into v_business_id, v_old_section_id, v_old_sort_order
  from menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  select m.business_id into v_target_business_id
  from menu_sections ms
  join menus m on m.id = ms.menu_id
  where ms.id = p_target_section_id;

  if v_target_business_id is distinct from v_business_id then
    return jsonb_build_object('ok', false, 'code', 'invalid_section');
  end if;

  if v_old_section_id = p_target_section_id then
    if p_target_sort_order > v_old_sort_order then
      update menu_items
      set sort_order = sort_order - 1
      where section_id = v_old_section_id
        and sort_order > v_old_sort_order
        and sort_order <= p_target_sort_order
        and id <> p_item_id;
    elsif p_target_sort_order < v_old_sort_order then
      update menu_items
      set sort_order = sort_order + 1
      where section_id = v_old_section_id
        and sort_order >= p_target_sort_order
        and sort_order < v_old_sort_order
        and id <> p_item_id;
    end if;
    update menu_items set sort_order = p_target_sort_order, updated_at = now() where id = p_item_id;
  else
    update menu_items
    set sort_order = sort_order - 1
    where section_id = v_old_section_id
      and sort_order > v_old_sort_order;

    update menu_items
    set sort_order = sort_order + 1
    where section_id = p_target_section_id
      and sort_order >= p_target_sort_order;

    update menu_items
    set section_id = p_target_section_id, sort_order = p_target_sort_order, updated_at = now()
    where id = p_item_id;
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.owner_reorder_menu_item_v1(uuid, uuid, int) from public;
grant execute on function public.owner_reorder_menu_item_v1(uuid, uuid, int) to authenticated;
revoke execute on function public.owner_reorder_menu_item_v1(uuid, uuid, int) from anon;
