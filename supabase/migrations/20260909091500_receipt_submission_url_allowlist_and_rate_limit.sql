-- B27 (mobil production-readiness denetimi): submit_receipt_submission_v1
-- p_image_url'i hiç doğrulamıyordu — herhangi bir authenticated kullanıcı
-- keyfi (bizim storage'ımıza ait olmayan) bir URL gönderebiliyordu; bu satır
-- daha sonra admin moderasyon kuyruğunda açılıyor. Ayrıca oran sınırı yoktu.
--
-- Fix: image_url artık yalnızca kendi Supabase Storage bucket'larımızdan
-- (menu-media / menu-media-private — bkz. media-upload-user edge function)
-- gelen bir URL olabilir; ayrıca kullanıcı başına kaba bir günlük üst sınır
-- eklendi (log_checkin_v1 / B10 ile aynı desen).
CREATE OR REPLACE FUNCTION public.submit_receipt_submission_v1(
  p_business_id uuid,
  p_image_url text,
  p_matches jsonb DEFAULT '[]'::jsonb
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
  v_image_url text := trim(coalesce(p_image_url, ''));
  v_recent_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if v_image_url = '' then
    return jsonb_build_object('ok', false, 'code', 'invalid_image');
  end if;

  if v_image_url !~ '^https?://[^/]+/storage/v1/object/(public|sign)/menu-media(-private)?/' then
    return jsonb_build_object('ok', false, 'code', 'invalid_image');
  end if;

  if p_business_id is null or not exists (
    select 1 from public.businesses b where b.id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'business_not_found');
  end if;

  select count(*) into v_recent_count
  from public.receipt_submissions r
  where r.user_id = auth.uid()
    and r.created_at >= now() - interval '1 day';
  if v_recent_count >= 30 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.receipt_submissions(user_id, business_id, image_url)
  values (auth.uid(), p_business_id, v_image_url)
  returning id into v_id;

  insert into public.receipt_matches(receipt_id, menu_item_id, detected_price_cents)
  select
    v_id,
    (m->>'menu_item_id')::uuid,
    greatest(((m->>'detected_price_cents')::int), 0)
  from jsonb_array_elements(coalesce(p_matches, '[]'::jsonb)) as m
  join public.menu_items mi on mi.id = (m->>'menu_item_id')::uuid
  where mi.business_id = p_business_id
    and (m->>'detected_price_cents') is not null;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;
