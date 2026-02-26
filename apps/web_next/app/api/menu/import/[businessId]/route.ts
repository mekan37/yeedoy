import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { menuImportSchema } from '@/src/lib/validators';
import { canManageBusiness } from '@/src/lib/ownership';

export async function POST(request: Request, { params }: { params: Promise<{ businessId: string }> }) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { businessId } = await params;
  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const payload = await request.json();
  const parsed = menuImportSchema.safeParse(payload);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues[0]?.message ?? 'Invalid payload' }, { status: 400 });
  }

  const admin = createServiceRoleClient();
  let importedCategories = 0;
  let importedItems = 0;

  for (const [cIdx, category] of parsed.data.categories.entries()) {
    const { data: insertedCategory, error: cErr } = await admin
      .from('menu_categories')
      .insert({ business_id: businessId, sort_order: category.sort_order ?? cIdx, is_active: true })
      .select('id')
      .single();
    if (cErr || !insertedCategory) {
      return NextResponse.json({ error: cErr?.message ?? 'Category insert failed' }, { status: 400 });
    }
    importedCategories += 1;

    await admin.from('menu_translations').upsert({
      entity_type: 'category',
      entity_id: insertedCategory.id,
      locale: 'tr',
      name: category.name,
    });

    for (const [iIdx, item] of category.items.entries()) {
      const { data: insertedItem, error: iErr } = await admin
        .from('menu_items')
        .insert({
          business_id: businessId,
          category_id: insertedCategory.id,
          name: item.name,
          description: item.description ?? null,
          price_cents: item.price_cents,
          currency: item.currency ?? 'TRY',
          is_available: item.is_available ?? true,
          sort_order: item.sort_order ?? iIdx,
          tags: item.tags ?? [],
          image_url: item.image_url ?? null,
        })
        .select('id')
        .single();

      if (iErr || !insertedItem) {
        return NextResponse.json({ error: iErr?.message ?? 'Item insert failed' }, { status: 400 });
      }
      importedItems += 1;

      await admin.from('menu_translations').upsert({
        entity_type: 'item',
        entity_id: insertedItem.id,
        locale: 'tr',
        name: item.name,
        description: item.description ?? null,
      });
    }
  }

  return NextResponse.json({ ok: true, imported_categories: importedCategories, imported_items: importedItems });
}
