-- Sadakat v1 — birleşik şema (damga+puan, tek RPC/UI yüzeyi).
-- bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

CREATE TABLE public.loyalty_programs (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid references public.businesses(id) on delete cascade,
  chain_id         uuid references public.chains(id) on delete cascade,
  mode             text not null check (mode in ('stamp','points')),
  name             text not null,
  reward_desc      text not null,
  reward_threshold int not null check (reward_threshold > 0),
  is_active        boolean not null default false,
  created_at       timestamptz not null default now(),
  constraint loyalty_programs_scope_check check (
    (business_id is not null and chain_id is null) or
    (business_id is null and chain_id is not null)
  )
);

CREATE UNIQUE INDEX idx_loyalty_programs_business ON public.loyalty_programs(business_id) WHERE business_id IS NOT NULL;
CREATE UNIQUE INDEX idx_loyalty_programs_chain ON public.loyalty_programs(chain_id) WHERE chain_id IS NOT NULL;

CREATE TABLE public.loyalty_members (
  id             uuid primary key default gen_random_uuid(),
  program_id     uuid not null references public.loyalty_programs(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  progress       int not null default 0,
  redeemed_count int not null default 0,
  updated_at     timestamptz not null default now(),
  unique (program_id, user_id)
);

CREATE INDEX idx_loyalty_members_user ON public.loyalty_members(user_id);

CREATE TABLE public.loyalty_events (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references public.loyalty_members(id) on delete cascade,
  source     text not null check (source in ('qr_scan','review','redeem')),
  amount     int not null,
  actor_id   uuid references auth.users(id),
  created_at timestamptz not null default now()
);

CREATE INDEX idx_loyalty_events_member ON public.loyalty_events(member_id);

ALTER TABLE public.loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_events   ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir (public read, mevcut desen); yazma yalnızca RPC üzerinden.
CREATE POLICY "loyalty_programs_public_read" ON public.loyalty_programs
  FOR SELECT USING (is_active = true);

-- Müşteri sadece kendi satırını görür; yazma yalnızca RPC üzerinden.
CREATE POLICY "loyalty_members_self_read" ON public.loyalty_members
  FOR SELECT USING (auth.uid() = user_id);

-- loyalty_events: hiçbir client rolüne GRANT yok — audit log, sadece SECURITY
-- DEFINER RPC'ler (get_business_loyalty_members_v1 vb.) içinden okunur/yazılır.

REVOKE ALL ON public.loyalty_programs FROM anon, authenticated;
REVOKE ALL ON public.loyalty_members  FROM anon, authenticated;
REVOKE ALL ON public.loyalty_events   FROM anon, authenticated;
GRANT SELECT ON public.loyalty_programs TO anon, authenticated;
GRANT SELECT ON public.loyalty_members  TO authenticated;

COMMENT ON TABLE public.loyalty_programs IS 'Bir işletmenin (business_id) veya zincirin (chain_id) sadakat programı — mode: stamp|points. Tam biri set olmalı.';
COMMENT ON TABLE public.loyalty_members IS 'Bir müşterinin bir programdaki ilerlemesi (damga sayısı veya puan).';
COMMENT ON TABLE public.loyalty_events IS 'Her ilerleme/kullanım olayının audit kaydı — kaynak: qr_scan|review|redeem.';
