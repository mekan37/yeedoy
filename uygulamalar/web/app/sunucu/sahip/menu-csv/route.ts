import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function GET(req: Request) {
  const url = new URL(req.url);
  const menuId = url.searchParams.get('menuId');
  if (!menuId) return NextResponse.json({ error: 'menuId required' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  // Verify ownership
  const { data: menu } = await (supabase as any)
    .from('menus')
    .select('id, title, business_id')
    .eq('id', menuId)
    .single() as { data: { id: string; title: string; business_id: string } | null };

  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, menu.business_id);
  if (!canManageBusiness) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  // Fetch sections and items
  const { data: sections } = await (supabase as any)
    .from('menu_sections')
    .select('id, title, sort_order')
    .eq('menu_id', menuId)
    .order('sort_order');

  const sectionIds = ((sections ?? []) as any[]).map((s: any) => s.id);
  const sectionMap = Object.fromEntries(((sections ?? []) as any[]).map((s: any) => [s.id, s.title]));

  const { data: items } = sectionIds.length > 0
    ? await (supabase as any)
        .from('menu_items')
        .select('id, section_id, name, description, price_cents, currency, is_available, sort_order')
        .in('section_id', sectionIds)
        .order('sort_order')
    : { data: [] };

  const header = 'Bölüm,Ürün Adı,Açıklama,Fiyat (₺),Para Birimi,Müsait,Sıra';
  const lines = ((items ?? []) as any[]).map((item: any) => {
    const section = sectionMap[item.section_id] ?? '';
    const price = ((item.price_cents ?? 0) / 100).toFixed(2);
    const desc = (item.description ?? '').replace(/"/g, '""');
    const name = (item.name ?? '').replace(/"/g, '""');
    return `"${section}","${name}","${desc}",${price},${item.currency ?? 'TRY'},${item.is_available ? 'Evet' : 'Hayır'},${item.sort_order ?? 0}`;
  });

  const csv = [header, ...lines].join('\n');
  const filename = `menu-${menu.title.replace(/\s+/g, '-').toLowerCase()}.csv`;

  return new Response('﻿' + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  });
}
