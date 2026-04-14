begin;

-- 1) Canonicalize reports to a single status column.
update public.reports
set status = case
  when status in ('open','reviewing','closed') then status
  when durum in ('acik','open') then 'open'
  when durum in ('inceleniyor','reviewing') then 'reviewing'
  when durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
  else coalesce(status, 'open')
end;

alter table public.reports
  alter column status set default 'open',
  alter column status set not null;

-- 2) Keep RPC compatibility while removing duplicated table column.
create or replace view public.admin_reports_queue_v1 as
select
  id,
  created_at,
  status as durum,
  reason,
  details,
  user_id,
  business_id,
  review_id,
  handled_by,
  handled_at,
  admin_note
from public.reports r;

create or replace function public.admin_bulk_update_reports_status_v1(
  p_report_ids uuid[],
  p_durum text,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_durum in ('acik','open') then 'open'
    when p_durum in ('inceleniyor','reviewing') then 'reviewing'
    when p_durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = coalesce(p_admin_note, admin_note)
  where id = any(p_report_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'report.bulk_update',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$$;

create or replace function public.admin_export_reports_csv_v1(
  p_status text default null,
  p_q text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_csv text;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else null
  end;

  select string_agg(line, E'\n') into v_csv
  from (
    select 'id,created_at,status,reason,details,user_id,business_id,review_id,handled_by,handled_at,admin_note' as line
    union all
    select
      concat_ws(',',
        r.id::text,
        to_char(r.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        replace(coalesce(r.status,''), ',', ' '),
        replace(coalesce(r.reason,''), ',', ' '),
        replace(coalesce(r.details,''), E'\n', ' '),
        coalesce(r.user_id::text,''),
        coalesce(r.business_id::text,''),
        coalesce(r.review_id::text,''),
        coalesce(r.handled_by::text,''),
        coalesce(to_char(r.handled_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),''),
        replace(coalesce(r.admin_note,''), E'\n', ' ')
      ) as line
    from public.reports r
    where (v_status is null or r.status = v_status)
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
    order by r.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'report.export_csv',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'q', p_q)
  );

  return v_csv;
end;
$$;

create or replace function public.admin_get_queues_counts_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reports_open int;
  v_claims_pending int;
  v_suggestions_pending int;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select count(*) into v_reports_open
  from public.reports
  where status in ('open','reviewing');

  select count(*) into v_claims_pending
  from public.owner_claims
  where status = 'pending';

  select count(*) into v_suggestions_pending
  from public.business_suggestions
  where status = 'pending';

  return jsonb_build_object(
    'reports_open', v_reports_open,
    'claims_pending', v_claims_pending,
    'suggestions_pending', v_suggestions_pending
  );
end;
$$;

create or replace function public.admin_list_reports_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text
)
language sql
security definer
set search_path = public
as $$
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  )
  select
    r.id, r.created_at, r.status as durum, r.reason, r.details, r.user_id,
    r.business_id, r.review_id, r.handled_by, r.handled_at, r.admin_note
  from public.reports r
  cross join params p
  where public.is_admin()
    and (p.status_filter is null or r.status = p.status_filter)
    and (
      p_q is null
      or r.reason ilike ('%'||p_q||'%')
      or r.details ilike ('%'||p_q||'%')
      or r.admin_note ilike ('%'||p_q||'%')
    )
  order by r.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

create or replace function public.admin_list_reports_v2(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text
)
language sql
security definer
set search_path = public
as $$
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  )
  select
    r.id, r.created_at, r.status as durum, r.reason, r.details, r.user_id,
    r.business_id, r.review_id,
    r.assigned_to, r.assigned_at,
    r.handled_by, r.handled_at, r.admin_note
  from public.reports r
  cross join params p
  where public.is_admin()
    and (p.status_filter is null or r.status = p.status_filter)
    and (
      p_assigned is null
      or (p_assigned='me' and r.assigned_to = auth.uid())
      or (p_assigned='unassigned' and r.assigned_to is null)
    )
    and (
      p_q is null
      or r.reason ilike ('%'||p_q||'%')
      or r.details ilike ('%'||p_q||'%')
      or r.admin_note ilike ('%'||p_q||'%')
    )
  order by r.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

