-- P2: Owner-initiated push campaigns

do $$ begin
  create type public.push_campaign_segment as enum (
    'all_followers', 'loyal_top20', 'inactive_30d', 'new_30d'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.push_campaigns (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid not null references public.businesses(id) on delete cascade,
  title            text not null,
  body             text not null,
  image_url        text,
  target_segment   public.push_campaign_segment default 'all_followers' not null,
  scheduled_at     timestamptz,
  sent_at          timestamptz,
  sent_count       int default 0,
  opened_count     int default 0,
  created_at       timestamptz default now(),
  created_by       uuid references auth.users(id)
);

create index if not exists idx_push_campaigns_biz on public.push_campaigns(business_id, created_at desc);

alter table public.push_campaigns enable row level security;

create policy "push_campaigns_owner_all"
  on public.push_campaigns for all
  using (
    public.is_admin() or public.is_owner_of_business(business_id)
  );

-- RPC: create campaign
create or replace function public.create_push_campaign_v1(
  p_business_id    uuid,
  p_title          text,
  p_body           text,
  p_target_segment text default 'all_followers',
  p_image_url      text default null,
  p_scheduled_at   timestamptz default null
)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    raise exception 'not_authorized';
  end if;

  if length(trim(p_title)) = 0 then raise exception 'title_required'; end if;
  if length(trim(p_body)) > 300 then raise exception 'body_too_long'; end if;

  insert into public.push_campaigns
    (business_id, title, body, image_url, target_segment, scheduled_at, created_by)
  values
    (p_business_id, trim(p_title), trim(p_body), nullif(trim(p_image_url), ''),
     p_target_segment::public.push_campaign_segment, p_scheduled_at, auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

-- RPC: list campaigns for business
create or replace function public.list_push_campaigns_v1(
  p_business_id uuid,
  p_limit       int default 20,
  p_offset      int default 0
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    jsonb_build_object(
      'total', (select count(*) from public.push_campaigns where business_id = p_business_id),
      'items', coalesce(
        (select jsonb_agg(
          jsonb_build_object(
            'id',              pc.id,
            'title',           pc.title,
            'body',            pc.body,
            'target_segment',  pc.target_segment,
            'scheduled_at',    pc.scheduled_at,
            'sent_at',         pc.sent_at,
            'sent_count',      pc.sent_count,
            'opened_count',    pc.opened_count,
            'created_at',      pc.created_at
          )
          order by pc.created_at desc
        )
        from public.push_campaigns pc
        where pc.business_id = p_business_id
        limit greatest(p_limit, 1)
        offset p_offset),
        '[]'::jsonb
      )
    )
  );
$$;

-- RPC: estimate segment size (approximate)
create or replace function public.estimate_campaign_segment_v1(
  p_business_id uuid,
  p_segment     text
)
returns int
language sql stable security definer
set search_path = public
as $$
  select case p_segment
    when 'all_followers' then
      (select count(*)::int from public.business_follows where business_id = p_business_id)
    when 'new_30d' then
      (select count(*)::int from public.business_follows
       where business_id = p_business_id
         and created_at >= now() - interval '30 days')
    else
      (select count(*)::int from public.business_follows where business_id = p_business_id)
  end;
$$;

grant execute on function public.create_push_campaign_v1(uuid, text, text, text, text, timestamptz) to authenticated;
grant execute on function public.list_push_campaigns_v1(uuid, int, int)                              to authenticated;
grant execute on function public.estimate_campaign_segment_v1(uuid, text)                            to authenticated;
