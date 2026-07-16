import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { KampanyaListesi } from './kampanya-listesi';
import type { Kampanya } from './kampanya-formu';

export const metadata: Metadata = {
  title: 'Kampanyalar | Sahip Paneli',
  robots: { index: false, follow: false },
};

type OwnerClaim = { business_id: string };

export default async function SahipKampanyalarSayfasi() {
  const supabase = await createSupabaseServerClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();

  if (authError || !authData.user) {
    redirect('/giris?redirect=/sahip/pazarlama/kampanyalar');
  }

  const user = authData.user;
  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle() as { data: OwnerClaim | null };

  if (!claim) redirect('/sahip/gosterge-panosu');

  const businessId = claim.business_id;

  type ListResult  = { data: { total: number; campaigns: Kampanya[] } | null };
  type StatsResult = { data: {
    total_campaigns: number; active_campaigns: number;
    total_views: number; total_clicks: number;
    period_views: number; period_clicks: number;
  } | null };

  const [listRes, statsRes] = await Promise.all([
    (supabase as any).rpc('owner_list_campaigns_v1', {
      p_business_id: businessId, p_page: 1, p_page_size: 100,
    }) as Promise<ListResult>,
    (supabase as any).rpc('owner_get_campaign_stats_v1', {
      p_business_id: businessId, p_period_days: 7,
    }) as Promise<StatsResult>,
  ]);

  const campaigns: Kampanya[] = listRes.data?.campaigns ?? [];
  const total = listRes.data?.total ?? 0;
  const stats = statsRes.data ?? {
    total_campaigns: 0, active_campaigns: 0,
    total_views: 0, total_clicks: 0,
    period_views: 0, period_clicks: 0,
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Pazarlama"
        title="Kampanyalar"
        description="İşletmenize özel kampanyalar oluşturun, yönetin ve performanslarını takip edin."
      />
      <PanelIcerikYuzeyi className="pt-4">
        <KampanyaListesi
          businessId={businessId}
          initialCampaigns={campaigns}
          initialTotal={total}
          stats={stats}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
