-- ─────────────────────────────────────────────────────────────────────────────
-- Security: Restrict overly broad "to public" policies to "to authenticated"
-- ─────────────────────────────────────────────────────────────────────────────
-- Several policies were created with "to public" which means the anon role
-- can reach the USING clause. Although is_admin() returns false for anon,
-- it still wastes a function call on every anon request and is a security
-- smell that could become a vulnerability if is_admin() is ever changed.
-- We scope them to "authenticated" only — anon should never hit admin paths.
-- ─────────────────────────────────────────────────────────────────────────────

-- analytics_events
drop policy if exists "analytics_events_admin_all" on public.analytics_events;
create policy "analytics_events_admin_all"
  on public.analytics_events
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- business_checkins (admin path only — public insert handled by RPC)
drop policy if exists "business_checkins_admin_all" on public.business_checkins;
create policy "business_checkins_admin_all"
  on public.business_checkins
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- business_fee_flags
drop policy if exists "business_fee_flags_admin_all" on public.business_fee_flags;
create policy "business_fee_flags_admin_all"
  on public.business_fee_flags
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- business_fee_votes
drop policy if exists "business_fee_votes_admin_all" on public.business_fee_votes;
create policy "business_fee_votes_admin_all"
  on public.business_fee_votes
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- business_hours — owner write paths should require authenticated
drop policy if exists "business_hours_owner_update" on public.business_hours;
create policy "business_hours_owner_update"
  on public.business_hours
  as permissive
  for update
  to authenticated
  using  ((public.is_admin() OR public.is_owner_of_business(business_id)))
  with check ((public.is_admin() OR public.is_owner_of_business(business_id)));

drop policy if exists "business_hours_owner_write" on public.business_hours;
create policy "business_hours_owner_write"
  on public.business_hours
  as permissive
  for insert
  to authenticated
  with check ((public.is_admin() OR public.is_owner_of_business(business_id)));

-- business_meal_card_providers
drop policy if exists "business_meal_card_providers_owner_delete" on public.business_meal_card_providers;
create policy "business_meal_card_providers_owner_delete"
  on public.business_meal_card_providers
  as permissive
  for delete
  to authenticated
  using ((public.is_admin() OR public.is_owner_of_business(business_id)));

drop policy if exists "business_meal_card_providers_owner_insert" on public.business_meal_card_providers;
create policy "business_meal_card_providers_owner_insert"
  on public.business_meal_card_providers
  as permissive
  for insert
  to authenticated
  with check ((public.is_admin() OR public.is_owner_of_business(business_id)));

drop policy if exists "business_meal_card_providers_owner_update" on public.business_meal_card_providers;
create policy "business_meal_card_providers_owner_update"
  on public.business_meal_card_providers
  as permissive
  for update
  to authenticated
  using ((public.is_admin() OR public.is_owner_of_business(business_id)))
  with check ((public.is_admin() OR public.is_owner_of_business(business_id)));

-- business_premium
drop policy if exists "business_premium_admin_all" on public.business_premium;
create policy "business_premium_admin_all"
  on public.business_premium
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- business_presence_events
drop policy if exists "business_presence_admin_select" on public.business_presence_events;
create policy "business_presence_admin_select"
  on public.business_presence_events
  as permissive
  for select
  to authenticated
  using (public.is_admin());

-- business_submissions
drop policy if exists "business_submissions_admin_all" on public.business_submissions;
create policy "business_submissions_admin_all"
  on public.business_submissions
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- admin_runtime_settings: was "to public" — restrict to authenticated
drop policy if exists "admin_runtime_settings_admin_all" on public.admin_runtime_settings;
create policy "admin_runtime_settings_admin_all"
  on public.admin_runtime_settings
  as permissive
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
