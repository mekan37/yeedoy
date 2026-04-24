-- C4: Collaborative restaurant lists with multi-user voting
-- Tables: collab_lists, collab_list_members, collab_list_items, collab_list_votes

-- ── collab_lists ────────────────────────────────────────────────────────────
create table if not exists public.collab_lists (
  id             uuid primary key default gen_random_uuid(),
  owner_id       uuid not null references auth.users(id) on delete cascade,
  name           text not null check (char_length(name) between 1 and 80),
  description    text check (char_length(description) <= 280),
  invite_token   text not null unique default encode(gen_random_bytes(12), 'hex'),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

alter table public.collab_lists enable row level security;

create policy "owner full access on collab_lists"
  on public.collab_lists
  for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "members can read collab_lists"
  on public.collab_lists
  for select
  using (
    exists (
      select 1 from public.collab_list_members m
      where m.list_id = id and m.user_id = auth.uid()
    )
  );

-- ── collab_list_members ──────────────────────────────────────────────────────
create table if not exists public.collab_list_members (
  id         uuid primary key default gen_random_uuid(),
  list_id    uuid not null references public.collab_lists(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  unique (list_id, user_id)
);

alter table public.collab_list_members enable row level security;

create policy "owner and members can read collab_list_members"
  on public.collab_list_members
  for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.collab_lists l
      where l.id = list_id and l.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.collab_list_members m2
      where m2.list_id = list_id and m2.user_id = auth.uid()
    )
  );

create policy "authenticated users can join via invite (insert own row)"
  on public.collab_list_members
  for insert
  with check (user_id = auth.uid());

create policy "owner can remove members, members can leave"
  on public.collab_list_members
  for delete
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.collab_lists l
      where l.id = list_id and l.owner_id = auth.uid()
    )
  );

-- ── collab_list_items ────────────────────────────────────────────────────────
create table if not exists public.collab_list_items (
  id          uuid primary key default gen_random_uuid(),
  list_id     uuid not null references public.collab_lists(id) on delete cascade,
  business_id uuid not null,
  added_by    uuid not null references auth.users(id) on delete set null,
  note        text check (char_length(note) <= 280),
  created_at  timestamptz not null default now(),
  unique (list_id, business_id)
);

alter table public.collab_list_items enable row level security;

create policy "members and owner can read collab_list_items"
  on public.collab_list_items
  for select
  using (
    exists (
      select 1 from public.collab_lists l
      where l.id = list_id
        and (l.owner_id = auth.uid()
          or exists (
            select 1 from public.collab_list_members m
            where m.list_id = list_id and m.user_id = auth.uid()
          ))
    )
  );

create policy "members and owner can insert collab_list_items"
  on public.collab_list_items
  for insert
  with check (
    added_by = auth.uid()
    and exists (
      select 1 from public.collab_lists l
      where l.id = list_id
        and (l.owner_id = auth.uid()
          or exists (
            select 1 from public.collab_list_members m
            where m.list_id = list_id and m.user_id = auth.uid()
          ))
    )
  );

create policy "adder or owner can delete collab_list_items"
  on public.collab_list_items
  for delete
  using (
    added_by = auth.uid()
    or exists (
      select 1 from public.collab_lists l
      where l.id = list_id and l.owner_id = auth.uid()
    )
  );

-- ── collab_list_votes ────────────────────────────────────────────────────────
create table if not exists public.collab_list_votes (
  id       uuid primary key default gen_random_uuid(),
  list_id  uuid not null references public.collab_lists(id) on delete cascade,
  item_id  uuid not null references public.collab_list_items(id) on delete cascade,
  user_id  uuid not null references auth.users(id) on delete cascade,
  vote     smallint not null check (vote in (1, -1)),
  voted_at timestamptz not null default now(),
  unique (item_id, user_id)
);

alter table public.collab_list_votes enable row level security;

create policy "members and owner can read collab_list_votes"
  on public.collab_list_votes
  for select
  using (
    exists (
      select 1 from public.collab_lists l
      where l.id = list_id
        and (l.owner_id = auth.uid()
          or exists (
            select 1 from public.collab_list_members m
            where m.list_id = list_id and m.user_id = auth.uid()
          ))
    )
  );

create policy "members and owner can vote"
  on public.collab_list_votes
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.collab_lists l
      where l.id = list_id
        and (l.owner_id = auth.uid()
          or exists (
            select 1 from public.collab_list_members m
            where m.list_id = list_id and m.user_id = auth.uid()
          ))
    )
  );

create policy "members and owner can change own vote"
  on public.collab_list_votes
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "members can remove own vote"
  on public.collab_list_votes
  for delete
  using (user_id = auth.uid());

-- ── RPC: join via invite token ───────────────────────────────────────────────
create or replace function public.join_collab_list_v1(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_list_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('error', 'not_authenticated');
  end if;

  select id into v_list_id
  from public.collab_lists
  where invite_token = p_token;

  if v_list_id is null then
    return jsonb_build_object('error', 'invalid_token');
  end if;

  -- owner is already a member implicitly; skip insert if already member
  insert into public.collab_list_members (list_id, user_id)
  values (v_list_id, v_user_id)
  on conflict (list_id, user_id) do nothing;

  return jsonb_build_object('list_id', v_list_id::text, 'ok', true);
end;
$$;

-- ── RPC: upsert vote ────────────────────────────────────────────────────────
create or replace function public.upsert_collab_vote_v1(
  p_item_id uuid,
  p_vote    smallint  -- 1 or -1; 0 = remove vote
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_list_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('error', 'not_authenticated');
  end if;

  select list_id into v_list_id
  from public.collab_list_items
  where id = p_item_id;

  if v_list_id is null then
    return jsonb_build_object('error', 'item_not_found');
  end if;

  if p_vote = 0 then
    delete from public.collab_list_votes
    where item_id = p_item_id and user_id = v_user_id;
  else
    insert into public.collab_list_votes (list_id, item_id, user_id, vote)
    values (v_list_id, p_item_id, v_user_id, p_vote)
    on conflict (item_id, user_id)
    do update set vote = excluded.vote, voted_at = now();
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

-- ── RPC: get list with items + votes ────────────────────────────────────────
create or replace function public.get_collab_list_detail_v1(p_list_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_list    jsonb;
  v_items   jsonb;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('error', 'not_authenticated');
  end if;

  select to_jsonb(l) into v_list
  from public.collab_lists l
  where l.id = p_list_id
    and (l.owner_id = v_user_id
      or exists (
        select 1 from public.collab_list_members m
        where m.list_id = l.id and m.user_id = v_user_id
      ));

  if v_list is null then
    return jsonb_build_object('error', 'not_found');
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'id', i.id,
      'business_id', i.business_id,
      'added_by', i.added_by,
      'note', i.note,
      'created_at', i.created_at,
      'score', coalesce(vote_agg.score, 0),
      'my_vote', coalesce(my_vote.vote, 0)
    )
    order by coalesce(vote_agg.score, 0) desc, i.created_at
  ) into v_items
  from public.collab_list_items i
  left join (
    select item_id, sum(vote) as score
    from public.collab_list_votes
    where list_id = p_list_id
    group by item_id
  ) vote_agg on vote_agg.item_id = i.id
  left join (
    select item_id, vote
    from public.collab_list_votes
    where user_id = v_user_id
  ) my_vote on my_vote.item_id = i.id
  where i.list_id = p_list_id;

  return jsonb_build_object(
    'list', v_list,
    'items', coalesce(v_items, '[]'::jsonb)
  );
end;
$$;
