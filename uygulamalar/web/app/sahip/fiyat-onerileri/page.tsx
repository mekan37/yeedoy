import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Fiyat Önerileri | Sahip Paneli',
  robots: { index: false, follow: false },
};

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending: { label: 'Bekliyor', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

function formatPrice(cents: number) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY', minimumFractionDigits: 2 }).format(cents / 100);
}

export default async function OwnerPriceSuggestionsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b) => b.id);

  const { data: suggestions } = businessIds.length > 0
    ? await (supabase as any)
        .from('menu_item_price_suggestions')
        .select('id, menu_item_id, suggested_price_cents, status, created_at, menu_items(name, price_cents)')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(100)
    : { data: [] };

  const list = (suggestions ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Fiyat Önerileri"
        description="Menü ürünleriniz için gelen fiyat önerileri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<TagIcon />}
            title="Fiyat önerisi yok"
            description="Menü ürünleriniz için henüz fiyat önerisi gelmemiş."
          />
        ) : (
          <PanelBolumKarti noPadding>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border">
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Ürün</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Mevcut Fiyat</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Önerilen Fiyat</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((s: any) => {
                    const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['pending'];
                    return (
                      <tr key={s.id}>
                        <td className="px-5 py-3 font-[600] text-textStrong">
                          {s.menu_items?.name ?? s.menu_item_id}
                        </td>
                        <td className="px-5 py-3 text-muted">
                          {s.menu_items?.price_cents != null ? formatPrice(s.menu_items.price_cents) : '—'}
                        </td>
                        <td className="px-5 py-3 font-[700] text-textStrong">
                          {formatPrice(s.suggested_price_cents)}
                        </td>
                        <td className="px-5 py-3">
                          <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${statusInfo.className}`}>
                            {statusInfo.label}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-muted">
                          {new Date(s.created_at).toLocaleDateString('tr-TR')}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function TagIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" />
      <line x1="7" y1="7" x2="7.01" y2="7" />
    </svg>
  );
}

