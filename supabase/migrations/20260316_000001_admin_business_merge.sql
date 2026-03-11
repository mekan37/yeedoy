-- Admin merge flow for duplicate business records.

create table if not exists public.business_merge_log (
  duplicate_business_id uuid primary key references public.businesses(id) on delete cascade,
  primary_business_id uuid not null references public.businesses(id) on delete cascade,
  merged_by uuid null,
  merged_at timestamptz not null default now(),
  note text null
);
create or replace function public.admin_merge_businesses_v1(
  p_primary_business_id uuid,
  p_duplicate_business_id uuid,
  p_admin_note text default null,
  p_dry_run boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_primary_exists boolean := false;
  v_duplicate_exists boolean := false;
  v_now timestamptz := now();
  v_summary jsonb;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_primary_business_id is null or p_duplicate_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;
  if p_primary_business_id = p_duplicate_business_id then
    return jsonb_build_object('ok', false, 'error', 'same_business');
  end if;

  select exists(select 1 from public.businesses b where b.id = p_primary_business_id)
    into v_primary_exists;
  select exists(select 1 from public.businesses b where b.id = p_duplicate_business_id)
    into v_duplicate_exists;

  if not v_primary_exists or not v_duplicate_exists then
    return jsonb_build_object('ok', false, 'error', 'business_not_found');
  end if;

  v_summary := jsonb_build_object(
    'menus', (select count(*) from public.menus where business_id = p_duplicate_business_id),
    'menu_items', (select count(*) from public.menu_items where business_id = p_duplicate_business_id),
    'reviews', (select count(*) from public.reviews where business_id = p_duplicate_business_id),
    'media', (select count(*) from public.business_media where business_id = p_duplicate_business_id),
    'stories', (select count(*) from public.business_stories where business_id = p_duplicate_business_id),
    'favorites', (select count(*) from public.favorites where business_id = p_duplicate_business_id),
    'follows', (select count(*) from public.business_follows where business_id = p_duplicate_business_id)
  );

  if p_dry_run then
    return jsonb_build_object(
      'ok', true,
      'dry_run', true,
      'summary', v_summary
    );
  end if;

  -- conflict-safe merge on tables with unique constraints.
  insert into public.business_follows(user_id, business_id, created_at)
  select bf.user_id, p_primary_business_id, bf.created_at
  from public.business_follows bf
  where bf.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_follows x
      where x.user_id = bf.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.business_follows where business_id = p_duplicate_business_id;

  insert into public.favorites(user_id, business_id, created_at)
  select f.user_id, p_primary_business_id, f.created_at
  from public.favorites f
  where f.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.favorites x
      where x.user_id = f.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.favorites where business_id = p_duplicate_business_id;

  insert into public.user_favorites_legacy(user_id, business_id, created_at)
  select f.user_id, p_primary_business_id, f.created_at
  from public.user_favorites_legacy f
  where f.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.user_favorites_legacy x
      where x.user_id = f.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.user_favorites_legacy where business_id = p_duplicate_business_id;

  insert into public.collection_items(collection_id, business_id, note, created_at)
  select c.collection_id, p_primary_business_id, c.note, c.created_at
  from public.collection_items c
  where c.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.collection_items x
      where x.collection_id = c.collection_id
        and x.business_id = p_primary_business_id
    );
  delete from public.collection_items where business_id = p_duplicate_business_id;

  insert into public.business_amenity_map(business_id, amenity_id)
  select p_primary_business_id, m.amenity_id
  from public.business_amenity_map m
  where m.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_amenity_map x
      where x.business_id = p_primary_business_id
        and x.amenity_id = m.amenity_id
    );
  delete from public.business_amenity_map where business_id = p_duplicate_business_id;

  update public.owner_claims oc
  set business_id = p_primary_business_id
  where oc.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.owner_claims x
      where x.user_id = oc.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.owner_claims where business_id = p_duplicate_business_id;

  -- one-row-per-business tables
  if exists(select 1 from public.business_hours where business_id = p_primary_business_id) then
    delete from public.business_hours where business_id = p_duplicate_business_id;
  else
    update public.business_hours
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.owner_onboarding_progress where business_id = p_primary_business_id) then
    delete from public.owner_onboarding_progress where business_id = p_duplicate_business_id;
  else
    update public.owner_onboarding_progress
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.business_stats where business_id = p_primary_business_id) then
    delete from public.business_stats where business_id = p_duplicate_business_id;
  else
    update public.business_stats
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  -- direct updates
  update public.analytics_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_activity_log set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_media set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_premium set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_presence_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_stories set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.feed_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_photos set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_price_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_items set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menus set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.reviews set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorship_leads set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorships set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.suspended_meals set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.table_feedback set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.visits set business_id = p_primary_business_id where business_id = p_duplicate_business_id;

  insert into public.business_merge_log(
    duplicate_business_id,
    primary_business_id,
    merged_by,
    merged_at,
    note
  ) values (
    p_duplicate_business_id,
    p_primary_business_id,
    auth.uid(),
    v_now,
    nullif(trim(coalesce(p_admin_note, '')), '')
  )
  on conflict (duplicate_business_id)
  do update set
    primary_business_id = excluded.primary_business_id,
    merged_by = excluded.merged_by,
    merged_at = excluded.merged_at,
    note = excluded.note;

  update public.businesses
  set
    is_active = false,
    source = 'merged',
    source_id = p_primary_business_id::text
  where id = p_duplicate_business_id;

  perform public.log_admin_action_v1(
    'business.merge',
    'businesses',
    p_duplicate_business_id,
    jsonb_build_object(
      'primary_business_id', p_primary_business_id,
      'duplicate_business_id', p_duplicate_business_id,
      'note', p_admin_note,
      'summary', v_summary
    )
  );

  return jsonb_build_object(
    'ok', true,
    'dry_run', false,
    'summary', v_summary
  );
end;
$$;
grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to anon;
grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to authenticated;
grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to service_role;
