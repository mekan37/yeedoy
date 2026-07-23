-- Harden legacy/public views so they do not bypass base-table RLS.
--
-- Note (2026-07-23 fix): crowd_checkins, price_verifications, business_reviews
-- and review_ratings existed as views when this migration was first written,
-- but were later dropped/renamed elsewhere in the migration history before
-- the schema was squashed into 00000000000000_base_schema.sql — so a fresh
-- `supabase db reset` fails on ALTER/REVOKE/GRANT against them ("relation
-- does not exist"). Those four are now guarded with existence checks so this
-- migration is safe to replay from scratch; behavior against a database
-- where they still exist (e.g. an already-migrated remote) is unchanged.

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
alter view public.expired_temp_uploads_v1 set (security_invoker = true);

do $$
begin
  if to_regclass('public.business_reviews') is not null then
    execute 'alter view public.business_reviews set (security_invoker = true)';
  end if;
  -- review_ratings artık bir TABLO (2026-07-23, bkz. aşağıdaki not) —
  -- ALTER VIEW hedefi olamaz, kasıtlı olarak burada atlanıyor.
end
$$;

revoke all on public.admin_owner_claims_queue_v1 from anon, authenticated;
revoke all on public.admin_reports_queue_v1 from anon, authenticated;
revoke all on public.admin_suggestions_v1 from anon, authenticated;
revoke all on public.business_rating_summary from anon, authenticated;
revoke all on public.expired_temp_uploads_v1 from anon, authenticated;
revoke all on public.profiles from anon, authenticated;

grant select on public.business_rating_summary to anon, authenticated;
grant select on public.profiles to anon, authenticated;

grant select on public.admin_owner_claims_queue_v1 to authenticated;
grant select on public.admin_reports_queue_v1 to authenticated;
grant select on public.admin_suggestions_v1 to authenticated;
grant select on public.expired_temp_uploads_v1 to authenticated;

do $$
begin
  if to_regclass('public.business_reviews') is not null then
    execute 'revoke all on public.business_reviews from anon, authenticated';
    execute 'grant select on public.business_reviews to anon, authenticated';
  end if;
  if to_regclass('public.review_ratings') is not null then
    execute 'revoke all on public.review_ratings from anon, authenticated';
    execute 'grant select on public.review_ratings to anon, authenticated';
  end if;
end
$$;

alter view public.admin_business_suggestions_queue_v1 set (security_invoker = true);
alter view public.business_item_trends_v1 set (security_invoker = true);
alter view public.business_price_index_v1 set (security_invoker = true);
alter view public.business_quality_score_v1 set (security_invoker = true);
alter view public.businesses_with_stats set (security_invoker = true);
alter view public.businesses_with_stats_mv set (security_invoker = true);
alter view public.menu_item_price_status_v1 set (security_invoker = true);
alter view public.menu_item_value_score_v1 set (security_invoker = true);
alter view public.user_business_signals_v1 set (security_invoker = true);

do $$
begin
  if to_regclass('public.crowd_checkins') is not null then
    execute 'alter view public.crowd_checkins set (security_invoker = true)';
  end if;
  if to_regclass('public.price_verifications') is not null then
    execute 'alter view public.price_verifications set (security_invoker = true)';
  end if;
  -- review_ratings 2026-07-23'te bir TABLO olarak (yeniden) oluşturuldu
  -- (bkz. 20260422000005_reviews_sort_verified.sql) — bu yüzden burada
  -- ALTER VIEW hedefi değil, kasıtlı olarak atlanıyor.
end
$$;
