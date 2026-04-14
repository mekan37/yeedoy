-- Public dijital menü URL anahtarı
-- Amaç: /m/{public_slug} rotasını deterministik ve unique hale getirmek.

alter table public.businesses
  add column if not exists public_slug text;

create or replace function public._normalize_public_slug_v1(input text)
returns text
language sql
immutable
as $$
  select nullif(
    trim(
      both '-'
      from regexp_replace(
        regexp_replace(lower(coalesce(input, '')), '[^a-z0-9]+', '-', 'g'),
        '-{2,}',
        '-',
        'g'
      )
    ),
    ''
  )
$$;

create or replace function public._assign_business_public_slug_v1()
returns trigger
language plpgsql
as $$
declare
  base_slug text;
  candidate text;
  suffix int := 0;
begin
  base_slug := coalesce(
    public._normalize_public_slug_v1(new.public_slug),
    public._normalize_public_slug_v1(new.slug),
    public._normalize_public_slug_v1(new.name),
    substr(coalesce(new.id::text, gen_random_uuid()::text), 1, 12)
  );

  candidate := base_slug;
  while exists (
    select 1
    from public.businesses b
    where lower(b.public_slug) = lower(candidate)
      and (new.id is null or b.id <> new.id)
  ) loop
    suffix := suffix + 1;
    candidate := base_slug || '-' || suffix::text;
  end loop;

  new.public_slug := candidate;
  return new;
end;
$$;

drop trigger if exists trg_assign_business_public_slug_v1 on public.businesses;
create trigger trg_assign_business_public_slug_v1
before insert or update of name, slug, public_slug
on public.businesses
for each row
execute function public._assign_business_public_slug_v1();

update public.businesses
set public_slug = coalesce(public_slug, slug, name, id::text)
where public_slug is null or trim(public_slug) = '';

create unique index if not exists businesses_public_slug_unique_idx
  on public.businesses (lower(public_slug))
  where public_slug is not null;

