import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { AKTIF_ISLETME_COOKIE_NAME } from '@/src/ui/kabuk/aktif-isletme-cerezi';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { FiyatRaporuIstemcisi, type FiyatSatiri, type RakipIsletme } from './fiyat-raporu-istemcisi';

export const metadata: Metadata = {
  title: 'Fiyat Raporu | Sahip Paneli',
  robots: { index: false, follow: false },
};

// Supabase'in PostgrestBuilder'ı thenable ama .catch/.finally uygulamıyor —
// builder'a doğrudan .catch() zincirlemek "is not a function" ile patlıyordu.
// Builder'ı await edip try/catch'e almak güvenli yol.
async function safeRpc<T>(builder: PromiseLike<{ data: T | null }>): Promise<{ data: T | null }> {
  try {
    return await builder;
  } catch {
    return { data: null };
  }
}

async function hasPublishedPricedItems(supabase: any, businessId: string): Promise<boolean> {
  const { data: menus } = await supabase
    .from('menus')
    .select('id')
    .eq('business_id', businessId)
    .eq('status', 'published') as { data: Array<{ id: string }> | null };
  const menuIds = (menus ?? []).map((m: { id: string }) => m.id);
  if (menuIds.length === 0) return false;

  const { data: sections } = await supabase
    .from('menu_sections')
    .select('id')
    .in('menu_id', menuIds) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((s: { id: string }) => s.id);
  if (sectionIds.length === 0) return false;

  const { count } = await supabase
    .from('menu_items')
    .select('id', { count: 'exact', head: true })
    .in('section_id', sectionIds)
    .eq('is_available', true)
    .gt('price_cents', 0);
  return (count ?? 0) > 0;
}

export default async function OwnerPriceReportPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/fiyat-raporu');

  const [businesses, cookieStore] = await Promise.all([
    getOwnerBusinesses<{ id: string; name: string; city: string | null; district: string | null; is_active: boolean | null }>(
      supabase as any, user.id, 'id, name, city, district, is_active',
    ),
    cookies(),
  ]);
  const activeBusinesses = businesses.filter((b) => b.is_active !== false);

  if (activeBusinesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState icon={<ChartIcon />} title="İşletme bulunamadı" description="Aktif işletmeniz bulunmuyor." />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const cookieId = cookieStore.get(AKTIF_ISLETME_COOKIE_NAME)?.value;
  const biz = activeBusinesses.find((b) => b.id === cookieId) ?? activeBusinesses[0];

  const sb = supabase as any;
  const [{ data: rows }, { data: competitors }, pricedVar] = await Promise.all([
    safeRpc(sb.rpc('get_business_price_comparison_v1', { p_business_id: biz.id, p_limit: 50 })),
    safeRpc(sb.rpc('get_business_price_competitors_v1', { p_business_id: biz.id, p_limit: 20 })),
    hasPublishedPricedItems(sb, biz.id),
  ]);

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <FiyatRaporuIstemcisi
          businessLabel={`${biz.name}${biz.district ? ` · ${biz.district}` : ''}`}
          rows={(rows as FiyatSatiri[] | null) ?? []}
          rakipler={(competitors as RakipIsletme[] | null) ?? []}
          hasPricedItems={pricedVar}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ChartIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
    </svg>
  );
}