create or replace function public.admin_list_reports_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours float,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status as durum, reason, details, user_id, business_id, review_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

create or replace function public.admin_list_reports_v4(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours float,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin_or_community_mod_v1()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status as durum, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.admin_update_report_v1(
  p_report_id uuid,
  p_durum text,
  p_admin_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_durum in ('acik','open') then 'open'
    when p_durum in ('inceleniyor','reviewing') then 'reviewing'
    when p_durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.update',
    'reports',
    p_report_id,
    jsonb_build_object('status', v_status, 'admin_note', p_admin_note)
  );
end;
$$;

create or replace function public.auto_close_duplicate_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_exists boolean;
begin
  select * into v_r from public.reports where id = p_report_id;

  if v_r.id is null then return false; end if;

  select exists(
    select 1
    from public.reports
    where user_id = v_r.user_id
      and target_type = v_r.target_type
      and target_id = v_r.target_id
      and id <> v_r.id
      and created_at >= now() - interval '24 hours'
  ) into v_exists;

  if v_exists then
    update public.reports
    set
      status = 'closed',
      admin_note = 'Otomatik: 24 saat içinde mükerrer bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_close_duplicate',
      'reports',
      p_report_id,
      jsonb_build_object()
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.auto_queue_grey_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_len int;
begin
  select * into v_r from public.reports where id = p_report_id;
  v_len := length(coalesce(v_r.details, ''));

  if v_r.id is null then return false; end if;

  if v_r.status = 'closed' then
    return false;
  end if;

  if v_len >= 15 and v_len <= 200 and v_r.reason not in ('spam','duplicate') then
    update public.reports
    set
      status = 'reviewing',
      admin_note = 'Otomatik: gri alan, kuyruğa alındı',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_queue_grey',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len, 'reason', v_r.reason)
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.auto_reject_low_quality_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_len int;
  v_uid uuid;
begin
  select length(coalesce(details,'')), user_id into v_len, v_uid
  from public.reports
  where id = p_report_id;

  if v_len < 15 then
    update public.reports
    set
      status = 'closed',
      admin_note = 'Otomatik: çok kısa / düşük kaliteli bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_reject_low_quality',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len)
    );

    perform public.add_moderation_strike_v1(
      v_uid,
      'low_quality_report',
      'report'
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.get_business_reviews_v2(
  p_business_id uuid,
  p_sort text default 'newest',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table(
  id uuid,
  business_id uuid,
  user_id uuid,
  rating integer,
  title text,
  content text,
  helpful_count integer,
  created_at timestamptz,
  status text,
  quality_score numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      r.helpful_count,
      r.created_at,
      r.status,
      coalesce(rep.open_reports, 0) as open_reports,
      greatest(
        0::numeric,
        least(
          100::numeric,
          (coalesce(r.helpful_count, 0)::numeric * 2.2)
          + (least(length(coalesce(r.content, '')), 400)::numeric / 20)
          + (r.rating::numeric * 1.5)
          - (coalesce(rep.open_reports, 0)::numeric * 3.0)
        )
      ) as quality_score
    from public.reviews r
    left join (
      select
        review_id,
        count(*)::int as open_reports
      from public.reports
      where review_id is not null
        and status in ('open', 'reviewing')
      group by review_id
    ) rep on rep.review_id = r.id
    where r.business_id = p_business_id
      and r.status = 'approved'
  )
  select
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score
  from base b
  order by
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.quality_score else null end desc,
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.helpful_count else null end desc,
    b.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

-- 3) Remove deprecated favorites table usage from merge function and drop legacy table.
create or replace function public.admin_merge_businesses_v1(
  p_primary_business_id uuid,
  p_duplicate_business_id uuid,
  p_admin_note text default null,
  p_dry_run boolean default false
)
returns jsonb
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

drop table if exists public.user_favorites_legacy;

-- 4) Finally drop duplicated reports column.
alter table public.reports
  drop column if exists durum;

commit;;
