begin;

create or replace function public.list_audit_timeline_v2(
  p_limit integer default 50,
  p_offset integer default 0,
  p_action text default null,
  p_target_type text default null,
  p_target_id uuid default null,
  p_actor_id uuid default null,
  p_business_id uuid default null,
  p_from timestamp with time zone default null,
  p_to timestamp with time zone default null,
  p_q text default null
)
returns table(
  id uuid,
  created_at timestamp with time zone,
  actor_id uuid,
  actor_role text,
  action text,
  target_type text,
  target_id uuid,
  before_data jsonb,
  after_data jsonb,
  ip text,
  user_agent text,
  meta jsonb
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_is_admin boolean := false;
  v_q text := nullif(trim(coalesce(p_q, '')), '');
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select public.is_admin() into v_is_admin;

  if p_limit is null or p_limit < 1 then
    p_limit := 50;
  end if;
  if p_limit > 200 then
    p_limit := 200;
  end if;
  if p_offset is null or p_offset < 0 then
    p_offset := 0;
  end if;

  return query
  with owner_businesses as (
    select distinct oc.business_id
    from public.owner_claims oc
    where oc.user_id = v_uid
      and oc.status = 'approved'
    union
    select distinct btm.business_id
    from public.business_team_memberships btm
    where btm.user_id = v_uid
      and btm.revoked_at is null
      and btm.business_id is not null
  ),
  normalized as (
    select
      l.id,
      l.created_at,
      l.actor_id,
      l.actor_role,
      l.action,
      case
        when coalesce(l.target_type, l.target_table) in ('business', 'businesses') then 'business'
        when coalesce(l.target_type, l.target_table) in ('menu', 'menus') then 'menu'
        when coalesce(l.target_type, l.target_table) in ('menu_item', 'menu_items') then 'menu_item'
        when coalesce(l.target_type, l.target_table) in ('owner_claim', 'owner_claims') then 'owner_claim'
        when coalesce(l.target_type, l.target_table) in ('report', 'reports') then 'report'
        when coalesce(l.target_type, l.target_table) in (
          'business_team_memberships',
          'team_member',
          'team_membership'
        ) then 'team_member'
        when coalesce(l.target_type, l.target_table) in (
          'menu_item_price_suggestions',
          'price_suggestion'
        ) then 'price_suggestion'
        when coalesce(l.target_type, l.target_table) in ('auth.users', 'user_profiles', 'user') then 'user'
        else coalesce(l.target_type, l.target_table)
      end as canonical_target_type,
      l.target_id,
      l.before_data,
      l.after_data,
      l.ip,
      l.user_agent,
      l.meta
    from public.admin_audit_log l
    where (p_action is null or l.action = p_action)
      and (p_target_id is null or l.target_id = p_target_id)
      and (p_actor_id is null or l.actor_id = p_actor_id)
      and (p_from is null or l.created_at >= p_from)
      and (p_to is null or l.created_at <= p_to)
      and (
        p_target_type is null
        or case
          when coalesce(l.target_type, l.target_table) in ('business', 'businesses') then 'business'
          when coalesce(l.target_type, l.target_table) in ('menu', 'menus') then 'menu'
          when coalesce(l.target_type, l.target_table) in ('menu_item', 'menu_items') then 'menu_item'
          when coalesce(l.target_type, l.target_table) in ('owner_claim', 'owner_claims') then 'owner_claim'
          when coalesce(l.target_type, l.target_table) in ('report', 'reports') then 'report'
          when coalesce(l.target_type, l.target_table) in (
            'business_team_memberships',
            'team_member',
            'team_membership'
          ) then 'team_member'
          when coalesce(l.target_type, l.target_table) in (
            'menu_item_price_suggestions',
            'price_suggestion'
          ) then 'price_suggestion'
          when coalesce(l.target_type, l.target_table) in ('auth.users', 'user_profiles', 'user') then 'user'
          else coalesce(l.target_type, l.target_table)
        end = p_target_type
      )
      and (
        v_q is null
        or l.action ilike ('%' || v_q || '%')
        or coalesce(l.target_type, l.target_table, '') ilike ('%' || v_q || '%')
        or coalesce(l.actor_role, '') ilike ('%' || v_q || '%')
        or coalesce(l.target_id::text, '') ilike ('%' || v_q || '%')
        or coalesce(l.actor_id::text, '') ilike ('%' || v_q || '%')
        or coalesce(l.meta::text, '') ilike ('%' || v_q || '%')
      )
  ),
  base as (
    select
      n.id,
      n.created_at,
      n.actor_id,
      n.actor_role,
      n.action,
      n.canonical_target_type as target_type,
      n.target_id,
      n.before_data,
      n.after_data,
      n.ip,
      n.user_agent,
      n.meta,
      case
        when n.canonical_target_type = 'business' then n.target_id
        when n.canonical_target_type = 'menu' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select m.business_id from public.menus m where m.id = n.target_id)
        )
        when n.canonical_target_type = 'menu_item' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select mi.business_id from public.menu_items mi where mi.id = n.target_id)
        )
        when n.canonical_target_type = 'owner_claim' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select oc.business_id from public.owner_claims oc where oc.id = n.target_id)
        )
        when n.canonical_target_type = 'report' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select r.business_id from public.reports r where r.id = n.target_id)
        )
        when n.canonical_target_type = 'team_member' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select btm.business_id from public.business_team_memberships btm where btm.id = n.target_id)
        )
        when n.canonical_target_type = 'price_suggestion' then coalesce(
          nullif(n.after_data ->> 'business_id', '')::uuid,
          nullif(n.before_data ->> 'business_id', '')::uuid,
          nullif(n.meta ->> 'business_id', '')::uuid,
          (select s.business_id from public.menu_item_price_suggestions s where s.id = n.target_id)
        )
        else null::uuid
      end as resolved_business_id
    from normalized n
  )
  select
    b.id,
    b.created_at,
    b.actor_id,
    b.actor_role,
    b.action,
    b.target_type,
    b.target_id,
    b.before_data,
    b.after_data,
    b.ip,
    b.user_agent,
    b.meta
  from base b
  where
    (p_business_id is null or b.resolved_business_id = p_business_id)
    and (
      v_is_admin
      or b.resolved_business_id in (select ob.business_id from owner_businesses ob)
      or (
        b.target_type = 'owner_claim'
        and exists (
          select 1
          from public.owner_claims oc
          where oc.id = b.target_id
            and oc.user_id = v_uid
        )
      )
    )
  order by b.created_at desc
  limit p_limit
  offset p_offset;
