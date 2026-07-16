import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { QrPageClient, type QrCode, type QrStats } from './karekod-istemcisi';

export const metadata: Metadata = {
  title: 'QR Tasarım Kiti | Sahip Paneli',
  robots: { index: false, follow: false },
};

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, '') ?? 'http://localhost:3000';

type Props = { params: Promise<{ businessId: string }> };

export default async function OwnerQrPage({ params }: Props) {
  const { businessId } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) notFound();

  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('name, slug')
    .eq('id', businessId)
    .maybeSingle() as { data: { name: string; slug: string | null } | null };

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
        eyebrow={biz?.name ?? 'Owner'}
        title="QR Menü & QR Kod"
        description="Dijital menünüzü yönetin ve QR kodlarınızı oluşturup indirin."
      />
      <PanelIcerikYuzeyi className="pt-4">
        <QrPageClient
          businessId={businessId}
          businessSlug={biz?.slug ?? null}
          siteUrl={SITE_URL}
          initialCodes={codes}
          stats={stats}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
