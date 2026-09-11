-- B08 (mobil production-readiness denetimi): user_devices tablosunda DELETE
-- politikası hiç yoktu — istemcinin "cihazı kaldır" isteği RLS tarafından
-- sessizce 0 satır siliyordu (hata fırlatmıyordu), UI yine de "başarılı"
-- gösteriyordu. Diğer politikalarla (_own deseni) tutarlı bir DELETE
-- politikası ekleniyor.
CREATE POLICY "user_devices_delete_own" ON public.user_devices
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- B10: log_checkin_v1 anon'a açık ve dedup anahtarı tamamen istemcinin
-- uydurduğu p_client_id'ye dayanıyordu — authenticated bir kullanıcı bile
-- yeni bir client_id ile 10 dakikalık dedup'ı bypass edip sınırsız check-in
-- yazabiliyordu. Bu, business_checkins'in beslediği "kalabalık/popüler"
-- sinyalini manipüle edilebilir hale getiriyor.
--
-- Fix: authenticated çağıranlar için dedup anahtarı artık gerçek
-- auth.uid()'e dayanıyor (client_id rotasyonuyla bypass edilemez). Anon
-- çağrılar (QR taramasıyla menü görüntüleme analitiği — meşru bir kullanım
-- alanı, bu yüzden tamamen kapatılmadı) için client_id bazlı dedup
-- korunuyor, ama işletme başına kaba bir üst sınır eklendi.
CREATE OR REPLACE FUNCTION public.log_checkin_v1(
  p_business_id uuid,
  p_menu_id uuid DEFAULT NULL::uuid,
  p_table_no text DEFAULT NULL::text,
  p_client_id text DEFAULT NULL::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_client_id text := nullif(trim(coalesce(p_client_id, '')), '');
  v_table_no text := nullif(trim(coalesce(p_table_no, '')), '');
  v_dedup_key text;
  v_exists uuid;
  v_recent_count int;
begin
  if p_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_business');
  end if;

  if v_client_id is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if not exists (
    select 1 from public.businesses b where b.id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'business_not_found');
  end if;

  if p_menu_id is not null and not exists (
    select 1 from public.menus m where m.id = p_menu_id and m.business_id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'menu_mismatch');
  end if;

  -- authenticated çağıranlar için dedup gerçek kimliğe bağlı; anon için
  -- (tek meşru anonim kullanım: QR menü taraması) client_id'ye düşer.
  v_dedup_key := coalesce(auth.uid()::text, v_client_id);

  select c.id into v_exists
  from public.business_checkins c
  where c.business_id = p_business_id
    and coalesce(c.user_id::text, c.client_id) = v_dedup_key
    and coalesce(c.table_no, '') = coalesce(v_table_no, '')
    and c.created_at >= now() - interval '10 minutes'
  limit 1;

  if v_exists is not null then
    return jsonb_build_object('ok', true, 'deduped', true, 'id', v_exists);
  end if;

  if auth.uid() is null then
    select count(*) into v_recent_count
    from public.business_checkins c
    where c.business_id = p_business_id
      and c.user_id is null
      and c.created_at >= now() - interval '10 minutes';
    if v_recent_count >= 60 then
      return jsonb_build_object('ok', false, 'code', 'rate_limited');
    end if;
  end if;

  insert into public.business_checkins(
    business_id,
    menu_id,
    table_no,
    client_id,
    user_id
  )
  values (
    p_business_id,
    p_menu_id,
    v_table_no,
    v_client_id,
    auth.uid()
  )
  returning id into v_exists;

  return jsonb_build_object('ok', true, 'id', v_exists);
end;
$function$;
