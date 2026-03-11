-- Canonical alignment preflight (non-breaking, no destructive DDL)
-- Date: 2026-02-20
-- Purpose: Guard checks before legacy cleanup.

begin;
do $$
declare
  missing_count int;
  sort_mismatch int;
begin
  -- 1) Canonical menu_items columns must exist.
  perform 1
  from information_schema.columns
  where table_schema='public' and table_name='menu_items' and column_name in
    ('id','business_id','name','description','price_cents','currency','tags','image_url','is_available','sort_order','created_at','updated_at')
  group by table_name
  having count(*) = 12;

  if not found then
    raise exception 'menu_items canonical column set is incomplete';
  end if;

  -- 2) reports must use status (durum should not be a table column).
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='reports' and column_name='durum'
  ) then
    raise exception 'reports.durum still exists; expected canonical status';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='reports' and column_name='status'
  ) then
    raise exception 'reports.status missing';
  end if;

  -- 3) Detect temporary dual-column drift in menu_categories.
  select count(*) into sort_mismatch
  from public.menu_categories
  where coalesce(sort, -1) <> coalesce(sort_order, -1);

  raise notice 'menu_categories sort mismatch rows: %', sort_mismatch;

  -- 4) Track code-referenced missing DB objects (for refactor backlog).
  with expected(name) as (
    values
      ('menu_settings'),
      ('profiles'),
      ('qr_assets'),
      ('qr_links'),
      ('review_replies'),
      ('user_feed_preferences')
  )
  select count(*) into missing_count
  from expected e
  left join information_schema.tables t
    on t.table_schema='public' and t.table_name=e.name
  left join information_schema.views v
    on v.table_schema='public' and v.table_name=e.name
  where t.table_name is null and v.table_name is null;

  raise notice 'code-referenced missing objects: %', missing_count;
end $$;
commit;
