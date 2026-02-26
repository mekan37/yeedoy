import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';
import { menuItemCreateSchema, menuItemSchema } from '@/src/shared/schemas/menuItemSchema';

async function assertOwner(supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>, businessId: string) {
  const { data: userData } = await supabase.auth.getUser();
  const user = userData.user;
  if (!user) throw new Error('Unauthorized');
  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) throw new Error('Forbidden');
}

export async function POST(request: Request) {
  try {
    const form = await request.formData();
    const business_id = String(form.get('business_id') ?? '');
    const menu_id = String(form.get('menu_id') ?? '');
    const category_id = String(form.get('category_id') ?? '');
    const nameTr = String(form.get('name') ?? '').trim();
    const nameEn = String(form.get('name_en') ?? '').trim();
    const descriptionTr = String(form.get('description') ?? '').trim();
    const descriptionEn = String(form.get('description_en') ?? '').trim();
    const price_cents = Number(form.get('price_cents') ?? 0);
    const is_available = String(form.get('is_available') ?? 'true') === 'true';
    const image_url = String(form.get('image_url') ?? '').trim();
    const tagsRaw = String(form.get('tags') ?? '').trim();
    const tags = tagsRaw ? tagsRaw.split(',').map((x) => x.trim()).filter(Boolean) : [];
    const currencyRaw = String(form.get('currency') ?? 'TRY').trim().toUpperCase();

    const supabase = await createSupabaseServerClient();
    if (!nameTr) return NextResponse.json({ error: 'Item name required' }, { status: 400 });
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const parsed = menuItemCreateSchema.safeParse({
      business_id,
      category_id,
      name: nameTr,
      description: descriptionTr,
      price_cents,
      currency: currencyRaw || 'TRY',
      tags,
      image_url,
      is_available,
    });
    if (!parsed.success) {
      const firstError = parsed.error.issues[0]?.message ?? 'Invalid menu item payload';
      return NextResponse.json({ error: firstError }, { status: 400 });
    }

    if (!menu_id) {
      return NextResponse.json({ error: 'Menu required' }, { status: 400 });
    }

    const { data: categoryRow } = await admin
      .from('menu_categories')
      .select('id')
      .eq('id', category_id)
      .eq('business_id', business_id)
      .eq('menu_id', menu_id)
      .maybeSingle();
    if (!categoryRow) {
      return NextResponse.json({ error: 'Category/menu mismatch' }, { status: 400 });
    }

    const { data: maxSortRow } = await admin
      .from('menu_items')
      .select('sort_order')
      .eq('business_id', business_id)
      .eq('category_id', category_id)
      .order('sort_order', { ascending: false })
      .limit(1)
      .maybeSingle();

    const sortOrder = (maxSortRow?.sort_order ?? -1) + 1;

    const { data: item, error } = await admin
      .from('menu_items')
      .insert({
        business_id,
        category_id,
        name: parsed.data.name,
        description: parsed.data.description ?? null,
        price_cents: parsed.data.price_cents,
        currency: parsed.data.currency,
        is_available: parsed.data.is_available,
        image_url: parsed.data.image_url ?? null,
        tags: parsed.data.tags,
        sort_order: sortOrder,
      })
      .select('id')
      .single();

    if (error || !item) return NextResponse.json({ error: error?.message ?? 'Insert failed' }, { status: 400 });

    await admin.from('menu_translations').upsert({
      entity_type: 'item',
      entity_id: item.id,
      locale: 'tr',
      name: nameTr,
      description: descriptionTr || null,
    });
    if (nameEn) {
      await admin.from('menu_translations').upsert({
        entity_type: 'item',
        entity_id: item.id,
        locale: 'en',
        name: nameEn,
        description: descriptionEn || null,
      });
    }

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const { business_id, item_id, is_available } = body as { business_id: string; item_id: string; is_available: boolean };

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const { error } = await admin.from('menu_items').update({ is_available }).eq('id', item_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function PUT(request: Request) {
  try {
    const form = await request.formData();
    const business_id = String(form.get('business_id') ?? '').trim();
    const menu_id = String(form.get('menu_id') ?? '').trim();
    const item_id = String(form.get('item_id') ?? '').trim();
    const category_id = String(form.get('category_id') ?? '').trim();
    const nameTr = String(form.get('name') ?? '').trim();
    const nameEn = String(form.get('name_en') ?? '').trim();
    const descriptionTr = String(form.get('description') ?? '').trim();
    const descriptionEn = String(form.get('description_en') ?? '').trim();
    const price_cents = Number(form.get('price_cents') ?? 0);
    const is_available = String(form.get('is_available') ?? 'true') === 'true';
    const image_url = String(form.get('image_url') ?? '').trim();
    const tagsRaw = String(form.get('tags') ?? '').trim();
    const tags = tagsRaw ? tagsRaw.split(',').map((x) => x.trim()).filter(Boolean) : [];
    const currencyRaw = String(form.get('currency') ?? 'TRY').trim().toUpperCase();

    if (!business_id || !menu_id || !item_id || !category_id) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();

    const { data: existingItem } = await admin
      .from('menu_items')
      .select('id')
      .eq('id', item_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!existingItem) {
      return NextResponse.json({ error: 'Item not found' }, { status: 404 });
    }

    const { data: categoryRow } = await admin
      .from('menu_categories')
      .select('id')
      .eq('id', category_id)
      .eq('business_id', business_id)
      .eq('menu_id', menu_id)
      .maybeSingle();
    if (!categoryRow) {
      return NextResponse.json({ error: 'Category/menu mismatch' }, { status: 400 });
    }

    const parsed = menuItemSchema.safeParse({
      name: nameTr,
      description: descriptionTr,
      price_cents,
      currency: currencyRaw || 'TRY',
      tags,
      image_url,
      is_available,
    });
    if (!parsed.success) {
      const firstError = parsed.error.issues[0]?.message ?? 'Invalid menu item payload';
      return NextResponse.json({ error: firstError }, { status: 400 });
    }

    const { error } = await admin
      .from('menu_items')
      .update({
        category_id,
        name: parsed.data.name,
        description: parsed.data.description ?? null,
        price_cents: parsed.data.price_cents,
        currency: parsed.data.currency,
        is_available: parsed.data.is_available,
        image_url: parsed.data.image_url ?? null,
        tags: parsed.data.tags,
      })
      .eq('id', item_id)
      .eq('business_id', business_id);
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    await admin.from('menu_translations').upsert({
      entity_type: 'item',
      entity_id: item_id,
      locale: 'tr',
      name: nameTr,
      description: descriptionTr || null,
    });

    if (nameEn) {
      await admin.from('menu_translations').upsert({
        entity_type: 'item',
        entity_id: item_id,
        locale: 'en',
        name: nameEn,
        description: descriptionEn || null,
      });
    } else {
      await admin
        .from('menu_translations')
        .delete()
        .eq('entity_type', 'item')
        .eq('entity_id', item_id)
        .eq('locale', 'en');
    }

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function DELETE(request: Request) {
  try {
    const body = await request.json();
    const { business_id, item_id } = body as { business_id: string; item_id: string };

    if (!business_id || !item_id) {
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

    await admin.from('menu_translations').delete().eq('entity_type', 'item').eq('entity_id', item_id);
    const { error } = await admin.from('menu_items').delete().eq('id', item_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}
