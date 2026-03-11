-- schema.sql
create extension if not exists pgcrypto;

create type public.translation_entity_type as enum ('business', 'category', 'item');
create type public.qr_asset_type as enum ('svg', 'png', 'poster_pdf');

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  name text not null,
  slug text not null,
  public_slug text not null,
  city text,
  district text,
  address text,
  phone text,
  logo_url text,
  currency text not null default 'TRY',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint businesses_slug_unique unique (slug),
  constraint businesses_public_slug_unique unique (public_slug)
);

create table if not exists public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  sort int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_id uuid not null references public.menu_categories(id) on delete cascade,
  price_cents int not null check (price_cents >= 0),
  is_available boolean not null default true,
  image_url text,
  tags jsonb not null default '[]'::jsonb,
  sort int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.menu_translations (
  id uuid primary key default gen_random_uuid(),
  entity_type public.translation_entity_type not null,
  entity_id uuid not null,
  locale text not null,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  constraint menu_translations_unique unique (entity_type, entity_id, locale)
);

create table if not exists public.menu_settings (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  theme_id text not null default 'minimal',
  primary_color text not null default '#0f172a',
  show_prices boolean not null default true,
  show_allergens boolean not null default false,
  default_locale text not null default 'tr',
  supported_locales text[] not null default array['tr','en']::text[],
  updated_at timestamptz not null default now()
);

create table if not exists public.qr_assets (
  business_id uuid not null references public.businesses(id) on delete cascade,
  type public.qr_asset_type not null,
  path text not null,
  updated_at timestamptz not null default now(),
  primary key (business_id, type)
);

create table if not exists public.qr_links (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  business_id uuid not null references public.businesses(id) on delete cascade,
  locale text not null default 'tr',
  created_at timestamptz not null default now()
);

create index if not exists idx_menu_categories_business_id on public.menu_categories (business_id, sort);
create index if not exists idx_menu_items_business_id on public.menu_items (business_id, category_id, sort);
create index if not exists idx_menu_translations_entity on public.menu_translations (entity_type, entity_id, locale);
create index if not exists idx_menu_settings_business_id on public.menu_settings (business_id);
create index if not exists idx_qr_assets_business_id on public.qr_assets (business_id);
create index if not exists idx_qr_links_business_id on public.qr_links (business_id);

create or replace function public.tg_set_timestamp()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_menu_settings_updated_at on public.menu_settings;
create trigger trg_menu_settings_updated_at
before update on public.menu_settings
for each row execute function public.tg_set_timestamp();

insert into storage.buckets (id, name, public)
values ('menu-assets', 'menu-assets', true)
on conflict (id) do nothing;
