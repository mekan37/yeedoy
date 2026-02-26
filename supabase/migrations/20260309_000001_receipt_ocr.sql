create table if not exists public.receipt_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  image_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.receipt_matches (
  receipt_id uuid not null references public.receipt_submissions(id) on delete cascade,
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  detected_price_cents int not null,
  primary key (receipt_id, menu_item_id)
);

create index if not exists receipt_submissions_user_idx
  on public.receipt_submissions (user_id, created_at desc);

create index if not exists receipt_submissions_business_idx
  on public.receipt_submissions (business_id, created_at desc);

create index if not exists receipt_matches_receipt_idx
  on public.receipt_matches (receipt_id);

alter table public.receipt_submissions enable row level security;
alter table public.receipt_matches enable row level security;

drop policy if exists receipt_submissions_owner_select on public.receipt_submissions;
create policy receipt_submissions_owner_select
  on public.receipt_submissions
  for select
  using (user_id = auth.uid());

drop policy if exists receipt_submissions_owner_insert on public.receipt_submissions;
create policy receipt_submissions_owner_insert
  on public.receipt_submissions
  for insert
  with check (user_id = auth.uid());

drop policy if exists receipt_submissions_admin_all on public.receipt_submissions;
create policy receipt_submissions_admin_all
  on public.receipt_submissions
  for all
  using (public.is_admin());

drop policy if exists receipt_matches_owner_select on public.receipt_matches;
create policy receipt_matches_owner_select
  on public.receipt_matches
  for select
  using (
    exists (
      select 1
      from public.receipt_submissions s
      where s.id = receipt_id
        and s.user_id = auth.uid()
    )
  );

drop policy if exists receipt_matches_owner_insert on public.receipt_matches;
create policy receipt_matches_owner_insert
  on public.receipt_matches
  for insert
  with check (
    exists (
      select 1
      from public.receipt_submissions s
      where s.id = receipt_id
        and s.user_id = auth.uid()
    )
  );

drop policy if exists receipt_matches_admin_all on public.receipt_matches;
create policy receipt_matches_admin_all
  on public.receipt_matches
  for all
  using (public.is_admin());

create or replace function public.submit_receipt_submission_v1(
  p_business_id uuid,
  p_image_url text,
  p_matches jsonb default '[]'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if p_image_url is null or length(trim(p_image_url)) = 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid_image');
  end if;

  insert into public.receipt_submissions(user_id, business_id, image_url)
  values (auth.uid(), p_business_id, trim(p_image_url))
  returning id into v_id;

  insert into public.receipt_matches(receipt_id, menu_item_id, detected_price_cents)
  select
    v_id,
    (m->>'menu_item_id')::uuid,
    greatest(((m->>'detected_price_cents')::int), 0)
  from jsonb_array_elements(coalesce(p_matches, '[]'::jsonb)) as m
  join public.menu_items mi on mi.id = (m->>'menu_item_id')::uuid
  where mi.business_id = p_business_id
    and (m->>'detected_price_cents') is not null;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_list_receipt_submissions_v1(
  p_limit int default 50,
  p_offset int default 0
) returns table(
  receipt_id uuid,
  created_at timestamptz,
  user_id uuid,
  business_id uuid,
  business_name text,
  image_url text,
  matches_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as receipt_id,
    s.created_at,
    s.user_id,
    s.business_id,
    b.name as business_name,
    s.image_url,
    coalesce(m.cnt, 0) as matches_count
  from public.receipt_submissions s
  join public.businesses b on b.id = s.business_id
  left join (
    select receipt_id, count(*)::int as cnt
    from public.receipt_matches
    group by receipt_id
  ) m on m.receipt_id = s.id
  where public.is_admin()
  order by s.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;