end;
$$;

grant execute on function public.list_audit_timeline_v2(
  integer,
  integer,
  text,
  text,
  uuid,
  uuid,
  uuid,
  timestamp with time zone,
  timestamp with time zone,
  text
) to authenticated;

create or replace function public.admin_set_business_verified_v1(
  p_business_id uuid,
  p_is_verified boolean,
  p_tier text default 'verified',
  p_ends_at timestamp with time zone default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
  v_before jsonb;
  v_after jsonb;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  select jsonb_build_object(
    'business_id', b.id,
    'is_verified', b.is_verified,
    'verified_at', b.verified_at,
    'verified_by', b.verified_by,
    'tier', bp.tier,
    'premium_status', bp.status,
    'premium_ends_at', bp.ends_at
  )
  into v_before
  from public.businesses b
  left join lateral (
    select p.tier, p.status, p.ends_at
    from public.business_premium p
    where p.business_id = b.id
      and p.tier = p_tier
    order by p.created_at desc
    limit 1
  ) bp on true
  where b.id = p_business_id;

  update public.businesses
  set
    is_verified = p_is_verified,
    verified_at = case when p_is_verified then now() else null end,
    verified_by = case when p_is_verified then auth.uid() else null end
  where id = p_business_id;

  if p_is_verified then
    insert into public.business_premium(
      business_id, tier, status, starts_at, ends_at, source, created_by
    )
    values (
      p_business_id, p_tier, 'active', now(), p_ends_at, 'manual', auth.uid()
    )
    on conflict (business_id, tier) where status = 'active'
    do update set
      ends_at = excluded.ends_at,
      status = 'active';
  else
    update public.business_premium
    set status = 'ended',
        ends_at = coalesce(p_ends_at, now())
    where business_id = p_business_id
      and tier = p_tier
      and status = 'active';
  end if;

  select id into v_id
  from public.business_premium
  where business_id = p_business_id
    and tier = p_tier
  order by created_at desc
  limit 1;

  select jsonb_build_object(
    'business_id', b.id,
    'is_verified', b.is_verified,
    'verified_at', b.verified_at,
    'verified_by', b.verified_by,
    'tier', bp.tier,
    'premium_status', bp.status,
    'premium_ends_at', bp.ends_at,
    'premium_id', v_id
  )
  into v_after
  from public.businesses b
  left join lateral (
    select p.tier, p.status, p.ends_at
    from public.business_premium p
    where p.business_id = b.id
      and p.tier = p_tier
    order by p.created_at desc
    limit 1
  ) bp on true
  where b.id = p_business_id;

  perform public.insert_audit_log_v1(
    'business.verification_changed',
    'business',
    p_business_id,
    v_before,
    v_after
  );

  return jsonb_build_object('ok', true, 'business_id', p_business_id, 'premium_id', v_id);
end;
$$;

create or replace function public.admin_approve_menu_price_suggestion_v1(p_suggestion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item_id uuid;
  v_business_id uuid;
  v_new integer;
  v_old integer;
  v_cur text;
  v_before jsonb;
  v_after jsonb;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  select
    s.menu_item_id,
    s.business_id,
    s.suggested_price_cents,
    s.currency,
    jsonb_build_object(
      'business_id', s.business_id,
      'menu_item_id', s.menu_item_id,
      'status', s.status,
      'current_price_cents', mi.price_cents,
      'suggested_price_cents', s.suggested_price_cents,
      'currency', s.currency,
      'note', s.note
    )
  into v_item_id, v_business_id, v_new, v_cur, v_before
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  where s.id = p_suggestion_id
    and s.status = 'pending';

  if v_item_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  select price_cents into v_old
  from public.menu_items
  where id = v_item_id;

  update public.menu_items
  set price_cents = v_new,
      currency = v_cur,
      updated_at = now()
  where id = v_item_id;

  update public.menu_item_price_suggestions
  set status = 'approved',
      handled_by = auth.uid(),
      handled_at = now()
  where id = p_suggestion_id;

  insert into public.menu_item_price_history(
    menu_item_id,
    price_cents,
    currency,
    source,
    created_by
  )
  values (
    v_item_id,
    v_new,
    v_cur,
    'suggestion',
    auth.uid()
  );

  v_after := jsonb_build_object(
    'business_id', v_business_id,
    'menu_item_id', v_item_id,
    'status', 'approved',
    'previous_price_cents', v_old,
    'new_price_cents', v_new,
    'currency', v_cur,
    'handled_by', auth.uid()
  );

  perform public.insert_audit_log_v1(
    'price_suggestion.approved',
    'menu_item_price_suggestions',
    p_suggestion_id,
    v_before,
    v_after
  );

  return jsonb_build_object('ok', true, 'old_price_cents', v_old, 'new_price_cents', v_new);
end;
$$;

create or replace function public.admin_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_note text;
  v_before jsonb;
  v_after jsonb;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  v_note := nullif(trim(p_note), '');

  select jsonb_build_object(
    'business_id', s.business_id,
    'menu_item_id', s.menu_item_id,
    'status', s.status,
    'suggested_price_cents', s.suggested_price_cents,
    'currency', s.currency,
    'note', s.note
  )
  into v_before
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id
    and s.status = 'pending';

  update public.menu_item_price_suggestions
  set status = 'rejected',
      note = coalesce(note, v_note),
      handled_by = auth.uid(),
      handled_at = now()
  where id = p_suggestion_id
    and status = 'pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  select jsonb_build_object(
    'business_id', s.business_id,
    'menu_item_id', s.menu_item_id,
    'status', s.status,
    'suggested_price_cents', s.suggested_price_cents,
    'currency', s.currency,
    'note', s.note,
    'handled_by', s.handled_by
  )
  into v_after
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id;

  perform public.insert_audit_log_v1(
    'price_suggestion.rejected',
    'menu_item_price_suggestions',
    p_suggestion_id,
    v_before,
    v_after
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.owner_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_id uuid;
  v_note text;
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_note := nullif(trim(p_note), '');

  select
    s.business_id,
    jsonb_build_object(
      'business_id', s.business_id,
      'menu_item_id', s.menu_item_id,
      'status', s.status,
      'suggested_price_cents', s.suggested_price_cents,
      'currency', s.currency,
      'note', s.note
    )
  into v_business_id, v_before
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id
    and s.status = 'pending';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  update public.menu_item_price_suggestions
  set status = 'rejected',
      note = coalesce(note, v_note),
      handled_by = auth.uid(),
      handled_at = now()
  where id = p_suggestion_id
    and status = 'pending';

  select jsonb_build_object(
    'business_id', s.business_id,
    'menu_item_id', s.menu_item_id,
    'status', s.status,
    'suggested_price_cents', s.suggested_price_cents,
    'currency', s.currency,
    'note', s.note,
    'handled_by', s.handled_by
  )
  into v_after
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id;

  perform public.insert_audit_log_v1(
    'owner.price_suggestion.rejected',
    'menu_item_price_suggestions',
    p_suggestion_id,
    v_before,
    v_after
  );

  return jsonb_build_object('ok', true);
end;
$$;

commit;;
