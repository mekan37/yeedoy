import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { CopKutusuIstemcisi, type CopKutusuSatiri } from './cop-kutusu-istemcisi';

export const metadata: Metadata = {
  title: 'Çöp Kutusu | Sahip Paneli',
  robots: { index: false, follow: false },
};

type TrashRow = {
  entity_type: 'menu' | 'item' | 'photo';
  entity_id: string;
  title: string;
  subtitle: string;
  occurred_at: string;
  menu_id: string | null;
  menu_item_id: string | null;
  photo_url: string | null;
};

export default async function OwnerTrashPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const bizList = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const trashResults = await Promise.all(
    bizList.map((b) =>
      (supabase as any)
        .rpc('list_owner_menu_trash_v1', { p_business_id: b.id })
        .then((res: { data: TrashRow[] | null }) => ({
          businessId: b.id,
          bizName: b.name,
          rows: res.data ?? [],
        })),
    ),
  );

  // Arşivlenmiş menülerin gerçek ürün sayısı (o menüye ait tüm bölüm+ürünler,
  // durumdan bağımsız) — "Silinme Ürün Sayısı" sütunu için.
  const archivedMenuIds = trashResults.flatMap((r) => r.rows.filter((row: TrashRow) => row.entity_type === 'menu').map((row: TrashRow) => row.entity_id));
  const menuItemCounts = new Map<string, number>();
  if (archivedMenuIds.length > 0) {
    const { data: sectionRows } = await (supabase as any).from('menu_sections').select('id, menu_id').in('menu_id', archivedMenuIds);
    const sectionToMenu = new Map<string, string>((sectionRows ?? []).map((s: { id: string; menu_id: string }) => [s.id, s.menu_id]));
    const sectionIds = Array.from(sectionToMenu.keys());
    if (sectionIds.length > 0) {
      const { data: itemRows } = await (supabase as any).from('menu_items').select('section_id').in('section_id', sectionIds);
      for (const item of (itemRows ?? []) as Array<{ section_id: string }>) {
        const menuId = sectionToMenu.get(item.section_id);
        if (!menuId) continue;
        menuItemCounts.set(menuId, (menuItemCounts.get(menuId) ?? 0) + 1);
      }
    }
  }

  const allRows: CopKutusuSatiri[] = trashResults.flatMap((r) =>
    r.rows.map((row: TrashRow): CopKutusuSatiri => ({
      entityType: row.entity_type,
      entityId: row.entity_id,
      title: row.title,
      subtitle: row.subtitle,
      occurredAt: row.occurred_at,
      photoUrl: row.photo_url,
      businessId: r.businessId,
      businessName: r.bizName,
      itemCount: row.entity_type === 'menu' ? (menuItemCounts.get(row.entity_id) ?? 0) : null,
    })),
  );

  allRows.sort((a, b) => new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime());

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <CopKutusuIstemcisi satirlar={allRows} coklu={bizList.length > 1} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
