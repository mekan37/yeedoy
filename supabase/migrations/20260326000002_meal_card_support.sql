create table if not exists public.meal_card_providers (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  asset_name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.business_meal_card_providers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  provider_id uuid not null references public.meal_card_providers(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (business_id, provider_id)
);

create index if not exists meal_card_providers_active_sort_idx
  on public.meal_card_providers (is_active, sort_order, name);

create index if not exists business_meal_card_providers_business_id_idx
  on public.business_meal_card_providers (business_id);

create index if not exists business_meal_card_providers_provider_id_idx
  on public.business_meal_card_providers (provider_id);

insert into public.meal_card_providers (
  key,
  name,
  asset_name,
  is_active,
  sort_order
)
values
  ('multinet', 'MultiNet', 'meal_card_multinet.png', true, 10),
  ('edenred', 'Edenred', 'meal_card_edenred.png', true, 20),
  ('tokenflex', 'TokenFlex', 'meal_card_tokenflex.png', true, 30),
  ('setcard', 'Setcard', 'meal_card_setcard.png', true, 40),
  ('pluxee', 'Pluxee', 'meal_card_pluxee.png', true, 50),
  ('metropol', 'Metropol', 'meal_card_metropol.png', true, 60),
  ('yemekmatik', 'Yemekmatik', 'meal_card_yemekmatik.png', true, 70)
on conflict (key) do update
set
  name = excluded.name,
  asset_name = excluded.asset_name,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order;

alter table public.meal_card_providers enable row level security;
alter table public.business_meal_card_providers enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'meal_card_providers'
      and policyname = 'meal_card_providers_read_all'
  ) then
    execute 'create policy meal_card_providers_read_all on public.meal_card_providers
      for select using (true)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'meal_card_providers'
      and policyname = 'meal_card_providers_admin_insert'
  ) then
    execute 'create policy meal_card_providers_admin_insert on public.meal_card_providers
      for insert with check (public.is_admin())';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'meal_card_providers'
      and policyname = 'meal_card_providers_admin_update'
  ) then
    execute 'create policy meal_card_providers_admin_update on public.meal_card_providers
      for update using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'meal_card_providers'
      and policyname = 'meal_card_providers_admin_delete'
  ) then
    execute 'create policy meal_card_providers_admin_delete on public.meal_card_providers
      for delete using (public.is_admin())';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'business_meal_card_providers'
      and policyname = 'business_meal_card_providers_read_all'
  ) then
    execute 'create policy business_meal_card_providers_read_all on public.business_meal_card_providers
      for select using (true)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'business_meal_card_providers'
      and policyname = 'business_meal_card_providers_owner_insert'
  ) then
    execute 'create policy business_meal_card_providers_owner_insert on public.business_meal_card_providers
      for insert with check (public.is_admin() or public.is_owner_of_business(business_id))';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'business_meal_card_providers'
      and policyname = 'business_meal_card_providers_owner_update'
  ) then
    execute 'create policy business_meal_card_providers_owner_update on public.business_meal_card_providers
      for update using (public.is_admin() or public.is_owner_of_business(business_id))
      with check (public.is_admin() or public.is_owner_of_business(business_id))';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'business_meal_card_providers'
      and policyname = 'business_meal_card_providers_owner_delete'
  ) then
    execute 'create policy business_meal_card_providers_owner_delete on public.business_meal_card_providers
      for delete using (public.is_admin() or public.is_owner_of_business(business_id))';
  end if;
end $$;

create or replace function public.get_business_meal_card_providers_v1(
  p_business_id uuid
)
returns table(
  provider_id uuid,
  key text,
  name text,
  asset_name text,
  sort_order integer
)
language sql
stable
security definer
set search_path = public
as $function$
  select
    p.id as provider_id,
    p.key,
    p.name,
    p.asset_name,
    p.sort_order
  from public.business_meal_card_providers bmp
  join public.meal_card_providers p
    on p.id = bmp.provider_id
  where bmp.business_id = p_business_id
    and p.is_active = true
  order by p.sort_order asc, p.name asc;
$function$;

create or replace function public.get_business_meal_card_provider_rows_v1(
  p_business_ids uuid[],
  p_provider_keys text[] default null
)
returns table(
  business_id uuid,
  provider_id uuid,
  key text,
  name text,
  asset_name text,
  sort_order integer
)
language sql
stable
security definer
set search_path = public
as $function$
  select
    bmp.business_id,
    p.id as provider_id,
    p.key,
    p.name,
    p.asset_name,
    p.sort_order
  from public.business_meal_card_providers bmp
  join public.meal_card_providers p
    on p.id = bmp.provider_id
  where coalesce(array_length(p_business_ids, 1), 0) > 0
    and bmp.business_id = any(p_business_ids)
    and p.is_active = true
    and (
      p_provider_keys is null
      or array_length(p_provider_keys, 1) is null
      or p.key = any(p_provider_keys)
    )
  order by bmp.business_id asc, p.sort_order asc, p.name asc;
$function$;

create or replace function public.owner_update_business_meal_card_providers_v1(
  p_business_id uuid,
  p_provider_keys text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
begin
  if auth.uid() is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'not_authenticated',
      'message', 'Auth required'
    );
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object(
      'ok', false,
      'code', 'not_owner',
      'message', 'Not owner'
    );
  end if;

  delete from public.business_meal_card_providers
  where business_id = p_business_id;

  if p_provider_keys is not null and array_length(p_provider_keys, 1) is not null then
    insert into public.business_meal_card_providers (
      business_id,
      provider_id
    )
    select
      p_business_id,
      p.id
    from public.meal_card_providers p
    where p.is_active = true
      and p.key = any(p_provider_keys)
    on conflict (business_id, provider_id) do nothing;
  end if;

  return jsonb_build_object(
    'ok', true,
    'business_id', p_business_id
  );
end;
$function$;

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
    'follows', (select count(*) from public.business_follows where business_id = p_duplicate_business_id),
    'meal_cards', (select count(*) from public.business_meal_card_providers where business_id = p_duplicate_business_id)
  );

  if p_dry_run then
    return jsonb_build_object(
      'ok', true,
      'dry_run', true,
      'summary', v_summary
    );
  end if;

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

  insert into public.business_meal_card_providers(
    business_id,
    provider_id,
    created_at
  )
  select
    p_primary_business_id,
    m.provider_id,
    m.created_at
  from public.business_meal_card_providers m
  where m.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_meal_card_providers x
      where x.business_id = p_primary_business_id
        and x.provider_id = m.provider_id
    );
  delete from public.business_meal_card_providers where business_id = p_duplicate_business_id;

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
