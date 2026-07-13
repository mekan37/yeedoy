import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getMenuWithSections } from '@/src/lib/veri/owner/sahip-menuler';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { MenuEditorClient } from './menu-duzenleyici-istemcisi';

type Props = { params: Promise<{ menuId: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('menus').select('title').eq('id', menuId).single() as { data: { title: string } | null };
  return { title: data ? `${data.title} Düzenle | Sahip Paneli` : 'Menü Editörü | Sahip Paneli', robots: { index: false, follow: false } };
}

export default async function MenuEditorPage({ params }: Props) {
  const { menuId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent(`/sahip/menuler/${menuId}/duzenle`)}`);
  }

  const detail = await getMenuWithSections(menuId, user.id);
  if (!detail) notFound();

  const { menu, business: biz, sections, items } = detail;

  // Batch-fetch allergens for all items in this menu
  const allItemIds = items.map((item) => item.id);
  const allergenMap: Record<string, string[]> = {};
  if (allItemIds.length > 0) {
    const { data: allergenRows } = await (supabase as any)
      .from('menu_item_allergens')
      .select('item_id, allergen')
      .in('item_id', allItemIds) as { data: Array<{ item_id: string; allergen: string }> | null };
    for (const row of allergenRows ?? []) {
      if (!allergenMap[row.item_id]) allergenMap[row.item_id] = [];
      allergenMap[row.item_id].push(row.allergen);
    }
  }

  // Batch-fetch ingredients for all items in this menu
  const ingredientMap: Record<string, string[]> = {};
  if (allItemIds.length > 0) {
    const { data: ingredientRows } = await (supabase as any)
      .from('menu_item_ingredients')
      .select('item_id, name')
      .in('item_id', allItemIds)
      .order('sort_order') as { data: Array<{ item_id: string; name: string }> | null };
    for (const row of ingredientRows ?? []) {
      if (!ingredientMap[row.item_id]) ingredientMap[row.item_id] = [];
      ingredientMap[row.item_id].push(row.name);
    }
  }

  const STATUS_MAP: Record<string, { label: string; className: string }> = {
    draft:     { label: 'Taslak',   className: 'bg-amber-50 text-amber-700' },
    published: { label: 'Yayında',  className: 'bg-green-50 text-green-700' },
    archived:  { label: 'Arşiv',    className: 'bg-zinc-100 text-zinc-500'  },
  };
  const statusInfo = STATUS_MAP[menu.status] ?? STATUS_MAP.draft;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow={biz.name}
        title={menu.title}
        description={`Menü editörü — ${sections.length} bölüm, ${items.length} ürün`}
        actions={
          <div className="flex items-center gap-2">
            <span className={`rounded-full px-2.5 py-1 text-[11px] font-[700] ${statusInfo.className}`}>{statusInfo.label}</span>
            <Link
              href={`/sahip/karekod/${biz.id}?lang=tr&theme=bold`}
              className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong transition-colors hover:bg-bg"
            >
              QR Studio
            </Link>
            <Link href={`/sahip/menuler/${menuId}`} className="rounded-xl border border-border bg-card px-3 py-1.5 text-[12px] font-[700] text-textStrong hover:bg-bg transition-colors cursor-pointer">← Önizleme</Link>
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
          <MenuEditorClient
          menuId={menuId}
          businessId={biz.id}
          initialTitle={menu.title}
          initialStatus={menu.status as 'draft' | 'published' | 'archived'}
          sections={sections.map((section) => ({
            id: section.id,
            title: section.title,
            sort_order: section.sort_order,
          }))}
          items={items.map((item) => ({
            id: item.id,
            name: item.name,
            description: item.description,
            image_url: item.image_url,
            price_cents: item.price_cents,
            currency: item.currency,
            is_available: item.is_available,
            section_id: item.section_id,
            sort_order: item.sort_order,
            calories_min: item.calories_min ?? null,
            portion_size: item.portion_size ?? null,
            portion_unit: item.portion_unit ?? null,
          }))}
          allergenMap={allergenMap}
          ingredientMap={ingredientMap}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}

