-- Moat signals: trust graph, behavior segment, and silent quality score.

create or replace function public.get_my_trust_graph_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_price_approved int := 0;
  v_price_rejected int := 0;
  v_review_published int := 0;
  v_review_rejected int := 0;
  v_report_resolved int := 0;
  v_report_rejected int := 0;
  v_spam_signals int := 0;
  v_accuracy numeric := 0;
  v_trust int := 0;
begin
  if v_user is null then
    return jsonb_build_object(
      'trusted_actions', 0,
      'rejected_actions', 0,
      'spam_signals', 0,
      'accuracy_score', 0,
      'trust_score', 0
    );
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    select
      count(*) filter (where status = any(array['approved','accepted','handled','verified'])),
      count(*) filter (where status = 'rejected')
    into v_price_approved, v_price_rejected
    from public.menu_item_price_suggestions
    where created_by = v_user;
  end if;

  if to_regclass('public.reviews') is not null then
    select
      count(*) filter (where status = any(array['approved','published'])),
      count(*) filter (where status = 'rejected')
    into v_review_published, v_review_rejected
    from public.reviews
    where user_id = v_user;
  end if;

  if to_regclass('public.reports') is not null then
    select
      count(*) filter (where status = any(array['resolved','handled','accepted'])),
      count(*) filter (where status = 'rejected')
    into v_report_resolved, v_report_rejected
    from public.reports
    where created_by = v_user;
  end if;

  if to_regclass('public.user_rate_limits') is not null then
    select count(*)
      into v_spam_signals
    from public.user_rate_limits
    where user_id = v_user
      and day >= current_date - 30
      and action in (
        'review_submit',
        'price_suggestion_submit',
        'business_media_upload',
        'menu_photo_upload'
      )
      and count >= 10;
  end if;

  v_accuracy :=
    (
      (v_price_approved + v_review_published + v_report_resolved)::numeric /
      nullif(
        (v_price_approved + v_review_published + v_report_resolved + v_price_rejected + v_review_rejected + v_report_rejected),
        0
      )::numeric
    );
  if v_accuracy is null then
    v_accuracy := 0;
  end if;

  v_trust := round(
    least(
      100::numeric,
      greatest(
        0::numeric,
        (v_accuracy * 70) +
        least(20, (v_price_approved + v_review_published + v_report_resolved)) -
        least(30, v_spam_signals * 6)
      )
    )
  )::int;

  return jsonb_build_object(
    'trusted_actions', (v_price_approved + v_review_published + v_report_resolved),
    'rejected_actions', (v_price_rejected + v_review_rejected + v_report_rejected),
    'spam_signals', v_spam_signals,
    'accuracy_score', round(v_accuracy * 100),
    'trust_score', v_trust
  );
end;
$$;
grant all on function public.get_my_trust_graph_v1() to anon;
grant all on function public.get_my_trust_graph_v1() to authenticated;
grant all on function public.get_my_trust_graph_v1() to service_role;
create or replace function public.get_my_behavior_segment_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_price_actions int := 0;
  v_discovery_actions int := 0;
  v_photo_actions int := 0;
  v_total int := 0;
  v_primary text := 'balanced';
begin
  if v_user is null then
    return jsonb_build_object(
      'primary_segment', 'balanced',
      'price_actions', 0,
      'discovery_actions', 0,
      'photo_actions', 0
    );
  end if;

  if to_regclass('public.menu_item_price_votes') is not null then
    select count(*) into v_price_actions
    from public.menu_item_price_votes
    where user_id = v_user
      and created_at >= now() - interval '90 days';
  end if;

  if to_regclass('public.analytics_events') is not null then
    select count(*) into v_discovery_actions
    from public.analytics_events
    where user_id = v_user
      and created_at >= now() - interval '90 days'
      and event_name in ('discovery_business_click', 'business_page_view', 'menu_link_opened');
  end if;

  if to_regclass('public.business_media') is not null then
    select count(*) into v_photo_actions
    from public.business_media
    where created_by = v_user
      and created_at >= now() - interval '90 days';
  end if;

  v_total := v_price_actions + v_discovery_actions + v_photo_actions;
  if v_total = 0 then
    v_primary := 'balanced';
  elsif v_price_actions >= v_discovery_actions and v_price_actions >= v_photo_actions then
    v_primary := 'price_hunter';
  elsif v_photo_actions >= v_discovery_actions and v_photo_actions >= v_price_actions then
    v_primary := 'photo_proof';
  else
    v_primary := 'explorer';
  end if;

  return jsonb_build_object(
    'primary_segment', v_primary,
    'price_actions', v_price_actions,
    'discovery_actions', v_discovery_actions,
    'photo_actions', v_photo_actions
  );
end;
$$;
grant all on function public.get_my_behavior_segment_v1() to anon;
grant all on function public.get_my_behavior_segment_v1() to authenticated;
grant all on function public.get_my_behavior_segment_v1() to service_role;
create or replace function public.get_my_silent_quality_score_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_contribution_count int := 0;
  v_approved_count int := 0;
  v_review_count int := 0;
  v_score int := 0;
begin
  if v_user is null then
    return jsonb_build_object(
      'silent_quality_score', 0,
      'is_silent_quality', false,
      'approved_count', 0,
      'contribution_count', 0
    );
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    select
      count(*),
      count(*) filter (where status = any(array['approved','accepted','handled','verified']))
    into v_contribution_count, v_approved_count
    from public.menu_item_price_suggestions
    where created_by = v_user
      and created_at >= now() - interval '180 days';
  end if;

  if to_regclass('public.reviews') is not null then
    select count(*)
      into v_review_count
    from public.reviews
    where user_id = v_user
      and created_at >= now() - interval '180 days';
  end if;

  v_score := round(
    least(
      100::numeric,
      greatest(
        0::numeric,
        (
          (coalesce(v_approved_count, 0)::numeric / nullif(v_contribution_count, 0)::numeric) * 80
        ) + least(20, v_approved_count)
      )
    )
  )::int;
  if v_contribution_count = 0 then
    v_score := 0;
  end if;

  return jsonb_build_object(
    'silent_quality_score', v_score,
    'is_silent_quality', (v_review_count <= 2 and v_approved_count >= 5 and v_score >= 70),
    'approved_count', v_approved_count,
    'contribution_count', v_contribution_count
  );
end;
$$;
grant all on function public.get_my_silent_quality_score_v1() to anon;
grant all on function public.get_my_silent_quality_score_v1() to authenticated;
grant all on function public.get_my_silent_quality_score_v1() to service_role;
