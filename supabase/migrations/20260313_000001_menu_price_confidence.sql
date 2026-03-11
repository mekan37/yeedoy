-- Menu & price trust hardening:
-- 1) Optional evidence URL for price suggestions
-- 2) New submit RPC with confidence score + conservative auto-approval
-- 3) Enriched price status payload (price, last verification, confidence)

alter table if exists public.menu_item_price_suggestions
  add column if not exists evidence_url text;
create or replace function public.get_menu_item_price_status_v1(p_menu_item_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with votes as (
    select
      count(*) filter (where created_at >= now() - interval '30 days') as total_30d,
      count(*) filter (where vote = 1 and created_at >= now() - interval '30 days') as ok_30d,
      count(*) filter (where vote = -1 and created_at >= now() - interval '30 days') as bad_30d,
      (
        select vote
        from public.menu_item_price_votes
        where menu_item_id = p_menu_item_id and user_id = auth.uid()
        limit 1
      ) as my_vote
    from public.menu_item_price_votes
    where menu_item_id = p_menu_item_id
  ),
  latest as (
    select
      mi.price_cents,
      (
        select max(h.created_at)
        from public.menu_item_price_history h
        where h.menu_item_id = p_menu_item_id
      ) as last_verified_at
    from public.menu_items mi
    where mi.id = p_menu_item_id
    limit 1
  )
  select jsonb_build_object(
    'total_30d', votes.total_30d,
    'ok_30d', votes.ok_30d,
    'bad_30d', votes.bad_30d,
    'my_vote', votes.my_vote,
    'price_cents', latest.price_cents,
    'last_verified_at', latest.last_verified_at,
    'confidence_score',
      greatest(
        0::numeric,
        least(
          1::numeric,
          (
            case
              when votes.total_30d <= 0 then 0.2
              else (votes.ok_30d::numeric / nullif(votes.total_30d, 0))
            end
          ) * 0.8
          +
          (
            case
              when votes.total_30d >= 12 then 0.2
              when votes.total_30d >= 6 then 0.12
              when votes.total_30d >= 3 then 0.06
              else 0
            end
          )
        )
      ),
    'status',
      case
        when votes.total_30d = 0 then 'unknown'
        when votes.ok_30d >= 3 and votes.ok_30d >= votes.bad_30d * 2 then 'verified'
        when votes.bad_30d >= 3 and votes.bad_30d > votes.ok_30d then 'outdated'
        else 'mixed'
      end
  )
  from votes
  left join latest on true;
$$;
create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(trim(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: same user, same item, once per 24h
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  -- Conservative auto-approval rule:
  -- enough signal + strong positive votes + small price delta (<=5%)
  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now()
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count
  );
end;
$$;
grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to anon;
grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to service_role;
