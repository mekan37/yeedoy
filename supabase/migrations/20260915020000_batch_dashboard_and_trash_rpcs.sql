-- Sahip Paneli Güvenlik Denetimi P3 (son kalem): çoklu şubeli sahiplerde
-- gösterge panosu ve çöp kutusu, işletme başına ayrı bir RPC dalgası
-- tetikliyordu (Promise.all(selectedIds.map(id => rpc(...)))) — N şubeli
-- bir sahip N ayrı round-trip yapıyordu. Üçü de zaten sahiplik/izin
-- kontrolünü tek işletme başına yapıyordu; burada aynı mantığı
-- p_business_ids uuid[] üzerinden tekilleştiriyoruz — davranış birebir
-- aynı, yalnızca round-trip sayısı 1'e iniyor.

-- ── get_business_hours_v1'in batch hali: gösterge panosunda "bugün açık
-- mı + kapanış saati" için şube başına ayrı çağrılıyordu. Bu fonksiyon
-- zaten public (anon dahil) okunabilir olduğu için ek bir yetki kontrolü
-- gerekmiyor — orijinaliyle birebir aynı hesaplama, sadece unnest edilmiş.
create or replace function public.get_business_hours_batch_v1(p_business_ids uuid[])
returns table(business_id uuid, weekly jsonb, special jsonb, is_open_now boolean)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    b.id as business_id,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'day_of_week', bh.day_of_week,
          'open_time', to_char(bh.open_time, 'HH24:MI'),
          'close_time', to_char(bh.close_time, 'HH24:MI'),
          'is_closed', bh.is_closed
        ) order by bh.day_of_week
      )
      from public.business_weekly_hours bh
      where bh.business_id = b.id
    ), '[]'::jsonb) as weekly,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'date', sh.special_date,
          'open_time', to_char(sh.open_time, 'HH24:MI'),
          'close_time', to_char(sh.close_time, 'HH24:MI'),
          'is_closed', sh.is_closed,
          'note', sh.note
        ) order by sh.special_date
      )
      from public.business_special_hours sh
      where sh.business_id = b.id
        and sh.special_date >= current_date
    ), '[]'::jsonb) as special,
    (
      select
        case
          when exists (
            select 1 from public.business_special_hours sh
            where sh.business_id = b.id and sh.special_date = current_date
          ) then (
            select not sh.is_closed
              and sh.open_time is not null
              and current_time between sh.open_time and sh.close_time
            from public.business_special_hours sh
            where sh.business_id = b.id and sh.special_date = current_date
          )
          when exists (
            select 1 from public.business_weekly_hours bh
            where bh.business_id = b.id
              and bh.day_of_week = extract(dow from current_timestamp at time zone 'Europe/Istanbul')::smallint
          ) then (
            select not bh.is_closed
              and (current_timestamp at time zone 'Europe/Istanbul')::time between bh.open_time and bh.close_time
            from public.business_weekly_hours bh
            where bh.business_id = b.id
              and bh.day_of_week = extract(dow from current_timestamp at time zone 'Europe/Istanbul')::smallint
          )
          else null
        end
    ) as is_open_now
  from unnest(p_business_ids) as b(id);
$function$;

revoke all on function public.get_business_hours_batch_v1(uuid[]) from public;
grant execute on function public.get_business_hours_batch_v1(uuid[]) to anon, authenticated;

-- ── list_owner_menu_trash_v1'in batch hali: çöp kutusu sayfası şube
-- başına ayrı çağırıyordu. Yetki kontrolü (business_read) her işletme
-- için ayrı ayrı uygulanıyor — bir işletmeye erişimi olmayan sahip o
-- işletmenin satırlarını hiç görmez (tek-tek çağrıyla birebir aynı
-- güvenlik semantiği).
create or replace function public.list_owner_menu_trash_batch_v1(p_business_ids uuid[])
returns table(business_id uuid, entity_type text, entity_id uuid, title text, subtitle text, occurred_at timestamp with time zone, menu_id uuid, menu_item_id uuid, photo_url text)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with allowed_business as (
    select bid
    from unnest(p_business_ids) as bid
    where public.is_admin() or public.has_business_permission_v1(bid, 'business_read')
  )
  select *
  from (
    select
      m.business_id,
      'menu'::text as entity_type,
      m.id as entity_id,
      m.title,
      'Menü'::text as subtitle,
      coalesce(m.updated_at, m.created_at) as occurred_at,
      m.id as menu_id,
      null::uuid as menu_item_id,
      null::text as photo_url
    from public.menus m
    join allowed_business ab on ab.bid = m.business_id
    where m.status = 'archived'

    union all

    select
      i.business_id,
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
    join public.menus m on m.id = ms.menu_id
    join allowed_business ab on ab.bid = i.business_id
    where i.deleted_at is not null

    union all

    select
      p.business_id,
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
    join public.menu_sections ms on ms.id = mi.section_id
    join allowed_business ab on ab.bid = p.business_id
    where p.deleted_at is not null
  ) rows
  order by occurred_at desc nulls last;
$function$;

revoke all on function public.list_owner_menu_trash_batch_v1(uuid[]) from public;
grant execute on function public.list_owner_menu_trash_batch_v1(uuid[]) to authenticated;
revoke execute on function public.list_owner_menu_trash_batch_v1(uuid[]) from anon;
