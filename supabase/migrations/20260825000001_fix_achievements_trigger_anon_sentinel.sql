-- log_event_v1 substitutes the zero-UUID sentinel (00000000-0000-0000-0000-000000000000)
-- for auth.uid() when the caller is anonymous. trg_recompute_achievements_analytics_v1 only
-- checked `new.user_id is not null`, so it treated that sentinel as a real user and called
-- recompute_user_achievements_v1(), which violates user_achievements_user_id_fkey since the
-- sentinel has no matching public.users row. Every anonymous business_page_view (and any other
-- tracked event) was throwing a 500 on POST /sunucu/izleme.
CREATE OR REPLACE FUNCTION public.trg_recompute_achievements_analytics_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
begin
  if new.user_id is not null and new.user_id <> '00000000-0000-0000-0000-000000000000'::uuid then
    perform public.recompute_user_achievements_v1(new.user_id);
  end if;
  return new;
end;
$function$;

COMMENT ON FUNCTION public.trg_recompute_achievements_analytics_v1 IS 'Recomputes achievement progress after an analytics_events insert; skips anonymous visitors (log_event_v1 substitutes the zero-UUID sentinel for auth.uid() when unauthenticated, which has no matching public.users row).';
