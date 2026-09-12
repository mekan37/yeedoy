-- P2: admin_approve_business_submission_v1 zaten islenmis (status <> 'new')
-- bir basvuruyu reddediyordu ama admin_reject_business_submission_v1'de ayni
-- guard yoktu — onaylanip gercek bir businesses+owner_claims kaydi
-- olusturulmus bir basvuru, sonradan "reddedildi"ye cevrilebiliyordu; halbuki
-- olusturulan isletme kaydi silinmiyordu (durum tutarsizligi).
CREATE OR REPLACE FUNCTION "public"."admin_reject_business_submission_v1"("p_submission_id" "uuid", "p_note" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_status text;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  select status into v_status
  from public.business_submissions
  where id = p_submission_id;

  if v_status is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_status <> 'new' then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  update public.business_submissions
  set status = 'rejected',
      admin_note = p_note
  where id = p_submission_id;

  return jsonb_build_object('ok', true);
end;
$$;
