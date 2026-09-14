-- Sahip Paneli Güvenlik Denetimi P1: Çöp Kutusu, "silinmiş" ürünü
-- is_available=false ile aynı kolonla tanımlıyordu — bu da menü
-- editöründeki günlük "Pasif yap" işlemiyle (mevsimlik ürünleri gizleme
-- gibi normal bir kullanım) AYNI kolon. Sonuç: sahip 40 mevsimlik ürünü
-- pasif yapınca Çöp Kutusu'nda "silinmiş" görünüyor, "Çöp Kutusunu
-- Boşalt" bunları kalıcı olarak yok ediyordu — kötü niyet gerekmeden,
-- normal kullanımda tetiklenen geri dönüşsüz veri kaybı. Ayrıca
-- deleteItem/bulkDeleteItems (menu-islemleri.ts) hiçbir trash
-- aşamasından geçmeden DOĞRUDAN kalıcı silme yapıyordu — "Geri
-- Yükle"/"Kalıcı Sil" iki aşamalı modeli item'lar için fiilen hiç
-- çalışmıyordu.
--
-- Fotoğraflarda zaten var olan doğru desen (deleted_at/deleted_by,
-- owner_soft_delete_menu_item_photo_v1 / owner_restore_menu_item_photo_v1)
-- menu_items'a da uygulandı. is_available artık yalnızca "aktif/pasif"
-- anlamına geliyor; "silinmiş" ayrı bir deleted_at kolonuyla temsil
-- ediliyor. Mevcut pasif ürünler deleted_at=NULL ile başladığı için bu
-- migration onları çöp kutusuna almıyor (geriye dönük veri kaybı yok).
alter table menu_items
  add column deleted_at timestamptz,
  add column deleted_by uuid references auth.users(id);

create or replace function public.owner_soft_delete_menu_item_v1(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
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

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menu_items
  set deleted_at = now(),
      deleted_by = auth.uid(),
      is_available = false
  where id = p_item_id
    and deleted_at is null;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'already_deleted');
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id);
end;
$$;

revoke all on function public.owner_soft_delete_menu_item_v1(uuid) from public;
grant execute on function public.owner_soft_delete_menu_item_v1(uuid) to authenticated;
revoke execute on function public.owner_soft_delete_menu_item_v1(uuid) from anon;

create or replace function public.owner_restore_menu_item_v1(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
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

  if not (public.is_admin() or public.has_business_permission_v1(v_business_id, 'menu_write')) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.menu_items
  set deleted_at = null,
      deleted_by = null,
      is_available = true,
      updated_at = now()
  where id = p_item_id
    and deleted_at is not null;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_deleted');
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id);
end;
$$;

create or replace function public.owner_permanently_delete_menu_item_v1(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_business_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  SELECT business_id INTO v_business_id FROM public.menu_items WHERE id = p_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_found');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(v_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  DELETE FROM public.menu_items WHERE id = p_item_id AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_archived');
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', p_item_id);
END;
$function$;

create or replace function public.owner_empty_trash_v1(p_business_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_menus   int;
  v_items   int;
  v_photos  int;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_authenticated');
  END IF;

  IF NOT (public.is_admin() OR public.has_business_permission_v1(p_business_id, 'menu_write')) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'not_owner');
  END IF;

  WITH deleted AS (
    DELETE FROM public.menus WHERE business_id = p_business_id AND status = 'archived' RETURNING id
  )
  SELECT count(*) INTO v_menus FROM deleted;

  WITH deleted AS (
    DELETE FROM public.menu_items WHERE business_id = p_business_id AND deleted_at IS NOT NULL RETURNING id
  )
  SELECT count(*) INTO v_items FROM deleted;

  WITH deleted AS (
    DELETE FROM public.menu_item_photos WHERE business_id = p_business_id AND deleted_at IS NOT NULL RETURNING id
  )
  SELECT count(*) INTO v_photos FROM deleted;

  RETURN jsonb_build_object('ok', true, 'menus', v_menus, 'items', v_items, 'photos', v_photos);
END;
$function$;

create or replace function public.list_owner_menu_trash_v1(p_business_id uuid)
returns table(entity_type text, entity_id uuid, title text, subtitle text, occurred_at timestamp with time zone, menu_id uuid, menu_item_id uuid, photo_url text)
language sql
stable security definer
set search_path to 'public'
as $function$
  with permission_check as (
    select
      public.is_admin() as is_admin,
      public.has_business_permission_v1(p_business_id, 'business_read') as can_read
  )
  select *
  from (
    select
      'menu'::text as entity_type,
      m.id as entity_id,
      m.title,
      'Menü'::text as subtitle,
      coalesce(m.updated_at, m.created_at) as occurred_at,
      m.id as menu_id,
      null::uuid as menu_item_id,
      null::text as photo_url
    from public.menus m, permission_check pc
    where m.business_id = p_business_id
      and m.status = 'archived'
      and (pc.is_admin or pc.can_read)

    union all

    select
      'item'::text as entity_type,
      i.id as entity_id,
      i.name as title,
      coalesce(ms.title, 'Bölüm') || ' • ' || coalesce(m.title, 'Menü') as subtitle,
      coalesce(i.deleted_at, i.updated_at, i.created_at) as occurred_at,
      ms.menu_id as menu_id,
      i.id as menu_item_id,
      null::text as photo_url
    from public.menu_items i
    join public.menu_sections ms on ms.id = i.section_id
    join public.menus m on m.id = ms.menu_id,
    permission_check pc
    where i.business_id = p_business_id
      and i.deleted_at is not null
      and (pc.is_admin or pc.can_read)

    union all

    select
      'photo'::text as entity_type,
      p.id as entity_id,
      coalesce(mi.name, 'Ürün fotoğrafı') as title,
      'Fotoğraf'::text as subtitle,
      p.deleted_at as occurred_at,
      ms.menu_id as menu_id,
      p.menu_item_id,
      coalesce(nullif(p.url_thumb, ''), nullif(p.url_large, ''), p.url) as photo_url
    from public.menu_item_photos p
    join public.menu_items mi on mi.id = p.menu_item_id
    join public.menu_sections ms on ms.id = mi.section_id,
    permission_check pc
    where p.business_id = p_business_id
      and p.deleted_at is not null
      and (pc.is_admin or pc.can_read)
  ) rows
  order by occurred_at desc nulls last;
$function$;
