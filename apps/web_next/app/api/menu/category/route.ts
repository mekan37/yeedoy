import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { canManageBusiness } from '@/src/lib/ownership';
import {
  menuCategoryCreateSchema,
  menuCategoryDeleteSchema,
  menuCategoryReorderSchema,
} from '@/src/shared/schemas/menuCategorySchema';

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
    const parsed = menuCategoryCreateSchema.safeParse({
      business_id: String(form.get('business_id') ?? ''),
      menu_id: String(form.get('menu_id') ?? ''),
      name_tr: String(form.get('name_tr') ?? ''),
      name_en: String(form.get('name_en') ?? ''),
    });
    if (!parsed.success) {
      return NextResponse.json({ error: parsed.error.issues[0]?.message ?? 'Invalid payload' }, { status: 400 });
    }
    const { business_id, menu_id, name_tr: nameTr, name_en: nameEn } = parsed.data;

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();
    const { data: menuRow } = await admin
      .from('menus')
      .select('id')
      .eq('id', menu_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!menuRow) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

    const { data: maxSortRow } = await admin
      .from('menu_categories')
      .select('sort_order')
      .eq('business_id', business_id)
      .eq('menu_id', menu_id)
      .order('sort_order', { ascending: false })
      .limit(1)
      .maybeSingle();

    const sort_order = (maxSortRow?.sort_order ?? -1) + 1;

    const { data: category, error } = await admin
      .from('menu_categories')
      .insert({ business_id, menu_id, sort_order, is_active: true })
      .select('id')
      .single();
    if (error || !category) return NextResponse.json({ error: error?.message ?? 'Insert failed' }, { status: 400 });

    await admin.from('menu_translations').upsert({
      entity_type: 'category',
      entity_id: category.id,
      locale: 'tr',
      name: nameTr,
      description: null,
    });

    if (nameEn) {
      await admin.from('menu_translations').upsert({
        entity_type: 'category',
        entity_id: category.id,
        locale: 'en',
        name: nameEn,
        description: null,
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
    const parsed = menuCategoryReorderSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: parsed.error.issues[0]?.message ?? 'Invalid payload' }, { status: 400 });
    }
    const { business_id, menu_id, category_id, direction } = parsed.data;

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();
    const { data: menuRow } = await admin
      .from('menus')
      .select('id')
      .eq('id', menu_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!menuRow) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

    const { data: current } = await admin
      .from('menu_categories')
      .select('id,sort_order,menu_id')
      .eq('id', category_id)
      .eq('menu_id', menu_id)
      .single();
    if (!current) return NextResponse.json({ error: 'Category not found' }, { status: 404 });

    const op = direction === 'up' ? 'lt' : 'gt';
    const orderAscending = direction !== 'up';
    const q = admin
      .from('menu_categories')
      .select('id,sort_order')
      .eq('business_id', business_id)
      .eq('menu_id', menu_id)
      .order('sort_order', { ascending: orderAscending })
      .limit(1);

    const { data: sibling } = await (op === 'lt'
      ? q.lt('sort_order', current.sort_order)
      : q.gt('sort_order', current.sort_order)).maybeSingle();
    if (!sibling) return NextResponse.json({ ok: true });

    await admin.from('menu_categories').update({ sort_order: sibling.sort_order }).eq('id', current.id);
    await admin.from('menu_categories').update({ sort_order: current.sort_order }).eq('id', sibling.id);

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}

export async function DELETE(request: Request) {
  try {
    const body = await request.json();
    const parsed = menuCategoryDeleteSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: parsed.error.issues[0]?.message ?? 'Invalid payload' }, { status: 400 });
    }
    const { business_id, menu_id, category_id } = parsed.data;

    const supabase = await createSupabaseServerClient();
    await assertOwner(supabase, business_id);
    const admin = createServiceRoleClient();
    const { data: menuRow } = await admin
      .from('menus')
      .select('id')
      .eq('id', menu_id)
      .eq('business_id', business_id)
      .maybeSingle();
    if (!menuRow) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

    const { data: category } = await admin
      .from('menu_categories')
      .select('id')
      .eq('id', category_id)
      .eq('business_id', business_id)
      .eq('menu_id', menu_id)
      .maybeSingle();

    if (!category) {
      return NextResponse.json({ error: 'Category not found' }, { status: 404 });
    }

    const { data: categoryItems } = await admin
      .from('menu_items')
      .select('id')
      .eq('business_id', business_id)
      .eq('category_id', category_id);

    const itemIds = (categoryItems ?? []).map((x) => x.id as string);

    if (itemIds.length > 0) {
      await admin.from('menu_translations').delete().eq('entity_type', 'item').in('entity_id', itemIds);
      await admin.from('menu_items').delete().in('id', itemIds);
    }

    await admin.from('menu_translations').delete().eq('entity_type', 'category').eq('entity_id', category_id);
    const { error } = await admin.from('menu_categories').delete().eq('id', category_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 400 });

    return NextResponse.json({ ok: true, deleted_items: itemIds.length });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Error' }, { status: 400 });
  }
}
