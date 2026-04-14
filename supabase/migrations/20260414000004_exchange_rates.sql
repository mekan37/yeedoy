-- ─────────────────────────────────────────────────────────────────────────────
-- exchange_rates
-- Daily rates from TCMB (Turkish Central Bank) — TRY base.
-- 1 USD = try_rate TRY, 1 EUR = try_rate TRY
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.exchange_rates (
  currency    text        primary key,   -- 'USD' | 'EUR'
  try_rate    numeric     not null,      -- 1 unit of currency = X TRY
  source      text        not null default 'tcmb',
  fetched_at  timestamptz not null default now()
);

-- Public read — exchange rates are not sensitive
alter table public.exchange_rates enable row level security;

create policy "public_read_exchange_rates"
  on public.exchange_rates
  for select
  using (true);
