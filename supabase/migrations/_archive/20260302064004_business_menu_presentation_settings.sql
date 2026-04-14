create table if not exists public.business_menu_presentation_settings (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  default_lang text not null default 'tr',
  template_key text not null default 'bold',
  settings jsonb not null default '{}'::jsonb,
  logo_url text,
  cover_url text,
  background_url text,
  constraint business_menu_presentation_settings_default_lang_check
    check (lower(default_lang) in ('tr', 'en')),
  constraint business_menu_presentation_settings_template_key_check
    check (char_length(btrim(template_key)) > 0),
  constraint business_menu_presentation_settings_settings_object_check
    check (jsonb_typeof(settings) = 'object')
);

create or replace function public.touch_updated_at_v1()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_business_menu_presentation_settings_touch_v1
on public.business_menu_presentation_settings;
create trigger trg_business_menu_presentation_settings_touch_v1
before update on public.business_menu_presentation_settings
for each row
execute function public.touch_updated_at_v1();

alter table public.business_menu_presentation_settings enable row level security;

drop policy if exists business_menu_presentation_settings_read_all
on public.business_menu_presentation_settings;
create policy business_menu_presentation_settings_read_all
on public.business_menu_presentation_settings
for select
to public
using (true);

drop policy if exists business_menu_presentation_settings_insert_manage
on public.business_menu_presentation_settings;
create policy business_menu_presentation_settings_insert_manage
on public.business_menu_presentation_settings
for insert
to authenticated
with check (public.can_manage_business_v1(business_id));

drop policy if exists business_menu_presentation_settings_update_manage
on public.business_menu_presentation_settings;
create policy business_menu_presentation_settings_update_manage
on public.business_menu_presentation_settings
for update
to authenticated
using (public.can_manage_business_v1(business_id))
with check (public.can_manage_business_v1(business_id));

drop policy if exists business_menu_presentation_settings_delete_manage
on public.business_menu_presentation_settings;
create policy business_menu_presentation_settings_delete_manage
on public.business_menu_presentation_settings
for delete
to authenticated
using (public.can_manage_business_v1(business_id));

grant select on public.business_menu_presentation_settings to anon;
grant select on public.business_menu_presentation_settings to authenticated;
grant insert, update, delete on public.business_menu_presentation_settings to authenticated;;
