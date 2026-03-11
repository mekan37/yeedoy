begin;

create or replace function public.admin_list_business_submissions_v2(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0,
  p_q text default null,
  p_date_from timestamptz default null,
  p_date_to timestamptz default null,
  p_sort_key text default 'created_at',
  p_sort_ascending boolean default false
)
returns table(
  total_count bigint,
  id uuid,
  submitted_by uuid,
  name text,
  city text,
  district text,
  category text,
  address text,
  phone text,
  website text,
  status text,
  admin_note text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with filtered as (
    select
      s.id,
      s.submitted_by,
      s.name,
      s.city,
      s.district,
      s.category,
      s.address,
      s.phone,
      s.website,
      s.status::text as status,
      s.admin_note,
      s.created_at
    from public.business_submissions s
    where public.is_admin()
      and (
        p_status is null
        or p_status = ''
        or s.status::text = p_status
      )
      and (
        p_q is null
        or p_q = ''
        or s.name ilike '%' || p_q || '%'
        or s.address ilike '%' || p_q || '%'
        or s.category ilike '%' || p_q || '%'
        or coalesce(s.phone, '') ilike '%' || p_q || '%'
        or coalesce(s.website, '') ilike '%' || p_q || '%'
        or s.submitted_by::text ilike '%' || p_q || '%'
      )
      and (p_date_from is null or s.created_at >= p_date_from)
      and (p_date_to is null or s.created_at <= p_date_to)
  ),
  counted as (
    select count(*)::bigint as total_count from filtered
  )
  select
    counted.total_count,
    filtered.id,
    filtered.submitted_by,
    filtered.name,
    filtered.city,
    filtered.district,
    filtered.category,
    filtered.address,
    filtered.phone,
    filtered.website,
    filtered.status,
    filtered.admin_note,
    filtered.created_at
  from filtered
  cross join counted
  order by
    case when p_sort_key = 'name' and p_sort_ascending then filtered.name end asc,
    case when p_sort_key = 'name' and not p_sort_ascending then filtered.name end desc,
    case when p_sort_key = 'status' and p_sort_ascending then filtered.status end asc,
    case when p_sort_key = 'status' and not p_sort_ascending then filtered.status end desc,
    case when p_sort_key = 'category' and p_sort_ascending then filtered.category end asc,
    case when p_sort_key = 'category' and not p_sort_ascending then filtered.category end desc,
    case when p_sort_key = 'submitted_by' and p_sort_ascending then filtered.submitted_by::text end asc,
    case when p_sort_key = 'submitted_by' and not p_sort_ascending then filtered.submitted_by::text end desc,
    case when p_sort_key = 'created_at' and p_sort_ascending then filtered.created_at end asc,
    case when p_sort_key = 'created_at' and not p_sort_ascending then filtered.created_at end desc,
    filtered.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;

grant execute on function public.admin_list_business_submissions_v2(
  text,
  int,
  int,
  text,
  timestamptz,
  timestamptz,
  text,
  boolean
) to authenticated;

commit;;
