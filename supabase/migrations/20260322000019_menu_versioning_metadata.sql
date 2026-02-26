begin;

alter table if exists public.menus
  add column if not exists version int not null default 1,
  add column if not exists source text not null default 'owner',
  add column if not exists confidence_score numeric not null default 0,
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menus_source_check_v1'
  ) then
    alter table public.menus
      add constraint menus_source_check_v1
      check (source in ('owner', 'admin', 'user_promoted'));
  end if;
end $$;

create or replace function public.bump_menu_version_v1()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();

  if tg_op = 'INSERT' then
    new.version := coalesce(new.version, 1);
    new.source := coalesce(nullif(trim(coalesce(new.source, '')), ''), 'owner');
    new.confidence_score := greatest(0, least(1, coalesce(new.confidence_score, 0)));
    return new;
  end if;

  if (
    new.title is distinct from old.title
    or new.kind is distinct from old.kind
    or new.active_from is distinct from old.active_from
    or new.active_to is distinct from old.active_to
    or new.status is distinct from old.status
  ) then
    new.version := greatest(coalesce(old.version, 1) + 1, 1);
  else
    new.version := coalesce(old.version, 1);
  end if;

  new.source := coalesce(nullif(trim(coalesce(new.source, '')), ''), old.source, 'owner');
  new.confidence_score := greatest(0, least(1, coalesce(new.confidence_score, old.confidence_score, 0)));
  return new;
end;
$$;

drop trigger if exists trg_menus_versioning_v1 on public.menus;
create trigger trg_menus_versioning_v1
before insert or update on public.menus
for each row execute function public.bump_menu_version_v1();

commit;
