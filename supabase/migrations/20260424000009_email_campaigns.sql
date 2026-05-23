-- Email campaigns table
create table if not exists public.email_campaigns (
  id             uuid primary key default gen_random_uuid(),
  business_id    uuid not null references public.businesses(id) on delete cascade,
  subject        text not null check (char_length(subject) between 1 and 150),
  html_body      text not null,
  target_segment text not null default 'all_followers',
  scheduled_at   timestamptz,
  sent_at        timestamptz,
  sent_count     int not null default 0,
  opened_count   int not null default 0,
  created_at     timestamptz not null default now()
);

alter table public.email_campaigns enable row level security;

create policy "owner_read_email_campaigns"
  on public.email_campaigns for select
  using (
    exists (
      select 1 from public.business_claims bc
      where bc.business_id = email_campaigns.business_id
        and bc.user_id = auth.uid()
        and bc.status = 'approved'
    )
  );

create policy "owner_insert_email_campaigns"
  on public.email_campaigns for insert
  with check (
    exists (
      select 1 from public.business_claims bc
      where bc.business_id = email_campaigns.business_id
        and bc.user_id = auth.uid()
        and bc.status = 'approved'
    )
  );

-- Opt-in column on business_follows
alter table public.business_follows
  add column if not exists is_subscribed_email boolean not null default false;

-- List email campaigns RPC
create or replace function public.list_email_campaigns_v1(
  p_business_id uuid,
  p_limit       int  default 20,
  p_offset      int  default 0
)
returns jsonb
language sql stable security definer
as $$
  select jsonb_build_object(
    'total', count(*) over(),
    'items', coalesce(jsonb_agg(
      jsonb_build_object(
        'id',             id,
        'subject',        subject,
        'target_segment', target_segment,
        'scheduled_at',   scheduled_at,
        'sent_at',        sent_at,
        'sent_count',     sent_count,
        'opened_count',   opened_count,
        'created_at',     created_at
      )
      order by created_at desc
    ), '[]'::jsonb)
  )
  from (
    select *, count(*) over() as total_count
    from public.email_campaigns
    where business_id = p_business_id
    limit p_limit offset p_offset
  ) sub
$$;

grant execute on function public.list_email_campaigns_v1 to authenticated;

-- Create email campaign RPC
create or replace function public.create_email_campaign_v1(
  p_business_id    uuid,
  p_subject        text,
  p_html_body      text,
  p_target_segment text default 'all_followers',
  p_scheduled_at   timestamptz default null
)
returns uuid
language plpgsql security definer
as $$
declare
  v_id uuid;
begin
  if not exists (
    select 1 from public.business_claims
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'approved'
  ) then
    raise exception 'not_authorized';
  end if;

  insert into public.email_campaigns (
    business_id, subject, html_body, target_segment, scheduled_at
  )
  values (p_business_id, p_subject, p_html_body, p_target_segment, p_scheduled_at)
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.create_email_campaign_v1 to authenticated;

-- Estimate email segment (subscribed followers)
create or replace function public.estimate_email_segment_v1(
  p_business_id uuid,
  p_segment     text default 'all_followers'
)
returns int
language sql stable security definer
as $$
  select count(*)::int
  from public.business_follows bf
  join public.profiles p on p.id = bf.follower_id
  where bf.business_id = p_business_id
    and bf.is_subscribed_email = true
    and p.email is not null
    and (
      p_segment = 'all_followers'
      or (p_segment = 'new_30d'     and bf.created_at >= now() - interval '30 days')
      or (p_segment = 'inactive_30d' and bf.created_at < now() - interval '30 days')
    )
$$;

grant execute on function public.estimate_email_segment_v1 to authenticated;
