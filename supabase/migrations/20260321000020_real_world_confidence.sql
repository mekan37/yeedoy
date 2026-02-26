alter table if exists public.menu_item_price_suggestions
  add column if not exists client_id text,
  add column if not exists captured_at timestamptz,
  add column if not exists onsite_verified boolean not null default false,
  add column if not exists onsite_signal text;

create index if not exists menu_item_price_suggestions_onsite_idx
  on public.menu_item_price_suggestions(menu_item_id, onsite_verified, created_at desc);

create or replace function public.submit_menu_item_price_suggestion_v3(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_result jsonb;
  v_client_id text := nullif(trim(coalesce(p_client_id, '')), '');
  v_captured_at timestamptz := coalesce(p_captured_at, now());
  v_recent_checkin boolean := false;
  v_onsite boolean := false;
  v_signal text := 'none';
begin
  select mi.business_id
    into v_business_id
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  v_result := public.submit_menu_item_price_suggestion_v2(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url
  );

  if coalesce((v_result->>'ok')::boolean, false) is false then
    return v_result;
  end if;

  if v_business_id is not null and v_client_id is not null then
    v_recent_checkin := public.has_recent_checkin_v1(v_business_id, v_client_id, 180);
  end if;

  v_onsite := v_recent_checkin and v_captured_at >= (now() - interval '6 hours');
  v_signal := case
    when v_onsite then 'checkin_recent'
    when v_client_id is null then 'no_client_id'
    when not v_recent_checkin then 'checkin_missing'
    else 'stale_capture'
  end;

  update public.menu_item_price_suggestions s
  set client_id = coalesce(v_client_id, s.client_id),
      captured_at = v_captured_at,
      onsite_verified = v_onsite,
      onsite_signal = v_signal
  where s.id = (
    select x.id
    from public.menu_item_price_suggestions x
    where x.menu_item_id = p_menu_item_id
      and x.created_by = auth.uid()
    order by x.created_at desc
    limit 1
  );

  return v_result || jsonb_build_object(
    'onsite_verified', v_onsite,
    'onsite_signal', v_signal,
    'xp_multiplier', case when v_onsite then 1.25 else 1.0 end,
    'queue_priority', case when v_onsite then 'high' else 'normal' end
  );
end;
$$;

grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to anon;
grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to service_role;

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
  ),
  consensus as (
    select
      (count(distinct s.created_by) filter (
        where s.created_at >= now() - interval '48 hours'
          and s.status::text = any (array['approved', 'accepted', 'handled', 'verified'])
      ))::int as verified_sources_48h
    from public.menu_item_price_suggestions s
    where s.menu_item_id = p_menu_item_id
  )
  select jsonb_build_object(
    'total_30d', votes.total_30d,
    'ok_30d', votes.ok_30d,
    'bad_30d', votes.bad_30d,
    'my_vote', votes.my_vote,
    'price_cents', latest.price_cents,
    'last_verified_at', latest.last_verified_at,
    'verified_sources_48h', coalesce(consensus.verified_sources_48h, 0),
    'safe_to_trust',
      (
        coalesce(consensus.verified_sources_48h, 0) >= 3
        and coalesce(votes.ok_30d, 0) >= greatest(3, coalesce(votes.bad_30d, 0) * 2)
      ),
    'consensus_status',
      case
        when coalesce(consensus.verified_sources_48h, 0) >= 3
             and coalesce(votes.ok_30d, 0) >= greatest(3, coalesce(votes.bad_30d, 0) * 2)
          then 'strong'
        when coalesce(consensus.verified_sources_48h, 0) >= 2
             and coalesce(votes.ok_30d, 0) > coalesce(votes.bad_30d, 0)
          then 'moderate'
        when coalesce(votes.bad_30d, 0) >= 3
             and coalesce(votes.bad_30d, 0) >= coalesce(votes.ok_30d, 0)
          then 'conflicted'
        else 'weak'
      end,
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
  left join latest on true
  left join consensus on true;
$$;

create or replace function public.get_business_reality_score_v1(
  p_business_id uuid
) returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with recent as (
    select
      (select count(*)::int
       from public.menu_item_price_history h
       join public.menu_items mi on mi.id = h.menu_item_id
       where mi.business_id = p_business_id
         and h.created_at >= now() - interval '30 days') as menu_updates_30d,
      (select count(*)::int
       from public.menu_item_price_suggestions s
       where s.business_id = p_business_id
         and s.status::text = any(array['approved', 'accepted', 'handled', 'verified'])
         and s.created_at >= now() - interval '30 days') as verified_prices_30d,
      (select count(*)::int
       from public.business_checkins c
       where c.business_id = p_business_id
         and c.created_at >= now() - interval '30 days') as checkins_30d,
      (select count(*)::int
       from public.business_media bm
       where bm.business_id = p_business_id
         and bm.created_at >= now() - interval '30 days') as fresh_media_30d,
      (select count(*)::int
       from public.owner_claims oc
       where oc.business_id = p_business_id
         and oc.status::text in ('approved', 'accepted')) as active_owner_claims
  ),
  points as (
    select
      least(30, recent.menu_updates_30d * 6) as p_menu,
      least(25, recent.verified_prices_30d * 5) as p_price,
      least(20, recent.checkins_30d * 2) as p_presence,
      least(15, recent.fresh_media_30d * 3) as p_media,
      case when recent.active_owner_claims > 0 then 10 else 0 end as p_owner,
      recent.*
    from recent
  )
  select jsonb_build_object(
    'score', greatest(0, least(100, points.p_menu + points.p_price + points.p_presence + points.p_media + points.p_owner)),
    'menu_updates_30d', points.menu_updates_30d,
    'verified_prices_30d', points.verified_prices_30d,
    'checkins_30d', points.checkins_30d,
    'fresh_media_30d', points.fresh_media_30d,
    'owner_active', (points.active_owner_claims > 0),
    'warning', case
      when (points.p_menu + points.p_price + points.p_presence + points.p_media + points.p_owner) < 40
        then 'Bilgi eski olabilir; son katkıları kontrol et.'
      else null
    end
  )
  from points;
$$;

grant all on function public.get_business_reality_score_v1(uuid) to anon;
grant all on function public.get_business_reality_score_v1(uuid) to authenticated;
grant all on function public.get_business_reality_score_v1(uuid) to service_role;
