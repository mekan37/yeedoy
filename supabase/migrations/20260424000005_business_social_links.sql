-- U2: Business social links
create table if not exists public.business_social_links (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  website     text,
  instagram   text,
  whatsapp    text,   -- phone number incl. country code, e.g. +905001234567
  facebook    text,
  tiktok      text,
  updated_at  timestamptz default now()
);

alter table public.business_social_links enable row level security;

-- Public can read
create policy "social_links_public_read"
  on public.business_social_links for select
  using (true);

-- Owners can upsert their own business's links
create policy "social_links_owner_write"
  on public.business_social_links for all
  using (
    exists (
      select 1 from public.business_claims
      where business_claims.business_id = business_social_links.business_id
        and business_claims.user_id = auth.uid()
        and business_claims.status = 'approved'
    )
  );

-- Read RPC (anon-safe)
create or replace function public.get_business_social_links_v1(p_business_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(
    (select to_jsonb(s) from public.business_social_links s where s.business_id = p_business_id),
    jsonb_build_object(
      'business_id', p_business_id,
      'website', null,
      'instagram', null,
      'whatsapp', null,
      'facebook', null,
      'tiktok', null
    )
  );
$$;

-- Upsert RPC (authenticated owner only)
create or replace function public.upsert_business_social_links_v1(
  p_business_id uuid,
  p_website     text default null,
  p_instagram   text default null,
  p_whatsapp    text default null,
  p_facebook    text default null,
  p_tiktok      text default null
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  -- Verify caller owns this business
  if not exists (
    select 1 from public.business_claims
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'approved'
  ) then
    raise exception 'not_authorized';
  end if;

  insert into public.business_social_links
    (business_id, website, instagram, whatsapp, facebook, tiktok, updated_at)
  values
    (p_business_id, p_website, p_instagram, p_whatsapp, p_facebook, p_tiktok, now())
  on conflict (business_id) do update set
    website    = excluded.website,
    instagram  = excluded.instagram,
    whatsapp   = excluded.whatsapp,
    facebook   = excluded.facebook,
    tiktok     = excluded.tiktok,
    updated_at = excluded.updated_at;
end;
$$;

grant execute on function public.get_business_social_links_v1(uuid) to anon, authenticated;
grant execute on function public.upsert_business_social_links_v1(uuid, text, text, text, text, text) to authenticated;
