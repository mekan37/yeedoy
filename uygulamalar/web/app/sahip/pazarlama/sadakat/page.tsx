import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import Link from 'next/link';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { SadakatIstemcisi } from './sadakat-istemcisi';
import type { SadakatProgram } from './sadakat-kurulum-istemcisi';
import type { SadakatUyesi } from './uye-listesi';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SadakatSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/pazarlama/sadakat');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const sb = supabase as any;

  const { data: plan } = (await sb.rpc('get_my_plan_v1', { p_business_id: businessId })) as {
    data: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean }> } | null;
  };
  const sadakatAcik = plan?.features.some((f) => f.feature_key === 'sadakat_programi' && f.enabled) ?? false;

  if (!sadakatAcik) {
    return (
      <div className="flex flex-col">
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<span>🎁</span>}
            title="Sadakat programı Standart ve üzeri planlarda"
            description="Müşterilerinize damga kartı veya puan sistemi sunmak için planınızı yükseltin."
            action={
              <Link
                href="/sahip/premium"
                className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90"
              >
                Planları Görüntüle
              </Link>
            }
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { data: program } = (await sb.rpc('get_business_loyalty_program_v1', {
    p_business_id: businessId,
  })) as { data: SadakatProgram | null };

  const [{ data: members }, { count: aktifKampanyaSayisi }] = await Promise.all([
    program
      ? (sb.rpc('get_business_loyalty_members_v1', { p_business_id: businessId }) as Promise<{ data: SadakatUyesi[] | null }>)
      : Promise.resolve({ data: null as SadakatUyesi[] | null }),
    sb.from('campaigns').select('id', { count: 'exact', head: true }).eq('business_id', businessId).eq('status', 'active'),
  ]);

  const uyeler = members ?? [];
  const aktifUye = uyeler.length;
  const toplamPuanVeyaDamga = uyeler.reduce((sum, m) => sum + m.progress, 0);
  const kullanilanOdul = uyeler.reduce((sum, m) => sum + m.redeemed_count, 0);

  const tamamlayanlar = uyeler.filter((m) => m.redeemed_count > 0).length;
  const devamEdenler = uyeler.filter((m) => m.redeemed_count === 0 && m.progress > 0).length;
  const aktifOlmayanlar = uyeler.filter((m) => m.progress === 0 && m.redeemed_count === 0).length;

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <SadakatIstemcisi
          businessId={businessId}
          program={program ?? null}
          uyeler={uyeler}
          stats={{
            aktifUye,
            toplamPuanVeyaDamga,
            kullanilanOdul,
            aktifKampanyaSayisi: aktifKampanyaSayisi ?? 0,
          }}
          uyeDagilimi={{ tamamlayanlar, devamEdenler, aktifOlmayanlar }}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
