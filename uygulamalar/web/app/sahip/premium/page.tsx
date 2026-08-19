import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PremiumIstemcisi } from './premium-istemcisi';
import type { PlanTierId } from './premium-veri';

export const metadata: Metadata = {
  title: 'Premium | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SahipPremiumSayfasi() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/premium');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];

  let currentTier: PlanTierId | null = null;
  if (businessId) {
    const { data } = (await (supabase as any).rpc('get_my_plan_v1', { p_business_id: businessId })) as {
      data: { plan_tier: PlanTierId } | null;
    };
    currentTier = data?.plan_tier ?? null;
  }

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <PremiumIstemcisi currentTier={currentTier} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
