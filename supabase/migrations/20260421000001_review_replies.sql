-- review_replies: işletme sahibi yorumlara yanıt verebilir (bir yoruma en fazla bir yanıt)
create table if not exists public.review_replies (
  id              uuid        primary key default gen_random_uuid(),
  review_id       uuid        not null references public.reviews(id) on delete cascade,
  business_id     uuid        not null references public.businesses(id) on delete cascade,
  owner_user_id   uuid        not null references auth.users(id) on delete cascade,
  content         text        not null check (char_length(content) between 10 and 2000),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint uq_review_reply unique (review_id)
);

create index if not exists idx_review_replies_business_id
  on public.review_replies (business_id);

create index if not exists idx_review_replies_review_id
  on public.review_replies (review_id);

-- updated_at otomatik güncelle
create or replace function public.set_review_reply_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_review_reply_updated_at on public.review_replies;
create trigger trg_review_reply_updated_at
  before update on public.review_replies
  for each row execute function public.set_review_reply_updated_at();

-- RLS
alter table public.review_replies enable row level security;

-- Herkes okuyabilir
create policy "review_replies_public_read"
  on public.review_replies for select
  using (true);

-- Onaylı claim sahibi ekleyebilir/güncelleyebilir
create policy "review_replies_owner_insert"
  on public.review_replies for insert
  with check (
    auth.uid() = owner_user_id
    and exists (
      select 1 from public.business_claims bc
      where bc.business_id = review_replies.business_id
        and bc.user_id = auth.uid()
        and bc.status = 'approved'
    )
  );

create policy "review_replies_owner_update"
  on public.review_replies for update
  using (auth.uid() = owner_user_id);

create policy "review_replies_owner_delete"
  on public.review_replies for delete
  using (auth.uid() = owner_user_id);

-- ---------------------------------------------------------------------------
-- RPC: submit_review_reply
--   İşletme sahibi bir yoruma yanıt verir (upsert — sonradan düzenleyebilir).
-- ---------------------------------------------------------------------------
create or replace function public.submit_review_reply(
  p_review_id uuid,
  p_content   text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_reply_id    uuid;
begin
  -- Review'un işletmesini bul
  select business_id into v_business_id
  from public.reviews
  where id = p_review_id
    and status in ('approved', 'pending');

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'review_not_found');
  end if;

  -- Çağıran kullanıcı bu işletme için onaylı bir claim sahibi mi?
  if not exists (
    select 1 from public.business_claims
    where business_id = v_business_id
      and user_id = auth.uid()
      and status = 'approved'
  ) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  -- Upsert
  insert into public.review_replies (review_id, business_id, owner_user_id, content)
  values (p_review_id, v_business_id, auth.uid(), trim(p_content))
  on conflict (review_id) do update
    set content = excluded.content
  returning id into v_reply_id;

  return jsonb_build_object('ok', true, 'reply_id', v_reply_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: delete_review_reply
-- ---------------------------------------------------------------------------
create or replace function public.delete_review_reply(p_review_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reply_owner uuid;
begin
  select owner_user_id into v_reply_owner
  from public.review_replies
  where review_id = p_review_id;

  if v_reply_owner is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_reply_owner <> auth.uid() then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  delete from public.review_replies where review_id = p_review_id;

  return jsonb_build_object('ok', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: get_review_replies_batch
--   Bir işletmenin review listesi için toplu yanıt çekimi.
-- ---------------------------------------------------------------------------
create or replace function public.get_review_replies_batch(p_review_ids uuid[])
returns table (
  review_id   uuid,
  id          uuid,
  content     text,
  created_at  timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select review_id, id, content, created_at
  from public.review_replies
  where review_id = any(p_review_ids);
$$;

-- ---------------------------------------------------------------------------
-- RPC: get_owner_reviews_v1
--   Panel: işletmeye ait onaylı yorumlar + varsa yanıt içeriği.
-- ---------------------------------------------------------------------------
create or replace function public.get_owner_reviews_v1(
  p_business_id uuid,
  p_sort        text    default 'newest',  -- 'newest' | 'helpful'
  p_limit       int     default 20,
  p_offset      int     default 0
)
returns table (
  id             uuid,
  rating         int,
  title          text,
  content        text,
  helpful_count  int,
  quality_score  numeric,
  created_at     timestamptz,
  status         text,
  reply_id       uuid,
  reply_content  text,
  reply_at       timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.id,
    r.rating,
    r.title,
    r.content,
    coalesce(r.helpful_count, 0) as helpful_count,
    coalesce(r.helpful_count, 0)::numeric as quality_score,
    r.created_at,
    r.status,
    rr.id           as reply_id,
    rr.content      as reply_content,
    rr.created_at   as reply_at
  from public.reviews r
  left join public.review_replies rr on rr.review_id = r.id
  where r.business_id = p_business_id
    and r.status in ('approved', 'pending')
  order by
    case when p_sort = 'helpful' then r.helpful_count end desc nulls last,
    case when p_sort = 'newest'  then r.created_at    end desc nulls last
  limit p_limit
  offset p_offset;
$$;
