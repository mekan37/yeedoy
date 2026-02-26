begin;

-- Reviews: keep public approved read, add admin override for update/delete.
drop policy if exists reviews_update_admin on public.reviews;
create policy reviews_update_admin
  on public.reviews
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists reviews_delete_admin on public.reviews;
create policy reviews_delete_admin
  on public.reviews
  for delete
  to authenticated
  using (public.is_admin());

-- Review votes: owner scope + admin override.
drop policy if exists review_votes_admin_all on public.review_votes;
create policy review_votes_admin_all
  on public.review_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Business suggestions:
-- approved visible to everyone; pending/non-approved visible only to owner/admin.
drop policy if exists business_suggestions_select_access on public.business_suggestions;
drop policy if exists business_suggestions_select_public_or_owner_admin on public.business_suggestions;
create policy business_suggestions_select_public_or_owner_admin
  on public.business_suggestions
  for select
  to public
  using (
    status = 'approved'
    or user_id = auth.uid()
    or public.is_admin()
  );

-- allow user to update/delete only own pending suggestion; admin keeps full control.
drop policy if exists business_suggestions_update_own_pending on public.business_suggestions;
create policy business_suggestions_update_own_pending
  on public.business_suggestions
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and status = 'pending'
  )
  with check (
    user_id = auth.uid()
    and status = 'pending'
  );

drop policy if exists business_suggestions_delete_own_pending on public.business_suggestions;
create policy business_suggestions_delete_own_pending
  on public.business_suggestions
  for delete
  to authenticated
  using (
    user_id = auth.uid()
    and status = 'pending'
  );

-- Menu item price suggestions:
-- approved public; pending visible to creator/owner/admin.
drop policy if exists price_sugg_select_access on public.menu_item_price_suggestions;
drop policy if exists price_sugg_select_public_or_actor on public.menu_item_price_suggestions;
create policy price_sugg_select_public_or_actor
  on public.menu_item_price_suggestions
  for select
  to public
  using (
    status::text = 'approved'
    or created_by = auth.uid()
    or public.is_admin()
    or public.is_owner_of_business(business_id)
  );

-- creator can update/delete only own pending rows; admin remains all-powerful.
drop policy if exists price_sugg_update_own_pending on public.menu_item_price_suggestions;
create policy price_sugg_update_own_pending
  on public.menu_item_price_suggestions
  for update
  to authenticated
  using (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  )
  with check (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  );

drop policy if exists price_sugg_delete_own_pending on public.menu_item_price_suggestions;
create policy price_sugg_delete_own_pending
  on public.menu_item_price_suggestions
  for delete
  to authenticated
  using (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  );

-- Price/photo/business-fee votes: ensure admin override exists consistently.
drop policy if exists menu_item_price_votes_admin_all on public.menu_item_price_votes;
create policy menu_item_price_votes_admin_all
  on public.menu_item_price_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists menu_item_photo_votes_admin_all on public.menu_item_photo_votes;
create policy menu_item_photo_votes_admin_all
  on public.menu_item_photo_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- owner_claims already enforces own/admin access, keep as is.
-- admin_audit_log already admin-only, keep as is.

commit;
