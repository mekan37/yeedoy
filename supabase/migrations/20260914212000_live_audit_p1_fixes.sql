-- Canlı Supabase Güvenlik & Bütünlük Denetimi P1 grubu.

-- ── 1) table_orders RPC üçlüsü: SECURITY DEFINER + anon-grant + gövde içi
-- yetki kontrolü yok. RLS doğru (using:false) ama DEFINER fonksiyonlar onu
-- bypass ediyor. 2-arg update_table_order_status_v1 var-olmayan
-- businesses.owner_id'ye bakıyor (runtime'da her zaman patlar, ölü) —
-- DROP ediliyor. Yeni 'orders_manage' izni staff rütbesinde (rank>=200,
-- media_upload/qr_manage ile aynı seviye — masa siparişi yönetimi zaten bir
-- saha/personel işi).
create or replace function public.business_role_has_permission_v1(p_role text, p_permission text)
returns boolean
language sql
stable security definer
set search_path to 'public'
as $function$
  select case lower(coalesce(p_permission, ''))
    when 'business_read' then public.business_role_rank_v1(p_role) >= 100
    when 'analytics_view' then public.business_role_rank_v1(p_role) >= 100
    when 'media_upload' then public.business_role_rank_v1(p_role) >= 200
    when 'qr_manage' then public.business_role_rank_v1(p_role) >= 200
    when 'orders_manage' then public.business_role_rank_v1(p_role) >= 200
    when 'menu_write' then public.business_role_rank_v1(p_role) >= 300
    when 'business_write' then public.business_role_rank_v1(p_role) >= 400
    when 'team_manage' then public.business_role_rank_v1(p_role) >= 400
    else false
  end;
$function$;

drop function if exists public.update_table_order_status_v1(uuid, text);

create or replace function public.get_pending_table_orders_v1(p_business_id uuid, p_limit integer default 20)
returns table(id uuid, table_number text, items_json jsonb, customer_note text, status text, created_at timestamptz)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'orders_manage')) then
    raise exception 'forbidden' using errcode = 'P0002';
  end if;

  return query
    select o.id, o.table_number, o.items_json, o.customer_note, o.status, o.created_at
    from public.table_orders o
    where o.business_id = p_business_id
      and o.status in ('pending', 'seen')
    order by o.created_at desc
    limit p_limit;
end;
$function$;

create or replace function public.update_table_order_status_v1(p_order_id uuid, p_status text, p_business_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'orders_manage')) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_status not in ('pending', 'seen', 'waiting', 'done') then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  update public.table_orders
  set
    status       = p_status,
    processed_by = auth.uid(),
    seen_at      = case when p_status = 'seen'  then now() else seen_at  end,
    done_at      = case when p_status = 'done'  then now() else done_at  end,
    updated_at   = now()
  where id = p_order_id
    and business_id = p_business_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.update_table_order_staff_note_v1(p_order_id uuid, p_staff_note text, p_business_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'orders_manage')) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  update public.table_orders
  set staff_note = p_staff_note, updated_at = now()
  where id = p_order_id and business_id = p_business_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

revoke all on function public.get_pending_table_orders_v1(uuid, integer) from public;
grant execute on function public.get_pending_table_orders_v1(uuid, integer) to authenticated;
revoke execute on function public.get_pending_table_orders_v1(uuid, integer) from anon;

revoke all on function public.update_table_order_status_v1(uuid, text, uuid) from public;
grant execute on function public.update_table_order_status_v1(uuid, text, uuid) to authenticated;
revoke execute on function public.update_table_order_status_v1(uuid, text, uuid) from anon;

revoke all on function public.update_table_order_staff_note_v1(uuid, text, uuid) from public;
grant execute on function public.update_table_order_staff_note_v1(uuid, text, uuid) to authenticated;
revoke execute on function public.update_table_order_staff_note_v1(uuid, text, uuid) from anon;

-- ── 2) Bildirim kuyruğu RPC'leri: gövde içinde çağıran kimliği hiç
-- doğrulanmıyor, yalnızca service_role (trigger/dispatcher) tarafından
-- çağrılmalı — anon/authenticated'a hiç açık olmamalı.
revoke execute on function public.notify_user_v1(uuid, text, text, text, jsonb) from anon, authenticated, public;
revoke execute on function public.dequeue_notification_dispatch_jobs_v1(integer) from anon, authenticated, public;
revoke execute on function public.complete_notification_dispatch_job_v1(uuid, boolean, text) from anon, authenticated, public;
revoke execute on function public.resolve_actor_role_v1(uuid) from anon, authenticated, public;

-- ── 3) Legacy submit_menu_item_price_suggestion_v1: v2+ sertleştirmesini
-- (sanitizasyon, küfür/strike, global kota, shadow-ban) tamamen atlıyor.
-- Uygulama v5→v3→v2 fallback zinciri kullanıyor, v1 hiçbir yerden
-- çağrılmıyor — kapatılıyor.
revoke execute on function public.submit_menu_item_price_suggestion_v1(uuid, integer, text, text) from anon, authenticated, public;

-- ── 4) update_team_member_v1: kardeş fonksiyon upsert_team_member_v1
-- 'owner' rolünü ekip üyeliği üzerinden ASLA atanamaz olarak tanımlıyor
-- (yalnızca owner_claims onay akışı) ve rank-tavanı kontrolü yapıyor —
-- update yolunda ikisi de unutulmuştu.
create or replace function public.update_team_member_v1(p_business_id uuid, p_membership_id uuid, p_role text, p_scope text default 'this_business'::text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
  v_updated_id uuid;
  v_caller_rank int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  -- 'owner' bilerek dışarıda: sahiplik yalnızca owner_claims onay akışından
  -- geçmeli, ekip üyeliği üzerinden asla verilmemeli (admin dahil) — bkz.
  -- upsert_team_member_v1 ile aynı kural.
  if v_role not in ('manager', 'editor', 'staff', 'viewer') then
    return jsonb_build_object('ok', false, 'code', 'invalid_role');
  end if;

  if v_scope not in ('this_business', 'all_branches') then
    return jsonb_build_object('ok', false, 'code', 'invalid_scope');
  end if;

  if not public.is_admin() then
    v_caller_rank := public.business_role_rank_v1(public.get_business_role_v1(p_business_id));
    if public.business_role_rank_v1(v_role) >= v_caller_rank then
      return jsonb_build_object('ok', false, 'code', 'role_escalation_denied');
    end if;
  end if;

  select b.chain_id
  into v_chain_id
  from public.businesses b
  where b.id = p_business_id;

  update public.business_team_memberships
  set
    business_id = case when v_scope = 'this_business' then p_business_id else null end,
    chain_id = case when v_scope = 'all_branches' then v_chain_id else null end,
    role = v_role,
    updated_at = now()
  where id = p_membership_id
    and revoked_at is null
    and (
      business_id = p_business_id
      or (v_chain_id is not null and chain_id = v_chain_id)
    )
  returning id into v_updated_id;

  if v_updated_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.team.update',
    'business_team_memberships',
    p_membership_id,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'business_id', p_business_id,
      'role', v_role,
      'scope', v_scope
    )
  );

  return jsonb_build_object('ok', true);
end;
$function$;
