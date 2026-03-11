begin;
create or replace function public.ensure_default_section_for_business_v1(
  p_business_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_menu_id uuid;
  v_section_id uuid;
begin
  select id
    into v_menu_id
  from public.menus
  where business_id = p_business_id
  order by created_at asc
  limit 1;

  if v_menu_id is null then
    insert into public.menus (business_id, title, status, created_by)
    values (p_business_id, 'Menü', 'published', auth.uid())
    returning id into v_menu_id;
  end if;

  select id
    into v_section_id
  from public.menu_sections
  where menu_id = v_menu_id
  order by sort_order asc, created_at asc
  limit 1;

  if v_section_id is null then
    insert into public.menu_sections (menu_id, title, sort_order, created_by)
    values (v_menu_id, 'Genel', 0, auth.uid())
    returning id into v_section_id;
  end if;

  return v_section_id;
end;
$$;
create or replace function public.menu_items_assign_section_v1()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_section_business_id uuid;
begin
  if new.section_id is null then
    new.section_id := public.ensure_default_section_for_business_v1(new.business_id);
  end if;

  select m.business_id
    into v_section_business_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = new.section_id
  limit 1;

  if v_section_business_id is null then
    raise exception 'invalid_section_id';
  end if;

  if v_section_business_id <> new.business_id then
    raise exception 'section_business_mismatch';
  end if;

  return new;
end;
$$;
drop trigger if exists trg_menu_items_assign_section on public.menu_items;
create trigger trg_menu_items_assign_section
before insert or update of section_id, business_id
on public.menu_items
for each row
execute function public.menu_items_assign_section_v1();
commit;
