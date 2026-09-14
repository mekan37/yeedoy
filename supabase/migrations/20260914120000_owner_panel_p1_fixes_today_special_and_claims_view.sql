-- Sahip Paneli Güvenlik Denetimi P2: set_today_special_v1, var olmayan bir
-- businesses.owner_id kolonuna bakıyordu — her çağrı runtime hatasıyla
-- patlıyordu, "Bugünün Spesiyali" özelliği tamamen kırıktı (fail-closed,
-- sömürülebilir değil, ama gerçek bir correctness bug'ı). Diğer owner-only
-- RPC'lerle aynı owner_claims tabanlı kontrole (_is_approved_owner_of_business)
-- geçirildi.
create or replace function public.set_today_special_v1(p_menu_item_id uuid, p_is_special boolean, p_note text default null::text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_business_id UUID;
BEGIN
  SELECT b.id
  INTO v_business_id
  FROM menu_items mi
  JOIN businesses b ON b.id = mi.business_id
  WHERE mi.id = p_menu_item_id;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF NOT public._is_approved_owner_of_business(v_business_id) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  UPDATE menu_items
  SET
    is_today_special = p_is_special,
    special_date     = CASE WHEN p_is_special THEN CURRENT_DATE ELSE NULL END,
    special_note     = CASE WHEN p_is_special THEN p_note       ELSE NULL END
  WHERE id = p_menu_item_id;

  RETURN jsonb_build_object('ok', true, 'business_id', v_business_id);
END;
$function$;

-- P2: business_claims (owner_claims uyumluluk view'ı) anon'a INSERT/
-- UPDATE/DELETE grant'liydi. Şu an owner_claims'in kendi RLS politikaları
-- (yalnızca `authenticated` rolüne TO ile sınırlı) bunu nötralize ediyor,
-- ama tek bir politika değişikliği bunu yeniden açabilirdi — P0-1'in tam
-- olarak nasıl ortaya çıktığı da bu. Anon'un bu view üzerinde hiçbir
-- meşru mutasyon ihtiyacı yok; grant'leri kaldır.
revoke insert, update, delete on public.business_claims from anon;
