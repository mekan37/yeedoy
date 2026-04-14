create or replace function public.search_admin_v1(
  p_q text,
  p_limit integer default 6
)
returns table(
  category text,
  item_id uuid,
  title text,
  subtitle text,
  search_token text,
  created_at timestamptz,
  meta jsonb,
  score integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_q text := lower(trim(coalesce(p_q, '')));
  v_limit integer := greatest(1, least(coalesce(p_limit, 6), 10));
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if v_q = '' then
    return;
  end if;

  return query
  with candidates as (
    select
      'business'::text as category,
      b.id as item_id,
      coalesce(nullif(trim(b.name), ''), b.id::text) as title,
      trim(
        concat_ws(
          ' • ',
          nullif(trim(coalesce(b.phone, '')), ''),
          nullif(trim(coalesce(b.address, '')), ''),
          nullif(trim(concat_ws(' / ', b.district, b.city)), '')
        )
      ) as subtitle,
      coalesce(nullif(trim(b.name), ''), b.id::text) as search_token,
      b.created_at,
      jsonb_build_object(
        'business_id', b.id,
        'business_name', b.name,
        'phone', b.phone,
        'address', b.address,
        'city', b.city,
        'district', b.district
      ) as meta,
      case
        when b.id::text = v_q then 1000
        when lower(coalesce(b.name, '')) = v_q then 920
        when lower(coalesce(b.phone, '')) = v_q then 900
        when lower(coalesce(b.address, '')) = v_q then 880
        when lower(coalesce(b.name, '')) like (v_q || '%') then 820
        when lower(coalesce(b.phone, '')) like (v_q || '%') then 800
        when lower(coalesce(b.address, '')) like (v_q || '%') then 780
        else 720
      end as score
    from public.businesses b
    where
      b.id::text = v_q
      or lower(coalesce(b.name, '')) like ('%' || v_q || '%')
      or lower(coalesce(b.phone, '')) like ('%' || v_q || '%')
      or lower(coalesce(b.address, '')) like ('%' || v_q || '%')

    union all

    select
      'user'::text as category,
      u.id as item_id,
      lower(u.email::text) as title,
      u.id::text as subtitle,
      lower(u.email::text) as search_token,
      u.created_at,
      jsonb_build_object(
        'user_id', u.id,
        'email', lower(u.email::text)
      ) as meta,
      case
        when u.id::text = v_q then 1000
        when lower(u.email::text) = v_q then 940
        when lower(u.email::text) like (v_q || '%') then 860
        else 760
      end as score
    from auth.users u
    where
      u.id::text = v_q
      or lower(u.email::text) like ('%' || v_q || '%')

    union all

    select
      'report'::text as category,
      r.id as item_id,
      coalesce(nullif(trim(r.reason), ''), 'report') as title,
      trim(
        concat_ws(
          ' • ',
          nullif(trim(coalesce(b.name, '')), ''),
          nullif(trim(coalesce(r.details, '')), ''),
          nullif(trim(coalesce(r.status, '')), '')
        )
      ) as subtitle,
      coalesce(nullif(trim(b.name), ''), nullif(trim(r.reason), ''), r.id::text) as search_token,
      r.created_at,
      jsonb_build_object(
        'report_id', r.id,
        'business_id', r.business_id,
        'business_name', b.name,
        'status', r.status,
        'target_type', r.target_type,
        'target_id', r.target_id
      ) as meta,
      case
        when r.id::text = v_q then 1000
        when lower(coalesce(b.name, '')) = v_q then 900
        when lower(coalesce(r.reason, '')) = v_q then 880
        when lower(coalesce(b.name, '')) like (v_q || '%') then 820
        when lower(coalesce(r.reason, '')) like (v_q || '%') then 800
        else 720
      end as score
    from public.reports r
    left join public.businesses b on b.id = r.business_id
    where
      r.id::text = v_q
      or lower(coalesce(r.reason, '')) like ('%' || v_q || '%')
      or lower(coalesce(r.details, '')) like ('%' || v_q || '%')
      or lower(coalesce(b.name, '')) like ('%' || v_q || '%')

    union all

    select
      'submission'::text as category,
      s.id as item_id,
      coalesce(nullif(trim(s.name), ''), 'submission') as title,
      trim(
        concat_ws(
          ' • ',
          nullif(trim(coalesce(s.phone, '')), ''),
          nullif(trim(coalesce(s.address, '')), ''),
          nullif(trim(concat_ws(' / ', s.district, s.city)), '')
        )
      ) as subtitle,
      coalesce(nullif(trim(s.name), ''), s.id::text) as search_token,
      s.created_at,
      jsonb_build_object(
        'submission_id', s.id,
        'status', s.status,
        'phone', s.phone,
        'address', s.address,
        'city', s.city,
        'district', s.district,
        'category', s.category
      ) as meta,
      case
        when s.id::text = v_q then 1000
        when lower(coalesce(s.name, '')) = v_q then 920
        when lower(coalesce(s.phone, '')) = v_q then 900
        when lower(coalesce(s.name, '')) like (v_q || '%') then 840
        else 760
      end as score
    from public.business_submissions s
    where
      s.id::text = v_q
      or lower(coalesce(s.name, '')) like ('%' || v_q || '%')
      or lower(coalesce(s.phone, '')) like ('%' || v_q || '%')
      or lower(coalesce(s.address, '')) like ('%' || v_q || '%')

    union all

    select
      'claim'::text as category,
      c.id as item_id,
      coalesce(nullif(trim(c.full_name), ''), 'claim') as title,
      trim(
        concat_ws(
          ' • ',
          nullif(trim(coalesce(c.phone, '')), ''),
          nullif(trim(coalesce(b.name, '')), ''),
          nullif(trim(coalesce(c.status, '')), '')
        )
      ) as subtitle,
      coalesce(nullif(trim(c.full_name), ''), nullif(trim(coalesce(b.name, '')), ''), c.id::text) as search_token,
      c.created_at,
      jsonb_build_object(
        'claim_id', c.id,
        'business_id', c.business_id,
        'business_name', b.name,
        'status', c.status,
        'phone', c.phone
      ) as meta,
      case
        when c.id::text = v_q then 1000
        when lower(coalesce(c.full_name, '')) = v_q then 920
        when lower(coalesce(c.phone, '')) = v_q then 900
        when lower(coalesce(c.full_name, '')) like (v_q || '%') then 840
        when lower(coalesce(b.name, '')) like (v_q || '%') then 820
        else 760
      end as score
    from public.owner_claims c
    left join public.businesses b on b.id = c.business_id
    where
      c.id::text = v_q
      or lower(coalesce(c.full_name, '')) like ('%' || v_q || '%')
      or lower(coalesce(c.phone, '')) like ('%' || v_q || '%')
      or lower(coalesce(b.name, '')) like ('%' || v_q || '%')

    union all

    select
      'menu_item'::text as category,
      mi.id as item_id,
      coalesce(nullif(trim(mi.name), ''), 'menu item') as title,
      trim(
        concat_ws(
          ' • ',
          nullif(trim(coalesce(b.name, '')), ''),
          nullif(trim(coalesce(mi.status, '')), '')
        )
      ) as subtitle,
      coalesce(nullif(trim(mi.name), ''), nullif(trim(coalesce(b.name, '')), ''), mi.id::text) as search_token,
      mi.created_at,
      jsonb_build_object(
        'menu_item_id', mi.id,
        'business_id', mi.business_id,
        'business_name', b.name,
        'status', mi.status
      ) as meta,
      case
        when mi.id::text = v_q then 1000
        when lower(coalesce(mi.name, '')) = v_q then 920
        when lower(coalesce(mi.name, '')) like (v_q || '%') then 840
        when lower(coalesce(b.name, '')) like (v_q || '%') then 820
        else 740
      end as score
    from public.menu_items mi
    left join public.businesses b on b.id = mi.business_id
    where
      mi.id::text = v_q
      or lower(coalesce(mi.name, '')) like ('%' || v_q || '%')
      or lower(coalesce(b.name, '')) like ('%' || v_q || '%')
  ),
  ranked as (
    select
      c.*,
      row_number() over (
        partition by c.category
        order by c.score desc, c.created_at desc nulls last, c.item_id
      ) as row_no
    from candidates c
  )
  select
    r.category,
    r.item_id,
    r.title,
    coalesce(nullif(r.subtitle, ''), '-') as subtitle,
    r.search_token,
    r.created_at,
    r.meta,
    r.score
  from ranked r
  where r.row_no <= v_limit
  order by
    case r.category
      when 'business' then 1
      when 'user' then 2
      when 'report' then 3
      when 'submission' then 4
      when 'claim' then 5
      when 'menu_item' then 6
      else 99
    end,
    r.score desc,
    r.created_at desc nulls last,
    r.item_id;
end;
$$;

grant execute on function public.search_admin_v1(text, integer) to authenticated;
