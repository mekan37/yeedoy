import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getQrAccessState } from '@/src/lib/karekod-erisimi';
import { getBusinessById } from '@/src/lib/veri/isletme-okuma';
import { appConfig } from '@/src/lib/ayarlar';
import { isUuid } from '@/src/lib/yol-normalizasyonu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { KodlarIstemcisi, type QrCode, type QrStats } from './kodlar-istemcisi';

export const metadata: Metadata = {
  title: 'QR Kodlarım ve Analitik | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  params: Promise<{ businessId: string }>;
};

export default async function KodlarimPage({ params }: Props) {
  const { businessId } = await params;

  if (!isUuid(businessId)) {
    notFound();
  }

  const redirectTo = `/karekod/${businessId}/kodlarim`;
  const access = await getQrAccessState(businessId);

  if (!access.user) {
    redirect(`/giris?redirect=${encodeURIComponent(redirectTo)}`);
  }

  if (!access.canManage) {
    redirect(`/yasakli?from=${encodeURIComponent(redirectTo)}`);
  }

  const business = await getBusinessById(businessId);
  if (!business) notFound();

  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const supabase = await createSupabaseServerClient();
  const { data: result } = await (supabase as any).rpc('owner_list_qr_codes_v1', {
    p_business_id: businessId,
  }) as { data: { codes: QrCode[]; stats: QrStats } | null };

  const codes: QrCode[] = result?.codes ?? [];
  const stats: QrStats = result?.stats ?? {
    total_codes: 0,
    active_codes: 0,
    total_scans: 0,
    unique_visitors: 0,
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="QR Kodlarım ve Analitik"
        description="Birden fazla adlandırılmış QR kod oluşturun, tarama ve ziyaretçi istatistiklerini izleyin."
        actions={
          <Link
            href={`/karekod/${businessId}`}
            className="rounded-xl border border-border bg-bg px-3 py-2 text-xs font-[800] text-textStrong transition hover:bg-card"
          >
            ← QR Studio&apos;ya dön
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-2">
        <KodlarIstemcisi
          businessId={businessId}
          businessSlug={business.slug}
          siteUrl={siteUrl}
          initialCodes={codes}
          stats={stats}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
