alter table public.receipt_submissions
  add column if not exists review_status text not null default 'pending',
  add column if not exists review_note text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'receipt_submissions_review_status_ck'
  ) then
    alter table public.receipt_submissions
      add constraint receipt_submissions_review_status_ck
      check (review_status in ('pending', 'reviewed', 'needs_followup'));
  end if;
end $$;

update public.receipt_submissions
set review_status = 'pending'
where review_status not in ('pending', 'reviewed', 'needs_followup');

create or replace function public.admin_list_receipt_submissions_v2(
  p_query text default null,
  p_review_status text default null,
  p_only_unmatched boolean default false,
  p_limit int default 50,
  p_offset int default 0
) returns table(
  receipt_id uuid,
  created_at timestamptz,
  user_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  chain_id uuid,
  chain_name text,
  image_url text,
  matches_count int,
  review_status text,
  review_note text,
  reviewed_at timestamptz,
  reviewed_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with match_counts as (
    select receipt_id, count(*)::int as cnt
    from public.receipt_matches
    group by receipt_id
  ),
  filtered as (
    select
      s.id as receipt_id,
      s.created_at,
      s.user_id,
      s.business_id,
      b.name as business_name,
      b.city,
      b.district,
      b.chain_id,
      ch.name as chain_name,
      s.image_url,
      coalesce(mc.cnt, 0) as matches_count,
      s.review_status,
      s.review_note,
      s.reviewed_at,
      s.reviewed_by
    from public.receipt_submissions s
    join public.businesses b on b.id = s.business_id
    left join public.chains ch on ch.id = b.chain_id
    left join match_counts mc on mc.receipt_id = s.id
    where public.is_admin()
      and (
        coalesce(nullif(trim(p_query), ''), '') = ''
        or b.name ilike '%' || trim(p_query) || '%'
        or coalesce(b.city, '') ilike '%' || trim(p_query) || '%'
        or coalesce(b.district, '') ilike '%' || trim(p_query) || '%'
        or coalesce(ch.name, '') ilike '%' || trim(p_query) || '%'
      )
      and (
        coalesce(nullif(trim(p_review_status), ''), '') = ''
        or s.review_status = trim(p_review_status)
      )
      and (
        coalesce(p_only_unmatched, false) = false
        or coalesce(mc.cnt, 0) = 0
      )
  )
  select *
  from filtered
  order by
    case review_status
      when 'pending' then 1
      when 'needs_followup' then 2
      when 'reviewed' then 3
      else 99
    end,
    created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$function$;

create or replace function public.admin_get_receipt_submission_summary_v1(
  p_query text default null,
  p_review_status text default null,
  p_only_unmatched boolean default false
) returns table(
  total_count int,
  pending_count int,
  reviewed_count int,
  needs_followup_count int,
  zero_match_count int,
  business_count int,
  recent_24h_count int
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with match_counts as (
    select receipt_id, count(*)::int as cnt
    from public.receipt_matches
    group by receipt_id
  ),
  filtered as (
    select
      s.id,
      s.business_id,
      s.created_at,
      s.review_status,
      coalesce(mc.cnt, 0) as matches_count
    from public.receipt_submissions s
    join public.businesses b on b.id = s.business_id
    left join public.chains ch on ch.id = b.chain_id
    left join match_counts mc on mc.receipt_id = s.id
    where public.is_admin()
      and (
        coalesce(nullif(trim(p_query), ''), '') = ''
        or b.name ilike '%' || trim(p_query) || '%'
        or coalesce(b.city, '') ilike '%' || trim(p_query) || '%'
        or coalesce(b.district, '') ilike '%' || trim(p_query) || '%'
        or coalesce(ch.name, '') ilike '%' || trim(p_query) || '%'
      )
      and (
        coalesce(nullif(trim(p_review_status), ''), '') = ''
        or s.review_status = trim(p_review_status)
      )
      and (
        coalesce(p_only_unmatched, false) = false
        or coalesce(mc.cnt, 0) = 0
      )
  )
  select
    count(*)::int as total_count,
    count(*) filter (where review_status = 'pending')::int as pending_count,
    count(*) filter (where review_status = 'reviewed')::int as reviewed_count,
    count(*) filter (where review_status = 'needs_followup')::int as needs_followup_count,
    count(*) filter (where matches_count = 0)::int as zero_match_count,
    count(distinct business_id)::int as business_count,
    count(*) filter (where created_at >= now() - interval '24 hours')::int as recent_24h_count
  from filtered;
$function$;

create or replace function public.admin_list_receipt_submission_matches_v1(
  p_receipt_id uuid
) returns table(
  menu_item_id uuid,
  item_name text,
  detected_price_cents int,
  current_price_cents int,
  delta_cents int
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    rm.menu_item_id,
    mi.name as item_name,
    rm.detected_price_cents,
    mi.price_cents as current_price_cents,
    (rm.detected_price_cents - mi.price_cents) as delta_cents
  from public.receipt_matches rm
  join public.menu_items mi on mi.id = rm.menu_item_id
  where public.is_admin()
    and rm.receipt_id = p_receipt_id
  order by abs(rm.detected_price_cents - mi.price_cents) desc, mi.name;
$function$;

create or replace function public.admin_list_receipt_submission_batch_opportunities_v1(
  p_limit int default 8
) returns table(
  business_id uuid,
  business_name text,
  chain_id uuid,
  chain_name text,
  pending_count int,
  zero_match_count int,
  last_submitted_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with match_counts as (
    select receipt_id, count(*)::int as cnt
    from public.receipt_matches
    group by receipt_id
  )
  select
    s.business_id,
    b.name as business_name,
    b.chain_id,
    ch.name as chain_name,
    count(*)::int as pending_count,
    count(*) filter (where coalesce(mc.cnt, 0) = 0)::int as zero_match_count,
    max(s.created_at) as last_submitted_at
  from public.receipt_submissions s
  join public.businesses b on b.id = s.business_id
  left join public.chains ch on ch.id = b.chain_id
  left join match_counts mc on mc.receipt_id = s.id
  where public.is_admin()
    and s.review_status in ('pending', 'needs_followup')
  group by s.business_id, b.name, b.chain_id, ch.name
  order by pending_count desc, zero_match_count desc, last_submitted_at desc
  limit greatest(p_limit, 0);
$function$;

create or replace function public.admin_update_receipt_submission_review_v1(
  p_receipt_id uuid,
  p_review_status text,
  p_review_note text default null,
  p_reviewed_by uuid default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin');
  end if;

  if p_review_status not in ('pending', 'reviewed', 'needs_followup') then
    return jsonb_build_object('ok', false, 'code', 'invalid_status');
  end if;

  update public.receipt_submissions
  set
    review_status = p_review_status,
    review_note = nullif(trim(coalesce(p_review_note, '')), ''),
    reviewed_at = case
      when p_review_status = 'pending' then null
      else now()
    end,
    reviewed_by = case
      when p_review_status = 'pending' then null
      else p_reviewed_by
    end
  where id = p_receipt_id;

  return jsonb_build_object('ok', true, 'id', p_receipt_id);
end;
$function$;
