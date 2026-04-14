-- Business slug/public slug alanlarini aktif schema'ya ekler.
-- Amaç: web public route select kontratinin mevcut projede calismasi.

alter table public.businesses
  add column if not exists slug text,
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
$$;;
