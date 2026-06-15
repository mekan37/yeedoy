-- Fix trg_audit_menus_cud_v1: it referenced NEW.name / NEW.is_active, but the
-- public.menus table has no such columns (it has title, status). This bug
-- caused every INSERT/UPDATE/DELETE on public.menus to fail with
-- "record \"new\" has no field \"name\"".
create or replace function public.trg_audit_menus_cud_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if TG_OP = 'INSERT' then
    perform public.insert_audit_log_v1(
      'menu.created',
      'menu',
      NEW.id,
      null,
      jsonb_build_object(
        'business_id', NEW.business_id,
        'title', NEW.title,
        'status', NEW.status
      )
    );
    return NEW;
  elsif TG_OP = 'UPDATE' then
    if row(NEW.title, NEW.status) is distinct from row(OLD.title, OLD.status) then
      perform public.insert_audit_log_v1(
        'menu.updated',
        'menu',
        NEW.id,
        jsonb_build_object(
          'title', OLD.title,
          'status', OLD.status
        ),
        jsonb_build_object(
          'title', NEW.title,
          'status', NEW.status
        )
      );
    end if;
    return NEW;
  else
    perform public.insert_audit_log_v1(
      'menu.deleted',
      'menu',
      OLD.id,
      jsonb_build_object(
        'business_id', OLD.business_id,
        'title', OLD.title,
        'status', OLD.status
      ),
      null
    );
    return OLD;
  end if;
end;
$function$;
