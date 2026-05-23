import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { EnvanterIstemci } from './envanter-istemci';

export const metadata: Metadata = {
  title: 'Envanter | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function EnvanterPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const bizIds = businesses.map(b => b.id);

  // Fetch menu items with stock info
  const { data: items } = bizIds.length > 0
    ? await (supabase as any)
        .from('menu_items')
        .select('id, name, is_available, stock_count, price, reorder_threshold, supplier, menus(id, name, businesses(id, name))')
        .in('menus.business_id', bizIds)
        .order('stock_count', { ascending: true })
        .limit(500)
    : { data: [] };

  const allItems = (items ?? []) as Array<{
    id: string; name: string; is_available: boolean; stock_count: number | null; price: number;
    reorder_threshold?: number | null; supplier?: string | null;
    menus: { id: string; name: string; businesses: { id: string; name: string } | null } | null;
  }>;

  const lowStock = allItems.filter(i => (i.stock_count ?? 99) <= 5 && (i.stock_count ?? 99) > 0);
  const outOfStock = allItems.filter(i => i.stock_count === 0 || i.is_available === false);
  const okStock = allItems.filter(i => (i.stock_count ?? 99) > 5 && i.is_available);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Envanter Takibi"
        description="Stok seviyeleri, tükenme uyarıları ve müsaitlik durumu"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Summary */}
          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-xl border border-red-200 bg-red-50 p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-red-700">Stok Tükendi</p>
              <p className="mt-1 text-2xl font-[900] text-red-700">{outOfStock.length}</p>
            </div>
            <div className="rounded-xl border border-yellow-200 bg-yellow-50 p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-yellow-700">Düşük Stok (≤5)</p>
              <p className="mt-1 text-2xl font-[900] text-yellow-700">{lowStock.length}</p>
            </div>
            <div className="rounded-xl border border-green-200 bg-green-50 p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-green-700">Yeterli Stok</p>
              <p className="mt-1 text-2xl font-[900] text-green-700">{okStock.length}</p>
            </div>
          </div>

          {/* Critical alerts */}
          {outOfStock.length > 0 && (
            <PanelBolumKarti title="⚠️ Stok Tükendi — Acil" noPadding>
              <EnvanterIstemci items={outOfStock} alertLevel="critical" />
            </PanelBolumKarti>
          )}

          {lowStock.length > 0 && (
            <PanelBolumKarti title="⚡ Düşük Stok" noPadding>
              <EnvanterIstemci items={lowStock} alertLevel="warning" />
            </PanelBolumKarti>
          )}

          {/* Full inventory */}
          <PanelBolumKarti title="Tüm Ürünler" noPadding>
            <EnvanterIstemci items={allItems} alertLevel="none" />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
