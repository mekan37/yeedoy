import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';

async function assertOwner(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  businessId: string,
) {
  const { data: userData } = await supabase.auth.getUser();
  const user = userData.user;
  if (!user) throw new Error('Unauthorized');
  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) throw new Error('Forbidden');
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const business_id = String(body.business_id ?? '');
    const item_id = String(body.item_id ?? '');
    const label = String(body.label ?? '').trim();
    const price_cents = Number(body.price_cents ?? 0);
    const currency = String(body.currency ?? 'TRY').trim().toUpperCase();
    const is_default = body.is_default === true;

    if (!business_id || !item_id || !label) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const { data: item } = await admin
      .from('menu_items')
      .select('id')
      .eq('id', item_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!item) return NextResponse.json({ error: 'Item not found' }, { status: 404 });

    if (is_default) {
      await admin.from('menu_item_variants').update({ is_default: false }).eq('menu_item_id', item_id);
    }

    const { data: maxSort } = await admin
      .from('menu_item_variants')
      .select('sort_order')
      .eq('menu_item_id', item_id)
      .order('sort_order', { ascending: false })
      .limit(1)
      .maybeSingle();

    const sortOrder = (maxSort?.sort_order ?? -1) + 1;
    const { error } = await admin.from('menu_item_variants').insert({
      menu_item_id: item_id,
      label,
      price_cents: price_cents < 0 ? 0 : Math.round(price_cents),
      currency: currency || 'TRY',
      is_default,
      is_available: true,
      sort_order: sortOrder,
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const business_id = String(body.business_id ?? '');
    const item_id = String(body.item_id ?? '');
    const variant_id = String(body.variant_id ?? '');
    const is_default = body.is_default === true;
    if (!business_id || !item_id || !variant_id) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }
    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();
    const { data: item } = await admin
      .from('menu_items')
      .select('id')
      .eq('id', item_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!item) return NextResponse.json({ error: 'Item not found' }, { status: 404 });

    if (is_default) {
      await admin.from('menu_item_variants').update({ is_default: false }).eq('menu_item_id', item_id);
      await admin
        .from('menu_item_variants')
        .update({ is_default: true })
        .eq('id', variant_id)
        .eq('menu_item_id', item_id);
    }
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function DELETE(request: Request) {
  try {
    const body = await request.json();
    const business_id = String(body.business_id ?? '');
    const variant_id = String(body.variant_id ?? '');
    if (!business_id || !variant_id) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }
    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const { data: variant } = await admin
      .from('menu_item_variants')
      .select('id,menu_item_id')
      .eq('id', variant_id)
      .maybeSingle();
    if (!variant) return NextResponse.json({ error: 'Variant not found' }, { status: 404 });

    const { data: item } = await admin
      .from('menu_items')
      .select('id')
      .eq('id', variant.menu_item_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!item) return NextResponse.json({ error: 'Item not found' }, { status: 404 });

    const { error } = await admin.from('menu_item_variants').delete().eq('id', variant_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}
