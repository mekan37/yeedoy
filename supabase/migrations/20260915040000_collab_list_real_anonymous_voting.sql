-- `as any` temizliği sırasında bulunan bug: /oyoyla/[token] "Oylar anonim —
-- hesap gerekmez" diyor ama:
--  (a) YAZMA: collab_list_votes.user_id NOT NULL + INSERT RLS'i
--      `user_id = auth.uid()` istiyor — anonim (oturumsuz) her oy denemesi
--      başarısız oluyordu.
--  (b) OKUMA: page.tsx anon istemciyle collab_lists/collab_list_items/
--      collab_list_votes'a doğrudan .select() atıyor, ama SELECT RLS
--      politikaları owner_id=auth.uid() veya üyelik istiyor — oturumsuz
--      ziyaretçi için auth.uid() NULL, yani sayfa her zaman "Davet
--      bulunamadı" gösteriyordu. Özellik hem yazma hem okuma tarafında
--      tamamen kırıktı.
--
-- Çözüm: RLS token'ı JWT'de taşımadığı için satır bazlı politikayla ifade
-- edilemiyor — iki SECURITY DEFINER RPC ile token doğrulanıp veri
-- okunuyor/yazılıyor, gerçek RLS anon'a hâlâ kapalı kalıyor (yalnızca bu
-- iki dar RPC üzerinden erişim var).

alter table public.collab_list_votes alter column user_id drop not null;

create or replace function public.get_collab_list_by_token_v1(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_list record;
  v_items jsonb;
begin
  select id, name, description into v_list
  from public.collab_lists
  where invite_token = p_token;

  if v_list.id is null then
    return jsonb_build_object('error', 'not_found');
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'id', i.id,
      'business_id', i.business_id,
      'name', b.name,
      'slug', b.slug,
      'category', b.category,
      'city', b.city,
      'district', b.district,
      'up_votes', coalesce(v.up, 0),
      'down_votes', coalesce(v.down, 0)
    )
    order by i.created_at
  ) into v_items
  from public.collab_list_items i
  join public.businesses b on b.id = i.business_id and b.is_active = true
  left join (
    select item_id,
      count(*) filter (where vote = 1) as up,
      count(*) filter (where vote = -1) as down
    from public.collab_list_votes
    where list_id = v_list.id
    group by item_id
  ) v on v.item_id = i.id
  where i.list_id = v_list.id;

  return jsonb_build_object(
    'id', v_list.id,
    'name', v_list.name,
    'description', v_list.description,
    'items', coalesce(v_items, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_collab_list_by_token_v1(text) from public;
grant execute on function public.get_collab_list_by_token_v1(text) to anon, authenticated;

create or replace function public.upsert_collab_vote_anon_v1(
  p_token text,
  p_item_id uuid,
  p_vote smallint,
  p_voter_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_list_id uuid;
  v_item_list_id uuid;
begin
  if p_voter_key is null or length(p_voter_key) < 16 then
    return jsonb_build_object('error', 'invalid_voter_key');
  end if;

  select id into v_list_id from public.collab_lists where invite_token = p_token;
  if v_list_id is null then
    return jsonb_build_object('error', 'not_found');
  end if;

  select list_id into v_item_list_id from public.collab_list_items where id = p_item_id;
  if v_item_list_id is null or v_item_list_id <> v_list_id then
    return jsonb_build_object('error', 'item_not_found');
  end if;

  if p_vote = 0 then
    delete from public.collab_list_votes
    where list_id = v_list_id and item_id = p_item_id and voter_ip = p_voter_key;
  elsif p_vote in (1, -1) then
    insert into public.collab_list_votes (list_id, item_id, user_id, vote, voter_ip)
    values (v_list_id, p_item_id, null, p_vote, p_voter_key)
    on conflict (list_id, item_id, voter_ip) where voter_ip is not null
    do update set vote = excluded.vote, voted_at = now();
  else
    return jsonb_build_object('error', 'invalid_vote');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.upsert_collab_vote_anon_v1(text, uuid, smallint, text) from public;
grant execute on function public.upsert_collab_vote_anon_v1(text, uuid, smallint, text) to anon, authenticated;
