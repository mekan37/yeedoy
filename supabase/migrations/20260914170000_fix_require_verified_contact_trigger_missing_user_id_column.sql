-- KRİTİK BUG (owner panel canlı testinde keşfedildi, orijinal denetimde
-- yoktu): trg_require_verified_contact_v1, NEW.user_id'ye doğrudan
-- erişiyordu. Bu generic trigger 4 tabloya bağlı (business_media,
-- menu_item_photos, menu_item_price_suggestions, reviews) ama yalnızca
-- reviews'ta user_id kolonu var — diğer 3 tabloda yalnızca created_by
-- var. PL/pgSQL'de NEW.olmayan_kolon erişimi COALESCE içinde bile
-- runtime hatası fırlatıyor ("record new has no field user_id") — yani
-- service_role olmayan HERHANGİ bir authenticated kullanıcı bu 3
-- tabloya INSERT yapmaya çalıştığında (örn. add_business_media_v1 RPC'si
-- üzerinden) istek tamamen patlıyordu. Bu muhtemelen fark edilmemişti
-- çünkü bu tabloların çoğu yazma yolu service_role kullanıyor
-- (trigger'ın erken-dönüş kolu) — ama add_business_media_v1 SECURITY
-- DEFINER olsa da orijinal çağıranın auth context'ini koruyor, bu yüzden
-- trigger'a authenticated olarak ulaşıyordu.
--
-- Fix: NEW'i jsonb'ye çevirip alanlara ->> ile erişmek — olmayan bir key
-- sadece NULL döner, hata fırlatmaz.
create or replace function public.trg_require_verified_contact_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid;
  v_role text := current_setting('request.jwt.claim.role', true);
  v_is_verified boolean := false;
  v_new jsonb := to_jsonb(new);
begin
  if v_role = 'service_role' then
    return new;
  end if;

  if auth.uid() is null then
    return new;
  end if;

  v_user_id := coalesce(
    (v_new->>'user_id')::uuid,
    (v_new->>'created_by')::uuid,
    auth.uid()
  );
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
$function$;
