import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { SiparisYonetimi } from './siparis-yonetimi';

export const metadata: Metadata = {
  title: 'Masa Siparişleri | Sahip Paneli',
  robots: { index: false, follow: false },
};

export const dynamic = 'force-dynamic'; // gerçek zamanlı, cache'lenmesin

export default async function SiparislerPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
      supabase as any,
      user.id,
      'id, name, is_active',
    )).filter((business) => business.is_active !== false)
    : [];

  const allOrders: any[] = [];
  for (const biz of businesses) {
    const { data } = await (supabase as any).rpc('get_pending_table_orders_v1', {
      p_business_id: biz.id,
      p_limit: 30,
    }).catch(() => ({ data: null }));
    if (data) {
      allOrders.push(...(data as any[]).map((o: any) => ({ ...o, businessName: biz.name })));
    }
  }

  allOrders.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  const pending = allOrders.filter((o) => o.status === 'pending');
  const seen = allOrders.filter((o) => o.status === 'seen');

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Masa Siparişleri"
        description={`${pending.length} bekliyor · ${seen.length} görüldü`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {allOrders.length === 0 ? (
          <PanelEmptyState
            icon={<BasketIcon />}
            title="Bekleyen sipariş yok"
            description="Müşteriler QR menü üzerinden sipariş gönderdiğinde burada görünür."
          />
        ) : (
          <SiparisYonetimi orders={allOrders} />
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function BasketIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/>
    </svg>
  );
}
