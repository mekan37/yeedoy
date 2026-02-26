-- Group offer votes (one vote per user per offer)
create table if not exists public.group_offer_votes (
  offer_id uuid not null references public.group_offers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  vote smallint not null default 1 check (vote in (1)),
  created_at timestamptz not null default now(),
  primary key (offer_id, user_id)
);

alter table public.group_offer_votes enable row level security;

create policy "group_offer_votes_select_own"
  on public.group_offer_votes
  for select
  using (auth.uid() = user_id);

create policy "group_offer_votes_insert_own"
  on public.group_offer_votes
  for insert
  with check (auth.uid() = user_id);

create policy "group_offer_votes_delete_own"
  on public.group_offer_votes
  for delete
  using (auth.uid() = user_id);

-- Returns offers with vote counts + my_vote
create or replace function public.get_group_offers_v1(p_request_id uuid)
returns table(
  id uuid,
  request_id uuid,
  business_id uuid,
  offered_total_cents integer,
  includes jsonb,
  message text,
  status text,
  created_by uuid,
  created_at timestamptz,
  votes_count integer,
  my_vote smallint
) language sql stable as $$
  select
    o.id,
    o.request_id,
    o.business_id,
    o.offered_total_cents,
    o.includes,
    o.message,
    o.status,
    o.created_by,
    o.created_at,
    coalesce(v.count, 0) as votes_count,
    mv.vote as my_vote
  from public.group_offers o
  left join (
    select offer_id, count(*)::int as count
    from public.group_offer_votes
    group by offer_id
  ) v on v.offer_id = o.id
  left join public.group_offer_votes mv
    on mv.offer_id = o.id and mv.user_id = auth.uid()
  where o.request_id = p_request_id
  order by v.count desc, o.created_at desc;
$$;

-- Toggle vote for an offer (1 = voted, 0 = removed)
create or replace function public.vote_group_offer_v1(p_offer_id uuid)
returns jsonb
language plpgsql
as $$
declare
  v_prev smallint;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'unauthorized');
  end if;

  select vote into v_prev
  from public.group_offer_votes
  where offer_id = p_offer_id and user_id = auth.uid();

  if v_prev is null then
    insert into public.group_offer_votes(offer_id, user_id, vote)
    values (p_offer_id, auth.uid(), 1);
    return jsonb_build_object('ok', true, 'mode', 'insert', 'vote', 1);
  else
    delete from public.group_offer_votes
    where offer_id = p_offer_id and user_id = auth.uid();
    return jsonb_build_object('ok', true, 'mode', 'remove', 'vote', 0);
  end if;
end;
$$;

grant all on table public.group_offer_votes to anon, authenticated, service_role;
grant all on function public.get_group_offers_v1(uuid) to anon, authenticated, service_role;
grant all on function public.vote_group_offer_v1(uuid) to anon, authenticated, service_role;
