-- Migration: 20260504000002_revoke_anon_grants
-- Purpose: Revoke anon role access from functions that require authentication.
--          These functions use auth.uid() internally — anon access is meaningless
--          (they'd return empty/zero data) but unnecessarily widens attack surface.
-- Ref: guvenlik.md G14

-- Profile / personal data functions
revoke execute on function public.get_my_achievements_v1()                                                    from anon;
revoke execute on function public.get_my_achievements_v2()                                                    from anon;
revoke execute on function public.get_my_behavior_segment_v1()                                                from anon;
revoke execute on function public.get_my_daily_micro_task_v1()                                                from anon;
revoke execute on function public.get_my_diet_profile_v1()                                                    from anon;
revoke execute on function public.get_my_favorites_v1(integer, integer)                                       from anon;
revoke execute on function public.get_my_profile_progress_v1()                                                from anon;
revoke execute on function public.get_my_profile_stats()                                                      from anon;
revoke execute on function public.get_my_reputation_score_v1()                                                from anon;
revoke execute on function public.get_my_silent_quality_score_v1()                                            from anon;
revoke execute on function public.get_my_suspended_claim_badge_v1()                                           from anon;
revoke execute on function public.get_my_suspended_claims_v1(text, integer, integer)                          from anon;
revoke execute on function public.get_my_trust_graph_v1()                                                     from anon;
revoke execute on function public.get_my_weekly_missions()                                                    from anon;

-- Ensure authenticated users still have access
grant execute on function public.get_my_achievements_v1()                                                     to authenticated;
grant execute on function public.get_my_achievements_v2()                                                     to authenticated;
grant execute on function public.get_my_behavior_segment_v1()                                                 to authenticated;
grant execute on function public.get_my_daily_micro_task_v1()                                                 to authenticated;
grant execute on function public.get_my_diet_profile_v1()                                                     to authenticated;
grant execute on function public.get_my_favorites_v1(integer, integer)                                        to authenticated;
grant execute on function public.get_my_profile_progress_v1()                                                 to authenticated;
grant execute on function public.get_my_profile_stats()                                                       to authenticated;
grant execute on function public.get_my_reputation_score_v1()                                                 to authenticated;
grant execute on function public.get_my_silent_quality_score_v1()                                             to authenticated;
grant execute on function public.get_my_suspended_claim_badge_v1()                                            to authenticated;
grant execute on function public.get_my_suspended_claims_v1(text, integer, integer)                           to authenticated;
grant execute on function public.get_my_trust_graph_v1()                                                      to authenticated;
grant execute on function public.get_my_weekly_missions()                                                     to authenticated;
