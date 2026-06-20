-- group_offer_votes: _archive/20260319_000001_group_offer_votes.sql'den terfi
--
-- base_schema.sql'de vote_group_offer_idempotent_v1 ve get_group_offers_v1 fonksiyonları
-- bu tabloya referans veriyor. Tablo sadece arşivde olduğundan üretim geçmişinde eksikti.
-- IF NOT EXISTS ile güvenli: tablo zaten varsa idempotent çalışır.

create table if not exists public.group_offer_votes (
  offer_id   uuid     not null references public.group_offers(id) on delete cascade,
  user_id    uuid     not null references auth.users(id) on delete cascade,
  vote       smallint not null default 1 check (vote in (1)),
  created_at timestamptz not null default now(),
  primary key (offer_id, user_id)
);

alter table public.group_offer_votes enable row level security;

-- Kullanıcı kendi oyunu görür
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'group_offer_votes'
      and policyname = 'group_offer_votes_select_own'
  ) then
    execute $policy$
      create policy "group_offer_votes_select_own"
        on public.group_offer_votes for select
        using (auth.uid() = user_id)
    $policy$;
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'group_offer_votes'
      and policyname = 'group_offer_votes_insert_own'
  ) then
    execute $policy$
      create policy "group_offer_votes_insert_own"
        on public.group_offer_votes for insert
        with check (auth.uid() = user_id)
    $policy$;
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'group_offer_votes'
      and policyname = 'group_offer_votes_delete_own'
  ) then
    execute $policy$
      create policy "group_offer_votes_delete_own"
        on public.group_offer_votes for delete
        using (auth.uid() = user_id)
    $policy$;
  end if;
end $$;

grant all on table public.group_offer_votes to anon, authenticated, service_role;
