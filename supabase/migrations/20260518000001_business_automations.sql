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

create policy "owner_manage_automations" on business_automations
  using (
    exists (
      select 1 from business_owners
      where business_owners.business_id = business_automations.business_id
        and business_owners.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from business_owners
      where business_owners.business_id = business_automations.business_id
        and business_owners.user_id = auth.uid()
    )
  );

create index if not exists idx_business_automations_business_id
  on business_automations (business_id);
