-- Sahip Paneli Güvenlik Denetimi P2: 10-fotoğraf galeri limiti yalnızca
-- app katmanında (fotograflar/route.ts) "count sonra insert" şeklinde
-- kontrol ediliyordu — klasik TOCTOU: iki eşzamanlı yükleme isteği aynı
-- count'u okuyup ikisi de geçebiliyordu. Limiti INSERT ile aynı
-- transaction'da (bu RPC çağrısı) kontrol ederek atomik hale getirildi.
create or replace function public.add_business_media_v1(p_business_id uuid, p_url text, p_url_large text default null::text, p_url_thumb text default null::text, p_provider text default 'wp'::text, p_kind text default 'venue'::text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_shadow boolean := false;
  v_rate jsonb;
  v_gallery_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  if not (public.is_admin() or public.can_manage_business_v1(p_business_id)) then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;

  v_rate := public.consume_rate_limit_v1('business_media', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'business_media_daily_rate_limited');
  end if;

  if coalesce(p_kind, 'venue') = 'gallery' then
    select count(*) into v_gallery_count
    from public.business_media
    where business_id = p_business_id
      and kind = 'gallery'
      and status <> 'rejected'
      and is_hidden = false;

    if v_gallery_count >= 10 then
      return jsonb_build_object('ok', false, 'error', 'photo_limit_reached');
    end if;
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.business_media(
    business_id, kind, url, url_large, url_thumb, provider, created_by, is_shadow
  ) values (
    p_business_id, coalesce(p_kind, 'venue'), p_url, p_url_large, p_url_thumb, p_provider, auth.uid(), v_shadow
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$function$;
