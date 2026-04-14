begin;

create or replace function public.get_owner_menu_version_detail_v1(
  p_snapshot_id uuid
)
returns table(
  snapshot_id uuid,
  menu_id uuid,
  menu_version integer,
  snapshot_reason text,
  created_at timestamptz,
  menu_title text,
  menu_kind text,
  section_titles text[],
  item_names text[]
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.id as snapshot_id,
    s.source_menu_id as menu_id,
    s.menu_version,
    s.snapshot_reason,
    s.created_at,
    coalesce(s.snapshot_json->'menu'->>'title', '') as menu_title,
    nullif(trim(coalesce(s.snapshot_json->'menu'->>'kind', '')), '') as menu_kind,
    coalesce(
      (
        select array_agg(nullif(trim(section_row->>'title'), ''))
        from jsonb_array_elements(coalesce(s.snapshot_json->'sections', '[]'::jsonb)) section_row
        where nullif(trim(section_row->>'title'), '') is not null
      ),
      '{}'::text[]
    ) as section_titles,
    coalesce(
      (
        select array_agg(nullif(trim(item_row->>'name'), ''))
        from jsonb_array_elements(coalesce(s.snapshot_json->'sections', '[]'::jsonb)) section_row,
             jsonb_array_elements(coalesce(section_row->'items', '[]'::jsonb)) item_row
        where nullif(trim(item_row->>'name'), '') is not null
      ),
      '{}'::text[]
    ) as item_names
  from public.menu_snapshots s
  join public.menus m on m.id = s.source_menu_id
  where s.id = p_snapshot_id
    and (
      public.is_admin()
      or public.has_business_permission_v1(m.business_id, 'business_read')
    );
$$;

grant execute on function public.get_owner_menu_version_detail_v1(uuid) to authenticated;

commit;
