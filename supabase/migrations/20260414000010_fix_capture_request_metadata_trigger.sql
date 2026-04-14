create or replace function public.capture_request_metadata_v1()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if tg_table_name in ('user_policy_acceptances', 'privacy_requests', 'account_deletion_requests')
     and coalesce(to_jsonb(new)->>'user_id', '') = '' then
    new := jsonb_populate_record(new, jsonb_build_object('user_id', auth.uid()));
  end if;

  if tg_table_name in ('user_policy_acceptances', 'business_policy_acceptances') then
    if coalesce(to_jsonb(new)->>'accepted_at', '') = '' then
      new := jsonb_populate_record(new, jsonb_build_object('accepted_at', now()));
    end if;
    if coalesce(to_jsonb(new)->>'user_agent', '') = '' then
      new := jsonb_populate_record(
        new,
        jsonb_build_object('user_agent', public.request_header_v1('user-agent'))
      );
    end if;
    if coalesce(to_jsonb(new)->>'ip_address', '') = '' then
      new := jsonb_populate_record(
        new,
        jsonb_build_object('ip_address', public.request_ip_v1())
      );
    end if;
  end if;

  if tg_table_name = 'privacy_requests'
     and coalesce(to_jsonb(new)->>'submitted_at', '') = '' then
    new := jsonb_populate_record(new, jsonb_build_object('submitted_at', now()));
  end if;

  if tg_table_name = 'account_deletion_requests'
     and coalesce(to_jsonb(new)->>'requested_at', '') = '' then
    new := jsonb_populate_record(new, jsonb_build_object('requested_at', now()));
  end if;

  return new;
end;
$$;
