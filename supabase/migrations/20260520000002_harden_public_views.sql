-- Harden legacy/public views so they do not bypass base-table RLS.

create or replace view public.profiles
with (security_invoker = true)
as
select
  up.user_id as id,
  up.display_name,
  up.avatar_url,
  up.bio,
  up.is_gourmet,
  null::character varying(255) as email
from public.user_profiles up;

alter view public.admin_owner_claims_queue_v1 set (security_invoker = true);
alter view public.admin_reports_queue_v1 set (security_invoker = true);
alter view public.admin_suggestions_v1 set (security_invoker = true);
alter view public.business_rating_summary set (security_invoker = true);
alter view public.business_reviews set (security_invoker = true);
alter view public.expired_temp_uploads_v1 set (security_invoker = true);
alter view public.review_ratings set (security_invoker = true);

revoke all on public.admin_owner_claims_queue_v1 from anon, authenticated;
revoke all on public.admin_reports_queue_v1 from anon, authenticated;
revoke all on public.admin_suggestions_v1 from anon, authenticated;
revoke all on public.business_rating_summary from anon, authenticated;
revoke all on public.business_reviews from anon, authenticated;
revoke all on public.expired_temp_uploads_v1 from anon, authenticated;
revoke all on public.profiles from anon, authenticated;
revoke all on public.review_ratings from anon, authenticated;

grant select on public.business_rating_summary to anon, authenticated;
grant select on public.business_reviews to anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant select on public.review_ratings to anon, authenticated;

grant select on public.admin_owner_claims_queue_v1 to authenticated;
grant select on public.admin_reports_queue_v1 to authenticated;
grant select on public.admin_suggestions_v1 to authenticated;
grant select on public.expired_temp_uploads_v1 to authenticated;

alter view public.admin_business_suggestions_queue_v1 set (security_invoker = true);
alter view public.business_item_trends_v1 set (security_invoker = true);
alter view public.business_price_index_v1 set (security_invoker = true);
alter view public.business_quality_score_v1 set (security_invoker = true);
alter view public.businesses_with_stats set (security_invoker = true);
alter view public.businesses_with_stats_mv set (security_invoker = true);
alter view public.crowd_checkins set (security_invoker = true);
alter view public.menu_item_price_status_v1 set (security_invoker = true);
alter view public.menu_item_value_score_v1 set (security_invoker = true);
alter view public.price_verifications set (security_invoker = true);
alter view public.user_business_signals_v1 set (security_invoker = true);
