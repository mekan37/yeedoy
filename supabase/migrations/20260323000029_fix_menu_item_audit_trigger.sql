-- Fix legacy audit trigger against current menu_items schema
create or replace function public.trg_audit_menu_items_cud_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_menu_id uuid;
begin
  select s.menu_id into v_menu_id
  from public.menu_sections s
  where s.id = coalesce(new.section_id, old.section_id)
  limit 1;

  if TG_OP = 'INSERT' then
    perform public.insert_audit_log_v1(
      'menu_item.created',
      'menu_item',
      NEW.id,
      null,
      jsonb_build_object(
        'business_id', NEW.business_id,
        'menu_id', v_menu_id,
        'name', NEW.name,
        'price_cents', NEW.price_cents,
        'currency', NEW.currency,
        'is_available', NEW.is_available
      )
    );
    return NEW;
  elsif TG_OP = 'UPDATE' then
    if row(NEW.name, NEW.price_cents, NEW.currency, NEW.is_available)
       is distinct from
       row(OLD.name, OLD.price_cents, OLD.currency, OLD.is_available) then
      perform public.insert_audit_log_v1(
        'menu_item.updated',
        'menu_item',
        NEW.id,
        jsonb_build_object(
          'name', OLD.name,
          'price_cents', OLD.price_cents,
          'currency', OLD.currency,
          'is_available', OLD.is_available
        ),
        jsonb_build_object(
          'name', NEW.name,
          'price_cents', NEW.price_cents,
          'currency', NEW.currency,
          'is_available', NEW.is_available
        )
      );
    end if;
    return NEW;
  else
    perform public.insert_audit_log_v1(
      'menu_item.deleted',
      'menu_item',
      OLD.id,
      jsonb_build_object(
        'business_id', OLD.business_id,
        'menu_id', v_menu_id,
        'name', OLD.name,
        'price_cents', OLD.price_cents
      ),
      null
    );
    return OLD;
  end if;
end;
$$;
