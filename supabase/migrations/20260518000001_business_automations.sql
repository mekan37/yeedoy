create table if not exists business_automations (
  id             uuid primary key default gen_random_uuid(),
  business_id    uuid not null references businesses(id) on delete cascade,
  template_id    text not null,
  is_enabled     boolean not null default true,
  config         jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (business_id, template_id)
);

alter table business_automations enable row level security;

-- 2026-07-23 fix: "business_owners" tablosu hiç var olmadı (proje genelinde
-- sahiplik public.is_owner_of_business()/owner_claims üzerinden kontrol
-- ediliyor) — zaten var olan, aynı işi yapan yardımcı fonksiyona geçildi.
drop policy if exists "owner_manage_automations" on business_automations;
create policy "owner_manage_automations" on business_automations
  using (public.is_owner_of_business(business_id))
  with check (public.is_owner_of_business(business_id));

create index if not exists idx_business_automations_business_id
  on business_automations (business_id);
