-- policies.sql
alter table public.businesses enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.menu_translations enable row level security;
alter table public.menu_settings enable row level security;
alter table public.qr_assets enable row level security;
alter table public.qr_links enable row level security;

-- businesses
create policy if not exists businesses_owner_select
on public.businesses for select
to authenticated
using (owner_id = auth.uid());

create policy if not exists businesses_owner_insert
on public.businesses for insert
to authenticated
with check (owner_id = auth.uid());

create policy if not exists businesses_owner_update
on public.businesses for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy if not exists businesses_owner_delete
on public.businesses for delete
to authenticated
using (owner_id = auth.uid());

create policy if not exists businesses_public_read_active
on public.businesses for select
to anon
using (is_active = true);

-- menu_categories
create policy if not exists menu_categories_owner_crud
on public.menu_categories
for all
to authenticated
using (
  exists (
    select 1 from public.businesses b
    where b.id = menu_categories.business_id and b.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.businesses b
    where b.id = menu_categories.business_id and b.owner_id = auth.uid()
  )
);

create policy if not exists menu_categories_public_read
on public.menu_categories for select
to anon
using (
  is_active = true and exists (
    select 1 from public.businesses b where b.id = menu_categories.business_id and b.is_active = true
  )
);

-- menu_items
create policy if not exists menu_items_owner_crud
on public.menu_items
for all
to authenticated
using (
  exists (
    select 1 from public.businesses b
    where b.id = menu_items.business_id and b.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.businesses b
    where b.id = menu_items.business_id and b.owner_id = auth.uid()
  )
);

create policy if not exists menu_items_public_read
on public.menu_items for select
to anon
using (
  exists (
    select 1 from public.businesses b where b.id = menu_items.business_id and b.is_active = true
  )
);

-- menu_translations
create policy if not exists menu_translations_owner_crud
on public.menu_translations
for all
to authenticated
using (
  (
    menu_translations.entity_type = 'business'
    and exists (
      select 1
      from public.businesses b
      where b.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
  or (
    menu_translations.entity_type = 'category'
    and exists (
      select 1
      from public.menu_categories c
      join public.businesses b on b.id = c.business_id
      where c.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
  or (
    menu_translations.entity_type = 'item'
    and exists (
      select 1
      from public.menu_items i
      join public.businesses b on b.id = i.business_id
      where i.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
)
with check (
  (
    menu_translations.entity_type = 'business'
    and exists (
      select 1
      from public.businesses b
      where b.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
  or (
    menu_translations.entity_type = 'category'
    and exists (
      select 1
      from public.menu_categories c
      join public.businesses b on b.id = c.business_id
      where c.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
  or (
    menu_translations.entity_type = 'item'
    and exists (
      select 1
      from public.menu_items i
      join public.businesses b on b.id = i.business_id
      where i.id = menu_translations.entity_id
        and b.owner_id = auth.uid()
    )
  )
);

create policy if not exists menu_translations_public_read
on public.menu_translations for select
to anon
using (true);

-- menu_settings
create policy if not exists menu_settings_owner_crud
on public.menu_settings
for all
to authenticated
using (
  exists (
    select 1 from public.businesses b where b.id = menu_settings.business_id and b.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.businesses b where b.id = menu_settings.business_id and b.owner_id = auth.uid()
  )
);

create policy if not exists menu_settings_public_read
on public.menu_settings for select
to anon
using (
  exists (
    select 1 from public.businesses b where b.id = menu_settings.business_id and b.is_active = true
  )
);

-- qr assets and links
create policy if not exists qr_assets_owner_crud
on public.qr_assets for all
to authenticated
using (
  exists (select 1 from public.businesses b where b.id = qr_assets.business_id and b.owner_id = auth.uid())
)
with check (
  exists (select 1 from public.businesses b where b.id = qr_assets.business_id and b.owner_id = auth.uid())
);

create policy if not exists qr_assets_public_read
on public.qr_assets for select
to anon
using (
  exists (select 1 from public.businesses b where b.id = qr_assets.business_id and b.is_active = true)
);

create policy if not exists qr_links_owner_crud
on public.qr_links for all
to authenticated
using (
  exists (select 1 from public.businesses b where b.id = qr_links.business_id and b.owner_id = auth.uid())
)
with check (
  exists (select 1 from public.businesses b where b.id = qr_links.business_id and b.owner_id = auth.uid())
);

create policy if not exists qr_links_public_read
on public.qr_links for select
to anon
using (
  exists (select 1 from public.businesses b where b.id = qr_links.business_id and b.is_active = true)
);

-- storage policies
create policy if not exists menu_assets_public_read
on storage.objects for select
to public
using (bucket_id = 'menu-assets');

create policy if not exists menu_assets_owner_write
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'menu-assets'
  and split_part(name, '/', 1) in ('business', 'qr')
  and exists (
    select 1
    from public.businesses b
    where b.id::text = split_part(name, '/', 2)
      and b.owner_id = auth.uid()
  )
);

create policy if not exists menu_assets_owner_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'menu-assets'
  and exists (
    select 1
    from public.businesses b
    where b.id::text = split_part(name, '/', 2)
      and b.owner_id = auth.uid()
  )
)
with check (
  bucket_id = 'menu-assets'
  and exists (
    select 1
    from public.businesses b
    where b.id::text = split_part(name, '/', 2)
      and b.owner_id = auth.uid()
  )
);

create policy if not exists menu_assets_owner_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'menu-assets'
  and exists (
    select 1
    from public.businesses b
    where b.id::text = split_part(name, '/', 2)
      and b.owner_id = auth.uid()
  )
);
