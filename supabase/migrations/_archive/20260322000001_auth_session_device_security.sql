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
  values (
    v_user_id,
    trim(p_fcm_token),
    lower(trim(p_platform)),
    nullif(trim(coalesce(p_app_version, '')), ''),
    now()
  )
  on conflict (user_id, fcm_token)
  do update set
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  returning id into v_id;

  delete from public.user_devices d
  where d.user_id = v_user_id
    and (
      d.last_seen_at < now() - interval '120 days'
      or d.id in (
        select stale.id
        from public.user_devices stale
        where stale.user_id = v_user_id
        order by stale.last_seen_at desc
        offset 10
      )
    );

  return v_id;
end;
$$;
create or replace function public.unregister_user_device_v1(
  p_fcm_token text default null
)
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_count int := 0;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if coalesce(trim(coalesce(p_fcm_token, '')), '') = '' then
    update public.user_devices
    set last_seen_at = now() - interval '365 days'
    where user_id = v_user_id;
    get diagnostics v_count = row_count;
    return v_count;
  end if;

  delete from public.user_devices
  where user_id = v_user_id
    and fcm_token = trim(p_fcm_token);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
grant execute on function public.unregister_user_device_v1(text) to authenticated;
create or replace function public.trg_require_verified_contact_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
  v_role text := current_setting('request.jwt.claim.role', true);
  v_is_verified boolean := false;
begin
  if v_role = 'service_role' then
    return new;
  end if;

  if auth.uid() is null then
    return new;
  end if;

  v_user_id := coalesce(new.user_id, new.created_by, auth.uid());
  if v_user_id is null then
    raise exception 'contact_verification_required';
  end if;

  select
    (u.email_confirmed_at is not null or u.phone_confirmed_at is not null)
  into v_is_verified
  from auth.users u
  where u.id = v_user_id;

  if coalesce(v_is_verified, false) = false then
    raise exception 'contact_verification_required';
  end if;

  return new;
end;
$$;
drop trigger if exists trg_reviews_require_verified_contact_v1 on public.reviews;
create trigger trg_reviews_require_verified_contact_v1
before insert on public.reviews
for each row
execute function public.trg_require_verified_contact_v1();
drop trigger if exists trg_price_suggestions_require_verified_contact_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_require_verified_contact_v1
before insert on public.menu_item_price_suggestions
for each row
execute function public.trg_require_verified_contact_v1();
drop trigger if exists trg_menu_item_photos_require_verified_contact_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_require_verified_contact_v1
before insert on public.menu_item_photos
for each row
execute function public.trg_require_verified_contact_v1();
drop trigger if exists trg_business_media_require_verified_contact_v1 on public.business_media;
create trigger trg_business_media_require_verified_contact_v1
before insert on public.business_media
for each row
execute function public.trg_require_verified_contact_v1();
