-- P3: Email opt-in on business favorite
-- Adds email_optin flag to favorites and a simple RPC to update it.

alter table public.favorites
  add column if not exists email_optin boolean not null default false;

create or replace function public.set_favorite_email_optin_v1(
  p_business_id uuid,
  p_email_optin  boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  update public.favorites
  set email_optin = p_email_optin
  where user_id   = v_user_id
    and business_id = p_business_id;

  return jsonb_build_object('ok', true, 'email_optin', p_email_optin);
end;
$$;

grant execute on function public.set_favorite_email_optin_v1 to authenticated;
