import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { KampanyaFormuIstemcisi } from './kampanya-formu-istemcisi';
import { KampanyaListesi, type KampanyaOzet } from './kampanya-listesi';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function EpostaKampanyalariSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/pazarlama/eposta-kampanyalari');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data: etiketler }, { data: kampanyalarSonuc }] = await Promise.all([
    (supabase as any).rpc('list_customer_tags_v1', { p_business_id: businessId }) as Promise<{ data: string[] | null }>,
    (supabase as any).rpc('list_email_campaigns_v1', { p_business_id: businessId }) as Promise<{
      data: { total: number; items: KampanyaOzet[] } | null;
    }>,
  ]);

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi eyebrow="Pazarlama" title="E-posta Kampanyaları" description="Etiketlediğiniz veya takip eden müşterilerinize toplu e-posta gönderin" />
      <PanelIcerikYuzeyi>
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[1fr_320px]">
          <PanelBolumKarti title="Yeni Kampanya">
            <KampanyaFormuIstemcisi businessId={businessId} etiketler={etiketler ?? []} />
          </PanelBolumKarti>
          <PanelBolumKarti title="Geçmiş Kampanyalar">
            <KampanyaListesi kampanyalar={kampanyalarSonuc?.items ?? []} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
