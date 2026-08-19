import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { ZamanCizelgesi, type ZamanCizelgesiOlayi } from './zaman-cizelgesi';
import { EtiketNotFormu } from './etiket-not-formu';
import type { MusteriOzet } from '../musteriler-istemcisi';

export const metadata: Metadata = {
  title: 'Müşteri Profili | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusteriDetaySayfasi({
  params,
}: {
  params: Promise<{ user_id: string }>;
}) {
  const { user_id: musteriId } = await params;
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data: musteriler }, { data: olaylar }, { data: businessChain }] = await Promise.all([
    (supabase as any).rpc('get_business_customers_v1', { p_business_id: businessId }) as Promise<{
      data: MusteriOzet[] | null;
    }>,
    (supabase as any).rpc('get_customer_timeline_v1', {
      p_business_id: businessId,
      p_user_id: musteriId,
    }) as Promise<{ data: ZamanCizelgesiOlayi[] | null }>,
    (supabase as any)
      .from('businesses')
      .select('chain_id')
      .eq('id', businessId)
      .maybeSingle() as Promise<{ data: { chain_id: string | null } | null }>,
  ]);

  const musteri = (musteriler ?? []).find((m) => m.user_id === musteriId);
  if (!musteri) notFound();

  const zincirli = Boolean(businessChain?.chain_id);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Müşteriler" title={musteri.display_name} />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[280px_1fr]">
          <PanelBolumKarti title="Müşteri Bilgileri">
            <div className="flex flex-col gap-2 text-sm">
              <p className="text-muted">Yorum: {musteri.review_count}</p>
              <p className="text-muted">Rezervasyon: {musteri.reservation_count}</p>
              {musteri.loyalty_progress !== null && (
                <p className="text-muted">
                  Sadakat ilerlemesi: {musteri.loyalty_progress}
                  {musteri.loyalty_reward_threshold !== null
                    ? ` / ${musteri.loyalty_reward_threshold}`
                    : ''}
                </p>
              )}
            </div>
            <EtiketNotFormu
              businessId={businessId}
              userId={musteriId}
              mevcutEtiketler={musteri.tags}
            />
          </PanelBolumKarti>
          <PanelBolumKarti title="Zaman Çizelgesi">
            <ZamanCizelgesi olaylar={olaylar ?? []} subeEtiketiGoster={zincirli} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
