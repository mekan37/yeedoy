alter table public.menu_item_price_suggestions
  add column if not exists approved_by uuid,
  add column if not exists approved_at timestamp with time zone;
create or replace function public.owner_approve_price_suggestion_v1(p_suggestion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_approve_menu_price_suggestion_v1(p_suggestion_id);
end;
$function$;
create or replace function public.owner_reject_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_reject_menu_price_suggestion_v1(p_suggestion_id, p_reason);
end;
$function$;
create or replace function public.get_owner_price_suggestions_v1(
  p_business_id uuid default null,
  p_status text default 'pending',
  p_limit integer default 30,
  p_offset integer default 0
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with owner_businesses as (
    select c.business_id
    from public.owner_claims c
    where c.user_id = auth.uid()
      and c.status = 'approved'
  ),
  target_businesses as (
    select business_id
    from owner_businesses
    where p_business_id is null
    union all
    select p_business_id
    where p_business_id is not null
  )
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    s.business_id,
    b.name as business_name,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by
  from public.menu_item_price_suggestions s
  join target_businesses tb on tb.business_id = s.business_id
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or s.status::text = p_status)
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$;
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'menu_item_price_suggestions'
      and policyname = 'price_sugg_owner_read'
  ) then
    execute 'create policy price_sugg_owner_read on public.menu_item_price_suggestions
      for select
      using (public.is_owner_of_business(business_id))';
  end if;
end $$;
