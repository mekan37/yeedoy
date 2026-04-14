create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);
create index if not exists notifications_user_created_idx
  on public.notifications(user_id, created_at desc);
create index if not exists notifications_user_unread_idx
  on public.notifications(user_id, is_read, created_at desc);
create index if not exists user_devices_user_last_seen_idx
  on public.user_devices(user_id, last_seen_at desc);
alter table public.notifications enable row level security;
alter table public.user_devices enable row level security;
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
on public.notifications
for select
to authenticated
using (user_id = auth.uid());
drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
drop policy if exists user_devices_select_own on public.user_devices;
create policy user_devices_select_own
on public.user_devices
for select
to authenticated
using (user_id = auth.uid());
drop policy if exists user_devices_insert_own on public.user_devices;
create policy user_devices_insert_own
on public.user_devices
for insert
to authenticated
with check (user_id = auth.uid());
drop policy if exists user_devices_update_own on public.user_devices;
create policy user_devices_update_own
on public.user_devices
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
create or replace function public.notify_user_v1(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if p_user_id is null then
    return null;
  end if;

  insert into public.notifications(user_id, type, title, body, data)
  values (
    p_user_id,
    coalesce(nullif(trim(p_type), ''), 'system'),
    coalesce(nullif(trim(p_title), ''), 'Bildirim'),
    coalesce(nullif(trim(p_body), ''), ''),
    coalesce(p_data, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;
create or replace function public.register_user_device_v1(
  p_fcm_token text,
  p_platform text,
  p_app_version text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;
  if coalesce(trim(p_fcm_token), '') = '' then
    raise exception 'invalid_token';
  end if;
  if coalesce(trim(p_platform), '') = '' then
    raise exception 'invalid_platform';
  end if;

  insert into public.user_devices(user_id, fcm_token, platform, app_version, last_seen_at)
  values (v_user_id, trim(p_fcm_token), lower(trim(p_platform)), nullif(trim(coalesce(p_app_version, '')), ''), now())
  on conflict (user_id, fcm_token)
  do update set
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  returning id into v_id;

  return v_id;
end;
$$;
create or replace function public.mark_notification_read_v1(
  p_notification_id uuid
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.notifications
  set is_read = true
  where id = p_notification_id
    and user_id = auth.uid();

  return found;
end;
$$;
create or replace function public.mark_all_notifications_read_v1()
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_count int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.notifications
  set is_read = true
  where user_id = auth.uid()
    and is_read = false;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
create or replace function public.trg_notify_price_suggestion_result_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_status text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if coalesce(old.status, '') = coalesce(new.status, '') then
    return new;
  end if;

  if coalesce(new.status, '') not in ('approved', 'rejected') then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  v_status := case when new.status = 'approved' then 'onaylandi' else 'reddedildi' end;

  perform public.notify_user_v1(
    new.created_by,
    'price_verification_result',
    case when new.status = 'approved' then 'Fiyat dogrulama onaylandi' else 'Fiyat dogrulama reddedildi' end,
    coalesce(v_business_name, 'Isletme') || ' icin fiyat dogrulaman ' || v_status || '.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'suggestion_id', new.id,
      'status', new.status
    )
  );

  return new;
end;
$$;
drop trigger if exists trg_notify_price_suggestion_result_v1
on public.menu_item_price_suggestions;
create trigger trg_notify_price_suggestion_result_v1
after update on public.menu_item_price_suggestions
for each row
execute function public.trg_notify_price_suggestion_result_v1();
create or replace function public.trg_notify_owner_new_price_suggestion_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.created_by
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_new_price_suggestion',
      'Yeni fiyat onerisi geldi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni bir fiyat onerisi var.',
      jsonb_build_object(
        'business_id', new.business_id,
        'menu_item_id', new.menu_item_id,
        'suggestion_id', new.id
      )
    );
  end loop;

  return new;
end;
$$;
drop trigger if exists trg_notify_owner_new_price_suggestion_v1
on public.menu_item_price_suggestions;
create trigger trg_notify_owner_new_price_suggestion_v1
after insert on public.menu_item_price_suggestions
for each row
execute function public.trg_notify_owner_new_price_suggestion_v1();
create or replace function public.trg_notify_owner_new_review_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.user_id
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_new_review',
      'Yeni yorum geldi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni yorum aldin.',
      jsonb_build_object(
        'business_id', new.business_id,
        'review_id', new.id
      )
    );
  end loop;

  return new;
end;
$$;
drop trigger if exists trg_notify_owner_new_review_v1
on public.reviews;
create trigger trg_notify_owner_new_review_v1
after insert on public.reviews
for each row
execute function public.trg_notify_owner_new_review_v1();
create or replace function public.trg_notify_owner_reported_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  if new.business_id is null then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.user_id
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_business_reported',
      'Isletmen raporlandi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni bir rapor acildi.',
      jsonb_build_object(
        'business_id', new.business_id,
        'report_id', new.id,
        'reason', new.reason
      )
    );
  end loop;

  return new;
end;
$$;
drop trigger if exists trg_notify_owner_reported_v1
on public.reports;
create trigger trg_notify_owner_reported_v1
after insert on public.reports
for each row
execute function public.trg_notify_owner_reported_v1();
create or replace function public.trg_notify_review_reply_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  perform public.notify_user_v1(
    new.review_author_id,
    'review_reply',
    'Yorumuna cevap geldi',
    coalesce(v_business_name, 'Isletme') || ' yorumuna cevap verdi.',
    jsonb_build_object(
      'business_id', new.business_id,
      'review_id', new.review_id,
      'reply_id', new.id
    )
  );

  return new;
end;
$$;
do $$
begin
  if to_regclass('public.review_replies') is not null then
    execute 'drop trigger if exists trg_notify_review_reply_v1 on public.review_replies';
    execute 'create trigger trg_notify_review_reply_v1
      after insert on public.review_replies
      for each row
      execute function public.trg_notify_review_reply_v1()';
  end if;
end;
$$;
create or replace function public.trg_notify_price_alert_event_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_item_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  select mi.name into v_item_name
  from public.menu_items mi
  where mi.id = new.menu_item_id;

  perform public.notify_user_v1(
    new.user_id,
    'favorite_price_changed',
    'Favori urunun fiyati degisti',
    coalesce(v_business_name, 'Isletme') || ' / ' || coalesce(v_item_name, 'Urun') || ' icin yeni fiyat var.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'alert_event_id', new.id,
      'matched_price_cents', new.matched_price_cents,
      'previous_price_cents', new.previous_price_cents,
      'district_avg_price_cents', new.district_avg_price_cents
    )
  );

  return new;
end;
$$;
do $$
begin
  if to_regclass('public.alert_events') is not null then
    execute 'drop trigger if exists trg_notify_price_alert_event_v1 on public.alert_events';
    execute 'create trigger trg_notify_price_alert_event_v1
      after insert on public.alert_events
      for each row
      execute function public.trg_notify_price_alert_event_v1()';
  end if;
end;
$$;
grant execute on function public.register_user_device_v1(text, text, text) to authenticated;
grant execute on function public.mark_notification_read_v1(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read_v1() to authenticated;
