begin;
create or replace function public.sanitize_plain_text_v1(p_text text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(
        regexp_replace(coalesce(p_text, ''), '<[^>]*>', ' ', 'gi'),
        '&[a-zA-Z0-9#]+;',
        ' ',
        'g'
      ),
      '[[:cntrl:]]+',
      ' ',
      'g'
    )
  );
$$;
create or replace function public.mask_contact_tokens_v1(p_text text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          coalesce(p_text, ''),
          '(https?://[^\s]+|www\.[^\s]+|t\.me/[^\s]+|wa\.me/[^\s]+|instagram\.com/[^\s]*)',
          '[gizlendi]',
          'gi'
        ),
        '([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})',
        '[gizlendi]',
        'gi'
      ),
      '(\+?\d[\d\s\-\(\)]{7,}\d)',
      '[gizlendi]',
      'g'
    )
  );
$$;
create or replace function public.contains_contact_or_url_v1(p_text text)
returns boolean
language sql
immutable
as $$
  select coalesce(p_text, '') ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com/|[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))';
$$;
create or replace function public.normalize_for_moderation_v1(p_text text)
returns text
language sql
immutable
as $$
  select regexp_replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(
                        translate(lower(coalesce(p_text, '')), 'çğıöşü', 'cgiosu'),
                        '@',
                        'a'
                      ),
                      '4',
                      'a'
                    ),
                    '0',
                    'o'
                  ),
                  '1',
                  'i'
                ),
                '!',
                'i'
              ),
              '$',
              's'
            ),
            '5',
            's'
          ),
          '3',
          'e'
        ),
        '.',
        ''
      ),
      '_',
      ''
    ),
    '[^a-z0-9]+',
    ' ',
    'g'
  );
$$;
create or replace function public.contains_obfuscated_profanity_v1(p_text text)
returns boolean
language plpgsql
immutable
as $$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
begin
  if v_norm ~* '(^| )a\s*m\s*k( |$)' then
    return true;
  end if;

  if v_compact ~* '(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)' then
    return true;
  end if;

  return false;
end;
$$;
create or replace function public.submit_review_v1(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := public.sanitize_plain_text_v1(p_content);
  v_title text := nullif(public.sanitize_plain_text_v1(p_title), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
  v_has_contact boolean := false;
  v_has_profanity boolean := false;
  v_status text := 'approved';
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_has_contact := public.contains_contact_or_url_v1(coalesce(p_content, ''))
    or public.contains_contact_or_url_v1(v_content);

  v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
    or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

  if v_has_contact then
    v_content := public.mask_contact_tokens_v1(v_content);
    v_title := nullif(public.mask_contact_tokens_v1(coalesce(v_title, '')), '');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();
  v_status := case
    when v_shadow or v_has_contact or v_has_profanity then 'pending'
    else 'approved'
  end;

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content, v_status
  );

  return jsonb_build_object(
    'ok', true,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity
  );
end;
$$;
create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(public.sanitize_plain_text_v1(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and public.contains_contact_or_url_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null and public.contains_obfuscated_profanity_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_profanity');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$$;
create or replace function public.submit_report_v1(
  p_business_id uuid default null,
  p_review_id uuid default null,
  p_menu_item_photo_id uuid default null,
  p_reason text default 'other',
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
  v_target_type text;
  v_target_id uuid;
  v_business_id uuid;
  v_review_id uuid;
  v_photo_id uuid;
  v_reason text := coalesce(nullif(public.sanitize_plain_text_v1(p_reason), ''), 'other');
  v_details text := nullif(public.sanitize_plain_text_v1(p_details), '');
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null and p_review_id is null and p_menu_item_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  if p_menu_item_photo_id is not null then
    v_target_type := 'menu_item_photo';
    v_target_id := p_menu_item_photo_id;
    v_photo_id := p_menu_item_photo_id;
    select business_id into v_business_id
    from public.menu_item_photos
    where id = p_menu_item_photo_id;
    if v_business_id is null then
      return jsonb_build_object('ok', false, 'error', 'photo_not_found');
    end if;
  elsif p_review_id is not null then
    v_target_type := 'review';
    v_target_id := p_review_id;
    v_review_id := p_review_id;
  else
    v_target_type := 'business';
    v_target_id := p_business_id;
    v_business_id := p_business_id;
  end if;

  if v_target_type = 'business' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = v_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  elsif v_target_type = 'review' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = v_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and menu_item_photo_id = v_photo_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    reason,
    details
  )
  values (
    v_uid,
    v_business_id,
    v_review_id,
    v_photo_id,
    v_target_type,
    v_target_id,
    v_reason,
    v_details
  )
  returning id into v_report_id;

  return jsonb_build_object('ok', true, 'report_id', v_report_id);
end;
$$;
commit;
