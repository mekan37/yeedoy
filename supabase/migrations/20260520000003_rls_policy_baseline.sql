-- Replace implicit "RLS enabled but no policies" with explicit access rules.

drop policy if exists "temp_uploads_admin_all" on public.temp_uploads;
create policy "temp_uploads_admin_all"
  on public.temp_uploads
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "client_mutation_idempotency_keys_no_direct_access" on public.client_mutation_idempotency_keys;
create policy "client_mutation_idempotency_keys_no_direct_access"
  on public.client_mutation_idempotency_keys
  for all
  to anon, authenticated
  using (false)
  with check (false);

drop policy if exists "favorite_revisit_reminders_sent_no_direct_access" on public.favorite_revisit_reminders_sent;
create policy "favorite_revisit_reminders_sent_no_direct_access"
  on public.favorite_revisit_reminders_sent
  for all
  to anon, authenticated
  using (false)
  with check (false);

drop policy if exists "loyalty_cards_no_direct_access" on public.loyalty_cards;
create policy "loyalty_cards_no_direct_access"
  on public.loyalty_cards
  for all
  to anon, authenticated
  using (false)
  with check (false);

drop policy if exists "menu_snapshots_no_direct_access" on public.menu_snapshots;
create policy "menu_snapshots_no_direct_access"
  on public.menu_snapshots
  for all
  to anon, authenticated
  using (false)
  with check (false);

drop policy if exists "rate_limit_buckets_no_direct_access" on public.rate_limit_buckets;
create policy "rate_limit_buckets_no_direct_access"
  on public.rate_limit_buckets
  for all
  to anon, authenticated
  using (false)
  with check (false);

drop policy if exists "table_orders_no_direct_access" on public.table_orders;
create policy "table_orders_no_direct_access"
  on public.table_orders
  for all
  to anon, authenticated
  using (false)
  with check (false);
