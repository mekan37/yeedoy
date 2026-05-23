-- ─────────────────────────────────────────────────────────────────────────────
-- Security: RLS policies for tables created in 2026-05-07 migrations
-- that are missing proper access control.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── loyalty_programs ─────────────────────────────────────────────────────────
-- The 20260424000007 migration created loyalty_programs with RLS but:
--   1. loyalty_programs_public_read uses (true) — exposing inactive programs
--   2. loyalty_programs_owner_all is missing "to authenticated" (defaults to public)
-- We replace both. The 20260507000008 migration created a second loyalty_programs
-- table definition (IF NOT EXISTS guard). Normalize both.
alter table if exists public.loyalty_programs enable row level security;

-- Fix: restrict public read to active programs only
drop policy if exists "loyalty_programs_public_read" on public.loyalty_programs;
create policy "loyalty_programs_public_read"
  on public.loyalty_programs
  as permissive
  for select
  to anon, authenticated
  using (is_active = true);

-- Fix: restrict owner_all to authenticated only (was missing role spec)
drop policy if exists "loyalty_programs_owner_all" on public.loyalty_programs;
create policy "loyalty_programs_owner_all"
  on public.loyalty_programs
  as permissive
  for all
  to authenticated
  using  (public.is_admin() OR public.is_owner_of_business(business_id))
  with check (public.is_admin() OR public.is_owner_of_business(business_id));

drop policy if exists "loyalty_programs_owner_write" on public.loyalty_programs;
-- (legacy name from 20260507 — replaced by loyalty_programs_owner_all above)

-- ── loyalty_accounts ────────────────────────────────────────────────────────
-- 20260424000007 created loyalty_accounts_definer_write policy which incorrectly
-- uses "for all ... using (auth.uid() = user_id)" — this blocks SECURITY DEFINER
-- function writes for other users (e.g. owner awarding points to a customer).
-- Fix: remove the overly-restrictive write policy; writes go only through
-- SECURITY DEFINER functions (award_loyalty_points_v1) which bypass RLS.
alter table if exists public.loyalty_accounts enable row level security;

drop policy if exists "loyalty_accounts_definer_write" on public.loyalty_accounts;
create policy "loyalty_accounts_no_direct_write"
  on public.loyalty_accounts
  as permissive
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- Ensure self-read policy is scoped to authenticated only
drop policy if exists "loyalty_accounts_self_read" on public.loyalty_accounts;
create policy "loyalty_accounts_self_read"
  on public.loyalty_accounts
  as permissive
  for select
  to authenticated
  using (auth.uid() = user_id OR public.is_admin());

-- ── loyalty_cards ─────────────────────────────────────────────────────────────
-- Created in 20260507000008 without RLS policies.
-- Cards are accessed only through RPCs; no direct table access needed.
alter table if exists public.loyalty_cards enable row level security;

drop policy if exists "loyalty_cards_own_read" on public.loyalty_cards;
create policy "loyalty_cards_own_read"
  on public.loyalty_cards
  as permissive
  for select
  to authenticated
  using (user_id = auth.uid() OR public.is_admin());

-- No direct insert/update/delete — only via add_loyalty_stamp_v1 (SECURITY DEFINER).
drop policy if exists "loyalty_cards_no_direct_write" on public.loyalty_cards;
create policy "loyalty_cards_no_direct_write"
  on public.loyalty_cards
  as permissive
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ── table_orders ──────────────────────────────────────────────────────────────
-- table_orders was created in 20260507000006 and a "no_direct_access" policy
-- was added in 20260520000003_rls_policy_baseline.sql. Verify it is present
-- and also add owner read access so dashboard queries work.
-- The baseline migration already blocks direct anon/auth access. We supplement
-- with a SECURITY DEFINER owner-read path.

-- Owner read: let owners fetch their own business orders directly if needed.
drop policy if exists "table_orders_owner_read" on public.table_orders;
create policy "table_orders_owner_read"
  on public.table_orders
  as permissive
  for select
  to authenticated
  using (public.is_admin() OR public.is_owner_of_business(business_id));

-- Admin full access
drop policy if exists "table_orders_admin_all" on public.table_orders;
create policy "table_orders_admin_all"
  on public.table_orders
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ── visits ────────────────────────────────────────────────────────────────────
-- Ensure the visits table has proper RLS (created in 20260507000002_check_in).
alter table if exists public.visits enable row level security;

drop policy if exists "visits_own_read" on public.visits;
create policy "visits_own_read"
  on public.visits
  as permissive
  for select
  to authenticated
  using (user_id = auth.uid() OR public.is_admin());

drop policy if exists "visits_no_direct_write" on public.visits;
create policy "visits_no_direct_write"
  on public.visits
  as permissive
  for all
  to anon, authenticated
  using (false)
  with check (false);

-- ── push_campaigns ────────────────────────────────────────────────────────────
-- Guard push_campaigns if it exists (created in personel app migrations).
do $$
begin
  if exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'push_campaigns'
  ) then
    execute 'alter table public.push_campaigns enable row level security';
    execute $pol$
      drop policy if exists "push_campaigns_owner_all" on public.push_campaigns;
      create policy "push_campaigns_owner_all"
        on public.push_campaigns
        as permissive
        for all
        to authenticated
        using (public.is_admin() or public.is_owner_of_business(business_id))
        with check (public.is_admin() or public.is_owner_of_business(business_id))
    $pol$;
  end if;
end $$;

-- ── email_campaigns ───────────────────────────────────────────────────────────
do $$
begin
  if exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'email_campaigns'
  ) then
    execute 'alter table public.email_campaigns enable row level security';
    execute $pol$
      drop policy if exists "email_campaigns_owner_all" on public.email_campaigns;
      create policy "email_campaigns_owner_all"
        on public.email_campaigns
        as permissive
        for all
        to authenticated
        using (public.is_admin() or public.is_owner_of_business(business_id))
        with check (public.is_admin() or public.is_owner_of_business(business_id))
    $pol$;
  end if;
end $$;
