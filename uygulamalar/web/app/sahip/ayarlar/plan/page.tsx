import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PlanOzetIstemcisi } from './plan-ozet-istemcisi';
import { FEATURE_LABELS, TIER_LABELS } from '@/src/lib/plan/plan-sabitleri';

export const metadata: Metadata = {
  title: 'Plan | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function PlanSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/ayarlar/plan');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const { data, error } = (await (supabase as any).rpc('get_my_plan_v1', {
    p_business_id: businessId,
  })) as {
    data: {
      plan_tier: string;
      features: Array<{ feature_key: string; enabled: boolean; limit_value: number | null; used: number }>;
    } | null;
    error: { message: string } | null;
  };

  if (error || !data) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Ayarlar" title="Plan" />
        <PanelIcerikYuzeyi className="pt-6">
          <p className="text-sm font-bold text-red-600">Plan bilgisi yüklenemedi.</p>
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Ayarlar"
        title="Plan"
        description="Kademenizi ve özellik limitlerinizi görüntüleyin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <PlanOzetIstemcisi
          planTier={data.plan_tier}
          planLabel={TIER_LABELS[data.plan_tier as keyof typeof TIER_LABELS] ?? data.plan_tier}
          features={data.features.map((f) => ({
            ...f,
            label: FEATURE_LABELS[f.feature_key as keyof typeof FEATURE_LABELS] ?? f.feature_key,
          }))}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
