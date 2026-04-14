-- Business slug/public slug verisini mevcut kayitlar icin doldurur
-- ve yeni/degisen kayitlar icin canonical token trigger'ini kurar.

create or replace function public._allocate_business_slug_token_v1(desired text, current_business_id uuid)
returns text
language plpgsql
as $$
declare
  base_slug text := coalesce(
    public._normalize_public_slug_v1(desired),
    substr(coalesce(current_business_id::text, gen_random_uuid()::text), 1, 12)
  );
  candidate text := base_slug;
  suffix int := 0;
begin
  while exists (
    select 1
    from public.businesses b
    where (current_business_id is null or b.id <> current_business_id)
      and (
        lower(coalesce(b.slug, '')) = lower(candidate)
        or lower(coalesce(b.public_slug, '')) = lower(candidate)
      )
  ) loop
    suffix := suffix + 1;
    candidate := base_slug || '-' || suffix::text;
  end loop;

  return candidate;
end;
$$;

with base as (
  select
    b.id,
    coalesce(
      public._normalize_public_slug_v1(coalesce(nullif(trim(b.public_slug), ''), nullif(trim(b.slug), ''), b.name)),
      substr(b.id::text, 1, 12)
    ) as base_slug,
    substr(replace(b.id::text, '-', ''), 1, 12) as id_suffix
  from public.businesses b
),
resolved as (
  select
    id,
    case
      when base_slug like '%' || id_suffix then base_slug
      else base_slug || '-' || id_suffix
    end as canonical_slug
  from base
)
update public.businesses b
set slug = r.canonical_slug,
    public_slug = r.canonical_slug
from resolved r
where b.id = r.id
  and (
    b.slug is null
    or trim(b.slug) = ''
    or b.public_slug is null
    or trim(b.public_slug) = ''
  );

create or replace function public._assign_business_public_slug_v2()
returns trigger
language plpgsql
as $$
declare
  desired text;
  candidate text;
begin
  desired := coalesce(new.public_slug, new.slug, new.name, new.id::text);
  candidate := public._allocate_business_slug_token_v1(desired, new.id);

  -- Web resolver'i slug ve public_slug alanlarini ayni public token olarak ele alir.
  new.slug := candidate;
  new.public_slug := candidate;
  return new;
end;
$$;

drop trigger if exists trg_assign_business_public_slug_v1 on public.businesses;
drop trigger if exists trg_assign_business_public_slug_v2 on public.businesses;
create trigger trg_assign_business_public_slug_v2
before insert or update of name, slug, public_slug
on public.businesses
for each row
execute function public._assign_business_public_slug_v2();

create unique index if not exists businesses_slug_unique_idx
  on public.businesses (lower(slug))
  where slug is not null;

create unique index if not exists businesses_public_slug_unique_idx
  on public.businesses (lower(public_slug))
  where public_slug is not null;
