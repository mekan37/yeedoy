-- business pricing rules + bill estimate rpc

create table if not exists public.business_pricing_rules (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  service_fee_pct int null,
  cover_charge_cents int null,
  vat_included boolean not null default true,
  default_tip_pct int null
);
alter table if exists public.business_pricing_rules enable row level security;
create or replace function public.get_bill_estimate_v1(
  p_business_id uuid,
  p_items jsonb,
  p_tip_pct int default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_subtotal int := 0;
  v_cover int := 0;
  v_service int := 0;
  v_tip int := 0;
  v_total int := 0;
  v_service_pct int := 0;
  v_tip_pct int := 0;
  v_vat_included boolean := true;
  v_has_rules boolean := false;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    return jsonb_build_object(
      'ok', false,
      'error', 'invalid_items'
    );
  end if;

  select
    coalesce(r.service_fee_pct, 0),
    coalesce(r.cover_charge_cents, 0),
    coalesce(r.vat_included, true),
    r.default_tip_pct
  into v_service_pct, v_cover, v_vat_included, v_tip_pct
  from public.business_pricing_rules r
  where r.business_id = p_business_id;

  if found then
    v_has_rules := true;
  end if;

  v_tip_pct := coalesce(p_tip_pct, v_tip_pct, 0);

  select
    coalesce(sum(mi.price_cents * req.qty), 0)
  into v_subtotal
  from (
    select
      (i->>'menu_item_id')::uuid as menu_item_id,
      greatest(coalesce((i->>'qty')::int, 1), 1) as qty
    from jsonb_array_elements(p_items) as i
  ) req
  join public.menu_items mi on mi.id = req.menu_item_id;

  v_service := (v_subtotal * v_service_pct / 100.0)::int;
  v_tip := (v_subtotal * v_tip_pct / 100.0)::int;
  v_total := v_subtotal + v_cover + v_service + v_tip;

  return jsonb_build_object(
    'ok', true,
    'has_rules', v_has_rules,
    'subtotal_cents', v_subtotal,
    'cover_cents', v_cover,
    'service_fee_cents', v_service,
    'service_fee_pct', v_service_pct,
    'tip_cents', v_tip,
    'tip_pct', v_tip_pct,
    'total_cents', v_total,
    'vat_included', v_vat_included
  );
end;
$$;
