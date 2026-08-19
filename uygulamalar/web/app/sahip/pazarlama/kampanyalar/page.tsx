import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { KampanyalarSayfaIstemcisi } from './kampanyalar-sayfa-istemcisi';
import type { Kampanya } from './kampanya-formu';
import type { EpostaKampanyaOzet } from './eposta-sekmesi';

export const metadata: Metadata = {
  title: 'Kampanyalar | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SahipKampanyalarSayfasi() {
  const supabase = await createSupabaseServerClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/pazarlama/kampanyalar');

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle() as { data: { business_id: string } | null };

  if (!claim) redirect('/sahip/gosterge-panosu');

  const businessId = claim.business_id;

  type ListSonucu  = { data: { total: number; campaigns: Kampanya[] } | null };
  type StatsSonucu = { data: {
    total_campaigns: number; active_campaigns: number;
    total_views: number; total_clicks: number;
    period_views: number; period_clicks: number;
  } | null };

  type EtiketSonucu = { data: string[] | null };
  type EmailListSonucu = { data: { total: number; items: EpostaKampanyaOzet[] } | null };

  const [listRes, statsRes, etiketRes, emailListRes] = await Promise.all([
    (supabase as any).rpc('owner_list_campaigns_v1', {
      p_business_id: businessId, p_page: 1, p_page_size: 100,
    }) as Promise<ListSonucu>,
    (supabase as any).rpc('owner_get_campaign_stats_v1', {
      p_business_id: businessId, p_period_days: 7,
    }) as Promise<StatsSonucu>,
    (supabase as any).rpc('list_customer_tags_v1', { p_business_id: businessId }) as Promise<EtiketSonucu>,
    (supabase as any).rpc('list_email_campaigns_v1', { p_business_id: businessId }) as Promise<EmailListSonucu>,
  ]);

  const campaigns: Kampanya[] = listRes.data?.campaigns ?? [];
  const total = listRes.data?.total ?? 0;
  const stats = statsRes.data ?? {
    total_campaigns: 0, active_campaigns: 0,
    total_views: 0, total_clicks: 0,
    period_views: 0, period_clicks: 0,
  };
  const etiketler = etiketRes.data ?? [];
  const emailKampanyalar = emailListRes.data?.items ?? [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Pazarlama"
        title="Kampanyalar"
        description="İşletmenize özel kampanyalar oluşturun, yönetin, performanslarını takip edin ve e-posta ile duyurun."
      />
      <PanelIcerikYuzeyi className="pt-4">
        <KampanyalarSayfaIstemcisi
          businessId={businessId}
          initialCampaigns={campaigns}
          initialTotal={total}
          stats={stats}
          etiketler={etiketler}
          initialEmailKampanyalar={emailKampanyalar}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
