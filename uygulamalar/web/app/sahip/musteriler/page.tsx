import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { MusteriListesi, type MusteriOzet } from './musteri-listesi';
import { zincirAciklamasiOlustur } from './musteriler-yardimcilari';

export const metadata: Metadata = {
  title: 'Müşteriler | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusterilerSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data }, { data: businessChain }] = await Promise.all([
    (supabase as any).rpc('get_business_customers_v1', {
      p_business_id: businessId,
    }) as Promise<{ data: MusteriOzet[] | null }>,
    (supabase as any)
      .from('businesses')
      .select('chain_id, chains(name)')
      .eq('id', businessId)
      .maybeSingle() as Promise<{ data: { chain_id: string | null; chains: { name: string } | null } | null }>,
  ]);

  const zincirAdi = businessChain?.chains?.name ?? null;

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi
        eyebrow="Müşteriler"
        title="Müşteriler"
        description={zincirAciklamasiOlustur(zincirAdi)}
      />
      <PanelIcerikYuzeyi>
        <MusteriListesi musteriler={data ?? []} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
